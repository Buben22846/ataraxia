"""Original sea angel; arctic / rare. Side view; opaque stylized planes."""
import os,sys
sys.path.insert(0,os.path.join(os.path.dirname(os.path.abspath(__file__)),'..'))
from pixel import Grid,save_sprite
OUT='#1d2b3a'; LIGHT='#e6ffff'; BASE='#a9dfeb'; SHADE='#639aaf'
WING='#c8f0f1'; TURQ='#6ec3cb'; HEART='#e8a993'; PINK='#b77785'; WHITE='#ffffff'
g=Grid()
# Small far parapodium swept backwards; body hides its attachment.
g.poly([(18,13),(12,8),(7,7),(8,11),(13,14),(17,16)], TURQ)
g.poly([(9,8),(12,9),(15,12),(12,11)], WING)
# Diagonal taper: lower-left tail to upper-right head, never frontal.
g.poly([(9,26),(11,20),(14,14),(18,10),(19,6),(22,5),(25,7),(25,11),(21,15),(20,20),(16,24)], BASE)
g.poly([(9,26),(13,22),(17,17),(19,13),(21,12),(20,19),(16,24)], SHADE)
g.poly([(11,22),(15,14),(19,10),(20,7),(22,6),(23,7),(21,12),(18,15),(14,21)], LIGHT)
# One connected warm internal plane, painted opaque (not real transparency).
g.poly([(17,13),(18,12),(20,13),(21,12),(22,14),(20,18),(18,17)], HEART)
g.poly([(18,16),(20,16),(21,15),(20,18)], PINK)
# Broad near parapodium projects lower-right, asymmetrical to far wing.
g.poly([(17,16),(21,14),(27,18),(27,21),(24,22),(19,20)], TURQ)
g.poly([(19,16),(21,15),(25,18),(26,20),(23,19)], WING)
g.rect(23,8,24,9,WHITE); g.set(24,9,OUT)
# Compact connected heart plane; never semi-transparent.
g.rect(18,12,19,13,HEART)
g.rect(21,12,21,13,HEART)
g.rect(18,14,21,14,HEART)
g.rect(19,15,20,15,HEART)
g.set(19,16,PINK)
g.set(20,15,PINK)
g.outline(OUT); g.recenter()
if __name__=='__main__': save_sprite('sea_angel',g.to_image())
