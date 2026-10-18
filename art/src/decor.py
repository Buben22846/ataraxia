"""Декор аквариумов «Атараксии»: растения, домики, сундуки, бочки и т.п. Свой оригинальный пиксель-арт.
Каждый предмет стоит на дне: низ картинки = точка опоры (в игре AnchorPoint (0.5, 1)).
Масштаб тот же, что у фонов (1 пиксель предмета = 1 пиксель фона 135x240), поэтому размеры в пикселях фона.
Запуск: python3 art/src/decor.py  -> art/png/decor_*.png, art/preview/decor_sheet_<аквариум>.png
"""
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite, OUT_PNG, OUT_PREVIEW
from PIL import Image

OUT = "#1d2b3a"
WHITE = "#ffffff"
ITEMS = {}  # id -> Grid


def item(name):
    def wrap(fn):
        ITEMS[name] = fn
        return fn
    return wrap


def shade_body(g, base, light, dark):
    """Свет сверху-слева, тень снизу-справа для всех пикселей цвета base."""
    snap = [row[:] for row in g.px]
    for y in range(g.h):
        for x in range(g.w):
            if snap[y][x] != base:
                continue
            up = snap[y - 1][x] if y > 0 else None
            left = snap[y][x - 1] if x > 0 else None
            down = snap[y + 1][x] if y + 1 < g.h else None
            right = snap[y][x + 1] if x + 1 < g.w else None
            if up != base or left is None:
                g.set(x, y, light)
            elif down != base or right is None:
                g.set(x, y, dark)


