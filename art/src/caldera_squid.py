"""Кальмар кальдеры (вулкан, эпический). Смотрит ВПРАВО."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#ee6b45"
BASE = "#b73a2a"
SHADE = "#6a1c22"
FIN = "#c2412a"
GLOW = "#ff9a3c"
GLOW2 = "#ffd84a"
WHITE = "#ffffff"

g = Grid()
# щупальца (сзади тела)
def tent(pts, w=2):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        for dy in range(w):
            g.line(x0, y0 + dy, x1, y1 + dy, BASE)
tent([(21, 19), (24, 21), (26, 20), (29, 22), (30, 25)])
tent([(20, 20), (22, 24), (25, 25), (27, 27), (30, 28)])
tent([(18, 20), (19, 25), (22, 28), (24, 28), (26, 30)])
tent([(21, 18), (25, 18), (28, 17), (30, 14)], 2)
for p in ((30, 25), (30, 28), (26, 30), (30, 14)):
    g.set(*p, GLOW2)
# плавники
g.poly([(3, 12), (8, 4), (12, 9)], FIN)
g.poly([(5, 13), (9, 19), (13, 20), (11, 14)], FIN)
# мантия
g.poly([(1, 14), (8, 8), (17, 8), (21, 13), (21, 19), (16, 21), (8, 20)], BASE)
g.ellipse(20, 15, 3, 4, BASE)  # голова
g.poly([(3, 10), (8, 8), (17, 8), (17, 10), (8, 10)], LIGHT)
g.poly([(9, 20), (16, 21), (20, 19), (12, 19)], SHADE)
# светящиеся полосы
g.line(5, 13, 16, 12, GLOW); g.line(5, 14, 16, 13, GLOW)
g.line(7, 16, 17, 16, GLOW); g.line(8, 17, 16, 17, GLOW)
g.line(10, 19, 15, 19, GLOW)
g.set(6, 13, GLOW2); g.set(10, 12, GLOW2); g.set(14, 12, GLOW2)
g.set(11, 16, GLOW2); g.set(15, 16, GLOW2)
# глаз
g.rect(20, 12, 22, 14, WHITE)
g.rect(21, 13, 22, 14, OUT)
g.rect(18, 10, 20, 10, LIGHT)
g.rect(19, 11, 19, 11, LIGHT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("caldera_squid", g.to_image())
    print("ok")
