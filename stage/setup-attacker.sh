#!/usr/bin/env bash
# One-time setup of the attacker side (scenes 1, 2 and 2b).
#
# Before running:
#   1. gh is logged in to github.com with BOTH accounts:
#        gh auth login --hostname github.com   (once per account)
#   2. A classic PAT of vuthongkms with only write:packages, expiring after the talk,
#      is in the environment without echoing it:
#        read -rs STOLEN_PAT && export STOLEN_PAT
#
# Usage: ATTACKER=<attacker login> stage/setup-attacker.sh
set -euo pipefail
STAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
EVIL_DIR="$(cd "$STAGE_DIR/../.." && pwd)/evil-app"
export GH_HOST=github.com
OWNER=vuthongkms
: "${ATTACKER:?set ATTACKER to the attacker GitHub login}"
: "${STOLEN_PAT:?export STOLEN_PAT first (read -rs STOLEN_PAT)}"
[ -d "$EVIL_DIR/.git" ] || { echo "missing $EVIL_DIR"; exit 1; }

gh auth status --hostname github.com 2>&1 | grep -q "account $ATTACKER " \
  || { echo "gh is not logged in as $ATTACKER on github.com"; exit 1; }
trap 'gh auth switch --hostname github.com --user "$OWNER" > /dev/null 2>&1 || true' EXIT
gh auth switch --hostname github.com --user "$ATTACKER"

# Repository under the attacker account, committed as the attacker.
ATTACKER_ID=$(gh api user --jq .id)
git -C "$EVIL_DIR" config user.name "$ATTACKER"
git -C "$EVIL_DIR" config user.email "${ATTACKER_ID}+${ATTACKER}@users.noreply.github.com"
git -C "$EVIL_DIR" add -A
git -C "$EVIL_DIR" diff --cached --quiet || git -C "$EVIL_DIR" commit -q -m "Attacker workflows for the demo"
if ! gh repo view "$ATTACKER/evil-app" > /dev/null 2>&1; then
  gh repo create "$ATTACKER/evil-app" --public --description "Plays the attacker in the Signed Isn't Enough demo" \
    --source "$EVIL_DIR" --remote origin --push
else
  git -C "$EVIL_DIR" push -q origin HEAD:main
fi

# The stolen token, read from stdin so it never appears in a command line.
printf '%s' "$STOLEN_PAT" | gh secret set STOLEN_PAT -R "$ATTACKER/evil-app"

for wf in act1-unsigned.yml act2-self-signed.yml act2b-borrow-builder.yml; do
  gh workflow run "$wf" -R "$ATTACKER/evil-app"
done
sleep 10
for wf in act1-unsigned.yml act2-self-signed.yml act2b-borrow-builder.yml; do
  run=$(gh run list -R "$ATTACKER/evil-app" --workflow "$wf" --limit 1 --json databaseId --jq '.[0].databaseId')
  echo "waiting for $wf (run $run)"
  gh run watch "$run" -R "$ATTACKER/evil-app" --exit-status --interval 15 > /dev/null
done

gh auth switch --hostname github.com --user "$OWNER"
# Scene 1 copies this image with the victim token; the cluster and preflight pull it anonymously.
if ! DOCKER_CONFIG=$(mktemp -d) crane digest "ghcr.io/${ATTACKER,,}/evil-app:act1" > /dev/null 2>&1; then
  echo "ghcr.io/${ATTACKER,,}/evil-app is not public: open its package settings on GitHub and change visibility to public, then re-run."
  exit 1
fi
mkdir -p "$STAGE_DIR/.tmp" && echo "$ATTACKER" > "$STAGE_DIR/.tmp/attacker"
ATTACKER="$ATTACKER" STOLEN_PAT="$STOLEN_PAT" "$STAGE_DIR/prepare.sh"
echo "done: run stage/preflight.sh, then stage/negative-controls.sh"
