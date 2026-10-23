"""Рыба-ходульщик / abyss epic. Original right profile, three solid supports."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#8894ae'; BASE='#535d7c'; SHADE='#303b58'
FIN='#637ba2'; TEAL='#3fa8b5'; PURPLE='#ba85c6'; PEARL='#b5d8d7'; WHITE='#ffffff'
g=Grid()
# Far, shorter support; two near supports create the tall open bridge.
g.poly([(15,10),(17,11),(15,22),(13,22)],PURPLE)
g.poly([(10,10),(12,11),(7,24),(5,27),(3,27),(6,22)],FIN)
g.poly([(21,10),(23,11),(25,23),(28,27),(25,27),(22,23)],TEAL)
g.line(7,22,5,25,PEARL)
g.line(24,23,26,26,PEARL)
# Small fork tail and thin horizontal back: never a jellyfish bell.
g.poly([(3,5),(8,8),(8,10),(3,12),(4,8)],FIN)
g.poly([(8,7),(18,6),(24,7),(28,9),(28,11),(22,12),(10,11),(7,9)],BASE)
g.poly([(9,7),(18,6),(23,7),(24,8),(12,8)],LIGHT)
g.rect(12,10,24,11,SHADE)
# Short side gill, subdued jaw, bright eyes remain the focal point.
g.line(22,8,21,9,FIN)
g.poly([(13,7),(16,5),(18,5),(19,7)],FIN)
g.rect(18,9,19,10,PURPLE)
g.rect(14,19,15,20,PEARL)
g.rect(4,26,6,26,PEARL)
g.rect(24,8,25,9,WHITE); g.set(25,9,OUT)
g.set(28,10,OUT)
g.outline(OUT); g.recenter()
if __name__=='__main__': save_sprite('stilt_fish', g.to_image())
