// API references: Python objects documented from their source and docstrings, read by tdg's plugin (plugin/).

#import "util.typ": *
#import "components.typ": callout

#let _plugin = tdg-plugin

/// A Python module's API: `#let wgw = python-api(read("/python/wgw.py"), module: "wgw")`, then `#api(wgw, "wgw.Widget")`.
/// Typst plugins can't read files, so the page reads the source. `page` is the page that documents the module
/// ("reference"), so docstrings' links to other objects ([text][wgw.Slider]) point there.
#let python-api(source, module: none, page: "") = {
  assert(module != none, message: "python-api needs the module's name, such as module: \"wgw\"")
  json(_plugin.python_api(bytes(source), bytes(module), bytes(page)))
}

#let _inline(segments) = segments.map(s => {
  if s.t == "code" { raw(s.v) } else if s.t == "strong" { strong(s.v) } else if s.t == "em" { emph(s.v) }
  else if s.t == "link" { link(s.href, s.v) } else { s.v }
}).join()

#let _blocks(blocks) = blocks.map(b => {
  if b.t == "p" { par(_inline(b.v)) }
  else if b.t == "list" { list(..b.items.map(_inline)) }
  else if b.t == "code" { raw(b.v, lang: b.lang, block: true) }
  else if b.t == "table" and b.rows.len() > 0 {
    let n = calc.max(..b.rows.map(r => r.len()))
    table(columns: n, ..b.rows.enumerate().map(((i, row)) => row.map(c => if i == 0 { strong(_inline(c)) } else { _inline(c) })).flatten())
  }
}).join()

#let _section-titles = (parameters: "Parameters", "other parameters": "Other parameters", attributes: "Attributes",
  returns: "Returns", yields: "Yields", raises: "Raises", receives: "Receives")

#let _section(s) = {
  if s.kind == "text" { return _blocks(s.blocks) }
  let title = _section-titles.at(s.kind, default: s.kind)
  let rows = s.items.map(item => (
    if item.name != "" { raw(item.name) } else if item.type != "" { raw(item.type) } else { [] },
    _blocks(item.blocks),
  ))
  context if html-target() {
    html.elem("div", attrs: (class: "api-section api-" + s.kind.replace(" ", "-")))[
      #html.elem("p", attrs: (class: "api-section-title"), title)
      #html.elem("dl", rows.map(((name, doc)) => html.elem("dt", name) + html.elem("dd", doc)).join())
    ]
  } else {
    block(above: 0.8em, strong(title))
    grid(columns: (auto, 1fr), column-gutter: 1em, row-gutter: 0.7em, ..rows.flatten())
  }
}

#let _object(data, path, level, members) = {
  let o = data.at(path, default: none)
  assert(o != none, message: "api: nothing documented as " + repr(path) + "; is it public, and in tdg.toml's api modules?")
  let name = [#raw(o.name)#for label in o.labels.filter(l => l in ("dataclass", "property", "classmethod", "staticmethod")) [ #box(text(size: 0.7em, fill: luma(110), label))]]
  let body = {
    if "signature" in o and o.signature != o.name { raw(o.signature, lang: "python", block: true) }
    for s in o.doc { _section(s) }
    let shown = if members == false { () } else if members == auto { o.members } else {
      members.map(m => if m.contains(".") { m } else { path + "." + m })
    }
    for m in shown { _object(data, m, level + 1, auto) }
  }
  context if html-target() {
    html.elem("section", attrs: (class: "api api-" + o.kind))[
      #html.elem("h" + str(level), attrs: (id: path, class: "api-name"), name)
      #body
    ]
  } else {
    heading(level: level - 1, outlined: level <= 3, name)
    body
  }
}

// An object's text, for search: its name, signature and docs, and its members'.
#let _segments(v) = v.map(s => s.v).join(" ")
#let _blocks-text(blocks) = blocks.map(b => {
  if b.t == "p" { _segments(b.v) } else if b.t == "list" { b.items.map(_segments).join(" ") }
  else if b.t == "table" { b.rows.map(r => r.map(_segments).join(" ")).join(" ") } else { "" }
}).join(" ")
#let _text(data, path, members) = {
  let o = data.at(path, default: none)
  if o == none { return "" }
  let docs = o.doc.map(s => if s.kind == "text" { _blocks-text(s.blocks) } else {
    s.items.map(i => i.name + " " + _blocks-text(i.blocks)).join(" ")
  }).join(" ")
  let shown = if members == false { () } else if members == auto { o.members } else {
    members.map(m => if m.contains(".") { m } else { path + "." + m })
  }
  (o.name, o.at("signature", default: ""), o.labels.join(" "), if docs != none { docs } else { "" },
    ..shown.map(m => _text(data, m, auto))).join(" ")
}

/// An object's reference: its signature, docstring and members. `data` comes from `python-api`. Classes and
/// modules include their public members (`members: auto`), some (`members: ("load", "save")`), or none (`false`).
#let api(data, path, members: auto, level: 3) = {
  [#metadata(_text(data, path, members)) <tdg-search-text>]  // for the site's search
  _object(data, path, level, members)
}
