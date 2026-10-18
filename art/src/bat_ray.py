"""Скат-нетопырь (Призрачный пруд, редкий). Тёмно-фиолетовый скат с крыльями как у летучей мыши, ушки, длинный хвост."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite
OUT = "#1d2b3a"
WHITE = "#ffffff"
g = Grid()
BODY = "#5b3a8c"; LIGHT = "#8a64c4"; SHADE = "#3a2260"; WING = "#4a2d78"; BONE = "#2b1847"; EYE = "#ffcf3f"
# крылья с «пальцами» и зубчиками по нижнему краю
g.poly([(16, 14), (8, 6), (4, 12), (2, 20), (6, 18), (9, 21), (12, 19), (16, 20)], WING)
g.poly([(18, 14), (24, 6), (28, 12), (30, 20), (26, 18), (23, 21), (20, 19), (17, 20)], WING)
g.line(16, 15, 6, 8, BONE); g.line(16, 16, 4, 16, BONE)
g.line(18, 15, 26, 8, BONE); g.line(18, 16, 28, 16, BONE)
g.ellipse(17, 16, 5, 5, BODY)
g.ellipse(16, 13, 3, 1, LIGHT, only_where="filled")
g.ellipse(17, 20, 3, 1, SHADE, only_where="filled")
g.poly([(14, 11), (14, 7), (16, 11)], BODY); g.poly([(19, 11), (20, 7), (21, 11)], BODY)   # ушки
g.line(17, 21, 17, 29, SHADE); g.set(16, 29, SHADE)                # хвост
g.rect(15, 15, 15, 16, EYE); g.rect(19, 15, 19, 16, EYE)           # жёлтые глазки
g.outline(OUT); g.recenter()
if __name__ == "__main__":
    save_sprite("bat_ray", g.to_image()); print("ok")
