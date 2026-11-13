//! tdg's Typst plugin: a Python module's API, from its source and Google-style docstrings, as JSON that tdg's
//! `api(...)` lays out. Typst plugins can't read files, so the page reads the source and passes it in.

use rustpython_parser::ast::{self, Ranged};
use serde_json::{json, Map, Value};
#[cfg(target_arch = "wasm32")]
use wasm_minimal_protocol::*;

// The protocol imports functions Typst provides, so it's only built for Typst; natively, the parsing is tested.
#[cfg(target_arch = "wasm32")]
initiate_protocol!();

/// `python_api(source, module, page)`: {path: object} for the module and its public classes, functions and
/// methods. `page` is the page that documents them ("reference"), for links between objects; "" for this page.
#[cfg_attr(target_arch = "wasm32", wasm_func)]
pub fn python_api(source: &[u8], module: &[u8], page: &[u8]) -> Result<Vec<u8>, String> {
    let source = std::str::from_utf8(source).map_err(|_| "the source isn't UTF-8".to_string())?;
    let module = std::str::from_utf8(module).map_err(|_| "the module name isn't UTF-8".to_string())?;
    let page = std::str::from_utf8(page).map_err(|_| "the page isn't UTF-8".to_string())?;
    let records = api(source, module, page)?;
    Ok(serde_json::to_vec(&records).unwrap())
}

pub fn api(source: &str, module: &str, page: &str) -> Result<Map<String, Value>, String> {
    let parsed = rustpython_parser::parse(source, rustpython_parser::Mode::Module, module)
        .map_err(|e| format!("{module}: can't parse its source: {e}"))?;
    let body = match parsed {
        ast::Mod::Module(m) => m.body,
        _ => return Err("expected a module".into()),
    };
    let ctx = Ctx { source, page };
    let mut records = Map::new();
    let mut members = vec![];
    for stmt in &body {
        match stmt {
            ast::Stmt::ClassDef(c) if public(&c.name) => {
                members.push(json!(format!("{module}.{}", c.name)));
                class(&ctx, c, module, &mut records);
            }
            ast::Stmt::FunctionDef(f) if public(&f.name) => {
                members.push(json!(format!("{module}.{}", f.name)));
                function(&ctx, f, module, false, &mut records);
            }
            _ => {}
        }
    }
    records.insert(module.into(), json!({
        "path": module, "name": module, "kind": "module", "labels": [],
        "doc": sections(docstring(&body).as_deref(), page), "members": members,
    }));
    Ok(records)
}

struct Ctx<'a> {
    source: &'a str,
    page: &'a str,
}

impl Ctx<'_> {
    fn text<T: Ranged>(&self, node: &T) -> String {
        let r = node.range();
        self.source[r.start().to_usize()..r.end().to_usize()].to_string()
    }
}

fn public(name: &str) -> bool {
    !name.starts_with('_')
}

/// A body's docstring, cleaned as Python's inspect.cleandoc does.
fn docstring(body: &[ast::Stmt]) -> Option<String> {
    let ast::Stmt::Expr(e) = body.first()? else { return None };
    let ast::Expr::Constant(c) = e.value.as_ref() else { return None };
    let ast::Constant::Str(s) = &c.value else { return None };
    Some(cleandoc(s))
}

fn cleandoc(s: &str) -> String {
    let expanded = s.replace('\t', "        ");
    let lines: Vec<&str> = expanded.lines().collect();
    let indent = lines.iter().skip(1).filter(|l| !l.trim().is_empty())
        .map(|l| l.len() - l.trim_start().len()).min().unwrap_or(0);
    let mut out: Vec<String> = lines.iter().enumerate()
        .map(|(i, l)| if i == 0 { l.trim().to_string() } else { l.get(indent..).unwrap_or("").trim_end().to_string() })
        .collect();
    while out.first().is_some_and(|l| l.is_empty()) { out.remove(0); }
    while out.last().is_some_and(|l| l.is_empty()) { out.pop(); }
    out.join("\n")
}

