# Harmless stand-in for a malicious image: it only prints a banner.
FROM busybox:1.37@sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e
# A different value per scene gives each scene's image its own digest.
ARG ACT=borrowed-builder
LABEL demo.act=$ACT
# Links the package to its repository so it inherits the repository's public visibility.
ARG SOURCE=""
LABEL org.opencontainers.image.source=$SOURCE
CMD ["sh", "-c", "echo 'evil-app: this is NOT the real demo-app'; sleep 3600"]
