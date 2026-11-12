#!/usr/bin/env python3
"""Updates versions and hashes of the local packages in packages/.

`nix flake update` does not touch them: version and hash are written into
the recipes. This script asks the official sources for the latest versions,
downloads the files into the store and rewrites version and hash.

Usage:
  scripts/update-apps.py                update everything
  scripts/update-apps.py --check        only show what is outdated
  scripts/update-apps.py happ jaeger    update the named packages
"""

import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PKGS = REPO / "packages"
FAKE_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


def fetch(url, attempts=4):
    # Download mirrors sometimes time out on the TLS handshake: retry before
    # treating the package as broken.
    req = urllib.request.Request(url, headers={"User-Agent": "update-apps"})
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                return r.read().decode()
        except (urllib.error.URLError, TimeoutError) as e:
            if isinstance(e, urllib.error.HTTPError) and e.code < 500 or attempt == attempts:
                raise
            time.sleep(2 * attempt)


def github_latest(repo):
    tag = json.loads(fetch(f"https://api.github.com/repos/{repo}/releases/latest"))["tag_name"]
    return tag.removeprefix("v")


def run(*cmd, check=True):
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def to_sri(h):
    return run("nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", h).stdout.strip()


def prefetch(url, name=None):
    """Downloads a file into the store and returns (SRI hash, path)."""
    cmd = ["nix-prefetch-url", "--print-path", url]
    if name:
        cmd[1:1] = ["--name", name]
    h, path = run(*cmd).stdout.split()
    return to_sri(h), path


def vkey(v):
    return [int(x) if x.isdigit() else x for x in re.split(r"[.\-]", v)]


def current(text, pattern):
    m = re.search(pattern, text)
    if not m:
        raise RuntimeError(f"{pattern!r} not found in the recipe")
    return m.group(1)


def replace_hash(text, old, new):
    # happ stores the hash without the sha256- prefix; keep that format.
    if not old.startswith("sha256-"):
        new = new.removeprefix("sha256-")
    return text.replace(old, new)


def simple(file, latest_fn, url_fn, hash_re=r'(?:hash|sha256) = "([^"]+)"', name_fn=None):
    """A recipe with one version line and one hash line."""

    def update(check):
        path = PKGS / file
        text = path.read_text()
        old_v = current(text, r'version = "([^"]+)"')
        new_v = latest_fn()
        if vkey(new_v) <= vkey(old_v):
            return old_v, None
        if check:
            return old_v, new_v
        old_h = current(text, hash_re)
        new_h, _ = prefetch(url_fn(new_v), name_fn(new_v) if name_fn else None)
        text = replace_hash(text.replace(old_v, new_v), old_h, new_h)
        path.write_text(text)
        return old_v, new_v

    return update


def claude_desktop(check):
    path = PKGS / "claude-desktop/default.nix"
    text = path.read_text()
    old_v = current(text, r'version = "([^"]+)"')
    index = fetch("https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages")
    entries = {}
    for block in index.split("\n\n"):
        f = dict(re.findall(r"^(\w+): (.*)$", block, re.M))
        if "Version" in f:
            entries[f["Version"]] = f["SHA256"]
    new_v = max(entries, key=vkey)
    if vkey(new_v) <= vkey(old_v):
        return old_v, None
    if not check:
        old_h = current(text, r'hash = "([^"]+)"')
        path.write_text(text.replace(old_v, new_v).replace(old_h, to_sri(entries[new_v])))
    return old_v, new_v


def claude_code(check):
    path = PKGS / "claude-code/default.nix"
    text = path.read_text()
    old_v = current(text, r'version = "([^"]+)"')
    base = "https://downloads.claude.ai/claude-code-releases"
    new_v = fetch(f"{base}/stable").strip()
    if vkey(new_v) <= vkey(old_v):
        return old_v, None
    if not check:
        manifest = json.loads(fetch(f"{base}/{new_v}/manifest.json"))
        new_h = to_sri(manifest["platforms"]["linux-x64"]["checksum"])
        old_h = current(text, r'hash = "([^"]+)"')
        path.write_text(text.replace(old_v, new_v).replace(old_h, new_h))
    return old_v, new_v


