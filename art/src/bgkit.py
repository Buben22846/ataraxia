"""Общие инструменты для фонов 135x240: дизеринг Bayer 4x4, холст, сохранение + превью x4.
pixel.py не трогаем; Grid здесь не нужен (ограничение 10 цветов только для спрайтов)."""
import os, math, random
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.dirname(HERE)
W, H = 135, 240
MAX_COLORS = 24
_B = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 + 1 / 32.0
BT = np.tile(_B, (H // 4 + 1, W // 4 + 1))[:H, :W]
YY, XX = np.mgrid[0:H, 0:W]


def rgb(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def quantize(t, ramp, strength=1.0):
    """t — карта в индексах рампы (float). Дизеринг Bayer между соседними цветами."""
    idx = np.floor(t + (BT - 0.5) * strength + 0.5).astype(int)
    idx = np.clip(idx, 0, len(ramp) - 1)
    pal = np.array([rgb(c) for c in ramp], dtype=np.uint8)
    return pal[idx]


class Canvas:
    def __init__(self, arr):
        self.img = Image.fromarray(arr.astype(np.uint8), "RGB")
        self.d = ImageDraw.Draw(self.img)

    def arr(self):
        return np.array(self.img)

    def dmask(self, mask, color, region=None):
        """Закрасить пиксели, где mask(0..1) > порога Bayer — мягкая пиксельная «дымка»."""
        px = self.arr()
        sel = np.asarray(mask) > BT
        if region is not None:
            sel &= region
        px[sel] = rgb(color)
        self.img.paste(Image.fromarray(px, "RGB"))

    def pt(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.img.putpixel((int(x), int(y)), rgb(c))

    def rect(self, x0, y0, x1, y1, c):
        self.d.rectangle([x0, y0, x1, y1], fill=rgb(c))

    def poly(self, pts, c):
        self.d.polygon([(round(x), round(y)) for x, y in pts], fill=rgb(c))

    def line(self, x0, y0, x1, y1, c, w=1):
        self.d.line([round(x0), round(y0), round(x1), round(y1)], fill=rgb(c), width=w)

    def ell(self, cx, cy, rx, ry, c):
        self.d.ellipse([round(cx - rx), round(cy - ry), round(cx + rx), round(cy + ry)], fill=rgb(c))

    def ring(self, cx, cy, r, c):
        self.d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=rgb(c))

    def sparkle(self, x, y, c, big=False):
        self.pt(x, y, c)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            self.pt(x + dx, y + dy, c)
        if big:
            for k in (2,):
                for dx, dy in ((k, 0), (-k, 0), (0, k), (0, -k)):
                    self.pt(x + dx, y + dy, c)


def blur(a, r):
    k = np.exp(-0.5 * (np.arange(-3 * r, 3 * r + 1) / r) ** 2)
    k /= k.sum()
    a = np.apply_along_axis(lambda m: np.convolve(m, k, "same"), 0, a)
    a = np.apply_along_axis(lambda m: np.convolve(m, k, "same"), 1, a)
    return a


def edge(x):
    """0 в центре, 1 по краям."""
    return abs(x - (W - 1) / 2) / ((W - 1) / 2)


def finish(c, name):
    im = c.img
    n = len(set(im.getdata()))
    out_png = os.path.join(ART, "png", name + ".png")
    out_pre = os.path.join(ART, "preview", name + "_x4.png")
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    os.makedirs(os.path.dirname(out_pre), exist_ok=True)
    assert im.size == (W, H)
    im.convert("RGBA").save(out_png)
    im.resize((W * 4, H * 4), Image.NEAREST).save(out_pre)
    print(f"{name}: {n} цветов (лимит {MAX_COLORS})")
    if n > MAX_COLORS:
        raise SystemExit("слишком много цветов")
    return n
