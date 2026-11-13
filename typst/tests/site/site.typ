// A small site: a home page listing the posts, a post with a widget and a theorem, a doc with an API reference, a
// standalone page, and a template of its own (notes).
#import "../../lib.typ": *
#show: site.with(title: "Test", url: "https://example.com/", feed: "post", search: true, nav: (("about", "about/"),))
#include "index.typ"
#include "posts/hello/main.typ"
#include "about.typ"
#include "reference.typ"
#include "note.typ"
