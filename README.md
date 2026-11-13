<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/banner-dark.svg">
    <img src="assets/banner-light.svg" height="56" alt="tdg: Typst Docs Generator">
  </picture>
</h1>

Websites from [Typst](https://typst.app), built by `typst compile` alone: blogs, and documentation for software.
tdg is a Typst package: a site is a Typst file that includes its pages, and Typst's bundle export writes the whole
site, every page, its PDFs, its feed and its files. Pages have Typst's math, as MathML, and tdg's components:
numbered theorems, callouts, API references generated from Python docstrings, and interactive 3D figures
([wgw](https://github.com/frisbro303/wgw), built in).

tdg is in beta: its API still changes, without deprecations.

```typ
// site.typ
#import "@local/tdg:0.1.0": *
#show: site.with(title: "My notes", url: "https://me.github.io/", feed: "post")
#include "posts/hopf/main.typ"
```

```typ
// posts/hopf/main.typ
#import "@local/tdg:0.1.0": *
#show: blog.post.with("hopf", title: "Hopf fibrations", date: "2026-11-03")
#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
```

```sh
typst compile --features html,bundle --format bundle site.typ _site                    # the site
typst compile --features html,bundle --format bundle --input tdg=pdf site.typ _site    # and its PDFs
```

**Docs: https://frisbro303.github.io/tdg/**, built by tdg from [`docs/`](docs).

Until tdg is on Typst Universe, install it as a local package: link (or copy) this repository's `typst/` folder
to `<data>/typst/packages/local/tdg/0.1.0`, where `<data>` is `~/.local/share` on Linux and
`~/Library/Application Support` on macOS.

- `typst/`: the package: `lib.typ`, `src/` (sites, themes, components, API references), `assets/` (styles, wgw's
  runtime, the plugin), and `tests/run.sh`
- `plugin/`: the plugin that reads Python modules' API (Rust, built to `typst/assets/tdg.wasm`)
- `docs/`: the docs site
