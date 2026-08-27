#!/usr/bin/env python3
"""Static frontend integrity check: every ES-module import must resolve
to an existing file under frontend/, and the imported names must appear
as exported in that file."""
import re, sys, pathlib

ROOT = pathlib.Path("frontend/js")
fail = 0
files = list(ROOT.rglob("*.js"))
for f in files:
    src = f.read_text()
    exports = set(re.findall(r"export\s+(?:class|const|function|let|var)\s+([A-Za-z0-9_$]+)", src))
    exports |= set(re.findall(r"export\s+async\s+function\s+([A-Za-z0-9_$]+)", src))
    exports |= set(re.findall(r"export\s*\{([^}]+)\}", src) and
                   {n.strip().split(" as ")[-1] for grp in re.findall(r"export\s*\{([^}]+)\}", src)
                    for n in grp.split(",")})
    if re.search(r"export\s+default", src):
        exports.add("default")
    for m in re.finditer(r"import\s*(?:\{([^}]*)\})?\s*(?:([A-Za-z0-9_$]+)\s*,?)?\s*from\s*['\"](\./[^'\"]+|\.\./[^'\"]+)['\"]", src):
        names, default, path = m.group(1), m.group(2), m.group(3)
        target = (f.parent / path).resolve()
        if not target.exists():
            print(f"MISSING FILE: {f} imports '{path}'")
            fail = 1
            continue
        tsrc = target.read_text()
        texports = set(re.findall(r"export\s+(?:class|const|function|let|var)\s+([A-Za-z0-9_$]+)", tsrc))
        texports |= set(re.findall(r"export\s+async\s+function\s+([A-Za-z0-9_$]+)", tsrc))
        for grp in re.findall(r"export\s*\{([^}]+)\}", tsrc):
            texports |= {n.strip().split(" as ")[-1] for n in grp.split(",")}
        if default:
            if not re.search(r"export\s+default", tsrc):
                print(f"MISSING DEFAULT EXPORT: {f} <- {path}")
                fail = 1
        for spec in (names or "").split(","):
            spec = spec.strip()
            if not spec:
                continue
            name = spec.split(" as ")[-1].strip()
            if name and name not in texports:
                print(f"MISSING EXPORT: {f} imports '{name}' from {path}")
                fail = 1
if fail:
    sys.exit(1)
print(f"IMPORT GRAPH OK ({len(files)} files checked)")
