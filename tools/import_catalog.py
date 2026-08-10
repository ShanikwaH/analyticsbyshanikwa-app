#!/usr/bin/env python3
"""
Import the full Shopify/Payhip catalog into the app's content.json.

Sources (all local, all authoritative):
  digital-products-100/catalog.json      100 individual products
  digital-products-100/originals-15.json  15 flagship products/bundles
  .../Shopify Bundle Downloads/*.zip      the sellable bundle files

Shopify product URLs are derived from `handle` — the pattern
https://jrip3r-qz.myshopify.com/products/<handle> was verified live against
the Admin API before this script was written.

Writes a lean `catalog` array. The existing 4-item `products` array is left
alone so the Today/Vault/Trivia screens and their tests keep working.
"""
import json
import io
import os
import re
import sys
from collections import OrderedDict

APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DP = os.path.join(os.path.dirname(APP), "digital-products-100")
BUNDLES = ("C:/Users/nikki/OneDrive/0 A Etsy-TikTok-YouTube Content Business/"
           "Etsy Shop/Cursor-Claude Code Digital Products/Shopify Bundle Downloads")
SHOP = "https://jrip3r-qz.myshopify.com/products"
PAYHIP_STORE = "https://payhip.com/AnalyticsByShanikwa"
TRACK = "ref=app&utm_source=app&utm_medium=app&utm_content="

# Category scoring. First-match-wins mislabelled badly — "excel-template" on a
# career product scored it as Data, leaving Career with 1 item out of 115. Now
# every category scores its matches and the highest wins, with tags weighted
# above the title because tags are curated and titles are marketing copy.
CATEGORIES = [
    ("Faith", ("bible", "scripture", "christian", "faith", "theology", "prayer",
               "devotional", "sunday-school", "apologetics", "worship", "tithe",
               "verse", "sermon", "church", "discipleship")),
    ("CPA", ("cpa", "accounting", "far-exam", "audit", "bookkeeping",
             "exam-prep", "financial-statement", "ratio")),
    ("Data", ("data-analyst", "data-analytics", "sql", "power-bi", "pivot",
              "ab-testing", "data-cleaning", "portfolio", "dashboard-bundle",
              "visualization", "statistics")),
    ("Career", ("career", "job-search", "resume", "interview", "salary",
                "linkedin", "onboarding", "federal-jobs", "usajobs",
                "promotion", "new-job")),
    ("Business", ("small-business", "etsy", "creator", "side-hustle", "crm",
                  "email-marketing", "launch", "content-calendar",
                  "freelancer", "seller")),
    ("Life", ("planner", "printable", "homeschool", "kids", "family", "budget",
              "finance", "fitness", "wellness", "caregiver", "burnout",
              "self-care", "declutter", "behavior", "habit", "emergency",
              "meal", "chore", "cleaning")),
]


def categorise(tags, title):
    tagtext = " ".join(tags).lower()
    titletext = title.lower()
    best, score = "Life", 0
    for name, needles in CATEGORIES:
        s = sum(3 for n in needles if n in tagtext)
        s += sum(1 for n in needles if n in titletext)
        if s > score:
            best, score = name, s
    return best


def summarise(html, fallback):
    if not html:
        return fallback
    text = re.sub(r"<[^>]+>", " ", html)
    text = re.sub(r"\s+", " ", text).strip()
    text = text.replace("&amp;", "&").replace("&nbsp;", " ").replace("&#39;", "'")
    # First sentence-ish, capped.
    cut = text.split(" — ")[-1] if " — " in text[:120] else text
    return (cut[:180].rsplit(" ", 1)[0] + "…") if len(cut) > 180 else cut


def load(p):
    with io.open(p, encoding="utf-8") as fh:
        return json.load(fh, object_pairs_hook=OrderedDict)


