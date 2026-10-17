"""Нарвал (лёд, легендарный). Сине-серый с пятнами, спиральный бивень, ледяные блики."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
BODY = "#7b9db8"
LIGHT = "#a3c3d8"
SHADE = "#57799a"
SPOT = "#3f5f80"
BELLY = "#e4f2f8"
WHITE = "#ffffff"
TURQ = "#5fd3d0"
PINK = "#f4a6b8"
SPARK = "#bff3ff"

g = Grid()
# хвост
g.poly([(7, 17), (2, 11), (1, 12), (4, 18), (1, 25), (3, 25), (8, 20)], SHADE)
# бивень (наискосок вверх-вправо)
g.poly([(22, 14), (31, 8), (31, 10), (23, 17)], WHITE)
for x, y in ((24, 13), (26, 12), (28, 10), (30, 9)):
    g.line(x, y + 2, x + 1, y - 1, TURQ)
# тело
g.ellipse(13, 18, 10, 6, BODY)
g.ellipse(12, 14, 8, 1, LIGHT, only_where="filled")
g.ellipse(14, 22, 9, 2, BELLY, only_where="filled")
g.ellipse(14, 24, 7, 1, SHADE, only_where="filled")
# голова
g.ellipse(21, 17, 5, 5, BODY)
g.ellipse(21, 13, 3, 1, LIGHT, only_where="filled")
# пятна
for x, y in ((7, 16), (10, 18), (13, 15), (16, 17), (6, 20), (12, 20)):
    g.rect(x, y, x + 1, y + 1, SPOT)
# ласт
g.poly([(15, 21), (13, 26), (17, 26), (19, 22)], SHADE)
# глаз
g.rect(21, 15, 22, 16, WHITE)
g.set(22, 16, OUT)
g.rect(20, 18, 21, 18, PINK)
g.line(24, 20, 26, 20, OUT)
g.outline(OUT)
# блики
for x, y in ((4, 4), (28, 25), (17, 4)):
    g.set(x, y, SPARK); g.set(x - 1, y, WHITE); g.set(x + 1, y, WHITE); g.set(x, y - 1, WHITE); g.set(x, y + 1, WHITE)
g.recenter()

if __name__ == "__main__":
    save_sprite("narwhal", g.to_image())
    print("ok")
