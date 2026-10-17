"""Лавовая креветка (вулкан, обычная). Смотрит ВПРАВО."""
import os, sys
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
# усики и ножки (сзади)
g.line(19, 8, 23, 2, FIN)
g.line(20, 10, 24, 6, FIN)
for x in (9, 12, 15):
    g.line(x, 13, x - 1, 16, FIN)
# хвостовой веер
g.poly([(6, 17), (2, 16), (1, 20), (4, 22), (8, 20)], FIN)
g.poly([(5, 18), (3, 18), (3, 20), (5, 20)], SHADE)
# сегменты тела по дуге
g.ellipse(18, 11, 3, 3, BASE)       # голова
g.ellipse(14, 8, 3, 3, BASE)
g.ellipse(10, 9, 3, 3, BASE)
g.ellipse(7, 12, 2, 3, BASE)
g.ellipse(6, 16, 2, 2, BASE)
g.poly([(19, 7), (22, 8), (20, 10)], BASE)  # рострум
# блик сверху и тень снизу
for cx, cy in ((14, 8), (10, 9), (7, 12)):
    g.ellipse(cx - 1, cy - 2, 2, 0, LIGHT, only_where="filled")
g.ellipse(18, 8, 2, 0, LIGHT, only_where="filled")
for cx, cy in ((14, 8), (10, 9), (18, 11), (6, 16)):
    g.ellipse(cx, cy + 3, 2, 0, SHADE, only_where="filled")
# светящиеся сегменты
g.line(12, 6, 12, 10, GLOW)
g.line(16, 6, 16, 9, GLOW)
g.line(8, 10, 9, 11, GLOW)
g.line(5, 13, 8, 13, GLOW)
g.line(5, 16, 8, 16, GLOW)
# глаз
g.rect(18, 9, 19, 10, WHITE)
g.set(19, 10, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("ember_shrimp", g.to_image())
    print("ok")
