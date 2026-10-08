# shellcheck shell=bash
# Shared settings for the stage scripts.
export GH_HOST=github.com
export KUBECONTEXT=kind-signed-demo
export IMAGE=ghcr.io/vuthongkms/demo-app
export APP_REPO=vuthongkms/demo-app
export ISSUER=https://token.actions.githubusercontent.com
export BUILDER_ID=https://github.com/vuthongkms/trusted-builder/.github/workflows/build-sign-attest.yml@refs/tags/v1
export SIGNER_WORKFLOW=vuthongkms/trusted-builder/.github/workflows/build-sign-attest.yml
# Second GitHub account that plays the attacker; setup-attacker.sh records it in stage/.tmp/attacker.
[ -z "${ATTACKER:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/.tmp/attacker" ] && ATTACKER=$(cat "$(dirname "${BASH_SOURCE[0]}")/.tmp/attacker")
export ATTACKER="${ATTACKER:-CHANGE-ME}"
# Scene 1: an unsigned image built locally from ../evil-app (prepare.sh builds it).
EVIL_TARBALL="$(dirname "${BASH_SOURCE[0]}")/.tmp/evil-act1.tar"
export EVIL_TARBALL
