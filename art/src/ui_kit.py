"""UI-кит «Атараксии»: панели и кнопки в том же стиле, что и рыбы (контур #1d2b3a, плоские тона, без градиентов).
Все картинки рисуются как 9-slice: углы остаются, середина растягивается. Запуск: python3 art/src/ui_kit.py
Размеры и срезы (SliceCenter) нужны клиенту — они прописаны в src/ReplicatedStorage/Shared/UIKit.luau."""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PNG = os.path.join(HERE, "..", "png")
PREVIEW = os.path.join(HERE, "..", "preview")
OUT = "#1d2b3a"


def hx(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# срезанные углы: чем больше радиус, тем круглее
CUTS = {
    1: {(0, 0)},
    2: {(0, 0), (1, 0), (0, 1)},
    3: {(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (0, 2)},
}


def box(w, h, radius, fill, light, shade, raised=True, edge_rows=2):
    """Скруглённая плитка: контур, светлая кромка сверху-слева, тёмная снизу-справа."""
    cut = CUTS[radius]
    mask = set()
    for y in range(h):
        for x in range(w):
            cx = min(x, w - 1 - x)
            cy = min(y, h - 1 - y)
            if (cx, cy) not in cut:
                mask.add((x, y))
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    inner = set()
    for (x, y) in mask:
        edge = any((x + dx, y + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            img.putpixel((x, y), hx(OUT))
        else:
            inner.add((x, y))
    ys = [p[1] for p in inner]
    xs = [p[0] for p in inner]
    top, bottom, left, right = min(ys), max(ys), min(xs), max(xs)
    top_c, bot_c = (light, shade) if raised else (shade, light)
    for (x, y) in inner:
        color = fill
        if y == top or (x == left and y < bottom - edge_rows + 1):
            color = top_c if raised else shade
        if y > bottom - edge_rows and y <= bottom:
            color = bot_c if raised else fill
        if x == right and y > top and y <= bottom - edge_rows:
            color = bot_c if raised else fill
        if not raised and y in (top, top + 1):
            color = shade
        img.putpixel((x, y), hx(color))
    return img


def panel():
    img = box(24, 24, 3, "#0a4a5f", "#2a8aa0", "#073646", raised=True, edge_rows=1)
    # заклёпки в углах (внутри области среза 6 px, поэтому не растягиваются)
    for (rx, ry) in ((3, 3), (19, 3), (3, 19), (19, 19)):
        for dx in (0, 1):
            for dy in (0, 1):
                img.putpixel((rx + dx, ry + dy), hx("#7fd6e6"))
        img.putpixel((rx + 1, ry + 1), hx("#2a8aa0"))
    return img


def row():
    return box(12, 12, 1, "#083448", "#0b4259", "#062b3c", raised=False, edge_rows=1)


ASSETS = {
    "ui_panel": panel(),
    "ui_row": row(),
    "ui_btn": box(16, 16, 2, "#26a69a", "#7fe3d6", "#177a70"),
    "ui_btn_down": box(16, 16, 2, "#1f8f85", "#7fe3d6", "#147067", raised=False),
    "ui_btn_gold": box(16, 16, 2, "#ffca28", "#fff0a8", "#d99a00"),
    "ui_btn_gold_down": box(16, 16, 2, "#f0b81a", "#fff0a8", "#c98a00", raised=False),
    "ui_btn_dark": box(16, 16, 2, "#0f5c75", "#2f8fae", "#08384a"),
    "ui_btn_dark_down": box(16, 16, 2, "#0c4d63", "#2f8fae", "#06303f", raised=False),
    "ui_btn_off": box(16, 16, 2, "#5d7380", "#8fa4b0", "#3f525d"),
}


def main():
    os.makedirs(PNG, exist_ok=True)
    os.makedirs(PREVIEW, exist_ok=True)
    for name, img in ASSETS.items():
        img.save(os.path.join(PNG, name + ".png"))
    # лист для просмотра глазами: все элементы x10 на цвете воды
    scale, pad = 10, 12
    width = sum(i.width * scale + pad for i in ASSETS.values()) + pad
    height = max(i.height for i in ASSETS.values()) * scale + 2 * pad
    sheet = Image.new("RGBA", (width, height), hx("#146f8c"))
    x = pad
    for img in ASSETS.values():
        big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        sheet.alpha_composite(big, (x, pad))
        x += big.width + pad
    sheet.save(os.path.join(PREVIEW, "ui_kit_sheet.png"))
    print("готово:", ", ".join(ASSETS))


if __name__ == "__main__":
    main()
