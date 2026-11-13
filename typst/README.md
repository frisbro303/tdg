# tdg

Interactive 3D figures, numbered theorems, callouts, source listings and API references, for Typst documents
compiled to **HTML or PDF**. Every function works in both: in HTML it emits elements that a site styles (and a
figure's widget runs, with [wgw](https://github.com/frisbro303/wgw)); in a PDF it lays out an equivalent.

It's the library of [tdg](https://github.com/frisbro303/tdg), which builds websites from Typst, but it works in
any document.

```typ
#import "@preview/tdg:0.1.0": *

#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
#proof[By inspection.]

#callout(kind: "tip", title: [Try it])[Drag the figure below.]

#widget(widget: "torus_widget.py", view: (-60, 35), still: image("torus.png"),
        caption: [A torus, colored by its Gaussian curvature.])
```

## Functions

| function | |
|---|---|
| `widget(widget:, src:, still:, caption:, up:, view:, pick:, flat:, height:, alt:, url:, credit:)` | an interactive 3D figure (wgw); in a PDF, its `still` |
| `theorem`, `lemma`, `proposition`, `corollary`, `definition`, `example` | numbered boxes, sharing one count: `#lemma(title: [...])[...]` |
| `theorem-kind(kind, name)` | another kind: `#let conjecture = theorem-kind("conjecture", "Conjecture")` |
| `proof(body, title:)` | a proof, ending in a square |
| `callout(body, kind:, title:)` | an aside: `"note"`, `"tip"` or `"warning"` |
| `source-code(name, text, lang:)` | a file's source under its name: `#source-code("x.py", read("x.py"))` |
| `responsive(wide, narrow)` | two layouts: `narrow` on phones, `wide` elsewhere and in PDFs |
| `themed-image(name, description, ext:, print:)` | an image with a dark-theme version (`name-dark.ext`); `print` in PDFs |
| `api(path, members:)` | a Python object's reference, from data tdg extracts from its docstrings |

HTML output needs Typst's HTML export (`typst compile --features html --format html`). Interactive figures need
wgw's script on the page, which tdg adds; see [its docs](https://frisbro303.github.io/tdg/typst/).
