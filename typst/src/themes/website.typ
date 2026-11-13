// The website theme: for a site of pages, such as a personal site. Its look, a serif text column, and two
// templates: `standalone`, a page, and `home`, a front page. A theme is just this: templates sharing a look.

#import "../site.typ": template
#import "../layout.typ": looks

/// Its look, which its templates share: their stylesheets, fonts and layout. Start your own templates from it with
/// `template(..website.look, ...)`.
#let look = looks.website

/// A page, such as an about page or a CV: no footer; it lays out its own headings. The slug "index" is the site's
/// front page. Use as `#show: website.standalone.with("cv", title: "CV")`.
#let standalone = template("page", ..look, header: page => none, footer: false)

/// A front page with the theme's home styling and no title of its own, for an introduction and listings
/// (`#listing("post")`). Use as `#show: website.home.with("index", title: "My site")`.
#let home = template("home", ..look, url: slug => "", main: (site, page, body) => body, class: "home")
