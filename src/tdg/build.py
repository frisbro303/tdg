"""Building a site: each section's sources compiled with Typst, and wrapped in the theme's templates."""
import datetime
import fnmatch
import html
import math
import os
import re
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path

import jinja2
from markupsafe import Markup

from tdg import api, typst
from tdg.config import Config, Section, copies

HERE = Path(__file__).parent
THEMES = HERE / "themes"  # base (shared templates and components), and the themes built on it
WGW = HERE / "assets" / "wgw"
RESERVED = {"_tdg", "feed.xml", "index.html"}


class BuildError(Exception):
    pass


@dataclass
class Entry:
    """One page of the site: a .typ file, or a folder compiled from its main.typ."""

    section: Section
    slug: str
    path: Path  # the .typ file or the folder
    source: Path  # the .typ compiled
    url: str  # from the site's root: "posts/hopf/", "cv/"
    title: str = ""
    description: str = ""
    head: str = ""  # Typst's <head>, kept: its title, description and math styles
    body: str = ""
    date: datetime.datetime | None = None
    minutes: int = 0
    widgets: bool = False
    published: list = field(default_factory=list)  # (attribute, path) of files the page's figures load
    toc: list = field(default_factory=list)  # [{level, id, text}] of the page's h2 and h3
    warnings: list = field(default_factory=list)

    @property
    def root(self):
        """The relative path from this page back to the site's root."""
        return "../" * self.url.count("/")

    @property
    def day(self):
        return self.date.date().isoformat() if self.date else ""


@dataclass
class Result:
    entries: list
    seconds: float

    @property
    def warnings(self):
        return [f"{e.path}: {w}" for e in self.entries for w in e.warnings]


