"""Compiling with the typst CLI, with tdg's Typst library on the package path."""
import os
import re
import shutil
import subprocess
import tempfile
import tomllib
from pathlib import Path

# tdg's Typst library: in an installed tdg, bundled as _typst; in the repository, its typst/ folder.
LIBRARY = next(p for p in (Path(__file__).parent / "_typst", Path(__file__).parents[2] / "typst") if (p / "typst.toml").exists())
VERSION = tomllib.loads((LIBRARY / "typst.toml").read_text())["package"]["version"]


def _packages():
    """A package folder holding the library as local/tdg/<version>, for `#import "@local/tdg:<version>"`.

    Pages can also import it from Typst Universe once it's there (`@preview/tdg`); this keeps the version that
    came with tdg working offline, and before then.
    """
    folder = Path(tempfile.gettempdir()) / f"tdg-packages-{os.getuid() if hasattr(os, 'getuid') else 0}"
    target = folder / "local" / "tdg" / VERSION
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(LIBRARY, target, ignore=shutil.ignore_patterns("tests", "examples", "*.pdf", "*.html"))
    return folder

# Typst warns that HTML export is experimental on every compile; tdg relies on it knowingly.
_EXPERIMENTAL = re.compile(r"warning: html export is under active development.*?(?=\n(?:warning|error)|\Z)", re.S)


class TypstError(Exception):
    pass


PACKAGES = None


def check():
    """Make sure typst is installed, and put the library where compiles find it."""
    global PACKAGES
    if not shutil.which("typst"):
        raise TypstError("typst isn't installed: see https://github.com/typst/typst#installation")
    PACKAGES = _packages()


def compile(source, output, root, fmt="html", inputs=None):
    """Compile source to output (html or pdf); returns Typst's warnings, raises TypstError on errors.

    inputs become `sys.inputs` in Typst: tdg passes `tdg-api`, the API reference's data, as JSON.
    """
    command = ["typst", "compile", "--root", str(root), "--package-path", str(PACKAGES), "--format", fmt]
    for key, value in (inputs or {}).items():
        command += ["--input", f"{key}={value}"]
    if fmt == "html":
        command += ["--features", "html"]
    result = subprocess.run(command + [str(source), str(output)], capture_output=True, text=True)
    messages = _EXPERIMENTAL.sub("", result.stderr).strip()
    if result.returncode != 0:
        raise TypstError(messages or f"typst failed on {source}")
    return messages


def install():
    """Copy tdg's Typst library into Typst's local packages, where editors and plain `typst` find it."""
    import os
    import platform

    system = platform.system()
    if system == "Darwin":
        data = Path.home() / "Library" / "Application Support"
    elif system == "Windows":
        data = Path(os.environ["APPDATA"])
    else:
        data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    target = data / "typst" / "packages" / "local" / "tdg" / VERSION
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(LIBRARY, target, ignore=shutil.ignore_patterns("tests", "examples", "*.pdf", "*.html"))
    return [target]
