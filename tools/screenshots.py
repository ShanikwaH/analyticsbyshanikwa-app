"""
Store screenshots, captured from the live app.

    python tools/screenshots.py

Flutter web renders to a <canvas> with CanvasKit, so there is no DOM to query
and no accessibility tree by default. Everything here therefore clicks by
coordinate, computed from the layout in lib/screens/home_shell.dart:

  width <  840  -> Material NavigationBar along the bottom (phone)
  width >= 840  -> NavigationRail down the left (desktop)

If that breakpoint or the section list changes, these coordinates must change
with it. The script re-checks the pixel size of every file it writes, so a
silently-wrong capture fails loudly rather than shipping.
"""

import sys
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

URL = "https://app.analyticsbyshanikwa.com/"
OUT = Path(__file__).resolve().parent.parent / "store" / "screenshots"

# AppConfig.sections for the 'full' build.
TABS = ["today", "stories", "play", "shop"]

# Google Play: 9:16, each side 320-3840 px. 1080x1920 is the safe default.
PHONE_CSS = (540, 960)
PHONE_SCALE = 2
# Microsoft Store desktop: 1366x768 is the documented minimum.
DESK_CSS = (1366, 768)
DESK_SCALE = 1

RENDER_WAIT = 6.0   # CanvasKit + remote content.json
TAB_WAIT = 2.5      # let the new tab settle/animate


def settle(page, seconds):
    try:
        page.wait_for_load_state("networkidle", timeout=20000)
    except Exception:
        pass
    time.sleep(seconds)


def phone_tab_point(index, count, w, h):
    """Centre of destination `index` in the bottom NavigationBar."""
    return ((index + 0.5) * w / count, h - 40)


# main.dart's MaterialApp.builder caps content at this width and centres it,
# so on a wide viewport the rail is NOT at x=0 - it starts at the left edge of
# the centred 900px band. Getting this wrong silently captures the same tab
# four times, which is exactly what happened the first time.
CONTENT_MAX_WIDTH = 900


def rail_tab_point(index, _count, w, _h):
    """Centre of destination `index` in the left NavigationRail."""
    left = max(0, (w - CONTENT_MAX_WIDTH) / 2)
    return (left + 40, 115 + index * 64)


def capture(page, out_dir, prefix, css, scale, point_fn):
    w, h = css
    shots = []
    for i, name in enumerate(TABS):
        if i:
            x, y = point_fn(i, len(TABS), w, h)
            page.mouse.click(x, y)
            time.sleep(TAB_WAIT)
        path = out_dir / f"{prefix}-{i+1}-{name}.png"
        page.screenshot(path=str(path))
        shots.append(path)
        print(f"    {path.name}")
    return shots, (w * scale, h * scale)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    written = []

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome")

        for prefix, css, scale, point_fn in (
            ("phone", PHONE_CSS, PHONE_SCALE, phone_tab_point),
            ("desktop", DESK_CSS, DESK_SCALE, rail_tab_point),
        ):
            print(f"  {prefix}: {css[0]}x{css[1]} @{scale}x")
            ctx = browser.new_context(
                viewport={"width": css[0], "height": css[1]},
                device_scale_factor=scale,
            )
            page = ctx.new_page()
            page.goto(URL, wait_until="domcontentloaded")
            settle(page, RENDER_WAIT)
            shots, expect = capture(page, OUT, prefix, css, scale, point_fn)
            written.append((shots, expect))
            ctx.close()

        browser.close()

    # Verify rather than assume. A blank-frame check alone is not enough: if the
    # tab clicks miss, every file is a valid, non-blank picture of the SAME tab.
    # So also require every screenshot in a set to be distinct.
    import hashlib

    from PIL import Image
    bad = 0
    for shots, expect in written:
        seen = {}
        for path in shots:
            with Image.open(path) as im:
                size = im.size
                colours = im.convert("RGB").getcolors(maxcolors=100000)
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if size != expect:
                print(f"  WRONG SIZE {path.name}: {size} != {expect}")
                bad += 1
            elif colours is not None and len(colours) < 12:
                print(f"  LOOKS BLANK {path.name}: only {len(colours)} colours")
                bad += 1
            elif digest in seen:
                print(f"  DUPLICATE {path.name} is identical to {seen[digest]}"
                      f" - the tab click missed")
                bad += 1
            seen[digest] = path.name
    print(f"\n  {sum(len(s) for s, _ in written)} files, {bad} problem(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
