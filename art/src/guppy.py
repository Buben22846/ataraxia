"""Эталонный спрайт стиля «Атараксии»: гуппи (лагуна, обычная). Рыба смотрит ВПРАВО.
Рисуем фигурами (Grid), в конце — контур. До 10 цветов, холст 32x32."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid, save_sprite

OUT = "#1d2b3a"     # контур
BODY = "#f4a261"    # тело
LIGHT = "#ffd29a"   # свет сверху
SHADE = "#d9822b"   # тень снизу
FIN = "#e76f51"     # плавники и хвост
SPOT = "#f9c74f"    # жёлтые пятна на хвосте
WHITE = "#ffffff"

g = Grid()
# хвост-веер (слева), плавники
g.poly([(9, 15), (1, 8), (3, 16), (1, 24), (9, 17)], FIN)
g.poly([(8, 15), (4, 12), (5, 16), (4, 20), (8, 17)], SPOT)
g.poly([(16, 10), (20, 5), (23, 11)], FIN)          # спинной плавник
g.poly([(15, 22), (18, 25), (21, 22)], FIN)         # нижний плавник
# тело
g.ellipse(19, 16, 10, 6, BODY)
g.ellipse(19, 13, 8, 2, LIGHT, only_where="filled") # блик сверху
g.ellipse(19, 20, 8, 1, SHADE, only_where="filled") # тень снизу
# глаз
g.rect(24, 14, 25, 15, WHITE)
g.set(25, 15, OUT)
g.outline(OUT)
g.recenter()

if __name__ == "__main__":
    save_sprite("guppy", g.to_image())
    print("ok")
