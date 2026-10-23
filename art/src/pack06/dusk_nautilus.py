"""Сумеречный наутилус — abyss / epic; оригинальный боковой профиль вправо."""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite

OUT = '#1d2b3a'
LIGHT = '#8799c5'
BASE = '#535e8c'
SHADE = '#313c61'
RIM = '#a7e1dc'
TEAL = '#44bdb9'
PURPLE = '#9568ba'
PEARL = '#c8b7e5'
WHITE = '#ffffff'

g = Grid()
# Three thick, separated tentacle bundles, at the opening on the RIGHT.
g.poly([(20, 13), (24, 11), (28, 9), (28, 11), (25, 14), (21, 16)], PURPLE)
g.poly([(21, 17), (26, 17), (27, 15), (28, 15), (28, 18), (26, 19), (22, 19)], PURPLE)
g.poly([(20, 19), (24, 22), (27, 23), (27, 25), (23, 24), (19, 21)], PURPLE)
g.rect(26, 10, 27, 11, PEARL)
g.rect(26, 17, 27, 17, PEARL)
g.rect(25, 23, 26, 23, PEARL)
# External shell is the dominant mass, not a soft octopus hood.
g.ellipse(11, 15, 9, 11, BASE)
g.ellipse(10, 5, 4, 0, LIGHT, only_where='filled')
g.ellipse(4, 11, 0, 4, LIGHT, only_where='filled')
g.ellipse(12, 23, 7, 2, SHADE, only_where='filled')
g.ellipse(18, 17, 2, 6, SHADE, only_where='filled')
# Thick stepped shell spiral, one connected band.
spiral = [(17, 10), (15, 8), (9, 8), (6, 11), (6, 18), (9, 21),
          (14, 21), (16, 19), (16, 14), (14, 12), (11, 12), (10, 14),
          (10, 16), (12, 17), (13, 16)]
for (x0, y0), (x1, y1) in zip(spiral, spiral[1:]):
    steps = max(abs(x1-x0), abs(y1-y0), 1)
    for i in range(steps+1):
        x = round(x0+(x1-x0)*i/steps)
        y = round(y0+(y1-y0)*i/steps)
        g.rect(x, y, x+1, y+1, PEARL)
# Aperture, short hood, and the one visible side eye.
g.ellipse(20, 17, 2, 5, TEAL)
g.rect(20, 14, 20, 19, RIM)
g.poly([(18, 12), (21, 11), (24, 13), (24, 15), (20, 16)], PURPLE)
g.rect(20, 12, 22, 12, PEARL)
g.rect(21, 16, 23, 17, PURPLE)
g.rect(21, 13, 23, 15, WHITE)
g.rect(23, 14, 23, 15, OUT)
g.outline(OUT)
g.recenter()

if __name__ == '__main__':
    save_sprite('dusk_nautilus', g.to_image())
