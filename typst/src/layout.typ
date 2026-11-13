// Layout: how a site's pages are laid out as HTML. A template's look is its stylesheets, its fonts and a `layout`
// function from the site's settings, the page (with its look) and its <main> content to the page's <html>; tdg's
// is `page-layout`. What goes in <main> is the template's too (site.typ). Every page also gets
// assets/components.css, which lays out what the components make.

#import "util.typ": *

#let _moon = "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"
#let _sun = "M12 1v2m0 18v2M4.22 4.22l1.42 1.42m12.72 12.72 1.42 1.42M1 12h2m18 0h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"

#let _link(href) = {  // a link from the site's settings: from the site's root ("cv/"), or a full URL
  if href.contains(":") or href.starts-with("//") or href.starts-with("#") { href } else { root() + href.trim("/", at: start) }
}

/// The page's <head>: its title and description, its template's and the site's styles and scripts, and wgw's when
/// the page has a widget.
#let head(site, page) = context {
  let r = root()
  html.elem("head")[
    #html.elem("meta", attrs: (charset: "utf-8"))
    #html.elem("meta", attrs: (name: "viewport", content: "width=device-width, initial-scale=1"))
    #html.elem("title", page.at("tab-title", default: page.title))
    #if page.description != none { html.elem("meta", attrs: (name: "description", content: page.description)) }
    #if page.at("author", default: none) not in (none, auto) { html.elem("meta", attrs: (name: "author", content: page.author)) }
    #let fonts = page.at("fonts", default: none)
    #if fonts != none {
      if fonts.contains("fonts.googleapis.com") {
        html.elem("link", attrs: (rel: "preconnect", href: "https://fonts.googleapis.com"))
        html.elem("link", attrs: (rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: ""))
      }
      html.elem("link", attrs: (rel: "stylesheet", href: fonts))
    }
    #html.elem("link", attrs: (rel: "stylesheet", href: r + "_tdg/components.css"))
    #for css in page.at("css", default: ()) { html.elem("link", attrs: (rel: "stylesheet", href: css-url(css))) }
    #for css in site.css { html.elem("link", attrs: (rel: "stylesheet", href: file-url(css))) }
    #if site.icon != none { html.elem("link", attrs: (rel: "icon", href: file-url(site.icon))) }
    #html.elem("script", attrs: (src: r + "_tdg/theme.js"))
    #for js in site.js { html.elem("script", attrs: (src: file-url(js))) }
    #if query(<tdg-widget>).any(m => m.value == page.url) {
      html.elem("script", attrs: (type: "module", src: r + "_tdg/wgw/wgw.js"))
    }
    #if site.url != none and site.feed != none {
      html.elem("link", attrs: (rel: "alternate", type: "application/atom+xml", href: r + "feed.xml", title: site.title))
    }
    #if site.search and query(<tdg-search>).any(m => m.value.url == page.url) {
      html.elem("script", attrs: (type: "module", src: r + "_tdg/search.js"))
    }
  ]
}

#let _icon(class, d) = html.elem("svg", attrs: (class: class, viewBox: "0 0 24 24"), html.elem("path", attrs: (d: d)))

#let header(site) = context html.elem("header", attrs: (class: "site-header"))[
  #html.elem("a", attrs: (class: "logo", href: root()))[
    #html.elem("span", site.title)
    #if site.icon != none { html.elem("img", attrs: (src: file-url(site.icon), alt: "", width: "36", height: "36")) }
  ]
  #html.elem("nav", attrs: (class: "site-nav"), site.nav.map(((label, href)) => html.elem("a", attrs: (href: _link(href)), label)).join())
  #html.elem("button", attrs: (id: "theme-toggle", type: "button", aria-label: "Toggle dark mode"))[
    #html.elem("svg", attrs: (class: "moon", viewBox: "0 0 24 24"), html.elem("path", attrs: (d: _moon)))
    #html.elem("svg", attrs: (class: "sun", viewBox: "0 0 24 24"))[
      #html.elem("circle", attrs: (cx: "12", cy: "12", r: "5"))
      #html.elem("path", attrs: (d: _sun))
    ]
  ]
]

#let footer(site) = context if site.footer != none or site.credit {
  html.elem("footer", attrs: (class: "site-footer"))[
    #if site.footer != none {
      if "copyright" in site.footer { html.elem("div")[© #datetime.today().year() #site.footer.copyright] }
      html.elem("div", attrs: (class: "contact"),
        site.footer.at("links", default: (:)).pairs().map(((label, url)) => html.elem("a", attrs: (href: url), label)).join())
    }
    #if site.credit {
      html.elem("div", attrs: (class: "credit"), html.elem("a", attrs: (href: "https://github.com/frisbro303/tdg", target: "_blank", rel: "noopener"))[
        #html.elem("img", attrs: (src: root() + "_tdg/tdg.svg", alt: "", width: "14", height: "14")) tdg-built website
      ])
    }
  ]
}

