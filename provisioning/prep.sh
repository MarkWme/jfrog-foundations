#!/usr/bin/env bash
#
# JFrog Foundations: instructor prep script.
#
# Run this once against a fresh trial instance before a delivery. It creates
# one JFrog Project per attendee, one user per attendee, assigns each user to
# their project, and writes a handout you can distribute in the room.
#
# It creates NOTHING ELSE, on purpose. Repositories, Curation policies, Xray
# policies, watches, builds and access tokens are all workshop content and are
# created by attendees during the labs. If you find yourself wanting to
# pre-create something here to make a lab run more smoothly, the lab needs
# rewriting. See provisioning/README.md.
#
# Safe to re-run. Anything that already exists is left alone.
#
# Usage:
#   export JF_ACCESS_TOKEN=<platform admin token>
#   ./prep.sh --url https://example.jfrog.io --count 15
#
#   ./prep.sh --url https://example.jfrog.io --count 15 --dry-run
#
# Requires: bash, jf (the JFrog CLI), jq

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------- defaults

JF_URL="${JF_URL:-}"
JF_TOKEN="${JF_ACCESS_TOKEN:-}"
COUNT=""
PREFIX="user"
EMAIL_DOMAIN="workshop.invalid"
OUT_DIR="${SCRIPT_DIR}/out"
DRY_RUN=0

# The project role assigned to each attendee. They need to create
# repositories, policies, watches and builds inside their own project, so this
# has to be the project-administrator role rather than Developer.
#
# VERIFY: confirm the exact role name against a live tenant. The JFrog REST API
# reference documents the roles field as an array of strings without listing the
# built-in names, so this string is a best guess taken from the platform UI.
# If provisioning fails on the role assignment step with a 400, list the
# available roles for a project and set --role accordingly.
# https://docs.jfrog.com/projects/reference/addorupdateprojectuser
ROLE="Project Admin"

usage() {
    cat <<'EOF'
JFrog Foundations: instructor prep script.

Creates one JFrog Project per attendee, one user per attendee, and assigns
each user to their project. Then writes a handout to distribute in the room.

It creates NOTHING ELSE, on purpose. Repositories, Curation policies, Xray
policies, watches, builds and access tokens are all workshop content, created
by attendees during the labs. See provisioning/README.md.

Safe to re-run. Anything that already exists is left alone.

Usage:
  export JF_ACCESS_TOKEN=<platform admin token>
  ./prep.sh --url https://example.jfrog.io --count 15
  ./prep.sh --url https://example.jfrog.io --count 15 --dry-run

Requires: bash, jf (the JFrog CLI), jq

Options:
  --url URL           JFrog platform base URL, no trailing slash.
                      Falls back to $JF_URL.
  --token TOKEN       Platform admin access token.
                      Falls back to $JF_ACCESS_TOKEN. Prefer the env var:
                      a token on the command line lands in your shell history.
  --count N           Number of attendees. Required.
  --prefix STR        Attendee key prefix. Default: user
                      Produces user01, user02, ...
  --role NAME         Project role to assign. Default: "Project Admin"
  --email-domain DOM  Domain for generated user emails.
                      Default: workshop.invalid (a reserved TLD, so these
                      addresses cannot reach a real mailbox)
  --out DIR           Where to write the handout. Default: provisioning/out
  --dry-run           Print what would be created, change nothing.
  -h, --help          This message.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --url)          JF_URL="${2:-}"; shift 2 ;;
        --token)        JF_TOKEN="${2:-}"; shift 2 ;;
        --count)        COUNT="${2:-}"; shift 2 ;;
        --prefix)       PREFIX="${2:-}"; shift 2 ;;
        --role)         ROLE="${2:-}"; shift 2 ;;
        --email-domain) EMAIL_DOMAIN="${2:-}"; shift 2 ;;
        --out)          OUT_DIR="${2:-}"; shift 2 ;;
        --dry-run)      DRY_RUN=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

