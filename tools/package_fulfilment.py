#!/usr/bin/env python3
"""
Package every catalog product into one downloadable file, ready for R2.

Sources
  digital-products-100/products/<ID>-<handle>/   the individual product files
  .../Shopify Bundle Downloads/*.zip             the pre-built bundle zips

Output
  worker/.staging/<id>.zip           one file per product
  worker/product-files.json          productId -> R2 object key, for the Worker

Folders holding a single file are still zipped, so every product is delivered
the same way and the Worker has one content type to think about.

These go to a PRIVATE R2 bucket, not the public site. That is the whole point
of the Worker: objects are never publicly addressable, and the only way to one
is a signed link that expires in five minutes.

    python tools/package_fulfilment.py            # build the zips
    python tools/package_fulfilment.py --upload   # ...and push them to R2
"""
import io
import json
import os
import subprocess
import sys
import zipfile
from collections import OrderedDict

APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DP = os.path.join(os.path.dirname(APP), "digital-products-100", "products")
BUNDLES = ("C:/Users/nikki/OneDrive/0 A Etsy-TikTok-YouTube Content Business/"
           "Etsy Shop/Cursor-Claude Code Digital Products/Shopify Bundle Downloads")
STAGING = os.path.join(APP, "worker", ".staging")
MAPPING = os.path.join(APP, "worker", "product-files.json")
BUCKET = "abs-fulfilment"


def load_catalog():
    p = os.path.join(APP, "assets", "content", "content.json")
    with io.open(p, encoding="utf-8") as fh:
        return json.load(fh)["catalog"]


def folder_for(pid):
    """Product folders are named '<ID>-<handle>', so the id prefix is the key."""
    if not os.path.isdir(DP):
        return None
    for name in os.listdir(DP):
        if name.startswith(pid + "-"):
            return os.path.join(DP, name)
    return None


def bundle_zip_for(item):
    """A bundle's iap_id ends in the zip's slug, e.g. ...bundle.cpa_exam_prep_bundle."""
    if not item["iap_id"] or not os.path.isdir(BUNDLES):
        return None
    slug = item["iap_id"].rsplit(".", 1)[-1]
    for z in os.listdir(BUNDLES):
        if z.endswith(".zip") and z[:-4].lower().replace("-", "_") == slug:
            return os.path.join(BUNDLES, z)
    return None


def main(argv):
    catalog = load_catalog()
    os.makedirs(STAGING, exist_ok=True)

    mapping = OrderedDict()
    built = skipped = 0
    total_bytes = 0

    for item in catalog:
        pid = item["id"]
        out = os.path.join(STAGING, f"{pid}.zip")

        src_zip = bundle_zip_for(item)
        if src_zip:
            # Already a zip built for the storefront — ship it byte for byte.
            with open(src_zip, "rb") as fh:
                data = fh.read()
            with open(out, "wb") as fh:
                fh.write(data)
        else:
            folder = folder_for(pid)
            if not folder:
                skipped += 1
                continue
            files = [f for f in sorted(os.listdir(folder))
                     if os.path.isfile(os.path.join(folder, f))]
            if not files:
                skipped += 1
                continue
            with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
                for f in files:
                    z.write(os.path.join(folder, f), arcname=f)

        size = os.path.getsize(out)
        total_bytes += size
        built += 1
        # Key by product id, not title: titles change, ids do not.
        key = f"products/{pid}.zip"
        # Only products that can actually be bought in-app need a mapping
        # entry; the rest are link-out only and never reach the Worker.
        if item["iap_id"]:
            mapping[item["iap_id"]] = key

    with io.open(MAPPING, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(json.dumps(mapping, indent=2) + "\n")

    print(f"  packaged {built} products ({total_bytes/1024/1024:,.1f} MB), "
          f"{skipped} skipped (no source files)")
    print(f"  {len(mapping)} in-app-purchasable products mapped -> {os.path.relpath(MAPPING, APP)}")

    if "--upload" not in argv:
        print("\n  Dry run. Re-run with --upload to push to R2.")
        return 0

    # Only upload what the Worker can actually serve. The other ~104 products
    # are link-out only, so putting them in R2 would be storage with no reader.
    to_upload = [i for i in catalog if i["iap_id"]]
    print(f"\n  uploading {len(to_upload)} purchasable products to R2 '{BUCKET}' …")
    ok = fail = 0
    for item in to_upload:
        pid = item["id"]
        f = os.path.join(STAGING, f"{pid}.zip")
        if not os.path.isfile(f):
            continue
        r = subprocess.run(
            ["npx", "wrangler", "r2", "object", "put",
             f"{BUCKET}/products/{pid}.zip", "--file", f, "--remote"],
            capture_output=True, text=True, shell=True)
        if r.returncode == 0:
            ok += 1
        else:
            fail += 1
            print(f"    ! {pid}: {r.stderr.strip().splitlines()[-1][:120]}")
    print(f"  uploaded {ok}, failed {fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
