"""Тюлень (лёд, обычный). Пятнистый серый, усики, большие чёрные глаза."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

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
g.poly([(7, 17), (1, 13), (3, 18), (1, 23), (7, 20)], SHADE)
# тело
g.ellipse(13, 18, 10, 6, BODY)
g.ellipse(13, 14, 7, 1, LIGHT, only_where="filled")
g.ellipse(13, 23, 8, 1, SHADE, only_where="filled")
# голова
g.ellipse(22, 14, 6, 5, BODY)
g.ellipse(21, 10, 4, 1, LIGHT, only_where="filled")
g.ellipse(26, 17, 4, 3, MUZZ, only_where="filled")
# пятна
for x, y in ((8, 15), (11, 19), (14, 15), (16, 21), (5, 19)):
    g.rect(x, y, x + 1, y, SPOT)
g.set(9, 16, SPOT); g.set(12, 20, SPOT); g.set(15, 16, SPOT)
# глаз большой чёрный
g.rect(21, 12, 23, 14, OUT)
g.set(21, 12, WHITE)
# нос, усики, щека
g.rect(27, 14, 28, 15, OUT)
g.set(25, 18, SPOT); g.set(27, 18, SPOT); g.set(28, 17, SPOT)
g.rect(20, 17, 21, 17, PINK)
# передний ласт
g.poly([(15, 19), (12, 24), (16, 25), (19, 21)], SHADE)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("seal", g.to_image())
    print("ok")
