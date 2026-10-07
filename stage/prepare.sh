#!/usr/bin/env bash
# Run once all pipelines have finished, before going on stage.
# Records the digest of every scene's image in stage/.digests and logs the
# attacker's stolen token into a separate Docker config used by scene 1.
#   ATTACKER=<login> STOLEN_PAT=<classic PAT with write:packages> ./prepare.sh
source "$(dirname "$0")/lib.sh"
set -e

# Tag v1 is overwritten in scene 1, so only trust it if its provenance says main.
# Otherwise keep the digest recorded earlier (scene 1 was not reset yet).
CURRENT=$(crane digest "$IMAGE:v1")
if gh attestation verify "oci://$IMAGE@$CURRENT" -R "$APP_REPO" \
    --signer-workflow "$SIGNER_WORKFLOW" --source-ref refs/heads/main > /dev/null 2>&1; then
  GOOD_DIGEST=$CURRENT
elif [ -n "${GOOD_DIGEST:-}" ]; then
  echo "WARN: v1 is not a main build; keeping $GOOD_DIGEST. Run reset.sh." >&2
else
  echo "v1 is not a main build and no earlier digest is recorded."; exit 1
fi

# Scenes whose image is missing are recorded empty so the others can still be rehearsed.
digest_or_empty() { crane digest "$IMAGE:$1" 2>/dev/null || echo "WARN: $IMAGE:$1 not found" >&2; }
cat > "$STAGE_DIR/.digests" <<DIGESTS
GOOD_DIGEST=$GOOD_DIGEST
EVIL_DIGEST=$(digest_or_empty v1-evil)
BORROWED_DIGEST=$(digest_or_empty v1-borrowed)
FEATURE_DIGEST=$(digest_or_empty feature-x)
DIGESTS
cat "$STAGE_DIR/.digests"

# Links to open in browser tabs before going on stage.
{
  echo "Rekor, legitimate signature: $(rekor_url "$IMAGE@$GOOD_DIGEST" || true)"
  if crane digest "$IMAGE:v1-evil" > /dev/null 2>&1; then
    echo "Rekor, attacker signature:   $(rekor_url "$IMAGE:v1-evil" || true)"
  fi
  echo "GitHub Actions run:          $(gh run list -R "$APP_REPO" --branch main --workflow release --limit 1 --json url --jq '.[0].url' || true)"
} | tee "$STAGE_DIR/.tmp/links.txt"

if [ -n "${STOLEN_PAT:-}" ]; then
  echo "$STOLEN_PAT" | DOCKER_CONFIG="$STAGE_DIR/.attacker-docker" \
    crane auth login ghcr.io -u "$ATTACKER" --password-stdin
fi