fn decorators(ctx: &Ctx, list: &[ast::Expr]) -> Vec<String> {
    list.iter().map(|d| {
        let text = ctx.text(d);
        text.split('(').next().unwrap_or("").rsplit('.').next().unwrap_or("").to_string()
    }).collect()
}

fn signature(ctx: &Ctx, name: &str, args: &ast::Arguments, skip_self: bool) -> String {
    let mut positional: Vec<&ast::ArgWithDefault> = args.posonlyargs.iter().chain(args.args.iter()).collect();
    if skip_self && positional.first().is_some_and(|a| ["self", "cls"].contains(&a.def.arg.as_str())) {
        positional.remove(0);
    }
    let with_default = |a: &ast::ArgWithDefault| match &a.default {
        Some(d) => format!("{}={}", a.def.arg, ctx.text(d.as_ref())),
        None => a.def.arg.to_string(),
    };
    let mut parts: Vec<String> = positional.iter().map(|a| with_default(a)).collect();
    if let Some(v) = &args.vararg {
        parts.push(format!("*{}", v.arg));
    } else if !args.kwonlyargs.is_empty() {
        parts.push("*".into());
    }
    parts.extend(args.kwonlyargs.iter().map(with_default));
    if let Some(k) = &args.kwarg {
        parts.push(format!("**{}", k.arg));
    }
    format!("{name}({})", parts.join(", "))
}

fn function(ctx: &Ctx, f: &ast::StmtFunctionDef, parent: &str, method: bool, records: &mut Map<String, Value>) {
    let path = format!("{parent}.{}", f.name);
    let labels: Vec<String> = decorators(ctx, &f.decorator_list).into_iter()
        .filter(|d| ["property", "classmethod", "staticmethod", "cached_property"].contains(&d.as_str()))
        .map(|d| if d == "cached_property" { "property".into() } else { d }).collect();
    let is_property = labels.iter().any(|l| l == "property");
    let skip_self = method && !labels.iter().any(|l| l == "staticmethod");
    records.insert(path.clone(), json!({
        "path": path, "name": f.name.as_str(), "kind": if is_property { "attribute" } else { "function" },
        "labels": labels,
        "signature": if is_property { f.name.to_string() } else { signature(ctx, &f.name, &f.args, skip_self) },
        "doc": sections(docstring(&f.body).as_deref(), ctx.page), "members": [],
    }));
}

fn class(ctx: &Ctx, c: &ast::StmtClassDef, parent: &str, records: &mut Map<String, Value>) {
    let path = format!("{parent}.{}", c.name);
    let is_dataclass = decorators(ctx, &c.decorator_list).iter().any(|d| d == "dataclass");
    let labels: Vec<&str> = if is_dataclass { vec!["dataclass"] } else { vec![] };

    // Its signature: __init__'s, or a dataclass's fields in order.
    let init = c.body.iter().find_map(|s| match s {
        ast::Stmt::FunctionDef(f) if f.name.as_str() == "__init__" => Some(f),
        _ => None,
    });
    let signature = if let Some(init) = init {
        signature(ctx, &c.name, &init.args, true)
    } else if is_dataclass {
        let fields: Vec<String> = c.body.iter().filter_map(|s| match s {
            ast::Stmt::AnnAssign(a) => {
                let ast::Expr::Name(n) = a.target.as_ref() else { return None };
                if ctx.text(a.annotation.as_ref()).starts_with("ClassVar") { return None; }
                Some(match &a.value {
                    None => n.id.to_string(),
                    Some(v) => format!("{}={}", n.id, dataclass_default(ctx, v)),
                })
            }
            _ => None,
        }).collect();
        format!("{}({})", c.name, fields.join(", "))
    } else {
        format!("{}()", c.name)
    };

    // Its members: public methods, and properties; fields are described in its docstring.
    let mut members = vec![];
    for stmt in &c.body {
        if let ast::Stmt::FunctionDef(f) = stmt {
            if public(&f.name) {
                members.push(json!(format!("{path}.{}", f.name)));
                function(ctx, f, &path, true, records);
            }
        }
    }
    records.insert(path.clone(), json!({
        "path": path, "name": c.name.as_str(), "kind": "class", "labels": labels, "signature": signature,
        "doc": sections(docstring(&c.body).as_deref(), ctx.page), "members": members,
    }));
}

