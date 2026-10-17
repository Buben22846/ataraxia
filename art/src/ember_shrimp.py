"""Лавовая креветка (вулкан, обычная). Смотрит ВПРАВО."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#ff9a3c"
BASE = "#e4572e"
SHADE = "#a8321f"
FIN = "#7a2118"
GLOW = "#ffd84a"
WHITE = "#ffffff"

g = Grid()
# усики и ножки (сзади)
g.line(26, 11, 30, 3, FIN)
g.line(27, 13, 31, 8, FIN)
for x in (13, 16, 19, 22):
    g.line(x, 18, x - 1, 22, FIN)
# хвостовой веер
g.poly([(9, 23), (3, 22), (1, 26), (5, 29), (10, 27)], FIN)
g.poly([(8, 24), (4, 24), (3, 26), (6, 27)], SHADE)
# сегменты тела по дуге
g.ellipse(24, 15, 4, 4, BASE)       # голова
g.ellipse(19, 11, 4, 4, BASE)
g.ellipse(14, 12, 4, 4, BASE)
g.ellipse(10, 16, 3, 4, BASE)
g.ellipse(9, 21, 3, 3, BASE)
g.poly([(26, 11), (29, 12), (27, 14)], BASE)  # рострум
# блик сверху и тень снизу
for cx, cy, r in ((19, 11, 4), (14, 12, 4), (10, 16, 3)):
    g.ellipse(cx - 1, cy - 2, r - 1, 0, LIGHT, only_where="filled")
g.ellipse(24, 12, 3, 0, LIGHT, only_where="filled")
for cx, cy, r in ((19, 11, 4), (14, 12, 4), (24, 15, 4)):
    g.ellipse(cx, cy + 4, r - 1, 0, SHADE, only_where="filled")
g.line(7, 17, 7, 22, SHADE); g.line(8, 23, 11, 22, SHADE)
# светящиеся сегменты
g.line(16, 8, 16, 14, GLOW)
g.line(21, 8, 21, 13, GLOW)
g.line(11, 12, 12, 13, GLOW)
g.line(8, 17, 11, 17, GLOW)
g.line(8, 21, 11, 21, GLOW)
# глаз
g.rect(25, 13, 26, 14, WHITE)
g.set(26, 14, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("ember_shrimp", g.to_image())
    print("ok")
