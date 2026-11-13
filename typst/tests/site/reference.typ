#import "../../lib.typ": *
#show: doc.with("reference", title: "Reference", order: 1)
#let pkg = python-api(read("../fixtures/pkg.py"), module: "pkg", page: "reference")
#api(pkg, "pkg.Thing")
