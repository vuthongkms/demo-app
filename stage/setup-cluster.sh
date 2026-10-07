#!/usr/bin/env bash
# Create or repair the demo cluster: kind, Kyverno and the two policies.
# Safe to re-run (for example after a Windows or WSL restart).
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLUSTER=signed-demo
CTX="kind-$CLUSTER"
KYVERNO_CHART_VERSION=3.9.1

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kind create cluster --config "$REPO_DIR/k8s/kind.yaml"
fi
kubectl --context "$CTX" wait --for=condition=Ready node --all --timeout=180s

helm repo add kyverno https://kyverno.github.io/kyverno/ > /dev/null 2>&1 || true
helm repo update kyverno > /dev/null
helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --version "$KYVERNO_CHART_VERSION" -f "$REPO_DIR/k8s/kyverno-values.yaml" \
  --kube-context "$CTX" --wait --timeout 10m

kubectl --context "$CTX" apply \
  -f "$REPO_DIR/k8s/policy-allow-registry.yaml" \
  -f "$REPO_DIR/k8s/policy-verify-supply-chain.yaml"

# The webhooks take a few seconds to be configured after the policies land.
ready=false vready=false
for _ in $(seq 1 30); do
  ready=$(kubectl --context "$CTX" get imagevalidatingpolicy verify-supply-chain -o jsonpath='{.status.conditionStatus.ready}' 2> /dev/null || true)
  vready=$(kubectl --context "$CTX" get validatingpolicy allow-only-ghcr-vuthongkms -o jsonpath='{.status.conditionStatus.ready}' 2> /dev/null || true)
  [ "$ready" = true ] && [ "$vready" = true ] && break
  sleep 2
done
echo "cluster $CTX: verify-supply-chain ready=$ready, allow-only-ghcr ready=$vready"
echo "next: stage/prepare.sh, then stage/preflight.sh"
