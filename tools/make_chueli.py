#!/usr/bin/env python3
"""Generate the Chueli cow mood images for the e-paper display.

Writes one SVG source and one 1-bit PNG per mood to images/chueli/.
Requires rsvg-convert (brew install librsvg) and Pillow.

    python tools/make_chueli.py
"""

import subprocess
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "images" / "chueli"
WIDTH, HEIGHT = 76, 72
VIEWBOX = "-2 -6 82 78"

INK, PAPER = "#000", "#fff"
OUTLINE = f'fill="{PAPER}" stroke="{INK}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"'
LINE = f'fill="none" stroke="{INK}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"'


def dot(x, y, r=2.4):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}"/>'


def cross(x, y):
    return f'<path d="M{x - 2.5} {y - 2.5} l5 5 M{x - 2.5} {y + 2.5} l5 -5" {LINE}/>'


def drop(x, y):
    return (
        f'<path d="M{x} {y} Q{x - 4} {y + 7} {x} {y + 9} Q{x + 4} {y + 7} {x} {y} Z" '
        f'fill="{PAPER}" stroke="{INK}" stroke-width="1.5"/>'
    )


CLOSED_EYES = f'<path d="M25 33 Q28 36 31 33 M41 33 Q44 36 47 33" {LINE}/>'
SNORE = f'<path d="M58 6 h5 l-5 6 h5 M65 -4 h7 l-7 9 h7" {LINE}/>'
BELL_RINGING = f'<path d="M22 58 l-6 1 M22 63 l-7 1 M50 58 l6 1 M50 63 l7 1" {LINE}/>'

# Faces and props drawn on top of the cow, keyed by mood.
MOODS = {
    "happy": dot(28, 33) + dot(44, 33) + f'<path d="M31 50 Q36 53 41 50" {LINE}/>',
    "sleepy": CLOSED_EYES
    + f'<circle cx="36" cy="51" r="1.8" fill="none" stroke="{INK}" stroke-width="1.6"/>'
    + SNORE,
    "dizzy": cross(28, 33)
    + cross(44, 33)
    + f'<ellipse cx="36" cy="50.5" rx="3" ry="2.2" fill="{INK}"/>'
    + BELL_RINGING,
    "stink": f'<path d="M25.5 30.5 L30.5 33 L25.5 35.5 M46.5 30.5 L41.5 33 L46.5 35.5" {LINE}/>'
    + f'<path d="M31 50.5 q1.25 -2 2.5 0 t2.5 0 t2.5 0 t2.5 0" {LINE}/>'
    + f'<path d="M70 66 q-3 -5 0 -9 t0 -9 t0 -9 M77 70 q-3 -5 0 -9 t0 -9 t0 -9" {LINE}/>',
    "smoke": f'<circle cx="28" cy="33" r="3.4" fill="{PAPER}" stroke="{INK}" stroke-width="1.6"/>'
    + dot(28, 33, 1.5)
    + f'<circle cx="44" cy="33" r="3.4" fill="{PAPER}" stroke="{INK}" stroke-width="1.6"/>'
    + dot(44, 33, 1.5)
    + f'<ellipse cx="36" cy="50.5" rx="2.6" ry="2.4" fill="{INK}"/>'
    + f'<path d="M58 14 C54 14 54 8 59 8 C60 3 67 3 68 7 C72 6 73 13 69 14 Z" {OUTLINE}/>'
    + f'<path d="M64 26 C61 26 61 21 65 21 C66 18 71 18 71 21 C74 21 74 26 71 26 Z" {OUTLINE}/>',
    "raclette": f'<path d="M25 34 Q28 29 31 34 M41 34 Q44 29 47 34" {LINE}/>'
    + f'<path d="M31 49.5 Q36 52.5 41 49.5" {LINE}/>'
    + f'<path d="M37.5 51 v2.5 a2.2 2.2 0 0 0 4.4 0 v-2.5" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"/>'
    + drop(16, 40),
    "cough": f'<path d="M25.5 33 h5 M41.5 33 h5" {LINE}/>'
    + f'<ellipse cx="36" cy="50.5" rx="2.4" ry="2.6" fill="{INK}"/>'
    + f'<circle cx="57" cy="50" r="2.2" {OUTLINE}/><circle cx="63" cy="46" r="1.6" {OUTLINE}/>'
    + f'<circle cx="64" cy="53" r="1.3" {OUTLINE}/>',
    "hot": dot(28, 33)
    + dot(44, 33)
    + f'<path d="M32 50 h8" {LINE}/>'
    + f'<path d="M35 50.5 v3 a2.2 2.2 0 0 0 4.4 0 v-3" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"/>'
    + drop(13, 36)
    + drop(60, 38),
    "cold": dot(28, 33)
    + dot(44, 33)
    + f'<path d="M31 51 l1.7 -1.7 l1.7 1.7 l1.7 -1.7 l1.7 1.7 l1.7 -1.7" {LINE}/>'
    + f'<path d="M19 54 Q36 60 53 54 L53 60 Q36 66 19 60 Z" {OUTLINE}/>'
    + f'<path d="M46 60 l3 9 h5 l-2 -10" {OUTLINE}/>'
    + f'<path d="M8 40 q-2 4 0 8 M4 38 q-3 6 0 12 M64 40 q2 4 0 8 M68 38 q3 6 0 12" {LINE}/>',
    "humid": dot(28, 33)
    + dot(44, 33)
    + f'<path d="M32 50.5 q2 -2 4 0 t4 0" {LINE}/>'
    + drop(8, 6)
    + drop(64, 12)
    + drop(4, 40)
    + drop(66, 40),
    "dry": dot(28, 33)
    + dot(44, 33)
    + f'<path d="M31 49.5 h10" {LINE}/>'
    + f'<path d="M33.5 50 v6 a2.5 2.5 0 0 0 5 0 v-6" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"/>'
    + f'<circle cx="64" cy="10" r="5" {OUTLINE}/>'
    + f'<path d="M64 1 v-1 M72 10 h2 M70 4 l1.5 -1.5 M70 16 l1.5 1.5" {LINE}/>',
    "boot": CLOSED_EYES + f'<path d="M33 50 h6" {LINE}/>' + SNORE,
}


