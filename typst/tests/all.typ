// Every function, once; compiled to PDF and to HTML by run.sh.
#import "../lib.typ": *

= Functions

#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.]
#proof[By inspection.]
#definition[A *manifold* is locally Euclidean.]
#let conjecture = theorem-kind("conjecture", "Conjecture")
#conjecture[It holds.]

#widget(widget: "x_widget.py", src: "m.obj", up: "y", view: (90, 10), pick: "hover", flat: true, height: 300pt,
        caption: [A widget with no still.])
#widget(src: "m.obj", still: rect(width: 3cm, height: 2cm, fill: luma(200)), caption: [A widget with a still.])

#callout(kind: "tip", title: [Hint])[Use it.]
#callout[A plain note.]
#responsive($ a + b + c $, $ a \ + b \ + c $)
#source-code("example.py", "print(1)\n")
#themed-image("chart", [A chart.], ext: "gif")
#themed-image("chart", "Alt only.", print: rect(width: 2cm, height: 1cm))
// Negative angles must reach HTML as ASCII minus signs, which JavaScript can read.
#widget(src: "m.obj", view: (-50, 25))
// Captions with math still give plain alt text.
#widget(src: "m.obj", caption: [Curvature $K = cos v \/ (r (R + r cos v))$ on a torus.])
