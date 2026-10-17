"""Фон «Лагуна» 135x240. Тёплая тропическая вода, лучи сверху, песок и кораллы внизу."""
import math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bgkit import *

rng = random.Random(11)
WATER = ["#5CC0C4", "#3CA4B4", "#2488A6", "#146E8C", "#10607C", "#0C506A"]
FAR_A, FAR_B = "#16627F", "#0F5672"
SAND = ["#F0D9A4", "#DCBF86", "#BD9E6A", "#8F7A57"]
PINK, PINK_D = "#E8728A", "#B9486A"
ORG, ORG_D = "#F5A25C", "#C86B3C"
PUR, PUR_D = "#9A68B8", "#6C4590"
GRN, GRN_D, GRN_L = "#2C7A55", "#1E5A47", "#4DAF74"
PALE, GOLD = "#D6F4EE", "#F5C84A"

# ---------- вода + лучи ----------
t = 5.0 * (YY / (H - 1)) ** 0.95 + 0.55 * ((XX - 67) / 67.0) ** 2
t -= 1.5 * np.clip((0.16 - YY / H) / 0.16, 0, 1)
for x0, slope, hw in [(18, 0.34, 4.0), (46, 0.30, 5.5), (74, 0.26, 4.5), (101, 0.22, 6.0), (128, 0.18, 4.0), (-4, 0.36, 3.5)]:
    cx = x0 + slope * YY
    half = hw + YY * 0.07
    soft = np.clip(1 - np.abs(XX - cx) / half, 0, 1)
    fade = np.clip(1 - YY / (0.40 * H), 0, 1) ** 1.3
    t -= 1.5 * soft * fade
c = Canvas(quantize(t, WATER, 0.85))

# поверхность: блики-рябь
for x in range(0, W):
    y = 3 + round(1.4 * math.sin(x / 4.5) + 0.8 * math.sin(x / 2.1 + 1))
    if (x * 7) % 5 < 3:
        c.pt(x, y, PALE)
for _ in range(14):
    x, y = rng.randrange(W), rng.randrange(8, 36)
    c.line(x, y, x + rng.randrange(2, 5), y, WATER[0])

# ---------- дальний план ----------
def profile(base, amp, ed, seed):
    r = random.Random(seed)
    ph = [r.uniform(0, 6) for _ in range(3)]
    ys = []
    for x in range(W):
        h = base - amp * (0.5 + 0.5 * math.sin(x / 11 + ph[0])) - 0.6 * amp * math.sin(x / 5.3 + ph[1]) ** 2 * 0.5
        h -= ed * edge(x) ** 2.8
        ys.append(h)
    return ys

for col, base, amp, ed, seed in [(FAR_A, 196, 9, 62, 3), (FAR_B, 206, 8, 52, 9)]:
    ys = profile(base, amp, ed, seed)
    pts = [(0, H)] + [(x, ys[x]) for x in range(W)] + [(W - 1, H)]
    c.poly(pts, col)
# далёкие арки / скалы лагуны
for x0, w, h in [(12, 7, 26), (22, 5, 18), (113, 8, 30), (123, 5, 20)]:
    c.poly([(x0, 200), (x0 + 1, 200 - h), (x0 + w - 1, 200 - h * 0.8), (x0 + w, 200)], FAR_B)
# мягкая дымка воды поверх дали (прячет контраст)
haze = np.clip((YY - 150) / 40.0, 0, 1) * 0.0
c.dmask(np.clip((YY - 160) / 60.0, 0, 1) * 0.28, WATER[4], region=(YY < 205))

# ---------- песок ----------
sy = np.array([207 + 2.5 * math.sin(x / 9.0) + 1.5 * math.sin(x / 3.7 + 1) - 13 * edge(x) ** 3 for x in range(W)])
below = YY - sy[XX]
ts = np.clip(below / 14.0, 0, 3.0) + 0.0
ts += 0.5 * np.clip((YY - 225) / 15.0, 0, 1)
sand_img = quantize(ts, SAND, 0.9)
px = c.arr()
m = below >= 0
px[m] = sand_img[m]
c.img.paste(Image.fromarray(px, "RGB"))
# ряби на песке
for yrow in range(212, 240, 4):
    for x in range(0, W):
        if sy[x] < yrow - 1 and math.sin(x / 3.1 + yrow * 0.9) > 0.55:
            c.pt(x, yrow, SAND[0] if yrow < 226 else SAND[1])
# светлая кромка
for x in range(W):
    c.pt(x, round(sy[x]), SAND[0])

# ---------- растения / кораллы ----------
def weed(x0, y0, h, amp, ph, w=2, light=False):
    for i in range(h):
        x = x0 + amp * math.sin(i / 6.5 + ph) * (i / h)
        y = y0 - i
        ww = w if i < h * 0.7 else 1
        c.rect(round(x), y, round(x) + ww - 1, y, GRN)
        c.pt(round(x), y, GRN_L if light else GRN)
        if ww > 1:
            c.pt(round(x) + 1, y, GRN_D)

