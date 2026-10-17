"""Медуза бездны (обычная). Колокол сверху, щупальца вниз; смотрит ВПРАВО (глаза справа)."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#f6d2f4"
BASE = "#c98ce6"
SHADE = "#8c5cbc"
TENT = "#e873c0"
TENT2 = "#a64f9e"
GLOW = "#4ff5e6"
GLOW2 = "#d7fff9"
WHITE = "#ffffff"

g = Grid()
CX, CY = 15, 10
# щупальца (под колоколом) — волнистые линии
def tent(x0, y0, length, phase, color, amp=1):
    for i in range(length):
        dx = amp if ((i + phase) // 2) % 2 else 0
        g.set(x0 + dx, y0 + i, color)
        g.set(x0 + dx + 1, y0 + i, color) if color == TENT and i < 3 else None
tent(8, 16, 11, 0, TENT)
tent(12, 16, 14, 1, TENT)
tent(16, 16, 12, 0, TENT2)
tent(20, 16, 13, 1, TENT)
tent(23, 16, 9, 0, TENT2)
# колокол
g.ellipse(CX, CY, 10, 7, BASE)
# срезаем низ эллипса — плоский край
for y in range(g.h):
    for x in range(g.w):
        if y > 15:
            if g.px[y][x] == BASE:
                g.px[y][x] = None
# нижняя кромка-тень
for x in range(5, 26):
    if g.get(x, 15) == BASE:
        g.set(x, 15, SHADE)
for x in range(5, 26):
    if g.get(x, 14) == BASE and (x % 3 != 1):
        g.set(x, 14, SHADE)
# зубчики края
for x in range(6, 25, 3):
    g.set(x, 16, SHADE)
# блик сверху-слева
g.ellipse(11, 6, 5, 1, LIGHT, only_where="filled")
g.rect(7, 8, 8, 9, LIGHT)
g.set(7, 7, LIGHT)
# светящиеся пятнышки
for (x, y) in ((11, 11), (16, 12), (14, 8)):
    g.set(x, y, GLOW)
g.set(11, 10, GLOW2); g.set(16, 11, GLOW2)
# глаз
g.rect(19, 9, 21, 11, WHITE)
g.rect(20, 10, 21, 11, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("jellyfish", g.to_image())
    print("ok")
