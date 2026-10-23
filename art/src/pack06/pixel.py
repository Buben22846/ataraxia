"""Мини-инструмент для рисования пиксель-арта текстом.

Спрайт — список строк одинаковой длины. Каждый символ — цвет из палитры, '.' — прозрачность.
Рисунок автоматически центрируется на холсте 32x32 (рыба смотрит ВПРАВО).

Пример:
    from pixel import sprite, save_sprite
    img = sprite(["..oo..", ".obbo.", "..oo.."], {"o": "#1d2b3a", "b": "#f4a261"})
    save_sprite("guppy", img)       # art/png/guppy.png + art/preview/guppy_x8.png
"""
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_PNG = os.path.join(HERE, "png")
OUT_PREVIEW = os.path.join(HERE, "preview")
CANVAS = 32
MAX_COLORS = 10  # правило стиля: не больше 10 цветов на спрайт (включая контур)


def _hex(c):
    c = c.lstrip("#")
    return tuple(int(c[i : i + 2], 16) for i in (0, 2, 4)) + (255,)


def sprite(rows, palette, canvas=CANVAS):
    """Собирает RGBA-картинку canvas x canvas из строк и палитры."""
    if not rows:
        raise ValueError("пустой спрайт")
    width = len(rows[0])
    for i, row in enumerate(rows):
        if len(row) != width:
            raise ValueError(f"строка {i} имеет длину {len(row)}, а должна быть {width}: {row!r}")
    if width > canvas or len(rows) > canvas:
        raise ValueError(f"спрайт {width}x{len(rows)} больше холста {canvas}x{canvas}")
    used = set("".join(rows)) - {"."}
    missing = used - set(palette)
    if missing:
        raise ValueError(f"нет цвета в палитре для символов: {sorted(missing)}")
    if len(used) > MAX_COLORS:
        raise ValueError(f"использовано {len(used)} цветов, максимум {MAX_COLORS}")
    img = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    ox = (canvas - width) // 2
    oy = (canvas - len(rows)) // 2
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((ox + x, oy + y), _hex(palette[ch]))
    return img


def save_sprite(name, img, scale=8):
    """Сохраняет оригинал 32x32 и увеличенное превью (для просмотра глазами)."""
    os.makedirs(OUT_PNG, exist_ok=True)
    os.makedirs(OUT_PREVIEW, exist_ok=True)
    img.save(os.path.join(OUT_PNG, name + ".png"))
    big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    # светло-серая шахматка под превью, чтобы видеть прозрачность
    bg = Image.new("RGBA", big.size, (200, 210, 220, 255))
    for y in range(0, big.height, 16):
        for x in range(0, big.width, 16):
            if (x // 16 + y // 16) % 2:
                for yy in range(y, min(y + 16, big.height)):
                    for xx in range(x, min(x + 16, big.width)):
                        bg.putpixel((xx, yy), (185, 196, 208, 255))
    bg.alpha_composite(big)
    bg.save(os.path.join(OUT_PREVIEW, f"{name}_x{scale}.png"))


def contact_sheet(names, filename="sheet.png", scale=6, on_color=(20, 110, 140, 255)):
    """Лист из нескольких спрайтов на цвете воды — смотреть, как рыбы выглядят вместе."""
    imgs = [Image.open(os.path.join(OUT_PNG, n + ".png")).convert("RGBA") for n in names]
    cell = CANVAS * scale
    sheet = Image.new("RGBA", (cell * len(imgs), cell), on_color)
    for i, im in enumerate(imgs):
        big = im.resize((cell, cell), Image.NEAREST)
        sheet.alpha_composite(big, (i * cell, 0))
    sheet.save(os.path.join(OUT_PREVIEW, filename))
    return os.path.join(OUT_PREVIEW, filename)


class Grid:
    """Холст для рисования фигурами. Цвета задаются сразу строкой '#rrggbb'.

    Рыба смотрит ВПРАВО. Порядок: сначала крупные формы (хвост, тело), потом блики и тени,
    глаз, и в самом конце outline() — он обводит всё нарисованное тёмным контуром в 1 пиксель.
    """

    def __init__(self, w=CANVAS, h=CANVAS):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def set(self, x, y, color):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = color

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def rect(self, x0, y0, x1, y1, color):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, color)

    def ellipse(self, cx, cy, rx, ry, color, only_where=None):
        """Закрашенный эллипс. only_where='filled' — красить только поверх уже нарисованного (для бликов/теней)."""
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1.0:
                    if only_where == "filled" and self.get(x, y) is None:
                        continue
                    self.set(x, y, color)

    def poly(self, points, color):
        """Закрашенный многоугольник по списку (x, y)."""
        ys = [p[1] for p in points]
        for y in range(min(ys), max(ys) + 1):
            xs = []
            n = len(points)
            for i in range(n):
                (x1, y1), (x2, y2) = points[i], points[(i + 1) % n]
                if (y1 <= y < y2) or (y2 <= y < y1):
                    xs.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(round(xs[i]), round(xs[i + 1]) + 1):
                    self.set(x, y, color)

    def line(self, x0, y0, x1, y1, color):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(steps + 1):
            self.set(round(x0 + (x1 - x0) * i / steps), round(y0 + (y1 - y0) * i / steps), color)

    def outline(self, color):
        """Обводит все нарисованные пиксели контуром в 1 пиксель (по 4 соседям)."""
        add = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        if self.get(x + dx, y + dy) not in (None, color):
                            add.append((x, y))
                            break
        for x, y in add:
            self.px[y][x] = color

    def flip(self):
        """Зеркально отразить по горизонтали (если нарисовали смотрящей влево)."""
        for row in self.px:
            row.reverse()

    def recenter(self):
        """Сдвинуть рисунок в центр холста."""
        xs = [x for y in range(self.h) for x in range(self.w) if self.px[y][x] is not None]
        ys = [y for y in range(self.h) for x in range(self.w) if self.px[y][x] is not None]
        if not xs:
            return
        dx = (self.w - 1) // 2 - (min(xs) + max(xs)) // 2
        dy = (self.h - 1) // 2 - (min(ys) + max(ys)) // 2
        new = [[None] * self.w for _ in range(self.h)]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h:
                        new[ny][nx] = self.px[y][x]
        self.px = new

    def to_image(self):
        colors = {c for row in self.px for c in row if c is not None}
        if len(colors) > MAX_COLORS:
            raise ValueError(f"использовано {len(colors)} цветов, максимум {MAX_COLORS}: {sorted(colors)}")
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    img.putpixel((x, y), _hex(self.px[y][x]))
        return img



if __name__ == "__main__":
    sys.exit("Это библиотека: импортируйте её из art/src/*.py")
