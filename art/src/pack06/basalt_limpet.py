"""Original basalt limpet / volcano common. Living right-facing mollusc."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#998b83'; BODY='#665b5b'; SHADE='#403940'
FOOT='#b76e43'; SEAM='#eea755'; FOOT_SHADE='#742f37'; FACE='#c28d72'; WHITE='#ffffff'
g=Grid()
# Visible creeping sole, with a head emerging beyond the right shell edge.
g.poly([(8,18),(21,17),(24,16),(25,18),(25,20),(23,21),(9,21),(7,20)],FOOT)
g.rect(9,21,23,21,FOOT_SHADE)
g.rect(22,17,25,19,FACE)
g.rect(22,20,24,20,FOOT)
g.rect(23,16,24,17,FACE)
# Off-center apex: long slope to the right, no spiral or rock-only icon.
g.poly([(7,18),(9,15),(12,11),(14,11),(19,14),(22,18),(21,19),(8,19)],BODY)
g.poly([(9,15),(12,11),(14,11),(15,12),(12,14)],LIGHT)
g.poly([(8,17),(21,17),(22,18),(21,19),(8,19)],SHADE)
g.poly([(14,12),(15,12),(17,14),(17,15),(19,16),(20,18),(18,18),(17,16),(15,15)],SEAM)
g.rect(23,16,24,17,WHITE);g.set(24,17,OUT)
g.rect(10,20,20,20,FACE)
g.set(25,19,OUT)
g.outline(OUT);g.recenter()
if __name__=='__main__': save_sprite('basalt_limpet',g.to_image())
