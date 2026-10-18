"""Призрачная гуппи (Призрачный пруд, обычная). Бледно-мятное «привидение» с волнистым хвостом-простынкой."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
OUT = "#1d2b3a"
WHITE = "#ffffff"
g = Grid()
BODY = "#e4f7ef"; LIGHT = "#ffffff"; SHADE = "#a8d8c8"; TAIL = "#c6eadf"; GLOW = "#7ff0c8"; EYE = "#2a3550"
# волнистый хвост-простынка
g.poly([(10, 11), (2, 13), (5, 16), (1, 19), (5, 21), (2, 24), (10, 21)], TAIL)
g.ellipse(18, 16, 9, 6, BODY)
g.ellipse(17, 12, 6, 2, LIGHT, only_where="filled")
g.ellipse(18, 20, 7, 1, SHADE, only_where="filled")
g.poly([(14, 10), (18, 6), (21, 10)], TAIL)                       # спинной плавник
g.set(13, 17, GLOW); g.set(16, 18, GLOW); g.rect(11, 15, 12, 16, GLOW)  # светящиеся пятнышки
g.rect(21, 13, 23, 16, EYE); g.set(21, 13, WHITE)                # большой тёмный глаз-«дырка»
g.rect(25, 18, 26, 18, EYE)                                       # ротик «о»
g.outline(OUT); g.recenter()
if __name__ == "__main__":
    save_sprite("ghost_guppy", g.to_image()); print("ok")
