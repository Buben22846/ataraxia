"""Иконка (512x512) и миниатюра (1920x1080) игры из нашего пиксель-арта. Запуск: python3 art/store/make_store_art.py"""
import os, random
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PNG = os.path.join(HERE, "..", "png")
OUT = HERE
def load(n): return Image.open(os.path.join(PNG, n + ".png")).convert("RGBA")
def paste(canvas, img, x, y, flip=False, scale=1):
    if flip: img = img.transpose(Image.FLIP_LEFT_RIGHT)
    if scale != 1: img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    canvas.alpha_composite(img, (x, y))

def pixel_text(canvas, text, cx, y, size, fill, shadow=(12, 40, 70, 255), outline=(9, 30, 52, 255)):
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer); d.fontmode = "1"   # без сглаживания: чёткие пиксели
    w = d.textlength(text, font=font)
    x = int(cx - w / 2)
    for dx, dy in [(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1),(0,2),(1,2),(-1,2)]:
        d.text((x + dx, y + dy), text, font=font, fill=outline if dy < 2 else shadow)
    d.text((x, y), text, font=font, fill=fill)
    canvas.alpha_composite(layer)

bg = load("bg_lagoon")            # 135x240

# ---------- Миниатюра: 240x135 канвас, x8 ----------
W, H = 240, 135
th = Image.new("RGBA", (W, H))
water = bg.crop((0, 40, 135, 150))                 # ровная вода и лучи
for i in range(2):                                  # вода: два зеркальных куска + растяжка по высоте
    part = water if i == 0 else water.transpose(Image.FLIP_LEFT_RIGHT)
    th.paste(part.resize((135, 88), Image.NEAREST), (i * 135 - 15, 0))
floor = bg.crop((0, 150, 135, 240))                 # кораллы и песок
for i in range(2):
    part = floor if i == 0 else floor.transpose(Image.FLIP_LEFT_RIGHT)
    th.alpha_composite(part, (i * 135 - 15, H - 90))
fish = [("octopus", 150, 52, 2, False), ("whale", 8, 26, 2, True), ("puffer", 108, 72, 1, False),
        ("clown", 70, 70, 1, False), ("guppy", 178, 26, 1, True), ("leviathan", 206, 84, 1, True),
        ("narwhal", 8, 66, 1, False)]
for n, x, y, s, f in fish:
    paste(th, load(n), x, y, f, s)
pixel_text(th, "ATARAXIA", 120, 7, 22, (255, 247, 214, 255))
pixel_text(th, "Calm Aquarium", 120, 34, 10, (160, 235, 240, 255))
th.convert("RGB").resize((W * 8, H * 8), Image.NEAREST).save(os.path.join(OUT, "thumbnail_1920x1080.png"))

# ---------- Иконка: 64x64 канвас, x8 ----------
S = 64
ic = Image.new("RGBA", (S, S))
ic.paste(bg.crop((28, 120, 92, 184)), (0, 0))
ic.alpha_composite(bg.crop((28, 176, 92, 240)).crop((0, 0, 64, 40)), (0, S - 40))
paste(ic, load("clown"), 14, 14, False, 1)
paste(ic, load("guppy"), 30, 36, True, 1)
paste(ic, load("puffer"), 2, 4, False, 1)
ic.convert("RGB").resize((512, 512), Image.NEAREST).save(os.path.join(OUT, "icon_512.png"))
print("ok")
