"""Медуза бездны (обычная). Колокол сверху, щупальца вниз; смотрит ВПРАВО (глаз справа)."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#f6d2f4"
BASE = "#c98ce6"
SHADE = "#8c5cbc"
TENT = "#ea78c6"
TENT2 = "#a64f9e"
GLOW = "#4ff5e6"
GLOW2 = "#d7fff9"
WHITE = "#ffffff"

g = Grid()
CX, CY = 15, 10
# щупальца: 2 px шириной, волна, разнесены на 5 px, чтобы контуры не сливались
def tent(x0, y0, length, phase, color):
    for i in range(length):
        dx = 1 if ((i + phase) // 3) % 2 else 0
        g.set(x0 + dx, y0 + i, color)
        g.set(x0 + dx + 1, y0 + i, color)
tent(7, 15, 8, 0, TENT)
tent(12, 15, 12, 3, TENT)
tent(17, 15, 10, 0, TENT2)
tent(22, 15, 7, 3, TENT)
# колокол
g.ellipse(CX, CY, 10, 7, BASE)
for y in range(16, g.h):
    for x in range(g.w):
        if g.px[y][x] == BASE:
            g.px[y][x] = None
# тень по нижнему краю колокола
for x in range(g.w):
    if g.get(x, 15) == BASE:
        g.set(x, 15, SHADE)
    if g.get(x, 14) == BASE and x % 2 == 0:
        g.set(x, 14, SHADE)
# блик сверху-слева
g.ellipse(11, 5, 5, 1, LIGHT, only_where="filled")
g.rect(6, 7, 7, 9, LIGHT)
g.set(7, 6, LIGHT)
# светящиеся пятнышки (2x2 и поменьше)
g.rect(10, 11, 11, 12, GLOW); g.set(10, 11, GLOW2)
g.rect(15, 12, 16, 13, GLOW); g.set(15, 12, GLOW2)
g.set(13, 8, GLOW)
# глаз
g.rect(19, 8, 21, 10, WHITE)
g.rect(20, 9, 21, 10, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("jellyfish", g.to_image())
    print("ok")
