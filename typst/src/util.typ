// Helpers shared by the rest of tdg.

/// tdg's plugin (plugin/): Python modules' API, and stills of wgw figures.
#let tdg-plugin = plugin("../assets/tdg.wasm")

/// Whether this content is laid out as HTML (a web page), rather than paged (a PDF).
#let html-target() = target() == "html"

/// A number as HTML attributes and JavaScript read it: Typst writes negatives with a typographic minus (U+2212).
#let num(x) = str(x).replace("\u{2212}", "-")

/// The plain text of some content, for alt text and reading times; math and other non-text parts are dropped.
#let plain-text(it) = if type(it) == str { it } else if type(it) != content { "" } else if it.has("text") {
  plain-text(it.text)  // a string, or content (math operators like cos)
} else if it.has("children") {
  it.children.map(plain-text).join(default: "")
} else if it.has("body") { plain-text(it.body) } else if it == [ ] { " " } else { "" }

/// A URL-friendly name: "Hopf Fibrations" becomes "hopf-fibrations".
#let slugify(s) = lower(s).replace(regex("[^a-z0-9]+"), "-").trim("-")

// ---- Files and URLs.
//
// A site's files are published at the same place they have in the project: posts/hopf/figures/x.gif is served
// at <site>/posts/hopf/figures/x.gif. Components take `path(...)` values, which resolve relative to the file that
// makes them, and tdg reads and publishes them; strings are used as URLs, as they are.

/// The page being laid out, as a URL from the site's root, such as "posts/hopf/" (none outside a site).
#let page-url = state("tdg-page-url", none)

/// A path's place in the project, such as "posts/hopf/figures/x.gif". Typst shows no more of a path than its repr.
#let path-string(p) = {
  let r = repr(p)  // path("/posts/hopf/figures/x.gif")
  r.slice(r.position("\"") + 1, r.len() - 2).trim("/", at: start)
}

/// How to get from a page at `from` ("posts/hopf/") to `target` ("posts/hopf/figures/x.gif", or "" for the root).
#let relative(target, from) = {
  if from == none { return "/" + target }
  if from != "" and target.starts-with(from) { return target.slice(from.len()) }
  let depth = from.split("/").filter(s => s != "").len()
  if depth == 0 { "./" + target } else { "../" * depth + target }
}

/// The site's root, from the current page: "../../" from posts/hopf/. Call within `context`.
#let root() = relative("", page-url.get())

/// A URL for a file to link to: a string as it is, or a path, which is published (see `publish`).
/// Call within `context`.
#let file-url(file) = if type(file) == str { file } else { relative(path-string(file), page-url.get()) }

/// Publish a path's file on the site, at its place in the project; anything else (URLs, tdg's own files) is left
/// alone.
#let publish(file) = if type(file) == path {
  [#metadata((path: file, out: path-string(file))) <tdg-asset>]
}

// ---- Stylesheets: a template's `css` is tdg's own (from its themes' looks), paths, or URLs.

/// One of tdg's own stylesheets, in assets/, as its themes' looks give it.
#let tdg-css(name) = (tdg-css: name)

/// The stylesheets of the page being laid out, as its template gives them.
#let page-css = state("tdg-page-css", ())

/// A stylesheet's URL from the current page. Call within `context`.
#let css-url(css) = if type(css) == dictionary { root() + "_tdg/" + css.tdg-css } else { file-url(css) }

/// A stylesheet's text, for what Typst draws with the page's colors (widgets' stills); a URL's isn't read.
#let css-text(css) = if type(css) == dictionary { read("../assets/" + css.tdg-css) } else if type(css) == str { "" } else { read(css) }
