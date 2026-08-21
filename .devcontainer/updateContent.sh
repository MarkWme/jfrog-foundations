#!/usr/bin/env bash
#
# Installs dependencies for every sample application under apps/.
#
# This runs during a Codespaces prebuild, so its output is baked into the
# prebuilt image and a prebuilt Codespace starts with node_modules already in
# place. It also runs on a normal (unprebuilt) create, just more slowly.
#
# It must succeed when apps/ is empty, which is the state until Phase 2 adds
# the sample application.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

if [ ! -d apps ]; then
    echo "updateContent: no apps/ directory yet, nothing to install."
    exit 0
fi

found_any=0

# NOTE: --no-audit and --no-fund are not cosmetic. The sample applications ship
# with known-vulnerable dependencies on purpose, and npm's own audit summary
# would announce the findings during container creation, before the attendee has
# reached the lab that is supposed to reveal them. The workshop uses "jf audit",
# not "npm audit".
while IFS= read -r manifest; do
    app_dir="$(dirname "${manifest}")"
    found_any=1
    echo "updateContent: installing dependencies in ${app_dir}"

    if [ -f "${app_dir}/package-lock.json" ]; then
        ( cd "${app_dir}" && npm ci --no-audit --no-fund )
    else
        echo "updateContent: no package-lock.json in ${app_dir}, falling back to npm install."
        echo "updateContent: a committed lock file is expected here, see apps/*/README.md."
        ( cd "${app_dir}" && npm install --no-audit --no-fund )
    fi
done < <(find apps -mindepth 2 -maxdepth 2 -name package.json -not -path '*/node_modules/*' | sort)

if [ "${found_any}" -eq 0 ]; then
    echo "updateContent: no application manifests found under apps/, nothing to install."
fi

echo "updateContent: done."
