#!/usr/bin/env bash
# Rehearsal check that each provenance condition does real work:
# with the condition removed, the scene it guards must be ADMITTED.
# The real policy is restored on exit.
source "$(dirname "$0")/lib.sh"
POLICY="$REPO_DIR/k8s/policy-verify-supply-chain.yaml"
trap 'k apply -f "$POLICY" > /dev/null && echo "policy restored"' EXIT

# Print the policy without the validation whose message starts with "($1)".
without() {
  python3 - "$POLICY" "$1" <<'PY'
import sys
lines = open(sys.argv[1]).read().split("\n")
tag = '      message: "(' + sys.argv[2] + ')'
out, block = [], []
for line in lines:
    if line.startswith("    - expression:"):
        out.extend(block); block = [line]
    elif block:
        block.append(line)
        if line.startswith("      message:"):
            if not line.startswith(tag):
                out.extend(block)
            block = []
    else:
        out.append(line)
out.extend(block)
print("\n".join(out))
PY
}

control() {  # $1 condition, $2 image, $3 scene
  if ! crane digest "$2" > /dev/null 2>&1; then echo "SKIP  scene $3: $2 not found"; return; fi
  without "$1" | k apply -f - > /dev/null
  sleep 3
  if k run "nc-$3" --image="$2" --restart=Never --dry-run=server > /dev/null 2>&1; then
    echo "OK    without ($1), scene $3 is admitted: ($1) is what stops it"
  else
    echo "FAIL  without ($1), scene $3 is still denied: another check also stops it"
  fi
}

control c "$IMAGE:v1-borrowed" 2b
control d "$IMAGE:feature-x" 3
