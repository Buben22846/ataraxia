"""Осьминог (лагуна, легендарный): светящиеся пятнышки. Смотрит вправо."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"; BODY = "#c07ad8"; LIGHT = "#e2aef2"; SHADE = "#8f4fb0"
SUCK = "#f7b8d8"; GLOW = "#7ff5e0"; GLOW2 = "#fff3a0"; WHITE = "#ffffff"

g = Grid()
def tent(pts, r0, r1, color=BODY):
    n = len(pts) - 1
    for i in range(n):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for s in range(steps + 1):
            t = (i + s / steps) / n
            r = r0 + (r1 - r0) * t
            g.ellipse(x0 + (x1 - x0) * s / steps, y0 + (y1 - y0) * s / steps, r, r, color)
# щупальца: крупные, изогнутые, с завитками на концах
tent([(9, 17), (6, 22), (3, 26), (4, 29), (7, 30)], 2.0, 0.6)
tent([(14, 19), (11, 24), (11, 28), (12, 30), (15, 31)], 2.0, 0.6)
tent([(21, 19), (22, 24), (22, 28), (25, 30), (28, 30)], 2.0, 0.6)
tent([(25, 16), (28, 20), (29, 24), (30, 27)], 1.8, 0.6)
# голова-мантия: высокий купол
g.ellipse(17, 11, 10, 10, BODY)
g.ellipse(17, 17, 9, 4, BODY)
g.ellipse(14, 4, 6, 1, LIGHT, only_where="filled")
g.ellipse(10, 7, 2, 2, LIGHT, only_where="filled")
g.ellipse(17, 20, 7, 0, SHADE, only_where="filled")
g.ellipse(25, 14, 2, 4, SHADE, only_where="filled")
# светящиеся пятнышки 2x2 с жёлтой искрой
for (x, y, c, d) in [(12, 6, GLOW, GLOW2), (18, 4, GLOW, GLOW2), (9, 12, GLOW, GLOW2), (15, 11, GLOW, GLOW2), (19, 15, GLOW, GLOW2)]:
    g.rect(x, y, x + 1, y + 1, c)
    g.set(x, y, d)
# присоски
for (x, y) in [(5, 24), (11, 25), (22, 25), (29, 22)]:
    if g.get(x, y) is not None:
        g.set(x, y, SUCK)
# глаз
g.rect(22, 10, 24, 12, WHITE)
g.rect(23, 11, 24, 12, OUT)
g.set(23, 11, WHITE)
g.set(21, 15, SUCK); g.set(22, 15, SUCK)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("octopus", g.to_image())
    print("ok")
