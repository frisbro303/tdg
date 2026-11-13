#import "../../../../lib.typ": *
#show: blog.post.with("hello", title: "Hello", date: "2026-11-03", description: "A first post.")
= A section
Inline $x^2$, and @thm-hopf.
#theorem(title: [Hopf])[Every map $S^3 -> S^2$ of Hopf invariant one is a fibration.] <thm-hopf>
#widget(path("torus.wgw"), view: (-60, 35), caption: [A torus.]) <fig-torus>
See @fig-torus and #link("/about/")[about].
