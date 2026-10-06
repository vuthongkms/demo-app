#!/usr/bin/env bash
# Stage layout: scenes on the left, live pods on the right.
cd "$(dirname "$0")/.." || exit 1
SESSION=signed-demo
tmux has-session -t "$SESSION" 2>/dev/null && exec tmux attach -t "$SESSION"
tmux new-session -d -s "$SESSION" -n demo -c "$PWD"
tmux split-window -h -l 35% -t "$SESSION:demo" -c "$PWD" \
  "kubectl --context kind-signed-demo get pods -w -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IMAGE:.spec.containers[0].image"
tmux select-pane -t "$SESSION:demo.0"
exec tmux attach -t "$SESSION"
