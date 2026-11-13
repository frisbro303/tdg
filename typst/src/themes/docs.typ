// The docs theme: for software's documentation. Its look, sans-serif, and `doc`, pages in a sidebar with their
// contents and in the site's search, and `standalone`, a page.

#import "../site.typ": template, pdf-title
#import "../layout.typ": looks, docs-main

/// Its look, which its templates share: their stylesheets, fonts and layout.
#let look = looks.docs

/// A page of documentation: in the docs' sidebar, in order, with previous and next links and its contents, and in
/// the site's search. The slug "index" is the site's front page. Use as
/// `#show: docs.doc.with("widgets", title: "Writing widgets", order: 3)`.
#let doc = template("doc", ..look,
  fields: (order: 0),
  main: docs-main,
  pdf-header: pdf-title,
  class: "docs",
  search: true,
  tab-title: (site, page) => if page.url == "" { page.title } else { page.title + " · " + site.title },
)

/// A page that isn't documentation: no sidebar, no footer; it lays out its own headings.
#let standalone = template("page", ..look, header: page => none, footer: false)