def branch(x, y, ang, ln, depth, col, dark, tip):
    x2, y2 = x + math.cos(ang) * ln, y - math.sin(ang) * ln
    c.line(x, y, x2, y2, col, 2 if depth >= 2 else 1)
    if depth == 0:
        c.pt(x2, y2, tip)
        return
    n = 2 if depth > 1 else 2
    for da in (-0.55, 0.5) if n == 2 else (0,):
        branch(x2, y2, ang + da + rng.uniform(-0.15, 0.15), ln * 0.74, depth - 1, col, dark, tip)

def brain(cx, cy, r, col, dark, hi):
    c.ell(cx, cy, r, r * 0.75, col)
    c.d.pieslice([cx - r, cy - r * 0.75, cx + r, cy + r * 0.75], 200, 340, fill=rgb(dark)) if False else None
    for k in range(-int(r) + 2, int(r) - 1, 3):
        for yy in range(-int(r * 0.6), int(r * 0.6), 1):
            if ((k + yy * 0.5) % 4) == 0 and (k / r) ** 2 + (yy / (r * 0.75)) ** 2 < 0.85:
                c.pt(cx + k, cy + yy, dark)
    for k in range(3):
        c.pt(cx - r * 0.4 + k, cy - r * 0.5 + (k % 2), hi)

def fan(cx, cy, r, col, dark):
    for a in range(20, 161, 10):
        ang = math.radians(a)
        c.line(cx, cy, cx + math.cos(ang) * r, cy - math.sin(ang) * r, col)
    for a in range(30, 151, 20):
        ang = math.radians(a)
        c.pt(cx + math.cos(ang) * r, cy - math.sin(ang) * r, dark)
    c.line(cx, cy, cx, cy + 4, dark)

def tubes(cx, cy, n, col, dark, cap):
    for i in range(n):
        x = cx + i * 3
        h = rng.randrange(7, 15)
        c.rect(x, cy - h, x + 1, cy, col)
        c.pt(x + 1, cy - h + 2, dark)
        c.rect(x, cy - h - 1, x + 1, cy - h - 1, cap)

def star(cx, cy, col):
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (2, 1), (-2, 1), (1, -2), (-1, -2), (2, -1)):
        pass
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0), (0, 2), (0, -2)):
        c.pt(cx + dx, cy + dy, col)

SY = lambda x: round(sy[min(max(x, 0), W - 1)])
# левый кластер
weed(4, SY(4) + 1, 70, 5, 0.5, 2)
weed(10, SY(10) + 1, 46, 4, 2.0, 2, True)
weed(17, SY(17) + 1, 58, 5, 1.0, 2)
brain(26, SY(26) - 2, 9, ORG, ORG_D, SAND[0])
branch(14, SY(14) + 1, math.radians(80), 11, 3, PINK, PINK_D, PALE)
branch(33, SY(33) + 2, math.radians(95), 10, 3, PUR, PUR_D, PALE)
fan(6, SY(6) - 1, 17, PINK, PINK_D)
tubes(37, SY(37) + 1, 3, ORG, ORG_D, GOLD)
star(21, SY(21) + 4, ORG)
# правый кластер
weed(130, SY(130) + 1, 74, 5, 2.5, 2)
weed(122, SY(122) + 1, 50, 4, 0.2, 2, True)
weed(113, SY(113) + 1, 40, 4, 3.3, 2)
brain(106, SY(106) - 2, 8, PUR, PUR_D, SAND[0])
branch(120, SY(120) + 1, math.radians(100), 12, 3, ORG, ORG_D, PALE)
branch(97, SY(97) + 2, math.radians(85), 9, 3, PINK, PINK_D, PALE)
fan(128, SY(128) - 1, 15, PUR, PUR_D)
tubes(92, SY(92) + 1, 3, PINK, PINK_D, PALE)
star(112, SY(112) + 5, PINK)
# редкая мелочь в центре дна
weed(60, SY(60) + 1, 12, 2, 0.3, 1)
weed(75, SY(75) + 1, 9, 2, 1.3, 1, True)
for x, y in [(52, 226), (84, 230), (68, 233)]:
    c.pt(x, y, SAND[2]); c.pt(x + 1, y, SAND[2]); c.pt(x, y - 1, SAND[0])
# пузырьки
for x, y, r in [(30, 160, 1), (33, 140, 1), (36, 118, 2), (104, 170, 1), (102, 150, 1), (99, 128, 2), (12, 100, 1)]:
    if r == 1:
        c.pt(x, y, PALE)
    else:
        c.ring(x, y, 1, PALE)

finish(c, "bg_lagoon")
