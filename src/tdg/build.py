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

from tdg import typst
from tdg.config import Config, Section

HERE = Path(__file__).parent
THEME = HERE / "themes" / "default"
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
            if url.split("/")[0] in RESERVED:
                raise BuildError(f"{path}: the URL /{url} is reserved for tdg")
            if url in urls:
                raise BuildError(f"{path} and {urls[url]} both publish to /{url}")
            urls[url] = path
            entries.append(Entry(section=section, slug=slug, path=path, source=source, url=url))
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


def compile_entry(entry, config, out, now):
    """Compile an entry and publish the files beside it; fills in its title, head, body and so on."""
    target = out / entry.url
    if entry.path.is_dir():
        shutil.copytree(entry.path, target, ignore=publishable(config), dirs_exist_ok=True)
    target.mkdir(parents=True, exist_ok=True)
    output = target / "index.html"
    warnings = typst.compile(entry.source, output, config.root)
    if warnings:
        entry.warnings.append(warnings)
    if entry.section.pdf:
        typst.compile(entry.source, target / f"{entry.slug}.pdf", config.root, fmt="pdf")
    page = output.read_text()
    entry.head = _between(page, "<head>", "</head>")
    entry.body = _between(page, "<body>", "</body>")
    # Typst escapes these already, so they're reused as HTML.
    title = re.search(r"<title>(.*?)</title>", entry.head)
    entry.title = title.group(1) if title else html.escape(entry.path.stem.replace("-", " ").replace("_", " ").capitalize())
    if not title:
        entry.head += f"<title>{entry.title}</title>"
    description = re.search(r'<meta name="description" content="(.*?)">', entry.head)
    entry.description = description.group(1) if description else ""
    entry.widgets = 'class="wgw"' in entry.body
    for attr, path in re.findall(r'data-(src|widget)="([^"]+)"', entry.body):
        if not path.startswith(("http:", "https:", "/")) and not (target / path).exists():
            entry.warnings.append(f"the widget's {path} isn't published: is it beside the page, and not excluded?")
    if entry.section.kind == "post":
        override = config.dates.get(entry.slug)
        entry.date = (datetime.datetime.fromisoformat(str(override)).astimezone() if override
                      else first_commit(entry.path, config.root) or now)  # not committed yet: the build's time
        entry.minutes = minutes_to_read(entry.body)


def templates(config):
    """The site's own templates first, then tdg's."""
    loaders = [jinja2.FileSystemLoader(config.root / config.templates)] if (config.root / config.templates).is_dir() else []
    env = jinja2.Environment(loader=jinja2.ChoiceLoader(loaders + [jinja2.FileSystemLoader(THEME / "templates")]),
                             autoescape=True, trim_blocks=True, lstrip_blocks=True, keep_trailing_newline=False)
    return env


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
        for future in [pool.submit(compile_entry, e, config, out, now) for e in entries]:
            try:
                future.result()
            except typst.TypstError as e:
                raise BuildError(str(e)) from None

    assets = out / "_tdg"
    assets.mkdir()
    if config.default_style:
        for name in ("style.css", "theme.js"):
            shutil.copy(THEME / name, assets / name)
    if any(e.widgets for e in entries):
        shutil.copytree(WGW, assets / "wgw", ignore=shutil.ignore_patterns("__pycache__"))
    for folder in config.copy:
        source = config.root / folder
        if not source.exists():
            raise BuildError(f"tdg.toml: copy: no such folder {folder}")
        shutil.copytree(source, out / folder, ignore=publishable(config), dirs_exist_ok=True)
    if dev:
        (assets / "build-id").write_text(str(time.time()))

    posts = sorted((e for e in entries if e.section.kind == "post"), key=lambda e: (e.date, e.slug), reverse=True)
    env = templates(config)
    common = {"site": config, "year": datetime.date.today().year, "feed": bool(config.url and posts), "dev": dev}
    for entry in entries:
        page = env.get_template(f"{entry.section.kind}.html").render(
            **common, entry=entry, root=entry.root, link=link(entry.root),
            head=Markup(entry.head), body=Markup(entry.body))
        (out / entry.url / "index.html").write_text(page)
    if posts:
        home = env.get_template("home.html").render(**common, entry=None, root="./", link=link("./"), posts=posts)
        (out / "index.html").write_text(home)
    if common["feed"]:
        (out / "feed.xml").write_text(feed(config, posts))
    return Result(entries=entries, seconds=time.monotonic() - started)
