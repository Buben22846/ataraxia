"""Мандаринка / Synchiropus splendidus — lagoon, proposed rare.
Original hand-authored 32px candidate; no game/config integration.
Run from repository root: python3 art/src/mandarin.py
"""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite

OUT = '#1d2b3a'
BODY = '#28b9b1'
LIGHT = '#83e5cc'
SHADE = '#187e91'
ORANGE = '#f49b38'
GOLD = '#ffd078'
RUST = '#d65d32'
WHITE = '#ffffff'

g = Grid()
# Rounded caudal fan, two soft dorsal lobes and pelvic fin.
g.ellipse(6, 16, 3, 4, BODY)
g.ellipse(5, 16, 1, 3, ORANGE)
g.ellipse(13, 10, 3, 3, BODY)
g.ellipse(12, 9, 1, 1, GOLD)
g.ellipse(13, 11, 1, 2, ORANGE)
g.ellipse(19, 10, 3, 2, BODY)
g.ellipse(17, 22, 3, 1, RUST)
g.line(15, 22, 18, 22, ORANGE)
# Compact dragonet body, slightly pointed snout on right.
g.ellipse(17, 16, 9, 5, BODY)
g.poly([(23, 14), (26, 16), (26, 18), (23, 18)], BODY)
g.ellipse(16, 13, 6, 1, LIGHT, only_where='filled')
g.ellipse(16, 20, 7, 1, SHADE, only_where='filled')
# Broad orange saddles, not a noisy scale pattern.
def band(points, color):
    mask = Grid()
    mask.poly(points, color)
    for y in range(11, 22):
        for x in range(9, 26):
            if mask.get(x, y) and g.get(x, y):
                g.set(x, y, color)
band([(11, 11), (14, 11), (13, 15), (15, 18), (14, 20), (11, 17)], ORANGE)
band([(17, 12), (19, 12), (18, 16), (20, 19), (18, 20), (16, 17)], ORANGE)
# Orange cheek marks the dragonet head without adding micro-patterns.
g.rect(23, 17, 25, 18, ORANGE)
# Rounded near-side fin, highlighted upper-left.
g.ellipse(21, 19, 2, 2, SHADE)
g.ellipse(21, 19, 1, 1, ORANGE)
g.line(20, 18, 21, 18, GOLD)
g.line(21, 20, 22, 20, RUST)
# Bright 2x2 eye and forward pupil, consistent with guppy.
g.rect(23, 14, 24, 15, WHITE)
g.set(24, 15, OUT)
g.outline(OUT)
g.recenter()

if __name__ == '__main__':
    save_sprite('mandarin', g.to_image())
