#import "@local/tdg:0.1.0": *
#set document(title: "Sites", description: "tdg.toml: a site's settings, sections, and how its files are published.")

A site is a folder with a `tdg.toml`, which says what the site is called, which folders hold its pages, and how
they look.

= Sections

A site's pages come from its *sections*: folders, each of one kind.

#table(
  columns: 2,
  [*kind*], [],
  [`post`], [dated (by the file's first git commit, or `dates`), with a reading time, listed newest first on the
    home page and in the feed],
  [`page`], [standalone, such as an about page or a CV; they lay out their own headings],
  [`doc`], [documentation, with a sidebar in the order of `pages`, previous and next links, and contents; a page
    called `index` is the section's front page],
)

```toml
[[sections]]
dir = "posts"      # the folder
kind = "post"
url = "posts"      # posts/hopf.typ is published at posts/hopf/

[[sections]]
dir = "pages"
kind = "page"
pdf = true         # also publish each as a PDF: cv/cv.pdf

[[sections]]
dir = "docs"
kind = "doc"
pages = ["index", "install", "guide", "reference"]
```

An entry is a `.typ` file, or a folder compiled from its `main.typ` (or its only `.typ` file). A folder's other
files are published beside the page, so its figures, data and widgets come along; see
#link("#publishing")[publishing].

Titles and descriptions come from the page: `#set document(title: "...", description: "...")`.

= Settings

#table(
  columns: 2,
  [*`[site]`*], [],
  [`title`], [the site's name; required],
  [`author`], [for the footer and the feed],
  [`url`], [where it's published: gives posts a feed (`feed.xml`)],
  [`theme`], [`"blog"` (the default), `"docs"`, or a folder of the site's own: see #link("/themes/")[themes]],
  [`icon`], [an image in the site, for the header and the browser tab],
  [`fonts`], [a stylesheet URL for web fonts],
  [`css`, `js`], [the site's own stylesheets and scripts],
  [`nav`], [the header's links: `[{label = "about", href = "about/"}]`, from the site's root],
  [`footer`], [`{copyright = "...", links = {github = "https://..."}}`],
  [`home`], [a heading above the home page's posts],
  [`copy`], [published as they are: `["theme"]`, or `{published = "source"}` such as `{examples = "../examples"}`],
  [`typst_root`], [Typst's root, from the site; `"/x"` in a page means `<typst_root>/x`],
  [`search`], [index the site with #link("https://pagefind.app")[Pagefind], and show a search box in docs],
  [`credit`], [a small "made with tdg" link in the footer; `false` hides it],
  [`wgw`], [a #link("https://github.com/frisbro303/wgw")[wgw] build to use instead of the one bundled with tdg],
)

Settings outside `[site]`: `dates` (`{slug = "2026-11-03"}`, overriding posts' git dates), `exclude` and
`include` (below), `api` (#link("/typst/#api-references")[API references]), `out` (`"_site"`), `templates` (the
site's own template overrides), and `serve` (#link("/commands/#serve")[serving]).

= Publishing

tdg publishes everything beside a page except what `exclude` names, unless `include` brings it back:

```toml
exclude = ["*.typ", "*.py", ".DS_Store", "__pycache__"]   # scripts that make figures stay private
include = ["*_widget.py"]                                  # but widgets run in the browser
```

After building, tdg checks that every widget's files made it, and warns about any that didn't.

= Paths

In a page, a path starting with `/` is from `typst_root`, for Typst (`read("/examples/x.py")`) and on the site
alike: tdg rewrites such links to be relative, so a site works at any address, such as
`https://you.github.io/project/`. Paths without `/` are relative to the page.
