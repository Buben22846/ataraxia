"""Фон «Бездна» 135x240. Тёмно-синяя вода, едва видимые лучи, ровный центр, дно с курильщиками,
приглушённая биолюминесценция, силуэт гигантского существа вдали."""
import math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bgkit import *

rng = random.Random(42)
WATER = ["#213F6E", "#1A3262", "#142853", "#0F1E42", "#0B1635", "#080F27"]
FAR = "#150F33"                                     # дальние холмы (чуть фиолетовее воды)
ROCK = ["#2D2A57", "#1C1A3A", "#110F28", "#08071A"]  # скалы: свет, середина, тень, глубокая тень
SMOKE = "#252B52"
VENT = ["#6E2A28", "#BD5A2C", "#F29A48"]            # тёплое свечение курильщиков
TEAL, TEAL_D = "#34C0AE", "#176A63"
PINK, PINK_D = "#D0569A", "#6E2C5E"
LIME, LIME_D = "#A4CE3E", "#566F25"
PALE = "#86AFD8"
TEAL_H, PINK_H, LIME_H = "#0E3446", "#341A48", "#2A3A24"   # мягкие ореолы


def smooth(a, b, x):
    u = np.clip((x - a) / (b - a), 0, 1)
    return u * u * (3 - 2 * u)


def glow(cx, cy, r, amp):
    return amp * np.exp(-((XX - cx) ** 2 + (YY - cy) ** 2) / (2.0 * r * r))


# ---------- вода: плато в зоне рыб ----------
yf = YY / (H - 1.0)
t = 0.6 + 1.4 * smooth(0.0, 0.34, yf)            # поверхность светлее -> плато индекс 2.0
t += 2.3 * smooth(0.66, 1.0, yf)                 # вниз темнее
t += 1.0 * smooth(0.78, 1.0, edge(XX))           # виньетка только у самых краёв
# едва заметные лучи
for x0, slope, hw in [(24, 0.20, 3.0), (60, 0.12, 4.5), (98, 0.05, 3.2)]:
    cxr = x0 + slope * YY
    half = hw + YY * 0.05
    soft = np.clip(1 - np.abs(XX - cxr) / half, 0, 1) ** 0.7
    t -= 0.75 * soft * np.clip(1 - YY / (0.28 * H), 0, 1) ** 1.3
t = np.clip(t, 0, 5)
c = Canvas(quantize(t, WATER, 0.3))

# ---------- гигантское существо вдали (на 1 тон ярче) ----------
cm = Image.new("L", (W, H), 0)
cd = ImageDraw.Draw(cm)
body = [(108, 160), (104, 152), (95, 147), (82, 146), (66, 148), (52, 152), (40, 156), (30, 154),
        (24, 146), (14, 136), (6, 130), (10, 140), (16, 150), (12, 160), (6, 168), (16, 164), (26, 164),
        (36, 170), (52, 175), (70, 177), (88, 176), (100, 172), (106, 168)]
cd.polygon(body, fill=255)
cd.polygon([(78, 174), (70, 192), (62, 200), (84, 184), (92, 175)], fill=255)   # грудной плавник
cd.polygon([(62, 148), (56, 138), (52, 136), (54, 150)], fill=255)               # спинной гребень
cmask = np.array(cm) > 0
px = c.arr()
lit = quantize(np.clip(t - 1.0, 0, 5), WATER, 0.3)
px[cmask] = lit[cmask]
c.img.paste(Image.fromarray(px, "RGB"))
for x, y in [(96, 160), (84, 163), (66, 164), (48, 162)]:       # едва заметные светящиеся точки
    c.pt(x, y, TEAL_D)

# ---------- дальние холмы ----------
def prof(base, amp, ed, seed):
    r = random.Random(seed)
    ph = [r.uniform(0, 6) for _ in range(3)]
    return [base - amp * (0.5 + 0.5 * math.sin(x / 11 + ph[0])) - 4 * math.sin(x / 5.0 + ph[1]) ** 2
            - ed * edge(x) ** 2.8 for x in range(W)]

ys = prof(200, 9, 78, 3)
c.poly([(0, H)] + [(x, ys[x]) for x in range(W)] + [(W - 1, H)], FAR)
# дымка на дали