def entry(pid, title, handle, price, fmt, tags, summary, is_bundle, iap=""):
    return OrderedDict([
        ("id", pid),
        ("title", title),
        ("price", f"${float(price):.2f}"),
        ("format", fmt),
        ("category", categorise(tags, title)),
        ("summary", summary),
        ("bundle", is_bundle),
        ("shopify_url", f"{SHOP}/{handle}?{TRACK}{pid}"),
        ("payhip_url", f"{PAYHIP_STORE}?{TRACK}{pid}"),
        ("iap_id", iap),
        ("fulfillment_url", ""),
    ])


def main():
    items = []

    for p in load(os.path.join(DP, "catalog.json")):
        items.append(entry(
            p["id"], p["title"], p["handle"], p["price"],
            p.get("format", "Digital download"), p.get("tags", []),
            summarise(p.get("description_html", ""), p["title"]),
            is_bundle=False))

    zips = sorted(f for f in os.listdir(BUNDLES) if f.endswith(".zip")) \
        if os.path.isdir(BUNDLES) else []

    flagships = load(os.path.join(DP, "originals-15.json"))

    # Match flagships to bundle zips. Each zip belongs to exactly ONE product:
    # a naive best-match-per-product gave "Career Pivot Suite Guide" and
    # "Career Blueprint Job Search Bundle" the same zip, which would have
    # produced duplicate IAP ids — buying one would unlock the other, and both
    # consoles reject duplicate product ids anyway. So score every pair and
    # assign greedily, strongest match first.
    STOP = {"the", "and", "for", "your", "with", "all", "in", "one", "a"}

    def words(s):
        return set(re.findall(r"[a-z]+", s.lower())) - STOP

    pairs = []
    for p in flagships:
        for z in zips:
            n = len(words(p["title"]) & words(z[:-4]))
            if n >= 2:
                pairs.append((n, p["id"], z))
    pairs.sort(reverse=True)

    assigned, taken = {}, set()
    for _n, pid, z in pairs:
        if pid in assigned or z in taken:
            continue
        assigned[pid], _ = z, taken.add(z)

    for p in flagships:
        title = p["title"]
        z = assigned.get(p["id"])
        slug = re.sub(r"[^a-z0-9]+", "_", (z[:-4] if z else title).lower()).strip("_")
        items.append(entry(
            p["id"], title, p["handle"], p["price"],
            "Bundle · multiple files", [title],
            f'Flagship bundle — {p.get("claimed_files", "several")} files.',
            is_bundle=bool(z),
            iap=("com.analyticsbyshanikwa.bundle." + slug) if z else ""))

    ids = [i["iap_id"] for i in items if i["iap_id"]]
    if len(ids) != len(set(ids)):
        dupes = {i for i in ids if ids.count(i) > 1}
        raise SystemExit(f"ABORT: duplicate iap_id(s) {dupes}")

    cats = {}
    for i in items:
        cats[i["category"]] = cats.get(i["category"], 0) + 1

    for path, bump in ((os.path.join(APP, "assets/content/content.json"), False),
                       (os.path.join(APP, "remote/content.json"), True)):
        d = load(path)
        d["catalog"] = items
        if bump:
            d["version"] += 1
        with io.open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        size = os.path.getsize(path) / 1024
        print(f'  {os.path.relpath(path, APP)}  v{d["version"]}  ({size:,.0f} KB)')

    print(f'\n  {len(items)} catalog items '
          f'({sum(1 for i in items if i["bundle"])} bundles, '
          f'{sum(1 for i in items if not i["bundle"])} individual)')
    print('  categories:', ", ".join(f"{k} {v}" for k, v in sorted(cats.items())))
    print(f'  bundle zips available for fulfilment: {len(zips)}')
    print('\n  Bundle IAP ids (create these in both consoles):')
    for i in items:
        if i["iap_id"]:
            print(f'    {i["iap_id"]}   {i["price"]:>8}  {i["title"][:44]}')
    return 0


if __name__ == "__main__":
    sys.exit(main())
