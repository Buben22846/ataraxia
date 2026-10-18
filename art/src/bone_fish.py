"""Рыба-скелет (Призрачный пруд, эпическая). Тёмная полупрозрачная на вид рыба с белым скелетом внутри и светящимся глазом."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
OUT = "#1d2b3a"
WHITE = "#ffffff"
g = Grid()
BODY = "#4a6680"; LIGHT = "#6a8aa6"; BONE = "#f2ecd8"; BONE_D = "#c9bf9f"; GLOW = "#9cff6e"; FIN = "#36506a"
g.poly([(8, 16), (1, 9), (3, 16), (1, 23), (8, 17)], FIN)          # хвост
g.poly([(13, 10), (19, 4), (23, 10)], FIN)                         # спинной плавник
g.poly([(14, 21), (17, 26), (20, 21)], FIN)
g.ellipse(18, 16, 11, 6, BODY)
g.ellipse(17, 12, 7, 1, LIGHT, only_where="filled")
g.line(7, 16, 24, 16, BONE)                                        # позвоночник
for x in (10, 13, 16, 19):                                         # рёбра
    g.line(x, 12, x + 1, 15, BONE_D); g.line(x, 20, x + 1, 17, BONE_D)
g.line(4, 12, 7, 16, BONE_D); g.line(4, 20, 7, 16, BONE_D)         # кости хвоста
g.rect(24, 13, 27, 18, BONE)                                       # череп
g.rect(25, 14, 26, 15, GLOW)                                       # светящийся глаз
g.rect(27, 17, 28, 17, BONE_D)
g.outline(OUT); g.recenter()
if __name__ == "__main__":
    save_sprite("bone_fish", g.to_image()); print("ok")
