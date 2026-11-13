#import "@local/tdg:0.2.0": *
#show: doc.with("building", title: "Building", order: 5, description: "Compiling a tdg site, watching it, PDFs, and publishing to GitHub Pages.")

= Compiling

A site is built by Typst alone (0.15 or later), with its HTML and bundle exports, which are still experimental:

```sh
typst compile --features html,bundle --format bundle site.typ _site
```

Use `--root` if pages read files above the site file's folder, as these docs do (`--root .`, from the repository).
While writing, rebuild on every save, and serve the site with any static server:

```sh
typst watch --features html,bundle --format bundle site.typ _site
python3 -m http.server -d _site      # http://localhost:8000
```

= PDFs

A post is also published as a PDF (`pdf: true`, the default for posts), and any page compiles to one on its own:
`typst compile posts/hopf/main.typ`. Components lay themselves out for print: theorems as blocks, and widgets as
the figure's first frame, drawn by wgw's own renderer and shaders on the CPU, in tdg's plugin.

= Publishing to GitHub Pages

A workflow that builds the site on every push and publishes it (set Pages to deploy from GitHub Actions in the
repository's settings):

```yaml
name: Site
on: { push: { branches: [main] }, workflow_dispatch: {} }
permissions: { contents: read, pages: write, id-token: write }
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: typst-community/setup-typst@v5
        with: { typst-version: 0.15.0 }
      - run: typst compile --features html,bundle --format bundle site.typ _site
      - uses: actions/upload-pages-artifact@v5
        with: { path: _site/ }
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: { name: github-pages }
    steps:
      - uses: actions/deploy-pages@v5
```

= Inside

tdg is a Typst package: `typst/lib.typ` and `typst/src/` (sites, themes, components, API references), its assets
(stylesheets, wgw's runtime) and its plugin, `typst/assets/tdg.wasm`, built from `plugin/` (Rust) with
`cargo build --release --target wasm32-unknown-unknown`. `typst/tests/run.sh` compiles its tests, as PDF, HTML and
a bundled site.