for tool in jf jq; do
    command -v "${tool}" >/dev/null 2>&1 || die "'${tool}' is required but not on PATH."
done

[ -n "${JF_URL}" ]   || die "No instance URL. Pass --url or set JF_URL."
[ -n "${JF_TOKEN}" ] || die "No admin token. Set JF_ACCESS_TOKEN or pass --token."
[ -n "${COUNT}" ]    || die "No attendee count. Pass --count N."

case "${COUNT}" in
    ''|*[!0-9]*) die "--count must be a whole number, got '${COUNT}'." ;;
esac
[ "${COUNT}" -ge 1 ] || die "--count must be at least 1."
[ "${COUNT}" -le 99 ] || die "--count above 99 would break the two-digit key format."

# Normalize the URL the same way scripts/setup.sh does, so a pasted browser URL
# does not produce a confusing 404 on every call.
while [ "${JF_URL}" != "${JF_URL%/}" ]; do JF_URL="${JF_URL%/}"; done
case "${JF_URL}" in
    http://*|https://*) ;;
    *) JF_URL="https://${JF_URL}" ;;
esac
case "${JF_URL}" in
    */ui|*/ui/*) JF_URL="${JF_URL%%/ui*}" ;;
esac

# ---------------------------------------------------------------- plumbing

RESP="$(mktemp)"
ERRF="$(mktemp)"

# The JFrog CLI keeps its server configurations in JFROG_CLI_HOME_DIR. Pointing
# that at a throwaway directory does two useful things: it guarantees this
# script cannot touch or clobber the server profiles you already have, and it
# keeps the admin token out of every command line, where "ps" would show it, by
# putting it in one mode-600 file that is deleted on exit.
PREP_HOME="$(mktemp -d)"
export JFROG_CLI_HOME_DIR="${PREP_HOME}"
export JFROG_CLI_OFFER_CONFIG=false
export JFROG_CLI_AVOID_NEW_VERSION_WARNING=true

SERVER_ID="workshop-prep"

cleanup() { rm -rf "${RESP}" "${ERRF}" "${PREP_HOME}"; }
trap cleanup EXIT

jf config add "${SERVER_ID}" \
    --url "${JF_URL}" \
    --access-token "${JF_TOKEN}" \
    --interactive=false >/dev/null 2>&1 \
    || die "Could not create a temporary JFrog CLI configuration for ${JF_URL}."

# api METHOD PATH [JSON_BODY] -> prints the HTTP status code, body lands in $RESP
#
# Uses "jf api", the JFrog CLI's authenticated passthrough to any JFrog Platform
# REST endpoint. It reads better than a hand-built curl, and an SE or attendee
# reading this script picks up a command they can use themselves, which a raw
# curl does not teach.
#
# jf api writes the response body to stdout and a line of the form
#     12:00:25 [Info] Http Status: 409
# to stderr, exiting non-zero for any non-2xx while still printing the body.
# This script branches on the status code rather than the exit code, because the
# distinction matters: 409 means "already exists", which is success here, while
# 400 on the role step means the role name is wrong.
api() {
    local method="$1" path="$2" body="${3:-}"
    local -a args=(api "${path}" --method "${method}" --server-id "${SERVER_ID}")
    [ -n "${body}" ] && args+=(--header "Content-Type: application/json" --data "${body}")

    : > "${RESP}"; : > "${ERRF}"
    jf "${args[@]}" >"${RESP}" 2>"${ERRF}" || true

    local status
    status="$(sed -n 's/.*Http Status: \([0-9][0-9][0-9]\).*/\1/p' "${ERRF}" | tail -n 1)"

    if [ -z "${status}" ]; then
        # No status line means the request never reached the platform at all:
        # DNS, TLS, or a refused connection. The CLI's own message is the useful
        # part, so put it where the caller's error handling will print it.
        cat "${ERRF}" >> "${RESP}"
        echo "000"
    else
        echo "${status}"
    fi
}

