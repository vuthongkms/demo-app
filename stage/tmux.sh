#!/usr/bin/env bash
# Stage layout: scenes on the left; live pods (top right) and every Kyverno block (bottom right).
cd "$(dirname "$0")/.." || exit 1
SESSION=signed-demo
tmux has-session -t "$SESSION" 2>/dev/null && exec tmux attach -t "$SESSION"
tmux new-session -d -s "$SESSION" -n demo -c "$PWD"
tmux split-window -h -l 35% -t "$SESSION:demo" -c "$PWD" \
  "kubectl --context kind-signed-demo get pods -w -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IMAGE:.spec.containers[0].image"
tmux split-window -v -t "$SESSION:demo.1" -c "$PWD" \
  "kubectl --context kind-signed-demo get events -w --watch-only --field-selector reason=PolicyViolation -o custom-columns=BLOCKED:.message"
tmux select-pane -t "$SESSION:demo.0"
exec tmux attach -t "$SESSION"
