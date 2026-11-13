#import "@local/tdg:0.2.0": *
#show: doc.with("index", title: "Overview", order: 1, description: "tdg: websites from Typst, built by typst compile.")

tdg makes websites from #link("https://typst.app")[Typst]: blogs, and documentation for software. It's a Typst
package, so a whole site, every page, its PDFs, its feed and its files, comes out of one `typst compile`, with no
other tools. Pages have Typst's math, which browsers show as MathML, and tdg's components: numbered theorems,
callouts, API references generated from Python docstrings, and interactive 3D figures.

#widget(path("examples/torus.wgw"), view: (-60, 35), caption: [A torus colored by its Gaussian curvature,
  $K = cos v \/ (r (R + r cos v))$, built by a widget in Rust. Drag it; move the sliders.])

This site is made by tdg, from #link("https://github.com/frisbro303/tdg/tree/main/docs")[these pages].

= Getting started

A site is a file that sets it up and includes its pages:

```typ
// site.typ
#import "@preview/tdg:0.2.0": *
#show: site.with(title: "My notes", author: "Me", url: "https://me.github.io/")

#include "posts/hopf/main.typ"
#include "about.typ"
```

Each page starts with what it is:

```typ
// posts/hopf/main.typ
#import "@preview/tdg:0.2.0": *
#show: post.with("hopf", title: "Hopf fibrations", date: "2026-11-03")

#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
```

Then build it with Typst 0.15 or later, whose bundle export writes the whole site:

```sh
typst compile --features html,bundle --format bundle site.typ _site
```

A page compiled on its own is a document of its own: `typst compile posts/hopf/main.typ` makes its PDF.

= What's here

- #link("/sites/")[Sites]: `site`, posts, pages and docs, and how files are published
- #link("/components/")[Components]: widgets, theorems, callouts, source listings, images, API references
- #link("/themes/")[Themes]: tdg's blog and docs themes, and your own
- #link("/building/")[Building]: compiling, watching, PDFs, and publishing to GitHub Pages
