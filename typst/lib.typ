// tdg: interactive 3D figures, theorems, callouts and API references, for documents compiled to HTML or PDF.
//
// Every function works in both: in HTML it emits elements that tdg's themes style (and a figure's widget runs), and
// in a PDF it lays out an equivalent. With tdg (the site builder) pages get it as `@local/tdg`; otherwise import it
// from Typst Universe as `@preview/tdg`.

#let _html() = target() == "html"

// A number as HTML attributes and JavaScript read it: Typst writes negatives with a typographic minus (U+2212).
#let _num(x) = str(x).replace("\u{2212}", "-")

// The plain text of some content, for alt text; math and other non-text parts are dropped.
#let _plain-text(it) = if type(it) == str { it } else if type(it) != content { "" } else if it.has("text") {
  _plain-text(it.text)  // a string, or content (math operators like cos)
} else if it.has("children") {
  it.children.map(_plain-text).join(default: "")
} else if it.has("body") { _plain-text(it.body) } else if it == [ ] { " " } else { "" }

// ---- Widgets: interactive 3D figures, run by wgw (bundled with tdg).

/// An interactive 3D figure: a mesh, a widget that builds or drives it, or both. In HTML it's a live figure; in a
/// PDF, its `still`.
///
/// - widget (str, none): A widget file, `.py` or `.js`, relative to the page: a function `widget(mesh)` returning
///   a `Widget` (see wgw's docs). Its folder is published with the page, so it can read files beside it.
/// - src (str, none): A mesh file, `.obj` or `.wgw`, relative to the page: drawn at once, then given to the widget.
/// - still (content, none): What a PDF shows instead, such as `image("figures/spot.png")` (`tdg stills` renders
///   these). Without one, a PDF shows a note that the figure is interactive online.
/// - caption (content, none): The figure's caption.
/// - up (str): The axis that points up: "x", "y" or "z".
/// - view (array, str, none): The starting camera, `(turn, tilt)` in degrees.
/// - pick (str): When the widget's `on_pick` runs: "click", "hover" or "none".
/// - flat (bool): Flat shading for the figure's mesh.
/// - height (length, str, none): The canvas's height, such as `360pt` or "50vh"; by default the site's.
/// - alt (str, none): A description for screen readers; by default the caption's text.
/// - url (str, none): Where the interactive version is, for the note a PDF shows without a still.
/// - credit (bool): A small "wgw" link in the figure's corner.
#let widget(widget: none, src: none, still: none, caption: none, up: "z", view: none, pick: "click", flat: false,
            height: none, alt: none, url: none, credit: true) = {
  assert(widget != none or src != none, message: "a widget needs a widget file, a src mesh, or both")
  assert(type(widget) in (str, type(none)), message: "widget is a file name, relative to the page")
  assert(type(src) in (str, type(none)), message: "src is a file name, relative to the page")
  assert(up in ("x", "y", "z"), message: "up is \"x\", \"y\" or \"z\", not " + repr(up))
  assert(pick in ("click", "hover", "none"), message: "pick is \"click\", \"hover\" or \"none\", not " + repr(pick))
  let body = context if _html() {
    let attrs = (class: "wgw")
    if src != none { attrs.insert("data-src", src) }
    if widget != none { attrs.insert("data-widget", widget) }
    if up != "z" { attrs.insert("data-up", up) }
    if view != none { attrs.insert("data-view", if type(view) == str { view } else { view.map(_num).join(",") }) }
    if pick != "click" { attrs.insert("data-pick", pick) }
    if flat { attrs.insert("data-flat", "") }
    if not credit { attrs.insert("data-credit", "false") }
    if height != none {
      attrs.insert("style", "--wgw-height: " + if type(height) == str { height } else { _num(height.pt()) + "pt" })
    }
    let label = if alt != none { alt } else if caption != none { _plain-text(caption) } else { none }
    if label != none { attrs.insert("data-label", label) }
    html.elem("div", attrs: attrs)
  } else if still != none {
    still
  } else {
    block(width: 100%, height: 5cm, stroke: 0.5pt + luma(180), radius: 3pt,
      align(center + horizon, text(fill: luma(110), size: 0.9em)[
        An interactive 3D figure#if url != none [: #link(url)] else [, in the web version].
      ]))
  }
  figure(body, caption: caption, kind: image)  // numbered with the other figures
}

// ---- Theorems: numbered boxes, one count for all kinds.

#let _theorems = counter("tdg-theorem")

