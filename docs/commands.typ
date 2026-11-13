#import "@local/tdg:0.1.0": *
#set document(title: "Commands", description: "tdg build, serve and install, and publishing to GitHub Pages.")

= Build

```sh
tdg build [folder] [--out path]
```

Builds the site in the folder (by default, here) into `_site/`. Pages compile in parallel; Typst's errors stop the
build, with the file and line, and warnings are listed after it.

= Serve

```sh
tdg serve [folder] [--port 8000]
```

Builds the site, serves it at `http://localhost:8000`, and rebuilds when a file changes, reloading open pages. Say
what to ignore, and a command to run before rebuilding (such as re-rendering figures; `{files}` is the changed
files), in `tdg.toml`:

```toml
[serve]
port = 8000
ignore = ["media", ".cache"]
on_change = "uv run render.py {files}"
```

= Install

```sh
tdg install
```

Copies tdg's Typst library into Typst's local packages, so `#import "@local/tdg:0.1.0"` also works in editors (such
as Tinymist's preview) and in plain `typst compile`. Builds don't need it: tdg gives every compile its library.

= Publishing to GitHub Pages

A workflow that builds the site on every push, and publishes it (set Pages to deploy from GitHub Actions, in the
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
        with: { fetch-depth: 0 }                  # posts' dates come from git
      - uses: typst-community/setup-typst@v5
        with: { typst-version: 0.15.0 }
      - run: pip install "tdg @ git+https://github.com/frisbro303/tdg" "pagefind[bin]"
      - run: tdg build
      - uses: actions/upload-pages-artifact@v5
        with: { path: _site/ }
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: { name: github-pages }
    steps:
      - uses: actions/deploy-pages@v5
```
