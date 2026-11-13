// tdg's Typst library, for pages of sites built by tdg: `#import "@local/tdg:0.1.0": *`.
// Each function emits HTML that tdg's themes style (see themes/default/style.css), so it works in any tdg site.

// The plain text of some content, for alt text; math and other non-text parts are dropped.
#let _plain-text(it) = if type(it) == str { it } else if it.has("text") { it.text } else if it.has("children") {
  it.children.map(_plain-text).join(default: "")
} else if it.has("body") { _plain-text(it.body) } else if it == [ ] { " " } else { "" }

// ---- Widgets: interactive 3D figures (wgw), bundled with tdg.

/// An interactive 3D figure: a mesh, a widget that builds or drives it, or both.
///
/// - widget (str, none): A widget file, `.py` or `.js`, relative to the page: a function `widget(mesh)` returning a
///   `Widget` (see wgw's docs). Its folder is published with the page, so it can read files beside it.
/// - src (str, none): A mesh file, `.obj` or `.wgw`, relative to the page; drawn at once, then handed to the widget.
/// - caption (content, none): The figure's caption.
/// - up (str): The axis that points up: "x", "y" or "z".
/// - view (array, str, none): The starting camera: `(turn, tilt)` in degrees, or "turn,tilt".
/// - pick (str): When the widget's `on_pick` runs: "click", "hover" or "none".
/// - flat (bool): Flat shading for the figure's mesh.
/// - height (length, str, none): The canvas's height, such as `360pt` or "50vh"; by default the site's.
/// - alt (str, none): A description for screen readers; by default the caption's text.
#let widget(widget: none, src: none, caption: none, up: "z", view: none, pick: "click", flat: false,
            height: none, alt: none) = {
  assert(widget != none or src != none, message: "a widget needs a widget file, a src mesh, or both")
  assert(up in ("x", "y", "z"), message: "up is \"x\", \"y\" or \"z\", not " + repr(up))
  assert(pick in ("click", "hover", "none"), message: "pick is \"click\", \"hover\" or \"none\", not " + repr(pick))
  let attrs = (class: "wgw")
  if src != none { attrs.insert("data-src", src) }
  if widget != none { attrs.insert("data-widget", widget) }
  if up != "z" { attrs.insert("data-up", up) }
  if view != none { attrs.insert("data-view", if type(view) == str { view } else { view.map(str).join(",") }) }
  if pick != "click" { attrs.insert("data-pick", pick) }
  if flat { attrs.insert("data-flat", "") }
  if height != none { attrs.insert("style", "--wgw-height: " + if type(height) == str { height } else { str(height.pt()) + "pt" }) }
  let label = if alt != none { alt } else if caption != none { _plain-text(caption) } else { none }
  if label != none { attrs.insert("data-label", label) }
  figure(html.elem("div", attrs: attrs), caption: caption, kind: image)  // numbered with the other figures
}

// ---- Theorems: numbered boxes, one count for all kinds.

#let _theorems = counter("tdg-theorem")

/// A kind of numbered box, such as `theorem-kind("conjecture", "Conjecture")`; used as `#conjecture[...]` or
/// `#conjecture(title: [Goldbach])[...]`.
#let theorem-kind(kind, name) = (body, title: none) => {
  _theorems.step()
  html.elem("div", attrs: (class: "thm thm-" + kind))[
    *#name #context _theorems.display()#if title != none [ (#title)].* #body
  ]
}

#let theorem = theorem-kind("theorem", "Theorem")
#let lemma = theorem-kind("lemma", "Lemma")
#let proposition = theorem-kind("proposition", "Proposition")
#let corollary = theorem-kind("corollary", "Corollary")
#let definition = theorem-kind("definition", "Definition")
#let example = theorem-kind("example", "Example")

/// A proof, ending in a square.
#let proof(body, title: none) = html.elem("div", attrs: (class: "proof"))[
  _Proof#if title != none [ (#title)]._ #body #html.elem("span", attrs: (class: "qed"), $square$)
]

// ---- Layout

/// Content in two layouts: `wide` on wide screens, `narrow` on phones (an equation broken over lines, say).
#let responsive(wide, narrow) = {
  html.elem("div", attrs: (class: "wide-only"), wide)
  html.elem("div", attrs: (class: "narrow-only"), narrow)
}

/// A boxed aside: kind is "note", "tip" or "warning".
#let callout(body, kind: "note", title: none) = {
  assert(kind in ("note", "tip", "warning"), message: "a callout is a \"note\", \"tip\" or \"warning\"")
  html.elem("aside", attrs: (class: "callout callout-" + kind))[
    #if title != none { html.elem("p", attrs: (class: "callout-title"), title) }
    #body
  ]
}

/// A file's source as a code block, under its name: `#source-code("example.py", read("example.py"))`.
#let source-code(name, text, lang: auto) = {
  let lang = if lang != auto { lang } else { name.split(".").last() }
  html.elem("div", attrs: (class: "source-code"))[
    #html.elem("div", attrs: (class: "source-name"), name)
    #raw(text, lang: lang, block: true)
  ]
}

// ---- Images

/// An image with a version for each theme: `name` is the path without extension, and `name-dark.ext` the dark
/// version. A string description is alt text only; content is the caption, and its text the alt.
#let themed-image(name, description, alt: auto, ext: "png") = {
  let caption = if type(description) == str { none } else { description }
  let alt = if alt != auto { alt } else { _plain-text(description) }
  figure(
    {
      html.elem("img", attrs: (src: name + "." + ext, alt: alt, class: "light-only"))
      html.elem("img", attrs: (src: name + "-dark." + ext, alt: alt, class: "dark-only"))
    },
    caption: caption,
  )
}
