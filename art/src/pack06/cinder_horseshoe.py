"""Original cinder horseshoe — volcano / rare, low right-facing side profile."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import pixel
from pixel import Grid, save_sprite
OUT = '#1d2b3a'
LIGHT, BODY, SHADE = '#bc8b65', '#805a4e', '#4b393d'
EMBER, GLOW, LEG, RIM = '#c7613c', '#f1ab56', '#8b3340', '#d4ae87'
WHITE = '#ffffff'

def build():
    g = Grid()
    # Broad, straight telson behind the animal. No claws or antennae.
    g.poly([(5,18),(12,16),(16,16),(16,20),(11,20)],BODY)
    g.rect(7,18,13,18,LIGHT)
    # Three compact, joined foot masses — not isolated single-pixel legs.
    for x in (14,19,24):
        g.rect(x,20,x+2,24,LEG)
        g.rect(x,24,x+2,24,EMBER)
    # Two broad stepped rear plates.
    g.poly([(11,17),(13,14),(17,14),(20,17),(20,21),(14,21)],BODY)
    g.rect(13,15,16,16,LIGHT)
    g.rect(12,18,15,19,SHADE)
    g.rect(16,17,18,20,EMBER)
    # Forward dome: low rounded cap on the right, never a frontal crab.
    g.poly([(16,18),(17,15),(19,12),(21,11),(24,11),(26,13),(28,17),(28,20),(26,21),(18,21)],BODY)
    g.poly([(17,16),(19,13),(21,11),(24,11),(26,13),(21,13),(19,16)],LIGHT)
    g.line(18,15,20,13,RIM)
    g.line(20,13,22,12,RIM)
    g.line(21,12,24,12,RIM)
    g.set(25,13,LIGHT)
    g.poly([(17,19),(28,19),(27,21),(18,21)],SHADE)
    g.rect(20,19,25,19,EMBER)
    g.rect(24,18,26,18,GLOW)
    g.rect(25,16,26,17,WHITE)
    g.set(26,17,OUT)
    g.outline(OUT)
    g.recenter()
    return g.to_image()

if __name__ == '__main__':
    pixel.OUT_PNG = str(Path(__file__).resolve().parents[1] / 'png')
    pixel.OUT_PREVIEW = str(Path(__file__).resolve().parents[1] / 'preview' / 'batch03-a')
    save_sprite('cinder_horseshoe', build())
