// Sites: a site file, and the pages it includes, compiled into a website in one go:
//
//   typst compile --features html,bundle --format bundle site.typ _site
//
// site.typ sets up the site with `#show: site.with(...)` and includes its pages. Each page starts with a template,
// `#show: blog.post.with(...)`: a kind of page, made by `template(...)`, which says where its pages go, what
// settings they take, and how they look. A theme is a module of templates: tdg's (themes/), or a site's own.
// Compiled on its own, a page is a document of its own.

#import "util.typ": *
#import "layout.typ": page-layout

#let _site = state("tdg-site", none)

// What a bundle compile makes: the site's HTML pages and files, or (with `--input tdg=pdf`) its pages' PDFs. They're
// two compiles because a page in both would have each of its labels twice, which Typst doesn't allow.
#let _pdfs() = sys.inputs.at("tdg", default: "site") == "pdf"

// A page's author: its own, or the site's.
#let _author(author) = if author != auto { author } else {
  let site = _site.get()
  if site != none { site.author } else { none }
}


#let _defaults = (
  title: "", author: none, lang: "en", url: none, description: none,
  css: (), js: (), icon: none,
  nav: (), footer: none, credit: true, search: false, feed: none,
)

#let _assets = ("components.css", "website.css", "blog.css", "docs.css", "theme.js", "tdg.svg", "search.js")
#let _wgw = ("wgw.js", "io.js", "patch.js", "widget.js", "widget-worker.js", "style.js", "logo.svg", "core/wgw_core.js",
  "core/wgw_core_bg.wasm")

#let _escape(s) = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

#let _feed(site, pages) = {
  let base = site.url.trim("/", at: end) + "/"
  let entries = pages.map(p => {
    let updated = p.at("updated", default: none)
    "<entry><title>" + _escape(p.title) + "</title><link href=\"" + base + p.url + "\"/><id>" + base + p.url + "</id>"
    "<published>" + p.date.display() + "T00:00:00Z</published>"
    "<updated>" + (if updated != none { updated } else { p.date }).display() + "T00:00:00Z</updated>"
    if p.description != none { "<summary>" + _escape(p.description) + "</summary>" }
    "</entry>"
  }).join()
  let updated = if pages.len() > 0 { pages.first().date.display() } else { datetime.today().display() }
  ("<?xml version=\"1.0\" encoding=\"utf-8\"?><feed xmlns=\"http://www.w3.org/2005/Atom\">"
    + "<title>" + _escape(site.title) + "</title><link href=\"" + base + "\"/><id>" + base + "</id>"
    + "<updated>" + updated + "T00:00:00Z</updated><author><name>" + _escape(if site.author != none { site.author } else { site.title }) + "</name></author>"
    + if entries != none { entries } else { "" } + "</feed>")
}

// The site's pages of one kind, newest first when they're dated, and otherwise by title.
#let _pages(kind) = {
  let pages = query(<tdg-page>).map(m => m.value).filter(p => p.kind == kind)
  if pages.len() > 0 and pages.all(p => type(p.at("date", default: none)) == datetime) {
    pages.sorted(key: p => (p.date, p.url)).rev()
  } else {
    pages.sorted(key: p => (p.title, p.url))
  }
}

// Counters start afresh on each page (figures, theorems, equations), as each is a document of its own.
#let _fresh(body) = {
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(math.equation).update(0)
  counter(heading).update(0)
  counter(figure.where(kind: "tdg-theorem")).update(0)
  body
}

