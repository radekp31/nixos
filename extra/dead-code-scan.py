#!/usr/bin/env python3
"""Walk nix import paths from the real flake roots. Over-approximate on purpose:
any relative path token counts as a reference, so nothing live is called dead."""
import os, re, sys

ROOT = "/etc/nixos"
# Entry points the flake actually evaluates.
ROOTS = [
    "flake.nix",
    "hosts/nixos-desktop/configuration.nix",
    "hosts/nixos-wsl/configuration.nix",
    "modules/home/users/radekp/desktop/default.nix",
    "modules/home/users/radekp/wsl/default.nix",
    "patches/opencode-stub.nix",
    "treefmt.nix",
]

def strip_comments(text):
    out = []
    for line in text.splitlines():
        # drop a full-line comment
        if re.match(r'\s*#', line):
            continue
        # drop a trailing comment (paths never contain '#')
        line = re.split(r'#', line, 1)[0]
        out.append(line)
    return "\n".join(out)

PATH_RE = re.compile(r'(?<![\w/.])((?:\./|\.\./)[^\s;\]\)"\'{}]*)')

def resolve(base_file, token):
    token = token.rstrip('/')
    p = os.path.normpath(os.path.join(os.path.dirname(base_file), token))
    if os.path.isdir(p):
        cand = os.path.join(p, "default.nix")
        return cand if os.path.isfile(cand) else None
    if os.path.isfile(p):
        return p
    if os.path.isfile(p + ".nix"):
        return p + ".nix"
    return None

seen, queue = set(), []
for r in ROOTS:
    ap = os.path.join(ROOT, r)
    if os.path.isfile(ap):
        queue.append(ap)

while queue:
    f = queue.pop()
    if f in seen:
        continue
    seen.add(f)
    try:
        text = strip_comments(open(f, encoding="utf-8", errors="replace").read())
    except OSError:
        continue
    for tok in PATH_RE.findall(text):
        tgt = resolve(f, tok)
        if tgt and tgt.endswith(".nix") and tgt not in seen:
            queue.append(tgt)

all_nix = set()
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in (".git", ".direnv")]
    for fn in filenames:
        if fn.endswith(".nix"):
            all_nix.add(os.path.join(dirpath, fn))

dead = sorted(all_nix - seen)
live = sorted(seen & all_nix)

def lines(p):
    try:
        return sum(1 for _ in open(p, encoding="utf-8", errors="replace"))
    except OSError:
        return 0

print(f"LIVE: {len(live)} files")
print(f"UNREACHED: {len(dead)} files, {sum(lines(p) for p in dead)} lines\n")
print("=== UNREACHED FROM THE FLAKE ROOTS ===")
for p in dead:
    print(f"{lines(p):5d}  {os.path.relpath(p, ROOT)}")
print("\n=== LIVE (for cross-check) ===")
for p in live:
    print(f"{lines(p):5d}  {os.path.relpath(p, ROOT)}")
