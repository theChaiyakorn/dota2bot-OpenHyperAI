#!/usr/bin/env python3
"""
Parse Dota's console.log into labelled training sets for every hybrid-ML task.

How the data gets there:
  1. Launch Dota with  -condebug  (writes console output to console.log).
  2. Enable logging: bots load FunLib/ml/datalog.lua with OHA_ML_LOG=true.
  3. Play / sim games, then point this script at the console.log.

It joins DECIDE + OUTCOME lines by id (per task), turns the outcome into a reward + binary
label, and writes one  ml/data/<task>.jsonl  per task. The trainers auto-detect these files.

Console line format (see datalog.lua):
  OHA_ML|<task>|DECIDE |id=..|t=..|feat=f1,..,fN
  OHA_ML|<task>|OUTCOME|id=..|t=..|<field>=..|<field>=..
"""

import os
import sys
import json
import argparse

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(REPO_ROOT, "ml", "data")


# ----------------------------------------------------------------------------------------------------
# Per-task label functions: (features, outcome_kv) -> (reward, label in [0,1])
# ----------------------------------------------------------------------------------------------------
def label_sniper(feat, oc):
    target_died = int(oc["targetDied"]); self_died = int(oc["selfDied"])
    ttd = float(oc["ttd"]); t_end = float(oc["tEnd"]); retreating = feat[8]
    r = 0.0
    if target_died:
        r += 1.0
        if ttd < 2.0: r += 0.3
        if retreating > 0.5: r += 0.4
        if self_died: r -= 0.3
    else:
        if self_died: r -= 1.0
        elif t_end > 0.6: r -= 0.6
        else: r -= 0.2
    return r, max(0.0, min(1.0, 0.5 + 0.4 * r))


def label_cs(feat, oc):
    """last-hit / deny: commit was good if it succeeded cheaply; bad if it failed or cost HP."""
    success = int(oc["success"]); hp_lost = float(oc.get("hpLost", 0.0))
    if success:
        r = 1.0 - 1.2 * hp_lost          # got the CS, minus harass taken
    else:
        r = -0.6 - 1.2 * hp_lost         # missed it (and maybe took damage anyway)
    return r, max(0.0, min(1.0, 0.5 + 0.4 * r))


def label_trade(feat, oc):
    """HP trade: good if we netted enemy HP off in our favour; punish dying for it."""
    net = float(oc["net"]); self_died = int(oc.get("selfDied", 0))
    r = 4.0 * net                        # net is an HP fraction; scale into reward range
    if self_died:
        r -= 1.0
    return r, max(0.0, min(1.0, 0.5 + 0.4 * r))


# task -> (n_features, label_fn)
TASKS = {
    "sniper_assassinate": (10, label_sniper),
    "laning_lasthit":     (6,  label_cs),
    "laning_deny":        (5,  label_cs),
    "laning_trade":       (9,  label_trade),
}


def parse_kv(line):
    parts = line.strip().split("|")
    if len(parts) < 3 or parts[0] != "OHA_ML":
        return None
    kv = {}
    for seg in parts[3:]:
        if "=" in seg:
            k, v = seg.split("=", 1); kv[k] = v
    return parts[1], parts[2], kv


def parse_log(path):
    decides = {}                       # (task,id) -> features
    rows = {t: [] for t in TASKS}      # task -> list of row dicts
    dangling = {t: 0 for t in TASKS}
    with open(path, "r", errors="ignore") as fh:
        for raw in fh:
            if "OHA_ML|" not in raw:
                continue
            raw = raw[raw.index("OHA_ML|"):]
            parsed = parse_kv(raw)
            if parsed is None:
                continue
            task, etype, kv = parsed
            if task not in TASKS:
                continue
            n_feat, label_fn = TASKS[task]

            if etype == "DECIDE":
                try:
                    feat = [float(x) for x in kv["feat"].split(",")]
                except (KeyError, ValueError):
                    continue
                if len(feat) == n_feat:
                    decides[(task, kv.get("id"))] = feat

            elif etype == "OUTCOME":
                feat = decides.pop((task, kv.get("id")), None)
                if feat is None:
                    continue
                try:
                    r, label = label_fn(feat, kv)
                except (KeyError, ValueError):
                    continue
                rows[task].append({"features": feat, "reward": round(r, 4), "label": round(label, 4)})

    for (t, _id) in decides:
        dangling[t] += 1
    return rows, dangling


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("console_log", help="path to Dota's console.log")
    args = ap.parse_args()
    if not os.path.exists(args.console_log):
        sys.exit(f"not found: {args.console_log}")

    rows, dangling = parse_log(args.console_log)
    os.makedirs(DATA_DIR, exist_ok=True)

    any_written = False
    for task, rlist in rows.items():
        if not rlist:
            continue
        any_written = True
        out = os.path.join(DATA_DIR, f"{task}.jsonl")
        with open(out, "w") as fh:
            for r in rlist:
                fh.write(json.dumps(r) + "\n")
        pos = sum(1 for r in rlist if r["label"] >= 0.5)
        avg = sum(r["reward"] for r in rlist) / len(rlist)
        print(f"{task:20s} {len(rlist):5d} rows (+{pos}/-{len(rlist)-pos})  "
              f"mean_r={avg:+.3f}  dangling={dangling[task]}  -> ml/data/{task}.jsonl")

    if not any_written:
        print("no OHA_ML rows found (was OHA_ML_LOG=true and -condebug set?)")


if __name__ == "__main__":
    main()
