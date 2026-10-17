"""Фон «Вулкан» 135x240. Угольно-красная вода, базальтовые столбы, лава в трещинах дна."""
import math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bgkit import *

rng = random.Random(5)
WATER = ["#7C3126", "#6E2A20", "#69241C", "#5A1F19", "#4A1915", "#38120F"]
GLOW = ["#7A2A1B", "#97371E", "#B84A23"]            # тёплое свечение воды у лавы
BAS = ["#4E4247", "#3A3136", "#2B2428", "#1C1719"]  # базальт: свет, середина, тень, глубокая тень
FAR = "#4F2019"                                     # дальний план (чуть светлее воды внизу)
LAVA = ["#C8381C", "#FF6A2A", "#FFA23C", "#FFD684"]
ASH, ASH_D = "#C99580", "#8F5B4B"
WARM = "#7A4034"

# ---------- вода ----------
t = 5.0 * (YY / (H - 1)) ** 1.1 + 0.5 * ((XX - 67) / 67.0) ** 2
t -= 1.0 * np.clip((0.2 - YY / H) / 0.2, 0, 1)
# тусклые багровые лучи из-под свода (мягче, чем в лагуне)
for x0, slope, hw in [(22, 0.30, 3.0), (62, 0.24, 3.8), (104, 0.18, 3.0)]:
    cx = x0 + slope * YY
    half = hw + YY * 0.06
    soft = np.clip(1 - np.abs(XX - cx) / half, 0, 1) ** 0.7
    t -= 1.0 * soft * np.clip(1 - YY / (0.30 * H), 0, 1) ** 1.2
c = Canvas(quantize(t, WATER, 0.55))

# ---------- лава: сначала маска, чтобы получить свечение ----------
body_im = Image.new("L", (W, H), 0)
core_im = Image.new("L", (W, H), 0)
bd, cd = ImageDraw.Draw(body_im), ImageDraw.Draw(core_im)
def crack(x, y, steps, ang, wid):
    pts = [(x, y)]
    for i in range(steps):
        ang += rng.uniform(-0.6, 0.6)
        ang = max(-0.7, min(0.7, ang)) if abs(math.cos(ang)) < 0.3 else ang
        x += math.cos(ang) * 3.0
        y += math.sin(ang) * 1.3
        pts.append((x, y))
        if rng.random() < 0.12 and wid > 2:
            crack(x, y, rng.randrange(4, 9), ang + rng.choice((-1, 1)) * 0.9, 2)
    bd.line([(round(a), round(b)) for a, b in pts], fill=255, width=wid)
    cd.line([(round(a), round(b)) for a, b in pts], fill=255, width=1)
for x0, y0, a in [(-4, 226, 0.1), (36, 231, -0.25), (92, 224, 0.2), (80, 236, 3.1), (4, 213, 0.35), (122, 214, 3.4), (130, 232, 3.2), (50, 238, -0.1)]:
    crack(x0, y0, 16, a, 3)
for cx, cy, rx, ry in [(14, 233, 8, 3), (121, 232, 9, 3)]:
    bd.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
    cd.ellipse([cx - rx + 2, cy - ry + 1, cx + rx - 2, cy + ry - 1], fill=255)
body = np.array(body_im) > 0
corem = np.array(core_im) > 0
core = body
g = blur(core.astype(float), 5) * 6.0
g2 = blur(core.astype(float), 13) * 5.0
glow = np.clip(g + g2, 0, 2.2) * np.clip((YY - 150) / 60.0, 0.1, 1.0)
gi = np.clip(np.floor(glow * 3.2 + BT * 0.9), 0, 3).astype(int)
px = c.arr()
for k, col in enumerate(GLOW, start=1):
    px[(gi >= k)] = rgb(col)
c.img.paste(Image.fromarray(px, "RGB"))

# ---------- дальний план ----------
def prof(base, amp, ed, seed):
    r = random.Random(seed)
    ph = [r.uniform(0, 6) for _ in range(3)]
    return [base - amp * (0.5 + 0.5 * math.sin(x / 10 + ph[0])) - 4 * math.sin(x / 4.1 + ph[1]) ** 2 - ed * edge(x) ** 2.6 for x in range(W)]
ys = prof(190, 8, 55, 2)
c.poly([(0, H)] + [(x, ys[x]) for x in range(W)] + [(W - 1, H)], FAR)
# далёкий вулканический конус слева-вдали и жар на горизонте
c.poly([(52, 192), (62, 172), (66, 171), (72, 172), (82, 192)], FAR)
c.dmask(np.clip((YY - 176) / 30.0, 0, 1) * np.clip(1 - np.abs(XX - 67) / 40.0, 0, 1) * 0.5, GLOW[0], region=(YY < 205))

