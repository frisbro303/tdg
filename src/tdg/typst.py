"""Compiling with the typst CLI, with tdg's Typst library on the package path."""
import re
import shutil
import subprocess
from pathlib import Path

PACKAGES = Path(__file__).parent / "typst"  # holds local/tdg/<version>, for `#import "@local/tdg:0.1.0"`

# Typst warns that HTML export is experimental on every compile; tdg relies on it knowingly.
_EXPERIMENTAL = re.compile(r"warning: html export is under active development.*?(?=\n(?:warning|error)|\Z)", re.S)


class TypstError(Exception):
    pass


def check():
    if not shutil.which("typst"):
        raise TypstError("typst isn't installed: see https://github.com/typst/typst#installation")


def compile(source, output, root, fmt="html"):
    """Compile source to output (html or pdf); returns Typst's warnings, raises TypstError on errors."""
    command = ["typst", "compile", "--root", str(root), "--package-path", str(PACKAGES), "--format", fmt]
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
    installed = []
    for package in (PACKAGES / "local").glob("*/*"):
        target = data / "typst" / "packages" / "local" / package.parent.name / package.name
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(package, target)
        installed.append(target)
    return installed
