"""Пингвин (лёд, обычный). Плывёт в профиль вправо."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
from _scale import SG

OUT = "#1d2b3a"
BACK = "#4a6d90"     # спина база
BACKL = "#6f93b5"    # спина свет
BACKS = "#34506f"    # спина тень / ласты
WHITE = "#ffffff"
BELLY = "#cfe7f3"    # тень на белом
BEAK = "#f4a24a"
BEAKS = "#d9822b"
PINK = "#f4a6b8"

g = Grid()
# лапки и хвост сзади
g.poly([(6, 20), (3, 21), (4, 22), (8, 22)], BEAKS)
g.poly([(6, 13), (2, 15), (6, 18)], BACKS)
# тело
g.ellipse(12, 16, 7, 7, BACK)
g.ellipse(14, 19, 6, 4, WHITE, only_where="filled")
g.ellipse(13, 22, 5, 1, BELLY, only_where="filled")
g.ellipse(11, 11, 5, 1, BACKL, only_where="filled")
# голова
g.ellipse(18, 11, 4, 4, BACK)
g.ellipse(17, 8, 2, 1, BACKL, only_where="filled")
g.ellipse(20, 13, 2, 2, WHITE, only_where="filled")
# клюв
g.poly([(22, 10), (27, 11), (27, 12), (22, 14)], BEAK)
g.rect(22, 13, 25, 13, BEAKS)
# большой глаз и щека
g.rect(19, 9, 21, 11, OUT)
g.set(19, 9, WHITE)
g.rect(17, 12, 18, 12, PINK)
# ласта
g.poly([(12, 16), (8, 22), (11, 23), (15, 18)], BACKS)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("penguin", g.to_image())
    print("ok")
