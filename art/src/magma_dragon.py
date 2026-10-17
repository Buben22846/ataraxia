"""Магмовый дракон (вулкан, легендарная). Милый морской дракон-змей. Смотрит ВПРАВО."""
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"
LIGHT = "#8a7478"   # базальт, свет
BASE = "#54444b"    # базальт, база
SHADE = "#2f262c"   # базальт, тень
LAVA = "#ff7a1f"
GLOW = "#ffd84a"
HORN = "#ffb04a"
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

ctrl = [(3, 22), (7, 26), (13, 26), (19, 22), (21, 16), (23, 12)]
pts = spline(ctrl)
M = len(pts)
rad = [1.0 + 2.6 * min(i / (M * 0.55), 1.0) for i in range(M)]

g = Grid()
# светящийся гребень вдоль спины
for i in range(8, M - 6, 4):
    x, y = pts[i]
    g.poly([(round(x) - 1, round(y - rad[i])), (round(x), round(y - rad[i]) - 4), (round(x) + 2, round(y - rad[i]))], LAVA)
    g.set(round(x), round(y - rad[i]) - 2, GLOW)
# огненный кончик хвоста
tx, ty = pts[0]
g.poly([(round(tx) + 1, round(ty) + 1), (round(tx) - 2, round(ty) - 3), (round(tx), round(ty) - 5), (round(tx) + 3, round(ty) - 1)], LAVA)
g.set(round(tx), round(ty) - 2, GLOW)
# тело
for (x, y), r in zip(pts, rad):
    g.ellipse(round(x), round(y), r - 0.5, r - 0.5, BASE)
for (x, y), r in zip(pts, rad):
    g.set(round(x) - 1, round(y - r + 0.5), LIGHT)
    g.set(round(x), round(y - r + 0.5), LIGHT)
    g.set(round(x), round(y + r - 0.5), SHADE)
# лавовые трещины-полоски на теле
for i in range(10, M - 8, 5):
    x, y = pts[i]
    g.line(round(x), round(y - 1), round(x) + 1, round(y + 1), LAVA)
# лапка-плавник
g.poly([(19, 21), (16, 26), (20, 24), (22, 22)], LAVA)
# голова
hx, hy = 24, 10
g.ellipse(hx, hy, 5, 4, BASE)
g.ellipse(hx + 4, hy + 2, 3, 2, BASE)           # морда
g.ellipse(hx - 1, hy - 3, 4, 0, LIGHT, only_where="filled")
g.line(hx + 2, hy + 4, hx + 6, hy + 4, SHADE)
g.line(hx + 4, hy + 3, hx + 7, hy + 3, LAVA)     # улыбка
g.set(hx + 2, hy + 2, LAVA)                      # румянец
g.set(hx + 3, hy + 2, LAVA)
# рожки
g.poly([(hx - 3, hy - 3), (hx - 6, hy - 9), (hx - 1, hy - 4)], HORN)
g.poly([(hx, hy - 4), (hx - 1, hy - 10), (hx + 3, hy - 4)], HORN)
g.set(hx - 6, hy - 9, GLOW); g.set(hx - 1, hy - 10, GLOW)
# глаз крупный
g.rect(hx + 1, hy - 2, hx + 3, hy, WHITE)
g.rect(hx + 2, hy - 1, hx + 3, hy, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("magma_dragon", g.to_image())
    print("ok")
