#!/usr/bin/env python3
# .github/scripts/update_security_versions.py

import os
import re
import sys
import requests
import yaml
from collections import defaultdict
from packaging.version import Version, InvalidVersion

REPO = os.environ.get("GITHUB_REPOSITORY")  # "OWNER/REPO" (set by GitHub Actions)
TOKEN = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
API = "https://api.github.com"

SECURITY_MD = "SECURITY.md"
CFG_PATH = "SECURITY_SUPPORT.yaml"

START = "<!-- SECURITY-VERSIONS:START -->"
END = "<!-- SECURITY-VERSIONS:END -->"


def gh(url, params=None):
    headers = {"Accept": "application/vnd.github+json"}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    r = requests.get(url, headers=headers, params=params, timeout=30)
    r.raise_for_status()
    return r.json()


def load_cfg():
    with open(CFG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def parse_tag(tag, prefix):
    if prefix and tag.startswith(prefix):
        tag = tag[len(prefix) :]
    try:
        v = Version(tag)
        return v
    except InvalidVersion:
        return None


def fetch_all_tags():
    tags = []
    page = 1
    while True:
        data = gh(f"{API}/repos/{REPO}/tags", params={"per_page": 100, "page": page})
        if not data:
            break
        tags.extend([t["name"] for t in data])
        page += 1
    return tags


def minor_key(v: Version) -> str:
    return f"{v.major}.{v.minor}"


def build_table(cfg, tags):
    prefix = cfg.get("tag_prefix", "v")
    lts = set(cfg.get("lts_minors", []) or [])
    deny = set(cfg.get("unsupported_minors", []) or [])
    minor_window = int(cfg.get("minor_window", 1))
    newest_first = bool(cfg.get("newest_first", True))

    versions = []
    for t in tags:
        v = parse_tag(t, prefix)
        if v:
            versions.append(v)

    if not versions:
        return "| Version | Supported |\n| ------- | --------- |\n| (no tags) | ❌ No |\n"

    minors = defaultdict(list)
    for v in versions:
        minors[minor_key(v)].append(v)

    minor_list = sorted(minors.keys(), key=lambda m: Version(m + ".0"), reverse=True)

    supported = set(minor_list[:minor_window])
    supported |= lts
    supported -= deny

    rows = []
    for m in minor_list:
        badge = "✅ Yes" if m in supported else "❌ No"
        rows.append((Version(m + ".0"), f"| {m}.x | {badge} |"))

    rows.sort(key=lambda x: x[0], reverse=newest_first)
    body = "\n".join(r for _, r in rows)
    table = (
        "| Version | Supported |\n"
        "| ------- | --------- |\n"
        f"{body}\n"
    )
    return table


def replace_block(md_text, new_table):
    pattern = re.compile(re.escape(START) + r".*?" + re.escape(END), re.DOTALL | re.MULTILINE)
    block = START + "\n" + new_table + END
    if pattern.search(md_text):
        return pattern.sub(block, md_text)
    else:
        return md_text.rstrip() + "\n\n" + block + "\n"


def main():
    if not REPO:
        print("GITHUB_REPOSITORY not set", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(CFG_PATH):
        print(f"{CFG_PATH} not found", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(SECURITY_MD):
        print(f"{SECURITY_MD} not found", file=sys.stderr)
        sys.exit(1)

    cfg = load_cfg()
    tags = fetch_all_tags()
    table = build_table(cfg, tags)

    with open(SECURITY_MD, "r", encoding="utf-8") as f:
        md = f.read()
    new_md = replace_block(md, table)

    if new_md != md:
        with open(SECURITY_MD, "w", encoding="utf-8") as f:
            f.write(new_md)
        print("SECURITY.md updated.")
    else:
        print("No changes needed.")


if __name__ == "__main__":
    main()