/// A dataclass field's default as its constructor's: `field(default_factory=dict)` is `dict()`.
fn dataclass_default(ctx: &Ctx, value: &ast::Expr) -> String {
    if let ast::Expr::Call(call) = value {
        if ctx.text(call.func.as_ref()).rsplit('.').next() == Some("field") {
            for k in &call.keywords {
                match k.arg.as_ref().map(|a| a.as_str()) {
                    Some("default_factory") => return format!("{}()", ctx.text(&k.value)),
                    Some("default") => return ctx.text(&k.value),
                    _ => {}
                }
            }
        }
    }
    ctx.text(value)
}

// ---- Google-style docstrings.

const SECTIONS: &[(&str, &str)] = &[
    ("Args", "parameters"), ("Arguments", "parameters"), ("Parameters", "parameters"), ("Params", "parameters"),
    ("Keyword Args", "other parameters"), ("Keyword Arguments", "other parameters"), ("Other Parameters", "other parameters"),
    ("Attributes", "attributes"), ("Returns", "returns"), ("Return", "returns"), ("Yields", "yields"),
    ("Raises", "raises"), ("Examples", "examples"), ("Example", "examples"), ("Note", "text"), ("Notes", "text"),
    ("Warning", "text"), ("Warnings", "text"),
];

fn sections(doc: Option<&str>, page: &str) -> Value {
    let Some(doc) = doc else { return json!([]) };
    let lines: Vec<&str> = doc.lines().collect();
    let mut out = vec![];
    let mut text: Vec<&str> = vec![];
    let mut i = 0;
    let flush = |text: &mut Vec<&str>, out: &mut Vec<Value>| {
        if text.iter().any(|l| !l.trim().is_empty()) {
            out.push(json!({"kind": "text", "blocks": blocks(&text.join("\n"), page)}));
        }
        text.clear();
    };
    while i < lines.len() {
        let line = lines[i];
        let header = if line.starts_with(' ') { None } else {
            line.trim_end().strip_suffix(':').and_then(|h| SECTIONS.iter().find(|(name, _)| *name == h).map(|(_, kind)| *kind))
        };
        let Some(kind) = header else {
            text.push(line);
            i += 1;
            continue;
        };
        flush(&mut text, &mut out);
        // The section's body: the indented lines after its header.
        let mut body = vec![];
        i += 1;
        while i < lines.len() && (lines[i].trim().is_empty() || lines[i].starts_with(' ')) {
            body.push(lines[i]);
            i += 1;
        }
        let body = cleandoc(&format!("\n{}", body.join("\n")));
        match kind {
            "text" => out.push(json!({"kind": "text", "blocks": blocks(&body, page)})),
            "examples" => out.push(json!({"kind": "text", "blocks": [{"t": "code", "lang": "python", "v": body}]})),
            "returns" | "yields" => {
                let (ty, desc) = match body.split_once(": ") {
                    Some((ty, desc)) if !ty.trim().contains(' ') => (ty.trim().to_string(), desc.to_string()),
                    _ => (String::new(), body.clone()),
                };
                out.push(json!({"kind": kind, "items": [{"name": "", "type": ty, "blocks": blocks(&desc, page)}]}));
            }
            _ => out.push(json!({"kind": kind, "items": items(&body, page)})),
        }
    }
    flush(&mut text, &mut out);
    Value::Array(out)
}

