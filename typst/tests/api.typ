// api() with data from the plugin, laid out for PDF and HTML.
#import "../lib.typ": *
#let pkg = python-api(read("fixtures/pkg.py"), module: "pkg", page: "reference")
= Reference
#api(pkg, "pkg.Thing")
#api(pkg, "pkg.helper")
