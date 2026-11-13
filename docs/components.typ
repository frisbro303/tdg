#import "@local/tdg:0.2.0": *
#show: doc.with("components", title: "Components", order: 3, description: "tdg's components: widgets, theorems, callouts, source listings, images, API references.")

Every component works in HTML (styled by the site's theme) and in PDF (laid out by Typst), so a page is both a web
page and a printable document.

= Widgets

`widget(...)` makes an interactive 3D figure, run by #link("https://github.com/frisbro303/wgw")[wgw], which tdg
bundles, from its `.wgw` file: a widget (a small WebAssembly module, written in Rust, with its data inside;
#link("https://frisbro303.github.io/wgw/widgets/")[writing widgets]), or a mesh (or an `.obj`). In a PDF it's the
figure's first frame: tdg runs the widget as a plugin, and wgw's own renderer draws it, with the page's shaders.

#widget(path("examples/torus.wgw"), view: (-60, 35), caption: [A torus.])

```typ
#widget(path("examples/torus.wgw"), view: (-60, 35), caption: [A torus.])
```

#table(
  columns: 2,
  [*argument*], [],
  [`src`], [the figure's file, first and unnamed: a `.wgw` widget or mesh, or an `.obj`, as a path (a URL string isn't drawn in PDFs)],
  [`caption`], [its caption; widgets are numbered with the other figures],
  [`up`], [the axis that points up: `"x"`, `"y"` or `"z"` (the default)],
  [`view`], [the starting camera, `(turn, tilt)` in degrees, and optionally a scale: `(turn, tilt, 1.5)`],
  [`pick`], [when a pick reaches the widget: `"click"` (the default), `"hover"` or `"none"`],
  [`flat`], [flat shading],
  [`height`], [the canvas's height, such as `360pt` or `"380px"`],
  [`alt`], [a description for screen readers; by default the caption's text],
  [`credit`], [a small "wgw" link in the corner; `false` hides it],
)

= Theorems and proofs

#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
#proof[By inspection.]

```typ
#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
#proof[By inspection.]
```

`theorem`, `lemma`, `proposition`, `corollary`, `definition` and `example` share one count. Make another kind with
`theorem-kind`: `#let conjecture = theorem-kind("conjecture", "Conjecture")`.

= Callouts

#callout(kind: "tip", title: [A tip])[Callouts are `"note"`, `"tip"` or `"warning"`.]

```typ
#callout(kind: "tip", title: [A tip])[Callouts are `"note"`, `"tip"` or `"warning"`.]
```

= Source files

`source-code(path("examples/plot.py"))` shows a file under its name, read by Typst, so what's shown is
the file itself.

= Two layouts, two themes

`responsive(wide, narrow)` shows `wide` on wide screens and in PDFs and `narrow` on phones, such as an equation
broken over lines. `themed-image(path("chart.png"), path("chart-dark.png"), [A chart.])` shows the dark version in
the dark theme; a PDF shows the light one.

= API references

`api(...)` documents a Python object from its source and docstring: its signature, description, parameters and
members. tdg's plugin, a small WebAssembly program in the package, reads the module's source, which the page passes
it:

```typ
#let pkg = python-api(read("/src/mypackage.py"), module: "mypackage", page: "reference")

#api(pkg, "mypackage.Thing")                       // with its public members
#api(pkg, "mypackage.Thing", members: ("load",))   // with some
#api(pkg, "mypackage.helper", members: false)      // alone
```

Docstrings are Google style (`Args:`, `Returns:`, `Attributes:`, ...), and may use a little Markdown: `` `code` ``,
`**strong**`, `*emphasis*`, links (`[text](url)`, or `[text][mypackage.Thing]` to another object on the `page`),
lists, tables and code blocks. See #link("https://frisbro303.github.io/wgw/reference/")[wgw's reference] for how
it looks.
