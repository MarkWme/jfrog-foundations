#!/usr/bin/env bash
#
# Interactive JFrog connection setup for the JFrog Foundations workshop.
#
# Run this once, in lab 00. It does three things:
#
#   1. Creates a JFrog CLI server configuration from the details on your
#      handout, so that "jf" commands know where to go and who you are.
#   2. Confirms the connection works.
#   3. Writes the non-secret parts (instance URL, project key) to .env.
#
# Your password or access token is handed to the JFrog CLI and stored in its
# own configuration. It is deliberately NOT written to .env, so that .env stays
# safe to display on a projector.
#
# Usage:
#   bash scripts/setup.sh
#   bash scripts/setup.sh --url https://example.jfrog.io --project user01
#
# Flags are optional and exist so the script can be re-run without retyping.
# You are always prompted for the credential itself.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

ENV_FILE="${REPO_ROOT}/.env"
ENV_EXAMPLE="${REPO_ROOT}/.env.example"

arg_url=""
arg_project=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --url)     arg_url="${2:-}"; shift 2 ;;
        --project) arg_project="${2:-}"; shift 2 ;;
        -h|--help)
            cat <<'EOF'
Interactive JFrog connection setup for the JFrog Foundations workshop.

Run this once, in lab 00. It creates a JFrog CLI server configuration from the
details on your handout, confirms the connection works, and writes the
non-secret parts (instance URL, project key) to .env.

Your password or access token is held by the JFrog CLI in its own
configuration. It is deliberately NOT written to .env.

Usage:
  bash scripts/setup.sh
  bash scripts/setup.sh --url https://example.jfrog.io --project user01

Options:
  --url URL          Instance URL, to avoid retyping it.
  --project KEY      Your project key, to avoid retyping it.
  -h, --help         This message.

You are always prompted for the credential itself.
EOF
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Run 'bash scripts/setup.sh --help' for usage." >&2
            exit 2
            ;;
    esac
done

die() {
    echo "" >&2
    echo "ERROR: $*" >&2
    exit 1
}

# Sets KEY=VALUE in .env, replacing an existing entry or appending a new one,
# and leaving comments and unrelated keys untouched.
set_env_var() {
    local key="$1" value="$2" tmp
    tmp="$(mktemp)"
    if [ -f "${ENV_FILE}" ] && grep -qE "^${key}=" "${ENV_FILE}"; then
        awk -v k="${key}" -v v="${value}" -F= '$1 == k { print k "=" v; next } { print }' \
            "${ENV_FILE}" > "${tmp}"
    else
        [ -f "${ENV_FILE}" ] && cat "${ENV_FILE}" > "${tmp}"
        printf '%s=%s\n' "${key}" "${value}" >> "${tmp}"
    fi
    mv "${tmp}" "${ENV_FILE}"
}

command -v jf >/dev/null 2>&1 || die "The JFrog CLI ('jf') is not on PATH. Run scripts/verify.sh."

echo ""
echo "=============================================================="
echo "  JFrog Foundations: connection setup"
echo "=============================================================="
echo ""
echo "  You need the handout your instructor gave you. It has the"
echo "  instance URL, your username, your password and your project"
echo "  key."
echo ""

# Seed defaults from an existing .env so re-running is cheap.
if [ -f "${ENV_FILE}" ]; then
    # shellcheck disable=SC1091
    set -a; . "${ENV_FILE}"; set +a
fi

SERVER_ID="${JF_SERVER_ID:-workshop}"

# ---------------------------------------------------------------- instance URL

url="${arg_url:-}"
if [ -z "${url}" ]; then
    default_url="${JF_URL:-}"
    if [ -n "${default_url}" ]; then
        read -r -p "JFrog instance URL [${default_url}]: " url
        url="${url:-${default_url}}"
    else
        read -r -p "JFrog instance URL (for example https://example.jfrog.io): " url
    fi
fi

[ -n "${url}" ] || die "An instance URL is required."

# Normalize: strip trailing slashes, add a scheme if the attendee omitted it.
url="${url%%/}"
while [ "${url}" != "${url%/}" ]; do url="${url%/}"; done
case "${url}" in
    http://*|https://*) ;;
    *) url="https://${url}"; echo "  Assuming https, using ${url}" ;;
esac

