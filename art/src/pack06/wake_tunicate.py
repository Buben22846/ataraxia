"""Заупокойная асцидия: original haunted / rare / seasonal art candidate.
Rebuild: python3 art/src/wake_tunicate.py --iteration 0|1|2
No external images. Editable Grid masses; v2 is the canonical PNG.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pixel import Grid, save_sprite
from PIL import Image
OUT='#1d2b3a'; LIGHT='#e2d9d9'; BASE='#b3a2b6'; SHADE='#786880'
MINT='#aec7b2'; PATINA='#72948b'; FOLD='#947fa7'; WHITE='#ffffff'

def build(iteration=2):
    g=Grid()
    # Single tunic sack; no branches, dorsal cerata, feet or coral pedestal.
    g.ellipse(14,19,7,7,BASE)
    if iteration<2:g.poly([(7,22),(11,23),(13,26),(8,26),(6,25)],BASE)
    # Broad asymmetric upper siphon; its bore is a dark slit, never a flame.
    g.poly([(12,15),(13,9),(16,4),(20,4),(22,6),(21,9),(18,11),(18,15)],BASE)
    g.poly([(13,12),(14,9),(16,6),(18,5),(18,7),(16,10),(16,14)],LIGHT)
    g.poly([(18,9),(21,7),(20,10),(18,12),(18,15),(16,15)],FOLD)
    g.line(17,5,20,6,OUT);g.line(17,6,19,7,MINT)
    # Lower siphon emerges to the right from the SAME soft sack.
    if iteration<2:
        g.poly([(19,16),(23,13),(26,13),(27,15),(27,17),(23,19),(19,20)],BASE)
        g.line(22,14,25,14,LIGHT)
        g.rect(25,15,26,16,OUT);g.line(24,17,26,17,MINT)
    # Flat light planes, soft lower sag and a small patina fold.
    g.ellipse(11,17,3,4,LIGHT,only_where='filled')
    g.poly([(8,23),(13,24),(18,22),(21,20),(20,24),(17,26),(11,26)],SHADE)
    g.poly([(8,20),(10,21),(10,24),(8,24),(7,22)],PATINA)
    g.line(10,22,11,23,MINT)
    if iteration>=1:
        # Revision 1: broaden the whole sack, round the shoulder, remove foot-like toe.
        g.ellipse(14,19,8,7,BASE)
        g.ellipse(10,17,3,4,LIGHT,only_where='filled')
        g.poly([(7,22),(11,24),(16,24),(21,21),(20,24),(17,26),(11,26),(8,25)],SHADE)
        g.poly([(7,19),(9,20),(9,23),(8,23),(7,22)],PATINA)
        g.line(8,19,9,20,MINT)
        for x in range(6,9): g.set(x,26,None)
    if iteration>=2:
        # Revision 2: shorter horizontal collar, two-pixel clear gulf to upper tube.
        for y in range(12,21):
            for x in range(23,30):g.set(x,y,None)
        g.poly([(21,17),(24,15),(26,15),(26,18),(23,19),(21,20)],BASE)
        g.line(24,15,25,15,LIGHT)
        g.rect(25,16,26,17,OUT)
        g.line(24,18,25,18,MINT)
        # One quiet broad lower fold rather than sprinkled texture or amber tips.
        g.line(11,24,16,24,FOLD)
        g.line(11,14,14,13,LIGHT)
    # A SINGLE fictional eye on right cheek, not on siphons (white 2x2 + pupil).
    ex,ey=(19,18) if iteration>=2 else (20,20)
    g.rect(ex,ey,ex+1,ey+1,WHITE);g.set(ex+1,ey+1,OUT)
    g.outline(OUT)
    return g

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--iteration',type=int,default=2,choices=[0,1,2]);a=p.parse_args()
    im=build(a.iteration).to_image()
    out=Path(__file__).resolve().parents[1]/'preview'/'batch04-c';out.mkdir(parents=True,exist_ok=True)
    im.save(out/f'wake_tunicate_iter{a.iteration}.png')
    bg=Image.new('RGBA',(256,256),'#393447');bg.alpha_composite(im.resize((256,256),Image.Resampling.NEAREST));bg.save(out/f'wake_tunicate_iter{a.iteration}_x8.png')
    if a.iteration==2:save_sprite('wake_tunicate',im)
