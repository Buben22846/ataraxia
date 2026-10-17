"""Тюлень (лёд, обычный). Пятнистый серый, усики, большие чёрные глаза."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
from _scale import SG

OUT = "#1d2b3a"
BODY = "#a3b5c5"
LIGHT = "#d0dde8"
SHADE = "#7d92a7"
SPOT = "#667c92"
MUZZ = "#eef5f9"
PINK = "#f4a6b8"
WHITE = "#ffffff"

g = Grid()
# задние ласты
g.poly([(6, 17), (1, 13), (3, 18), (1, 23), (6, 20)], SHADE)
# тело
g.ellipse(11, 18, 8, 5, BODY)
g.ellipse(11, 15, 6, 1, LIGHT, only_where="filled")
g.ellipse(11, 22, 7, 1, SHADE, only_where="filled")
# голова
g.ellipse(18, 15, 5, 4, BODY)
g.ellipse(17, 12, 3, 1, LIGHT, only_where="filled")
g.ellipse(21, 17, 3, 2, MUZZ, only_where="filled")
# пятна
for x, y in ((7, 16), (10, 19), (12, 16), (13, 21), (4, 19)):
    g.rect(x, y, x + 1, y, SPOT)
g.set(8, 17, SPOT); g.set(11, 20, SPOT)
# глаз большой чёрный
g.rect(17, 13, 19, 15, OUT)
g.set(17, 13, WHITE)
# нос, усики, щека
g.rect(22, 15, 23, 16, OUT)
g.set(20, 18, SPOT); g.set(22, 18, SPOT); g.set(23, 17, SPOT)
g.rect(16, 17, 17, 17, PINK)
# передний ласт
g.poly([(12, 19), (10, 24), (13, 24), (16, 21)], SHADE)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("seal", g.to_image())
    print("ok")
