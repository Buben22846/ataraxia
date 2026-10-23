"""Купологлаз — original abyss/rare; opaque dome, no antenna."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#8b9bbb'; BASE='#53617f'; SHADE='#333d5c'
GLASS='#8bc9c8'; TEAL='#48a7ad'; GREEN='#b6db71'; PURPLE='#7f62a5'; WHITE='#ffffff'
g=Grid()
g.poly([(5,14),(10,17),(10,19),(5,21),(6,17)],PURPLE)
g.poly([(12,19),(18,19),(19,22),(14,22),(10,21)],TEAL)
g.ellipse(17,18,9,3,BASE)
g.ellipse(17,20,7,1,SHADE,only_where='filled')
# One solid pale dome integrated into the head; no real transparency.
g.ellipse(20,13,6,5,TEAL)
g.ellipse(19,12,5,4,GLASS,only_where='filled')
g.rect(16,10,18,10,LIGHT)
g.rect(16,11,17,11,LIGHT)
# Lime internal tubular eye, large block rather than isolated pixels.
g.rect(20,12,23,16,GREEN)
g.rect(22,12,23,13,WHITE); g.set(23,13,OUT)
g.poly([(18,18),(22,19),(20,22),(16,21)],PURPLE)
# Dark jaw anchors the pale dome in a short fish body.
g.rect(21,18,25,19,SHADE)
g.rect(24,18,26,18,BASE)
g.poly([(17,19),(20,20),(19,22),(14,22)],PURPLE)
g.line(16,20,18,20,LIGHT)
g.set(26,19,OUT)
g.outline(OUT); g.recenter()
if __name__=='__main__': save_sprite('glass_barreleye',g.to_image())
