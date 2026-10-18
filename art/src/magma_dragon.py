"""Магмовый дракон (вулкан, легендарная). Милый морской дракон-змей. Смотрит ВПРАВО."""
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#a8908f"   # базальт, свет
BASE = "#6e5c62"    # базальт, база
SHADE = "#46393f"   # базальт, тень
LAVA = "#ff7a1f"
GLOW = "#ffd84a"
HORN = "#ffe0a8"
WHITE = "#ffffff"

def spline(ctrl, n=14):
    out = []
    P = [ctrl[0]] + ctrl + [ctrl[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(n):
            t = k / n
            f = lambda a, b, c, d: 0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t ** 3)
            out.append((f(p0[0], p1[0], p2[0], p3[0]), f(p0[1], p1[1], p2[1], p3[1])))
    out.append(ctrl[-1])
    return out

ctrl = [(3, 15), (7, 19), (12, 21), (17, 19), (20, 16), (22, 15)]
pts = spline(ctrl)
M = len(pts)
rad = [0.8 + 2.6 * min(i / (M * 0.55), 1.0) for i in range(M)]

def normal(i):
    j0, j1 = max(i - 1, 0), min(i + 1, M - 1)
    dx, dy = pts[j1][0] - pts[j0][0], pts[j1][1] - pts[j0][1]
    L = math.hypot(dx, dy) or 1
    dx, dy = dx / L, dy / L
    return (dx, dy), (dy, -dx)   # направление, нормаль к спине

g = Grid()
# светящийся гребень вдоль спины
for i in range(8, M - 4, 5):
    (dx, dy), (nx, ny) = normal(i)
    x, y = pts[i]; r = rad[i]
    b0 = (round(x + nx * (r - 0.5) - dx * 1.5), round(y + ny * (r - 0.5) - dy * 1.5))
    b1 = (round(x + nx * (r - 0.5) + dx * 1.5), round(y + ny * (r - 0.5) + dy * 1.5))
    tip = (round(x + nx * (r + 3) - dx * 1.5), round(y + ny * (r + 3) - dy * 1.5))
    g.poly([b0, tip, b1], LAVA)
    g.set(*tip, GLOW)
# огненный кончик хвоста
tx, ty = pts[0]
tx, ty = round(tx), round(ty)
g.poly([(tx + 1, ty + 1), (tx - 2, ty - 3), (tx - 1, ty - 6), (tx + 1, ty - 3), (tx + 3, ty - 4), (tx + 3, ty)], LAVA)
g.poly([(tx, ty - 1), (tx, ty - 4), (tx + 1, ty - 1)], GLOW)
# тело
for (x, y), r in zip(pts, rad):
    g.ellipse(round(x), round(y), r - 0.5, r - 0.5, BASE)
# лапка-плавник
g.poly([(15, 22), (13, 26), (18, 23)], LAVA)
g.set(13, 26, GLOW)
g.poly([(9, 21), (7, 25), (11, 22)], LAVA)
g.set(7, 25, GLOW)
# голова
hx, hy = 24, 13
g.ellipse(hx, hy, 5, 5, BASE)
g.ellipse(hx + 4, hy + 3, 2, 2, BASE)             # морда
# рожки
g.poly([(hx - 5, hy - 3), (hx - 8, hy - 7), (hx - 3, hy - 4)], HORN)
g.poly([(hx, hy - 4), (hx - 1, hy - 9), (hx + 3, hy - 4)], HORN)
# свет и тень
snap = [[g.get(x, y) for x in range(g.w)] for y in range(g.h)]
for y in range(g.h):
    for x in range(g.w):
        if snap[y][x] == BASE:
            if snap[y - 1][x] is None or snap[y - 1][x - 1] is None and snap[y][x - 1] == BASE and snap[y - 1][x] != BASE:
                g.set(x, y, LIGHT)
            elif snap[y + 1][x] is None:
                g.set(x, y, LAVA if (x < 22) else SHADE)
            elif snap[y + 2][x] is None and x < 22:
                g.set(x, y, SHADE)
# трещины
for (x, y) in ((8, 17), (9, 18), (13, 19), (14, 18), (18, 16), (19, 17)):
    if g.get(x, y) in (BASE, SHADE, LIGHT):
        g.set(x, y, LAVA)
# лицо
g.line(hx + 3, hy + 4, hx + 6, hy + 4, SHADE)
g.set(hx + 2, hy + 3, LAVA)
g.rect(hx + 1, hy - 2, hx + 3, hy, WHITE)
g.rect(hx + 2, hy - 1, hx + 3, hy, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("magma_dragon", g.to_image())
    print("ok")
