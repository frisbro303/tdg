#import "@local/tdg:0.1.0": *
#set document(title: "The Typst library", description: "tdg's Typst functions: widgets, theorems, callouts, API references, and more.")

Pages import tdg's library with `#import "@local/tdg:0.1.0": *`; tdg provides it to every compile, and
`tdg install` makes it visible to editors. Every function works for HTML (styled by the site's theme) and for PDF
(laid out by Typst), so the same page can be a web page and a printable document.

= Widgets

`widget(...)` makes an interactive 3D figure, run by #link("https://github.com/frisbro303/wgw")[wgw], which tdg
bundles: a mesh, a widget (a short Python or JavaScript program) that builds or drives it, or both.

```typ
#widget(widget: "/examples/torus_widget.py", view: (-60, 35), caption: [A torus.])
```

#widget(widget: "/examples/torus_widget.py", view: (-60, 35), caption: [A torus.])

#table(
  columns: 2,
  [*argument*], [],
  [`widget`], [a widget file, `.py` or `.js`, relative to the page (#link("https://frisbro303.github.io/wgw/widgets/")[writing widgets])],
  [`src`], [a mesh file, `.obj` or `.wgw`, relative to the page],
  [`still`], [what a PDF shows instead, such as `image("torus.png")`],
  [`caption`], [the figure's caption; widgets are numbered with the other figures],
  [`up`], [the axis that points up: `"x"`, `"y"` or `"z"` (the default)],
  [`view`], [the starting camera, `(turn, tilt)` in degrees],
  [`pick`], [when the widget's `on_pick` runs: `"click"` (the default), `"hover"` or `"none"`],
  [`flat`], [flat shading],
  [`height`], [the canvas's height, such as `360pt`],
  [`alt`], [a description for screen readers; by default the caption's text],
  [`url`], [where the interactive version is, for a PDF without a still],
  [`credit`], [a small "wgw" link in the corner; `false` hides it],
)

= Theorems and proofs

#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
#proof[By inspection.]

```typ
#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
#proof[By inspection.]
```

`theorem`, `lemma`, `proposition`, `corollary`, `definition` and `example` share one count. Make another kind
with `theorem-kind`:

```typ
#let conjecture = theorem-kind("conjecture", "Conjecture")
#conjecture(title: [Goldbach])[Every even number above 2 is a sum of two primes.]
```

= Callouts

#callout(kind: "tip", title: [A tip])[Callouts are `"note"`, `"tip"` or `"warning"`.]

```typ
#callout(kind: "tip", title: [A tip])[Callouts are `"note"`, `"tip"` or `"warning"`.]
```

= Source files

`source-code(name, text)` shows a file's source under its name. Read it with Typst, so what's shown is the file
itself: `#source-code("torus_widget.py", read("examples/torus_widget.py"))`.

= Two layouts, two themes

`responsive(wide, narrow)` shows `wide` on wide screens and in PDFs and `narrow` on phones, such as an equation
broken over lines. `themed-image(name, description, ext: "png")` shows `name.png`, or `name-dark.png` in the dark
theme; in a PDF it shows its `print` argument.

= API references

`api(path)` documents a Python object from its docstring: its signature, description, parameters and members. Say
which modules in `tdg.toml`:

```toml
[api]
page = "reference"                                   # the page that documents them, for links between them
python = { paths = ["../src"], modules = ["mypackage"] }
```

```typ
#api("mypackage.Thing")                       // with its public members
#api("mypackage.Thing", members: ("load",))   // with some
#api("mypackage.helper", members: false)      // alone
```

tdg reads the modules with #link("https://mkdocstrings.github.io/griffe/")[griffe] when it builds the site.
Docstrings are Google style, and may use a little Markdown: `` `code` ``, `**strong**`, `*emphasis*`, links
(`[text](url)`, or `[text][mypackage.Thing]` to another object), lists, tables and code blocks. See
#link("https://frisbro303.github.io/wgw/reference/")[wgw's reference] for what it looks like.
