#!/usr/bin/env bash
# shellcheck disable=SC2015
# Smoke test: bring the stack up (Speakr + the mock provider) and exercise the product flow —
# health, the login/registration security gates, admin login, and a real
# upload -> transcribe -> summarise round trip driven through the token API. Standalone.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"
trap 'compose logs --no-color --tail 120 || true; compose down -v --remove-orphans >/dev/null 2>&1 || true; rm -rf "$TEST_TMP"' EXIT

section "bring the stack up"
compose up -d --pull always >/dev/null 2>&1 || die "compose up failed"
wait_for_code "$APP_URL/login" 200 240 && pass "the login page is served (healthy)" || die "app never became healthy"

section "security gates"
assert_eq "the app root requires a login (redirects)" "302" "$(http_code "$APP_URL/")"
assert_eq "the API rejects a request with no token" "401" "$(http_code "$APP_URL/api/v1/recordings")"
assert_eq "registration is closed (GET /register is 404/redirect, not 200)" "true" \
  "$([ "$(http_code "$APP_URL/register")" != "200" ] && echo true || echo false)"
jarw="$TEST_TMP/jarw"
assert_eq "a wrong password does not authenticate (no 302)" "true" \
  "$([ "$(login_code "$jarw" "$SPEAKR_EMAIL" "definitely-wrong")" != "302" ] && echo true || echo false)"

section "admin login and API token"
jar="$TEST_TMP/jar"
login "$jar" && pass "the admin logs in with ADMIN_EMAIL / ADMIN_PASSWORD" || die "admin login failed"
TOKEN=$(mint_token "$jar"); export TOKEN
[ -n "$TOKEN" ] && pass "a personal API token is minted" || die "could not mint an API token"
assert_eq "the token authenticates against /api/v1/users/me" "200" "$(api_code "$APP_URL/api/v1/users/me")"

section "upload -> transcribe -> summarise"
rid=$(upload_recording "$REPO_ROOT/tests/fixtures/sample.wav")
[ -n "$rid" ] && pass "a recording is uploaded (id $rid)" || die "upload did not return a recording id"
wait_for_transcription "$rid" 240 && pass "the recording reaches COMPLETED (transcription pipeline works)" || die "transcription did not complete"
detail=$(api_get "/api/v1/recordings/$rid")
assert_contains "the transcript from the provider is stored" "mock transcript" "$detail"
assert_contains "the recording is listed for the owner" "template-test" "$(api_get "/api/v1/recordings")"
# Summary is best-effort (depends on auto-summarise settings); the endpoint must at least answer.
assert_eq "the summary endpoint answers for the recording" "200" "$(api_code "$APP_URL/api/v1/recordings/$rid/summary")"

summary
