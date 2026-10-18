"""Фон «Призрачный пруд» 135x240 (ивент Хэллоуин). Сумеречная фиолетово-бирюзовая вода, луна у поверхности,
ровный тёмный центр для рыб, на дне тыквы, водоросли и силуэт затонувшей ограды."""
import math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bgkit import *

rng = random.Random(7)
WATER = ["#5B4F8A", "#463F78", "#363266", "#2A2853", "#201F43", "#171733"]
MOON, MOON_H = "#E9E3C4", "#8C86A8"
FAR = "#2B2550"
ROCK = ["#3A3160", "#2A2348", "#1B1733"]
WEED, WEED_D = "#3E7A6A", "#24504A"
PUMP, PUMP_D, PUMP_L, STEM = "#E8801E", "#A9520F", "#FFC15A", "#4F7A2E"
FENCE = "#151227"
WISP = "#8CF0D0"


def smooth(a, b, x):
    u = np.clip((x - a) / (b - a), 0, 1)
    return u * u * (3 - 2 * u)


yf = YY / (H - 1.0)
t = 0.4 + 1.6 * smooth(0.0, 0.34, yf)
t += 2.4 * smooth(0.66, 1.0, yf)
t += 1.0 * smooth(0.78, 1.0, edge(XX))
# отсвет луны сверху
t -= 1.3 * np.exp(-(((XX - 96) / 26.0) ** 2 + ((YY - 10) / 30.0) ** 2))
t = np.clip(t, 0, 5)
c = Canvas(quantize(t, WATER, 0.3))

# луна, искажённая поверхностью воды
c.ell(96, 8, 9, 5, MOON_H)
c.ell(96, 8, 7, 4, MOON)
for x in range(86, 107, 3):
    c.pt(x, 14, MOON_H)

# дальние холмы и ограда
def SY(x):
    return int(204 + 6 * math.sin(x / 17.0) + 3 * math.sin(x / 7.0 + 1))
for x in range(W):
    for y in range(SY(x) - 14 - int(5 * math.sin(x / 11.0 + 2)), SY(x)):
        c.pt(x, y, FAR)
for x in range(10, 70, 7):                       # затонувшая ограда (пики)
    base = SY(x) - 10
    c.rect(x, base - 14, x + 1, base, FENCE)
    c.pt(x, base - 15, FENCE); c.pt(x + 1, base - 15, FENCE); c.pt(x, base - 16, FENCE)
c.rect(8, SY(30) - 20, 72, SY(30) - 19, FENCE)
c.rect(8, SY(30) - 14, 72, SY(30) - 13, FENCE)

# дно
for x in range(W):
    for y in range(SY(x), H):
        d = y - SY(x)
        col = ROCK[0] if d < 2 else ROCK[1] if d < 12 else ROCK[2]
        if d >= 2 and (x * 7 + y * 3) % 23 == 0:
            col = ROCK[0]
        c.pt(x, y, col)

# водоросли
for x0, h in [(6, 34), (24, 22), (80, 28), (118, 40), (128, 26)]:
    for k in range(h):
        x = x0 + round(2 * math.sin(k / 5.0 + x0))
        y = SY(x0) - k
        c.pt(x, y, WEED if k % 6 < 4 else WEED_D)
        c.pt(x + 1, y, WEED_D)

# тыквы на дне
def pumpkin(cx, cy, r, face):
    c.ell(cx, cy, r + 2, r, PUMP)
    for dx in (-r // 2 - 1, r // 2 + 1):
        for y in range(cy - r + 1, cy + r):
            c.pt(cx + dx, y, PUMP_D)
    c.ell(cx - 2, cy - r // 2, max(1, r // 2), 1, PUMP_L)
    c.rect(cx, cy - r - 2, cx + 1, cy - r, STEM)
    if face:
        # светящиеся вырезанные глаза-треугольники и улыбка
        for ex in (cx - 3, cx + 2):
            c.pt(ex, cy - 2, MOON); c.pt(ex + 1, cy - 2, MOON); c.pt(ex, cy - 1, MOON)
        c.rect(cx - 3, cy + 1, cx + 3, cy + 1, MOON)
        c.pt(cx - 4, cy, MOON); c.pt(cx + 4, cy, MOON); c.pt(cx, cy + 2, PUMP_D)
pumpkin(44, SY(44) + 3, 5, True)
pumpkin(100, SY(100) + 5, 4, False)
pumpkin(60, SY(60) + 8, 3, False)

# огоньки-«души» и пузырьки
for x, y in [(20, 70), (118, 82), (12, 150), (126, 160), (70, 30)]:
    c.pt(x, y, WISP)
for x, y in [(34, 190), (36, 178), (35, 166), (110, 186), (112, 172), (64, 22), (30, 40)]:
    c.pt(x, y, MOON_H)

finish(c, "bg_haunted")
