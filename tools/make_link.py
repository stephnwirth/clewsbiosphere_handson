#!/usr/bin/env python3
"""Create a webR share link that opens hands_on_session.R (and plot_map.R) in the browser IDE.

Usage:
    python3 tools/make_link.py OWNER/REPO [--branch main] [--webr latest]

It also writes the GitHub location of the data into the script's `data_url`
line, so the copy in the repo and the copy in the link stay the same.
Format of the link (msgpack/JSON, zlib, base64, flags after `&`):
https://github.com/r-wasm/webr/blob/main/src/repl/components/Share.tsx
"""
import argparse
import base64
import json
import pathlib
import re
import urllib.parse
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "hands_on_session.R"
HELPERS = [ROOT / "plot_map.R"]  # opened as extra tabs, sourced by the script

ap = argparse.ArgumentParser()
ap.add_argument("repo", help="GitHub OWNER/REPO that hosts data/lpjml_lecture.zip")
ap.add_argument("--branch", default="main")
ap.add_argument("--webr", default="latest", help="webR app version, e.g. latest or v0.6.1")
args = ap.parse_args()

data_url = (f"https://raw.githubusercontent.com/{args.repo}/{args.branch}"
            "/data/lpjml_lecture.zip")
text = SCRIPT.read_text(encoding="utf-8")
text, n = re.subn(r'^data_url <- ".*"$', f'data_url <- "{data_url}"', text, flags=re.M)
if n != 1:
    raise SystemExit("could not find the data_url line in the script")
SCRIPT.write_bytes(text.encode("utf-8"))  # keep LF line endings on Windows too

items = [{"name": SCRIPT.name, "path": f"/home/web_user/{SCRIPT.name}", "text": text}]
items += [{"name": h.name, "path": f"/home/web_user/{h.name}", "text": h.read_text(encoding="utf-8")}
          for h in HELPERS]
payload = zlib.compress(json.dumps(items).encode("utf-8"), 9)
code = urllib.parse.quote(base64.b64encode(payload).decode("ascii"), safe="")
print(f"https://webr.r-wasm.org/{args.webr}/#code={code}&jz")
