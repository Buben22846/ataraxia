"""Свечной слизень — haunted / rare; три янтарных кончика, без огня."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite

OUT = '#1d2b3a'
LIGHT = '#d8cbe9'
BASE = '#9d85b8'
SHADE = '#65577f'
MINT = '#b7d6b1'
PATINA = '#709b88'
AMBER = '#ffc66e'
OCHRE = '#db874f'
WHITE = '#ffffff'

g = Grid()
# Dorsal cerata are fleshy blunt lobes, not flames.
for x, y in [(8, 12), (13, 10), (18, 11)]:
    g.rect(x, y, x+1, 18, BASE)
    g.rect(x-1, y+4, x+2, 19, BASE)
    g.rect(x-1, y+4, x-1, 18, LIGHT)
    g.rect(x, y, x+1, y+2, OCHRE)
    g.rect(x, y, x+1, y+1, AMBER)
# Two anterior rhinophores: staggered in profile, both thick.
g.rect(21, 10, 22, 13, PATINA)
g.rect(22, 13, 23, 17, PATINA)
g.rect(21, 10, 22, 11, MINT)
g.rect(25, 12, 26, 17, PATINA)
g.rect(25, 12, 26, 13, MINT)
# Long foot and low mantle, head at right.
g.poly([(5, 21), (7, 18), (14, 17), (22, 17), (26, 19), (26, 22), (22, 24), (8, 24)], PATINA)
g.poly([(5, 21), (9, 18), (17, 16), (23, 16), (26, 18), (26, 21), (21, 22), (8, 22)], BASE)
g.line(8, 20, 18, 18, LIGHT)
g.rect(19, 17, 23, 17, LIGHT)
g.rect(10, 22, 22, 22, SHADE)
g.rect(8, 23, 22, 23, MINT)
g.rect(23, 18, 25, 20, WHITE)
g.rect(25, 19, 25, 20, OUT)
g.rect(25, 21, 26, 21, SHADE)
g.outline(OUT)
g.recenter()

if __name__ == '__main__':
    save_sprite('candle_nudibranch', g.to_image())
