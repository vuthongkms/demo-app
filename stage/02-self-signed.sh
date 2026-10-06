#!/usr/bin/env bash
# Scene 2: the attacker signs their own image, keyless, from their own repository.
source "$(dirname "$0")/lib.sh"
say "Scene 2: a perfectly valid signature"
run "cosign verify $IMAGE:v1-evil --certificate-identity-regexp '.*' --certificate-oidc-issuer $ISSUER > /dev/null"
say "Is your pipeline verifying like this?"
run "signer_of $IMAGE:v1-evil"
run "k run attack2 --image=$IMAGE:v1-evil --restart=Never"
say "Bonus: the attacker's identity is now in a public, append-only log"
run "rekor_url $IMAGE:v1-evil"
