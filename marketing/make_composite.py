#!/usr/bin/env python3
"""Compose an App Store marketing image: branded background + headline + the
app screenshot with rounded corners and a soft shadow.

Usage:
    python3 make_composite.py SCREENSHOT HEADLINE SUBTEXT OUTPUT [--theme light|dark]
"""
import sys, argparse
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Brand palette (from Assets.xcassets)
ACCENT       = (47, 74, 61)      # #2F4A3D forest green
ACCENT_DARK  = (123, 168, 139)   # #7BA88B sage
BG_LIGHT     = (250, 250, 247)   # #FAFAF7 warm off-white
BG_DARK      = (15, 15, 14)      # #0F0F0E near-black
SUB_LIGHT    = (96, 108, 102)
SUB_DARK     = (170, 178, 173)

# App Store 6.9" portrait canvas
CANVAS_W, CANVAS_H = 1320, 2868

FONT_BOLD = "/Library/Fonts/SF-Pro-Display-Bold.otf"
FONT_MED_CANDIDATES = [
    "/Library/Fonts/SF-Pro-Display-Medium.otf",
    "/Library/Fonts/SF-Pro-Display-Regular.otf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
]

def load_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", size)

def med_font(size):
    for p in FONT_MED_CANDIDATES:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()

def wrap(draw, text, font, max_w):
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial, font=font) <= max_w:
            cur = trial
        else:
            if cur: lines.append(cur)
            cur = w
    if cur: lines.append(cur)
    return lines

def balanced(draw, text, font, max_w):
    """One line if it fits; otherwise the most even 2-line split (no orphan
    words). Falls back to greedy wrapping for very long text."""
    if draw.textlength(text, font=font) <= max_w:
        return [text]
    words = text.split()
    best = None
    for i in range(1, len(words)):
        l1, l2 = " ".join(words[:i]), " ".join(words[i:])
        w1, w2 = draw.textlength(l1, font=font), draw.textlength(l2, font=font)
        if w1 <= max_w and w2 <= max_w:
            score = max(w1, w2)
            if best is None or score < best[0]:
                best = (score, [l1, l2])
    return best[1] if best else wrap(draw, text, font, max_w)

def draw_centered(draw, lines, font, top, color, line_gap):
    y = top
    for ln in lines:
        w = draw.textlength(ln, font=font)
        draw.text(((CANVAS_W - w) / 2, y), ln, font=font, fill=color)
        asc, desc = font.getmetrics()
        y += asc + desc + line_gap
    return y

def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0], img.size[1]], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("screenshot"); ap.add_argument("headline")
    ap.add_argument("subtext"); ap.add_argument("output")
    ap.add_argument("--theme", default="light", choices=["light", "dark"])
    a = ap.parse_args()

    dark = a.theme == "dark"
    bg     = BG_DARK if dark else BG_LIGHT
    accent = ACCENT_DARK if dark else ACCENT
    subcol = SUB_DARK if dark else SUB_LIGHT

    canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), bg)
    draw = ImageDraw.Draw(canvas)

    margin = 110
    h_font = load_font(FONT_BOLD, 112)
    s_font = med_font(50)

    # Headline + subtext, centered near the top.
    h_lines = balanced(draw, a.headline, h_font, CANVAS_W - 2 * margin)
    y = draw_centered(draw, h_lines, h_font, 170, accent, 8)
    s_lines = wrap(draw, a.subtext, s_font, CANVAS_W - 2 * margin)
    y = draw_centered(draw, s_lines, s_font, y + 24, subcol, 6)

    # Screenshot: scale to width, round corners, soft shadow, bleed off bottom.
    shot = Image.open(a.screenshot).convert("RGBA")
    target_w = 900
    scale = target_w / shot.width
    shot = shot.resize((target_w, int(shot.height * scale)), Image.LANCZOS)
    shot = rounded(shot, 56)

    x = (CANVAS_W - target_w) // 2
    top = int(y + 70)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sh = Image.new("RGBA", shot.size, (0, 0, 0, 90))
    sh.putalpha(rounded(sh, 56).split()[3])
    shadow.paste(sh, (x, top + 24), sh)
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)
    canvas.paste(shot, (x, top), shot)

    canvas.convert("RGB").save(a.output, "PNG")
    print(f"wrote {a.output} ({CANVAS_W}x{CANVAS_H})")

if __name__ == "__main__":
    main()