# Deliberately excludes characters that are misread when typed from a printed
# handout: i, l, o, 0, 1.
gen_password() {
    local letters digits
    letters="$( set +o pipefail; LC_ALL=C tr -dc 'abcdefghjkmnpqrstuvwxyz' < /dev/urandom | head -c 6 )"
    digits="$( set +o pipefail; LC_ALL=C tr -dc '23456789' < /dev/urandom | head -c 4 )"
    printf 'Frog-%s%s' "${letters}" "${digits}"
}

step_ok=0
step_skip=0
step_fail=0

# ---------------------------------------------------------------- preflight

echo ""
echo "=============================================================="
echo "  JFrog Foundations: attendee provisioning"
echo "=============================================================="
echo ""
echo "  Instance : ${JF_URL}"
echo "  Attendees: ${COUNT}  (${PREFIX}01 .. $(printf '%s%02d' "${PREFIX}" "${COUNT}"))"
echo "  Role     : ${ROLE}"
if [ "${DRY_RUN}" -eq 1 ]; then
    echo "  Mode     : DRY RUN, nothing will be created"
fi
echo ""

echo "Checking the admin token..."
code="$(api GET "/access/api/v1/projects")"
case "${code}" in
    200) echo "  Token accepted, and it can list projects." ;;
    401) die "Authentication failed (401). The token is wrong or expired." ;;
    403) die "Authorization failed (403). This token is not a platform admin token." ;;
    000) die "Could not reach ${JF_URL} at all. The CLI reported:
$(cat "${RESP}")" ;;
    *)   die "Unexpected response ${code} from ${JF_URL}/access/api/v1/projects. Body: $(cat "${RESP}")" ;;
esac
echo ""

# ---------------------------------------------------------------- main loop

mkdir -p "${OUT_DIR}"
HANDOUT_MD="${OUT_DIR}/handout.md"
HANDOUT_CSV="${OUT_DIR}/handout.csv"
rows=()

for i in $(seq 1 "${COUNT}"); do
    key="$(printf '%s%02d' "${PREFIX}" "${i}")"
    username="${key}"
    email="${key}@${EMAIL_DOMAIN}"
    password="$(gen_password)"
    password_note=""

    echo "[${key}]"

    if [ "${DRY_RUN}" -eq 1 ]; then
        echo "  would create project ${key}"
        echo "  would create user    ${username} <${email}>"
        echo "  would assign role    ${ROLE}"
        rows+=("${key}|${key}|${username}|${password}|dry run")
        continue
    fi

    # 1. Project.
    # https://docs.jfrog.com/projects/reference/createProject
    project_body="$(jq -n \
        --arg key "${key}" \
        --arg name "Workshop ${key}" \
        '{
            project_key: $key,
            display_name: $name,
            description: "JFrog Foundations workshop attendee project. Safe to delete after the delivery.",
            admin_privileges: {
                manage_members: true,
                manage_resources: true,
                index_resources: true
            }
        }')"

    code="$(api POST "/access/api/v1/projects" "${project_body}")"
    case "${code}" in
        200|201) echo "  project  created"; step_ok=$((step_ok + 1)) ;;
        409)     echo "  project  already exists, left alone"; step_skip=$((step_skip + 1)) ;;
        *)       echo "  project  FAILED (${code}): $(jq -r '.errors[0].message // .message // .' "${RESP}" 2>/dev/null || cat "${RESP}")"
                 step_fail=$((step_fail + 1)) ;;
    esac

    # 2. User.
    # https://docs.jfrog.com/administration/reference/createuser
    user_body="$(jq -n \
        --arg username "${username}" \
        --arg email "${email}" \
        --arg password "${password}" \
        '{
            username: $username,
            email: $email,
            password: $password,
            admin: false,
            profile_updatable: true,
            disable_ui_access: false,
            internal_password_disabled: false
        }')"

    code="$(api POST "/access/api/v2/users" "${user_body}")"
    case "${code}" in
        200|201) echo "  user     created"; step_ok=$((step_ok + 1)) ;;
        409)
            echo "  user     already exists, password NOT changed"
            password="(unchanged, see previous handout)"
            password_note="existing user"
            step_skip=$((step_skip + 1))
            ;;
        *)  echo "  user     FAILED (${code}): $(jq -r '.errors[0].message // .message // .' "${RESP}" 2>/dev/null || cat "${RESP}")"
            password="(not set, creation failed)"
            password_note="FAILED"
            step_fail=$((step_fail + 1))
            ;;
    esac

    # 3. Membership.
    # https://docs.jfrog.com/projects/reference/addorupdateprojectuser
    role_body="$(jq -n --arg role "${ROLE}" '{ roles: [ $role ] }')"
    code="$(api PUT "/access/api/v1/projects/${key}/users/${username}" "${role_body}")"
    case "${code}" in
        200|201|204) echo "  role     assigned (${ROLE})"; step_ok=$((step_ok + 1)) ;;
        409)         echo "  role     already assigned"; step_skip=$((step_skip + 1)) ;;
        400)
            echo "  role     FAILED (400): $(jq -r '.errors[0].message // .message // .' "${RESP}" 2>/dev/null || cat "${RESP}")"
            echo "           A 400 here usually means the role name '${ROLE}' is wrong"
            echo "           for this instance. See the VERIFY note at the top of"
            echo "           this script and re-run with --role."
            step_fail=$((step_fail + 1))
            ;;
        *)  echo "  role     FAILED (${code}): $(jq -r '.errors[0].message // .message // .' "${RESP}" 2>/dev/null || cat "${RESP}")"
            step_fail=$((step_fail + 1))
            ;;
    esac

    rows+=("${key}|${key}|${username}|${password}|${password_note}")
