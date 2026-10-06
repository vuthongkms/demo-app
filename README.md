# Signed Isn't Enough: demo

Live demo for the talk *Signed Isn't Enough: Identity-Based Supply Chain Security from CI to Kubernetes Admission*.

A valid signature proves very little on its own. Before an image runs, the cluster should check **who** built it, **from which source** and **with which workflow**. This repository shows that with one legitimate image and four attacks, each stopped by a different layer.

## How it works

```
demo-app (push to any branch)
  └─ release.yml ─ uses ─> vuthongkms/trusted-builder/.github/workflows/build-sign-attest.yml@v1
        build + push      ghcr.io/vuthongkms/demo-app@sha256:...
        cosign sign       Sigstore bundle, keyless
        cosign attest     SPDX SBOM, OpenVEX (vex/openvex.json)
        actions/attest    SLSA v1 provenance
        every certificate: SAN = trusted-builder/.../build-sign-attest.yml@refs/tags/v1

kind + Kyverno 1.19 (k8s/)
  ValidatingPolicy       only ghcr.io/vuthongkms/* images
  ImageValidatingPolicy  (a) cosign-signed by trusted-builder@v1
                         (b) SLSA provenance signed by trusted-builder@v1
                         (c) provenance repository == vuthongkms/demo-app
                         (d) provenance ref == refs/heads/main
```

| Scene | Attack | Signed? | Builder identity? | Stopped by |
|---|---|---|---|---|
| 0 | none: build from `main` | yes | yes | admitted, digest pinned |
| 1 | overwrite tag `v1` with a stolen token | no | | (a) signature |
| 2 | attacker signs keyless from their own repo | yes, valid | no | (a) identity |
| 2b | attacker calls the public trusted builder | yes | **yes** | (c) provenance repository |
| 3 | unreviewed branch `feature/x` of this repo | yes | **yes** | (d) provenance ref |
| 4 | VEX: a CVE in a function the app never calls | | | Trivy suppresses it, after we verify who signed the VEX |

## Run it

Tools: kind, kubectl, helm, cosign v3.1.3+, crane, trivy v0.73+, gh, jq, Go, govulncheck (`stage/tools-check.sh`).

```bash
kind create cluster --config k8s/kind.yaml
helm install kyverno kyverno/kyverno -n kyverno --create-namespace --version 3.9.1 -f k8s/kyverno-values.yaml
kubectl apply -f k8s/policy-allow-registry.yaml -f k8s/policy-verify-supply-chain.yaml

stage/prepare.sh     # records the image digests of every scene
stage/preflight.sh   # every line must say OK
stage/00-happy.sh    # then 01, 02, 02b, 03, 04; AUTO=1 runs without pausing
stage/reset.sh       # restore tag v1 after scene 1
```

## Notes

- `verifyImageSignatures` in Kyverno and `cosign verify` both accept *any* Sigstore bundle from the given identity, including SLSA provenance alone. The policy therefore checks the cosign signature as its own predicate type, `https://sigstore.dev/cosign/sign/v1`.
- `trivy --vex oci` does not verify who signed the VEX attestation. Verify it first (`stage/04-vex.sh`).
- The attacker side lives in a separate repository (`evil-app`) under a second account. Its images are harmless.
