# JFrog Foundations workshop devcontainer.
#
# Everything expensive belongs in this file rather than in postCreate.sh,
# because GitHub Codespaces prebuilds bake the image but run postCreate per
# Codespace. See docs/repo-setup.md.

ARG NODE_VARIANT=1-22-bookworm
FROM mcr.microsoft.com/devcontainers/javascript-node:${NODE_VARIANT}

# Pinned deliberately. Do not switch this to "curl | sh" against latest: a
# workshop that installs a different CLI version each morning is a workshop
# that breaks in a different way each morning.
ARG JF_CLI_VERSION=2.120.0

# jq is used by scripts/verify.sh and provisioning/prep.sh.
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        jq \
        tree; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Architecture is detected rather than taken from a build arg, so the image
# builds on both an amd64 Codespace and an arm64 laptop.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
        amd64) jf_platform="jfrog-cli-linux-amd64" ;; \
        arm64) jf_platform="jfrog-cli-linux-arm64" ;; \
        *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL \
        -o /usr/local/bin/jf \
        "https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/${JF_CLI_VERSION}/${jf_platform}/jf"; \
    chmod 0755 /usr/local/bin/jf; \
    jf --version

# Stop the JFrog CLI offering to configure a server on first run, which is a
# blocking interactive prompt that confuses a non-interactive postCreate step,
# and silence its upgrade nag so the pinned version stays quiet.
ENV JFROG_CLI_OFFER_CONFIG=false \
    JFROG_CLI_AVOID_NEW_VERSION_WARNING=true

# Record the pinned version so scripts/verify.sh can report drift between the
# version the image was built with and the version actually on PATH.
ENV WORKSHOP_JF_CLI_VERSION=${JF_CLI_VERSION}
