#import "@local/tdg:0.1.0": *
#set document(title: "Themes", description: "tdg's blog and docs themes, and making your own.")

A theme is how a site looks: its templates (the HTML around each page) and its static files (stylesheets,
scripts). tdg has two, and a site can have its own.

#table(
  columns: 2,
  [*theme*], [],
  [`blog`], [for writing: a serif text column, posts listed by date. The default.],
  [`docs`], [for software: sans-serif, a header across the page, a sidebar of pages and their contents. This site.],
)

```toml
[site]
theme = "docs"
```

= Your own theme

Set `theme` to a folder in your site, with either or both of:

- `templates/`: templates that replace tdg's, by name. Anything not there comes from tdg's base templates.
- `static/`: files published in `_tdg/`, beside (or replacing) tdg's. `static/style.css` is the theme's
  stylesheet.

```toml
[site]
theme = "theme"      # ./theme/templates/, ./theme/static/
```

To change a template or two of a built-in theme instead, put them in the site's `templates/` folder.

= Templates

Templates are #link("https://jinja.palletsprojects.com")[Jinja]. tdg's base templates are:

#table(
  columns: 2,
  [*template*], [],
  [`base.html`], [every page: `<head>`, the header, `main`, the footer],
  [`_head.html`, `_header.html`, `_footer.html`], [their parts],
  [`post.html`, `page.html`, `doc.html`], [an entry of each kind],
  [`home.html`], [the home page, listing posts],
)

They get `site` (the settings), `entry` (the page: `title`, `description`, `url`, `day`, `minutes`, `toc`), `body`
and `head` (Typst's output), `root` (the path back to the site's root), `link(href)` (a path from the site's root,
made relative), `posts` (on the home page), and, for docs, `docs`, `prev` and `next`.

= Styling tdg's components

Every theme gets `_tdg/components.css`, which lays out what the Typst library makes (theorems, callouts, API
references, the docs layout) using the theme's colors, as custom properties: `--bg`, `--text`, `--muted`,
`--line`, `--panel`, `--link`, `--accent`, `--mono` and `--width`. A theme that sets these gets them all for free,
and the light and dark versions follow `data-theme` on `<html>`, which the theme switch sets.
