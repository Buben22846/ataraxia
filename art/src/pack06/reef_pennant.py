"""Original reef pennant — lagoon / rare; right profile, editable Grid shapes."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import pixel
from pixel import Grid, save_sprite
OUT = '#1d2b3a'
LIGHT, BODY, SHADE = '#ffefd2', '#edc47b', '#b28a5a'
FLAG, FIN_SHADOW = '#f0a34d', '#b46045'
BAND, FIN = '#426c7c', '#7bc7ba'
WHITE = '#ffffff'

def build():
    g = Grid()
    # Caudal lobe: small, broad, clearly behind the tall body.
    g.poly([(5,16),(10,18),(10,20),(5,22)], FIN)
    g.rect(5,20,7,21,BAND)
    # A SINGLE solid dorsal pennant, swept backward with a blunt tip.
    g.poly([(6,3),(9,3),(12,4),(16,6),(18,10),(17,14),(14,12),(13,8),(9,6),(6,6)], FLAG)
    # Deep diamond body, with short projecting snout at the right.
    g.poly([(17,10),(21,12),(24,16),(26,17),(26,19),(23,20),(17,26),(11,22),(9,18),(12,14)], BODY)
    g.poly([(17,10),(21,12),(23,15),(18,14),(13,17),(10,18),(12,14)], LIGHT)
    g.poly([(11,21),(17,23),(22,20),(23,20),(17,26)], SHADE)
    # Broad diagonal sash, no curls, dots, or little secondary pennants.
    g.poly([(13,13),(15,11),(20,22),(18,25)], BAND)
    g.poly([(12,19),(16,20),(16,22),(14,23),(12,22)], FLAG)
    g.line(13,22,15,22,FIN_SHADOW)
    # A small gill mark keeps the projecting face legible against the sash.
    g.line(22,18,22,19,SHADE)
    g.rect(23,16,24,17,WHITE)
    g.set(24,17,OUT)
    g.set(26,19,OUT)
    g.outline(OUT)
    g.recenter()
    return g.to_image()

if __name__ == '__main__':
    # Resolve paths from THIS working copy, never the shell's current directory.
    pixel.OUT_PNG = str(Path(__file__).resolve().parents[1] / 'png')
    pixel.OUT_PREVIEW = str(Path(__file__).resolve().parents[1] / 'preview' / 'batch03-a')
    save_sprite('reef_pennant', build())
