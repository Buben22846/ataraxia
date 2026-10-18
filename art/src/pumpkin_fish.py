"""Тыквенная рыбка (Призрачный пруд, обычная). Круглое оранжевое тело с дольками тыквы, зелёный «хвостик»-плавник сверху."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
OUT = "#1d2b3a"
WHITE = "#ffffff"
g = Grid()
BODY = "#f28c28"; LIGHT = "#ffb85c"; SHADE = "#c25f12"; RIB = "#d9731a"
STEM = "#5e9c3a"; STEM_D = "#3c6b25"; FIN = "#e0661a"
g.poly([(9, 16), (3, 10), (5, 16), (3, 22), (9, 17)], FIN)        # хвост
g.ellipse(18, 16, 9, 7, BODY)
g.ellipse(17, 12, 6, 2, LIGHT, only_where="filled")
g.ellipse(18, 21, 7, 1, SHADE, only_where="filled")
for x in (14, 18, 22):                                          # дольки тыквы
    for y in range(10, 23):
        if g.get(x, y) in (BODY, LIGHT, SHADE):
            g.set(x, y, RIB)
g.rect(17, 6, 18, 8, STEM); g.set(18, 6, STEM_D)                  # «хвостик» тыквы
g.poly([(19, 7), (23, 5), (21, 8)], STEM)                         # листик
g.rect(22, 13, 24, 15, WHITE); g.rect(23, 14, 24, 15, OUT)        # глаз
g.outline(OUT); g.recenter()
if __name__ == "__main__":
    save_sprite("pumpkin_fish", g.to_image()); print("ok")
