"""Камбала-плащ / haunted common — seasonal event candidate, not integrated.
Grid-native original art. Run from any working directory; writes only sibling art/.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#d7d6df'; BODY='#a3a1b8'; SHADE='#6c6a88'
RIM='#9dbcae'; PATINA='#638b83'; FOLD='#917da0'; WHITE='#ffffff'

def build():
    g=Grid()
    # Short blunt tail merging into an unbroken mantle; no wing notches.
    g.rect(6,15,10,17,PATINA)
    for y,a,b in [(10,12,15),(11,11,18),(12,10,21),(13,10,22),
                  (14,9,23),(15,8,24),(16,8,25),(17,9,25),
                  (18,10,24),(19,11,22),(20,13,22),(21,17,20)]:
        g.rect(a,y,b,y,RIM if y<17 else PATINA)
    g.poly([(10,15),(14,12),(19,12),(24,15),(25,18),(20,19),(14,19)],BODY)
    g.poly([(11,15),(14,12),(19,12),(21,14),(16,14)],LIGHT)
    g.poly([(12,17),(17,18),(24,18),(23,19),(15,20)],SHADE)
    # Two broad textile folds, not rays or individual spines.
    g.poly([(11,12),(13,11),(16,14),(14,14)],FOLD)
    g.poly([(16,18),(18,18),(21,21),(18,21)],FOLD)
    g.rect(13,15,16,15,BODY)
    g.rect(22,14,23,15,WHITE);g.set(23,15,OUT)
    g.rect(19,13,20,14,LIGHT);g.rect(20,13,20,14,OUT)
    g.set(25,17,OUT)
    g.outline(OUT);g.recenter()
    return g

if __name__=='__main__':
    save_sprite('shroud_flatfish',build().to_image())
