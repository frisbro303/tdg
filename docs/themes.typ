#import "@local/tdg:0.2.0": *
#show: doc.with("themes", title: "Themes", order: 4, description: "tdg's blog and docs themes, and your own.")

A theme is how a site's pages are laid out as HTML: Typst functions that build each page's `<html>`, and a
stylesheet. tdg has two:

#table(
  columns: 2,
  [*theme*], [],
  [`"blog"`], [for writing: a serif text column, posts listed by date. The default.],
  [`"docs"`], [for software: sans-serif, a header across the page, a sidebar of pages and their contents. This site.],
)

= Your own look

The simplest way is CSS: keep a theme's layout, and add your stylesheet, or replace the theme's with yours:

```typ
#show: site.with(theme: "blog", css: (path("theme/style.css"),), theme-style: false)
```

A theme can also be a dictionary over a built-in one, replacing what it names: its `css` (a file in tdg's assets),
`fonts`, `layout` (a function from the site's settings, the page and its body to the page's `<html>`), or `home`
(the home page's list of posts).

```typ
#show: site.with(theme: (base: "blog", fonts: "https://fonts.googleapis.com/css2?family=Inter&display=swap"))
```

= Styling components

Every theme gets tdg's `components.css`, which lays out what the components make (theorems, callouts, API
references, the docs layout) with the theme's colors, as custom properties: `--bg`, `--text`, `--muted`,
`--line`, `--panel`, `--link`, `--accent`, `--mono` and `--width`. A stylesheet that sets these styles them all,
and the light and dark versions follow `data-theme` on `<html>`, which the theme switch sets.
