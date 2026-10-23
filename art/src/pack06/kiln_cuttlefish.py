"""Печная каракатица / volcano rare. Original Grid fantasy.
R5 in docs/NEXT_WAVE_21_25.md supports fin/mantle distinction, not lava life.
Two arm masses are a game simplification. --iteration 0|1|2 (final default).
"""
from pathlib import Path
import sys,argparse
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import pixel
from pixel import Grid,save_sprite
OUT='#1d2b3a'; LIGHT='#d4b59b'; BASE='#9b7667'; SHADE='#604d53'
TERRA='#c66543'; AMBER='#e9a75f'; DEEP='#8c4143'; WHITE='#ffffff'

def build(iteration=2):
    g=Grid()
    # Continuous soft ribbon, two broad humps, no radial rays.
    g.poly([(5,13),(7,10),(10,9),(13,10),(16,9),(19,10),(21,12),(22,17),(21,21),(18,23),(15,22),(12,23),(8,22),(5,19)],TERRA)
    g.ellipse(13,16,8,5,BASE)
    g.ellipse(12,14,6,3,LIGHT,only_where='filled')
    g.poly([(6,17),(10,18),(17,18),(20,16),(21,19),(18,21),(10,21),(7,19)],SHADE)
    # Short head distinctly in front of mantle, and only two chunky masses.
    g.rect(21,14,24,19,BASE)
    g.rect(22,14,24,15,LIGHT)
    g.rect(24,12,27,14,BASE)
    g.rect(24,19,26,21,BASE)
    g.rect(25,21,27,22,BASE)
    if iteration>=1:
        # Expose a continuous ribbon instead of a triangular cap.
        g.rect(8,10,10,10,AMBER)
        g.rect(15,10,17,10,AMBER)
        g.line(7,20,10,21,TERRA)
        g.line(11,22,13,22,DEEP)
        g.line(17,22,19,21,DEEP)
        # Join upper arm to head with a thick shoulder, not a hairline.
        g.rect(23,13,25,15,BASE)
        g.rect(25,12,27,12,LIGHT)
    if iteration>=2:
        # Round left mantle; two large lobes, quiet single amber inner stripe.
        g.rect(9,9,11,9,TERRA)
        g.rect(15,9,17,9,TERRA)
        g.rect(5,14,6,18,TERRA)
        g.rect(6,12,7,13,TERRA)
        g.rect(8,11,11,11,TERRA)
        g.line(9,12,17,12,AMBER)
        g.line(8,13,8,15,LIGHT)
        g.rect(12,13,17,14,BASE)
        g.rect(24,19,26,20,SHADE)
        g.rect(25,21,27,23,BASE)
        g.line(26,23,27,23,SHADE)
    g.rect(22,16,23,17,WHITE);g.set(23,17,OUT)
    g.outline(OUT);g.recenter();return g.to_image()

def main():
    p=argparse.ArgumentParser();p.add_argument('--iteration',type=int,default=2,choices=[0,1,2]);a=p.parse_args()
    dest=Path(__file__).resolve().parents[1]/'preview/batch05-a';dest.mkdir(exist_ok=True)
    im=build(a.iteration);im.save(dest/f'kiln_cuttlefish_iter{a.iteration}.png')
    bg=__import__('PIL.Image',fromlist=['Image']).new('RGBA',(256,256),'#bcc6d0');bg.alpha_composite(im.resize((256,256),0));bg.save(dest/f'kiln_cuttlefish_iter{a.iteration}_x8.png')
    if a.iteration==2:
        pixel.OUT_PREVIEW=str(dest);save_sprite('kiln_cuttlefish',im)
if __name__=='__main__':main()
