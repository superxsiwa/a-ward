#!/usr/bin/env python3
"""Draws the app icon into assets/branding/: a white heart crossed by an ECG trace, on the sky
gradient of superxsiwa's palette (sky-400 to sky-700).

    python3 tool/make_icon.py && dart run flutter_launcher_icons

Run from mobile/. Needs Pillow. Drawn at 4x and scaled down for smooth edges.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path("assets/branding")
SIZE = 1024
SS = 4  # supersampling
SKY_TOP = (56, 189, 248)  # sky-400
SKY_BOTTOM = (3, 105, 161)  # sky-700
TRACE = (14, 165, 233)  # sky-500


def heart_points(cx, cy, r, n=720):
    """The classic heart curve, scaled so its width is about 2r, centred on (cx, cy)."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * r / 16, cy - y * r / 16 - r * 0.08))
    return pts


def ecg_points(cx, cy, w, h):
    """One beat across the heart: flat, P wave, QRS spike, T wave, flat (his BEAT_PATH shape)."""
    beat = [(0, 0), (0.28, 0), (0.33, -0.12), (0.38, 0), (0.43, 0), (0.47, 0.18),
            (0.52, -1.0), (0.57, 0.62), (0.61, 0), (0.70, 0), (0.77, -0.22), (0.84, 0), (1, 0)]
    return [(cx - w / 2 + x * w, cy + y * h) for x, y in beat]


def gradient(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        f = y / (size - 1)
        c = tuple(round(a + (b - a) * f) for a, b in zip(SKY_TOP, SKY_BOTTOM))
        for x in range(size):
            px[x, y] = c
    return img


def foreground(scale, heart_fill, trace_color, heart_r):
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s / 2
    d.polygon(heart_points(c, c, heart_r * s * scale), fill=heart_fill)
    trace = ecg_points(c, c + 0.02 * s * scale, 0.86 * heart_r * 2 * s * scale, 0.30 * s * scale)
    d.line(trace, fill=trace_color, width=round(0.045 * s * scale), joint="curve")
    for p in (trace[0], trace[-1]):
        rr = 0.0225 * s * scale
        d.ellipse([p[0] - rr, p[1] - rr, p[0] + rr, p[1] + rr], fill=trace_color)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    white = (255, 255, 255, 255)
    # Adaptive icon: flutter_launcher_icons insets the foreground by 16% itself, so draw it full size.
    fg = foreground(0.95, white, TRACE + (255,), 0.30)
    fg.save(OUT / "icon-foreground.png")
    gradient(SIZE).save(OUT / "icon-background.png")
    # Themed (monochrome) icon: the heart with the trace cut out.
    mono = foreground(0.95, white, (0, 0, 0, 0), 0.30)
    mono.save(OUT / "icon-monochrome.png")
    # Full icon for iOS, the web and older Android: gradient plus a larger heart.
    full = gradient(SIZE).convert("RGBA")
    full.alpha_composite(foreground(1.0, white, TRACE + (255,), 0.30))
    full.convert("RGB").save(OUT / "icon-full.png")
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("icon-*.png"))))


if __name__ == "__main__":
    main()