# A pasted browser URL often carries a path such as /ui/ or /ui/login. The CLI
# wants the platform base URL only, and this is a very common paste error.
case "${url}" in
    */ui|*/ui/*)
        stripped="${url%%/ui*}"
        echo "  That looks like a browser URL. Using the platform base: ${stripped}"
        url="${stripped}"
        ;;
esac

# ----------------------------------------------------------------- project key

project="${arg_project:-}"
if [ -z "${project}" ]; then
    default_project="${JF_PROJECT:-}"
    if [ -n "${default_project}" ]; then
        read -r -p "Your project key [${default_project}]: " project
        project="${project:-${default_project}}"
    else
        read -r -p "Your project key (for example user01): " project
    fi
fi

[ -n "${project}" ] || die "A project key is required. It is on your handout."

# ---------------------------------------------------------------- credentials

echo ""
echo "  How do you want to authenticate?"
echo ""
echo "    1) Username and password   (this is what your handout gives you)"
echo "    2) Access token            (used later, in lab 07)"
echo ""
read -r -p "  Choice [1]: " auth_choice
auth_choice="${auth_choice:-1}"

username=""
secret=""
case "${auth_choice}" in
    1)
        read -r -p "  Username: " username
        [ -n "${username}" ] || die "A username is required."
        # -s so the password is not echoed to a projector.
        read -r -s -p "  Password: " secret
        echo ""
        [ -n "${secret}" ] || die "A password is required."
        ;;
    2)
        read -r -s -p "  Access token: " secret
        echo ""
        [ -n "${secret}" ] || die "An access token is required."
        ;;
    *)
        die "Choose 1 or 2."
        ;;
esac

# ------------------------------------------------------- configure the CLI

echo ""
echo "  Configuring JFrog CLI server '${SERVER_ID}'..."

# Replace rather than update, so re-running after a typo is reliable.
if jf config show "${SERVER_ID}" >/dev/null 2>&1; then
    jf config remove "${SERVER_ID}" --quiet >/dev/null 2>&1 || true
fi

if [ "${auth_choice}" = "1" ]; then
    jf config add "${SERVER_ID}" \
        --url "${url}" \
        --user "${username}" \
        --password "${secret}" \
        --interactive=false >/dev/null
else
    jf config add "${SERVER_ID}" \
        --url "${url}" \
        --access-token "${secret}" \
        --interactive=false >/dev/null
fi

jf config use "${SERVER_ID}" >/dev/null
unset secret

# ------------------------------------------------------------------ confirm

echo "  Testing the connection..."
echo ""

if jf rt ping --server-id "${SERVER_ID}"; then
    echo ""
    echo "  Connection confirmed."
else
    echo ""
    echo "  The connection failed. Nothing has been written to .env."
    echo ""
    echo "  The three things that are usually wrong:"
    echo "    - The URL has a path on the end. It should be just the host,"
    echo "      for example https://example.jfrog.io"
    echo "    - A typo in the password. It is not echoed as you type, so a"
    echo "      mistake is invisible. Use the password exactly as it appears"
    echo "      on your handout: there is no password change to do."
    echo "    - Your account may not be active until you have signed in to the"
    echo "      web UI once."
    echo ""
    echo "  Fix it and run 'bash scripts/setup.sh' again."
    exit 1
fi

# --------------------------------------------------------------- write .env

if [ ! -f "${ENV_FILE}" ] && [ -f "${ENV_EXAMPLE}" ]; then
    cp "${ENV_EXAMPLE}" "${ENV_FILE}"
fi

set_env_var "JF_URL" "${url}"
set_env_var "JF_PROJECT" "${project}"
set_env_var "JF_SERVER_ID" "${SERVER_ID}"

# Repository names are derived here rather than recorded by hand in lab 01.
#
# Lab 01 tells the attendee exactly what to type for each repository key, and
# the platform applies the project key prefix, so both names are fully
# determined the moment we know the project key. Having lab 01 write them with
# a sed command depended on .env already being sourced in that shell, which it
# frequently is not. The result was JF_NPM_VIRTUAL_REPO=-npm-virtual, missing
# the project key, with nothing on screen to say anything had gone wrong.
set_env_var "JF_NPM_VIRTUAL_REPO" "${project}-npm-virtual"
set_env_var "JF_DOCKER_REPO" "${project}-docker-virtual"

echo ""
echo "=============================================================="
echo "  Setup complete"
echo "=============================================================="
echo ""
echo "  Instance:  ${url}"
echo "  Project:   ${project}"
echo "  Server ID: ${SERVER_ID}"
echo ""
echo "  Repository names for later labs, worked out from your project key:"
echo "    npm:     ${project}-npm-virtual"
echo "    docker:  ${project}-docker-virtual"
echo ""
echo "  You create those repositories yourself in lab 01."
echo ""
echo "  Written to .env, which is gitignored. Your credential is held"
echo "  by the JFrog CLI and was not written to .env."
echo ""
echo "  Next: run the health check, then continue with lab 00."
echo ""
echo "      bash scripts/verify.sh"
echo ""
