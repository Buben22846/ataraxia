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


def ticket(down=False):
    """Цирковой билет 32x16: красный, с вырезами по бокам, пунктиром-отрывом и золотыми звёздами.
    Срез 9-slice: по горизонтали углы по 10 px (вырез, отрыв и звезда остаются целыми), по вертикали 5 px."""
    w, h = 32, 16
    fill, light, shade = ("#c8202f", "#ff5a5f", "#8f1523") if down else ("#e63946", "#ff7a7d", "#a81f2e")
    cream, gold, perf = "#fff1c1", "#ffca28", "#7a1420"
    mask = set()
    for y in range(h):
        for x in range(w):
            cx = min(x, w - 1 - x)
            cy = min(y, h - 1 - y)
            if (cx, cy) in CUTS[1]:
                continue
            # полукруглые вырезы посередине боковых сторон
            if cx * cx + (y - 7.5) ** 2 <= 9:
                continue
            mask.add((x, y))
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    inner = set()
    for (x, y) in mask:
        edge = any((x + dx, y + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            img.putpixel((x, y), hx(OUT))
        else:
            inner.add((x, y))
    for (x, y) in inner:
        color = fill
        if y == 1:
            color = light
        elif y >= h - 3:
            color = shade
        img.putpixel((x, y), hx(color))
    # кремовая рамка внутри (только по верху и низу, середина тянется)
    for x in range(4, w - 4):
        for y in (3, h - 4):
            if (x, y) in inner:
                img.putpixel((x, y), hx(cream))
    # пунктир-отрыв
    for px in (8, 23):
        for y in range(3, h - 3):
            if (y % 2 == 1) and (px, y) in inner:
                img.putpixel((px, y), hx(perf))
    # золотые звёзды-кресты на корешках
    for (sx, sy) in ((5, 8), (26, 8)):
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            img.putpixel((sx + dx, sy + dy), hx(gold))
        img.putpixel((sx, sy), hx(cream))
    return img


ASSETS = {
    "ui_ticket": ticket(),
    "ui_ticket_down": ticket(True),
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
