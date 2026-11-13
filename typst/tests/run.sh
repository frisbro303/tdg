#!/bin/sh
# Compile the tests: the components to PDF and HTML, and a small site as a bundle (its pages, then its PDFs). Files
# are published at their place in the project, which is the package here (--root ..): tests/site/...
set -e
cd "$(dirname "$0")"
out=$(mktemp -d)
for test in *.typ; do
  typst compile --root .. "$test" "$out/${test%.typ}.pdf"
  typst compile --root .. --features html --format html "$test" "$out/${test%.typ}.html" 2>/dev/null
done
typst compile --root .. --features html,bundle --format bundle site/site.typ "$out/site" 2>/dev/null
typst compile --root .. --features html,bundle --format bundle --input tdg=pdf site/site.typ "$out/site" 2>/dev/null
for file in index.html posts/hello/index.html posts/hello/hello.pdf tests/site/posts/hello/torus.wgw about/index.html \
            about/about.pdf reference/index.html notes/tori/index.html tests/site/note.css feed.xml _tdg/search.json _tdg/wgw/wgw.js; do
  [ -f "$out/site/$file" ] || { echo "missing from the site: $file"; exit 1; }
done
grep -q 'id="pkg.Thing.twice"' "$out/site/reference/index.html" || { echo "the reference lacks pkg.Thing.twice"; exit 1; }
grep -q 'href="./posts/hello/"' "$out/site/index.html" || { echo "the home page doesn't list the post"; exit 1; }
grep -q 'href="./notes/tori/"' "$out/site/index.html" || { echo "the home page doesn't list the note"; exit 1; }
grep -q 'Tori · geometry' "$out/site/notes/tori/index.html" || { echo "the note lacks its own header"; exit 1; }
grep -q '<entry><title>Hello' "$out/site/feed.xml" || { echo "the feed lacks the post"; exit 1; }
grep -q 'href="../../tests/site/note.css"' "$out/site/notes/tori/index.html" || { echo "the note lacks its template's stylesheet"; exit 1; }
grep -q '_tdg/blog.css' "$out/site/notes/tori/index.html" || { echo "the note lacks tdg's blog.css"; exit 1; }
grep -q '_tdg/docs.css' "$out/site/reference/index.html" || { echo "the doc lacks docs.css"; exit 1; }
echo "tests passed ($out)"
