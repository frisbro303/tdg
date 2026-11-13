// tdg: websites from Typst, and the components their pages are made of.
//
// A site is a file that sets it up and includes its pages, compiled in one go with Typst's bundle export:
//
//   typst compile --features html,bundle --format bundle site.typ _site
//
// Each page starts with a template, such as `#show: blog.post.with(...)`: a kind of page and its look. A theme is a
// module of templates: tdg's `website`, `blog` and `docs`, or a site's own, made with `template(...)`. Pages use the components: interactive
// 3D figures, theorems, callouts, source listings and themed images. Every component works for HTML and for PDF, so
// a page compiled alone is a document of its own.

#import "src/site.typ": site, template, listing, to-date, pdf-title
#import "src/layout.typ": page-layout, head, header, footer, post-header, docs-main
#import "src/themes/website.typ"
#import "src/themes/blog.typ"
#import "src/themes/docs.typ"
#import "src/api.typ": python-api, api
#import "src/components.typ": widget, theorem-kind, theorem, lemma, proposition, corollary, definition, example, proof, responsive, callout, source-code, themed-image
