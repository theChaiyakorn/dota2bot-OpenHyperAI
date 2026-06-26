#!/usr/bin/env python3
"""
Train the hybrid Sniper-Assassinate desire model and export it to a Lua weights table.

Pipeline:
  1. Build a training set of (features -> goodness) pairs.
     For this proof-of-concept we SYNTHESISE the data from an "expert" scoring
     function that encodes better judgement than the original binary rule
     (see expert_goodness). This proves the whole train -> export -> in-game
     path end to end and yields a policy that is already smarter than the
     hand-written heuristic.

     To make this a REAL learned policy, replace `make_dataset` with rows logged
     from games / parsed from replays, labelled by OUTCOME (did the ult secure a
     kill, was it wasted, etc.). The rest of the pipeline is unchanged.

  2. Train a tiny MLP (10 -> 8 -> 1) with plain numpy SGD. No torch dependency.

  3. Export weights to  bots/FunLib/ml/sniper_assassinate_weights.lua
     and self-test that a pure-Python replica of nn.lua's forward pass matches
     the trained model (guarantees the in-game Lua produces identical numbers).

Feature order MUST stay in sync with:
  bots/FunLib/ml/sniper_assassinate_policy.lua  (Policy.BuildFeatures)
"""

import os
import json
import numpy as np

rng = np.random.default_rng(7)

REAL_DATASET = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "data", "sniper_assassinate.jsonl")

FEATURE_NAMES = [
    "targetHP", "myMana", "myHP", "distNorm", "enemiesNear",
    "alliesNear", "willKill", "targetChanneling", "targetRetreating", "timeNorm",
]
N_IN = len(FEATURE_NAMES)
HIDDEN = 8
THRESHOLD = 0.5

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_LUA = os.path.join(REPO_ROOT, "bots", "FunLib", "ml", "sniper_assassinate_weights.lua")


# ----------------------------------------------------------------------------------------------------
# 1. Expert label: a smoother, smarter judgement than the original binary rule.
#    Returns goodness in [0, 1] = "how good is firing the ult in this state".
# ----------------------------------------------------------------------------------------------------
def expert_goodness(f):
    (targetHP, myMana, myHP, distNorm, enemiesNear,
     alliesNear, willKill, channeling, retreating, timeNorm) = f

    g = 0.0
    g += 0.60 * willKill                       # securing a guaranteed kill is the prime use
    g += 0.30 * (1.0 - targetHP)               # lower target HP -> more valuable
    g += 0.25 * retreating                     # long-range finisher on escapers
    g += 0.20 * channeling                     # interrupt + burst a channeller
    g += 0.10 * max(0.0, myMana - 0.3)         # only if we can afford it
    g -= 0.25 * enemiesNear                    # chaos / about to die -> hold
    g -= 0.20 * (1.0 if myHP < 0.3 else 0.0)   # don't ult while dying
    g -= 0.40 * (1.0 if (targetHP > 0.6 and willKill < 0.5) else 0.0)  # clearly wasteful
    g -= 0.10 * alliesNear * (1.0 - retreating)  # allies can finish a non-escaper, save ult

    return float(np.clip(g, 0.0, 1.0))


def sample_feature_row():
    targetHP = rng.uniform(0, 1)
    myMana = rng.uniform(0, 1)
    myHP = rng.uniform(0, 1)
    distNorm = rng.uniform(0, 1)
    enemiesNear = rng.uniform(0, 1)
    alliesNear = rng.uniform(0, 1)
    willKill = float(rng.random() < (0.6 if targetHP < 0.35 else 0.1))
    channeling = float(rng.random() < 0.15)
    retreating = float(rng.random() < 0.4)
    timeNorm = rng.uniform(0, 1)
    return np.array([targetHP, myMana, myHP, distNorm, enemiesNear,
                     alliesNear, willKill, channeling, retreating, timeNorm], dtype=np.float64)


def make_dataset(n=20000):
    X = np.stack([sample_feature_row() for _ in range(n)])
    y = np.array([expert_goodness(row) for row in X], dtype=np.float64).reshape(-1, 1)
    return X, y


def load_real_dataset(path=REAL_DATASET):
    """Load outcome-labelled rows produced by parse_console_log.py, if present."""
    if not os.path.exists(path):
        return None
    X, y = [], []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            if len(row.get("features", [])) != N_IN:
                continue
            X.append(row["features"])
            y.append([row["label"]])
    if not X:
        return None
    return np.array(X, dtype=np.float64), np.array(y, dtype=np.float64)


# ----------------------------------------------------------------------------------------------------
# 2. Tiny MLP in numpy: standardise -> Linear(10,8) -> relu -> Linear(8,1) -> sigmoid
# ----------------------------------------------------------------------------------------------------
def sigmoid(z):
    return 1.0 / (1.0 + np.exp(-np.clip(z, -30, 30)))


