#!/usr/bin/env python3
"""Stale agent panes: age = time since your last real prompt in the pane's
Claude session (not file mtime; resumes and away summaries touch that).

refresh  report a $age pane token on panes idle for STALE_H or more
pick     fzf popup listing stale panes, all preselected; Enter closes them
"""
import datetime, glob, json, os, subprocess, sys

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
STALE_H = 12  # sidebar marker from here
PICK_H = 24  # picker lists panes from here
STATE = os.environ.get("HERDR_PLUGIN_STATE_DIR", os.path.expanduser("~/.local/state/herdr/plugins/noah.tidy"))
CACHE = os.path.join(STATE, "last-prompt.json")
KEEP_TOKENS = {"watch", "wake", "mon"}  # panes someone is waiting on are never stale


def herdr(*args):
    out = subprocess.run([HERDR, *args], capture_output=True, text=True).stdout
    return json.loads(out) if out.strip().startswith("{") else {}


def last_prompt(session_id, cache):
    """ISO timestamp of the last user-typed prompt, cached by transcript mtime."""
    path = next(iter(glob.glob(os.path.expanduser(f"~/.claude/projects/*/{session_id}.jsonl"))), None)
    if not path:
        return None
    mtime = os.path.getmtime(path)
    hit = cache.get(session_id)
    if hit and hit["mtime"] == mtime:
        return hit["ts"]
    ts = None
    with open(path, errors="ignore") as f:
        for line in f:
            if '"type":"user"' not in line:
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue
            c = e.get("message", {}).get("content")
            if e.get("isMeta") or (isinstance(c, list) and not any(x.get("type") == "text" for x in c)):
                continue
            ts = e.get("timestamp", ts)
    cache[session_id] = {"mtime": mtime, "ts": ts}
    return ts


def agents_with_age():
    try:
        cache = json.load(open(CACHE))
    except (OSError, ValueError):
        cache = {}
    now = datetime.datetime.now(datetime.timezone.utc)
    rows = []
    for a in herdr("agent", "list").get("result", {}).get("agents", []):
        sess = a.get("agent_session") or {}
        ts = last_prompt(sess["value"], cache) if sess.get("agent") == "claude" else None
        # ponytail: Claude only; Codex sessions never get an age until their rollout files are read too
        a["age_h"] = (now - datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))).total_seconds() / 3600 if ts else None
        rows.append(a)
    os.makedirs(STATE, exist_ok=True)
    json.dump(cache, open(CACHE, "w"))
    return rows


def label(h):
    return f"{h:.0f}h" if h < 48 else f"{h / 24:.0f}d"


def stale(a, min_h):
    return (a["age_h"] or 0) >= min_h and a.get("agent_status") in ("idle", "done") and not a.get("focused")


def refresh():
    # ponytail: ages only move when some pane changes state; fine while any agent is busy
    for a in agents_with_age():
        tokens = (herdr("pane", "get", a["pane_id"]).get("result", {}).get("pane", {}).get("tokens") or {})
        args = ["--token", f"age=💤 {label(a['age_h'])}"] if stale(a, STALE_H) and not KEEP_TOKENS & tokens.keys() else ["--clear-token", "age"]
        subprocess.run([HERDR, "pane", "report-metadata", a["pane_id"], "--source", "noah.tidy", *args], capture_output=True)


def pick():
    ws = {w["workspace_id"]: w.get("label") or w.get("name", "") for w in herdr("workspace", "list").get("result", {}).get("workspaces", [])}
    rows = []
    for a in sorted(agents_with_age(), key=lambda a: -(a["age_h"] or 0)):
        tokens = herdr("pane", "get", a["pane_id"]).get("result", {}).get("pane", {}).get("tokens") or {}
        if stale(a, PICK_H) and not KEEP_TOKENS & tokens.keys():
            rows.append(f"{a['pane_id']}\t{label(a['age_h']):>4}  {a.get('terminal_title_stripped') or a['agent']}  ·  {ws.get(a['workspace_id'], '')}")
    if not rows:
        input(f"Nothing idle for {PICK_H}h+. Enter to close.")
        return
    fzf = subprocess.run(
        ["fzf", "--multi", "--bind", "load:select-all", "--with-nth", "2..", "--delimiter", "\t",
         "--header", "Enter closes selected · Tab toggles · Esc keeps all\nClosed sessions stay resumable via prefix+shift+a",
         "--reverse", "--no-sort"],
        input="\n".join(rows), capture_output=True, text=True)
    chosen = [l.split("\t")[0] for l in fzf.stdout.splitlines() if l]
    for pane in chosen:
        subprocess.run([HERDR, "pane", "close", pane], capture_output=True)
    if chosen:
        subprocess.run([HERDR, "plugin", "action", "invoke", "refresh-archive", "--plugin", "herdr.omnisearch"], capture_output=True)
        input(f"Closed {len(chosen)}. Find them again with prefix+shift+a. Enter to close.")


if __name__ == "__main__":
    {"refresh": refresh, "pick": pick}[sys.argv[1]]()
