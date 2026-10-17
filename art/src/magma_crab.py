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
for x, o in ((3, -2), (7, -1), (11, 1), (15, 2)):
    g.line(x + 1, 15, x + 1 + o, 19, SHADE); g.line(x + 2, 15, x + 2 + o, 19, SHADE)
    d = 1 if o > 0 else -1
    g.line(x + 1 + o, 19, x + 1 + o + d, 22, BASE); g.line(x + 2 + o, 19, x + 2 + o + d, 22, BASE)
# рука и клешня (поднята)
g.poly([(15, 13), (17, 15), (20, 11), (18, 9)], BASE)
g.ellipse(20, 8, 2, 2, CLAW)
g.poly([(18, 7), (18, 2), (20, 6)], CLAW)
g.poly([(22, 6), (24, 2), (24, 9)], CLAW)
g.line(20, 9, 22, 9, LAVA)
g.set(18, 3, GLOW)
# панцирь
g.ellipse(9, 13, 8, 4, BASE)
g.ellipse(8, 10, 5, 0, LIGHT, only_where="filled")
g.ellipse(9, 16, 7, 0, SHADE, only_where="filled")
# трещины лавы
for p in ((3, 12, 5, 14), (5, 14, 7, 11), (7, 11, 9, 14), (9, 14, 12, 12), (12, 12, 14, 14)):
    g.line(*p, LAVA)
g.set(7, 11, GLOW); g.set(9, 14, GLOW); g.set(5, 14, GLOW)
# глаз
g.line(13, 9, 14, 8, BASE)
g.rect(13, 6, 14, 7, WHITE)
g.set(14, 7, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("magma_crab", g.to_image())
    print("ok")