/// Items of an Args-like section: `name (type): description`, continued on more-indented lines.
fn items(body: &str, page: &str) -> Value {
    let item = regex_lite::Regex::new(r"^(\*{0,2}[\w.]+)\s*(?:\(([^)]*)\))?\s*:\s*(.*)$").unwrap();
    let mut out: Vec<(String, String, Vec<String>)> = vec![];
    for line in body.lines() {
        if !line.starts_with(' ') {
            if let Some(m) = item.captures(line) {
                out.push((m[1].to_string(), m.get(2).map_or("", |t| t.as_str()).to_string(), vec![m[3].to_string()]));
                continue;
            }
        }
        if let Some(last) = out.last_mut() {
            last.2.push(line.trim().to_string());
        }
    }
    Value::Array(out.into_iter().map(|(name, ty, desc)| {
        json!({"name": name, "type": ty, "blocks": blocks(&desc.join("\n"), page)})
    }).collect())
}

// ---- A little Markdown, as structured content (so Typst never evaluates docstrings).

/// Text as blocks: paragraphs, lists, tables and code.
fn blocks(text: &str, page: &str) -> Value {
    let lines: Vec<&str> = text.trim_matches('\n').lines().collect();
    let bullet = |l: &str| { let t = l.trim_start(); t.starts_with("- ") || t.starts_with("* ") };
    let special = |l: &str| { let t = l.trim_start(); t.starts_with('|') || t.starts_with("```") };
    let mut out = vec![];
    let mut i = 0;
    while i < lines.len() {
        let line = lines[i].trim_end();
        if line.trim().is_empty() {
            i += 1;
        } else if line.trim_start().starts_with("```") {
            let lang = line.trim().trim_start_matches('`');
            let mut j = i + 1;
            while j < lines.len() && !lines[j].trim_start().starts_with("```") { j += 1; }
            let code = lines[i + 1..j.min(lines.len())].join("\n");
            out.push(json!({"t": "code", "lang": if lang.is_empty() { "python" } else { lang }, "v": code}));
            i = j + 1;
        } else if line.trim_start().starts_with('|') {
            let mut rows = vec![];
            while i < lines.len() && lines[i].trim_start().starts_with('|') {
                let cells: Vec<&str> = lines[i].trim().trim_matches('|').split('|').map(|c| c.trim()).collect();
                let rule = cells.iter().all(|c| !c.is_empty() && c.chars().all(|ch| matches!(ch, '-' | ':')));
                if !rule { rows.push(Value::Array(cells.iter().map(|c| inline(c, page)).collect())); }
                i += 1;
            }
            out.push(json!({"t": "table", "rows": rows}));
        } else if bullet(line) {
            let mut items: Vec<String> = vec![];
            while i < lines.len() && !lines[i].trim().is_empty() {
                if bullet(lines[i]) { items.push(lines[i].trim_start()[2..].trim().to_string()); }
                else if let Some(last) = items.last_mut() { last.push(' '); last.push_str(lines[i].trim()); }
                i += 1;
            }
            out.push(json!({"t": "list", "items": items.iter().map(|it| inline(it, page)).collect::<Vec<_>>()}));
        } else {
            let mut paragraph = vec![];
            while i < lines.len() && !lines[i].trim().is_empty() && !bullet(lines[i]) && !special(lines[i]) {
                paragraph.push(lines[i].trim());
                i += 1;
            }
            out.push(json!({"t": "p", "v": inline(&paragraph.join(" "), page)}));
        }
    }
    Value::Array(out)
}