done

# ---------------------------------------------------------------- handout

if [ "${DRY_RUN}" -eq 1 ]; then
    echo ""
    echo "Dry run complete. No handout written."
    exit 0
fi

{
    echo "# JFrog Foundations: attendee handout"
    echo ""
    echo "Instance URL: \`${JF_URL}\`"
    echo ""
    echo "Hand one row to each attendee. They need all four values in lab 00."
    echo ""
    echo "On first sign-in to the web UI the platform may require a password"
    echo "change. That is expected. If an attendee changes their password, the"
    echo "new one is what \`scripts/setup.sh\` needs."
    echo ""
    echo "| Attendee | Project key | Username | Password | Notes |"
    echo "| --- | --- | --- | --- | --- |"
    for row in "${rows[@]}"; do
        IFS='|' read -r a p u pw n <<< "${row}"
        echo "| ${a} | \`${p}\` | \`${u}\` | \`${pw}\` | ${n} |"
    done
    echo ""
    echo "---"
    echo ""
    echo "Teardown: delete the projects, then delete the trial instance. There"
    echo "is no per-attendee cleanup to run. See provisioning/README.md."
} > "${HANDOUT_MD}"

{
    echo "attendee,project_key,username,password,notes"
    for row in "${rows[@]}"; do
        IFS='|' read -r a p u pw n <<< "${row}"
        echo "${a},${p},${u},${pw},${n}"
    done
} > "${HANDOUT_CSV}"

chmod 600 "${HANDOUT_MD}" "${HANDOUT_CSV}"

echo ""
echo "=============================================================="
echo "  Done"
echo "=============================================================="
echo ""
echo "  Created: ${step_ok}   Already present: ${step_skip}   Failed: ${step_fail}"
echo ""
echo "  Handout: ${HANDOUT_MD}"
echo "           ${HANDOUT_CSV}"
echo ""
echo "  These files contain attendee passwords. provisioning/out/ is"
echo "  gitignored. Do not commit them and do not paste them into chat."
echo ""

if [ "${step_fail}" -gt 0 ]; then
    echo "  Some steps failed. Read the output above before the delivery."
    echo ""
    exit 1
fi
