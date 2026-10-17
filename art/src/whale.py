"""Синий кит (лагуна, эпический). Смотрит вправо."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"; BODY = "#3d7fd1"; LIGHT = "#6fb0ee"; SHADE = "#2a5aa8"
BELLY = "#e6f1fa"; BSH = "#b4cfe4"; SPRAY = "#bfeaff"; WHITE = "#ffffff"

g = Grid()
# хвостовой стебель, изогнутый вверх, и лопасти
g.poly([(6, 22), (2, 17), (1, 13), (5, 13), (7, 17), (12, 18), (12, 24)], BODY)
g.poly([(0, 13), (0, 8), (3, 10), (4, 13)], SHADE)
g.poly([(2, 12), (5, 7), (8, 8), (7, 13)], SHADE)
g.poly([(2, 12), (3, 8), (5, 7), (5, 12)], BODY)
# тело (крупная голова справа)
g.ellipse(19, 19, 12, 8, BODY)
g.ellipse(21, 12, 8, 1, LIGHT, only_where="filled")
g.ellipse(19, 13, 4, 1, LIGHT, only_where="filled")
# белое брюхо
g.ellipse(21, 25, 11, 2, BELLY, only_where="filled")
g.ellipse(22, 27, 9, 1, BSH, only_where="filled")
for x in (18, 21, 24, 27):
    g.set(x, 24, BSH)
# грудной плавник (выступает вниз)
g.poly([(16, 25), (13, 30), (19, 29), (22, 25)], SHADE)
# глаз и улыбка
g.rect(27, 19, 28, 20, WHITE)
g.set(28, 20, OUT)
g.line(28, 24, 31, 23, OUT)
# фонтан
g.rect(25, 7, 25, 10, SPRAY)
g.poly([(25, 7), (22, 4), (23, 3), (25, 5)], SPRAY)
g.poly([(25, 7), (28, 4), (27, 3), (25, 5)], SPRAY)
g.set(25, 4, SPRAY); g.set(22, 2, SPRAY); g.set(28, 2, SPRAY)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("whale", g.to_image())
    print("ok")
