#!/usr/bin/env bash
# Scene 2b: the attacker calls OUR public trusted builder from THEIR repository.
source "$(dirname "$0")/lib.sh"
say "Scene 2b: signed by the trusted builder identity"
run "cosign verify $IMAGE:v1-borrowed --certificate-identity $BUILDER_ID --certificate-oidc-issuer $ISSUER > /dev/null"
run "signer_of $IMAGE:v1-borrowed"
say "Right builder. But built from where?"
run "provenance_of $IMAGE:v1-borrowed"
run "k run attack2b --image=$IMAGE:v1-borrowed --restart=Never"
