#!/usr/bin/env bash
#
# Runs once per Codespace, after the container is created.
#
# Kept deliberately cheap. Anything slow belongs in the Dockerfile or in
# updateContent.sh, both of which a Codespaces prebuild bakes into the image.
# See docs/repo-setup.md.
#
# This script must succeed with no JFrog credentials present. Lab 00 is where
# credentials get configured.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

# Safety net for the unprebuilt path. If updateContent.sh ran, node_modules is
# already present and this loop does nothing. If a fork did not inherit the
# upstream prebuild and something interrupted the create, this recovers.
if [ -d apps ]; then
    while IFS= read -r manifest; do
        app_dir="$(dirname "${manifest}")"
        if [ ! -d "${app_dir}/node_modules" ]; then
            echo "postCreate: ${app_dir} has no node_modules, installing now."
            bash .devcontainer/updateContent.sh
            break
        fi
    done < <(find apps -mindepth 2 -maxdepth 2 -name package.json -not -path '*/node_modules/*' | sort)
fi

echo ""
echo "=============================================================="
echo "  JFrog Foundations"
echo "=============================================================="
echo ""
echo "  Your workshop environment is ready."
echo ""
echo "  Start here:  labs/00-setup/README.md"
echo ""
echo "  Lab 00 takes you through connecting this Codespace to the"
echo "  workshop JFrog Platform instance. You will need the handout"
echo "  your instructor gave you: instance URL, username, password"
echo "  and your project key."
echo ""
echo "  No JFrog credentials are configured yet. That is expected."
echo ""
echo "=============================================================="
echo ""

# Confirm tool availability before the attendee starts. verify.sh exits
# non-zero if a required tool is missing, but a failed health check must not
# fail container creation: a usable container with a clear warning is far
# better than a Codespace that refuses to open.
if [ -x scripts/verify.sh ] || [ -f scripts/verify.sh ]; then
    echo "Running environment health check..."
    echo ""
    if ! bash scripts/verify.sh; then
        echo ""
        echo "WARNING: the environment health check reported problems above."
        echo "         Show this output to your instructor before starting lab 00."
        echo "         See docs/codespaces-troubleshooting.md."
    fi
else
    echo "WARNING: scripts/verify.sh not found, skipping health check."
fi

exit 0
