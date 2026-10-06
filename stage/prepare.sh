#!/usr/bin/env bash
# Run once all pipelines have finished, before going on stage.
# Records the digest of every scene's image in stage/.digests and logs the
# attacker's stolen token into a separate Docker config used by scene 1.
#   ATTACKER=<login> STOLEN_PAT=<classic PAT with write:packages> ./prepare.sh
source "$(dirname "$0")/lib.sh"
set -e

# Tag v1 is overwritten in scene 1, so only trust it if its provenance says main.
if [ -z "${GOOD_DIGEST:-}" ]; then
  GOOD_DIGEST=$(crane digest "$IMAGE:v1")
  gh attestation verify "oci://$IMAGE@$GOOD_DIGEST" -R "$APP_REPO" \
    --signer-workflow "$SIGNER_WORKFLOW" --source-ref refs/heads/main > /dev/null \
    || { echo "v1 is not a main build. Restore it before running prepare."; exit 1; }
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

if [ -n "${STOLEN_PAT:-}" ]; then
  echo "$STOLEN_PAT" | DOCKER_CONFIG="$STAGE_DIR/.attacker-docker" \
    crane auth login ghcr.io -u "$ATTACKER" --password-stdin
fi
