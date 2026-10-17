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
# ноги: 4 отдельные, с изгибом и просветами
for x, o in ((4, -3), (9, -1), (14, 1), (19, 3)):
    g.line(x + 1, 20, x + 1 + o, 25, SHADE); g.line(x + 2, 20, x + 2 + o, 25, SHADE)
    g.line(x + 1 + o, 25, x + 1 + o + o // 3 * 0 + (1 if o > 0 else -1), 28, BASE)
    g.line(x + 2 + o, 25, x + 2 + o + (1 if o > 0 else -1), 28, BASE)
# рука и клешня (поднята)
g.poly([(20, 17), (23, 19), (27, 15), (24, 13)], BASE)
g.ellipse(27, 12, 3, 3, CLAW)
g.poly([(24, 10), (24, 4), (27, 9)], CLAW)      # левый палец
g.poly([(29, 9), (31, 4), (32, 12)], CLAW)      # правый палец
g.ellipse(26, 10, 1, 1, "#e8622f", only_where="filled")
g.line(27, 13, 29, 14, LAVA)
g.set(24, 5, GLOW)
# панцирь
g.ellipse(12, 17, 10, 6, BASE)
g.ellipse(10, 13, 7, 1, LIGHT, only_where="filled")
g.ellipse(12, 21, 9, 1, SHADE, only_where="filled")
# трещины лавы
for p in ((3, 16, 6, 18), (6, 18, 9, 15), (9, 15, 12, 18), (12, 18, 15, 16), (15, 16, 17, 19), (9, 15, 9, 13)):
    g.line(*p, LAVA)
g.set(9, 15, GLOW); g.set(12, 18, GLOW); g.set(6, 18, GLOW); g.set(16, 17, GLOW)
# глаз на стебельке
g.line(18, 12, 19, 10, BASE)
g.rect(18, 8, 19, 9, WHITE)
g.set(19, 9, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("magma_crab", g.to_image())
    print("ok")