# ---------- боковые стены ----------
def wall(side, seed):
    r = random.Random(seed)
    ph = [r.uniform(0, 6) for _ in range(3)]
    for y in range(40, H):
        thick = 1.0 + 14.0 * (max(0.0, (y - 40) / 170.0)) ** 1.1
        thick += 2.6 * math.sin(y / 9.0 + ph[0]) + 1.6 * math.sin(y / 3.7 + ph[1])
        thick *= 0.55 + 0.45 * smooth(40, 90, y)
        n = int(round(thick))
        for k in range(n):
            x = k if side == 0 else W - 1 - k
            d = n - 1 - k  # расстояние от внутренней кромки
            if d == 0:
                col = ROCK[1]
            elif d < 3:
                col = ROCK[2]
            else:
                col = ROCK[3]
            if col == ROCK[3] and (x * 7 + y * 13) % 11 == 0:
                col = ROCK[2]
            c.pt(x, y, col)
        # светлая кромка на верхних уступах
        if n >= 2:
            xe = n - 1 if side == 0 else W - n
            prev = 0
            if y > 40:
                pt_ = 1.0 + 14.0 * (max(0.0, (y - 1 - 40) / 170.0)) ** 1.1
                pt_ += 2.6 * math.sin((y - 1) / 9.0 + ph[0]) + 1.6 * math.sin((y - 1) / 3.7 + ph[1])
                pt_ *= 0.55 + 0.45 * smooth(40, 90, y - 1)
                prev = int(round(pt_))
            if n > prev + 1:
                for k in range(max(prev, 0), n):
                    x = k if side == 0 else W - 1 - k
                    c.pt(x, y, ROCK[0] if k >= n - 2 else ROCK[1])
