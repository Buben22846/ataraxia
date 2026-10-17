"""Грубая симуляция прогресса активного игрока: когда он откроет вулкан и лёд.
Стратегия: тратить монеты на паки текущего аквариума, когда есть место; иначе на место; потом на следующий аквариум."""
import random
random.seed(1)
TICK=5; GROW=[(0,1),(600,1.5),(1800,2)]
def stage(a):
    m=1
    for f,x in GROW:
        if a>=f:m=x
    return m
VAR=[("n",1,88),("g",2,11),("r",5,1)]
def variant():
    r=random.uniform(0,100);acc=0
    for _,m,w in VAR:
        acc+=w
        if r<=acc:return m
    return 1
T={"lagoon":dict(price=0,pack=50,mult=1,sp={"c":[1,2],"r":[4],"e":[10],"l":[25]}),
   "volcano":dict(price=5000,pack=400,mult=4,sp={"c":[8,12],"r":[32],"e":[80],"l":[200]}),
   "arctic":dict(price=150000,pack=3000,mult=10,sp={"c":[60,100],"r":[240],"e":[600],"l":[1500]})}
SLOT={6:500,7:2000,8:8000,9:30000,10:100000}
def roll(t):
    r=random.uniform(0,100)
    k="c" if r<70 else "r" if r<92 else "e" if r<99 else "l"
    return random.choice(T[t]["sp"][k])*variant()
coins=100;tanks={"lagoon":{"slots":5,"fish":[]}};order=["lagoon","volcano","arctic"]
t=0;log={}
while t<6*3600:
    # доход
    for n,tk in tanks.items():
        for f in tk["fish"]:
            coins+=f[0]*stage(t-f[1])
    t+=TICK
    # покупки (активный игрок заходит раз в 5 с — оптимистично; считаем и "раз в минуту")
    if t%60: continue
    for _ in range(50):
        bought=False
        nxt=next((o for o in order if o not in tanks),None)
        cur=[o for o in order if o in tanks][-1]
        if nxt and coins>=T[nxt]["price"] and all(len(tanks[o]["fish"])>=tanks[o]["slots"] for o in tanks):
            coins-=T[nxt]["price"];tanks[nxt]={"slots":5,"fish":[]};log[nxt]=t;bought=True
        else:
            for o in reversed([x for x in order if x in tanks]):
                tk=tanks[o]
                if len(tk["fish"])<tk["slots"] and coins>=T[o]["pack"]:
                    coins-=T[o]["pack"];tk["fish"].append((roll(o),t));bought=True;break
        if not bought:break
print({k:round(v/60) for k,v in log.items()},"мин. Монет:",int(coins))
print({o:len(tk["fish"]) for o,tk in tanks.items()})
