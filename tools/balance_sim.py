"""Симуляция прогресса игрока на 30 дней по настоящим числам из FishConfig (скопированы ниже; при смене баланса обновить).
Учтено: паки, места, 4 аквариума, рост рыб, цвета, СЛИЯНИЕ (5 одинаковых -> следующий цвет), БОНУСЫ НАБОРОВ (+10/+25/+50% на аквариум),
офлайн-доход с лимитом (2 ч, с Night Watchman 12 ч), x2 от Poseidon's Blessing.
НЕ учтено (значит, реальный игрок чуть быстрее): музей и билеты, течения и мутации, награда за день, продажа рыбы.
Запуск: python3 tools/balance_sim.py"""
import random

TICKS_PER_MIN = 12  # раз в 5 с
STAGES = [(0, 1), (600, 1.5), (1800, 2)]
VARIANTS = ["normal", "golden", "rainbow"]
VMULT = {"normal": 1, "golden": 2, "rainbow": 5}
VWEIGHT = [88, 11, 1]
TANKS = ["lagoon", "volcano", "arctic", "abyss"]
TPRICE = {"lagoon": 0, "volcano": 5000, "arctic": 4000000, "abyss": 100000000}
PACK = {"lagoon": 50, "volcano": 400, "arctic": 3000, "abyss": 22000}
SLOTMULT = {"lagoon": 1, "volcano": 4, "arctic": 10, "abyss": 25}
SLOTBASE = {6: 500, 7: 2000, 8: 8000, 9: 30000, 10: 100000}
SPECIES = {  # доход за тик, редкость
    "lagoon": {"common": [1, 2], "rare": [4], "epic": [10], "legendary": [25]},
    "volcano": {"common": [8, 12], "rare": [32], "epic": [80], "legendary": [200]},
    "arctic": {"common": [60, 100], "rare": [240], "epic": [600], "legendary": [1500]},
    "abyss": {"common": [400, 700], "rare": [1600], "epic": [4000], "legendary": [10000]},
}
SET_BONUS = [0.10, 0.25, 0.50]


def stage(age):
    m = 1
    for start, mult in STAGES:
        if age >= start:
            m = mult
    return m


class Player:
    def __init__(self, double=False, watch=False):
        self.coins = 100
        self.tanks = {"lagoon": {"slots": 5, "fish": []}}  # fish: [income, variant, born]
        self.seen = {}  # tank -> set((income, variant))
        self.double = double
        self.cap = (12 if watch else 2) * 3600
        self.opened = {"lagoon": 0}

    def set_bonus(self, tank):
        seen = self.seen.get(tank, set())
        all_inc = [i for r in SPECIES[tank].values() for i in r]
        bonus = 0
        if all(any(s[0] == i for s in seen) for i in all_inc):
            bonus += SET_BONUS[0]
        if all((i, "golden") in seen for i in all_inc):
            bonus += SET_BONUS[1]
        if all((i, "rainbow") in seen for i in all_inc):
            bonus += SET_BONUS[2]
        return bonus

    def income_per_tick(self, t):
        total = 0
        for name, tk in self.tanks.items():
            b = 1 + self.set_bonus(name)
            for inc, var, born in tk["fish"]:
                total += round(inc * stage(t - born) * VMULT[var] * b)
        return total * (2 if self.double else 1)

    def add_fish(self, tank, inc, var, t):
        self.tanks[tank]["fish"].append([inc, var, t])
        self.seen.setdefault(tank, set()).add((inc, var))

    def merge(self, tank, t):
        fish = self.tanks[tank]["fish"]
        changed = True
        while changed:
            changed = False
            groups = {}
            for f in fish:
                groups.setdefault((f[0], f[1]), []).append(f)
            for (inc, var), lst in groups.items():
                if len(lst) >= 5 and var != "rainbow":
                    lst.sort(key=lambda f: f[2])  # молодые уходят
                    for f in lst[-5:]:
                        fish.remove(f)
                    self.add_fish(tank, inc, VARIANTS[VARIANTS.index(var) + 1], t)
                    changed = True
                    break

    def roll(self, tank):
        r = random.uniform(0, 100)
        k = "common" if r < 70 else "rare" if r < 92 else "epic" if r < 99 else "legendary"
        inc = random.choice(SPECIES[tank][k])
        var = random.choices(VARIANTS, VWEIGHT)[0]
        return inc, var

    def shop(self, t, log):
        for _ in range(60):
            nxt = next((x for x in TANKS if x not in self.tanks), None)
            if nxt and self.coins >= TPRICE[nxt]:
                self.coins -= TPRICE[nxt]
                self.tanks[nxt] = {"slots": 5, "fish": []}
                log[nxt] = t
                continue
            done = False
            for name in reversed([x for x in TANKS if x in self.tanks]):
                tk = self.tanks[name]
                if len(tk["fish"]) < tk["slots"] and self.coins >= PACK[name]:
                    self.coins -= PACK[name]
                    inc, var = self.roll(name)
                    self.add_fish(name, inc, var, t)
                    self.merge(name, t)
                    done = True
                    break
            if done:
                continue
            top = [x for x in TANKS if x in self.tanks][-1]
            tk = self.tanks[top]
            if len(tk["fish"]) >= tk["slots"] and tk["slots"] < 10:
                price = SLOTBASE[tk["slots"] + 1] * SLOTMULT[top]
                if self.coins >= price:
                    self.coins -= price
                    tk["slots"] += 1
                    continue
            break


def run(name, sessions_per_day, session_min, days=30, double=False, watch=False, seed=1):
    random.seed(seed)
    p = Player(double, watch)
    log = {}
    gap = 24 * 60 // sessions_per_day  # минут между началами сессий
    last_online_end = 0
    for minute in range(days * 24 * 60):
        t = minute * 60
        in_session = (minute % gap) < session_min
        if in_session:
            last_online_end = minute
        offline_ok = (minute - last_online_end) * 60 <= p.cap
        if in_session or offline_ok:
            p.coins += p.income_per_tick(t) * TICKS_PER_MIN
        if in_session:
            p.shop(t, log)
            if "full" not in log and all(len(p.tanks.get(n, {"slots": 0})["fish"]) >= 10 for n in TANKS):
                log["full"] = t  # все 4 аквариума по 10 рыб
    def day(x):
        return f"день {log[x] / 86400:.1f}" if x in log else "не открыт"
    per_hour = p.income_per_tick(days * 86400) * TICKS_PER_MIN * 60
    print(f"{name:32s} вулкан {day('volcano'):10s} лёд {day('arctic'):10s} бездна {day('abyss'):10s} всё заполнено: {day('full'):10s} доход/час в конце: {per_hour:,.0f}")


if __name__ == "__main__":
    print("Когда открываются аквариумы (30 дней симуляции):")
    run("Казуал: 1 заход/день, 20 мин", 1, 20)
    run("Обычный: 3 захода/день, 10 мин", 3, 10)
    run("Активный: 6 заходов/день, 30 мин", 6, 30)
    run("Обычный + Poseidon x2", 3, 10, double=True)
    run("Казуал + Night Watchman", 1, 20, watch=True)
    run("Обычный + x2 + Night Watchman", 3, 10, double=True, watch=True)
