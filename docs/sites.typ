#import "@local/tdg:0.1.0": *
#show: docs.doc.with("sites", title: "Sites", order: 2, description: "A tdg site: its settings, its pages and their templates, and its files.")

= The site file

A site is a Typst file that sets it up with `site` and includes its pages, in any order:

```typ
#import "@preview/tdg:0.1.0": *
#show: site.with(
  title: "Endless Quest",
  author: "Felix",
  url: "https://example.com/",
  feed: "post",                                // posts' Atom feed, feed.xml
  icon: path("theme/icon.png"),
  nav: (("blog", ""), ("about", "about/"), ("GitHub", "https://github.com/me")),
  footer: (links: (email: "mailto:me@example.com")),
)

#include "index.typ"
#include "posts/hopf-fibrations/main.typ"
#include "posts/diffusion-maps/main.typ"
#include "about.typ"
```

#table(
  columns: 2,
  [*setting*], [],
  [`title`], [the site's name],
  [`author`], [pages' author (unless a page names its own), and the feed's],
  [`url`], [where the site is published, which a feed needs],
  [`feed`], [a kind of page to publish as an Atom feed, `feed.xml`, such as `"post"`: its pages need a `date`],
  [`icon`], [an image for the header and the browser's tab, as a path],
  [`css`, `js`], [stylesheets and scripts for every page, after its template's: paths, or URLs],
  [`nav`], [the header's links: `(label, href)` pairs, `href` from the site's root, or a full URL],
  [`footer`], [`(links: (label: url))`, and `copyright: "..."` for a © line],
  [`credit`], [a small "tdg-built website" link in the footer's corner; `false` hides it],
  [`search`], [a search box in the docs' sidebar, searching pages whose template is searchable],
  [`files`], [other files to publish, as paths: downloads, data, ...],
)

= Pages

Each page starts with a template: a show rule saying what kind of page it is. Its slug gives its URL. Every
template takes `title`, `description`, `author` (by default the site's), `pdf` (also publish it as a PDF,
`<url><slug>.pdf`) and `pdf-page` (its PDF's page settings, such as `(margin: 2cm)`), and its own settings.
tdg's #link("/themes/")[themes] are templates:

#table(
  columns: 3,
  [*template*], [*URL*], [],
  [`blog.post.with(slug, title:, date:, updated:)`], [`posts/<slug>/`],
    [dated, with its author, and also a PDF linked under its title; `date` and `updated` are `"YYYY-MM-DD"` or a `datetime`],
  [`website.home.with(slug, title:)`], [the front page], [the site's home page, with no title of its own, for an introduction and listings],
  [`website.standalone.with(slug, title:)`], [`<slug>/`, or the front page for `"index"`], [a page such as an about page or a CV: no footer; it lays out its own headings],
  [`docs.doc.with(slug, title:, order:)`], [`<slug>/`, or the front page for `"index"`], [documentation: a sidebar in `order`, previous and next links, the page's contents, and search],
)

The blog theme has the website theme's templates too (`blog.home`, `blog.standalone`), and the docs theme a
`standalone` of its own.

= Listings

`listing(kind)` lists the site's pages of a kind as links, newest first when they have a `date`, and otherwise by
title. A blog's home page is a page with its posts:

```typ
// index.typ
#import "@preview/tdg:0.1.0": *
#show: blog.home.with("index", title: "Endless Quest")

= blog
#listing("post")
```

`item:` lists each page your own way: a function from the page's settings (`page.title`, `page.url`,
`page.date`, ...) to content.

= Your own templates

`template(kind, ...)` makes a kind of page: where its pages go, the settings they take, and how they look. A site
keeps its own in a file its pages import, which is its own #link("/themes/")[theme]:

```typ
#let note = template("note", ..blog.look,                     // the blog theme's look
  url: slug => "notes/" + slug + "/",                          // its URL from its slug
  fields: (topic: none, date: none),                          // its own settings, with defaults
  required: ("topic",),                                       // which a page must give
  prepare: page => page + (date: if page.date != none { to-date(page.date) }),  // to check or convert them
  header: page => html.elem("h1", page.title + " · " + page.topic),            // HTML above its body
  pdf-header: pdf-title,                                      // what's above its body in its PDF
)

#show: note.with("tori", title: "Tori", topic: "geometry")
```

#table(
  columns: 2,
  [*setting*], [],
  [`url`], [a function from the slug to the page's URL from the site's root; by default `<slug>/`, and `""` (the front page) for `"index"`],
  [`fields`, `required`], [the template's own settings with their defaults, and which a page must give],
  [`prepare`], [a function from the page's settings to the ones used: `to-date` turns `"YYYY-MM-DD"` into a `datetime`],
  [`header`], [a function from the page to the HTML above its body; by default its title as `<h1>`],
  [`main`], [a function from the site, the page and its body to the whole of `<main>`, instead of `header` and the body],
  [`pdf-header`], [a function from the page to what's above its body in its PDF: `pdf-title` is its title, and for dated pages their author and date],
  [`pdf`], [whether its pages are also PDFs, unless a page says otherwise],
  [`footer`], [whether its pages have the site's footer],
  [`class`], [a class for its pages' `<body>`, for stylesheets],
  [`search`], [whether its pages are in the site's search],
  [`tab-title`], [a function from the site and the page to the browser tab's title],
  [`css`], [its stylesheets: tdg's (from its themes' looks, as `blog.look.css`), paths, or URLs; every page also has tdg's `components.css`],
  [`fonts`], [a stylesheet URL for web fonts],
  [`layout`], [a function from the site, the page and its `<main>` to the page's `<html>`: tdg's `page-layout`, or your own],
)

The page these functions get is its settings, with `kind`, `slug` and `url`: the same dictionary a listing's
`item` gets. tdg's own templates are made this way (`typst/src/themes/`), and their parts can be borrowed:
`post-header` (a dated page's title, date and PDF link), `pdf-title` and `docs-main` (the docs' layout).

= Files

A site's files are published at the same place they have in the project: `posts/hopf/figures/hook.gif` is served
at `<site>/posts/hopf/figures/hook.gif`. Components publish what they're given as paths, such as
`widget(path("torus.wgw"))`, so a page's files come along without being listed; `site(files: ...)`
publishes others. Strings are used as URLs, as they are.

= Links

In a page, a link to `/sites/` is from the site's root; tdg makes it relative, so a site works at any address, such
as `https://you.github.io/project/`.
