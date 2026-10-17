"""Вспомогательный Grid: все координаты рисуются в «большой» системе и сжимаются к центру на k.
Формы (ellipse/poly/line) масштабируются, мелкие детали (rect/set) сохраняют размер."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from pixel import Grid


class SG(Grid):
    def __init__(self, k):
        super().__init__()
        self.k = k

    def _t(self, v):
        return 16 + (v - 16) * self.k

    def set(self, x, y, color):
        if getattr(self, "k", 1) != 1 and not getattr(self, "_raw", False):
            x, y = round(self._t(x)), round(self._t(y))
        super().set(x, y, color)

    def rect(self, x0, y0, x1, y1, color):
        X, Y = round(self._t(x0)), round(self._t(y0))
        for y in range(Y, Y + (y1 - y0) + 1):
            for x in range(X, X + (x1 - x0) + 1):
                Grid.set(self, x, y, color)

    def ellipse(self, cx, cy, rx, ry, color, only_where=None):
        super().ellipse(self._t(cx), self._t(cy), rx * self.k, ry * self.k, color, only_where)

    def poly(self, points, color):
        super().poly([(round(self._t(x)), round(self._t(y))) for x, y in points], color)

    def line(self, x0, y0, x1, y1, color):
        super().line(round(self._t(x0)), round(self._t(y0)), round(self._t(x1)), round(self._t(y1)), color)
