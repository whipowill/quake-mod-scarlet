#!/usr/bin/env python3
"""
Build the console background (gfx/conback.png and gfx/conback.tga) from art/conback_source.png.

The whole image is faded toward black so the console text on top of it is easy to read.
Run from anywhere:

    python3 art/make_conback.py

Tweak FADE_* below to taste.  Needs Pillow.
"""
import os
from PIL import Image

FADE_STRENGTH = 0.5  # how dark the whole image gets, 0 (none) to 1 (black)
FADE_COLOR = (6, 4, 5)

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
src = Image.open(os.path.join(root, "art", "conback_source.png")).convert("RGB")
w, h = src.size
px = src.load()

a = FADE_STRENGTH
for y in range(h):
    for x in range(w):
        r, g, b = px[x, y]
        px[x, y] = (round(r + (FADE_COLOR[0] - r) * a),
                    round(g + (FADE_COLOR[1] - g) * a),
                    round(b + (FADE_COLOR[2] - b) * a))

os.makedirs(os.path.join(root, "gfx"), exist_ok=True)
src.save(os.path.join(root, "gfx", "conback.png"), optimize=True)
src.save(os.path.join(root, "gfx", "conback.tga"), compression=None)  # engines that skip png use this
print("wrote gfx/conback.png and gfx/conback.tga (%dx%d)" % (w, h))
