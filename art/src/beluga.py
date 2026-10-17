"""Белуха (лёд, эпическая). Белая, лоб-дыня, улыбка."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
from _scale import SG

OUT = "#1d2b3a"
WHITE = "#ffffff"
BODY = "#e6f4fa"
SHADE = "#bddcec"
SHADE2 = "#8fbbd4"
FIN = "#a3c8dc"
TURQ = "#6fcfd0"
PINK = "#f4a6b8"

g = SG(0.96)
# хвост: стебель и две доли плавника
g.poly([(11, 16), (6, 13), (6, 17), (11, 22)], BODY)
g.poly([(7, 14), (3, 6), (1, 8), (2, 13)], SHADE2)
g.poly([(7, 14), (1, 17), (2, 21), (6, 17)], SHADE2)
g.rect(4, 12, 7, 15, SHADE2)
# тело
g.ellipse(16, 18, 11, 6, BODY)
g.ellipse(15, 14, 9, 1, WHITE, only_where="filled")
g.ellipse(16, 23, 9, 1, SHADE, only_where="filled")
# голова и лоб-дыня
g.ellipse(25, 14, 5, 5, BODY)
g.ellipse(26, 10, 3, 1, WHITE, only_where="filled")
g.ellipse(28, 18, 3, 3, BODY)
g.ellipse(26, 21, 4, 1, SHADE, only_where="filled")
# ласт
g.poly([(16, 20), (13, 25), (17, 25), (20, 22)], FIN)
# глаз, щека, улыбка
g.rect(25, 14, 26, 16, OUT)
g.set(25, 14, WHITE)
g.rect(23, 18, 24, 18, PINK)
g.line(27, 21, 30, 20, OUT)
g.set(31, 19, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("beluga", g.to_image())
    print("ok")
