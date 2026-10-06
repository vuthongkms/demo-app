#!/usr/bin/env bash
# Undo the scenes: restore tag v1 and remove what the scenes created.
source "$(dirname "$0")/lib.sh"
DOCKER_CONFIG="$STAGE_DIR/.attacker-docker" crane tag "$IMAGE@$GOOD_DIGEST" v1
k delete deploy demo-app --ignore-not-found
k delete pod attack1 attack2 attack2b attack3 --ignore-not-found
echo "v1 -> $(crane digest "$IMAGE:v1")"
