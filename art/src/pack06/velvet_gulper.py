"""Бархатный большерот — original abyss / epic, right-facing open pouch.
Editable Grid planes, four reproducible design passes via build(revision).
No shell, spiral, teeth, lure or tentacles. Light from upper-left.
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#8998b9'; BASE='#505a7c'; SHADE='#303b58'
PURPLE='#6f5b92'; TEAL='#4cabb1'; LILAC='#b591cd'; PEARL='#a9d1d3'; WHITE='#ffffff'

def build(revision=3):
    g=Grid()
    g.poly([(3,9),(7,11),(11,10),(12,14),(8,14),(4,15),(5,12)],PURPLE)
    g.rect(4,10,5,11,LIGHT)
    # A small head on top of an asymmetric hanging pear, not a round shell.
    bottom=24 if revision==0 else 25
    g.poly([(9,11),(13,8),(20,5),(23,5),(26,7),(28,9),(23,10),
            (17,11),(16,14),(18,18),(22,20),(27,19),(27,22),
            (24,bottom),(18,bottom+1),(13,23),(11,19),(10,15)],BASE)
    g.poly([(12,16),(15,19),(19,22),(24,23),(26,21),(24,bottom),
            (18,bottom+1),(13,23)],PURPLE)
    g.poly([(13,20),(18,24),(23,24),(21,25),(18,bottom+1),(14,23)],SHADE)
    g.poly([(11,11),(15,8),(20,6),(23,6),(24,7),(18,8),(14,11)],LIGHT)
    # Continuous broad teal lip; its right edge stays open.
    g.poly([(16,10),(23,9),(28,9),(27,11),(20,12),(18,13),
            (18,16),(20,18),(23,19),(27,18),(27,21),(23,23),
            (19,21),(16,18),(14,14),(14,12)],TEAL)
    # Connected velvet mouth, merging into the transparent right-facing opening.
    g.poly([(19,12),(25,11),(28,11),(28,17),(24,19),(22,19),
            (19,17),(17,14)],SHADE)
    # Remove the opening so the silhouette itself reads as an open jaw.
    for y in range(11,19):
        for x in range(27 if y<17 else 28,32): g.set(x,y,None)
    g.rect(23,8,24,9,WHITE); g.set(24,9,OUT)
    if revision>=1:
        # Thicker lower ribbon and two-pixel light on the upper-left fold.
        g.poly([(17,16),(20,19),(23,20),(27,18),(27,21),(23,23),
                (19,21),(16,18)],TEAL)
        g.line(16,12,16,14,PEARL)
        g.line(17,15,18,16,PEARL)
        g.rect(21,22,23,22,LILAC)
    if revision>=2:
        # Stronger droop, thick low jaw, no annular ornament or spiral.
        g.poly([(13,18),(15,21),(19,23),(24,23),(23,25),
                (18,26),(14,24)],PURPLE)
        g.poly([(18,21),(22,23),(25,22),(27,20),(27,22),(24,24),
                (21,24)],TEAL)
        g.line(19,22,22,23,PEARL)
        g.rect(15,22,16,23,LILAC)
    if revision>=3:
        # Real negative space: deep right-facing bite in the silhouette.
        # The remaining connected dark plane is the throat, not a closed disc.
        for y,cut in [(11,26),(12,24),(13,23),(14,23),(15,23),(16,23),(17,24),(18,26)]:
            for x in range(cut,32): g.set(x,y,None)
    g.outline(OUT); g.recenter()
    return g.to_image()

if __name__=='__main__':
    import pixel
    pixel.OUT_PREVIEW=os.path.join(pixel.HERE,'preview','batch04-b')
    save_sprite('velvet_gulper',build())
