"""Фугу (лагуна, редкая). Смотрит вправо."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"; BODY = "#f2c14e"; LIGHT = "#ffe39a"; SHADE = "#d99a2b"
BELLY = "#fff3d6"; SPIKE = "#b8741a"; FIN = "#f08a4b"; WHITE = "#ffffff"; BLUSH = "#ff8f8f"

g = Grid()
# хвост
g.poly([(7, 15), (3, 12), (4, 16), (3, 20), (7, 17)], FIN)
# иголки: треугольники по кругу (рисуем до тела, основание скрыто телом)
import math
for ang in range(-90, 270, 36):
    if 150 < ang % 360 < 210:   # у хвоста иголок нет
        continue
    t = math.radians(ang)
    cx, cy, rx, ry = 16, 16, 10.5, 9.5
    bx, by = cx + rx * math.cos(t), cy + ry * math.sin(t)
    tx, ty = cx + (rx + 3.2) * math.cos(t), cy + (ry + 3.2) * math.sin(t)
    px, py = -math.sin(t) * 1.6, math.cos(t) * 1.6
    g.poly([(round(bx - px), round(by - py)), (round(tx), round(ty)), (round(bx + px), round(by + py)),
            (round(cx + (rx - 3) * math.cos(t)), round(cy + (ry - 3) * math.sin(t)))], SPIKE)
# тело
g.ellipse(16, 16, 10, 9, BODY)
g.ellipse(14, 10, 7, 2, LIGHT, only_where="filled")
g.ellipse(16, 24, 8, 1, SHADE, only_where="filled")
g.ellipse(18, 21, 7, 2, BELLY, only_where="filled")
g.ellipse(18, 23, 5, 1, SHADE, only_where="filled")
# боковой плавник
g.poly([(15, 17), (12, 16), (12, 20), (15, 20)], FIN)
# глаз крупный 3x3 и щёчка, ротик
g.rect(21, 12, 23, 14, WHITE)
g.rect(22, 13, 23, 14, OUT)
g.set(22, 13, WHITE)
g.set(20, 17, BLUSH); g.set(21, 17, BLUSH)
g.set(26, 18, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("puffer", g.to_image())
    print("ok")
