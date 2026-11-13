// Every function, once; compiled to PDF and to HTML by run.sh.
#import "../lib.typ": *

= Functions

#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
#proof[By inspection.]
#definition[A *manifold* is locally Euclidean.]
#let conjecture = theorem-kind("conjecture", "Conjecture")
#conjecture[It holds.]

#widget("m.wgw", up: "y", view: (90, 10), pick: "hover", flat: true, height: 300pt,
        caption: [A figure from a URL: an empty figure in a PDF.])

#callout(kind: "tip", title: [Hint])[Use it.]
#callout[A plain note.]
#responsive($ a + b + c $, $ a \ + b \ + c $)
#source-code("example.py", text: "print(1)\n")
#themed-image("chart.gif", "chart-dark.gif", [A chart.])
#themed-image("chart.png", "chart-dark.png", "Alt only.")
// Negative angles must reach HTML as ASCII minus signs, which JavaScript can read.
#widget("m.obj", view: (-50, 25))
// Captions with math still give plain alt text.
#widget("m.obj", caption: [Curvature $K = cos v \/ (r (R + r cos v))$ on a torus.])
