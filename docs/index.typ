#import "@local/tdg:0.1.0": *
#set document(title: "Overview", description: "tdg builds websites from Typst: blogs and software docs, with math, theorems and interactive 3D widgets.")

tdg builds websites from #link("https://typst.app")[Typst]: blogs, and documentation for software. Pages are
Typst files, so they have Typst's math, which browsers show as MathML; and tdg's Typst library adds numbered
theorems, callouts, API references generated from docstrings, and interactive 3D figures.

#widget(widget: "/examples/torus_widget.py", view: (-60, 35), caption: [A torus colored by its Gaussian curvature,
  $K = cos v \/ (r (R + r cos v))$, built by a Python widget. Drag it; move the sliders.])

This site is built by tdg too, from #link("https://github.com/frisbro303/tdg/tree/main/docs")[these pages].

= Getting started

tdg needs Python 3.11 or later and #link("https://github.com/typst/typst#installation")[Typst] 0.15 or later.

```sh
pip install git+https://github.com/frisbro303/tdg
```

A site is a folder with a `tdg.toml` and its pages:

```toml
# tdg.toml
[site]
title = "My notes"

[[sections]]
dir = "posts"
kind = "post"
url = "posts"
```

```typ
// posts/hello.typ
#import "@local/tdg:0.1.0": *
#set document(title: "Hello", description: "A first post.")

Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.
#theorem(title: [Hopf])[...]
```

```sh
tdg serve    # http://localhost:8000, rebuilt and reloaded as you edit
tdg build    # the site, in _site/
```

= What's here

- #link("/sites/")[Sites]: `tdg.toml`, sections of posts, pages and docs, and how files are published
- #link("/typst/")[The Typst library]: widgets, theorems, callouts, API references, and more
- #link("/themes/")[Themes]: tdg's blog and docs themes, and making your own
- #link("/commands/")[Commands]: building, serving, and publishing to GitHub Pages
