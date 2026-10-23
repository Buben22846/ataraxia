"""Иконки интерфейса v2 в стиле макета (толстый контур, скруглённые формы).
Рисуются крупно (сетка 24 -> 192 px), затем каждый блок 4x4 превращается в один пиксель без полупрозрачности (SpriteData это требует).
Запуск: python3 art/src/icons.py"""
import os
from collections import Counter
from PIL import Image, ImageDraw

PNG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "png")
K = 8  # масштаб: 1 клетка сетки 24 = 8 px
W = "#ffffff"
GOLD = "#ffd166"
BROWN = "#4a2c00"
SKY = "#bfeaff"


def rgb(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Pen:
    def __init__(self):
        self.img = Image.new("RGBA", (24 * K, 24 * K), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def line(self, pts, color, w=2.3):
        pts = [(x * K, y * K) for x, y in pts]
        self.d.line(pts, fill=rgb(color), width=int(w * K), joint="curve")
        r = w * K / 2
        for (x, y) in (pts[0], pts[-1]):
            self.d.ellipse((x - r, y - r, x + r, y + r), fill=rgb(color))

    def rrect(self, box, color, w=2.3, fill=None, r=3):
        x0, y0, x1, y1 = [v * K for v in box]
        self.d.rounded_rectangle((x0, y0, x1, y1), radius=r * K, outline=rgb(color), width=int(w * K), fill=rgb(fill) if fill else None)

    def circle(self, cx, cy, r, color, w=None, fill=False):
        box = ((cx - r) * K, (cy - r) * K, (cx + r) * K, (cy + r) * K)
        if fill:
            self.d.ellipse(box, fill=rgb(color))
        else:
            self.d.ellipse(box, outline=rgb(color), width=int((w or 2.3) * K))

    def poly(self, pts, color):
        self.d.polygon([(x * K, y * K) for x, y in pts], fill=rgb(color))

    def finish(self, size=48):
        step = 24 * K // size
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        for oy in range(size):
            for ox in range(size):
                cnt = Counter()
                opaque = 0
                for y in range(step):
                    for x in range(step):
                        p = self.img.getpixel((ox * step + x, oy * step + y))
                        if p[3] > 128:
                            opaque += 1
                            cnt[p[:3]] += 1
                if opaque * 2 >= step * step:
                    c = cnt.most_common(1)[0][0]
                    out.putpixel((ox, oy), c + (255,))
        return out


def collection():
    p = Pen()
    for box in ((3, 3, 11, 11), (13, 3, 21, 11), (3, 13, 11, 21)):
        p.rrect(box, W, 2.2, r=2)
    p.rrect((13, 13, 21, 21), GOLD, 2.2, fill=GOLD, r=2)
    return p.finish()


def die():
    p = Pen()
    p.rrect((3, 3, 21, 21), W, 2.2, r=4)
    for (x, y) in ((8, 8), (16, 8), (12, 12), (8, 16), (16, 16)):
        p.circle(x, y, 1.7, W, fill=True)
    return p.finish()


def expand():
    p = Pen()
    p.rrect((3, 3, 21, 21), W, 2.2, r=4)
    p.line([(12, 7.5), (12, 16.5)], GOLD, 2.4)
    p.line([(7.5, 12), (16.5, 12)], GOLD, 2.4)
    return p.finish()


def tasks():
    p = Pen()
    p.rrect((4, 3, 20, 21), W, 2.2, r=3)
    p.line([(8, 10), (10.5, 12.5), (15.5, 7.5)], GOLD, 2.4)
    p.line([(8, 17), (16, 17)], W, 2.2)
    return p.finish()


def gift():
    p = Pen()
    p.rrect((4, 10, 20, 21), BROWN, 2.3, r=2)
    p.rrect((3, 7, 21, 11), BROWN, 2.3, r=1.5)
    p.line([(12, 7), (12, 21)], BROWN, 2.3)
    p.circle(8.6, 4.8, 2.4, BROWN, 2.2)
    p.circle(15.4, 4.8, 2.4, BROWN, 2.2)
    return p.finish()


def shop():
    p = Pen()
    p.line([(2.5, 4), (5, 4), (7, 15), (18, 15), (20.5, 7), (6, 7)], W, 2.3)
    p.circle(9, 19.5, 1.9, W, fill=True)
    p.circle(17, 19.5, 1.9, W, fill=True)
    return p.finish()


def sound():
    p = Pen()
    p.circle(7, 18, 3.2, W, fill=True)
    p.circle(17, 16, 3.2, W, fill=True)
    p.line([(10, 18), (10, 5), (20, 3), (20, 16)], W, 2.3)
    return p.finish()


def fish():
    p = Pen()
    p.d.ellipse((3 * K, 7 * K, 17 * K, 17 * K), fill=rgb(SKY))
    p.poly([(15, 12), (22, 6.5), (22, 17.5)], SKY)
    p.circle(7.5, 11, 1.3, "#0a2540", fill=True)
    return p.finish()


def guests():
    p = Pen()
    p.circle(9, 8, 3.6, W, 2.2)
    p.line([(3, 20.5), (3.5, 17), (6, 14.8), (12, 14.8), (14.5, 17), (15, 20.5)], W, 2.2)
    p.circle(17.5, 9, 2.7, W, 2.2)
    p.line([(17.5, 14.5), (20, 15.5), (21, 19)], W, 2.2)
    return p.finish()


def gear():
    p = Pen()
    p.circle(12, 12, 3.4, W, 2.4)
    for (a, b) in (((12, 2.5), (12, 5.5)), ((12, 18.5), (12, 21.5)), ((2.5, 12), (5.5, 12)), ((18.5, 12), (21.5, 12)),
                   ((5.3, 5.3), (7.4, 7.4)), ((16.6, 16.6), (18.7, 18.7)), ((18.7, 5.3), (16.6, 7.4)), ((7.4, 16.6), (5.3, 18.7))):
        p.line([a, b], W, 2.6)
    return p.finish()


def ticket():
    p = Pen()
    p.rrect((2, 6, 22, 18), "#ffd166", 2, fill="#ffd166", r=2)
    p.circle(2, 12, 2.2, "#0a2540", fill=True)
    p.circle(22, 12, 2.2, "#0a2540", fill=True)
    p.line([(9, 8.5), (9, 15.5)], BROWN, 1.6)
    return p.finish()


def shell():
    p = Pen()
    p.d.pieslice((3 * K, 4 * K, 21 * K, 22 * K), 180, 360, fill=rgb("#ffe08a"))
    p.d.rectangle((3 * K, 13 * K, 21 * K, 20 * K), fill=rgb("#ffe08a"))
    p.d.pieslice((3 * K, 4 * K, 21 * K, 22 * K), 180, 360, outline=rgb("#a86f00"), width=int(2 * K))
    p.line([(3, 13), (3, 20.5), (21, 20.5), (21, 13)], "#a86f00", 2)
    for (x0, x1) in ((12, 12), (12, 7), (12, 17)):
        p.line([(x0, 20), (x1, 7)], "#a86f00", 1.8)
    return p.finish()


ICONS = {
    "ic_collection": collection, "ic_odds": die, "ic_expand": expand, "ic_tasks": tasks, "ic_gift": gift,
    "ic_shop": shop, "ic_sound": sound, "ic_fish": fish, "ic_guests": guests, "ic_gear": gear,
    "ic_ticket": ticket, "ic_shell": shell,
}

if __name__ == "__main__":
    os.makedirs(PNG, exist_ok=True)
    sheet = Image.new("RGBA", (len(ICONS) * 56 + 8, 64), rgb("#1f64bd"))
    for i, (name, fn) in enumerate(ICONS.items()):
        img = fn()
        img.save(os.path.join(PNG, name + ".png"))
        sheet.alpha_composite(img, (8 + i * 56, 8))
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save("/tmp/icons_preview.png")
    print(len(ICONS))
