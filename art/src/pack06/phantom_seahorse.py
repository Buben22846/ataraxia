"""Конёк-миротворец — original haunted/epic candidate, not integrated.
Editable Grid art. python art/src/phantom_seahorse.py [--iteration 0|1|2]
No external art or antialiasing; only this species and its scoped previews.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from pixel import Grid, save_sprite
OUT='#1d2b3a'; LIGHT='#e1d9e9'; BASE='#aaa0bb'; SHADE='#70677f'
VEIL='#b5d1bb'; PATINA='#729e91'; AMBER='#d8b27c'; FOLD='#9b7ea9'; WHITE='#ffffff'

def build(iteration=2):
    g=Grid()
    # Broad trailing veil: two soft leaf lobes, never a crown or dorsal spikes.
    g.poly([(17,7),(12,7),(7,4),(4,5),(6,9),(10,12),(5,13),(3,16),(6,19),(12,18),(17,14)],PATINA)
    g.poly([(6,6),(11,8),(15,8),(13,11),(9,10)],VEIL)
    g.poly([(5,15),(10,13),(14,13),(12,16),(7,17)],VEIL)
    g.poly([(10,10),(14,10),(15,13),(11,13)],FOLD)
    # Continuous upright S: rounded poll, inward neck, outward breast.
    g.poly([(20,3),(23,4),(24,7),(22,10),(19,11),(18,13),(21,15),(23,18),(22,22),(19,25),(15,26),(15,23),(18,21),(18,18),(15,15),(14,12),(15,9),(17,7),(17,5)],BASE)
    g.poly([(18,5),(20,4),(22,5),(21,8),(18,10),(16,12),(17,14),(16,14),(15,12),(16,9)],LIGHT)
    g.poly([(20,12),(19,13),(22,16),(22,20),(20,23),(17,25),(16,24),(19,21),(20,18),(18,15)],SHADE)
    # Tubular right-facing muzzle; deliberately blunt, not a dragon jaw.
    g.rect(22,7,28,9,BASE); g.rect(24,7,28,7,LIGHT)
    # Thick open C-shaped prehensile tail with a generous negative space.
    g.poly([(19,22),(19,26),(16,29),(9,29),(5,27),(4,24),(5,21),(8,20),(11,20),(12,22),(10,23),(8,22),(7,23),(7,25),(10,27),(15,27),(17,25),(16,23)],BASE)
    g.line(6,23,6,25,LIGHT);g.line(8,28,14,28,SHADE)
    g.line(10,21,11,21,LIGHT)
    g.rect(19,17,20,18,AMBER)
    if iteration>=1:
        # Refine cheek/neck distinction and keep muzzle visibly tubular.
        g.rect(18,10,19,10,LIGHT)
        g.rect(23,9,27,9,SHADE)
        g.rect(17,15,18,16,LIGHT)
        g.rect(20,19,21,20,FOLD)
    if iteration>=2:
        # Shorten the curled tip BEFORE outlining: leave a real 2px opening.
        for y in range(20,23):
            for x in range(3,14): g.set(x,y,None)
        for x in range(8,14): g.set(x,23,None)
        g.rect(5,23,7,23,LIGHT)
        # Broader upper veil, quieter fold, top-left tail highlight.
        g.rect(4,6,6,7,VEIL)
        g.rect(7,15,10,15,LIGHT)
        g.rect(8,27,11,27,LIGHT)
        g.rect(19,17,20,17,BASE)
    g.rect(21,5,22,6,WHITE);g.set(22,6,OUT)
    g.outline(OUT)
    return g

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--iteration',type=int,default=2,choices=[0,1,2]);a=p.parse_args()
    im=build(a.iteration).to_image()
    out=Path(__file__).resolve().parents[1]/'preview'/'batch03-c';out.mkdir(parents=True,exist_ok=True)
    im.save(out/f'phantom_seahorse_iter{a.iteration}.png')
    bg=__import__('PIL.Image',fromlist=['Image']).new('RGBA',(256,256),'#bcc6d0')
    bg.alpha_composite(im.resize((256,256),0));bg.save(out/f'phantom_seahorse_iter{a.iteration}_x8.png')
    if a.iteration==2: save_sprite('phantom_seahorse',im)