def slugify(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def entry_point(folder):
    """A folder is compiled from main.typ, or from its only .typ file."""
    if (folder / "main.typ").exists():
        return folder / "main.typ"
    candidates = sorted(folder.glob("*.typ"))
    if len(candidates) != 1:
        raise BuildError(f"{folder}: expected main.typ or exactly one .typ file")
    return candidates[0]


def find_entries(config):
    """Every entry of every section, checked for clashing URLs."""
    entries, urls = [], {}
    for section in config.sections:
        for path in sorted((config.root / section.dir).iterdir()):
            if path.is_dir() and any(path.glob("*.typ")):
                source = entry_point(path)
            elif path.suffix == ".typ":
                source = path
            else:
                continue
            slug = slugify(path.stem)
            url = f"{section.url.strip('/')}/{slug}/".lstrip("/")
            if section.kind == "doc" and slug == "index":  # a docs section's front page
                url = f"{section.url.strip('/')}/".lstrip("/")
            if url.split("/")[0] in RESERVED:
                raise BuildError(f"{path}: the URL /{url} is reserved for tdg")
            if url in urls:
                raise BuildError(f"{path} and {urls[url]} both publish to /{url}")
            urls[url] = path
            entries.append(Entry(section=section, slug=slug, path=path, source=source, url=url))
    for section in config.sections:  # docs in their sidebar's order, the rest alphabetically after
        if section.kind == "doc":
            order = {slug: i for i, slug in enumerate(section.pages)}
            missing = set(section.pages) - {e.slug for e in entries if e.section is section}
            if missing:
                raise BuildError(f"tdg.toml: section {section.dir}: no pages {', '.join(sorted(missing))}")
            mine = sorted((e for e in entries if e.section is section), key=lambda e: (order.get(e.slug, len(order)), e.slug))
            first = next(i for i, e in enumerate(entries) if e.section is section)
            others = [e for e in entries if e.section is not section]
            entries = others[:first] + mine + others[first:]
    return entries


def publishable(config):
    """A copytree ignore function: what stays out of the site (exclude), unless include brings it back."""
    def ignore(folder, names):
        return [n for n in names
                if any(fnmatch.fnmatch(n, p) for p in config.exclude)
                and not any(fnmatch.fnmatch(n, p) for p in config.include)]
    return ignore


def first_commit(path, root):
    """When the path was first committed, or None if it isn't (or this isn't a git repository)."""
    result = subprocess.run(["git", "log", "--reverse", "--format=%aI", "--", str(path)],
                            capture_output=True, text=True, cwd=root)
    dates = result.stdout.split()
    return datetime.datetime.fromisoformat(dates[0]) if result.returncode == 0 and dates else None


def minutes_to_read(body):
    """At 200 words a minute, with 5 seconds for each drawing and 10 for each image."""
    text = re.sub(r"<svg.*?</svg>|<[^>]+>", " ", body, flags=re.S)
    seconds = len(text.split()) * 60 / 200 + 5 * body.count("<svg") + 10 * body.count("<img")
    return max(1, math.ceil(seconds / 60))


def _between(page, start, end):
    i = page.find(start)
    j = page.rfind(end)
    return page[i + len(start):j] if i >= 0 and j > i else ""


def relative_links(body, root):
    """Root-relative links ("/examples/x.py") made relative to a page at root, so a site works under any path."""
    return re.sub(r'((?:href|src|data-src|data-widget)=")/(?!/)', lambda m: m.group(1) + (root or "./"), body)


def anchor_headings(body):
    """Ids for headings that lack them, and the page's contents: its h2 and h3."""
    toc, used = [], set(re.findall(r'id="([^"]+)"', body))

    def anchor(m):
        level, attrs, text = m.group(1), m.group(2), m.group(3)
        found = re.search(r'id="([^"]+)"', attrs)
        if found:
            ident = found.group(1)
        else:
            base = slugify(re.sub(r"<[^>]+>", "", text)) or "section"
            ident, n = base, 2
            while ident in used:
                ident, n = f"{base}-{n}", n + 1
            used.add(ident)
            attrs += f' id="{ident}"'
        toc.append({"level": int(level), "id": ident, "text": Markup(re.sub(r"<(?!/?code)[^>]+>", "", text))})
        return f"<h{level}{attrs}>{text}</h{level}>"

    body = re.sub(r"<h([23])([^>]*)>(.*?)</h\1>", anchor, body, flags=re.S)
    return body, toc


def compile_entry(entry, config, out, now, inputs):
    """Compile an entry and publish the files beside it; fills in its title, head, body and so on."""
    target = out / entry.url
    if entry.path.is_dir():
        shutil.copytree(entry.path, target, ignore=publishable(config), dirs_exist_ok=True)
    target.mkdir(parents=True, exist_ok=True)
    output = target / "index.html"
    typst_root = (config.root / config.typst_root).resolve()
    warnings = typst.compile(entry.source, output, typst_root, inputs=inputs)
    if warnings:
        entry.warnings.append(warnings)
    if entry.section.pdf:
        typst.compile(entry.source, target / f"{entry.slug}.pdf", typst_root, fmt="pdf", inputs=inputs)
    page = output.read_text()
    entry.head = _between(page, "<head>", "</head>")
    entry.body = relative_links(_between(page, "<body>", "</body>"), entry.root)
    entry.body, entry.toc = anchor_headings(entry.body)
    # Typst escapes these already, so they're reused as HTML.
    title = re.search(r"<title>(.*?)</title>", entry.head)
    entry.title = title.group(1) if title else html.escape(entry.path.stem.replace("-", " ").replace("_", " ").capitalize())
    if not title:
        entry.head += f"<title>{entry.title}</title>"
    if entry.section.kind == "doc":  # "Page · Site" in the browser's tab
        entry.head = re.sub(r"<title>(.*?)</title>", lambda m: f"<title>{m.group(1)} · {html.escape(config.title)}</title>", entry.head, count=1)
    description = re.search(r'<meta name="description" content="(.*?)">', entry.head)
    entry.description = description.group(1) if description else ""
    entry.widgets = 'class="wgw"' in entry.body
    entry.published = [(attr, path) for attr, path in re.findall(r'data-(src|widget)="([^"]+)"', entry.body)
                        if not path.startswith(("http:", "https:", "//"))]
    if entry.section.kind == "post":
        override = config.dates.get(entry.slug)
        entry.date = (datetime.datetime.fromisoformat(str(override)).astimezone() if override
                      else first_commit(entry.path, config.root) or now)  # not committed yet: the build's time
        entry.minutes = minutes_to_read(entry.body)


def theme_folders(config):
    """The theme, and base under it: a built-in theme by name, or a folder in the site."""
    named = THEMES / config.theme
    theme = named if config.theme != "base" and named.is_dir() else config.root / config.theme
    if not theme.is_dir():
        built_in = ", ".join(sorted(p.name for p in THEMES.iterdir() if p.is_dir() and p.name != "base"))
        raise BuildError(f"tdg.toml: theme: no theme {config.theme!r}; tdg has {built_in}, or give a folder")
    return [theme, THEMES / "base"]


def templates(config):
    """The site's own templates first, then its theme's, then base's."""
    folders = [config.root / config.templates] + [t / "templates" for t in theme_folders(config)]
    loader = jinja2.ChoiceLoader([jinja2.FileSystemLoader(f) for f in folders if f.is_dir()])
    return jinja2.Environment(loader=loader, autoescape=True, trim_blocks=True, lstrip_blocks=True)


def link(root):
    """Links in settings are from the site's root ("cv/"), or absolute; made relative to a page at `root`."""
    def resolve(href):
        if re.match(r"^[a-z]+:|^#|^//", href):
            return href
        return (root or "./") + href.lstrip("/")
    return resolve


def feed(config, posts):
    """An Atom feed of the posts, if the site says where it's published."""
    base = config.url.rstrip("/") + "/"
    items = "".join(
        f"<entry><title>{p.title}</title><link href=\"{base}{p.url}\"/><id>{base}{p.url}</id>"
        f"<updated>{p.date.isoformat()}</updated>"
        + (f"<summary>{p.description}</summary>" if p.description else "") + "</entry>"
        for p in posts)
    updated = max((p.date for p in posts), default=datetime.datetime.now().astimezone()).isoformat()
    return (f'<?xml version="1.0" encoding="utf-8"?><feed xmlns="http://www.w3.org/2005/Atom">'
            f"<title>{html.escape(config.title)}</title><link href=\"{base}\"/><id>{base}</id>"
            f"<updated>{updated}</updated><author><name>{html.escape(config.author or config.title)}</name></author>"
            f"{items}</feed>")


def index_search(out):
    """A Pagefind index of the site, for the search box (pip install 'pagefind[bin]')."""
    import sys
    result = subprocess.run([sys.executable, "-m", "pagefind", "--site", str(out), "--silent"],
                            capture_output=True, text=True)
    if result.returncode != 0:
        raise BuildError("search: Pagefind failed (is it installed? pip install 'pagefind[bin]'):\n"
                         + (result.stderr or result.stdout).strip())


def build(config: Config, out=None, dev=False):
    """Build the site into out (by default, the config's); returns what was built."""
    started = time.monotonic()
    typst.check()
    out = Path(out or config.root / config.out)
    entries = find_entries(config)
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
        now = datetime.datetime.now().astimezone()
        inputs = {}
        if config.api.get("python"):
            python = config.api["python"]
            try:
                records = api.python([config.root / p for p in python.get("paths", ["."])], python["modules"],
                                     page=config.api.get("page", ""))
            except Exception as e:
                raise BuildError(f"tdg.toml: api: {e}") from None
            import json
            inputs["tdg-api"] = json.dumps(records, separators=(",", ":"))
        for future in [pool.submit(compile_entry, e, config, out, now, inputs) for e in entries]:
            try:
                future.result()
            except typst.TypstError as e:
                raise BuildError(str(e)) from None

    assets = out / "_tdg"
    assets.mkdir()
    if config.default_style:  # base's static files, then the theme's over them
        for theme in reversed(theme_folders(config)):
            if (theme / "static").is_dir():
                shutil.copytree(theme / "static", assets, dirs_exist_ok=True)
    if any(e.widgets for e in entries):
        wgw = config.root / config.wgw if config.wgw else WGW
        if not (wgw / "wgw.js").exists():
            raise BuildError(f"tdg.toml: wgw: no wgw build (wgw.js) in {wgw}")
        shutil.copytree(wgw, assets / "wgw", ignore=shutil.ignore_patterns("__pycache__"))
    for published, source in copies(config).items():
        if not source.exists():
            raise BuildError(f"tdg.toml: copy: no such file or folder {source}")
        if source.is_dir():
            shutil.copytree(source, out / published, ignore=publishable(config), dirs_exist_ok=True)
        else:
            (out / published).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(source, out / published)
    for entry in entries:  # a widget's files must be on the site
        for attr, path in entry.published:
            if not (out / entry.url / path).resolve().exists():
                entry.warnings.append(f"the figure's {path} isn't on the site: is it beside the page, copied, and not excluded?")
    if dev:
        (assets / "build-id").write_text(str(time.time()))

    posts = sorted((e for e in entries if e.section.kind == "post"), key=lambda e: (e.date, e.slug), reverse=True)
    env = templates(config)
    common = {"site": config, "year": datetime.date.today().year, "feed": bool(config.url and posts), "dev": dev}
    for entry in entries:
        docs = [e for e in entries if e.section is entry.section] if entry.section.kind == "doc" else []
        at = docs.index(entry) if docs else 0
        page = env.get_template(f"{entry.section.kind}.html").render(
            **common, entry=entry, root=entry.root, link=link(entry.root),
            head=Markup(entry.head), body=Markup(entry.body), toc=entry.toc, docs=docs,
            prev=docs[at - 1] if docs and at > 0 else None, next=docs[at + 1] if docs and at + 1 < len(docs) else None)
        (out / entry.url / "index.html").write_text(page)
    if posts:
        home = env.get_template("home.html").render(**common, entry=None, root="./", link=link("./"), posts=posts)
        (out / "index.html").write_text(home)
    if common["feed"]:
        (out / "feed.xml").write_text(feed(config, posts))
    if config.search:
        index_search(out)
    return Result(entries=entries, seconds=time.monotonic() - started)
