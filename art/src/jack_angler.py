"""Удильщик Джек (Призрачный пруд, легендарный). Чёрно-фиолетовый удильщик с зубастой пастью и фонарём-тыквой на удочке."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
OUT = "#1d2b3a"
WHITE = "#ffffff"
g = Grid()
BODY = "#3b2a52"; LIGHT = "#5c4680"; SHADE = "#21173a"; TOOTH = "#f6f1e0"
PUMP = "#ff9a1f"; PUMP_L = "#ffd36b"; ROD = "#8a7aa8"; EYE = "#ffe066"
g.poly([(6, 17), (1, 10), (2, 17), (1, 25), (6, 19)], SHADE)       # хвост
g.ellipse(15, 18, 10, 8, BODY)
g.ellipse(13, 13, 7, 2, LIGHT, only_where="filled")
g.ellipse(15, 24, 8, 1, SHADE, only_where="filled")
g.poly([(18, 18), (27, 15), (27, 23), (18, 22)], SHADE)            # открытая пасть
for x in (19, 22, 25):                                             # зубы
    g.set(x, 17, TOOTH); g.set(x + 1, 18, TOOTH)
    g.set(x, 22, TOOTH); g.set(x + 1, 21, TOOTH)
g.line(13, 10, 18, 4, ROD); g.line(18, 4, 24, 5, ROD); g.line(24, 5, 25, 7, ROD)   # удочка
g.ellipse(25, 9, 3, 2, PUMP)                                       # фонарь-тыква
g.set(24, 9, PUMP_L); g.set(26, 9, PUMP_L); g.rect(24, 10, 26, 10, PUMP_L)
g.rect(17, 14, 19, 15, EYE); g.set(19, 15, OUT)                    # глаз
g.outline(OUT); g.recenter()
if __name__ == "__main__":
    save_sprite("jack_angler", g.to_image()); print("ok")
