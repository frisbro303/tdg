"""The tdg command: build, serve and install."""
import argparse
import sys

from tdg import __version__, typst
from tdg.build import BuildError, build
from tdg.config import ConfigError, load


def main(argv=None):
    parser = argparse.ArgumentParser(prog="tdg", description="Websites from Typst: blogs and software docs.")
    parser.add_argument("--version", action="version", version=f"tdg {__version__}")
    commands = parser.add_subparsers(dest="command", required=True)
    b = commands.add_parser("build", help="build the site")
    b.add_argument("path", nargs="?", default=".", help="the site's folder, with its tdg.toml (default: here)")
    b.add_argument("--out", help="where to build it (default: the config's, _site)")
    s = commands.add_parser("serve", help="build, serve on localhost, and rebuild on changes")
    s.add_argument("path", nargs="?", default=".")
    s.add_argument("--port", type=int)
    commands.add_parser("install", help="install tdg's Typst library for editors and plain typst")
    args = parser.parse_args(argv)

    try:
        if args.command == "build":
            result = build(load(args.path), out=args.out)
            for warning in result.warnings:
                print("warning:", warning, file=sys.stderr)
            print(f"Built {len(result.entries)} page(s) in {result.seconds:.1f}s")
        elif args.command == "serve":
            from tdg.serve import serve
            serve(args.path, args.port)
        elif args.command == "install":
            for path in typst.install():
                print("Installed", path)
    except (ConfigError, BuildError, typst.TypstError) as e:
        print("error:", e, file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        pass
