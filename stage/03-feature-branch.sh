#!/usr/bin/env bash
# Scene 3: an unreviewed branch of the right repository, built by the real pipeline.
source "$(dirname "$0")/lib.sh"
say "Scene 3: same repo, same builder, unreviewed branch"
run "provenance_of $IMAGE:feature-x"
run "gh attestation verify oci://$IMAGE:feature-x -R $APP_REPO --signer-workflow $SIGNER_WORKFLOW --source-ref refs/heads/main"
run "k run attack3 --image=$IMAGE:feature-x --restart=Never"
