"""Ледяной гребешок / arctic rare. Original editable right-side bivalve.
Run from any directory with Python; uses only the project's Grid pipeline.
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#e4ffff'; BASE='#b2e0e7'; SHADE='#6dabbc'
TEAL='#88c6ca'; DEEP='#548a9c'; LILAC='#c9b8df'; PEARL='#eee0ee'; WHITE='#ffffff'
g=Grid()
# Hinge on the LEFT. Upper valve flares up and forward, not a frontal fan.
g.poly([(5,16),(9,11),(16,6),(22,6),(26,9),(27,12),(24,14),(9,17)],BASE)
g.poly([(5,16),(14,19),(26,21),(24,23),(18,24),(10,22)],TEAL)
g.poly([(10,21),(24,23),(22,24),(17,24)],DEEP)
# Three broad shell ribs diverge from hinge toward the RIGHT lip.
g.poly([(8,15),(15,8),(17,7),(18,7),(12,14)],LIGHT)
g.poly([(10,16),(20,8),(22,8),(22,9),(15,15)],LIGHT)
g.poly([(14,16),(24,11),(26,11),(25,12),(20,15)],LIGHT)
# Rib valleys remain broad stepped planes, not extra outline strokes.
g.line(11,14,16,9,SHADE)
g.line(16,14,21,10,SHADE)
g.line(11,16,24,13,SHADE)
g.rect(22,12,24,12,LIGHT)
# Opaque mantle inside the gap; a deliberate dark separation above/below.
g.poly([(8,17),(23,15),(27,16),(27,18),(24,20),(11,19)],OUT)
g.poly([(12,18),(23,16),(27,17),(26,19),(22,20)],LILAC)
g.rect(21,18,25,18,PEARL)
g.rect(24,16,25,17,WHITE); g.set(25,17,OUT)
g.rect(6,16,8,18,DEEP)
g.outline(OUT); g.recenter()
if __name__=='__main__': save_sprite('ice_scallop', g.to_image())
