// What pages are made of: interactive 3D figures, theorems, callouts, source listings and images. Every function
// works for HTML (styled by the site's theme, from assets/components.css) and for PDF (laid out by Typst).

#import "util.typ": *

// ---- Widgets: interactive 3D figures, run by wgw (bundled with tdg).

/// An interactive 3D figure: a mesh, a widget that builds or drives it, or both. In HTML it's a live figure; in a
/// PDF, its `still`.
///
/// - widget (path, str, none): A widget, `.py` or `.js`: `path("torus_widget.py")`, which tdg publishes, or a URL.
///   A widget is a function `widget(mesh)` returning a `Widget` (see wgw's docs).
/// - src (path, str, none): A mesh, `.obj` or `.wgw`, drawn at once, then given to the widget.
/// - data (array): Files the widget reads, such as `(path("spectrum.npz"),)`, published beside it.
/// - still (content, none): What a PDF shows instead, such as `image("torus.png")`. Without one, a PDF shows a note.
/// - caption (content, none): The figure's caption; widgets are numbered with the other figures.
/// - up (str): The axis that points up: "x", "y" or "z".
/// - view (array, none): The starting camera, `(turn, tilt)` in degrees.
/// - pick (str): When the widget's `on_pick` runs: "click", "hover" or "none".
/// - flat (bool): Flat shading for the figure's mesh.
/// - height (length, str, none): The canvas's height, such as `360pt` or "50vh".
/// - alt (str, none): A description for screen readers; by default the caption's text.
/// - url (str, none): Where the interactive version is, for the note a PDF shows without a still.
/// - credit (bool): A small "wgw" link in the figure's corner.
#let widget(widget: none, src: none, data: (), still: none, caption: none, up: "z", view: none, pick: "click",
            flat: false, height: none, alt: none, url: none, credit: true) = {
  assert(widget != none or src != none, message: "a widget needs a widget, a src mesh, or both")
  assert(up in ("x", "y", "z"), message: "up is \"x\", \"y\" or \"z\", not " + repr(up))
  assert(pick in ("click", "hover", "none"), message: "pick is \"click\", \"hover\" or \"none\", not " + repr(pick))
  // Its files are published with the site (marked inside the figure, so a label on it labels the figure).
  let files = { publish(widget); publish(src); for file in data { publish(file) } }
  let body = files + context if html-target() {
    [#metadata(page-url.get()) <tdg-widget>]
    let attrs = (class: "wgw")
    if src != none { attrs.insert("data-src", file-url(src)) }
    if widget != none { attrs.insert("data-widget", file-url(widget)) }
    if up != "z" { attrs.insert("data-up", up) }
    if view != none { attrs.insert("data-view", if type(view) == str { view } else { view.map(num).join(",") }) }
    if pick != "click" { attrs.insert("data-pick", pick) }
    if flat { attrs.insert("data-flat", "") }
    if not credit { attrs.insert("data-credit", "false") }
    if height != none {
      attrs.insert("style", "--wgw-height: " + if type(height) == str { height } else { num(height.pt()) + "pt" })
    }
    let label = if alt != none { alt } else if caption != none { plain-text(caption) } else { none }
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

// ---- Theorems: numbered boxes, one count for all kinds. Each is a figure of kind "tdg-theorem", so a label on it
// can be referenced: `@thm:hopf` reads "Theorem 1".

/// A kind of numbered box: `#let conjecture = theorem-kind("conjecture", "Conjecture")`, then
/// `#conjecture[...]` or `#conjecture(title: [Goldbach])[...]`.
#let theorem-kind(kind, name) = (body, title: none) => figure(kind: "tdg-theorem", supplement: name, numbering: "1",
  outlined: false, gap: 0pt, {
    let head = [*#name #context counter(figure.where(kind: "tdg-theorem")).display()#if title != none [ (#title)].*]
    context if html-target() {
      html.elem("div", attrs: (class: "thm thm-" + kind))[#head #body]
    } else {
      align(left, block(width: 100%, inset: (left: 0.9em, y: 0.4em), stroke: (left: 1.2pt + luma(150)))[#head #body])
    }
  })

#let theorem = theorem-kind("theorem", "Theorem")
#let lemma = theorem-kind("lemma", "Lemma")
#let proposition = theorem-kind("proposition", "Proposition")
#let corollary = theorem-kind("corollary", "Corollary")
#let definition = theorem-kind("definition", "Definition")
#let example = theorem-kind("example", "Example")

/// A proof, ending in a square.
#let proof(body, title: none) = context if html-target() {
  html.elem("div", attrs: (class: "proof"))[
    _Proof#if title != none [ (#title)]._ #body #html.elem("span", attrs: (class: "qed"), $square$)
  ]
} else {
  block(width: 100%)[_Proof#if title != none [ (#title)]._ #body #h(1fr) $square$]
}

// ---- Layout

/// Content in two layouts: `wide` on wide screens and in PDFs, `narrow` on phones (an equation broken over lines).
#let responsive(wide, narrow) = context if html-target() {
  html.elem("div", attrs: (class: "wide-only"), wide)
  html.elem("div", attrs: (class: "narrow-only"), narrow)
} else {
  wide
}

#let _callout-colors = (note: rgb("#205ea6"), tip: rgb("#66800b"), warning: rgb("#bc5215"))

/// A boxed aside: kind is "note", "tip" or "warning".
#let callout(body, kind: "note", title: none) = {
  assert(kind in _callout-colors, message: "a callout is a \"note\", \"tip\" or \"warning\", not " + repr(kind))
  context if html-target() {
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

/// A file's source as a code block under its name: `#source-code(path("example.py"))`, or a name and its text.
#let source-code(file, text: none, lang: auto) = {
  let name = if type(file) == str { file } else { path-string(file).split("/").last() }
  let text = if text != none { text } else { read(file) }
  let lang = if lang != auto { lang } else { name.split(".").last() }
  context if html-target() {
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

/// An image with a version for each theme: `light` and `dark` are its two files, as paths (published by tdg) or
/// URLs. A string description is alt text only; content is the caption, and its text the alt. A PDF shows the light
/// version (its first frame, for an animation).
#let themed-image(light, dark, description, alt: auto) = {
  let caption = if type(description) == str { none } else { description }
  let alt = if alt != auto { alt } else { plain-text(description) }
  figure(
    publish(light) + publish(dark) + context if html-target() {
      html.elem("img", attrs: (src: file-url(light), alt: alt, class: "light-only"))
      html.elem("img", attrs: (src: file-url(dark), alt: alt, class: "dark-only"))
    } else if type(light) != str {
      image(light, alt: alt)
    } else {
      block(width: 100%, inset: 1em, stroke: 0.5pt + luma(180), radius: 3pt, std.text(fill: luma(110), alt))
    },
    caption: caption,
  )
}