// Headings with ids, for links to them and the docs' contents. (Typst lays out `=` headings as <h2>.)
#let _anchored(body) = {
  show heading: it => html.elem("h" + str(calc.min(it.level + 1, 6)), attrs: (id: slugify(plain-text(it.body))), it.body)
  body
}

// Links from the site's root ("/widgets/") made relative, so a site works at any address.
#let _relative-links(body) = {
  show link: it => if type(it.dest) == str and it.dest.starts-with("/") and not it.dest.starts-with("//") {
    context html.elem("a", attrs: (href: relative(it.dest.trim("/", at: start), page-url.get())), it.body)
  } else { it }
  body
}

#let _document(site, page, body-attrs, main) = html.elem("html", attrs: (lang: site.lang))[
  #head(site, page)
  #html.elem("body", attrs: body-attrs)[
    #html.elem("div", attrs: (class: "page"))[
      #header(site)
      #html.elem("main", main)
      #if page.at("footer", default: true) { footer(site) }
    ]
  ]
]

/// A dated page's header: its title, then its author, date, when it was updated and a link to its PDF.
#let post-header(page) = html.elem("div", attrs: (class: "post-header"))[
  #html.elem("h1", page.title)
  #html.elem("div", attrs: (class: "meta"))[
    #if page.at("author", default: none) not in (none, auto) [#html.elem("span", attrs: (class: "author"), page.author) · ]
    #html.elem("time", attrs: (datetime: page.date.display()), page.date.display())
    #let updated = page.at("updated", default: none)
    #if updated != none { [(updated ] + html.elem("time", attrs: (datetime: updated.display()), updated.display()) + [)] }
    #if page.pdf [· #html.elem("a", attrs: (href: page.slug + ".pdf", target: "_blank", rel: "noopener"), "pdf")]
  ]
]

/// A doc's <main>: a sidebar of the site's pages of its kind, in their `order`, then the page with previous and next
/// links, and its contents.
#let docs-main(site, page, body) = context {
  let docs = query(<tdg-page>).map(m => m.value).filter(d => d.kind == page.kind)
    .sorted(key: d => (d.at("order", default: 0), d.title))
  let at = docs.position(d => d.url == page.url)
  let start = query(<tdg-start>).find(m => m.value == page.url).location()
  let end = query(<tdg-end>).find(m => m.value == page.url).location()
  let headings = query(selector(heading).after(start).before(end)).filter(h => h.level <= 2)
  html.elem("div", attrs: (class: "docs-layout"))[
    #html.elem("nav", attrs: (class: "docs-nav", aria-label: "Pages"))[
      #if site.search { html.elem("div", attrs: (id: "search")) }
      #html.elem("ul", docs.map(d => html.elem("li", html.elem("a",
        attrs: (href: relative(d.url, page.url)) + if d.url == page.url { (aria-current: "page") } else { (:) },
        d.title))).join())
    ]
    #html.elem("article", attrs: (class: "docs-article"))[
      #html.elem("h1", page.title)
      #body
      #html.elem("nav", attrs: (class: "docs-pager"))[
        #if at != none and at > 0 {
          let d = docs.at(at - 1)
          html.elem("a", attrs: (class: "prev", href: relative(d.url, page.url)))[#html.elem("span", "Previous")#d.title]
        }
        #if at != none and at + 1 < docs.len() {
          let d = docs.at(at + 1)
          html.elem("a", attrs: (class: "next", href: relative(d.url, page.url)))[#html.elem("span", "Next")#d.title]
        }
      ]
    ]
    #if headings.len() > 1 {
      html.elem("aside", attrs: (class: "docs-toc"))[
        #html.elem("p", "On this page")
        #html.elem("ul", headings.map(h => html.elem("li", attrs: (class: "toc-" + str(h.level + 1)),
          html.elem("a", attrs: (href: "#" + slugify(plain-text(h.body))), h.body))).join())
      ]
    }
  ]
}

/// tdg's layout of a page: its <head>, the site's header, the page's <main> and the site's footer (unless its
/// template has none), with headings' ids and links from the site's root made relative.
#let page-layout(site, page, main) = {
  let class = page.at("class", default: none)
  _relative-links(_anchored(_document(site, page, if class != none { (class: class) } else { (:) }, main)))
}

/// The looks of tdg's themes. `blog` (also the website theme's): a serif text column. `docs`: sans-serif, for a
/// sidebar of pages and their contents.
#let looks = (
  blog: (css: ("blog.css",), fonts: "https://fonts.googleapis.com/css2?family=IBM+Plex+Mono&family=Libertinus+Serif:ital,wght@0,400;0,600;1,400&display=swap", layout: page-layout),
  docs: (css: ("docs.css",), fonts: none, layout: page-layout),
)
