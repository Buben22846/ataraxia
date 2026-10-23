"""Эффекты для особых рыб: блёстки (белые — красятся в игре в золото/радугу) и монетка-награда.
Запуск: python3 art/src/fx.py  -> art/png/fx_star.png, fx_star_small.png, fx_coin.png"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PNG = os.path.join(HERE, "..", "png")
CLEAR = (0, 0, 0, 0)
W = (255, 255, 255, 255)   # ядро (красится целиком)
S = (205, 214, 232, 255)   # край луча (чуть темнее, тоже красится)
OL = (29, 43, 58, 255)     # контур как у рыб
GOLD = (255, 202, 40, 255)
LIGHT = (255, 243, 176, 255)
SHADE = (212, 154, 18, 255)


def draw(name, rows, key):
    h, w = len(rows), len(rows[0])
    img = Image.new("RGBA", (w, h), CLEAR)
    for y, row in enumerate(rows):
        assert len(row) == w, (name, y)
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), key[ch])
    img.save(os.path.join(PNG, name + ".png"))


# четырёхлучевая звезда 11x11
draw("fx_star", [
    ".....w.....",
    ".....w.....",
    ".....w.....",
    "....sws....",
    ".....w.....",
    "wwwswwwswww",
    ".....w.....",
    "....sws....",
    ".....w.....",
    ".....w.....",
    ".....w.....",
], {"w": W, "s": S})

# маленькая звёздочка 7x7
draw("fx_star_small", [
    "...w...",
    "...w...",
    "..sws..",
    "wwwwwww",
    "..sws..",
    "...w...",
    "...w...",
], {"w": W, "s": S})

# монетка 12x12: контур, золото, блик и тень
draw("fx_coin", [
    "...oooooo...",
    "..oLLLGGGo..",
    ".oLLGGGGGGo.",
    "oLLGGGGGGGGo",
    "oLGGGSSGGGGo",
    "oGGGGSGGGGGo",
    "oGGGGSGGGGGo",
    "oGGGGSSGGGgo",
    "oGGGGGGGGggo",
    ".oGGGGGGggo.",
    "..oggggggo..",
    "...oooooo...",
], {"o": OL, "L": LIGHT, "G": GOLD, "g": SHADE, "S": SHADE})
print("ok")
