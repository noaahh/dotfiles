#!/usr/bin/env python3
"""Keybinding cheat sheet in the spirit of omarchy's SUPER+K menu.

Merges herdr's built-in defaults (defaults.json, extracted from the config
reference of the herdr version noted inside), your [keys] overrides and
[[keys.command]] entries from config.toml, and plugin actions that have no
key. Flags bindings that collide. Enter on a plugin action runs it.
"""
import json, os, subprocess, sys, tomllib

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
ROOT = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.environ.get("HERDR_CONFIG_PATH", os.path.expanduser("~/.config/herdr/config.toml"))

MODS = {"ctrl": "⌃", "alt": "⌥", "shift": "⇧", "cmd": "⌘", "super": "⌘"}
NAMES = {"left": "←", "right": "→", "up": "↑", "down": "↓", "tab": "⇥", "enter": "↵",
         "esc": "⎋", "space": "␣", "backspace": "⌫", "minus": "-"}
DIM, BOLD, YEL, CYAN, RED, OFF = "\033[2m", "\033[1m", "\033[33m", "\033[36m", "\033[31m", "\033[0m"


def chord(s, prefix):
    parts = s.lower().split("+")
    out = prefix + " " if parts[0] == "prefix" else ""
    parts = parts[1:] if parts[0] == "prefix" else parts
    *mods, key = parts
    key = NAMES.get(key, key.upper() if len(key) == 1 else key)
    return out + "".join(MODS.get(m, m) for m in mods) + key


def pretty(binding, prefix):
    if isinstance(binding, list):
        return " / ".join(pretty(b, prefix) for b in binding)
    return chord(binding, prefix)


def rows():
    defaults = json.load(open(os.path.join(ROOT, "defaults.json")))
    cfg = tomllib.load(open(CONFIG, "rb")).get("keys", {})
    raw_prefix = cfg.get("prefix", json.loads(defaults["keys"]["prefix"]["default"]))
    prefix = pretty(raw_prefix, "")
    out = []  # (binding, label, tag, action)

    for c in cfg.get("command", []):
        what = c.get("description") or c.get("command", "")
        action = c["command"] if c.get("type") == "plugin_action" else None
        out.append((c["key"], what, "custom", action))

    for name, d in defaults["keys"].items():
        if name == "prefix":
            continue
        binding = cfg.get(name)
        tag = "override" if binding is not None else "built-in"
        if binding is None:
            if d["default"] == "unset":
                continue
            binding = json.loads(d["default"])
        out.append((binding, d["description"].split(". ")[0].rstrip("."), tag, None))

    bound = {r[3] for r in out if r[3]}
    listing = subprocess.run([HERDR, "plugin", "action", "list"], capture_output=True, text=True).stdout
    try:
        actions = json.loads(listing).get("result", {}).get("actions", [])
    except ValueError:
        actions = []
    for a in actions:
        qid = f"{a.get('plugin_id')}.{a.get('action_id') or a.get('id')}"
        if qid not in bound:
            out.append((None, a.get("title") or qid, "unbound", qid))

    # conflicts: same chord in global/prefix scope (navigate-mode keys live in their own mode)
    seen = {}
    for b, label, tag, _ in out:
        for one in (b if isinstance(b, list) else [b]):
            if one and ("prefix" in one or "+" in one) and "navigate mode" not in label:
                seen.setdefault(one.lower(), []).append(label)
    clash = {k for k, v in seen.items() if len(v) > 1}
    return out, prefix, clash, raw_prefix


def main():
    out, prefix, clash, raw_prefix = rows()
    lines = []
    order = {"custom": 0, "override": 1, "built-in": 2, "unbound": 3}
    for b, label, tag, action in sorted(out, key=lambda r: order[r[2]]):
        keys = pretty(b, prefix) if b else "—"
        hit = b and any(one.lower() in clash for one in (b if isinstance(b, list) else [b]))
        color = {"custom": CYAN, "override": YEL, "built-in": "", "unbound": DIM}[tag]
        warn = f"  {RED}⚠ conflict{OFF}" if hit else ""
        lines.append(f"{action or ''}\t{BOLD}{keys:<16}{OFF} {color}{label}{OFF}  {DIM}{tag}{OFF}{warn}")
    header = (f"prefix = {prefix} ({raw_prefix}) · type to search · Enter runs a plugin action · Esc closes\n"
              f"{CYAN}custom{OFF}  {YEL}override{OFF}  built-in  {DIM}unbound plugin action{OFF}")
    res = subprocess.run(["fzf", "--ansi", "--reverse", "--no-sort", "--delimiter", "\t", "--with-nth", "2..",
                          "--header", header, "--prompt", "keys › "],
                         input="\n".join(lines), capture_output=True, text=True)
    action = res.stdout.split("\t")[0].strip() if res.stdout else ""
    if action:
        plugin, act = action.rsplit(".", 1)
        subprocess.run([HERDR, "plugin", "action", "invoke", act, "--plugin", plugin], capture_output=True)


if __name__ == "__main__":
    if sys.argv[1:] == ["--print"]:  # plain dump for testing
        out, prefix, clash, _ = rows()
        for b, label, tag, action in out:
            print(f"{(pretty(b, prefix) if b else '—'):<16} {label} [{tag}]{' CONFLICT' if b and any(o.lower() in clash for o in (b if isinstance(b, list) else [b])) else ''}")
    else:
        main()