def cow(mood):
    return f"""<ellipse cx="12" cy="27" rx="9" ry="4.5" transform="rotate(-20 12 27)" {OUTLINE}/>
<ellipse cx="60" cy="27" rx="9" ry="4.5" transform="rotate(20 60 27)" {OUTLINE}/>
<path d="M25 14 Q21 10 22 4 M47 14 Q51 10 50 4" fill="none" stroke="{INK}" stroke-width="3.2" stroke-linecap="round"/>
<path d="M28 56 h16 l2.5 10 h-21 Z" {OUTLINE}/>{dot(36, 67.5, 2)}
<rect x="18" y="12" width="36" height="40" rx="16" {OUTLINE}/>
<path d="M21 26 C20 16 32 13 35 18 C38 23 31 30 25 29 Z" fill="{INK}"/>
<path d="M47 16 C52 16 53 22 50 24 C47 25 44 20 47 16 Z" fill="{INK}"/>
<ellipse cx="36" cy="46" rx="15" ry="9.5" {OUTLINE}/>
<ellipse cx="31" cy="44" rx="1.8" ry="2.4" fill="{INK}"/>
<ellipse cx="41" cy="44" rx="1.8" ry="2.4" fill="{INK}"/>
{MOODS[mood]}"""


def svg(mood):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" '
        f'viewBox="{VIEWBOX}">\n<rect x="-2" y="-6" width="82" height="78" fill="{PAPER}"/>\n'
        f"{cow(mood)}\n</svg>\n"
    )


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for mood in MOODS:
        svg_path = OUT / f"{mood}.svg"
        png_path = OUT / f"{mood}.png"
        svg_path.write_text(svg(mood))
        subprocess.run(
            ["rsvg-convert", "-w", str(WIDTH), "-h", str(HEIGHT), "-o", png_path, svg_path],
            check=True,
        )
        # Threshold the anti-aliased render to pure black and white so the
        # e-paper shows exactly what was drawn.
        gray = Image.open(png_path).convert("L")
        gray.point(lambda v: 255 if v >= 150 else 0).convert("1").save(png_path)
        print(f"wrote {png_path.relative_to(OUT.parent.parent)}")


if __name__ == "__main__":
    main()