/// Text as [{"t": "text" | "code" | "strong" | "em" | "link", "v": ..., "href"?: ...}].
fn inline(text: &str, page: &str) -> Value {
    let re = regex_lite::Regex::new(r"`([^`]+)`|\*\*(\S(?:.*?\S)?)\*\*|\[([^\]]+)\]\(([^)]+)\)|\[([^\]]+)\]\[([\w.]+)\]").unwrap();
    let mut out = vec![];
    let mut at = 0;
    for m in re.captures_iter(text) {
        let whole = m.get(0).unwrap();
        emphasis(&text[at..whole.start()], &mut out);
        if let Some(code) = m.get(1) { out.push(json!({"t": "code", "v": code.as_str()})); }
        else if let Some(strong) = m.get(2) { out.push(json!({"t": "strong", "v": strong.as_str()})); }
        else if let (Some(label), Some(url)) = (m.get(3), m.get(4)) { out.push(json!({"t": "link", "v": label.as_str(), "href": url.as_str()})); }
        else if let (Some(label), Some(target)) = (m.get(5), m.get(6)) {
            let href = if page.is_empty() { format!("#{}", target.as_str()) } else { format!("/{page}/#{}", target.as_str()) };
            out.push(json!({"t": "link", "v": label.as_str(), "href": href}));
        }
        at = whole.end();
    }
    emphasis(&text[at..], &mut out);
    Value::Array(out)
}

/// Plain text, with *emphasis* only between non-word characters, so `**params` and `2*x*3` stay text.
fn emphasis(text: &str, out: &mut Vec<Value>) {
    let re = regex_lite::Regex::new(r"\*([^*\s][^*]*?)\*").unwrap();
    let word = |c: Option<char>| c.is_some_and(|c| c.is_alphanumeric() || c == '*');
    let (mut at, mut from) = (0, 0);
    while let Some(m) = re.captures_at(text, from) {
        let whole = m.get(0).unwrap();
        if word(text[..whole.start()].chars().last()) || word(text[whole.end()..].chars().next()) {
            from = whole.start() + 1;  // not emphasis: look again one character on
            continue;
        }
        if whole.start() > at { out.push(json!({"t": "text", "v": &text[at..whole.start()]})); }
        out.push(json!({"t": "em", "v": &m[1]}));
        at = whole.end();
        from = at;
    }
    if at < text.len() { out.push(json!({"t": "text", "v": &text[at..]})); }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wgw() {
        let source = std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/../../wgw/python/wgw.py")).unwrap();
        let r = api(&source, "wgw", "reference").unwrap();
        assert_eq!(r["wgw.Widget"]["signature"], "Widget(scene=dict(), controls=dict(), on_change=None, on_pick=None, grid=False, picked=None, fps=30, loop=False)");
        assert_eq!(r["wgw.Mesh"]["signature"], "Mesh(vertices, faces, values=None, data=None, **params)");
        assert_eq!(r["wgw.torus"]["signature"], "torus(R=1.0, r=0.4, n=64)");
        assert_eq!(r["wgw.Mesh.load"]["labels"], json!(["classmethod"]));
        assert_eq!(r["wgw.Mesh.normals"]["kind"], "attribute");
        let kinds: Vec<_> = r["wgw.torus"]["doc"].as_array().unwrap().iter().map(|s| s["kind"].as_str().unwrap()).collect();
        assert_eq!(kinds, ["text", "parameters", "returns"]);
        let attrs = r["wgw.Widget"]["doc"].as_array().unwrap().iter().find(|s| s["kind"] == "attributes").unwrap();
        assert_eq!(attrs["items"][1]["name"], "controls");
        assert_eq!(attrs["items"][1]["blocks"][0]["v"][0]["href"], "/reference/#wgw.Slider");
        let layer = r["wgw.Layer"]["doc"].as_array().unwrap();
        assert!(layer.iter().any(|s| s["blocks"].as_array().is_some_and(|b| b.iter().any(|b| b["t"] == "table"))));
        let mesh_params = r["wgw.Mesh"]["doc"].as_array().unwrap().iter().find(|s| s["kind"] == "parameters").unwrap();
        assert_eq!(mesh_params["items"][4]["name"], "**params");
    }

    #[test]
    fn emphasis_needs_word_boundaries() {
        let v = inline("pass **params or a *word*, not 2*x*3", "");
        let kinds: Vec<_> = v.as_array().unwrap().iter().map(|s| s["t"].as_str().unwrap()).collect();
        assert_eq!(kinds, ["text", "em", "text"]);
    }
}
