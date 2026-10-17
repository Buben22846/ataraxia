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
lava = np.zeros((H, W), dtype=np.uint8)  # 0 нет, 1 край, 2 тело, 3 жар
def crack(x, y, steps, ang, wid=1):
    pts = []
    for i in range(steps):
        ang += rng.uniform(-0.55, 0.55)
        x += math.cos(ang) * 2.2
        y += math.sin(ang) * 0.9
        pts.append((x, y))
        if rng.random() < 0.09 and wid > 0:
            crack(x, y, rng.randrange(5, 12), ang + rng.choice((-1, 1)) * 0.9, 0)
    for (px_, py_) in pts:
        for dy in range(-wid, wid + 1):
            xi, yi = int(px_), int(py_) + dy
            if 0 <= xi < W and 0 <= yi < H:
                lava[yi, xi] = max(lava[yi, xi], 2 if wid else 1)
for x0, y0, a in [(-4, 228, 0.1), (40, 233, -0.2), (95, 225, 0.2), (70, 237, 3.1), (10, 214, 0.3), (118, 214, -0.4)]:
    crack(x0, y0, 22, a, 1)
# маленькие лужицы лавы по краям
for cx, cy, rx, ry in [(14, 232, 7, 2), (122, 231, 8, 2), (60, 236, 5, 1)]:
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if ((x - cx) / rx) ** 2 + ((y - cy) / max(ry, 1)) ** 2 <= 1 and 0 <= y < H and 0 <= x < W:
                lava[y, x] = 2
core = lava > 0
g = blur(core.astype(float), 6) * 5.0
g2 = blur(core.astype(float), 14) * 3.0
glow = np.clip(g + g2, 0, 1.6) * np.clip((YY - 150) / 70.0, 0.15, 1.0)
gi = np.clip(np.floor(glow * 3.4 + BT - 0.3), 0, 3).astype(int)
px = c.arr()
for k in range(1, 4):
    pass
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
c.dmask(fade, WATER[3], region=((XX < 33) | (XX > 102)) & (YY < 195))

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
px = c.arr()
for y in range(H):
    for x in range(W):
        v = lava[y, x]
        if v and (y >= fy[x] or y > 205):
            px[y, x] = rgb(LAVA[1] if v == 2 else LAVA[0])
c.img.paste(Image.fromarray(px, "RGB"))
# жар в центре трещин
for y in range(1, H - 1):
    for x in range(1, W - 1):
        if lava[y, x] == 2 and lava[y - 1, x] and lava[y + 1, x] and (x + y) % 2 == 0:
            c.pt(x, y, LAVA[2])
        if lava[y, x] == 2 and lava[y, x - 1] and lava[y, x + 1] and lava[y - 1, x] and lava[y + 1, x] and (x * 3 + y) % 5 == 0:
            c.pt(x, y, LAVA[3])

# ---------- пузырьки и пепел ----------
for x, y in [(8, 205), (12, 188), (11, 170), (14, 150), (125, 200), (120, 178), (123, 160), (118, 140), (30, 206), (36, 194), (100, 208), (96, 190)]:
    c.pt(x, y, ASH)
for x, y in [(10, 120), (126, 112), (4, 96), (130, 90), (22, 60), (112, 54), (45, 20), (90, 30)]:
    c.pt(x, y, ASH_D)
for x, y in [(12, 183), (121, 169), (34, 199)]:
    c.ring(x, y, 1, ASH)

finish(c, "bg_volcano")
