"""Original pall brittle star. Editable Grid; build(0|1|2), final=2.
Rebuild: python3 art/src/pall_brittle_star.py --iteration 2
Five anatomical arms are compressed into three perspective masses, not a frontal star.
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from pixel import Grid
from PIL import Image
O='#1d2b3a';L='#ded8e4';B='#aea0bc';S='#756782';M='#aec8b9';P='#72978c';F='#9683aa';W='#ffffff'
ROOT=Path(__file__).resolve().parents[2]
def build(iteration=2):
    g=Grid()
    # Rear bent arm-mass, broad blunt distal segment rather than a ray.
    g.poly([(18,12),(13,10),(11,6),(5,6),(5,8),(8,9),(10,13),(16,16),(19,15)],B)
    g.poly([(5,6),(10,6),(12,10),(11,11),(8,8),(5,8)],L)
    g.poly([(10,12),(16,14),(18,14),(18,16),(14,15)],S)
    # Lower short support, initially too straight; revision opens a deliberate elbow.
    if iteration==0:
        g.poly([(15,15),(19,17),(17,23),(9,23),(9,21),(14,20)],B)
    else:
        g.poly([(15,15),(19,17),(16,21),(12,24),(7,24),(7,22),(11,21),(13,18)],B)
        g.poly([(8,22),(11,22),(15,19),(16,17),(18,18),(15,22),(12,24),(8,24)],S)
        g.line(8,22,11,22,L)
    # Front arm curves down and then right; no claw, isolated tip or tail spike.
    g.poly([(21,14),(24,15),(24,17),(27,18),(27,20),(23,20),(20,18),(18,16)],B)
    g.poly([(22,17),(25,18),(27,18),(27,20),(24,20),(21,18)],S)
    # Two shorter FAR arms are surface-overlapped ribbons within the same three masses.
    g.poly([(17,12),(14,11),(12,9),(11,8),(13,8),(16,10),(19,11)],P)
    g.poly([(19,16),(16,18),(14,21),(12,22),(14,22),(18,20),(21,17)],P)
    g.line(14,10,17,11,M)
    # Small off-centre disc; revision 2 reduces bulk and gives it a sloping right cheek.
    if iteration<2:
        g.ellipse(19,14,5,4,B)
        g.ellipse(17,12,3,1,L,only_where='filled')
    else:
        g.poly([(17,11),(21,10),(23,12),(23,15),(21,17),(18,17),(16,14)],B)
        g.poly([(17,11),(20,10),(21,11),(19,12),(17,13)],L)
        g.poly([(17,15),(20,16),(23,14),(22,16),(20,17),(18,17)],S)
        # Wide pall-like painted band; not a held cloth or detachable object.
        g.poly([(23,15),(24,16),(24,17),(26,18),(25,19),(22,17)],L)
        g.line(24,17,25,18,M)
    if iteration>=2:
        # Three-pixel blunt terminal pads; keep them part of curved masses.
        g.rect(5,6,8,8,L)
        g.rect(7,21,10,23,B);g.line(7,21,10,21,L)
        g.rect(25,18,27,20,S);g.line(25,18,27,18,L)
    ex,ey=(21,12) if iteration>=2 else (21,13)
    g.rect(ex,ey,ex+1,ey+1,W);g.set(ex+1,ey+1,O)
    g.outline(O)
    return g

def render(iteration=2):
    im=build(iteration).to_image();out=ROOT/'art/preview/batch05-c';out.mkdir(parents=True,exist_ok=True)
    im.save(out/f'pall_brittle_star_iter{iteration}.png')
    bg=Image.new('RGBA',(256,256),'#393447');bg.alpha_composite(im.resize((256,256),Image.Resampling.NEAREST));bg.save(out/f'pall_brittle_star_iter{iteration}_x8.png')
    if iteration==2:im.save(ROOT/'art/png/pall_brittle_star.png')
    return im
if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--iteration',type=int,choices=[0,1,2],default=2);a=p.parse_args();render(a.iteration)
