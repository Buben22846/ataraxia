"""Узловая миксина — abyss/epic. Original editable Grid ribbon.
Central crossing and white eye are fictional game design, not an anatomy claim.
Revisions 0/1/2/3 record silhouette, aperture and crossing-plane refinements.
"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#9da9c2'; BASE='#616d90'; SHADE='#394565'
TEAL='#5cafb5'; DEEP='#397e91'; MID='#899bc4'; WHITE='#ffffff'

def build(revision=3):
    g=Grid()
    # The returning ribbon bends underneath a single low crossing.
    g.poly([(11,9),(16,9),(20,12),(22,17),(22,22),(19,26),
            (11,26),(7,23),(7,19),(9,15)],BASE)
    g.poly([(7,21),(10,23),(18,24),(21,21),(22,20),(22,23),
            (19,26),(11,26),(7,23)],SHADE)
    g.poly([(11,10),(15,10),(18,12),(18,14),(14,12),(11,14),(9,17),(9,14)],LIGHT)
    # Deliberate clear aperture; outline will inset it by one pixel.
    g.rect(12,17,17,22,None)
    g.poly([(3,11),(7,11),(12,13),(18,15),(23,13),(27,13),
            (28,14),(28,17),(23,18),(18,19),(12,17),(7,15),(3,15)],BASE)
    g.poly([(3,11),(7,11),(13,14),(18,15),(17,16),(11,15),(6,13),(3,13)],LIGHT)
    g.poly([(19,15),(23,13),(27,13),(28,15),(27,17),(22,18),(19,18)],TEAL)
    g.rect(25,14,26,15,WHITE); g.set(26,15,OUT)
    if revision>=1:
        # Open the low knot wider: the hole is central, never at the free tail.
        g.rect(12,18,17,23,None)
        g.rect(11,19,11,22,None)
        g.rect(18,19,18,22,None)
        g.rect(10,24,18,24,BASE)
        g.line(11,24,17,24,MID)
    if revision>=2:
        # Two broad overlapping planes, rather than a solitary divider stroke.
        g.poly([(9,13),(12,14),(18,16),(21,15),(21,18),(18,19),(13,17),(9,15)],SHADE)
        g.poly([(9,12),(12,13),(18,15),(21,14),(21,16),(18,17),(12,15),(9,14)],MID)
        g.line(10,12,14,14,LIGHT)
        g.poly([(20,15),(23,13),(27,13),(28,15),(27,17),(22,18),(20,17)],TEAL)
        g.line(22,17,25,17,DEEP)
        g.rect(25,14,26,15,WHITE); g.set(26,15,OUT)
    if revision>=3:
        # Rebuild as a continuous tied ribbon: tail descends into the low loop,
        # returning strand climbs behind it and exits into the right-facing head.
        # This removes the cap-like top bump of pass2.
        g=Grid()
        g.poly([(7,21),(9,17),(16,10),(20,10),(24,12),(28,13),
                (28,16),(23,16),(20,14),(12,21),(11,25),(8,25)],BASE)
        g.poly([(8,20),(10,16),(16,10),(19,10),(18,12),(12,18),(10,22)],LIGHT)
        g.poly([(3,10),(7,10),(12,13),(19,17),(23,20),(23,24),
                (20,28),(11,28),(7,26),(6,23),(8,19),(11,20),
                (10,23),(12,25),(17,25),(19,23),(17,20),
                (10,17),(6,14),(3,14)],BASE)
        g.poly([(7,24),(11,26),(19,26),(22,23),(23,23),(23,25),
                (20,28),(11,28),(7,26)],SHADE)
        g.line(11,26,18,26,MID)
        g.rect(12,19,18,24,None)
        # The foreground diagonal is a 4px broad plane, not a thin X mark.
        g.poly([(3,10),(7,10),(13,14),(19,17),(20,20),(16,19),
                (10,16),(6,13),(3,13)],MID)
        g.poly([(3,10),(7,10),(12,13),(13,15),(10,14),(6,12),(3,12)],LIGHT)
        g.poly([(11,16),(16,19),(20,20),(19,21),(15,20),(10,17)],SHADE)
        g.poly([(20,12),(24,12),(28,13),(28,16),(23,16),(20,14)],TEAL)
        g.line(22,15,26,16,DEEP)
        g.rect(25,13,26,14,WHITE); g.set(26,14,OUT)
        # Preserve >=3x4 clear pixels AFTER all crossing planes and outline.
        g.rect(12,19,18,25,None)
        for x,y in [(12,19),(13,19),(12,20),(18,19),(17,19),(18,20),
                    (12,25),(13,25),(12,24),(18,25),(17,25),(18,24)]: g.set(x,y,SHADE)
    g.outline(OUT); g.recenter()
    return g.to_image()

if __name__=='__main__':
    import pixel
    pixel.OUT_PREVIEW=os.path.join(pixel.HERE,'preview','batch05-b')
    save_sprite('knot_hagfish',build())
