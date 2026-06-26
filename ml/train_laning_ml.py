#!/usr/bin/env python3
"""
Train the shared hybrid laning policy (all heroes): TWO small MLP heads exported to Lua.

  head 'lasthit' : should I step forward into harass to secure a risky last hit?   (6 inputs)
  head 'deny'    : should I step up to deny this ally creep right now?              (5 inputs)

Guaranteed last-hits are NOT learned -- the rule layer always takes them. These heads only
decide the JUDGEMENT (step-up / deny under contest), so the model can never lose free CS.

Same pipeline as the Sniper experiment:
  synthetic expert bootstrap  ->  (optional) real outcome data  ->  numpy MLP  ->  Lua export
Real data: ml/data/laning_lasthit.jsonl / laning_deny.jsonl  (see parse_console_log.py).

Feature order MUST match bots/FunLib/ml/laning_ml_policy.lua.
"""

import os
import json
import numpy as np

rng = np.random.default_rng(11)

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ML_DIR = os.path.join(REPO_ROOT, "bots", "FunLib", "ml")
DATA_DIR = os.path.join(REPO_ROOT, "ml", "data")
HIDDEN = 8
THRESHOLD = 0.5

LASTHIT_FEATURES = ["creepHP", "dmgRatio", "enemiesNear", "alliesNear", "myHP", "timeNorm"]
DENY_FEATURES    = ["creepHP", "dmgRatio", "enemiesNear", "myHP", "timeNorm"]
TRADE_FEATURES   = ["myHP", "enemyHP", "rangeAdv", "distNorm", "enemyCreepsNear",
                    "enemiesNear", "alliesNear", "enemyBusy", "timeNorm"]


# ----------------------------------------------------------------------------------------------------
# Expert labels (smoother judgement than the rule's fixed thresholds). goodness in [0,1].
# ----------------------------------------------------------------------------------------------------
def lasthit_goodness(f):
    creepHP, dmgRatio, enemiesNear, alliesNear, myHP, _t = f
    g = 0.50
    g += 0.30 * (1.0 - creepHP)                 # creep nearly dead -> grab it
    g += 0.20 * max(0.0, dmgRatio - 0.40) * 2.5 # can I actually secure it
    g += 0.15 * alliesNear                      # support backup nearby
    g -= 0.55 * enemiesNear                     # walking into harass
    g -= 0.35 * (1.0 if myHP < 0.40 else 0.0)   # too low to trade
    return float(np.clip(g, 0.0, 1.0))


def deny_goodness(f):
    creepHP, dmgRatio, enemiesNear, myHP, _t = f
    g = 0.55
    g += 0.30 * (max(0.0, 0.5 - creepHP) * 2.0) # deny window opens under 50%
    g += 0.15 * max(0.0, dmgRatio - 0.40) * 2.5
    g -= 0.45 * enemiesNear                      # contest / harass risk
    g -= 0.30 * (1.0 if myHP < 0.35 else 0.0)
    return float(np.clip(g, 0.0, 1.0))


def trade_goodness(f):
    myHP, enemyHP, rangeAdv, dist, enemyCreeps, enemiesNear, alliesNear, enemyBusy, _t = f
    g = 0.45
    g += 0.35 * max(0.0, rangeAdv - 0.5) * 2.0   # outranging them = nearly free trade
    g += 0.20 * enemyBusy                         # they're last-hitting -> free hit
    g += 0.15 * (myHP - 0.5)                      # need an HP buffer to trade
    g -= 0.10 * enemyHP                           # mild: better when they're already lower
    g -= 0.45 * enemyCreeps                       # creep aggro will punish me
    g -= 0.40 * enemiesNear                       # gank / focus risk
    g += 0.10 * alliesNear                        # backup makes trades safer
    g -= 0.35 * (1.0 if myHP < 0.35 else 0.0)     # too low to trade
    g -= 0.50 * (1.0 if dist > 0.8 else 0.0)      # out of reach
    return float(np.clip(g, 0.0, 1.0))


def sample_trade():
    return np.array([rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, 1),
                     rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, 1),
                     float(rng.random() < 0.4), rng.uniform(0, 1)])


