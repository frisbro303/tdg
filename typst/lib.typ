// tdg: websites from Typst, and the components their pages are made of.
//
// A site is a file that sets it up and includes its pages, compiled in one go with Typst's bundle export:
//
//   typst compile --features html,bundle --format bundle site.typ _site
//
// Its pages start with `#show: post.with(...)`, `standalone.with(...)` or `doc.with(...)`, and use the components:
// interactive 3D figures, theorems, callouts, source listings and themed images. Every component works for HTML
// and for PDF, so a page compiled alone is a document of its own.

#import "src/site.typ": site, post, standalone, doc
#import "src/themes.typ": themes
#import "src/api.typ": python-api, api
#import "src/components.typ": widget, theorem-kind, theorem, lemma, proposition, corollary, definition, example, proof, responsive, callout, source-code, themed-image
