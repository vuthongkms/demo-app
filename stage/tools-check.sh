#!/usr/bin/env bash
# Print the version of every tool the demo needs.
for t in kind kubectl helm cosign crane syft trivy vexctl jq go govulncheck gh; do
  printf '%-12s ' "$t"
  case $t in
    kubectl) kubectl version --client 2>/dev/null | head -1 ;;
    cosign|vexctl) $t version 2>&1 | grep GitVersion ;;
    crane|kind) $t version ;;
    helm) helm version --short ;;
    go) go version ;;
    govulncheck) govulncheck -version | grep Scanner ;;
    *) $t --version 2>&1 | head -1 ;;
  esac || echo MISSING
done
