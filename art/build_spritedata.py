"""Собирает art/png/*.png в Luau-модуль SpriteData (пиксели хранятся прямо в игре).

Зачем: картинки можно превратить в EditableImage на клиенте — без загрузки в Roblox, без модерации и без asset id.
Формат: для каждой картинки палитра ("#rrggbb") и строки, сжатые по сериям: символ палитры + длина серии,
например "a3.5b2" = aaa.....bb  ('.' — прозрачный пиксель, длина 1 не пишется).

Запуск: python3 art/build_spritedata.py   (результат: src/ReplicatedStorage/Shared/SpriteData.luau)
"""
import os, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PNG = os.path.join(HERE, "png")
OUT = os.path.join(HERE, "..", "src", "ReplicatedStorage", "Shared", "SpriteData.luau")
SYMBOLS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

SPRITES = [
    "guppy", "clown", "puffer", "whale", "octopus",
    "ember_shrimp", "magma_crab", "fire_eel", "caldera_squid", "magma_dragon",
    "penguin", "seal", "polar_shark", "beluga", "narwhal",
    "lantern_fish", "jellyfish", "anglerfish", "abyss_ray", "leviathan",
    "pumpkin_fish", "ghost_guppy", "bat_ray", "bone_fish", "jack_angler",  # ивент Хэллоуин
]
BACKGROUNDS = ["bg_lagoon", "bg_volcano", "bg_arctic", "bg_abyss", "bg_haunted"]
UI = ["ui_banner", "ui_coin", "ui_ticket", "ui_ticket_down", "ui_panel", "ui_row", "ui_btn", "ui_btn_down", "ui_btn_gold", "ui_btn_gold_down", "ui_btn_dark", "ui_btn_dark_down", "ui_btn_off"]  # art/src/ui_kit.py


def encode(name):
    img = Image.open(os.path.join(PNG, name + ".png")).convert("RGBA")
    w, h = img.size
    palette = []
    rows = []
    for y in range(h):
        out, prev, count = [], None, 0
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            if a == 0:
                sym = "."
            else:
                if a != 255:
                    sys.exit(f"{name}: полупрозрачный пиксель ({x},{y}) a={a}: не поддерживается")
                col = "#%02x%02x%02x" % (r, g, b)
                if col not in palette:
                    palette.append(col)
                if len(palette) > len(SYMBOLS):
                    sys.exit(f"{name}: больше {len(SYMBOLS)} цветов")
                sym = SYMBOLS[palette.index(col)]
            if sym == prev:
                count += 1
            else:
                if prev is not None:
                    out.append(prev + (str(count) if count > 1 else ""))
                prev, count = sym, 1
        out.append(prev + (str(count) if count > 1 else ""))
        rows.append("".join(out))
    return w, h, palette, rows


def lua_entry(name):
    w, h, palette, rows = encode(name)
    pal = ", ".join('"%s"' % c for c in palette)
    body = ",\n".join('\t\t"%s"' % r for r in rows)
    return f'\t{name} = {{\n\t\tw = {w}, h = {h},\n\t\tpal = {{ {pal} }},\n\t\trows = {{\n{body},\n\t\t}},\n\t}},'


def main():
    names = [n for n in SPRITES + BACKGROUNDS + UI if os.path.exists(os.path.join(PNG, n + ".png"))]
    skipped = [n for n in SPRITES + BACKGROUNDS + UI if n not in names]
    parts = [
        "-- SpriteData: пиксель-арт игры (АВТОГЕНЕРАЦИЯ: art/build_spritedata.py, правьте картинки в art/src, а не этот файл).",
        "-- Формат строки: символ палитры + длина серии (\"a3.5b2\" = aaa.....bb), '.' — прозрачный пиксель.",
        "return {",
    ]
    parts += [lua_entry(n) for n in names]
    parts.append("}")
    text = "\n".join(parts) + "\n"
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"записано {len(names)} картинок, {len(text)} байт; пропущено (нет PNG): {skipped}")


if __name__ == "__main__":
    main()