/// A kind of numbered box: `#let conjecture = theorem-kind("conjecture", "Conjecture")`, then
/// `#conjecture[...]` or `#conjecture(title: [Goldbach])[...]`.
#let theorem-kind(kind, name) = (body, title: none) => {
  _theorems.step()
  let head = [*#name #context _theorems.display()#if title != none [ (#title)].*]
  context if _html() {
    html.elem("div", attrs: (class: "thm thm-" + kind))[#head #body]
  } else {
    block(width: 100%, inset: (left: 0.9em, y: 0.4em), stroke: (left: 1.2pt + luma(150)))[#head #body]
  }
}

#let theorem = theorem-kind("theorem", "Theorem")
#let lemma = theorem-kind("lemma", "Lemma")
#let proposition = theorem-kind("proposition", "Proposition")
#let corollary = theorem-kind("corollary", "Corollary")
#let definition = theorem-kind("definition", "Definition")
#let example = theorem-kind("example", "Example")

/// A proof, ending in a square.
#let proof(body, title: none) = context if _html() {
  html.elem("div", attrs: (class: "proof"))[
    _Proof#if title != none [ (#title)]._ #body #html.elem("span", attrs: (class: "qed"), $square$)
  ]
} else {
  block(width: 100%)[_Proof#if title != none [ (#title)]._ #body #h(1fr) $square$]
}

// ---- Layout

/// Content in two layouts: `wide` on wide screens and in PDFs, `narrow` on phones (an equation broken over lines).
#let responsive(wide, narrow) = context if _html() {
  html.elem("div", attrs: (class: "wide-only"), wide)
  html.elem("div", attrs: (class: "narrow-only"), narrow)
} else {
  wide
}

#let _callout-colors = (note: rgb("#205ea6"), tip: rgb("#66800b"), warning: rgb("#bc5215"))

/// A boxed aside: kind is "note", "tip" or "warning".
#let callout(body, kind: "note", title: none) = {
  assert(kind in _callout-colors, message: "a callout is a \"note\", \"tip\" or \"warning\", not " + repr(kind))
  context if _html() {
    html.elem("aside", attrs: (class: "callout callout-" + kind))[
      #if title != none { html.elem("p", attrs: (class: "callout-title"), title) }
      #body
    ]
  } else {
    let color = _callout-colors.at(kind)
    block(width: 100%, inset: 0.8em, radius: 2pt, fill: color.lighten(92%), stroke: (left: 2pt + color))[
      #if title != none { block(below: 0.6em, strong(title)) }
      #body
    ]
  }
}

/// A file's source as a code block under its name: `#source-code("example.py", read("example.py"))`.
#let source-code(name, text, lang: auto) = {
  let lang = if lang != auto { lang } else { name.split(".").last() }
  context if _html() {
    html.elem("div", attrs: (class: "source-code"))[
      #html.elem("div", attrs: (class: "source-name"), name)
      #raw(text, lang: lang, block: true)
    ]
  } else {
    block(width: 100%, breakable: true)[
      #std.text(size: 0.8em, fill: luma(100), raw(name))
      #block(width: 100%, inset: 0.7em, radius: 2pt, fill: luma(246), raw(text, lang: lang, block: true))
    ]
  }
}

// ---- Images

/// An image with a version for each theme: `name` is its path without extension, and `name-dark.ext` the dark
/// version, both relative to the page. A string description is alt text only; content is the caption, and its text
/// the alt. In a PDF it shows `print`, such as `image("figure.png")`, or else its alt text.
#let themed-image(name, description, alt: auto, ext: "png", print: none) = {
  let caption = if type(description) == str { none } else { description }
  let alt = if alt != auto { alt } else { _plain-text(description) }
  figure(
    context if _html() {
      html.elem("img", attrs: (src: name + "." + ext, alt: alt, class: "light-only"))
      html.elem("img", attrs: (src: name + "-dark." + ext, alt: alt, class: "dark-only"))
    } else if print != none {
      print
    } else {
      block(width: 100%, inset: 1em, stroke: 0.5pt + luma(180), radius: 3pt, std.text(fill: luma(110), alt))
    },
    caption: caption,
  )
}

// ---- API references: objects documented from their docstrings, with data tdg extracts when it builds the site.

#let _api-data() = {
  let data = sys.inputs.at("tdg-api", default: none)
  if data == none { none } else { json(bytes(data)) }
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
  context if _html() {
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
  context if _html() {
    html.elem("section", attrs: (class: "api api-" + o.kind))[
      #html.elem("h" + str(level), attrs: (id: path, class: "api-name"), name)
      #body
    ]
  } else {
    heading(level: level - 1, outlined: level <= 3, name)
    body
  }
}

/// A Python object's reference, from its docstring: `#api("wgw.Widget")`. Classes and modules include their
/// public members (`members: auto`), a chosen few (`members: ("load", "save")`), or none (`members: false`). The
/// data comes from tdg, which reads the modules in tdg.toml's `[api]` when it builds the site.
#let api(path, members: auto, level: 3) = {
  let data = _api-data()
  if data == none {
    callout(kind: "warning")[The reference for #raw(path) is added when tdg builds the site.]
  } else {
    _object(data, path, level, members)
  }
}
