"""Снежная голотурия — arctic/common. Original, editable Grid sprite.
The eye and two soft supports are game stylization, not natural anatomy.
Revisions 0, 1, 2, 3 preserve the initial construction and two design passes.
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#edf8ed'; BASE='#c2d8d5'; SHADE='#86a6b3'
TEAL='#85c5c0'; WHITE='#ffffff'

def build(revision=3):
    g=Grid()
    g.ellipse(14,15,8,4,BASE)
    g.rect(21,12,24,15,BASE)
    g.ellipse(10,19,3,1,SHADE)
    g.ellipse(19,19,3,1,SHADE)
    g.ellipse(13,13,6,2,LIGHT,only_where='filled')
    g.poly([(8,16),(12,17),(20,17),(22,16),(21,18),(9,18)],SHADE)
    g.line(12,14,10,17,TEAL)
    g.line(18,14,16,17,TEAL)
    g.rect(22,13,23,14,WHITE); g.set(23,14,OUT)
    if revision>=1:
        # Two broad attached cushions, with a shallow notch between them.
        g.ellipse(10,19,3,2,BASE)
        g.ellipse(19,19,3,2,BASE)
        g.rect(8,20,12,20,SHADE); g.rect(17,20,21,20,SHADE)
        # Lift the forehead while keeping the rear round and entirely tailless.
        g.rect(20,11,22,12,BASE)
        g.rect(20,11,21,11,LIGHT)
        g.rect(23,12,24,13,BASE)
        g.rect(22,12,23,13,WHITE); g.set(23,13,OUT)
    if revision>=2:
        # Replace two thin marks with soft two-tone diagonal folds.
        g.poly([(12,14),(14,14),(12,17),(10,17)],TEAL)
        g.poly([(18,14),(20,14),(18,17),(16,17)],TEAL)
        g.line(12,16,11,17,SHADE); g.line(18,16,17,17,SHADE)
        g.line(10,14,11,14,LIGHT); g.line(16,14,17,14,LIGHT)
        g.rect(8,19,11,19,LIGHT); g.rect(17,19,20,19,LIGHT)
    if revision>=3:
        # Bridge the tiny dip behind the raised front: a single soft back,
        # never two horn-like bumps in the black silhouette.
        g.rect(16,11,21,12,BASE)
        g.line(12,11,20,11,LIGHT)
    g.outline(OUT); g.recenter()
    return g.to_image()

if __name__=='__main__':
    import pixel
    pixel.OUT_PREVIEW=os.path.join(pixel.HERE,'preview','batch05-b')
    save_sprite('snow_bolster_cucumber',build())
