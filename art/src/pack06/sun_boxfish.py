"""Original sun boxfish / lagoon common. Deterministic 32px, right profile."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#fff09a'; BODY='#edc454'; SHADE='#b78738'
FIN='#f39f64'; FIN_SHADE='#bc6549'; SPOT='#6c5550'; WHITE='#ffffff'
g=Grid()
# Short, squared caudal fin rather than a puffer's fan/spines.
g.poly([(7,13),(10,14),(11,18),(7,19)],FIN)
g.rect(7,17,9,19,FIN_SHADE)
g.poly([(15,10),(17,9),(19,10),(19,12)],FIN)
g.poly([(16,20),(18,22),(20,21)],FIN)
# Flat back, clipped corners, vertical face, flat underside.
g.poly([(12,10),(22,10),(24,12),(24,20),(22,22),(12,22),(10,20),(10,12)],BODY)
g.poly([(12,10),(22,10),(23,12),(11,12)],LIGHT)
g.poly([(11,19),(23,19),(24,20),(22,22),(12,22)],SHADE)
g.rect(11,13,11,17,LIGHT)
g.rect(24,17,25,18,BODY)
g.rect(13,14,15,16,SPOT)
g.rect(18,16,20,18,SPOT)
g.poly([(15,18),(13,19),(15,21),(17,20)],FIN)
g.line(15,20,16,20,FIN_SHADE)
g.rect(21,13,22,14,WHITE);g.set(22,14,OUT)
g.outline(OUT);g.recenter()
if __name__=='__main__': save_sprite('sun_boxfish',g.to_image())
