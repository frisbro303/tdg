// tdg's docs, built by tdg: from the repository's root,
//
//   typst compile --root . --features html,bundle --format bundle docs/site.typ docs/_site
#import "@local/tdg:0.1.0": *

#show: site.with(
  title: "tdg",
  url: "https://frisbro303.github.io/tdg/",
  icon: path("../assets/tdg-icon.svg"),
  nav: (("GitHub", "https://github.com/frisbro303/tdg"),),
  search: true,
)

#include "index.typ"
#include "sites.typ"
#include "components.typ"
#include "themes.typ"
#include "building.typ"