def sample_lasthit():
    creepHP = rng.beta(2, 3)        # candidate creeps skew lowish
    return np.array([creepHP, rng.uniform(0, 1), rng.uniform(0, 1),
                     rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, 1)])


def sample_deny():
    creepHP = rng.beta(2, 4)        # deny candidates are low HP
    return np.array([creepHP, rng.uniform(0, 1), rng.uniform(0, 1),
                     rng.uniform(0, 1), rng.uniform(0, 1)])


def synth(sampler, scorer, n=20000):
    X = np.stack([sampler() for _ in range(n)])
    y = np.array([scorer(r) for r in X]).reshape(-1, 1)
    return X, y


def load_real(name, n_in):
    path = os.path.join(DATA_DIR, name)
    if not os.path.exists(path):
        return None
    X, y = [], []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            if len(row.get("features", [])) != n_in:
                continue
            X.append(row["features"]); y.append([row["label"]])
    if not X:
        return None
    return np.array(X, dtype=np.float64), np.array(y, dtype=np.float64)


# ----------------------------------------------------------------------------------------------------
# numpy MLP (variable input dim): standardise -> Linear(n,H) -> relu -> Linear(H,1) -> sigmoid
# ----------------------------------------------------------------------------------------------------
def sigmoid(z): return 1.0 / (1.0 + np.exp(-np.clip(z, -30, 30)))


def train(X, y, epochs=300, lr=0.05, batch=256):
    n_in = X.shape[1]
    mean, std = X.mean(0), X.std(0); std[std == 0] = 1.0
    Xn = (X - mean) / std
    W1 = rng.normal(0, np.sqrt(2.0 / n_in), (HIDDEN, n_in)); b1 = np.zeros(HIDDEN)
    W2 = rng.normal(0, np.sqrt(2.0 / HIDDEN), (1, HIDDEN));  b2 = np.zeros(1)
    n = Xn.shape[0]
    for ep in range(epochs):
        idx = rng.permutation(n)
        for s in range(0, n, batch):
            bi = idx[s:s + batch]; xb, yb = Xn[bi], y[bi]
            z1 = xb @ W1.T + b1; a1 = np.maximum(z1, 0)
            out = sigmoid(a1 @ W2.T + b2)
            d_out = (out - yb) * out * (1 - out) * (2.0 / xb.shape[0])
            gW2 = d_out.T @ a1; gb2 = d_out.sum(0)
            d_z1 = (d_out @ W2) * (z1 > 0)
            gW1 = d_z1.T @ xb; gb1 = d_z1.sum(0)
            W2 -= lr * gW2; b2 -= lr * gb2; W1 -= lr * gW1; b1 -= lr * gb1
    return dict(mean=mean, std=std, W1=W1, b1=b1, W2=W2, b2=b2)


def lua_replica(m, feats):
    n_in = len(feats)
    x = [(feats[i] - m["mean"][i]) / (m["std"][i] or 1.0) for i in range(n_in)]
    h = [max(0.0, m["b1"][o] + sum(m["W1"][o][i] * x[i] for i in range(n_in))) for o in range(HIDDEN)]
    s = m["b2"][0] + sum(m["W2"][0][j] * h[j] for j in range(HIDDEN))
    return 1.0 / (1.0 + np.exp(-np.clip(s, -30, 30)))


def fmt_vec(v): return "{" + ", ".join(f"{x:.8g}" for x in v) + "}"
def fmt_mat(M): return "{\n" + ",\n".join("\t\t" + fmt_vec(r) for r in M) + "\n\t}"


def export(m, path, feats):
    n_in = len(feats)
    lua = f"""----------------------------------------------------------------------------------------------------
--- AUTO-GENERATED by ml/train_laning_cs.py -- DO NOT EDIT BY HAND.
--- MLP: standardise -> Linear({n_in},{HIDDEN}) -> relu -> Linear({HIDDEN},1) -> sigmoid
--- Feature order: {", ".join(feats)}
----------------------------------------------------------------------------------------------------

return {{
\tthreshold = {THRESHOLD},
\tinputMean = {fmt_vec(m['mean'])},
\tinputStd  = {fmt_vec(m['std'])},
\tlayers = {{
\t\t{{ act = 'relu', b = {fmt_vec(m['b1'])}, W = {fmt_mat(m['W1'])} }},
\t\t{{ act = 'sigmoid', b = {fmt_vec(m['b2'])}, W = {fmt_mat(m['W2'])} }},
\t}},
}}
"""
    with open(path, "w") as fh:
        fh.write(lua)


