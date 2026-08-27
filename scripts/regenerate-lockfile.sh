#!/usr/bin/env bash
#
# MAINTAINER TOOL. Attendees never run this, and it is not part of any lab.
#
# Regenerates the committed package-lock.json for a sample application, then
# verifies the two properties the workshop depends on. Run it when the
# dependency set in package.json changes, and at no other time.
#
# This is NOT a reset or toggle script. It does not switch the application
# between vulnerable and clean states, and nothing like that exists in this
# repository, deliberately. See CONTRIBUTING.md. It is a build step that
# produces one committed artifact.
#
# WHY A SCRIPT RATHER THAN AN INSTRUCTION
#
# The lock file, not package.json, is what fixes the transitive vulnerabilities
# the later labs teach. Producing it correctly needs three things to be true at
# once, and getting any of them wrong fails silently:
#
#   1. A CLEAN TREE. npm seeds resolution from whatever is already in
#      node_modules. If modern versions are installed, they satisfy the caret
#      ranges, nothing gets re-resolved, and --before does nothing at all. This
#      is exactly how the first attempt produced minimist 1.2.8 instead of
#      1.2.5.
#   2. PUBLIC NPM. A lock file resolved through Artifactory embeds the tenant
#      hostname in every "resolved" URL, and this repository may never contain a
#      real tenant URL.
#   3. THE DATE CUTOFF. Resolved today, the transitive vulnerabilities patch
#      themselves and lab 07 loses its subject.
#
# Usage:
#   bash scripts/regenerate-lockfile.sh                 # default app
#   bash scripts/regenerate-lockfile.sh apps/node-dashboard
#
# Run it inside a Codespace, which is a clean environment with no npm
# configuration. A maintainer machine configured for JFrog routes npm to
# Artifactory and will fail check 2 below.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${1:-apps/node-dashboard}"

# The cutoff sits just after the newest direct pin, axios@0.21.0 from October
# 2020, so every direct pin still resolves while the transitive tree freezes
# period-accurate. Change this only alongside PLAN.md section 4.
BEFORE_DATE="2020-11-01"

# Transitive versions the later labs require. mkdirp arrives under tar, and
# minimist under mkdirp. minimist 1.2.5 carries CVE-2021-44906 at Critical;
# 1.2.6 and later are patched.
# Plain list rather than an associative array: "declare -A" needs bash 4, and
# stock macOS still ships bash 3.2, where it fails with an unbound variable
# error under "set -u" rather than anything legible.
REQUIRED_TRANSITIVES="mkdirp=0.5.5 minimist=1.2.5"

cd "${REPO_ROOT}"

die() { echo "" >&2; echo "ERROR: $*" >&2; exit 1; }

[ -d "${APP_DIR}" ] || die "No such directory: ${APP_DIR}"
[ -f "${APP_DIR}/package.json" ] || die "No package.json in ${APP_DIR}"
command -v npm >/dev/null 2>&1 || die "npm is not on PATH."
command -v jq  >/dev/null 2>&1 || die "jq is required but not on PATH."

echo ""
echo "=============================================================="
echo "  Regenerating ${APP_DIR}/package-lock.json"
echo "=============================================================="
echo ""
echo "  Cutoff date : ${BEFORE_DATE}"
echo "  Registry    : public npm (required, see header)"
echo ""

# --------------------------------------------------- refuse a routed registry

configured_registry="$(cd "${APP_DIR}" && npm config get registry 2>/dev/null || echo "")"
echo "  npm registry currently resolves to: ${configured_registry:-unknown}"
case "${configured_registry}" in
    https://registry.npmjs.org/*|https://registry.npmjs.org)
        ;;
    *)
        die "npm is not pointed at public npm, it is pointed at
       '${configured_registry}'.

       A lock file resolved through Artifactory would embed that hostname in
       every 'resolved' URL, and this repository must never contain a real
       tenant URL. Run this inside a Codespace, which has no npm configuration.

       This is a deliberate guard, not a routing policy violation: the artifact
       being produced is a public fixture that attendees fork, and lab 07 is
       where resolution moves to Artifactory."
        ;;
esac

# ------------------------------------------------------------- clean and build

echo ""
echo "  Removing node_modules and any existing lock file..."
rm -rf "${APP_DIR}/node_modules" "${APP_DIR}/package-lock.json"

echo "  Resolving with --before=${BEFORE_DATE}..."
echo ""
(
    cd "${APP_DIR}"
    # --prefer-online revalidates cached registry metadata, so a stale packument
    # cannot quietly defeat the date cutoff.
    npm install \
        --before="${BEFORE_DATE}" \
        --prefer-online \
        --no-audit \
        --no-fund
)

LOCK="${APP_DIR}/package-lock.json"
[ -f "${LOCK}" ] || die "npm did not produce ${LOCK}."

# ------------------------------------------------------------------- verify

echo ""
echo "=============================================================="
echo "  Verifying"
echo "=============================================================="
echo ""

failures=0

# 1. Every resolved URL must point at public npm.
echo "  Registry hosts in the lock file:"
hosts="$(jq -r '.packages | to_entries[] | .value.resolved // empty' "${LOCK}" \
    | sed -E 's#^https?://([^/]+)/.*#\1#' | sort -u)"
while IFS= read -r host; do
    [ -z "${host}" ] && continue
    if [ "${host}" = "registry.npmjs.org" ]; then
        echo "    ok    ${host}"
    else
        echo "    FAIL  ${host}   <-- not public npm"
        failures=$((failures + 1))
    fi
done <<< "${hosts}"

# 2. The transitive versions the labs depend on.
echo ""
echo "  Required transitive versions:"
for entry in ${REQUIRED_TRANSITIVES}; do
    pkg="${entry%%=*}"
    want="${entry#*=}"
    got="$(jq -r --arg p "node_modules/${pkg}" '.packages[$p].version // "absent"' "${LOCK}")"
    if [ "${got}" = "${want}" ]; then
        printf '    ok    %-10s %s\n' "${pkg}" "${got}"
    else
        printf '    FAIL  %-10s wanted %s, got %s\n' "${pkg}" "${want}" "${got}"
        failures=$((failures + 1))
    fi
done

echo ""
if [ "${failures}" -gt 0 ]; then
    echo "  ${failures} check(s) failed. DO NOT COMMIT this lock file."
    echo ""
    echo "  If the transitive versions are wrong, --before did not take effect."
    echo "  The usual cause is a node_modules tree that was not removed, which"
    echo "  this script does remove, so a failure here means npm's --before is"
    echo "  not doing what the workshop design assumes. Report it rather than"
    echo "  working around it: lab 07's central exercise depends on this, and"
    echo "  the fallback is to redesign that lab around a direct dependency."
    echo ""
    exit 1
fi

echo "  All checks passed. Commit ${LOCK}."
echo ""
echo "  Then confirm the tree from npm's own point of view:"
echo "      cd ${APP_DIR} && npm ls minimist mkdirp"
echo ""
