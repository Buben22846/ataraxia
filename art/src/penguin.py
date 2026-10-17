"""Пингвин (лёд, обычный). Плывёт в профиль вправо."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

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
g.poly([(6, 21), (2, 22), (3, 23), (8, 23)], BEAKS)
g.poly([(7, 14), (2, 16), (7, 19)], BACKS)
# тело
g.ellipse(14, 16, 9, 8, BACK)
g.ellipse(17, 19, 8, 5, WHITE, only_where="filled")
g.ellipse(15, 23, 7, 1, BELLY, only_where="filled")
g.ellipse(13, 10, 6, 1, BACKL, only_where="filled")
# голова
g.ellipse(21, 10, 5, 5, BACK)
g.ellipse(20, 6, 3, 1, BACKL, only_where="filled")
g.ellipse(24, 13, 3, 2, WHITE, only_where="filled")
# клюв
g.poly([(26, 10), (31, 11), (31, 12), (26, 14)], BEAK)
g.rect(26, 13, 29, 13, BEAKS)
# большой глаз и щека
g.rect(22, 9, 24, 11, OUT)
g.set(22, 9, WHITE)
g.rect(21, 12, 22, 12, PINK)
# ласта
g.poly([(13, 15), (8, 21), (11, 22), (17, 18)], BACKS)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("penguin", g.to_image())
    print("ok")
