"""Инеевый белокровник — original arctic/common; right profile."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#e9fcff'; BASE='#b7dbe4'; SHADE='#7ca0b5'
FIN='#6cbec6'; DEEP='#488a9f'; LILAC='#b8b7d8'; PEARL='#dbd2ee'; WHITE='#ffffff'
g=Grid()
# Short blunt caudal fan, low back and long sloping wedge head.
g.poly([(6,12),(9,13),(11,14),(10,16),(6,17),(7,14)],FIN)
g.poly([(10,12),(17,11),(21,12),(25,15),(25,16),(17,17),(10,16)],BASE)
g.poly([(11,12),(17,11),(21,12),(23,14),(17,13),(11,14)],LIGHT)
g.poly([(11,16),(24,16),(18,17),(12,17)],SHADE)
# Dominant near pectoral fan below the head; not a shark dorsal.
g.poly([(18,15),(21,18),(19,21),(14,21),(11,19),(13,17)],FIN)
g.poly([(18,16),(19,18),(17,20),(14,20),(12,19),(14,17)],LILAC)
g.poly([(17,17),(18,18),(16,20),(14,19)],PEARL)
g.line(18,17,19,19,DEEP)
g.line(19,14,18,15,SHADE)
g.rect(20,13,21,14,WHITE); g.set(21,14,OUT)
# Two broad cold rays preserve fan readability without extra palette entries.
g.rect(13,18,14,18,PEARL)
g.set(16,20,DEEP)
g.outline(OUT); g.recenter()
if __name__=='__main__': save_sprite('frost_icefish',g.to_image())
