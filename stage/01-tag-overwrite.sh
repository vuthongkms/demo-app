#!/usr/bin/env bash
# Scene 1: with a stolen registry token, the attacker overwrites the v1 tag.
source "$(dirname "$0")/lib.sh"
say "Scene 1: the attacker overwrites tag v1 with an unsigned image"
run "DOCKER_CONFIG=$STAGE_DIR/.attacker-docker crane push $EVIL_TARBALL $IMAGE:v1"
run "crane digest $IMAGE:v1"
run "k run attack1 --image=$IMAGE:v1 --restart=Never"
say "The running app was pinned by digest and is untouched"
run "k get pods -l app=demo-app -o jsonpath='{.items[0].spec.containers[0].image}'; echo"