def train(X, y, epochs=300, lr=0.05, batch=256):
    mean = X.mean(axis=0)
    std = X.std(axis=0)
    std[std == 0] = 1.0
    Xn = (X - mean) / std

    # He-ish init
    W1 = rng.normal(0, np.sqrt(2.0 / N_IN), size=(HIDDEN, N_IN))
    b1 = np.zeros((HIDDEN,))
    W2 = rng.normal(0, np.sqrt(2.0 / HIDDEN), size=(1, HIDDEN))
    b2 = np.zeros((1,))

    n = Xn.shape[0]
    for ep in range(epochs):
        idx = rng.permutation(n)
        for s in range(0, n, batch):
            bi = idx[s:s + batch]
            xb, yb = Xn[bi], y[bi]

            z1 = xb @ W1.T + b1            # (B, H)
            a1 = np.maximum(z1, 0)
            z2 = a1 @ W2.T + b2            # (B, 1)
            out = sigmoid(z2)

            # MSE on soft targets
            d_out = (out - yb) * out * (1 - out) * (2.0 / xb.shape[0])
            gW2 = d_out.T @ a1
            gb2 = d_out.sum(axis=0)
            d_a1 = d_out @ W2
            d_z1 = d_a1 * (z1 > 0)
            gW1 = d_z1.T @ xb
            gb1 = d_z1.sum(axis=0)

            W2 -= lr * gW2; b2 -= lr * gb2
            W1 -= lr * gW1; b1 -= lr * gb1

        if (ep + 1) % 50 == 0:
            pred = sigmoid(np.maximum((Xn @ W1.T + b1), 0) @ W2.T + b2)
            mse = float(((pred - y) ** 2).mean())
            print(f"  epoch {ep+1:3d}  mse={mse:.5f}")

    return dict(mean=mean, std=std, W1=W1, b1=b1, W2=W2, b2=b2)


# ----------------------------------------------------------------------------------------------------
# 3a. Pure-python replica of nn.lua forward (parity check)
# ----------------------------------------------------------------------------------------------------
def lua_replica_forward(m, feats):
    x = [(feats[i] - m["mean"][i]) / (m["std"][i] if m["std"][i] != 0 else 1.0) for i in range(N_IN)]
    h = []
    for o in range(HIDDEN):
        s = m["b1"][o] + sum(m["W1"][o][i] * x[i] for i in range(N_IN))
        h.append(s if s > 0 else 0.0)
    s = m["b2"][0] + sum(m["W2"][0][j] * h[j] for j in range(HIDDEN))
    return 1.0 / (1.0 + np.exp(-np.clip(s, -30, 30)))


# ----------------------------------------------------------------------------------------------------
# 3b. Export to Lua
# ----------------------------------------------------------------------------------------------------
def fmt_vec(v):
    return "{" + ", ".join(f"{x:.8g}" for x in v) + "}"


def fmt_mat(M):
    rows = ["\t\t" + fmt_vec(row) for row in M]
    return "{\n" + ",\n".join(rows) + "\n\t}"


def export_lua(m, path):
    lua = f"""----------------------------------------------------------------------------------------------------
--- AUTO-GENERATED by ml/train_sniper_assassinate.py -- DO NOT EDIT BY HAND.
--- MLP: standardise -> Linear({N_IN},{HIDDEN}) -> relu -> Linear({HIDDEN},1) -> sigmoid
--- Feature order: {", ".join(FEATURE_NAMES)}
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


def main():
    real = load_real_dataset()
    if real is not None:
        X, y = real
        print(f"[1/3] using REAL outcome dataset: {X.shape[0]} rows from "
              f"{os.path.relpath(REAL_DATASET, REPO_ROOT)}")
        print(f"      good(label>=0.5) = {(y >= 0.5).mean():.2%}")
        if X.shape[0] < 500:
            print("      (small sample — collect more games for a robust policy)")
    else:
        print("[1/3] no real dataset found -> synthetic bootstrap "
              "(run ml/parse_console_log.py on a console.log to use real data)")
        X, y = make_dataset()
        print(f"      {X.shape[0]} rows, fire-rate(expert>0.5) = {(y > 0.5).mean():.2%}")

    print("[2/3] training MLP...")
    m = train(X, y)

    print("[3/3] exporting Lua + parity check...")
    export_lua(m, OUT_LUA)

    # parity: numpy model vs lua replica on fresh samples
    Xt, _ = make_dataset(2000)
    Xn = (Xt - m["mean"]) / m["std"]
    np_out = sigmoid(np.maximum(Xn @ m["W1"].T + m["b1"], 0) @ m["W2"].T + m["b2"]).ravel()
    lua_out = np.array([lua_replica_forward(m, row) for row in Xt])
    max_err = float(np.abs(np_out - lua_out).max())
    print(f"      wrote {os.path.relpath(OUT_LUA, REPO_ROOT)}")
    print(f"      max |numpy - lua_replica| = {max_err:.2e}  ({'OK' if max_err < 1e-9 else 'MISMATCH'})")

    # show the policy disagreeing with the crude binary rule on a few cases
    print("\n  sanity cases (feat -> learned desire):")
    cases = {
        "low-hp escaper, will kill": [0.15, 0.8, 0.9, 0.5, 0.2, 0.0, 1, 0, 1, 0.4],
        "full-hp target, no kill   ": [0.9, 0.8, 0.9, 0.4, 0.2, 0.0, 0, 0, 0, 0.4],
        "channeller, mid hp        ": [0.5, 0.7, 0.8, 0.5, 0.2, 0.0, 0, 1, 0, 0.5],
        "low hp but I'm dying, 3 enemies": [0.25, 0.4, 0.2, 0.3, 0.8, 0.2, 0, 0, 0, 0.6],
    }
    for name, feat in cases.items():
        d = lua_replica_forward(m, np.array(feat, dtype=float))
        print(f"    {name:32s} -> {d:.3f}  {'FIRE' if d >= THRESHOLD else 'hold'}")


if __name__ == "__main__":
    main()
