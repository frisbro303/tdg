#import "@local/tdg:0.2.0": *
#show: doc.with("sites", title: "Sites", order: 2, description: "A tdg site: its settings, its pages, and its files.")

= The site file

A site is a Typst file that sets it up with `site` and includes its pages, in any order:

```typ
#import "@preview/tdg:0.2.0": *
#show: site.with(
  title: "Endless Quest",
  author: "Felix",
  url: "https://example.com/",                 // gives posts a feed
  icon: path("theme/icon.png"),
  nav: (("blog", ""), ("about", "about/"), ("GitHub", "https://github.com/me")),
  footer: (links: (email: "mailto:me@example.com")),
)

#include "posts/hopf-fibrations/main.typ"
#include "posts/diffusion-maps/main.typ"
#include "about.typ"
```

#table(
  columns: 2,
  [*setting*], [],
  [`title`], [the site's name],
  [`theme`], [`"blog"` (the default) or `"docs"`, or your own: see #link("/themes/")[themes]],
  [`author`], [posts' author (unless a post names its own), and the feed's],
  [`url`], [where the site is published: gives posts an Atom feed, `feed.xml`],
  [`icon`], [an image for the header and the browser's tab, as a path],
  [`css`, `js`], [the site's own stylesheets and scripts: paths, or URLs],
  [`theme-style`], [`false` to use only the site's stylesheets, not the theme's],
  [`fonts`], [a stylesheet URL for web fonts, instead of the theme's],
  [`nav`], [the header's links: `(label, href)` pairs, `href` from the site's root, or a full URL],
  [`footer`], [`(links: (label: url))`, and `copyright: "..."` for a © line],
  [`home`], [a heading above the home page's posts],
  [`credit`], [a small "made with tdg" link in the footer's corner; `false` hides it],
  [`search`], [a search box in the docs' sidebar],
  [`files`], [other files to publish, as paths: downloads, data, ...],
)

= Pages

Each page starts with a show rule saying what it is. Its slug is its URL.

#table(
  columns: 3,
  [*template*], [*URL*], [],
  [`post.with(slug, title:, date:, author:, description:, pdf: true)`], [`posts/<slug>/`],
    [dated, with its author and a reading time, listed newest first on the home page and in the feed, and also published as a PDF linked under its title],
  [`standalone.with(slug, title:, pdf: false)`], [`<slug>/`], [a page that isn't a post, such as an about page or a CV: no date, no footer; it lays out its own headings],
  [`doc.with(slug, title:, order:, description:)`], [`<slug>/`, or the front page for `"index"`], [documentation: a sidebar in `order`, previous and next links, and the page's contents],
)

A post's `date` is a `datetime` or `"YYYY-MM-DD"`. The home page lists the posts, unless a doc called `index` is
the front page.

= Files

A site's files are published at the same place they have in the project: `posts/hopf/figures/hook.gif` is served
at `<site>/posts/hopf/figures/hook.gif`. Components publish what they're given as paths, such as
`widget(widget: path("torus_widget.py"))`, so a page's files come along without being listed; `site(files: ...)`
publishes others. Strings are used as URLs, as they are.

= Links

In a page, a link to `/sites/` is from the site's root; tdg makes it relative, so a site works at any address, such
as `https://you.github.io/project/`.
