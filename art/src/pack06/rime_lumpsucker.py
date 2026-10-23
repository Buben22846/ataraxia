"""Инеевый пинагор — original arctic / rare. Editable Grid geometry.
Three intentional production passes are preserved by build(revision=0/1/2).
Final: pear-shaped back, three blunt nodules, integrated ventral suction disc.
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#e8f7f5'; BASE='#aecbd4'; SHADE='#758ca6'
TEAL='#84bfc4'; DEEP='#568e9d'; LILAC='#c5b6d6'; WARM='#e4cba7'; WHITE='#ffffff'

def build(revision=2):
    g=Grid()
    g.poly([(5,13),(9,15),(12,14),(12,18),(9,18),(5,19),(6,16)],DEEP)
    g.rect(6,14,7,16,TEAL)
    # Continuous asymmetric back: narrow tail root, high head, rounded cheek.
    g.poly([(10,14),(12,10),(16,7),(21,6),(24,8),(26,12),(26,17),
            (24,20),(20,22),(15,21),(12,19),(11,16)],BASE)
    g.poly([(12,17),(16,19),(22,20),(25,17),(24,20),(20,22),(15,21)],SHADE)
    g.poly([(12,12),(14,9),(18,7),(21,7),(23,9),(18,9),(15,12)],LIGHT)
    # Three broad, embedded nodules, never isolated needles.
    for x,y in [(13,11),(17,8),(21,8)]:
        g.ellipse(x,y,1.5,1,TEAL)
        g.rect(x-1,y-1,x,y-1,LIGHT)
    g.poly([(15,15),(18,14),(20,16),(18,19),(15,18)],TEAL)
    g.line(16,16,18,17,DEEP)
    g.rect(18,20,21,23,SHADE)
    g.ellipse(19,24,4 if revision==0 else 6,1,DEEP)
    g.line(16 if revision==0 else 14,23,22 if revision==0 else 24,23,TEAL)
    g.line(17,24,21,24,LILAC)
    g.rect(23,12,24,13,WHITE); g.set(24,13,OUT)
    g.line(25,17,26,17,OUT)
    if revision>=1:
        # Wider, shallow living sucker with warm inner pad; no upright pedestal.
        g.rect(17,21,21,23,SHADE)
        g.rect(15,23,23,23,LIGHT)
        g.rect(17,24,22,24,WARM)
    if revision>=2:
        # Link disc to belly more broadly; soften high forehead into a pear.
        g.rect(18,6,21,7,BASE)
        g.rect(18,6,20,6,LIGHT)
        g.rect(16,21,22,22,SHADE)
        g.rect(16,22,23,22,TEAL)
        g.rect(16,23,23,23,LIGHT)
        g.rect(19,10,21,11,BASE)
        g.rect(21,17,23,18,LILAC)
        g.rect(22,16,23,16,BASE)
    g.outline(OUT); g.recenter()
    return g.to_image()

if __name__=='__main__':
    import pixel
    pixel.OUT_PREVIEW=os.path.join(pixel.HERE,'preview','batch04-b')
    save_sprite('rime_lumpsucker',build())
