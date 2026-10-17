"""Удильщик (бездна, редкая). Тёмное пухлое тело, пасть с зубами, лаймовый фонарь на удочке. Смотрит ВПРАВО."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#7488c0"
BASE = "#40508a"
SHADE = "#262f5c"
FIN = "#5b4a94"
MOUTH = "#6a2a58"
LIME = "#d8ff4a"
LIME2 = "#fffdb8"
WHITE = "#ffffff"

g = Grid()
# хвост
g.poly([(7, 16), (2, 11), (4, 17), (2, 23), (8, 20)], FIN)
# спинной плавник
g.poly([(9, 11), (11, 7), (15, 11)], FIN)
# удочка с фонарём
g.line(16, 10, 17, 5, SHADE)
g.line(17, 5, 20, 2, SHADE)
g.line(20, 2, 24, 3, SHADE)
# тело
g.ellipse(13, 17, 8, 7, BASE)
# нижняя и верхняя челюсти
g.poly([(18, 20), (27, 19), (27, 23), (24, 26), (16, 26)], BASE)
g.poly([(18, 13), (24, 15), (27, 19), (18, 20)], BASE)
# тень и блик
g.ellipse(13, 23, 8, 2, SHADE, only_where="filled")
g.ellipse(11, 11, 6, 1, LIGHT, only_where="filled")
g.ellipse(13, 12, 3, 1, LIGHT, only_where="filled")
# пасть
g.poly([(17, 19), (27, 18), (27, 22), (17, 23)], MOUTH)
# зубы
for x in (19, 22, 25):
    g.set(x, 19, WHITE); g.set(x, 20, WHITE) if x != 22 else None
for x in (20, 23, 26):
    g.set(x, 22, WHITE); g.set(x, 21, WHITE)
# нижний плавник
g.poly([(10, 24), (12, 28), (15, 25)], FIN)
# глаз
g.rect(16, 12, 19, 15, WHITE)
g.rect(18, 13, 19, 15, OUT)
# фонарь
g.rect(23, 5, 26, 6, LIME)
g.rect(24, 4, 25, 4, LIME); g.rect(24, 7, 25, 7, LIME)
g.rect(24, 5, 25, 5, LIME2)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("anglerfish", g.to_image())
    print("ok")
