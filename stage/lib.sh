# shellcheck shell=bash disable=SC2034
# Helpers for the live demo. Each command is printed, then runs on Enter.
# AUTO=1 runs without pausing (rehearsals, recordings).
set -uo pipefail
STAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$STAGE_DIR")"
source "$STAGE_DIR/env.sh"
[ -f "$STAGE_DIR/.digests" ] && source "$STAGE_DIR/.digests"
mkdir -p "$STAGE_DIR/.tmp"

say() { printf '\n\033[1;36m# %s\033[0m\n' "$*"; }
run() {
  printf '\033[1;33m$ %s\033[0m' "$*"
  if [ "${AUTO:-0}" = 1 ]; then echo; else read -r _; fi
  eval "$*"
}
k() { kubectl --context "$KUBECONTEXT" "$@"; }

# First Sigstore bundle of a predicate type attached to an image.
bundle_of() {
  local f="$STAGE_DIR/.tmp/bundle.json"
  cosign download attestation --predicate-type "$2" "$1" 2>/dev/null | head -1 > "$f"
  echo "$f"
}
# Identity (Fulcio SAN) that signed the image.
signer_of() {
  cosign bundle inspect "$(bundle_of "$1" https://sigstore.dev/cosign/sign/v1)" 2>/dev/null \
    | grep -A1 'Subject Alternative Name' | tail -1 | sed 's/^ *- //'
}
# Where the SLSA provenance says the image was built from.
provenance_of() {
  jq -r '.dsseEnvelope.payload' "$(bundle_of "$1" https://slsa.dev/provenance/v1)" | base64 -d \
    | jq '{workflow: .predicate.buildDefinition.externalParameters.workflow, builder: .predicate.runDetails.builder.id}'
}
# Public Rekor search link for the image signature.
rekor_url() {
  local idx
  idx=$(jq -r '.verificationMaterial.tlogEntries[0].logIndex' "$(bundle_of "$1" https://sigstore.dev/cosign/sign/v1)")
  echo "https://search.sigstore.dev/?logIndex=${idx}"
}
