#import "@local/tdg:0.1.0": *
#show: docs.doc.with("themes", title: "Themes", order: 4, description: "tdg's website, blog and docs themes, and your own.")

A theme is a Typst module of #link("/sites/#pages")[templates] that share a look: their stylesheets, fonts and
layout. Each template carries its look, so there's nothing to set on the site: a page's template decides how it
looks. tdg has three:

#table(
  columns: 3,
  [*theme*], [*templates*], [],
  [`website`], [`home`, `standalone`], [for a site of pages, such as a personal site: a serif text column (`website.css`)],
  [`blog`], [`post`, `home`, `standalone`], [for writing: the website theme's look with posts' headers (`blog.css` after `website.css`), and dated posts with PDFs; list them on the home page with `#listing("post")`],
  [`docs`], [`doc`, `standalone`], [for software: sans-serif, a header across the page, a sidebar of pages and their contents, and search. This site.],
)

= Your own theme

A theme of your own is a file of templates, such as `theme.typ`, which your pages import. Each theme has its look
as a dictionary, `blog.look`, to start from: here the blog's, with your stylesheet instead of its:

```typ
// theme.typ
#import "@preview/tdg:0.1.0": *

#let look = blog.look + (css: (path("style.css"),))

#let post = template("post", ..look,
  url: slug => "posts/" + slug + "/",
  fields: (date: none), required: ("date",),
  prepare: page => page + (date: to-date(page.date)),
  header: post-header, pdf-header: pdf-title, pdf: true,
)
#let home = template("home", ..look, url: slug => "", main: (site, page, body) => body, class: "home")
```

```typ
// posts/hopf/main.typ
#import "/theme.typ": *
#show: post.with("hopf", title: "Hopf fibrations", date: "2026-11-03")
```

A look is three things, which every template takes:

#table(
  columns: 2,
  [*setting*], [],
  [`css`], [its stylesheets: paths (published with the site), URLs, or tdg's own, from its themes' looks: `blog.look.css + (path("extra.css"),)` adds yours after the blog's],
  [`fonts`], [a stylesheet URL for web fonts, or `none`],
  [`layout`], [a function from the site's settings, the page and its `<main>` to the page's `<html>`: tdg's `page-layout`, or your own, from tdg's `head`, `header` and `footer`],
)

tdg's themes are written this way, in `typst/src/themes/`.

= Styling components

Every page gets tdg's `components.css`, which lays out what the components make (theorems, callouts, API
references, the docs layout) with the page's colors, as custom properties: `--bg`, `--text`, `--muted`,
`--line`, `--panel`, `--link`, `--accent`, `--mono` and `--width`. A stylesheet that sets these styles them all,
and the light and dark versions follow `data-theme` on `<html>`, which the theme switch sets.
