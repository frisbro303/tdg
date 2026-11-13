# tdg

Websites from Typst, built by `typst compile` alone, and the components their pages are made of: interactive 3D
figures, numbered theorems, callouts, source listings, themed images and API references generated from Python
docstrings. Every component works in HTML and in PDF. tdg is in beta: its API still changes.

```typ
// site.typ
#import "@preview/tdg:0.1.0": *
#show: site.with(title: "My notes", url: "https://me.github.io/", feed: "post")
#include "posts/hopf/main.typ"
```

```typ
// posts/hopf/main.typ
#import "@preview/tdg:0.1.0": *
#show: blog.post.with("hopf", title: "Hopf fibrations", date: "2026-11-03")

#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.] <thm:hopf>
#widget(widget: path("torus_widget.py"), view: (-60, 35), still: image("torus.png"), caption: [A torus.])
```

```sh
typst compile --features html,bundle --format bundle site.typ _site                    # the site
typst compile --features html,bundle --format bundle --input tdg=pdf site.typ _site    # and its PDFs
```

| | |
|---|---|
| `site.with(title:, url:, feed:, nav:, footer:, icon:, search:, ...)` | a site: its settings, feed and files |
| `website`, `blog`, `docs` | themes, modules of templates: `blog.post.with(slug, title:, date:)`, `website.home`, `docs.doc`, ... |
| `template(kind, url:, fields:, header:, css:, ...)` | a template of your own: a kind of page and its look |
| `listing(kind)` | the site's pages of a kind, as links: a blog's posts |
| `widget(widget:, src:, data:, still:, caption:, ...)` | an interactive 3D figure; in a PDF, its `still` |
| `theorem`, `lemma`, `definition`, ..., `theorem-kind`, `proof` | numbered, referenceable boxes |
| `callout`, `source-code`, `responsive`, `themed-image` | asides, files' sources, two layouts, two themes |
| `python-api(source, module:)`, `api(data, path)` | a Python module's reference, read by tdg's plugin |

Docs: https://frisbro303.github.io/tdg/
