#!/usr/bin/env bash
#
# Environment health check for the JFrog Foundations workshop.
#
# Run at the end of container creation, and again by lab 00 after you have
# configured your JFrog connection.
#
# Two sections, and the difference matters:
#
#   Tools           Hard requirements. A failure here means the container is
#                   not usable and the instructor needs to know now.
#   JFrog connection Soft until lab 00 is complete. Before then, "not
#                   configured" is the correct and expected state.
#
# Exit codes:  0  every required tool present
#              1  a required tool is missing

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

PASS="  [ ok ]"
FAIL="  [FAIL]"
WARN="  [warn]"
INFO="  [ -- ]"

failures=0
warnings=0

heading() {
    echo ""
    echo "$1"
    echo "------------------------------------------------------------"
}

# require <command> <human name> [version command...]
require() {
    local cmd="$1" name="$2"
    shift 2
    if command -v "${cmd}" >/dev/null 2>&1; then
        local version=""
        if [ "$#" -gt 0 ]; then
            version="$("$@" 2>/dev/null | head -n 1)"
        fi
        printf '%s %-16s %s\n' "${PASS}" "${name}" "${version}"
    else
        printf '%s %-16s not found on PATH\n' "${FAIL}" "${name}"
        failures=$((failures + 1))
    fi
}

heading "Tools"

require node   "Node.js"    node --version
require npm    "npm"        npm --version
require jf     "JFrog CLI"  jf --version
require docker "Docker"     docker --version
require gh     "GitHub CLI" gh --version
require jq     "jq"         jq --version
require git    "Git"        git --version

# Node major version. The workshop targets Node 20 LTS. A different major is
# not necessarily fatal, but it is worth surfacing before it causes a confusing
# failure in a later lab.
if command -v node >/dev/null 2>&1; then
    node_major="$(node --version | sed -E 's/^v([0-9]+).*/\1/')"
    if [ "${node_major}" != "20" ]; then
        printf '%s %-16s expected Node 20 LTS, found major version %s\n' \
            "${WARN}" "Node version" "${node_major}"
        warnings=$((warnings + 1))
    fi
fi

# Drift between the JFrog CLI version pinned in the devcontainer image and the
# one actually on PATH. This catches a hand-installed CLI shadowing the pinned
# one, which produces baffling behavior three labs later.
if command -v jf >/dev/null 2>&1 && [ -n "${WORKSHOP_JF_CLI_VERSION:-}" ]; then
    jf_actual="$(jf --version 2>/dev/null | awk '{print $NF}')"
    if [ "${jf_actual}" != "${WORKSHOP_JF_CLI_VERSION}" ]; then
        printf '%s %-16s image pinned %s, PATH has %s\n' \
            "${WARN}" "JFrog CLI pin" "${WORKSHOP_JF_CLI_VERSION}" "${jf_actual}"
        warnings=$((warnings + 1))
    fi
fi

# Docker daemon reachability, which is separate from the client being present.
# The container scanning labs need the daemon, not just the CLI.
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        printf '%s %-16s daemon reachable\n' "${PASS}" "Docker daemon"
    else
        printf '%s %-16s client present but daemon not reachable yet\n' \
            "${WARN}" "Docker daemon"
        echo "         This is common in the first few seconds after a Codespace"
        echo "         starts. Re-run scripts/verify.sh in a moment. If it"
        echo "         persists, see docs/codespaces-troubleshooting.md."
        warnings=$((warnings + 1))
    fi
fi

heading "Workshop configuration"

if [ -f .env ]; then
    printf '%s %-16s present\n' "${PASS}" ".env"
    # shellcheck disable=SC1091
    set -a; . ./.env; set +a
else
    printf '%s %-16s not created yet, lab 00 writes this\n' "${INFO}" ".env"
fi

if [ -n "${JF_URL:-}" ]; then
    printf '%s %-16s %s\n' "${PASS}" "JF_URL" "${JF_URL}"
else
    printf '%s %-16s not set yet, lab 00 sets this\n' "${INFO}" "JF_URL"
fi

if [ -n "${JF_PROJECT:-}" ]; then
    printf '%s %-16s %s\n' "${PASS}" "JF_PROJECT" "${JF_PROJECT}"
else
    printf '%s %-16s not set yet, lab 00 sets this\n' "${INFO}" "JF_PROJECT"
fi

heading "JFrog connection"

server_id="${JF_SERVER_ID:-workshop}"

if ! command -v jf >/dev/null 2>&1; then
    printf '%s %-16s skipped, JFrog CLI missing\n' "${INFO}" "connection"
elif ! jf config show "${server_id}" >/dev/null 2>&1; then
    printf '%s %-16s no server named "%s" configured yet\n' \
        "${INFO}" "connection" "${server_id}"
    echo ""
    echo "  This is the expected state before lab 00. To configure it now:"
    echo ""
    echo "      bash scripts/setup.sh"
    echo ""
else
    printf '%s %-16s server "%s" configured\n' "${PASS}" "connection" "${server_id}"

    if jf rt ping --server-id "${server_id}" >/dev/null 2>&1; then
        printf '%s %-16s Artifactory reachable and credentials accepted\n' \
            "${PASS}" "jf rt ping"
    else
        printf '%s %-16s failed\n' "${WARN}" "jf rt ping"
        echo "         The server is configured but Artifactory did not answer."
        echo "         Check the URL and credentials on your handout, then re-run"
        echo "         bash scripts/setup.sh. See labs/00-setup/README.md."
        warnings=$((warnings + 1))
    fi

    # Project visibility. Reported for information only: a project you cannot
    # see yet is a permissions question for your instructor, not a broken
    # container.
    #
    # VERIFY: confirm against a live tenant that this endpoint returns 200 with
    # an empty array for a project that exists but has no repositories, and a
    # non-200 for a project key that does not exist. If it returns 200 either
    # way, this check proves nothing and should be replaced by the UI
    # confirmation step in lab 00.
    # https://docs.jfrog.com/artifactory/reference/get-repositories
    if [ -n "${JF_PROJECT:-}" ]; then
        if jf rt curl -s -XGET "/api/repositories?project=${JF_PROJECT}" \
            --server-id "${server_id}" >/dev/null 2>&1; then
            printf '%s %-16s project "%s" queried successfully\n' \
                "${PASS}" "project access" "${JF_PROJECT}"
        else
            printf '%s %-16s could not query project "%s"\n' \
                "${INFO}" "project access" "${JF_PROJECT}"
        fi
    fi
fi

heading "Summary"

if [ "${failures}" -gt 0 ]; then
    echo "  ${failures} required tool(s) missing. This container is not ready."
    echo "  Show this output to your instructor."
    echo "  See docs/codespaces-troubleshooting.md."
    echo ""
    exit 1
fi

if [ "${warnings}" -gt 0 ]; then
    echo "  All required tools present, with ${warnings} warning(s) above."
else
    echo "  All required tools present."
fi
echo ""
exit 0
