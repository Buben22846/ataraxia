"""Фон «Арктика» 135x240. Ледяной грот: голубая вода, сосульки по краям свода, снежное дно, кристаллы."""
import math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bgkit import *

rng = random.Random(21)
WATER = ["#8CC4E2", "#6BAAD2", "#5490BB", "#4078A5", "#356A97", "#2A5A85"]
FAR = "#3A70A0"
FAR2 = "#2F6490"
ICE = ["#EAF8FF", "#BDE6F6", "#8FCBE8", "#5FA6D0", "#3F82B2"]  # свет, светлый, средний, тень, глубокая тень
SNOW = ["#F2F8FC", "#D0E3F0", "#A9C8DE", "#7FA6C6"]
WHITE = "#FFFFFF"

# ---------- вода ----------
t = 5.0 * (YY / (H - 1)) ** 0.9 + 0.45 * ((XX - 67) / 67.0) ** 2
t += 1.1 - 1.1 * np.clip(YY / (0.12 * H), 0, 1)
# холодные лучи через отверстие в своде
for x0, slope, hw in [(40, 0.18, 3.0), (66, 0.0, 5.0), (92, -0.18, 3.0)]:
    cx = x0 + slope * YY
    half = hw + YY * 0.05
    soft = np.clip(1 - np.abs(XX - cx) / half, 0, 1) ** 0.6
    t -= 1.7 * soft * np.clip(1 - YY / (0.34 * H), 0, 1) ** 1.2
c = Canvas(quantize(t, WATER, 0.55))

# ---------- дальний план: ледяные колонны и арки ----------
def prof(base, amp, ed, seed):
    r = random.Random(seed)
    ph = [r.uniform(0, 6) for _ in range(3)]
    return [base - amp * (0.5 + 0.5 * math.sin(x / 9 + ph[0])) - 5 * math.sin(x / 4.3 + ph[1]) ** 2 - ed * edge(x) ** 2.8 for x in range(W)]
ys = prof(194, 8, 70, 4)
c.poly([(0, H)] + [(x, ys[x]) for x in range(W)] + [(W - 1, H)], FAR)
for x0, w, h in [(6, 8, 52), (17, 5, 30), (112, 7, 44), (122, 6, 58)]:
    c.poly([(x0, 200), (x0, 200 - h + 4), (x0 + 2, 200 - h), (x0 + w - 1, 200 - h + 2), (x0 + w, 200)], FAR)
ys2 = prof(204, 7, 55, 8)
c.poly([(0, H)] + [(x, ys2[x]) for x in range(W)] + [(W - 1, H)], FAR2)
c.dmask(np.clip((YY - 150) / 50.0, 0, 1) * 0.25, WATER[3], region=(YY < 200))

# ---------- свод (потолок) и стены ----------
def ceiling(x):
    # граница свода сверху: на краях глубже, в центре отверстие
    return 22 * edge(x) ** 1.6 + 4 * math.sin(x / 5.0 + 1) * edge(x) + 2
cy = [ceiling(x) for x in range(W)]
for x in range(W):
    top = int(cy[x])
    for y in range(top):
        f = y / max(top, 1)
        c.pt(x, y, ICE[4] if f < 0.55 else ICE[3])
    c.pt(x, top, ICE[2])
    if top > 3:
        c.pt(x, top - 1, ICE[2])
# блики на своде
for x in range(0, W, 1):
    top = int(cy[x])
    if top > 5 and (x * 3) % 7 < 2:
        c.pt(x, top - 3, ICE[2])
# боковые стены — ледяные плиты по краям (только у самых краёв)
def wall(side, width_fn, y0, y1):
    for y in range(y0, y1):
        wd = int(width_fn(y))
        for k in range(wd):
            x = k if side == 0 else W - 1 - k
            f = k / max(wd - 1, 1)
            c.pt(x, y, ICE[2] if f > 0.55 else ICE[3] if f > 0.15 else ICE[4])
        xe = wd if side == 0 else W - 1 - wd
        c.pt(xe, y, ICE[1])
wall(0, lambda y: 2 + 1.5 * math.sin(y / 17.0) + 9 * max(0, 1 - y / 80) ** 1.5, 0, 125)
wall(1, lambda y: 2 + 1.5 * math.sin(y / 15.0 + 2) + 9 * max(0, 1 - y / 80) ** 1.5, 0, 125)
# дитер, растворяющий стены в воду по мере спуска
px = c.arr()
isice = np.zeros((H, W), bool)
for col in ICE[1:]:
    isice |= (px == np.array(rgb(col))).all(axis=2)
c.dmask(np.clip((YY - 60) / 60.0, 0, 1) * 1.0, WATER[3], region=isice & (YY > 60) & (YY < 130) & ((XX < 20) | (XX > 114)))