wall(0, 4)
wall(1, 9)
# выступы-скалы по краям
def boulder(cx, cy, rx, ry):
    c.ell(cx, cy, rx, ry, ROCK[2])
    c.ell(cx - 1, cy - 1, max(rx - 2, 1), max(ry - 2, 1), ROCK[1])
    c.pt(cx - rx // 2, cy - ry + 1, ROCK[0])
    c.pt(cx - rx // 2 + 1, cy - ry, ROCK[0])
boulder(14, 150, 5, 3)
boulder(122, 126, 6, 3)
boulder(11, 118, 4, 2)
boulder(125, 176, 6, 4)

# ---------- дно ----------
fy = np.array([216 + 2.2 * math.sin(x / 8.0) + 1.4 * math.sin(x / 3.1 + 1) - 11 * edge(x) ** 2.5
               for x in range(W)])
below = YY - fy[XX]
tt = np.clip(below / 14.0, 0, 1.0) * 1.5 + 0.15 * np.sin(XX / 5.0 + YY / 2.0) + 0.1
floor_img = quantize(tt, ROCK[1:], 0.0)
px = c.arr()
m = below >= 0
px[m] = floor_img[m]
c.img.paste(Image.fromarray(px, "RGB"))
for x in range(W):
    c.pt(x, round(fy[x]), ROCK[0])
    if (x * 5) % 7 < 3:
        c.pt(x, round(fy[x]) + 1, ROCK[1])
SY = lambda x: round(fy[min(max(x, 0), W - 1)])
# валуны на дне
for cx, cy, rx, ry in [(52, 222, 8, 4), (84, 226, 9, 4), (66, 234, 6, 3), (30, 232, 6, 3), (112, 233, 6, 3)]:
    boulder(cx, cy, rx, ry)

# ---------- биолюминесценция: сначала мягкие ореолы ----------
BIO = [
    ("mush", 17, SY(17), 7, TEAL, TEAL_D),
    ("mush", 23, SY(23) + 1, 5, TEAL, TEAL_D),
    ("coral", 120, SY(120), 12, PINK, PINK_D),
    ("mush", 106, SY(106) + 1, 5, PINK, PINK_D),
    ("mush", 64, SY(64) + 5, 4, LIME, LIME_D),
    ("coral", 73, SY(73) + 4, 6, LIME, LIME_D),
    ("mush", 9, 147, 4, PINK, PINK_D),
    ("coral", 126, 172, 7, TEAL, TEAL_D),
    ("mush", 6, 205, 5, LIME, LIME_D),
]
HALO = {TEAL: TEAL_H, PINK: PINK_H, LIME: LIME_H}
for kind, x, y, h, col, dk in BIO:
    c.dmask(np.clip(glow(x, y - h * 0.6, 3.5 + h * 0.45, 1.2) - 0.25, 0, 0.9), HALO[col])


def mush(x, y, h, col, dk):
    c.line(x, y, x, y - h + 2, dk)
    c.line(x + 1, y, x + 1, y - h + 3, dk)
    cw = max(2, h // 2 + 1)
    c.ell(x, y - h + 1, cw, max(1, h // 4 + 1), dk)
    c.rect(x - cw + 1, y - h, x + cw - 1, y - h, col)
    c.pt(x - cw + 1, y - h + 1, col)
    c.pt(x + cw - 1, y - h + 1, dk)


def coral(x, y, h, col, dk):
    def br(x0, y0, ang, ln, d):
        x1, y1 = x0 + math.cos(ang) * ln, y0 - math.sin(ang) * ln
        c.line(x0, y0, x1, y1, dk)
        if d == 0:
            c.pt(x1, y1, col)
            c.pt(x1, y1 - 1, col)
            return
        for da in (-0.5, 0.45):
            br(x1, y1, ang + da, ln * 0.7, d - 1)
    br(x, y, math.radians(92), h * 0.5, 2)


for kind, x, y, h, col, dk in BIO:
    (mush if kind == "mush" else coral)(x, y, h, col, dk)

# ---------- курильщики ----------
def smoker(x, y, h, w, glow_on=True, lean=0):
    top = y - h
    for yy in range(top, y + 1):
        f = (yy - top) / max(h, 1)
        half = 1.0 + (w - 1.0) * f ** 0.8 + 0.5 * math.sin(yy / 2.7 + x)
        l, r = round(x - half + lean * (1 - f)), round(x + half + lean * (1 - f))
        for xx in range(l, r + 1):
            u = (xx - l) / max(r - l, 1)
            col = ROCK[0] if u < 0.2 else ROCK[1] if u < 0.65 else ROCK[2]
            c.pt(xx, yy, col)
        if (yy + x) % 6 == 0:
            c.pt(r - 1, yy, ROCK[3])
    # устье
    c.rect(round(x - 1 + lean), top - 1, round(x + 1 + lean), top - 1, ROCK[2])
    if glow_on:
        c.pt(x + lean, top - 1, VENT[2])
        c.pt(x - 1 + lean, top - 1, VENT[1])
        c.pt(x + 1 + lean, top - 1, VENT[1])
        c.pt(x + lean, top, VENT[0])
    return top


vents = [(28, SY(28) + 3, 30, 5, True, 1), (41, SY(41) + 3, 17, 4, False, -1),
         (99, SY(99) + 3, 23, 5, True, -1), (111, SY(111) + 3, 12, 3, False, 1)]
# сначала дымка и отсвет
for x, y, h, w, g, lean in vents:
    top = y - h
    sx = x + lean
    for k in range(2, 34, 4):
        py = top - k
        pxx = sx + round(2.2 * math.sin(k / 7.0 + x) * (k / 34.0) + 0.05 * k * lean)
        c.pt(pxx, py, SMOKE)
        if k > 18:
            c.pt(pxx + 1, py + 1, SMOKE)
    if g:
        for dx, dy in ((-2, 0), (2, 0), (-1, 1), (1, 1), (0, -2), (-1, -1), (1, -1)):
            c.pt(sx + dx, top - 1 + dy, VENT[0])
for x, y, h, w, g, lean in vents:
    smoker(x, y, h, w, g, lean)
# мелкие трубки у основания
for x, h in [(35, 5), (47, 4), (93, 5), (105, 4), (119, 3)]:
    smoker(x, SY(x) + 2, h, 2, False, 0)

# ---------- пузырьки и частицы ----------
for x, y in [(29, 188), (31, 176), (30, 162), (98, 192), (100, 181), (97, 170), (40, 200), (111, 206),
             (13, 70), (124, 58), (46, 22), (88, 30), (6, 100), (130, 94), (68, 12)]:
    c.pt(x, y, PALE)
for x, y in [(30, 150), (98, 156)]:
    c.ring(x, y, 1, PALE)
for x, y in [(52, 46), (82, 214), (20, 38), (118, 44)]:
    c.pt(x, y, WATER[0])

finish(c, "bg_abyss")
