# Typst Docs Generator

Websites from [Typst](https://typst.app): blogs, and documentation for software. Pages are Typst files, with
Typst's math in the browser, and a Typst library for numbered theorems, callouts, API references generated from
Python docstrings, and interactive 3D figures ([wgw](https://github.com/frisbro303/wgw), built in).

```sh
pip install git+https://github.com/frisbro303/tdg
tdg serve      # build the site in this folder, serve it, rebuild as you edit
tdg build      # -> _site/
```

**Docs: https://frisbro303.github.io/tdg/**, built by tdg from [`docs/`](docs).

- `src/tdg/`: the command (build, serve, install), the API reader, and the themes (`blog`, `docs`, on `base`)
- `typst/`: the Typst library, a Typst package of its own; `typst/tests/run.sh` compiles its tests to PDF and HTML
- `docs/`: the docs site
