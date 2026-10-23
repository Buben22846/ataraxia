"""Печной хитон — original volcano / common, editable Grid geometry.
Eight individually authored overlapping plates, soft right-facing forefoot.
Run: python3 art/src/kiln_chiton.py. No game integration.
"""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import pixel
from pixel import Grid, save_sprite
OUT = '#1d2b3a'
LIGHT, BODY, SHADE = '#b19a86', '#79615c', '#493c45'
BELT, AMBER, TERRA, FOOT = '#a85240', '#e39a56', '#c76b46', '#d4b582'
WHITE = '#ffffff'
# Eight abutting plates in rear-to-front order (left x, top y).
PLATES = ((7,14),(9,12),(11,12),(13,11),(15,11),(17,12),(19,12),(21,14))

def build():
    g = Grid()
    # Continuous soft sole; no legs, shell spike, or tail.
    g.poly([(7,19),(22,18),(24,17),(25,18),(25,20),(23,21),(8,21),(7,20)],TERRA)
    g.rect(8,21,23,21,SHADE)
    g.line(9,20,21,20,FOOT)
    g.rect(22,18,25,20,FOOT)
    # Exactly eight solid plates. Interior seams use shell shade, not black.
    for i,(x,top) in enumerate(PLATES):
        g.rect(x,top,x+1,18,BODY)
        g.line(x,top,x+1,top,LIGHT)
        # Short alternating laps group the rhythm; no eight black bars.
        g.line(x+1,top+2+(i % 2),x+1,17,SHADE)
    g.rect(7,18,22,19,BELT)
    g.line(8,18,21,18,TERRA)
    # Two broad amber articulation facets, not lava or emissive dots.
    g.rect(12,15,13,16,AMBER)
    g.rect(18,15,19,16,AMBER)
    g.line(8,20,23,20,FOOT)
    g.line(8,19,21,19,TERRA)
    g.rect(23,17,24,18,WHITE)
    g.set(24,18,OUT)
    g.set(25,20,OUT)
    g.outline(OUT)
    g.recenter()
    return g.to_image()

if __name__ == '__main__':
    pixel.OUT_PNG = str(Path(__file__).resolve().parents[1] / 'png')
    pixel.OUT_PREVIEW = str(Path(__file__).resolve().parents[1] / 'preview' / 'batch04-a')
    save_sprite('kiln_chiton', build())
