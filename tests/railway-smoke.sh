#!/usr/bin/env bash
# shellcheck disable=SC2015
# Live test of a deployed template: the flows the local smoke covers, over HTTPS.
#
#   ADMIN_PASSWORD_FILE=./admin-password tests/railway-smoke.sh https://<app-domain>
#
# Optional:
#   SPEAKR_EMAIL           admin email (default admin@example.com)
#   SPEAKR_SKIP_TRANSCRIBE 1 to skip the upload->transcribe leg (when no transcription
#                          provider is reachable from the deployment). Off by default.
# The password is read from a file (never an argument, never printed).
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
[ $# -ge 1 ] || { sed -n '3,12p' "$0"; exit 2; }
APP_URL=${1%/}; export APP_URL
: "${ADMIN_PASSWORD_FILE:?set ADMIN_PASSWORD_FILE}"
SPEAKR_PASSWORD=$(tr -d '\n' < "$ADMIN_PASSWORD_FILE"); export SPEAKR_PASSWORD
: "${SPEAKR_EMAIL:=admin@example.com}"; export SPEAKR_EMAIL
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"
trap 'rm -rf "$TEST_TMP"' EXIT

section "availability over HTTPS"
wait_for_code "$APP_URL/login" 200 300 && pass "/login returns 200 over HTTPS" || die "not healthy"

section "security gates over HTTPS"
assert_eq "the app root requires a login (redirects)" "302" "$(http_code "$APP_URL/")"
assert_eq "the API rejects a request with no token" "401" "$(http_code "$APP_URL/api/v1/recordings")"
jarw="$TEST_TMP/jarw"
assert_eq "a wrong password does not authenticate (no 302)" "true" \
  "$([ "$(login_code "$jarw" "$SPEAKR_EMAIL" "definitely-wrong")" != "302" ] && echo true || echo false)"

section "admin login and API token over HTTPS"
jar="$TEST_TMP/jar"
login "$jar" && pass "the admin logs in with ADMIN_EMAIL / ADMIN_PASSWORD" || die "admin login failed"
TOKEN=$(mint_token "$jar"); export TOKEN
[ -n "$TOKEN" ] && pass "a personal API token is minted" || die "could not mint an API token"
assert_eq "the token authenticates against /api/v1/users/me" "200" "$(api_code "$APP_URL/api/v1/users/me")"

if [ "${SPEAKR_SKIP_TRANSCRIBE:-0}" = "1" ]; then
  echo "  SKIP  upload -> transcribe (SPEAKR_SKIP_TRANSCRIBE=1)"
else
  section "upload -> transcribe over HTTPS"
  rid=$(upload_recording "$REPO_ROOT/tests/fixtures/sample.wav")
  [ -n "$rid" ] && pass "a recording is uploaded (id $rid)" || die "upload did not return a recording id"
  wait_for_transcription "$rid" 300 && pass "the recording reaches COMPLETED" || die "transcription did not complete"
  assert_contains "the recording is listed for the owner" "template-test" "$(api_get "/api/v1/recordings")"
fi

summary
