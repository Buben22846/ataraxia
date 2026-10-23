"""Original ember lionfish; volcano / epic. 32x32, right profile."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#a96a58'; BASE='#653b43'; SHADE='#392c39'
FIN='#e87538'; EMBER='#ffc663'; RED='#a4313c'; EDGE='#f1b48a'; WHITE='#ffffff'
g=Grid()
# Three broad dorsal teeth, not individual needles.
g.poly([(8,15),(7,5),(12,9),(13,5),(17,4),(18,10),(23,6),(24,14)], RED)
g.poly([(8,6),(10,8),(12,14),(10,14)], FIN)
g.poly([(15,6),(16,5),(17,13),(15,13)], FIN)
g.poly([(22,8),(23,7),(23,13),(21,14)], FIN)
# Tail and lower pectoral fan behind the short almond body.
g.poly([(11,15),(2,11),(3,16),(2,21),(11,19)], RED)
g.poly([(4,13),(8,15),(8,18),(4,20)], FIN)
g.poly([(12,18),(9,24),(14,24),(18,27),(21,23),(25,25),(23,18)], RED)
g.poly([(13,20),(12,23),(15,22),(18,25),(19,23),(18,20)], FIN)
g.poly([(22,20),(23,23),(21,22)], FIN)
g.ellipse(19,16,8,5,BASE)
g.poly([(11,15),(14,12),(20,11),(25,13),(21,14),(15,14)], LIGHT)
g.poly([(12,18),(17,19),(25,18),(23,21),(16,21)], SHADE)
g.rect(12,12,14,12,EDGE)
g.rect(11,22,13,22,EDGE)
g.rect(17,23,18,24,FIN)
g.rect(4,13,5,14,EDGE)
# Wide rhythmic bands, restricted to body.
g.poly([(14,14),(16,14),(18,18),(16,19)], RED)
g.poly([(19,13),(21,13),(22,18),(20,18)], RED)
for x,y in ((11,11),(16,10),(21,11)):
    g.rect(x,y,x+1,y+1,EMBER)
g.rect(23,14,25,16,WHITE); g.rect(24,15,25,16,OUT)
g.rect(26,18,27,18,OUT)
g.outline(OUT); g.recenter()
if __name__=='__main__': save_sprite('ember_lionfish',g.to_image())
