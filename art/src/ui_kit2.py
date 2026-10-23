"""Цветные кнопки с узорами (интерфейс v2): у каждой кнопки свой цвет и свой узор.
Узор — отдельная маленькая плитка (pat_*), которую клиент замощает поверх кнопки. Запуск: python3 art/src/ui_kit2.py"""
import os
from PIL import Image
from ui_kit import box, hx, PNG

BUTTONS = {
    # имя: (заливка, светлая кромка, тёмная кромка, заливка нажатой, тёмная нажатой)
    "ui_btn_coral": ("#c63f26", "#f08a70", "#7d2412", "#a9341f", "#6a1e0f"),
    "ui_btn_blue": ("#1f64bd", "#6aa6f0", "#123f78", "#1a55a0", "#0e3262"),
    "ui_btn_pink": ("#b8326b", "#e8789f", "#741e44", "#9d2a5c", "#601839"),
}


def tile(w, h, color, pixels):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for (x, y) in pixels:
        img.putpixel((x % w, y % h), hx(color))
    return img


def main():
    os.makedirs(PNG, exist_ok=True)
    assets = {}
    for name, (fill, light, shade, fill_d, shade_d) in BUTTONS.items():
        assets[name] = box(16, 16, 2, fill, light, shade)
        assets[name + "_down"] = box(16, 16, 2, fill_d, light, shade_d, raised=False)
    # большая золотая кнопка паков: крупнее углы и толще нижний «борт»
    assets["ui_btn_gold_big"] = box(24, 24, 3, "#ffca28", "#fff6c2", "#c98a00", edge_rows=4)
    assets["ui_btn_gold_big_down"] = box(24, 24, 3, "#f0b81a", "#fff0a8", "#b87a00", raised=False, edge_rows=4)
    # узоры (светлее заливки, чтобы текст оставался читаемым)
    assets["pat_stripes"] = tile(8, 8, "#d9593d", [(i, i) for i in range(8)] + [(i + 1, i) for i in range(8)])  # диагональ, коралл
    assets["pat_lines"] = tile(4, 6, "#3a7fd0", [(x, 0) for x in range(4)])  # линейка, блокнот
    assets["pat_dots"] = tile(8, 8, "#cc5a8a", [(1, 1), (2, 1), (1, 2), (2, 2), (5, 5), (6, 5), (5, 6), (6, 6)])  # чешуя/пятна, розовая
    assets["pat_bubbles"] = tile(10, 10, "#4cc4b6", [(2, 1), (1, 2), (3, 2), (2, 3), (7, 6), (6, 7), (8, 7), (7, 8)])  # пузырьки, бирюзовая
    assets["pat_sparkle"] = tile(14, 14, "#fff0a8", [(3, 2), (3, 3), (3, 4), (2, 3), (4, 3), (10, 9), (10, 10), (10, 11), (9, 10), (11, 10)])  # искры, золотая
    # блик, пробегающий по главной кнопке (рисуется полупрозрачным через ImageTransparency)
    shine = Image.new("RGBA", (8, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(4):
            shine.putpixel(((x + (15 - y) // 4) % 8, y), hx("#ffffff"))
    assets["fx_shine"] = shine
    for name, img in assets.items():
        img.save(os.path.join(PNG, name + ".png"))
    print("записано", len(assets))


if __name__ == "__main__":
    main()
