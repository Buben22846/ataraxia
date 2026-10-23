"""Шафрановый садовник / lagoon rare. Original fantasy, not an anatomy plate.
Editable Grid; --iteration 0,1,2 saves review passes; default 2 saves final.
R2 in docs/NEXT_WAVE_21_25.md: only stem habit, not free tail or band.
"""
from pathlib import Path
import sys, argparse
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import pixel
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#ffe8b3'; BASE='#e4b15f'; SHADE='#a77447'
BAND='#d0b37b'; WHITE='#ffffff'

def build(iteration=2):
    g=Grid()
    # One upright stalk, no terminal curl, tubular snout or trailing veil.
    left=10 if iteration==0 else 9
    g.rect(left,13,13,26,BASE)
    g.poly([(10,14),(11,10),(14,7),(18,5),(22,5),(24,6),(26,7),(26,10),(22,10),(19,9),(17,10),(15,13),(13,17)],BASE)
    g.poly([(10,24),(8,24),(6,26),(10,27),(13,27),(13,23)],BASE)
    g.line(left,15,left,23,LIGHT)
    g.poly([(11,12),(13,9),(17,6),(21,6),(23,7),(18,7),(15,9),(13,12)],LIGHT)
    g.line(13,17,13,26,SHADE)
    g.line(9,27,12,27,SHADE)
    g.line(21,10,25,10,SHADE)
    # Broad single transverse saffron band wraps the bend, not spots.
    g.poly([(12,11),(14,8),(17,10),(15,13)],SHADE)
    if iteration>=1:
        # Thicken knee interior and straighten the full lower stem.
        g.rect(10,12,14,16,BASE)
        g.rect(9,17,10,24,LIGHT)
        g.poly([(12,10),(14,8),(18,10),(16,12),(15,14),(13,13)],BAND)
        g.line(13,10,15,11,LIGHT)
    if iteration>=2:
        # Broad, quieter wrap, blunt cheek; shorten basal fold to a single nub.
        for y in range(24,28):
            for x in range(5,9): g.set(x,y,None)
        g.rect(6,25,10,26,BASE)
        g.rect(8,25,9,25,LIGHT)
        g.rect(10,26,12,27,BASE)
        g.set(13,27,None)
        g.rect(14,9,16,10,BAND)
        g.rect(24,8,26,9,BASE)
        g.line(22,10,25,10,SHADE)
    if iteration>=2:
        g.rect(24,8,25,9,WHITE);g.set(25,9,OUT)
    else:
        g.rect(23,7,24,8,WHITE);g.set(24,8,OUT)
    g.outline(OUT)
    g.recenter()
    return g.to_image()

def main():
    p=argparse.ArgumentParser();p.add_argument('--iteration',type=int,default=2,choices=[0,1,2]);a=p.parse_args()
    dest=Path(__file__).resolve().parents[1]/'preview/batch05-a';dest.mkdir(exist_ok=True)
    im=build(a.iteration);im.save(dest/f'saffron_garden_eel_iter{a.iteration}.png')
    bg=__import__('PIL.Image',fromlist=['Image']).new('RGBA',(256,256),'#bcc6d0');bg.alpha_composite(im.resize((256,256),0));bg.save(dest/f'saffron_garden_eel_iter{a.iteration}_x8.png')
    if a.iteration==2:
        pixel.OUT_PREVIEW=str(dest);save_sprite('saffron_garden_eel',im)
if __name__=='__main__':main()
