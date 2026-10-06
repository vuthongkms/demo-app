#!/usr/bin/env bash
# Checks before going on stage. Every line must say OK.
source "$(dirname "$0")/lib.sh"
fail=0
check() { if eval "$2" > /dev/null 2>&1; then echo "OK    $1"; else echo "FAIL  $1"; fail=1; fi; }

check "cluster reachable"              "k get nodes"
check "kyverno admission controller"   "k -n kyverno rollout status deploy/kyverno-admission-controller --timeout=5s"
check "policy verify-supply-chain"     "[ \"\$(k get imagevalidatingpolicy verify-supply-chain -o jsonpath='{.status.conditionStatus.ready}')\" = true ]"
check "policy allow-only-ghcr"         "k get validatingpolicy allow-only-ghcr-vuthongkms"
check "ghcr.io reachable"              "curl -s -o /dev/null -m 5 https://ghcr.io/v2/"
check "rekor reachable"                "curl -sf -o /dev/null -m 5 https://rekor.sigstore.dev/api/v1/log"
check "sigstore TUF reachable"         "curl -sf -o /dev/null -m 5 https://tuf-repo-cdn.sigstore.dev/timestamp.json"
check "digests recorded"               "[ -n \"\${GOOD_DIGEST:-}\" ]"
check "v1 points to the good digest"   "[ \"\$(crane digest $IMAGE:v1)\" = \"\${GOOD_DIGEST:-}\" ]"
check "attacker image exists"          "crane digest $EVIL_UNSIGNED"
check "attacker token for scene 1"     "[ -f $STAGE_DIR/.attacker-docker/config.json ]"
check "no leftover demo-app deploy"    "! k get deploy demo-app"

# Kyverno caches successful verifications (TTL 60m) but starts cold after a
# restart, and a cold check of a signed image can exceed the 30s webhook limit.
# Dry-run every scene image twice so the stage runs on a warm cache.
for img in "$IMAGE@${GOOD_DIGEST:-none}" "$IMAGE:v1-evil" "$IMAGE:v1-borrowed" "$IMAGE:feature-x"; do
  for _ in 1 2; do k run warmup --image="$img" --restart=Never --dry-run=server > /dev/null 2>&1; done
done
s=$(date +%s); k run warmup --image="$IMAGE@${GOOD_DIGEST:-none}" --restart=Never --dry-run=server > /dev/null 2>&1
check "warm admission under 10s"       "[ $(( $(date +%s) - s )) -lt 10 ]"
exit $fail
