#!/usr/bin/env bash
# Scene 4: a signed VEX statement suppresses a finding that is not reachable.
source "$(dirname "$0")/lib.sh"
say "Scene 4: what the scanner sees"
run "trivy image --quiet --severity HIGH,CRITICAL $IMAGE@$GOOD_DIGEST"
say "Is the vulnerable code reachable?"
run "(cd $REPO_DIR && govulncheck ./...)"
say "Trivy does not check who wrote a VEX. Verify it first, then use it"
run "gh attestation verify oci://$IMAGE@$GOOD_DIGEST -R $APP_REPO --signer-workflow $SIGNER_WORKFLOW --source-ref refs/heads/main --predicate-type https://openvex.dev/ns --format json --jq '.[0].verificationResult.statement.predicate' > $STAGE_DIR/.tmp/vex.json"
run "trivy image --quiet --severity HIGH,CRITICAL --vex $STAGE_DIR/.tmp/vex.json --show-suppressed $IMAGE@$GOOD_DIGEST"
