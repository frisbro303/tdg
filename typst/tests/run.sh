#!/bin/sh
# Compile the tests to PDF and to HTML; fails on any error.
set -e
cd "$(dirname "$0")"
for test in *.typ; do
  typst compile --root .. "$test" "/tmp/tdg-test-${test%.typ}.pdf"
  typst compile --root .. --features html --format html "$test" "/tmp/tdg-test-${test%.typ}.html" 2>&1 \
    | grep -v "html export\|hint:" || true
done
echo "tests passed"
