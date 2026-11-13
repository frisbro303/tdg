// Sites: a site file, and the pages it includes, compiled into a website in one go:
//
//   typst compile --features html,bundle --format bundle site.typ _site
//
// site.typ sets up the site with `#show: site.with(...)` and includes its pages; each page starts with
// `#show: post.with(...)`, `page.with(...)` or `doc.with(...)`. Compiled on its own, a page is a document of its own.

#import "util.typ": *
#import "themes.typ": themes

#let _site = state("tdg-site", none)

// What a bundle compile makes: the site's HTML pages and files, or (with `--input tdg=pdf`) its pages' PDFs. They're
// two compiles because a page in both would have each of its labels twice, which Typst doesn't allow.
#let _pdfs() = sys.inputs.at("tdg", default: "site") == "pdf"

#let _defaults = (
  title: "", author: none, lang: "en", url: none, description: none,
  theme: "blog", theme-style: true, fonts: none, css: (), js: (), icon: none,
  nav: (), footer: none, home: none, credit: true, search: false,
)

#let _assets = ("components.css", "blog.css", "docs.css", "theme.js", "tdg.svg", "search.js")
#let _wgw = ("wgw.js", "io.js", "patch.js", "runners.js", "style.js", "python-worker.js", "wgw.py", "logo.svg",
  "core/wgw_core.js", "core/wgw_core_bg.wasm")

#let _escape(s) = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

#let _feed(site, posts) = {
  let base = site.url.trim("/", at: end) + "/"
  let entries = posts.map(p => {
    "<entry><title>" + _escape(p.title) + "</title><link href=\"" + base + p.url + "\"/><id>" + base + p.url + "</id>"
    "<updated>" + p.date.display() + "T00:00:00Z</updated>"
    if p.description != none { "<summary>" + _escape(p.description) + "</summary>" }
    "</entry>"
  }).join()
  let updated = if posts.len() > 0 { posts.first().date.display() } else { datetime.today().display() }
  ("<?xml version=\"1.0\" encoding=\"utf-8\"?><feed xmlns=\"http://www.w3.org/2005/Atom\">"
    + "<title>" + _escape(site.title) + "</title><link href=\"" + base + "\"/><id>" + base + "</id>"
    + "<updated>" + updated + "T00:00:00Z</updated><author><name>" + _escape(if site.author != none { site.author } else { site.title }) + "</name></author>"
    + if entries != none { entries } else { "" } + "</feed>")
}

/// A website: its settings, and the pages it includes. Use as `#show: site.with(title: "...", ...)` in a site file.
///
/// - title (str): The site's name.
/// - theme (str, dictionary): "blog" or "docs", or a theme of your own (see the docs).
/// - author (str, none): For the footer and the feed.
/// - url (str, none): Where the site is published; gives posts a feed.
/// - icon (path, none): An image for the header and the browser's tab.
/// - css, js (array): The site's own stylesheets and scripts: paths, or URLs.
/// - theme-style (bool): Whether to use the theme's stylesheet (with `css` as well), or only the site's.
/// - fonts (str, none): A stylesheet URL for web fonts, instead of the theme's.
/// - nav (array): The header's links: `(("about", "about/"), ("GitHub", "https://..."))`, from the site's root.
/// - footer (dictionary, none): `(copyright: "...", links: (github: "https://..."))`.
/// - home (str, none): A heading above the home page's posts.
/// - credit (bool): A small "made with tdg" link in the footer.
/// - search (bool): A search box in docs.
/// - files (array): Other files to publish, as paths (data a widget reads, downloads, ...).
#let site(..settings, files: (), body) = {
  let site = _defaults + settings.named()
  let theme = if type(site.theme) == str { themes.at(site.theme) } else { themes.at(site.theme.at("base", default: "blog")) + site.theme }
  site.theme = theme
  _site.update(site)
  body
  if _pdfs() { return }

  // The home page: the posts, newest first (unless a page of the site is its home).
  context {
    let posts = query(<tdg-post>).map(m => m.value).sorted(key: p => (p.date, p.url)).rev()
    let homes = query(<tdg-start>).filter(m => m.value == "")
    if posts.len() > 0 and homes.len() == 0 {
      let page = (kind: "home", url: "", title: site.title, description: site.description, slug: "")
      document("index.html", title: site.title)[
        #page-url.update("")
        #(theme.layout)(site, page, theme, (theme.home)(site, posts))
      ]
    }
    if site.url != none and posts.len() > 0 { asset("feed.xml", _feed(site, posts)) }
    if site.search {  // what search.js searches: each doc's title and text
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

#let _date(date) = if type(date) == datetime { date } else if type(date) == str {
  let (y, m, d) = date.split("-").map(int)
  datetime(year: y, month: m, day: d)
} else { panic("a post's date is a datetime or \"YYYY-MM-DD\", not " + repr(date)) }

// Counters start afresh on each page (figures, theorems, equations), as each is a document of its own.
#let _fresh(body) = {
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(math.equation).update(0)
  counter(heading).update(0)
  counter(figure.where(kind: "tdg-theorem")).update(0)
  body
}

