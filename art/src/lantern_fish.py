"""Рыба-фонарик (бездна, обычная). Индиго-серая рыбка с бирюзовыми фотофорами. Смотрит ВПРАВО."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#a3afe0"
BASE = "#6471a6"
SHADE = "#414a80"
FIN = "#5a4f94"
TURQ = "#3df2e0"
TURQ2 = "#c4fff7"
WHITE = "#ffffff"

g = Grid()
# хвост
g.poly([(8, 16), (3, 11), (5, 16), (3, 21), (8, 17)], FIN)
# плавники
g.poly([(10, 12), (13, 8), (17, 12)], FIN)
g.poly([(11, 20), (13, 23), (16, 20)], FIN)
# тело + голова
g.ellipse(13, 16, 7, 4, BASE)
g.ellipse(17, 16, 4, 4, BASE)
g.ellipse(13, 13, 6, 1, LIGHT, only_where="filled")
g.ellipse(17, 12, 3, 1, LIGHT, only_where="filled")
g.ellipse(13, 19, 6, 1, SHADE, only_where="filled")
# фотофоры вдоль брюха
for x in (8, 11, 14, 17):
    g.set(x, 19, TURQ)
g.set(11, 19, TURQ2); g.set(17, 19, TURQ2)
g.set(9, 17, TURQ); g.set(13, 17, TURQ)   # боковые точки
# «фонарик» над глазом
g.set(18, 10, TURQ); g.set(19, 10, TURQ2)
# крупный глаз
g.rect(17, 13, 20, 16, WHITE)
g.rect(19, 14, 20, 16, OUT)
# рот
g.line(21, 18, 22, 18, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("lantern_fish", g.to_image())
    print("ok")
