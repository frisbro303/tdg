"""API references: Python modules read with griffe, as data a page's `#api(...)` lays out.

Docstrings are Google style. Their text may use a little Markdown, which becomes structured inline content (so
Typst never evaluates docstrings): `code`, **strong**, *emphasis*, [text](url), [text][module.Object] to link to
an object on the reference page, "- " lists, "|" tables, and ``` code blocks.
"""
import re

INLINE = re.compile(r"`([^`]+)`|\*\*(.+?)\*\*|(?<![\w*])\*([^*\s][^*]*?)\*(?![\w*])|\[([^\]]+)\]\(([^)]+)\)|\[([^\]]+)\]\[([\w.]+)\]")


def inline(text, page):
    """Text as [{"t": "text" | "code" | "strong" | "em" | "link", "v": ..., "href"?: ...}]."""
    out, at = [], 0
    for m in INLINE.finditer(text):
        if m.start() > at:
            out.append({"t": "text", "v": text[at:m.start()]})
        code, strong, em, label, url, ref_label, ref = m.groups()
        if code is not None:
            out.append({"t": "code", "v": code})
        elif strong is not None:
            out.append({"t": "strong", "v": strong})
        elif em is not None:
            out.append({"t": "em", "v": em})
        elif label is not None:
            out.append({"t": "link", "v": label, "href": url})
        else:
            out.append({"t": "link", "v": ref_label, "href": f"/{page}/#{ref}" if page else f"#{ref}"})
        at = m.end()
    if at < len(text):
        out.append({"t": "text", "v": text[at:]})
    return out


def blocks(text, page):
    """Text as blocks: paragraphs, lists, tables and code."""
    out, lines, i = [], (text or "").strip("\n").splitlines(), 0
    while i < len(lines):
        line = lines[i].rstrip()
        if not line.strip():
            i += 1
        elif line.lstrip().startswith("```"):
            j = i + 1
            while j < len(lines) and not lines[j].lstrip().startswith("```"):
                j += 1
            lang = line.strip()[3:] or "python"
            out.append({"t": "code", "lang": lang, "v": "\n".join(lines[i + 1:j])})
            i = j + 1
        elif line.lstrip().startswith("|"):
            rows = []
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{2,}:?", c) for c in cells):  # not the header's rule
                    rows.append([inline(c, page) for c in cells])
                i += 1
            out.append({"t": "table", "rows": rows})
        elif re.match(r"\s*[-*] ", line):
            items = []
            while i < len(lines) and lines[i].strip():
                if re.match(r"\s*[-*] ", lines[i]):
                    items.append(re.sub(r"^\s*[-*] ", "", lines[i]).strip())
                else:
                    items[-1] += " " + lines[i].strip()
                i += 1
            out.append({"t": "list", "items": [inline(item, page) for item in items]})
        else:
            paragraph = []
            while i < len(lines) and lines[i].strip() and not re.match(r"\s*([-*] |\||```)", lines[i]):
                paragraph.append(lines[i].strip())
                i += 1
            out.append({"t": "p", "v": inline(" ".join(paragraph), page)})
    return out


def _signature(name, parameters):
    parts, star = [], False
    for p in parameters:
        if p.name in ("self", "cls"):
            continue
        kind = str(p.kind.value) if p.kind else ""
        prefix = "**" if "variadic keyword" in kind else "*" if "variadic positional" in kind else ""
        if "keyword-only" in kind and not star:
            parts.append("*")
            star = True
        star = star or prefix == "*"
        default = f"={p.default}" if p.default is not None and not prefix else ""
        parts.append(f"{prefix}{p.name}{default}")
    return f"{name}({', '.join(parts)})"


def _sections(docstring, page):
    if docstring is None:
        return []
    out = []
    for section in docstring.parsed:
        kind = section.kind.value
        if kind == "text":
            out.append({"kind": "text", "blocks": blocks(section.value, page)})
        elif kind in ("parameters", "other parameters", "attributes", "raises", "returns", "yields", "receives"):
            items = []
            for item in section.value:
                name = getattr(item, "name", "") or ""
                annotation = getattr(item, "annotation", None)
                items.append({"name": name, "type": str(annotation) if annotation else "",
                              "blocks": blocks(item.description, page)})
            out.append({"kind": kind, "items": items})
        elif kind in ("examples",):
            for sub_kind, value in section.value:
                out.append({"kind": "text", "blocks": [{"t": "code", "lang": "python", "v": value}]
                            if str(getattr(sub_kind, "value", sub_kind)) == "examples" else blocks(value, page)})
        elif kind in ("admonition", "note", "warning"):
            value = section.value
            out.append({"kind": "text", "blocks": blocks(getattr(value, "description", str(value)), page)})
    return out


def _labels(obj):
    labels = set(getattr(obj, "labels", set()) or set())
    return sorted(str(label) for label in labels)


def _record(obj, page, records):
    """Add obj (and its public members) to records, by path."""
    kind = obj.kind.value
    record = {"path": obj.path, "name": obj.name, "kind": kind, "labels": _labels(obj),
              "doc": _sections(obj.docstring, page), "members": []}
    if kind == "function":
        record["signature"] = _signature(obj.name, obj.parameters) if "property" not in record["labels"] else obj.name
    elif kind == "class":
        init = obj.members.get("__init__")
        parameters = init.parameters if init is not None and hasattr(init, "parameters") else []
        record["signature"] = _signature(obj.name, parameters)
    elif kind == "attribute":
        is_property = "property" in record["labels"]
        record["signature"] = obj.name + (f" = {obj.value}" if not is_property and getattr(obj, "value", None) is not None else "")
    records[obj.path] = record
    if kind in ("module", "class"):
        for name, member in obj.members.items():
            if name.startswith("_") or member.is_alias:
                continue
            # A class's members: its methods, and attributes with docstrings of their own (properties, say); fields
            # are described in the class's docstring.
            if kind == "class" and member.kind.value == "attribute" and not member.docstring:
                continue
            record["members"].append(member.path)
            _record(member, page, records)


def python(paths, modules, page=""):
    """{path: record} for every public object in the modules, found on the search paths."""
    try:
        import griffe
    except ImportError:
        raise RuntimeError("API references need griffe: pip install griffe") from None
    loader = griffe.GriffeLoader(search_paths=[str(p) for p in paths], docstring_parser=griffe.Parser.google,
                                 docstring_options={"warn_unknown_params": False, "warn_missing_types": False},
                                 extensions=griffe.load_extensions("dataclasses"))
    records = {}
    for module in modules:
        _record(loader.load(module), page, records)
    return records