# ---------- сосульки ----------
def icicle(x, ytop, ln, w):
    """Сосулька с освещённой левой гранью."""
    for i in range(ln):
        ww = max(0.8, w * (1 - i / ln) ** 0.9)
        l = round(x - ww / 2)
        r = round(x + ww / 2)
        for xx in range(l, r + 1):
            f = (xx - l) / max(r - l, 1)
            col = ICE[0] if f < 0.2 and i < ln * 0.8 else ICE[1] if f < 0.5 else ICE[2] if f < 0.85 else ICE[3]
            c.pt(xx, ytop + i, col)
    c.pt(x, ytop + ln, ICE[1])

spec = [(2, 38, 7), (8, 26, 5), (14, 44, 6), (20, 18, 4), (26, 10, 3), (31, 14, 4), (36, 8, 3),
        (98, 9, 3), (103, 15, 4), (109, 12, 4), (115, 22, 5), (121, 40, 6), (127, 28, 5), (132, 52, 7)]
for x, ln, w in spec:
    icicle(x, int(cy[min(max(x, 0), W - 1)]) - 2, ln, w)
# маленькие сосульки по центру свода
for x in (50, 58, 78, 86):
    icicle(x, int(cy[x]) - 2, rng.randrange(3, 6), 2)

# ---------- дно: снег ----------
fy = np.array([210 + 3 * math.sin(x / 8.0) + 1.5 * math.sin(x / 3.1 + 2) - 12 * edge(x) ** 2.6 for x in range(W)])
below = YY - fy[XX]
tt = np.clip(below / 11.0, 0, 3.0) + 0.3 * np.clip((YY - 228) / 12.0, 0, 1)
img_s = quantize(tt, SNOW, 0.9)
px = c.arr()
m = below >= 0
px[m] = img_s[m]
c.img.paste(Image.fromarray(px, "RGB"))
for x in range(W):
    c.pt(x, round(fy[x]), SNOW[0])
# снежные дюны-тени
for yrow in range(216, 240, 5):
    for x in range(W):
        if fy[x] < yrow - 1 and math.sin(x / 3.4 + yrow) > 0.6:
            c.pt(x, yrow, SNOW[0] if yrow < 228 else SNOW[1])

# ---------- кристаллы ----------
def crystal(x, ybase, w, h, lean=0):
    """Шестигранная призма с наклонной вершиной: три грани."""
    xl, xr = x - w // 2, x + w // 2
    tip = (x + lean, ybase - h)
    body_top = ybase - h + max(3, w // 2 + 1)
    # левая (свет), центр (средний), правая (тень)
    third = max(1, w // 3)
    c.poly([(xl, ybase), (xl, body_top), (tip[0], tip[1]), (xl + third, body_top + 1), (xl + third, ybase)], ICE[1])
    c.poly([(xl + third, ybase), (xl + third, body_top + 1), (tip[0], tip[1]), (xr - third, body_top + 1), (xr - third, ybase)], ICE[2])
    c.poly([(xr - third, ybase), (xr - third, body_top + 1), (tip[0], tip[1]), (xr, body_top), (xr, ybase)], ICE[3])
    c.line(xl, ybase, xl, body_top, ICE[0])
    c.pt(tip[0], tip[1], ICE[0])
    c.pt(xl + 1, body_top + 2, ICE[0])
SY = lambda x: round(fy[min(max(x, 0), W - 1)])
crystal(6, SY(6) + 3, 8, 54, -1)
crystal(15, SY(15) + 3, 7, 38, 1)
crystal(23, SY(23) + 3, 5, 22, 0)
crystal(32, SY(32) + 3, 4, 13, -1)
crystal(129, SY(129) + 3, 8, 60, 1)
crystal(120, SY(120) + 3, 7, 40, -1)
crystal(112, SY(112) + 3, 5, 24, 0)
crystal(104, SY(104) + 3, 4, 12, 1)
for cx_ in (6, 15, 23, 32, 129, 120, 112, 104):
    for k in range(-6, 7):
        yy_ = SY(cx_ + k) - 1 + abs(k) // 3
        c.pt(cx_ + k, yy_, SNOW[0]); c.pt(cx_ + k, yy_ + 1, SNOW[1])
crystal(11, SY(11) + 3, 4, 20, -3)
crystal(27, SY(27) + 3, 4, 16, 3)
crystal(124, SY(124) + 3, 4, 22, 3)
crystal(108, SY(108) + 3, 4, 15, -3)
# мелочь в центре дна
crystal(58, SY(58) + 2, 3, 8, 0)
crystal(80, SY(80) + 2, 3, 6, 0)
# блики-искры
for x, y, big in [(7, 150, 1), (130, 140, 1), (16, 190, 0), (121, 185, 0), (24, 60, 0), (110, 66, 0), (4, 108, 0), (128, 100, 0)]:
    c.sparkle(x, y, WHITE if big else ICE[0], big=bool(big))
# пузырьки / льдинки в воде
for x, y in [(30, 176), (34, 160), (37, 142), (100, 180), (97, 164), (95, 148), (9, 80), (126, 76), (46, 28), (88, 36)]:
    c.pt(x, y, ICE[1])
for x, y in [(34, 130), (98, 138)]:
    c.ring(x, y, 1, ICE[0])

finish(c, "bg_arctic")