def build_head(name, jsonl, feats, sampler, scorer, out_lua, cases):
    n_in = len(feats)
    real = load_real(jsonl, n_in)
    if real is not None:
        X, y = real
        print(f"[{name}] REAL data: {X.shape[0]} rows ({(y>=0.5).mean():.0%} commit)"
              + ("  (small sample!)" if X.shape[0] < 500 else ""))
    else:
        X, y = synth(sampler, scorer)
        print(f"[{name}] synthetic: {X.shape[0]} rows ({(y>0.5).mean():.0%} commit)")

    m = train(X, y)
    export(m, out_lua, feats)

    Xt = np.stack([sampler() for _ in range(2000)])
    Xn = (Xt - m["mean"]) / m["std"]
    np_out = sigmoid(np.maximum(Xn @ m["W1"].T + m["b1"], 0) @ m["W2"].T + m["b2"]).ravel()
    lua_out = np.array([lua_replica(m, r) for r in Xt])
    print(f"        wrote {os.path.relpath(out_lua, REPO_ROOT)}  "
          f"parity max-err = {np.abs(np_out - lua_out).max():.1e}")
    for label, feat in cases:
        d = lua_replica(m, np.array(feat, float))
        print(f"        {label:38s} -> {d:.3f}  {'COMMIT' if d >= THRESHOLD else 'hold'}")


def main():
    build_head(
        "lasthit", "laning_lasthit.jsonl", LASTHIT_FEATURES, sample_lasthit, lasthit_goodness,
        os.path.join(ML_DIR, "laning_lasthit_weights.lua"),
        [   # creepHP, dmgRatio, enemiesNear, alliesNear, myHP, timeNorm
            ("dying creep, safe lane",            [0.10, 0.8, 0.0, 0.3, 0.9, 0.3]),
            ("dying creep, 2 enemies harassing",  [0.10, 0.8, 0.7, 0.0, 0.5, 0.3]),
            ("healthy creep, low dmg, risky",     [0.70, 0.3, 0.7, 0.0, 0.4, 0.3]),
            ("dying creep but I'm at 25% hp",     [0.12, 0.8, 0.5, 0.0, 0.25, 0.3]),
        ])
    print()
    build_head(
        "deny", "laning_deny.jsonl", DENY_FEATURES, sample_deny, deny_goodness,
        os.path.join(ML_DIR, "laning_deny_weights.lua"),
        [   # creepHP, dmgRatio, enemiesNear, myHP, timeNorm
            ("ally creep 20%, lane clear",        [0.20, 0.8, 0.0, 0.9, 0.3]),
            ("ally creep 20%, 2 enemies contest", [0.20, 0.8, 0.7, 0.5, 0.3]),
            ("ally creep 45%, low dmg",           [0.45, 0.3, 0.2, 0.8, 0.3]),
            ("ally creep 20% but I'm at 20% hp",  [0.20, 0.8, 0.4, 0.20, 0.3]),
        ])
    print()
    build_head(
        "trade", "laning_trade.jsonl", TRADE_FEATURES, sample_trade, trade_goodness,
        os.path.join(ML_DIR, "laning_trade_weights.lua"),
        [   # myHP, enemyHP, rangeAdv, dist, enemyCreepsNear, enemiesNear, alliesNear, enemyBusy, time
            ("I outrange, enemy last-hitting",    [0.9, 0.7, 0.85, 0.4, 0.0, 0.3, 0.0, 1, 0.3]),
            ("even range, enemy creeps on me",    [0.8, 0.7, 0.50, 0.4, 0.8, 0.3, 0.0, 0, 0.3]),
            ("outrange but I'm at 25% hp",        [0.25, 0.6, 0.80, 0.4, 0.0, 0.3, 0.0, 0, 0.3]),
            ("outrange but 2 enemies near (gank)",[0.8, 0.6, 0.80, 0.4, 0.0, 0.7, 0.0, 0, 0.3]),
        ])


if __name__ == "__main__":
    main()
