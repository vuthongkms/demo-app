#!/usr/bin/env bash
# Scene 4: a signed VEX statement suppresses a finding that is not reachable.
source "$(dirname "$0")/lib.sh"
say "Scene 4: what the scanner sees"
run "trivy image --quiet --severity HIGH,CRITICAL $IMAGE@$GOOD_DIGEST"
say "Is the vulnerable code reachable?"
run "(cd $REPO_DIR && govulncheck ./...)"
say "Trivy does not verify who signed the VEX. We do"
run "cosign verify-attestation --type openvex --certificate-identity $BUILDER_ID --certificate-oidc-issuer $ISSUER $IMAGE@$GOOD_DIGEST > /dev/null"
run "trivy image --quiet --severity HIGH,CRITICAL --vex oci --show-suppressed $IMAGE@$GOOD_DIGEST"
