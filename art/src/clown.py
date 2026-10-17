"""Рыба-клоун (лагуна, обычная). Смотрит вправо."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"; BODY = "#f77f2e"; LIGHT = "#ffb066"; SHADE = "#d3561a"
FIN = "#e8631c"; WHITE = "#ffffff"; WSH = "#c9dbe6"

g = Grid()
# хвост (веер, слева)
g.poly([(9, 14), (2, 9), (4, 16), (2, 23), (9, 18)], FIN)
# спинной и брюшной плавники
g.poly([(11, 11), (13, 6), (19, 5), (22, 8), (22, 11)], FIN)
g.poly([(14, 21), (16, 25), (20, 24), (20, 21)], FIN)
# тело
g.ellipse(16, 16, 9, 6, BODY)
g.ellipse(16, 12, 7, 1, LIGHT, only_where="filled")
g.ellipse(16, 20, 7, 1, SHADE, only_where="filled")
# белые полосы (только по телу)
def stripe(x0, x1, y0, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if g.get(x, y) is not None:
                g.set(x, y, WSH if y >= 19 else WHITE)
stripe(18, 19, 9, 22)    # полоса за головой
stripe(11, 12, 10, 22)   # полоса у хвоста
# белая кайма хвоста и плавников
g.set(3, 11, WHITE); g.set(3, 21, WHITE)
# глаз
g.rect(21, 13, 22, 14, WHITE)
g.set(22, 14, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("clown", g.to_image())
    print("ok")
