# Gives the dark_planet frames an alpha channel so stars can shine around
# the planet. The frames are drawn on pure black: the planet and its glow
# are every pixel brighter than 0, so that silhouette (closed, then softened)
# becomes the alpha, and the colours stay as they are.
# Usage: python3 planet-alpha.py <frames-in> <frames-out>
import sys
from pathlib import Path

from PIL import Image, ImageFilter

src, dst = Path(sys.argv[1]), Path(sys.argv[2])
dst.mkdir(parents=True, exist_ok=True)
for frame in sorted(src.glob("progress-*.png")):
    rgb = Image.open(frame).convert("RGB")
    brightest = rgb.convert("L").point(lambda v: 255 if v > 0 else 0)
    # Some pure-black pixels inside the planet: close those holes first.
    mask = brightest.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9))
    mask = mask.filter(ImageFilter.GaussianBlur(3))
    rgba = rgb.copy()
    rgba.putalpha(mask)
    rgba.save(dst / frame.name, optimize=True)