def chatgpt(check):
    # The link always serves the latest release, so read the version from the .deb.
    path = PKGS / "chatgpt/default.nix"
    sha_file = PKGS / "chatgpt/source.sha256"
    text = path.read_text()
    old_v = current(text, r'version = "([^"]+)"')
    new_h, deb = prefetch(
        "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb",
        "chatgpt_amd64.deb",
    )
    if new_h == sha_file.read_text().strip():
        return old_v, None
    new_v = run("nix", "shell", "nixpkgs#dpkg", "-c", "dpkg-deb", "-f", deb, "Version").stdout.strip()
    if not check:
        path.write_text(text.replace(f'version = "{old_v}"', f'version = "{new_v}"'))
        sha_file.write_text(new_h + "\n")
    return old_v, new_v


def go_tool(name, repo):
    """The `name = bump name { ... };` block in packages/go-tools/default.nix."""

    def update(check):
        path = PKGS / "go-tools/default.nix"
        text = path.read_text()
        m = re.search(rf"  {name} = bump {name} \{{.*?\n  \}};", text, re.S)
        block = m.group(0)
        old_v = current(block, r'version = "([^"]+)"')
        new_v = github_latest(repo)
        if vkey(new_v) <= vkey(old_v):
            return old_v, None
        if check:
            return old_v, new_v
        src_hash = json.loads(run("nix", "flake", "prefetch", "--json", f"github:{repo}/v{new_v}").stdout)["hash"]
        new_block = block.replace(f'version = "{old_v}"', f'version = "{new_v}"')
        new_block = new_block.replace(current(block, r' hash = "([^"]+)"'), src_hash)
        new_block = new_block.replace(current(block, r'vendorHash = "([^"]+)"'), FAKE_HASH)
        path.write_text(text.replace(block, new_block))
        # vendorHash is only known from the build error.
        out = run("nix", "build", "--no-link", f"{REPO}#go-tools.{name}", check=False).stderr
        got = re.search(r"got:\s+(sha256-\S+)", out)
        if not got:
            path.write_text(text)
            raise RuntimeError(f"could not get vendorHash:\n{out[-2000:]}")
        path.write_text(path.read_text().replace(FAKE_HASH, got.group(1)))
        return old_v, new_v

    return update


UPDATERS = {
    "claude-desktop": claude_desktop,
    "claude-code": claude_code,
    "chatgpt": chatgpt,
    "happ": simple(
        "happ/default.nix",
        lambda: github_latest("Happ-proxy/happ-desktop"),
        lambda v: f"https://github.com/Happ-proxy/happ-desktop/releases/download/{v}/Happ.linux.x64.deb",
    ),
    "jaeger": simple(
        "jaeger/default.nix",
        lambda: github_latest("jaegertracing/jaeger"),
        lambda v: f"https://github.com/jaegertracing/jaeger/releases/download/v{v}/jaeger-{v}-linux-amd64.tar.gz",
    ),
    "postman": simple(
        "postman/default.nix",
        lambda: json.loads(fetch("https://dl.pstmn.io/api/version/latest?platform=linux64"))["version"],
        lambda v: f"https://dl.pstmn.io/download/version/{v}/linux64",
        name_fn=lambda v: f"postman-{v}.tar.gz",
    ),
    "golangci-lint": go_tool("golangci-lint", "golangci/golangci-lint"),
    "oapi-codegen": go_tool("oapi-codegen", "oapi-codegen/oapi-codegen"),
    "goose": go_tool("goose", "pressly/goose"),
}


def main():
    args = sys.argv[1:]
    check = "--check" in args
    names = [a for a in args if not a.startswith("-")] or list(UPDATERS)
    unknown = set(names) - set(UPDATERS)
    if unknown:
        sys.exit(f"unknown packages: {', '.join(sorted(unknown))}; available: {', '.join(UPDATERS)}")

    failed = False
    for name in names:
        try:
            old, new = UPDATERS[name](check)
        except Exception as e:  # noqa: BLE001
            print(f"✗ {name}: {e}")
            failed = True
            continue
        if new is None:
            print(f"  {name}: {old}, up to date")
        else:
            print(f"{'↑' if check else '✓'} {name}: {old} → {new}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
