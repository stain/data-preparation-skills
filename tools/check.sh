#!/usr/bin/env bash
# Run all repository checks. Usage: tools/check.sh   (from anywhere)
# Needs python3 and network access; uses the `claude` CLI if installed.
set -euo pipefail
cd "$(dirname "$0")/.."
VENV="$(mktemp -d)"
trap 'rm -rf "$VENV"' EXIT
fail=0
step() { printf '\n== %s\n' "$1"; }

step "JSON syntax"
for f in $(git ls-files '*.json'); do
  python3 -I -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || { echo "invalid: $f"; fail=1; }
done
echo "ok"

step "Skill names, sizes and versions"
python3 -I - <<'PY' || fail=1
import json, pathlib, re, sys
root = pathlib.Path(".")
versions = {
    ".claude-plugin/plugin.json": json.load(open(".claude-plugin/plugin.json"))["version"],
    ".claude-plugin/marketplace.json": json.load(open(".claude-plugin/marketplace.json"))["metadata"]["version"],
    ".codex-plugin/plugin.json": json.load(open(".codex-plugin/plugin.json"))["version"],
    "codemeta.json": json.load(open("codemeta.json"))["version"],
}
bad = False
for skill in sorted(root.glob("skills/*/SKILL.md")):
    text = skill.read_text()
    front = text.split("---")[1]
    name = re.search(r"^name:\s*(\S+)", front, re.M).group(1)
    version = re.search(r'^\s+version:\s*"?([^"\n]+)"?', front, re.M).group(1)
    versions[str(skill)] = version
    lines = text.count("\n")
    if name != skill.parent.name:
        print(f"{skill}: name {name!r} != folder"); bad = True
    if lines >= 500:
        print(f"{skill}: {lines} lines (keep under 500)"); bad = True
    if not (skill.parent / "agents" / "openai.yaml").exists():
        print(f"{skill}: missing agents/openai.yaml"); bad = True
if len(set(versions.values())) != 1:
    print("version mismatch:", json.dumps(versions, indent=2)); bad = True
else:
    print("version", next(iter(versions.values())), "in", len(versions), "places")
sys.exit(1 if bad else 0)
PY

step "Install validators"
python3 -m venv "$VENV"
"$VENV/bin/pip" -q install "git+https://github.com/agentskills/agentskills#subdirectory=skills-ref" roc-validator
echo "ok"

step "skills-ref"
for s in skills/*/; do "$VENV/bin/skills-ref" validate "$s" || fail=1; done

step "CodeMeta terms"
curl -sSL -H "Accept: application/ld+json" "$(python3 -I -c "import json; print(json.load(open('codemeta.json'))['@context'])")" > "$VENV/codemeta-context.json"
python3 -I - "$VENV/codemeta-context.json" <<'PY' || fail=1
import json, sys
context = json.load(open(sys.argv[1]))["@context"]
doc = json.load(open("codemeta.json"))
def keys(o):
    if isinstance(o, dict):
        for k, v in o.items():
            yield k
            yield from keys(v)
    elif isinstance(o, list):
        for v in o:
            yield from keys(v)
missing = sorted({k for k in keys(doc) if not k.startswith("@") and k not in context})
print("ok" if not missing else f"not in context: {missing}")
sys.exit(1 if missing else 0)
PY

step "Claude plugin manifests"
if command -v claude >/dev/null; then
  claude plugin validate . || fail=1
  claude plugin validate .claude-plugin/plugin.json || fail=1
else
  echo "claude CLI not installed: skipped"
fi

step "RO-Crate examples (metadata only)"
for d in examples/*/; do
  [ -f "$d/ro-crate-metadata.json" ] || continue
  if "$VENV/bin/rocrate-validator" validate -p ro-crate-1.3 --metadata-only \
       --requirement-severity REQUIRED --output-format json "$d" < /dev/null 2>/dev/null \
     | python3 -I -c "import json,sys; r,_=json.JSONDecoder().raw_decode(sys.stdin.read()); print(sys.argv[1], 'REQUIRED issues:', len(r['issues'])); sys.exit(0 if r['passed'] else 1)" "$d"
  then :; else fail=1; fi
done

step "Result"
if [ "$fail" -eq 0 ]; then echo "all checks passed"; else echo "SOME CHECKS FAILED"; fi
exit "$fail"
