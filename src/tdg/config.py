"""A site's settings, from its tdg.toml."""
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

KINDS = ("post", "page", "doc")


class ConfigError(Exception):
    pass


@dataclass
class Section:
    """A folder of sources that publish together: posts (dated, listed on the home page), pages, or docs (with a
    sidebar, in the order of `pages`, and `index` as the section's front page)."""

    dir: str  # the folder, relative to the site
    kind: str = "post"  # "post", "page" or "doc"
    url: str = ""  # where entries publish: "posts" puts posts/x.typ at posts/x/
    pdf: bool = False  # also publish each entry as <slug>/<slug>.pdf
    pages: list = field(default_factory=list)  # docs: the sidebar's order, by slug; others follow alphabetically


@dataclass
class Config:
    root: Path
    title: str
    author: str = ""
    lang: str = "en"
    url: str = ""  # where the site is published, for its feed
    icon: str = ""  # an image in the site, shown in the header and as the favicon
    fonts: str = ""  # a stylesheet URL for web fonts
    theme: str = "blog"  # tdg's "blog" or "docs", or a folder of the site's own (templates/ and static/)
    default_style: bool = True  # include the theme's stylesheets and theme switch
    css: list = field(default_factory=list)  # the site's stylesheets
    js: list = field(default_factory=list)  # the site's scripts, loaded in <head>
    copy: list | dict = field(default_factory=list)  # published as they are: [folder], or {published: source}
    typst_root: str = "."  # Typst's root, from the site: "/x" in a page means <typst_root>/x, here and on the site
    wgw: str = ""  # a wgw build (dist/) to use instead of the one bundled with tdg
    api: dict = field(default_factory=dict)  # {python: {paths: [...], modules: [...]}, page: slug of the reference}
    search: bool = False  # index the site with Pagefind, and show a search box
    credit: bool = True  # a small "made with tdg" link in the footer
    nav: list = field(default_factory=list)  # [{label, href}] in the header; href is from the site's root
    footer: dict = field(default_factory=dict)  # {copyright, links: {label: url}}
    home: str = ""  # the home page's heading, above the list of posts
    sections: list = field(default_factory=list)
    dates: dict = field(default_factory=dict)  # slug -> date, overriding a post's first commit
    exclude: list = field(default_factory=lambda: ["*.typ", ".DS_Store", "__pycache__"])  # never published
    include: list = field(default_factory=list)  # published even if excluded, such as "*_widget.py"
    out: str = "_site"
    templates: str = "templates"  # the site's own templates, overriding tdg's
    serve: dict = field(default_factory=dict)  # {port, ignore: [folders], on_change: "command {files}"}


def load(root):
    """The settings in root/tdg.toml, checked."""
    root = Path(root).resolve()
    path = root / "tdg.toml"
    if not path.exists():
        raise ConfigError(f"no tdg.toml in {root}")
    try:
        data = tomllib.loads(path.read_text())
    except tomllib.TOMLDecodeError as e:
        raise ConfigError(f"{path}: {e}") from None
    site = data.pop("site", {})
    sections = data.pop("sections", [])
    known = Config.__dataclass_fields__.keys() - {"root", "sections"}
    unknown = (site.keys() | data.keys()) - known
    if unknown:
        raise ConfigError(f"{path}: unknown settings {', '.join(sorted(unknown))}")
    if "title" not in site:
        raise ConfigError(f"{path}: [site] needs a title")
    config = Config(root=root, **site, **data)
    for s in sections:
        bad = s.keys() - Section.__dataclass_fields__.keys()
        if bad:
            raise ConfigError(f"{path}: unknown section settings {', '.join(sorted(bad))}")
        section = Section(**s)
        if section.kind not in KINDS:
            raise ConfigError(f"{path}: section {section.dir}: kind is one of {', '.join(KINDS)}")
        if not (root / section.dir).is_dir():
            raise ConfigError(f"{path}: section {section.dir}: no such folder")
        config.sections.append(section)
    return config


def copies(config):
    """The config's `copy` as {published path: source path}."""
    items = config.copy.items() if isinstance(config.copy, dict) else ((c, c) for c in config.copy)
    return {published.strip("/"): config.root / source for published, source in items}
