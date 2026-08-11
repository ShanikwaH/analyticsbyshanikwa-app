"""
Required store graphics, generated from the real brand assets.

    python tools/store_graphics.py

Google Play will not let you publish without:
  * a 1024x500 feature graphic
  * a 512x512 icon (32-bit PNG)

Colours come from lib/app_config.dart so this cannot drift from the app:
  indigo #667EEA -> plum #764BA2  (gradIndigoPlum, the hero gradient)
  navy   #0F172A                  (brand navy)
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "graphics"
ICON = ROOT / "icon_src" / "icon_master.png"
ORB = ROOT / "assets" / "brand" / "logo_orb.png"

INDIGO = (102, 126, 234)
PLUM = (118, 74, 162)
WHITE = (255, 255, 255)

FONTS = [
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
    r"C:\Windows\Fonts\seguisb.ttf",
]
FONTS_REG = [
    r"C:\Windows\Fonts\segoeui.ttf",
    r"C:\Windows\Fonts\arial.ttf",
]


def font(paths, size):
    for p in paths:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def horizontal_gradient(w, h, left, right):
    base = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(base)
    for x in range(w):
        t = x / max(1, w - 1)
        draw.line(
            [(x, 0), (x, h)],
            fill=tuple(round(left[i] + (right[i] - left[i]) * t) for i in range(3)),
        )
    return base


def circular_orb(size, at):
    """assets/brand/logo_orb.png is a round orb sitting on an opaque square of
    swirl artwork. Pasted as-is on the gradient it reads as a stray rectangle,
    so cut the circle out and drop the square."""
    src = Image.open(ORB).convert("RGBA")
    w, h = src.size
    # The white ring is inset from the edges; measured against the 512px source.
    cx, cy, r = w * 0.506, h * 0.496, w * 0.362
    box = (round(cx - r), round(cy - r), round(cx + r), round(cy + r))
    orb = src.crop(box).resize((size, size), Image.LANCZOS)

    mask = Image.new("L", (size * 4, size * 4), 0)          # 4x for a smooth edge
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    orb.putalpha(mask.resize((size, size), Image.LANCZOS))
    return orb, at, orb


def feature_graphic():
    """1024x500. Play crops the edges on some surfaces, so everything
    important stays well inside a safe margin."""
    w, h = 1024, 500
    img = horizontal_gradient(w, h, INDIGO, PLUM)
    draw = ImageDraw.Draw(img)

    img.paste(*circular_orb(190, at=(78, 155)))

    x = 290
    draw.text((x, 170), "Analytics by Shanikwa", font=font(FONTS, 60), fill=WHITE)
    draw.text((x, 248), "Bible stories, real games,", font=font(FONTS_REG, 34),
              fill=(228, 226, 250))
    draw.text((x, 292), "and templates that actually work.", font=font(FONTS_REG, 34),
              fill=(228, 226, 250))
    draw.text((x, 352), "20+ games  ·  30 stories  ·  works offline",
              font=font(FONTS, 26), fill=(206, 202, 245))

    path = OUT / "play-feature-graphic-1024x500.png"
    img.save(path)
    return path, img.size


def play_icon():
    """512x512, 32-bit PNG. Play shows it on a light and a dark surface, so a
    transparent background would look broken on one of them - keep it opaque."""
    img = Image.open(ICON).convert("RGBA").resize((512, 512), Image.LANCZOS)
    flat = Image.new("RGB", (512, 512), (15, 23, 42))
    flat.paste(img, (0, 0), img)
    path = OUT / "play-icon-512.png"
    flat.convert("RGBA").save(path)
    return path, flat.size


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for fn, expect in ((feature_graphic, (1024, 500)), (play_icon, (512, 512))):
        path, size = fn()
        ok = "OK " if size == expect else "BAD"
        print(f"  {ok} {path.name}  {size[0]}x{size[1]}")


def _brand_panel(w, h, orb_frac, title_size, sub_size, title_y_frac):
    """Shared layout for the Microsoft Store logo images: brand gradient,
    the circular orb, then the name. Sized by fraction so one layout serves
    both the 9:16 poster and the 1:1 box art."""
    img = horizontal_gradient(w, h, INDIGO, PLUM)
    draw = ImageDraw.Draw(img)
    size = int(min(w, h) * orb_frac)
    orb, _, mask = circular_orb(size, (0, 0))
    img.paste(orb, ((w - size) // 2, int(h * title_y_frac) - size - int(h * 0.06)), mask)

    f_title = font(FONTS, title_size)
    f_sub = font(FONTS_REG, sub_size)
    for text, f, dy, fill in (
        ("Analytics by Shanikwa", f_title, 0, WHITE),
        ("Bible stories · games · templates", f_sub,
         int(title_size * 1.35), (223, 220, 250)),
    ):
        tw = draw.textbbox((0, 0), text, font=f)[2]
        draw.text(((w - tw) // 2, int(h * title_y_frac) + dy), text, font=f, fill=fill)
    return img


def poster_9x16():
    """Main Store logo on Windows 10/11."""
    img = _brand_panel(1440, 2160, 0.46, 96, 44, 0.62)
    p = OUT / "ms-poster-9x16-1440x2160.png"
    img.save(p)
    return p, img.size


def boxart_1x1():
    """Fallback/secondary logo used in various Store layouts."""
    img = _brand_panel(1080, 1080, 0.44, 74, 34, 0.66)
    p = OUT / "ms-boxart-1x1-1080x1080.png"
    img.save(p)
    return p, img.size


if True:
    OUT.mkdir(parents=True, exist_ok=True)
    for fn, expect in ((poster_9x16, (1440, 2160)), (boxart_1x1, (1080, 1080))):
        path, size = fn()
        print(f"  {'OK ' if size == expect else 'BAD'} {path.name}  {size[0]}x{size[1]}")
