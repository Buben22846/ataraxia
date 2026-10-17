"""Глубинный скат (бездна, эпический). Манта с неоновыми краями крыльев и хвостом-плетью. Смотрит ВПРАВО."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#6f9be6"
BASE = "#3b5aaa"
SHADE = "#26397c"
TURQ = "#2cf0dc"
TURQ2 = "#c4fff7"
WHITE = "#ffffff"

g = Grid()
# крылья-ромб: плавная передняя кромка, вогнутая задняя, концы загнуты назад
top = [(29, 15), (27, 11), (23, 8), (18, 5), (13, 3), (10, 2), (11, 6), (12, 10), (10, 13), (8, 15)]
bot = [(29, 17), (27, 21), (23, 24), (18, 27), (13, 29), (10, 30), (11, 26), (12, 22), (10, 19), (8, 17)]
g.poly(top + list(reversed(bot)), BASE)
g.poly([(9, 14), (29, 14), (29, 18), (9, 18)], BASE)
# нижняя часть в тени
for y in range(g.h):
    for x in range(g.w):
        if g.px[y][x] == BASE and y >= 21:
            g.px[y][x] = SHADE
# блики на верхнем крыле
g.line(26, 12, 22, 9, LIGHT); g.line(22, 9, 17, 6, LIGHT); g.line(17, 6, 14, 5, LIGHT)
g.line(25, 13, 21, 11, LIGHT); g.line(21, 11, 16, 8, LIGHT)
# неоновые края крыльев (кроме носа)
snap = [[g.px[y][x] for x in range(g.w)] for y in range(g.h)]
for y in range(g.h):
    for x in range(g.w):
        if snap[y][x] is not None and x < 27:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < g.w and 0 <= ny < g.h and snap[ny][nx] is None:
                    g.px[y][x] = TURQ
                    break
# светлые точки на кончиках
g.set(10, 3, TURQ2); g.set(11, 3, TURQ2); g.set(10, 29, TURQ2); g.set(11, 29, TURQ2)
# хвост-плеть (после неона, чтобы не обводился бирюзой)
tail = [(8, 16), (6, 17), (4, 17), (3, 18), (2, 20), (2, 21)]
for (x0, y0), (x1, y1) in zip(tail, tail[1:]):
    g.line(x0, y0, x1, y1, SHADE)
g.set(7, 16, SHADE); g.set(7, 17, SHADE)
g.set(2, 21, TURQ2); g.set(2, 22, TURQ)
# светящиеся пятна на спине
for x in (14, 17, 20):
    g.set(x, 16, TURQ)
# глаз и ноздря
g.rect(24, 13, 25, 14, WHITE)
g.set(25, 14, OUT)
g.set(28, 16, SHADE)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("abyss_ray", g.to_image())
    print("ok")