def blade(g, x0, y0, height, phase, width, color, amp=2.0):
    """Волнистая лента (водоросль) снизу вверх."""
    for i in range(height):
        y = y0 - i
        cx = x0 + amp * math.sin(i / 5.0 + phase) * (i / height)
        w = max(1, round(width * (1 - i / (height * 1.25))))
        for dx in range(-(w // 2), w - w // 2):
            g.set(round(cx) + dx, y, color)


# ===================== ЛАГУНА =====================
@item("decor_kelp")
def kelp():
    g = Grid(14, 46)
    blade(g, 6, 45, 44, 0.0, 5, "#2e9e5b", 2.5)
    blade(g, 10, 45, 34, 1.7, 4, "#4cc06e", 2.0)
    blade(g, 3, 45, 22, 3.1, 4, "#237a48", 1.5)
    # пузырьки-«поплавки» на листьях
    for (x, y) in ((6, 30), (8, 18), (10, 26)):
        if g.get(x, y):
            g.set(x, y, "#a8f0a0")
    g.outline(OUT)
    return g


@item("decor_coral")
def coral():
    g = Grid(26, 24)
    BASE, LIGHT, DARK, TIP = "#ff7aa2", "#ffb3c8", "#d94f7a", "#fff0b0"

    def branch(x, y, ang, length, w):
        for i in range(length):
            cx = x + math.cos(ang) * i
            cy = y - math.sin(ang) * i
            for dx in range(-(w // 2), w - w // 2):
                g.set(round(cx) + dx, round(cy), BASE)
        return x + math.cos(ang) * length, y - math.sin(ang) * length

    tips = []
    ex, ey = branch(13, 23, math.pi / 2, 8, 4)
    for a, l in ((2.3, 9), (1.6, 11), (0.85, 9)):
        tx, ty = branch(ex, ey, a, l, 3)
        tips.append((tx, ty))
        for a2 in (a + 0.5, a - 0.5):
            t2 = branch(tx, ty, a2, 4, 2)
            tips.append(t2)
    shade_body(g, BASE, LIGHT, DARK)
    for (x, y) in tips:
        g.set(round(x), round(y), TIP)
    g.outline(OUT)
    return g


@item("decor_anemone")
def anemone():
    g = Grid(22, 18)
    BASE, LIGHT, DARK, TENT, TIP = "#8e5cc4", "#b58ae0", "#5e3a8a", "#ff9ecb", "#ffe0f0"
    g.ellipse(11, 14, 7, 3, BASE)
    g.rect(5, 14, 17, 17, BASE)
    for i, x in enumerate(range(3, 20, 2)):
        h = 7 + (i * 5) % 4
        lean = (x - 11) / 6
        for k in range(h):
            g.set(round(x + lean * k / 2), 12 - k, TENT)
        g.set(round(x + lean * (h - 1) / 2), 12 - h + 1, TIP)
    shade_body(g, BASE, LIGHT, DARK)
    g.outline(OUT)
    return g


def chest_grid(open_):
    g = Grid(24, 22)
    WOOD, WL, WD, BAND, BANDL, GOLD, GOLDL = "#9a5b2e", "#c07a43", "#6b3a1c", "#d9a400", "#ffd54f", "#ffca28", "#fff3a0"
    # корпус
    g.rect(2, 12, 21, 21, WOOD)
    shade_body(g, WOOD, WL, WD)
    if open_:
        # монеты внутри и откинутая крышка
        g.ellipse(11, 12, 8, 2, GOLD)
        for (x, y) in ((6, 11), (10, 10), (14, 11), (17, 12)):
            g.set(x, y, GOLDL)
        g.poly([(2, 11), (21, 11), (23, 2), (4, 2)], WD)
        g.rect(5, 3, 21, 4, WOOD)
    else:
        g.ellipse(11.5, 12, 9.5, 4, WOOD)
        g.rect(2, 12, 21, 13, WOOD)
        for y in range(8, 13):
            for x in range(2, 22):
                if g.get(x, y) == WOOD and y < 10:
                    g.set(x, y, WL)
    # оковки
    for x in (5, 18):
        for y in range(4 if open_ else 8, 22):
            if g.get(x, y) is not None:
                g.set(x, y, BAND)
    g.rect(2, 13, 21, 13, BAND)
    # замок
    if not open_:
        g.rect(10, 12, 13, 15, BANDL)
        g.set(11, 14, OUT)
    g.outline(OUT)
    return g


@item("decor_chest")
def chest():
    return chest_grid(False)


@item("decor_chest_open")
def chest_open():
    return chest_grid(True)


def shell_grid(open_):
    g = Grid(18, 16)
    BASE, LIGHT, DARK, LINE, PEARL, PEARLL = "#f6c1a5", "#ffe3d3", "#d98f73", "#c76f55", "#f4f4ff", "#ffffff"
    g.ellipse(9, 13, 7, 2, BASE)  # нижняя створка
    if open_:
        g.ellipse(9, 6, 7, 4, BASE)  # верхняя откинута
        g.rect(4, 9, 14, 10, DARK)
        g.ellipse(9, 11, 2, 1.5, PEARL)
        g.set(8, 10, PEARLL)
    else:
        g.ellipse(9, 11, 7, 4, BASE)
    shade_body(g, BASE, LIGHT, DARK)
    # рёбрышки
    top = 7 if not open_ else 2
    for x in (5, 8, 11, 14):
        for y in range(top + 2, top + 7 if not open_ else top + 6):
            if g.get(x, y) in (BASE, DARK):
                g.set(x, y, LINE)
    g.outline(OUT)
    return g


@item("decor_shell")
def shell():
    return shell_grid(False)


@item("decor_shell_open")
def shell_open():
    return shell_grid(True)


@item("decor_starfish")
def starfish():
    g = Grid(14, 12)
    BASE, LIGHT, DARK, DOT = "#ff9f43", "#ffc58a", "#e0761a", "#fff1c1"
    pts = []
    for k in range(10):
        r = 6 if k % 2 == 0 else 2.5
        a = -math.pi / 2 + k * math.pi / 5
        pts.append((round(7 + r * math.cos(a)), round(6.5 + r * math.sin(a) * 0.85)))
    g.poly(pts, BASE)
    shade_body(g, BASE, LIGHT, DARK)
    for (x, y) in ((7, 4), (5, 6), (9, 6), (6, 8), (8, 8)):
        if g.get(x, y):
            g.set(x, y, DOT)
    g.outline(OUT)
    return g


@item("decor_shroomhouse")
def shroomhouse():
    g = Grid(26, 30)
    CAP, CAPL, CAPD, SPOT, STEM, STEML, STEMD, DOOR, WIN = "#e85d5d", "#ff9a8a", "#b83b45", "#fff3e0", "#f3e2c3", "#fff6e6", "#c9b08a", "#8a5a2e", "#ffe082"
    # шляпка
    g.ellipse(12.5, 11, 12.5, 7, CAP)
    for y in range(14, 19):
        for x in range(0, 26):
            g.set(x, y, None)
    shade_body(g, CAP, CAPL, CAPD)
    for (x, y, r) in ((7, 7, 1.5), (15, 5, 1.2), (19, 9, 1.5), (11, 10, 1)):
        g.ellipse(x, y, r, r, SPOT, only_where="filled")
    # ножка-дом (под шляпкой, тень от шляпки сверху)
    g.rect(6, 14, 19, 29, STEM)
    g.ellipse(12.5, 28, 7.5, 1.5, STEM)
    shade_body(g, STEM, STEML, STEMD)
    for x in range(6, 20):
        g.set(x, 14, STEMD)
    # дверь и окно
    g.rect(10, 21, 14, 28, DOOR)
    g.ellipse(12, 21, 2, 1.5, DOOR)
    g.set(13, 25, WIN)
    g.rect(16, 17, 18, 19, WIN)
    g.outline(OUT)
    return g


# ===================== ВУЛКАН =====================
@item("decor_vent")
def vent():
    g = Grid(20, 30)
    ROCK, RL, RD, LAVA, GLOW, HOT = "#5a4a50", "#857179", "#3a2f34", "#ff6a2a", "#ffa23c", "#ffe08a"
    g.poly([(2, 29), (5, 14), (7, 8), (12, 8), (14, 14), (17, 29)], ROCK)
    g.poly([(12, 29), (14, 20), (16, 18), (19, 29)], ROCK)
    shade_body(g, ROCK, RL, RD)
    g.rect(8, 7, 11, 8, LAVA)
    g.set(9, 7, HOT)
    g.set(10, 7, GLOW)
    # светящиеся трещины
    for (x, y) in ((8, 13), (9, 14), (9, 15), (10, 16), (11, 20), (10, 21), (6, 24), (7, 25)):
        g.set(x, y, LAVA)
    g.set(9, 15, GLOW)
    g.outline(OUT)
    return g


@item("decor_firecoral")
def firecoral():
    g = Grid(20, 26)
    BASE, LIGHT, DARK, TIP = "#e8502a", "#ff8a4c", "#a8321c", "#ffd84a"
    tips = []
    for x0, h, ph in ((6, 22, 0.0), (10, 25, 1.4), (14, 18, 2.6), (3, 13, 4.0), (17, 12, 5.1)):
        for i in range(h):
            cx = x0 + 1.5 * math.sin(i / 3.5 + ph)
            w = 3 if i < h * 0.6 else 2
            for dx in range(-(w // 2), w - w // 2):
                g.set(round(cx) + dx, 25 - i, BASE)
        tips.append((round(x0 + 1.5 * math.sin((h - 1) / 3.5 + ph)), 25 - h + 1))
    shade_body(g, BASE, LIGHT, DARK)
    for (x, y) in tips:
        g.set(x, y, TIP)
    g.outline(OUT)
    return g


@item("decor_amphora")
def amphora():
    g = Grid(16, 22)
    CLAY, CL, CD, PAT, CRACK = "#c8693a", "#e89a6a", "#8a4424", "#2b1a14", "#5a2a18"
    g.ellipse(8, 13, 6, 6, CLAY)
    g.rect(6, 3, 10, 8, CLAY)
    g.rect(5, 2, 11, 3, CLAY)
    g.rect(6, 19, 10, 21, CLAY)
    # ручки
    g.line(4, 5, 3, 9, CLAY)
    g.line(12, 5, 13, 9, CLAY)
    shade_body(g, CLAY, CL, CD)
    for x in range(3, 14):
        if g.get(x, 12) in (CLAY, CL, CD):
            g.set(x, 12, PAT if x % 2 else CD)
    # трещина и скол
    for (x, y) in ((9, 14), (10, 15), (10, 16), (11, 17)):
        g.set(x, y, CRACK)
    g.set(11, 2, None)
    g.outline(OUT)
    return g


@item("decor_obsidian")
def obsidian():
    g = Grid(26, 16)
    B, BL, BD, GLINT, LAVA = "#4a3d5c", "#7a6a94", "#2a2236", "#c8bcff", "#ff7a1f"
    for pts in (
        [(1, 15), (4, 6), (8, 2), (10, 9), (11, 15)],
        [(9, 15), (13, 4), (16, 8), (18, 15)],
        [(16, 15), (19, 7), (22, 5), (25, 15)],
    ):
        g.poly(pts, B)
    shade_body(g, B, BL, BD)
    for (x, y) in ((7, 4), (14, 6), (21, 7)):
        g.set(x, y, GLINT)
    for x in range(3, 23, 4):
        g.set(x, 15, LAVA)
    g.outline(OUT)
    return g


# ===================== ЛЁД =====================
@item("decor_igloo")
def igloo():
    g = Grid(30, 18)
    SNOW, SL, SD, LINE, DOOR, DOORD = "#e8f4fb", "#ffffff", "#a8cde0", "#bcd9e8", "#2b4a66", "#1a3044"
    g.ellipse(14, 17, 13, 13, SNOW)
    for y in range(17, 18):
        for x in range(30):
            pass
    shade_body(g, SNOW, SL, SD)
    # кирпичики
    for y in (8, 12, 15):
        for x in range(1, 29):
            if g.get(x, y) == SNOW:
                g.set(x, y, LINE)
    for y0, y1, off in ((9, 11, 0), (13, 14, 3)):
        for x in range(2 + off, 28, 6):
            for y in range(y0, y1 + 1):
                if g.get(x, y) == SNOW:
                    g.set(x, y, LINE)
    # вход-тоннель
    g.ellipse(23, 17, 5, 5, SNOW)
    shade_body(g, SNOW, SL, SD)
    g.ellipse(24, 17, 2.5, 3, DOOR)
    g.ellipse(24.5, 17, 1, 2, DOORD)
    # обрезаем низ по линии дна
    for x in range(30):
        g.set(x, 17, g.get(x, 17))
    g.outline(OUT)
    return g


@item("decor_icecrystal")
def icecrystal():
    g = Grid(16, 26)
    ICE, IL, ID, SHINE = "#7fd3f0", "#c8f2ff", "#3f9dc8", "#ffffff"
    for (x, w, h, lean) in ((7, 4, 24, 0), (3, 3, 14, -2), (12, 3, 17, 2)):
        top = 25 - h
        g.poly([(x - w // 2, 25), (x + lean - w // 2, top + 3), (x + lean, top), (x + lean + w // 2, top + 3), (x + w // 2 + 1, 25)], ICE)
    shade_body(g, ICE, IL, ID)
    for (x, y) in ((7, 4), (6, 9), (3, 15), (13, 12)):
        if g.get(x, y):
            g.set(x, y, SHINE)
    g.outline(OUT)
    return g


@item("decor_seagrass")
def seagrass():
    g = Grid(14, 32)
    for x0, h, ph, c in ((3, 26, 0.3, "#5fb7a4"), (6, 31, 1.6, "#7fd1bd"), (9, 22, 2.9, "#4a9c8a"), (11, 15, 4.2, "#7fd1bd")):
        blade(g, x0, 31, h, ph, 2, c, 1.6)
    g.outline(OUT)
    return g


@item("decor_anchor")
def anchor():
    g = Grid(20, 24)
    IRON, IL, ID, RUST, SNOW = "#6e7f8c", "#9fb0bc", "#46535d", "#b5652e", "#ffffff"
    g.rect(9, 4, 10, 20, IRON)          # стержень
    g.rect(5, 6, 14, 7, IRON)           # шток
    g.ellipse(9.5, 2.5, 2.5, 2.5, IRON)
    g.ellipse(9.5, 2.5, 1, 1, None)
    for i in range(7):                  # лапы-дуга
        g.set(9 - i, 21 - round(i * 0.6), IRON)
        g.set(10 + i, 21 - round(i * 0.6), IRON)
        g.set(9 - i, 22 - round(i * 0.6), IRON)
        g.set(10 + i, 22 - round(i * 0.6), IRON)
    g.poly([(1, 17), (3, 13), (5, 18)], IRON)
    g.poly([(18, 17), (16, 13), (14, 18)], IRON)
    shade_body(g, IRON, IL, ID)
    for (x, y) in ((9, 12), (10, 15), (4, 18), (15, 18), (6, 6)):
        g.set(x, y, RUST)
    for x in range(5, 15):
        g.set(x, 5, SNOW)
    g.set(8, 0, SNOW); g.set(9, 0, SNOW); g.set(10, 0, SNOW)
    g.outline(OUT)
    return g


# ===================== БЕЗДНА =====================
@item("decor_glowshroom")
def glowshroom():
    g = Grid(20, 20)
    STEM, STEMD, CAP1, CAP1L, CAP2, CAP2L, DOT = "#3a3f6b", "#262a4a", "#3fe0d0", "#a8fff4", "#ff5ab4", "#ffb3dc", "#ffffff"
    for (x, h, r, c, cl) in ((6, 12, 5, CAP1, CAP1L), (14, 8, 4, CAP2, CAP2L), (11, 5, 2.5, CAP1, CAP1L)):
        g.rect(x - 1, 19 - h, x, 19, STEM)
        g.set(x, 19 - h + 2, STEMD)
        g.ellipse(x, 19 - h, r, r * 0.6, c)
        for xx in range(x - int(r), x + int(r) + 1):
            if g.get(xx, 19 - h - 1) == c:
                g.set(xx, 19 - h - 1, cl)
        g.set(x - 1, 19 - h - 1, DOT)
    g.outline(OUT)
    return g


@item("decor_arch")
def arch():
    g = Grid(32, 30)
    ST, SL, SD, MOSS, RUNE = "#4a5070", "#6c7396", "#2c3048", "#3f8f7a", "#7cf8ff"
    g.rect(2, 8, 8, 29, ST)
    g.rect(23, 12, 29, 29, ST)
    for x in range(2, 30):
        y = 8 + round(((x - 16) / 13.0) ** 2 * 5)
        for yy in range(y - 5, y + 1):
            g.set(x, yy, ST)
    # пролом справа сверху
    for (x, y) in ((27, 9), (28, 9), (29, 9), (28, 10), (29, 10), (29, 11), (26, 8), (27, 8), (28, 8), (29, 8)):
        g.set(x, y, None)
    # проём
    for x in range(9, 23):
        top = 11 + round(((x - 16) / 7.0) ** 2 * 4)
        for y in range(top, 30):
            g.set(x, y, None)
    shade_body(g, ST, SL, SD)
    # кладка и мох
    for y in (14, 20, 26):
        for x in list(range(2, 9)) + list(range(23, 30)):
            if g.get(x, y) == ST:
                g.set(x, y, SD)
    for (x, y) in ((3, 9), (4, 9), (5, 8), (12, 4), (13, 4), (20, 5), (24, 13), (25, 13)):
        if g.get(x, y):
            g.set(x, y, MOSS)
    # светящиеся руны
    for (x, y) in ((5, 17), (5, 18), (4, 18), (26, 22), (26, 23), (27, 23), (16, 5), (15, 6), (17, 6)):
        g.set(x, y, RUNE)
    g.outline(OUT)
    return g


@item("decor_tubeworm")
def tubeworm():
    g = Grid(14, 24)
    TUBE, TL, TD, PLUME, PL = "#e6e1d6", "#ffffff", "#a39d90", "#e83a5c", "#ff8aa0"
    for (x, h) in ((3, 14), (7, 20), (11, 11)):
        g.rect(x - 1, 23 - h, x + 1, 23, TUBE)
    shade_body(g, TUBE, TL, TD)
    for (x, h) in ((3, 14), (7, 20), (11, 11)):
        top = 23 - h
        for dx, dy in ((-2, -1), (-1, -2), (0, -3), (1, -2), (2, -1), (-1, -1), (0, -1), (1, -1), (0, -2)):
            g.set(x + dx, top + dy, PLUME)
        g.set(x, top - 3, PL)
        g.set(x - 1, top - 2, PL)
    g.outline(OUT)
    return g


@item("decor_wreck")
def wreck():
    g = Grid(34, 20)
    W, WL, WD, BRASS, GLASS, GLOW = "#5b4a3c", "#7d6754", "#3a2e25", "#c9a227", "#5ce1e6", "#d8ffff"
    g.poly([(0, 19), (2, 9), (8, 4), (20, 3), (30, 5), (33, 12), (31, 19)], W)
    # пролом
    g.poly([(22, 19), (25, 11), (28, 13), (27, 19)], None)
    for (x, y) in ((24, 12), (26, 11), (27, 12)):
        g.set(x, y, None)
    shade_body(g, W, WL, WD)
    for y in (8, 12, 16):
        for x in range(1, 33):
            if g.get(x, y) == W:
                g.set(x, y, WD)
    # иллюминатор
    g.ellipse(12, 11, 3.5, 3.5, BRASS)
    g.ellipse(12, 11, 2, 2, GLASS)
    g.set(11, 10, GLOW)
    g.outline(OUT)
    return g


# ===================== ПРИЗРАЧНЫЙ ПРУД =====================
@item("decor_tombstone")
def tombstone():
    g = Grid(14, 18)
    ST, SL, SD, MOSS, CRACK = "#8a8fa3", "#b3b8c9", "#5c6073", "#5a8a4a", "#3d4050"
    g.rect(2, 6, 11, 17, ST)
    g.ellipse(6.5, 6, 4.5, 4.5, ST)
    shade_body(g, ST, SL, SD)
    # крестик-надпись
    g.rect(6, 5, 7, 11, SD)
    g.rect(4, 7, 9, 8, SD)
    for (x, y) in ((10, 9), (9, 10), (10, 11)):
        g.set(x, y, CRACK)
    for x in range(2, 12):
        g.set(x, 17, MOSS)
    g.set(3, 16, MOSS); g.set(10, 16, MOSS)
    g.outline(OUT)
    return g


@item("decor_deadtree")
def deadtree():
    g = Grid(26, 36)
    B, BL, BD = "#5a4a5e", "#7d6a82", "#3a2f3e"

    def limb(x, y, ang, length, w):
        for i in range(length):
            cx, cy = x + math.cos(ang) * i, y - math.sin(ang) * i
            for dx in range(-(w // 2), w - w // 2):
                g.set(round(cx) + dx, round(cy), B)
        return x + math.cos(ang) * length, y - math.sin(ang) * length

    x, y = limb(13, 35, math.pi / 2 + 0.05, 16, 4)
    a, b = limb(x, y, 2.4, 9, 2)
    limb(a, b, 1.9, 5, 1)
    limb(a, b, 2.9, 4, 1)
    c, d = limb(x, y, 0.8, 10, 2)
    limb(c, d, 1.4, 5, 1)
    limb(c, d, 0.2, 4, 1)
    limb(x, y, 1.6, 9, 2)
    limb(13, 28, 0.3, 5, 1)
    # корни
    for dx in (-4, -3, 3, 4, 5):
        g.set(13 + dx, 35, B)
    shade_body(g, B, BL, BD)
    g.outline(OUT)
    return g


@item("decor_barrel")
def barrel():
    g = Grid(16, 18)
    W, WL, WD, HOOP, HOOPL, SLIME = "#9a6a3a", "#c08a52", "#6a4424", "#4a4a55", "#8a8a99", "#7fdc6a"
    g.ellipse(7.5, 9, 6.5, 8.5, W)
    g.rect(2, 1, 13, 17, W)
    for x in range(16):
        for y in (0,):
            pass
    shade_body(g, W, WL, WD)
    for x in range(1, 15):
        for y in (4, 13):
            if g.get(x, y):
                g.set(x, y, HOOP)
        if g.get(x, 4) == HOOP and x < 6:
            g.set(x, 4, HOOPL)
    for y in range(2, 17):
        for x in (5, 10):
            if g.get(x, y) in (W, WL):
                g.set(x, y, WD)
    # капля слизи
    g.set(11, 1, SLIME); g.set(11, 2, SLIME); g.set(11, 3, SLIME)
    g.outline(OUT)
    return g


@item("decor_lantern")
def lantern():
    g = Grid(16, 14)
    P, PL, PD, STEM, FACE, GLOW = "#ff8c1a", "#ffb35c", "#c75f00", "#4a7a2a", "#ffe066", "#fff7c2"
    g.ellipse(7.5, 8, 7, 5, P)
    shade_body(g, P, PL, PD)
    for x in (4, 7, 11):
        for y in range(4, 13):
            if g.get(x, y) in (P, PL):
                g.set(x, y, PD)
    g.rect(7, 1, 8, 3, STEM)
    # лицо
    for (x, y) in ((4, 7), (5, 6), (6, 7), (9, 7), (10, 6), (11, 7)):
        g.set(x, y, FACE)
    for x in range(4, 12):
        g.set(x, 10, FACE)
    g.set(5, 11, FACE); g.set(9, 11, FACE)
    g.set(5, 6, GLOW); g.set(10, 6, GLOW)
    g.outline(OUT)
    return g


SHEETS = {
    "lagoon": (["decor_kelp", "decor_coral", "decor_anemone", "decor_shroomhouse", "decor_chest", "decor_chest_open", "decor_shell", "decor_shell_open", "decor_starfish"], (20, 110, 140)),
    "volcano": (["decor_vent", "decor_firecoral", "decor_amphora", "decor_obsidian"], (58, 35, 42)),
    "arctic": (["decor_igloo", "decor_icecrystal", "decor_seagrass", "decor_anchor"], (64, 120, 165)),
    "abyss": (["decor_glowshroom", "decor_arch", "decor_tubeworm", "decor_wreck"], (12, 22, 52)),
    "haunted": (["decor_tombstone", "decor_deadtree", "decor_barrel", "decor_lantern"], (40, 30, 60)),
}


def sheet(names, color, filename, scale=6, pad=4):
    imgs = [Image.open(os.path.join(OUT_PNG, n + ".png")).convert("RGBA") for n in names]
    width = sum(i.width + pad for i in imgs) + pad
    height = max(i.height for i in imgs) + 2 * pad
    canvas = Image.new("RGBA", (width, height), color + (255,))
    x = pad
    for im in imgs:
        canvas.alpha_composite(im, (x, height - pad - im.height))
        x += im.width + pad
    canvas = canvas.resize((width * scale, height * scale), Image.NEAREST)
    canvas.save(os.path.join(OUT_PREVIEW, filename))


if __name__ == "__main__":
    for name, fn in ITEMS.items():
        g = fn()
        save_sprite(name, g.to_image())
    for tank, (names, color) in SHEETS.items():
        sheet(names, color, f"decor_sheet_{tank}.png")
    print("готово:", len(ITEMS), "предметов")