# ---------- базальтовые столбы ----------
def column(x0, x1, ytop, ybot=H, tilt=0):
    w = x1 - x0 + 1
    for x in range(x0, x1 + 1):
        f = (x - x0) / max(w - 1, 1)
        col = BAS[0] if f < 0.25 else BAS[1] if f < 0.65 else BAS[2]
        c.rect(x, ytop, x, ybot, col)
    # грань сверху
    c.poly([(x0, ytop), (x0 + 1, ytop - 2), (x1 - 1, ytop - 2), (x1, ytop)], BAS[0])
    # трещинки-полосы
    for y in range(ytop + 6, min(ybot, H), rng.randrange(7, 11)):
        c.pt(x0 + w // 2, y, BAS[3]); c.pt(x0 + w // 2 + 1, y + 1, BAS[3])
    c.line(x1, ytop, x1, min(ybot, H), BAS[3])

def cluster(xs, tops, ybot=H):
    for (x0, x1), yt in zip(xs, tops):
        column(x0, x1, yt, ybot)

cluster([(0, 8), (9, 15), (16, 25), (26, 31)], [112, 150, 138, 182])
cluster([(104, 110), (111, 120), (121, 128), (129, 134)], [180, 140, 100, 128])
# средний план — низкие столбики у основания с обеих сторон
cluster([(32, 36), (37, 42)], [200, 207])
cluster([(93, 98), (99, 103)], [205, 198])

# затемнение вершин дальше от дна (уходят в воду)
fade = np.clip((190 - YY) / 80.0, 0, 1) * 0.55
px = c.arr()
isb = np.zeros((H, W), bool)
for col in BAS:
    isb |= (px == np.array(rgb(col))).all(axis=2)
c.dmask(fade, WATER[3], region=isb & (YY < 195))
# тёплый отсвет лавы на основании столбов
px = c.arr()
isb = np.zeros((H, W), bool)
for col in BAS[:3]:
    isb |= (px == np.array(rgb(col))).all(axis=2)
wg = np.clip(blur(body.astype(float), 9) * 9.0 - 0.15, 0, 1) * np.clip((YY - 140) / 60.0, 0, 1)
c.dmask(wg, WARM, region=isb)

# своды: висящие базальтовые столбы по краям
def hang(x0, x1, ybot):
    w = x1 - x0 + 1
    for x in range(x0, x1 + 1):
        f = (x - x0) / max(w - 1, 1)
        c.rect(x, 0, x, ybot, BAS[2] if f < 0.6 else BAS[3])
    c.line(x0, 0, x0, ybot - 1, BAS[1])
    c.poly([(x0, ybot), (x0 + 1, ybot + 2), (x1 - 1, ybot + 2), (x1, ybot)], BAS[2])
    for y in range(8, ybot, 9):
        c.pt(x0 + w // 2, y, BAS[3])
for a_, b_, h_ in [(0, 10, 48), (11, 17, 28), (18, 23, 14), (111, 117, 18), (118, 125, 36), (126, 134, 54)]:
    hang(a_, b_, h_)
# мягкая тень вокруг сводов (дизеринг тянется от столбов)
hm = np.zeros((H, W))
for a_, b_, h_ in [(0, 10, 48), (11, 17, 28), (18, 23, 14), (111, 117, 18), (118, 125, 36), (126, 134, 54)]:
    hm[: h_ + 3, a_:b_ + 1] = 1
px = c.arr()
notcol = np.ones((H, W), bool)
for col in BAS:
    notcol &= ~(px == np.array(rgb(col))).all(axis=2)
c.dmask(np.clip(blur(hm, 7) * 2.2, 0, 1), WATER[4], region=notcol & (YY < 90))

# ---------- дно ----------

fy = np.array([214 + 2.5 * math.sin(x / 7.0) + 1.5 * math.sin(x / 2.9) - 9 * edge(x) ** 2.5 for x in range(W)])
below = YY - fy[XX]
tt = np.clip(below / 12.0, 0, 3.0)
floor_img = quantize(np.clip(tt * 0.9 + 0.6 * (XX % 2 == YY % 2) * 0, 0, 3), BAS[1:], 0.9)
px = c.arr()
m = below >= 0
px[m] = floor_img[m]
c.img.paste(Image.fromarray(px, "RGB"))
for x in range(W):
    c.pt(x, round(fy[x]), BAS[0])
# валуны на дне
for cx, cy, rx, ry in [(46, 216, 7, 4), (88, 218, 8, 4), (66, 230, 6, 3)]:
    c.ell(cx, cy, rx, ry, BAS[2]); c.ell(cx - 1, cy - 1, rx - 2, ry - 2, BAS[1]); c.pt(cx - 3, cy - 2, BAS[0]); c.pt(cx - 2, cy - 3, BAS[0])

# рисуем лаву поверх
er = body.copy()
er[1:-1, 1:-1] = body[1:-1, 1:-1] & body[:-2, 1:-1] & body[2:, 1:-1] & body[1:-1, :-2] & body[1:-1, 2:]
px = c.arr()
vis = (YY >= fy[XX]) | (YY > 205)
px[body & vis] = rgb(LAVA[0])
px[er & vis] = rgb(LAVA[1])
px[corem & er & vis] = rgb(LAVA[2])
sp = corem & er & vis & ((XX * 5 + YY * 3) % 7 == 0)
px[sp] = rgb(LAVA[3])
c.img.paste(Image.fromarray(px, "RGB"))

# ---------- пузырьки и пепел ----------
for x, y in [(8, 205), (12, 188), (11, 170), (14, 150), (125, 200), (120, 178), (123, 160), (118, 140), (30, 206), (36, 194), (100, 208), (96, 190)]:
    c.pt(x, y, ASH)
for x, y in [(10, 120), (126, 112), (4, 96), (130, 90), (22, 60), (112, 54), (45, 20), (90, 30)]:
    c.pt(x, y, ASH_D)
for x, y in [(12, 183), (121, 169), (34, 199)]:
    c.ring(x, y, 1, ASH)

finish(c, "bg_volcano")
