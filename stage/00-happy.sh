#!/usr/bin/env bash
# Scene 0: a legitimate image from main runs.
source "$(dirname "$0")/lib.sh"
say "Scene 0: the legitimate build"
run "gh run list -R $APP_REPO --branch main --workflow release --limit 1"
say "Verify the signature against the builder identity, not just 'is it signed'"
run "cosign verify $IMAGE@$GOOD_DIGEST --certificate-identity $BUILDER_ID --certificate-oidc-issuer $ISSUER > /dev/null"
run "signer_of $IMAGE@$GOOD_DIGEST"
run "rekor_url $IMAGE@$GOOD_DIGEST"
say "Deploy by tag: Kyverno verifies, then pins the digest"
run "k apply -f $REPO_DIR/k8s/deploy-good.yaml && k rollout status deploy/demo-app --timeout=120s"
run "k get pods -l app=demo-app -o jsonpath='{.items[0].spec.containers[0].image}'; echo"
