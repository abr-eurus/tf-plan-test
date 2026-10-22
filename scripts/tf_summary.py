#!/usr/bin/env python3
"""Write a Terraform plan visual to the GitHub job summary. Pure Markdown, no JS.

    terraform show -json tfplan > plan.json
    python tf_summary.py plan.json "prod" >> "$GITHUB_STEP_SUMMARY"
"""
import json, sys

UNK, SENS = "(known after apply)", "(sensitive)"
ORDER = ["delete", "replace", "update", "create", "read"]
META = {"create": ("🟩", "Create"), "update": ("🟨", "Update"), "replace": ("🟪", "Replace"),
        "delete": ("🟥", "Destroy"), "read": ("🟦", "Read")}


def action(acts):
    if acts == ["no-op"] or not acts:
        return None
    if "create" in acts and "delete" in acts:
        return "replace"
    return acts[0]


def sub(x, k):
    if isinstance(x, dict):
        return x.get(k)
    if isinstance(x, list) and isinstance(k, int) and k < len(x):
        return x[k]
    return None


def walk(b, a, u, bs, as_, path, out):
    if u is True:
        out.append((path, b, UNK)); return
    if b == a:
        return
    if bs is True or as_ is True:
        out.append((path, SENS, SENS)); return
    if isinstance(b, dict) or isinstance(a, dict):
        keys = set()
        for x in (b, a, u):
            if isinstance(x, dict):
                keys |= set(x)
        for k in sorted(keys):
            walk(sub(b, k), sub(a, k), sub(u, k), sub(bs, k), sub(as_, k), f"{path}.{k}" if path else k, out)
        return
    if isinstance(b, list) or isinstance(a, list):
        n = max(len(x) for x in (b, a, u) if isinstance(x, list))
        for i in range(n):
            walk(sub(b, i), sub(a, i), sub(u, i), sub(bs, i), sub(as_, i), f"{path}[{i}]", out)
        return
    out.append((path, b, a))


def val(v):
    return v if isinstance(v, str) and v in (UNK, SENS) else json.dumps(v, ensure_ascii=False)[:120]


def diff(rc, act, limit=40):
    ch, out = rc["change"], []
    walk(ch.get("before"), ch.get("after"), ch.get("after_unknown", False),
         ch.get("before_sensitive", False), ch.get("after_sensitive", False), "", out)
    lines, computed = [], 0
    forced = {".".join(map(str, p)) for p in ch.get("replace_paths") or []}
    for path, b, a in out:
        if a == UNK and act in ("create", "replace", "read") and path not in forced:
            computed += 1; continue
        if len(lines) >= limit:
            lines.append(f"# ... {len(out) - limit} more"); break
        tag = "  # forces replacement" if path in forced else ""
        if b is None:
            lines.append(f"+ {path} = {val(a)}{tag}")
        elif a is None:
            lines.append(f"- {path} = {val(b)}")
        else:
            lines += [f"- {path} = {val(b)}", f"+ {path} = {val(a)}{tag}"]
    if computed:
        lines.append(f"# + {computed} computed attributes")
    return "\n".join(lines) or "# no attribute changes"


def main():
    plan = json.load(open(sys.argv[1]))
    title = sys.argv[2] if len(sys.argv) > 2 else ""
    rcs = [(action(r["change"]["actions"]), r) for r in plan.get("resource_changes", [])]
    rcs = [(a, r) for a, r in rcs if a]
    n = {a: sum(1 for x, _ in rcs if x == a) for a in ORDER}
    print(f"## Terraform plan{': ' + title if title else ''}\n")
    if not rcs:
        print("✅ **No changes.** Infrastructure matches the configuration."); return
    add, chg, des = n["create"] + n["replace"], n["update"], n["delete"] + n["replace"]
    print(f"**{add} to add, {chg} to change, {des} to destroy**\n")
    total = sum(n[a] for a in ORDER if a != "read") or 1
    print("".join(META[a][0] * max(1, round(n[a] / total * 20)) for a in ORDER[::-1] if n[a] and a != "read"), "\n")
    print("| Action | Count |\n|---|---:|")
    for a in ORDER:
        if n[a]:
            print(f"| {META[a][0]} {META[a][1]} | {n[a]} |")
    print()
    for a in ORDER:
        group = sorted((r for x, r in rcs if x == a), key=lambda r: r["address"])
        if not group:
            continue
        print(f"<details{' open' if a in ('delete', 'replace') else ''}><summary><b>{META[a][0]} {META[a][1]} ({len(group)})</b></summary>\n")
        for r in group:
            print(f"<details><summary><code>{r['address'].replace('<', '&lt;')}</code></summary>\n\n````diff\n{diff(r, a)}\n````\n\n</details>\n")
        print("</details>\n")


main()

