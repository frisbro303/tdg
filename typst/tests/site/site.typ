// A small site: a post with a widget and a theorem, a doc with an API reference, and a standalone page.
#import "../../lib.typ": *
#show: site.with(title: "Test", url: "https://example.com/", search: true, nav: (("about", "about/"),))
#include "posts/hello/main.typ"
#include "about.typ"
#include "reference.typ"