/// A website: its settings, and the pages it includes. Use as `#show: site.with(title: "...", ...)` in a site file.
///
/// - title (str): The site's name.
/// - author (str, none): For the footer, the feed and pages that don't name their own.
/// - url (str, none): Where the site is published; needed for a feed.
/// - feed (str, none): A kind of page to publish as an Atom feed, feed.xml, such as "post": its pages need a `date`.
/// - icon (path, none): An image for the header and the browser's tab.
/// - css, js (array): Stylesheets and scripts for every page, after its template's: paths, or URLs.
/// - nav (array): The header's links: `(("about", "about/"), ("GitHub", "https://..."))`, from the site's root.
/// - footer (dictionary, none): `(links: (github: "https://..."))`, and a line `(copyright: "...")` if you want one.
/// - credit (bool): A small "tdg-built website" link in the footer.
/// - search (bool): A search box on pages whose template is searchable, such as docs.
/// - files (array): Other files to publish, as paths (data a widget reads, downloads, ...).
#let site(..settings, files: (), body) = {
  for name in settings.named().keys() {
    assert(name in _defaults, message: "a site has no setting `" + name + "`" + if name in ("theme", "theme-style", "fonts") {
      ": a page's look is its template's (`css`, `fonts`, `layout`), and a theme is a module of templates"
    } else if name == "home" { ": make the home page a page of its own, with a #listing of its posts" } else { "" })
  }
  let site = _defaults + settings.named()
  _site.update(site)
  body
  if _pdfs() { return }

  context {
    if site.feed != none {
      assert(site.url != none, message: "a feed needs the site's url")
      let pages = _pages(site.feed)
      assert(pages.all(p => type(p.at("date", default: none)) == datetime),
        message: "a feed's pages need a date: " + site.feed + " pages don't all have one")
      asset("feed.xml", _feed(site, pages))
    }
    if site.search {  // what search.js searches: each searchable page's title and text
      let pages = query(<tdg-search>).map(m => {
        // with what generated parts of the page (API references) add
        let start = query(<tdg-start>).find(s => s.value == m.value.url)
        let end = query(<tdg-end>).find(s => s.value == m.value.url)
        let extra = if start != none and end != none {
          query(selector(<tdg-search-text>).after(start.location()).before(end.location())).map(e => e.value).join(" ")
        }
        m.value + (text: m.value.text + if extra != none { " " + extra } else { "" })
      })
      asset("_tdg/search.json", json.encode(pages, pretty: false))
    }
  }

  // Files: tdg's own, the site's, and those its pages publish.
  for name in _assets { asset("_tdg/" + name, read("../assets/" + name, encoding: none)) }
  context if query(<tdg-widget>).len() > 0 {
    for name in _wgw { asset("_tdg/wgw/" + name, read("../assets/wgw/" + name, encoding: none)) }
  }
  for file in (site.css, site.js, (site.icon,), files).flatten() { publish(file) }
  context {
    let seen = ()
    for m in query(<tdg-asset>) {
      if m.value.out not in seen {
        seen.push(m.value.out)
        asset(m.value.out, read(m.value.path, encoding: none))
      }
    }
  }
}

/// A date from a `datetime` or a "YYYY-MM-DD" string, for templates' date settings (in their `prepare`).
#let to-date(date) = if type(date) == datetime { date } else if type(date) == str {
  let (y, m, d) = date.split("-").map(int)
  datetime(year: y, month: m, day: d)
} else { panic("a date is a datetime or \"YYYY-MM-DD\", not " + repr(date)) }

