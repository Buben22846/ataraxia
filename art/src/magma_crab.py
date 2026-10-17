"""Магмовый краб (вулкан, обычная). Смотрит ВПРАВО."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#7d6a6e"   # базальт, свет
BASE = "#4d3f45"    # базальт, база
SHADE = "#2f262c"   # базальт, тень
LAVA = "#ff7a1f"
GLOW = "#ffd84a"
CLAW = "#c23a22"
WHITE = "#ffffff"

g = Grid()
# ноги
for x in (3, 8, 13, 18):
    g.poly([(x + 2, 21), (x + 4, 21), (x + 2, 27), (x - 1, 27)], SHADE)
    g.rect(x - 1, 27, x + 2, 27, BASE)
    g.line(x + 3, 21, x + 3, 22, BASE)
# рука и клешня (поднята)
g.poly([(19, 18), (22, 19), (27, 14), (24, 12)], BASE)
g.ellipse(26, 11, 3, 3, CLAW)
g.poly([(22, 10), (22, 2), (25, 8)], CLAW)      # левый палец
g.poly([(28, 8), (31, 2), (31, 11)], CLAW)      # правый палец
g.ellipse(25, 9, 1, 1, "#e8622f", only_where="filled")
g.line(26, 12, 28, 13, LAVA)
g.set(22, 4, GLOW)
# панцирь
g.ellipse(12, 18, 10, 6, BASE)
g.ellipse(10, 14, 7, 1, LIGHT, only_where="filled")
g.ellipse(12, 22, 9, 1, SHADE, only_where="filled")
# трещины лавы
for p in ((3, 17, 6, 19), (6, 19, 9, 16), (9, 16, 12, 19), (12, 19, 15, 17), (15, 17, 17, 20), (9, 16, 9, 14)):
    g.line(*p, LAVA)
g.set(9, 16, GLOW); g.set(12, 19, GLOW); g.set(6, 19, GLOW); g.set(16, 19, GLOW)
# глаз на стебельке
g.line(17, 13, 18, 11, BASE)
g.rect(17, 9, 18, 10, WHITE)
g.set(18, 10, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("magma_crab", g.to_image())
    print("ok")
