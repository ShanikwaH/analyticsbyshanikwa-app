#!/usr/bin/env python3
"""
Publish the paid product files and wire their download URLs into content.json.

This is the one prerequisite for turning in-app purchase on: after an IAP the
app has to hand the buyer an actual file, and Payhip's download links are
per-purchase so they cannot be baked in.

WHAT IT DOES
  1. Copies each file into analyticsbyshanikwa.com/app/files/ under an
     unguessable slug (16 random hex chars + the real extension).
  2. Writes that URL into `fulfillment_url` for the matching product in both
     assets/content/content.json and remote/content.json.
  3. Bumps the remote version so installed apps pick it up with no app release.

USAGE
    python tools/publish_fulfillment.py \
        p1="C:/path/Scripture Memory System.xlsx" \
        p2="C:/path/Bible Timeline Spreadsheet.xlsx" \
        p3="C:/path/Career Pivot Suite Guide.pdf" \
        p4="C:/path/ADHD Life Planner Bundle.pdf"

  Product ids are p1..p4 — run with --list to see them with their titles.
  You can do them one at a time; ids you omit are left alone.

  --dry-run  shows what it would do and changes nothing.

THEN
    cd ../analyticsbyshanikwa.com && git add app/ robots.txt \
      && git commit -m "fulfilment files" && git push
    # rebuild + redeploy the app only if you want the bundled copy updated;
    # the remote content.json alone is enough for installed apps.

SECURITY, STATED PLAINLY
  These end up as public URLs with unguessable names, and GitHub Pages cannot
  send an X-Robots-Tag header, so robots.txt is the only crawl protection —
  it is a request, not a wall. Anyone who has a link can pass it on. That is
  the normal trade-off for $15-20 templates. If it ever matters, move the files
  behind a Cloudflare Worker that validates a store receipt and issues a
  short-lived signed URL; only `fulfillment_url` changes.
  Re-running this for a product mints a NEW slug, which is how you rotate a
  link that leaked. The old file is deleted.
"""
import json
import os
import re
import secrets
import shutil
import sys
from collections import OrderedDict

APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = os.path.join(os.path.dirname(APP), "analyticsbyshanikwa.com")
FILES_DIR = os.path.join(SITE, "app", "files")
BASE_URL = "https://analyticsbyshanikwa.com/app/files"
CONTENT_FILES = [
    (os.path.join(APP, "assets", "content", "content.json"), False),
    (os.path.join(APP, "remote", "content.json"), True),
]


def load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh, object_pairs_hook=OrderedDict)


def save(path, data):
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def main(argv):
    content = load(CONTENT_FILES[0][0])
    products = {p["id"]: p for p in content["products"]}

    if "--list" in argv or not argv:
        print("Products awaiting a fulfilment file:\n")
        for pid, p in products.items():
            state = p.get("fulfillment_url") or "(none yet)"
            print(f'  {pid}  {p["title"]:38} {p["price"]:>7}  {p["format"]}')
            print(f'      -> {state}')
        print("\nUsage: python tools/publish_fulfillment.py p1=\"path/to/file.xlsx\" ...")
        return 0

    dry = "--dry-run" in argv
    pairs = [a for a in argv if "=" in a]
    if not pairs:
        print("Nothing to do. Pass id=path pairs, or --list.")
        return 1

    if not os.path.isdir(SITE):
        print(f"Site repo not found at {SITE}")
        return 1
    if not dry:
        os.makedirs(FILES_DIR, exist_ok=True)

    updates = {}
    for pair in pairs:
        pid, src = pair.split("=", 1)
        src = src.strip().strip('"')
        if pid not in products:
            print(f"  ! unknown product id {pid} (expected one of {list(products)})")
            return 1
        if not os.path.isfile(src):
            print(f"  ! file not found: {src}")
            return 1
        ext = os.path.splitext(src)[1].lower() or ".bin"
        # Slug carries a readable hint plus real entropy, so a leaked link
        # cannot be guessed from the product name alone.
        hint = re.sub(r"[^a-z0-9]+", "-", products[pid]["title"].lower()).strip("-")[:28]
        slug = f"{hint}-{secrets.token_hex(8)}{ext}"
        dest = os.path.join(FILES_DIR, slug)
        size = os.path.getsize(src) / 1024
        print(f'  {pid}  {products[pid]["title"]}')
        print(f'      {os.path.basename(src)}  ({size:,.0f} KB)')
        print(f'      -> {BASE_URL}/{slug}')
        if not dry:
            # Rotating: drop any previous file for this product.
            old = products[pid].get("fulfillment_url", "")
            if old.startswith(BASE_URL):
                prev = os.path.join(FILES_DIR, old.rsplit("/", 1)[-1])
                if os.path.isfile(prev):
                    os.remove(prev)
                    print(f'      (removed previous {os.path.basename(prev)})')
            shutil.copy2(src, dest)
        updates[pid] = f"{BASE_URL}/{slug}"

    if dry:
        print("\n--dry-run: nothing written.")
        return 0

    for path, bump in CONTENT_FILES:
        data = load(path)
        for p in data["products"]:
            if p["id"] in updates:
                p["fulfillment_url"] = updates[p["id"]]
        if bump:
            data["version"] += 1
        save(path, data)
        print(f'\n  wrote {os.path.relpath(path, APP)}  (version {data["version"]})')

    ready = [p for p in load(CONTENT_FILES[0][0])["products"]
             if p.get("fulfillment_url") and p.get("iap_id")]
    print(f'\n  {len(ready)}/4 products are now fully configured for IAP.')
    if len(ready) < 4:
        print('  Set iap_id on each product and flip commerce.iap_enabled to true '
              'once all four are ready.')
    print('\n  Next: commit the site repo (app/files/ + robots.txt) and push.')
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
