"""Полярная акула (лёд, редкая). Сине-серая, светлое брюхо."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
from _scale import SG

OUT = "#1d2b3a"
BODY = "#6b8cad"
LIGHT = "#8eb0cb"
SHADE = "#4f6f8f"
FIN = "#3f5c7b"
BELLY = "#e4f2f8"
BELLYS = "#bcd9e8"
PINK = "#f4a6b8"
WHITE = "#ffffff"

g = SG(0.94)
# хвост-полумесяц
g.poly([(8, 15), (2, 6), (4, 14), (3, 19), (7, 25), (8, 17)], FIN)
# спинной и грудной плавники
g.poly([(14, 11), (17, 3), (22, 11)], FIN)
g.poly([(16, 19), (13, 26), (20, 21)], FIN)
# тело
g.ellipse(18, 16, 11, 5, BODY)
g.poly([(26, 13), (31, 16), (26, 20)], BODY)
g.ellipse(17, 12, 8, 1, LIGHT, only_where="filled")
g.ellipse(18, 19, 10, 2, BELLY, only_where="filled")
g.ellipse(17, 21, 8, 1, BELLYS, only_where="filled")
# жабры
for x in (19, 21, 23):
    g.line(x, 14, x, 16, SHADE)
# глаз, щёчка, улыбка
g.rect(25, 14, 26, 15, WHITE)
g.set(26, 15, OUT)
g.rect(24, 17, 25, 17, PINK)
g.line(27, 18, 30, 18, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("polar_shark", g.to_image())
    print("ok")
