"""Левиафан (бездна, легендарный). Древний морской змей-кит: волнистое тело, светящиеся пластины, корона. Смотрит ВПРАВО."""
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#8e9cf2"
BASE = "#404fa4"
SHADE = "#262f70"
PLATE = "#ff6fd0"
PLATE2 = "#b65cff"
GLOW = "#ffd6f6"
HORN = "#e6dcff"
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

ctrl = [(3, 24), (7, 19), (11, 17), (15, 21), (19, 25), (22, 21), (23, 16)]
pts = spline(ctrl)
M = len(pts)
rad = [1.0 + 3.0 * min(i / (M * 0.55), 1.0) for i in range(M)]

def normal(i):
    j0, j1 = max(i - 1, 0), min(i + 1, M - 1)
    dx, dy = pts[j1][0] - pts[j0][0], pts[j1][1] - pts[j0][1]
    L = math.hypot(dx, dy) or 1
    dx, dy = dx / L, dy / L
    return (dx, dy), (dy, -dx)   # направление, нормаль (к спине: вверх)

g = Grid()
# хвостовой плавник-флюк
g.poly([(3, 24), (0, 20), (1, 25), (0, 29), (4, 26)], PLATE2)
# пластины вдоль спины
for i in range(6, M - 10, 5):
    (dx, dy), (nx, ny) = normal(i)
    x, y = pts[i]; r = rad[i]
    b0 = (round(x + nx * (r - 0.5) - dx * 1.5), round(y + ny * (r - 0.5) - dy * 1.5))
    b1 = (round(x + nx * (r - 0.5) + dx * 1.5), round(y + ny * (r - 0.5) + dy * 1.5))
    tip = (round(x + nx * (r + 2.5 + (0.8 if i % 10 == 6 else 0)) - dx * 0.5), round(y + ny * (r + 2.5 + (0.8 if i % 10 == 6 else 0)) - dy * 0.5))
    g.poly([b0, tip, b1], PLATE)
    g.set(*tip, GLOW)
# тело
for (x, y), r in zip(pts, rad):
    g.ellipse(round(x), round(y), r - 0.5, r - 0.5, BASE)
# голова
hx, hy = 25, 12
g.ellipse(hx, hy, 4, 4, BASE)
g.ellipse(hx + 3, hy + 1, 3, 2, BASE)          # морда
# корона-плавники
g.poly([(hx - 4, hy - 2), (hx - 8, hy - 8), (hx - 2, hy - 4)], PLATE2)
g.poly([(hx - 1, hy - 4), (hx - 3, hy - 10), (hx + 1, hy - 4)], PLATE)
g.poly([(hx + 1, hy - 4), (hx + 3, hy - 9), (hx + 4, hy - 3)], PLATE2)
g.set(hx - 3, hy - 10, GLOW)
# ласт
g.poly([(17, 24), (14, 28), (20, 26)], PLATE2)
# свет (сверху) и тень (снизу)
snap = [[g.get(x, y) for x in range(g.w)] for y in range(g.h)]
for y in range(1, g.h - 2):
    for x in range(1, g.w):
        if snap[y][x] == BASE:
            if snap[y - 1][x] is None or (snap[y - 1][x] in (PLATE, PLATE2) and snap[y][x - 1] != BASE):
                g.set(x, y, LIGHT)
            elif snap[y + 1][x] is None or snap[y + 2][x] is None:
                g.set(x, y, SHADE)
# светящиеся точки по брюху
for i in range(12, M - 14, 7):
    (dx, dy), (nx, ny) = normal(i)
    x, y = pts[i]; r = rad[i]
    g.set(round(x - nx * (r - 1.5)), round(y - ny * (r - 1.5)), PLATE)
# блик на лбу и морде
for x in range(hx - 1, hx + 5):
    if g.get(x, hy - 3) == BASE: g.set(x, hy - 3, LIGHT)
for x in range(hx + 2, hx + 7):
    if g.get(x, hy - 1) == BASE: g.set(x, hy - 1, LIGHT)
# глаз и пасть
g.rect(hx + 1, hy - 1, hx + 3, hy, PLATE)
g.rect(hx + 2, hy - 1, hx + 3, hy - 1, GLOW)
g.line(hx + 2, hy + 3, hx + 6, hy + 3, OUT)
g.set(hx + 5, hy + 4, HORN); g.set(hx + 3, hy + 4, HORN)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("leviathan", g.to_image())
    print("ok")
