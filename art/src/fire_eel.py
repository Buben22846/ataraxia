"""Огненный угорь (вулкан, редкая). Смотрит ВПРАВО."""
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#ffb04a"
BASE = "#ee5a24"
SHADE = "#a8321f"
FIN = "#7a2118"
GLOW = "#ffd84a"
WHITE = "#ffffff"

g = Grid()
N = 90
pts = []
for i in range(N + 1):
    t = i / N
    x = 3 + t * 16
    y = 17 + 6.5 * math.sin(t * math.pi * 2.6 + 3.3) * (0.5 + 0.5 * t)
    r = 0.8 + 1.9 * min(t * 2.2, 1.0)
    pts.append((x, y, r))
# спинной плавник (под телом, чтобы выглядывал)
for x, y, r in pts[10:-8:2]:
    g.ellipse(round(x), round(y - r - 1), 0, 0, FIN)
for x, y, r in pts:
    g.ellipse(round(x), round(y), r - 0.5, r - 0.5, BASE)
# блик сверху-слева и тень снизу
for x, y, r in pts[6:]:
    g.set(round(x), round(y - r + 0.5), LIGHT)
    g.set(round(x), round(y + r - 0.5), SHADE)
# жёлтые пятна
for k in range(14, 86, 12):
    x, y, r = pts[k]
    g.rect(round(x), round(y) - 1, round(x) + 1, round(y), GLOW)
# голова
hx, hy, _ = pts[-1]
hx, hy = round(hx), round(hy)
g.ellipse(hx + 2, hy, 4, 3, BASE)
g.set(hx + 6, hy + 1, BASE)
g.ellipse(hx + 1, hy - 2, 3, 0, LIGHT, only_where="filled")
g.line(hx + 1, hy + 3, hx + 5, hy + 3, SHADE)
g.line(hx + 4, hy + 1, hx + 6, hy + 1, SHADE)
g.rect(hx + 2, hy - 2, hx + 3, hy - 1, WHITE)
g.set(hx + 3, hy - 1, OUT)
# хвостовой плавничок
t0 = pts[0]
g.poly([(round(t0[0]) - 1, round(t0[1])), (round(t0[0]) - 2, round(t0[1]) - 2), (round(t0[0]) + 1, round(t0[1]) + 1)], FIN)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("fire_eel", g.to_image())
    print("ok")
