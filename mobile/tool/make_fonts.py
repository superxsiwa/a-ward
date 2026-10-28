#!/usr/bin/env python3
"""Cuts Google Sans (SIL OFL 1.1, variable: opsz, wght, GRAD) into the static weights the app
bundles, keeping only Latin, Thai and punctuation, so the app stays small.

    curl -L -o /tmp/GoogleSans.ttf \\
      'https://raw.githubusercontent.com/google/fonts/main/ofl/googlesans/GoogleSans%5BGRAD%2Copsz%2Cwght%5D.ttf'
    python3 -P tool/make_fonts.py /tmp/GoogleSans.ttf

Run from mobile/. Needs fontTools. Writes assets/fonts/GoogleSans-{Regular,Medium,SemiBold,Bold}.ttf.
"""
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

WEIGHTS = {"Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700}
UNICODES = (
    list(range(0x0020, 0x0100))  # Basic Latin + Latin-1
    + list(range(0x0E00, 0x0E80))  # Thai
    + list(range(0x2000, 0x2070))  # General punctuation (curly quotes, dashes the cases may hold)
    + list(range(0x2070, 0x20A0))  # Super- and subscripts (SpO2's 2)
    + list(range(0x2190, 0x2200))  # Arrows
    + [0x2713, 0x2714, 0x00D7, 0x20AC, 0x2122]  # check marks, multiplication sign, euro, TM
)


def main(source):
    out = Path("assets/fonts")
    for name, wght in WEIGHTS.items():
        font = instancer.instantiateVariableFont(TTFont(source), {"wght": wght, "opsz": 18, "GRAD": 0})
        options = subset.Options()
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        sub = subset.Subsetter(options)
        sub.populate(unicodes=UNICODES)
        sub.subset(font)
        path = out / f"GoogleSans-{name}.ttf"
        font.save(path)
        print(f"{path} {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main(sys.argv[1])