// One page of the site: its HTML document (and PDF), when the site is built; or the page itself, compiled alone.
// `look` is how its template lays it out: its stylesheets, fonts and layout, main content, PDF header, body class
// and footer.
#let _page(page, look, body) = context {
  let page = page + (author: _author(page.author))
  page-css.update(look.css)
  if target() != "bundle" {
    (look.pdf-header)(page)
    body
  } else if not _pdfs() {
    let site = _site.get()
    if site == none { site = _defaults }
    let page = page + (tab-title: (look.tab-title)(site, page), class: look.class, footer: look.footer,
      css: look.css, fonts: look.fonts)
    for css in look.css { publish(css) }
    let main = if look.main != none { (look.main)(site, page, body) } else {
      (look.header)(page)
      html.elem("article", body)
    }
    [#metadata(page.url) <tdg-start>]
    document(page.url + "index.html", title: page.title, description: page.description)[
      #page-url.update(page.url)
      #_fresh((look.layout)(site, page, main))
    ]
    [#metadata(page.url) <tdg-end>]
  } else if page.pdf {
    document(page.url + page.slug + ".pdf", format: "pdf", title: page.title, description: page.description,
      author: if page.author != none { page.author } else { () })[
      #set std.page(..page.pdf-page)  // set here: Typst allows page set rules only at a document's top
      #_fresh[#(look.pdf-header)(page) #body]
    ]
  }
}

/// A kind of page: where its pages go, what settings they take beyond the ones every page has (title, description,
/// author, pdf, pdf-page), and how they look. It gives a function to start a page with:
///
///   #let note = template("note", ..blog.look, url: slug => "notes/" + slug + "/", fields: (topic: none))
///   #show: note.with("tori", title: "Tori", topic: "geometry")
///
/// A theme is a module of templates sharing a look, such as tdg's `blog`, whose `blog.look` a template can start
/// from: `..(blog.look + (css: (path("style.css"),)))`.
///
/// A page's settings, with its kind, slug and url, are what `header`, `main` and `pdf-header` get as `page`, and
/// what listings and feeds of its kind see.
///
/// - kind (str): Its name, which listings (`#listing("note")`) and the site's `feed` use.
/// - url (function): Its URL from its slug, from the site's root and ending in "/" (or "" for the front page).
/// - fields (dictionary): Its own settings, with their defaults.
/// - required (array): Which of its settings a page must give.
/// - prepare (function): From the page's settings to the ones used, to check them or convert them (as `to-date`).
/// - header (function): From the page to HTML above its body, such as its title.
/// - main (function, none): From the site, the page and its body to the whole of the page's <main>, instead of
///   `header` and the body.
/// - pdf-header (function): From the page to what's above its body in its PDF.
/// - pdf (bool): Whether its pages are also PDFs by default, <url><slug>.pdf.
/// - footer (bool): Whether its pages have the site's footer.
/// - css (array): Its stylesheets: tdg's (from its themes' looks, as `blog.look.css`), paths, or URLs. Every page
///   also has tdg's components.css, before them.
/// - fonts (str, none): A stylesheet URL for web fonts.
/// - layout (function): From the site's settings, the page and its <main> to the page's <html>: tdg's
///   `page-layout`, or your own.
/// - class (str, none): A class for its pages' <body>, for its stylesheets.
/// - search (bool): Whether its pages are in the site's search.
/// - tab-title (function): From the site and the page to the browser tab's title.
#let template(
  kind,
  url: slug => if slug == "index" { "" } else { slug + "/" },
  fields: (:),
  required: (),
  prepare: page => page,
  header: page => html.elem("h1", page.title),
  main: none,
  pdf-header: page => none,
  pdf: false,
  footer: true,
  class: none,
  search: false,
  tab-title: (site, page) => page.title,
  css: (),
  fonts: none,
  layout: page-layout,
) = {
  let make-url = url
  let pdf-default = pdf
  let look = (header: header, main: main, pdf-header: pdf-header, footer: footer, class: class, tab-title: tab-title,
    css: css, fonts: fonts, layout: layout)
  (slug, title: none, description: none, author: auto, pdf: auto, pdf-page: (:), ..settings, body) => {
    assert(settings.pos().len() == 0, message: "a " + kind + " takes its slug, then named settings")
    assert(title != none, message: "a " + kind + " needs a title")
    for name in settings.named().keys() {
      assert(name in fields, message: "a " + kind + " has no setting `" + name + "`")
    }
    for name in required {
      assert(name in settings.named(), message: "a " + kind + " needs `" + name + "`")
    }
    let page = prepare((kind: kind, slug: slug, url: make-url(slug), title: title, description: description,
      author: author, pdf: if pdf == auto { pdf-default } else { pdf }, pdf-page: pdf-page) + fields + settings.named())
    [#metadata(page) <tdg-page>]
    if search {
      [#metadata((url: page.url, title: page.title, text: plain-text(body).replace(regex("\s+"), " ").trim())) <tdg-search>]
    }
    _page(page, look, body)
  }
}

/// The site's pages of one kind, as links: newest first when they have dates, and otherwise by title. Put it on the
/// home page, for example: `#listing("post")`.
///
/// - kind (str): The kind of page, as its template names it.
/// - item (function, auto): From a page to how it's listed; by default, its date, title and description.
#let listing(kind, item: auto) = context {
  let pages = _pages(kind)
  if target() == "html" {
    html.elem("div", attrs: (class: "listing"), for page in pages {
      if item != auto { item(page) } else {
        html.elem("a", attrs: (class: "row", href: relative(page.url, page-url.get())))[
          #let date = page.at("date", default: none)
          #if type(date) == datetime { html.elem("time", attrs: (datetime: date.display()), date.display()) }
          #html.elem("div")[
            #html.elem("h3", page.title)
            #if page.description != none { html.elem("p", page.description) }
          ]
        ]
      }
    })
  } else {
    list(..pages.map(page => if item != auto { item(page) } else { page.title }))
  }
}

/// A page's title for its PDF, and for dated pages their author, date and when they were last updated.
#let pdf-title(page) = {
  let date = page.at("date", default: none)
  let updated = page.at("updated", default: none)
  align(center, block(below: 1.8em)[
    #text(1.7em, weight: "bold", page.title)
    #if date != none {
      linebreak()
      v(0.2em)
      let long = d => d.display("[month repr:long] [day padding:none], [year]")
      let parts = (page.author, long(date), if updated != none [updated #long(updated)]).filter(x => x != none)
      text(0.9em, fill: luma(100), parts.join[ · ])
    }
  ])
}
