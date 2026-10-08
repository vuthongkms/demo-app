# attacker (evil-app)

Plays the attacker in the "Signed Isn't Enough" demo. The image is harmless: it only prints a banner.

Assumption for every scene: the attacker holds a stolen token that can push to `ghcr.io/vuthongkms/demo-app` (secret `STOLEN_PAT`), as in the tj-actions/changed-files incident.

| Workflow | Scene | What it produces |
|---|---|---|
| `act1-unsigned` | 1 | Optional. On stage, scene 1 pushes the same Dockerfile, built locally, over `demo-app:v1` |
| `act2-self-signed` | 2 | `demo-app:v1-evil`, signed keyless with this repository's identity |
| `act2b-borrow-builder` | 2b | `demo-app:v1-borrowed`, built and signed by the victim's trusted builder from this repository |
