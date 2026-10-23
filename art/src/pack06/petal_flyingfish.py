"""Летучка-лепесток — original lagoon / rare, editable Grid geometry.
Right-facing narrow flying fish, one dominant swept pectoral blade.
Run: python3 art/src/petal_flyingfish.py. No game integration.
"""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import pixel
from pixel import Grid, save_sprite
OUT = '#1d2b3a'
LIGHT, BODY, SHADE = '#ffe3ad', '#e8ad67', '#a96a4f'
FIN, FIN_SHADE, CORAL = '#7bd2c7', '#438e9b', '#ed8875'
WHITE = '#ffffff'

def build():
    g = Grid()
    # Forked tail and long, horizontal caudal peduncle.
    g.poly([(4,16),(6,16),(9,18),(9,20),(6,23),(4,23),(6,19)], FIN)
    g.rect(7,18,15,20,BODY)
    # Small far-side lower pectoral lobe, never a symmetrical wing pair.
    g.poly([(20,20),(19,23),(17,25),(14,23),(16,20)], FIN_SHADE)
    g.poly([(16,21),(19,21),(17,23),(15,23)],FIN)
    # Main torpedo, short projecting face on the right.
    g.poly([(10,18),(21,17),(24,17),(26,18),(26,20),(23,21),(12,20),(9,20)],BODY)
    g.line(12,18,22,18,LIGHT)
    g.line(12,20,22,20,SHADE)
    # Broad backward/upward pectoral blade, attached at the shoulder.
    g.poly([(9,7),(13,7),(17,10),(22,17),(20,19),(15,15),(10,11)], FIN)
    g.poly([(9,7),(13,7),(17,10),(13,9),(10,9)], LIGHT)
    g.poly([(12,10),(15,10),(20,16),(17,15)],CORAL)
    # Two-pixel shoulder facet makes the fin a pectoral attachment, not a flag.
    g.poly([(17,16),(19,17),(21,18),(20,19),(18,18)],FIN_SHADE)
    g.line(21,19,21,20,SHADE)
    g.rect(23,18,24,19,WHITE)
    g.set(24,19,OUT)
    g.set(26,20,OUT)
    g.outline(OUT)
    g.recenter()
    return g.to_image()

if __name__ == '__main__':
    pixel.OUT_PNG = str(Path(__file__).resolve().parents[1] / 'png')
    pixel.OUT_PREVIEW = str(Path(__file__).resolve().parents[1] / 'preview' / 'batch04-a')
    save_sprite('petal_flyingfish', build())