// One page of the site: its HTML document (and PDF), when the site is built; or the page itself, compiled alone.
#let _page(page, pdf-header, body) = context if target() != "bundle" {
  pdf-header
  body
} else if not _pdfs() {
  let site = _site.get()
  if site == none { site = _defaults + (theme: themes.blog) }
  [#metadata(page.url) <tdg-start>]
  document(page.url + "index.html", title: page.title, description: page.description)[
    #page-url.update(page.url)
    #_fresh((site.theme.layout)(site, page, site.theme, body))
  ]
  [#metadata(page.url) <tdg-end>]
} else {
  if page.pdf {
    document(page.url + page.slug + ".pdf", format: "pdf", title: page.title, description: page.description)[
      #set std.page(..page.at("pdf-page", default: (:)))  // set here: Typst allows page set rules only at a document's top
      #_fresh[#pdf-header #body]
    ]
  }
}

// A PDF's title, and for posts their date and reading time, as on the web.
#let _pdf-header(title, date: none, minutes: none) = {
  align(center, block(below: 1.8em)[
    #text(1.7em, weight: "bold", title)
    #if date != none {
      linebreak()
      v(0.2em)
      text(0.9em, fill: luma(100))[#date.display("[month repr:long] [day padding:none], [year]")#if minutes != none [ · #minutes min read]]
    }
  ])
}

/// A post: dated, listed on the home page and in the feed, with a reading time and a PDF. Use as
/// `#show: post.with("hopf-fibrations", title: "...", date: "2026-11-03")` at the top of the post.
///
/// - slug (str): Its URL: posts/<slug>/.
/// - title (str): Its title.
/// - date (datetime, str): When it was published: a datetime, or "YYYY-MM-DD".
/// - description (str, none): A line about it, for the home page and search engines.
/// - pdf (bool): Also publish it as a PDF, posts/<slug>/<slug>.pdf, linked under its title.
/// - pdf-page (dictionary): Page settings for its PDF, such as `(margin: 2cm)`: Typst allows `set page` only at a
///   document's top, which a page's content isn't.
#let post(slug, title: none, date: none, description: none, pdf: true, pdf-page: (:), body) = {
  assert(title != none, message: "a post needs a title")
  assert(date != none, message: "a post needs a date, such as date: \"2026-11-03\"")
  let date = _date(date)
  let url = "posts/" + slug + "/"
  let words = plain-text(body).split().len()
  let page = (kind: "post", slug: slug, url: url, title: title, date: date, description: description, pdf: pdf,
    minutes: calc.max(1, calc.ceil(words / 200)), pdf-page: pdf-page)
  [#metadata((url: url, title: title, date: date, description: description)) <tdg-post>]
  _page(page, _pdf-header(title, date: date, minutes: page.minutes), body)
}

/// A page that isn't a post, such as an about page or a CV: no date, no footer; it lays out its own headings. Use
/// as `#show: standalone.with("cv", title: "CV")`.
#let standalone(slug, title: none, description: none, pdf: false, pdf-page: (:), body) = {
  assert(title != none, message: "a page needs a title")
  let url = slug + "/"
  _page((kind: "page", slug: slug, url: url, title: title, description: description, pdf: pdf, pdf-page: pdf-page), [], body)
}

/// A page of documentation: in the docs' sidebar, in order, with previous and next links and its contents. The
/// slug "index" is the site's front page. Use as `#show: doc.with("widgets", title: "Writing widgets", order: 3)`.
#let doc(slug, title: none, order: 0, description: none, pdf: false, body) = {
  assert(title != none, message: "a doc needs a title")
  let url = if slug == "index" { "" } else { slug + "/" }
  [#metadata((url: url, title: title, order: order)) <tdg-doc>]
  [#metadata((url: url, title: title, text: plain-text(body).replace(regex("\s+"), " ").trim())) <tdg-search>]
  _page((kind: "doc", slug: slug, url: url, title: title, description: description, pdf: pdf), _pdf-header(title), body)
}
