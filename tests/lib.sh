#!/usr/bin/env bash
# shellcheck disable=SC2015
# Shared helpers for speakr-railway tests. Source this file; do not execute it.
#
# The admin password is never echoed. Login is a Flask-WTF form POST to /login
# (email + password + csrf_token); on success the app 302-redirects to "/". A
# personal API token is then minted (POST /api/tokens) so the /api/v1 calls can
# use a Bearer header, which bypasses CSRF the way a real API client does.

: "${APP_URL:=http://localhost:${SPEAKR_TEST_PORT:-18899}}"
: "${TEST_TIMEOUT:=300}"
: "${SPEAKR_EMAIL:=${SPEAKR_TEST_EMAIL:-admin@example.com}}"
: "${SPEAKR_PASSWORD:=${SPEAKR_TEST_PASSWORD:-local-test-only-admin-password}}"

TEST_TMP="${TEST_TMP:-$(mktemp -d)}"
export TEST_TMP
_PASS=0; _FAIL=0

pass() { _PASS=$((_PASS+1)); printf '  PASS  %s\n' "$*"; }
fail() { _FAIL=$((_FAIL+1)); printf '  FAIL  %s\n' "$*" >&2; }
die()  { printf 'FATAL: %s\n' "$*" >&2; exit 1; }
section() { printf '\n== %s ==\n' "$*"; }
summary() { printf '\n%d passed, %d failed\n' "$_PASS" "$_FAIL"; [ "$_FAIL" -eq 0 ]; }

assert_eq() { if [ "$2" = "$3" ]; then pass "$1 ($3)"; else fail "$1: expected [$2] got [$3]"; fi; }
assert_contains() { if grep -q -- "$2" <<<"$3"; then pass "$1"; else fail "$1: missing [$2]"; fi; }

http_code() { curl -s -o /dev/null -w '%{http_code}' --max-time 30 "$@" || true; }

wait_for_code() {
  local url=$1 want=$2 timeout=${3:-$TEST_TIMEOUT} start code
  start=$(date +%s)
  while :; do
    code=$(http_code "$url")
    [ "$code" = "$want" ] && return 0
    if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then printf 'timed out waiting for %s -> %s (last %s)\n' "$url" "$want" "$code" >&2; return 1; fi
    sleep 3
  done
}

compose() { docker compose -f "$REPO_ROOT/compose.yaml" "$@"; }

# Extract the hidden csrf_token value from an HTML page on stdin.
_extract_csrf() { grep -oE 'name="csrf_token"[^>]*value="[^"]+"' | sed -E 's/.*value="([^"]+)".*/\1/' | head -1; }

# login JAR -> 0 if the admin credentials authenticate. Writes the session cookie to
# JAR and the session's CSRF token to $TEST_TMP/csrf (reused for later browser-style POSTs).
login() {
  local jar=$1 page csrf code
  page=$(curl -s -c "$jar" --max-time 30 "$APP_URL/login")
  csrf=$(printf '%s' "$page" | _extract_csrf)
  [ -n "$csrf" ] || { echo "no csrf token on /login" >&2; return 1; }
  printf '%s' "$csrf" > "$TEST_TMP/csrf"
  # A successful login 302-redirects to "/"; a failed one re-renders /login as 200.
  code=$(curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{http_code}' --max-time 30 -X POST "$APP_URL/login" \
    --data-urlencode "email=$SPEAKR_EMAIL" \
    --data-urlencode "password=$SPEAKR_PASSWORD" \
    --data-urlencode "csrf_token=$csrf")
  [ "$code" = "302" ]
}

# login_code JAR EMAIL PASSWORD -> prints the HTTP status of a login attempt (for negative tests).
login_code() {
  local jar=$1 email=$2 password=$3 page csrf
  page=$(curl -s -c "$jar" --max-time 30 "$APP_URL/login")
  csrf=$(printf '%s' "$page" | _extract_csrf)
  curl -s -c "$jar" -b "$jar" -o /dev/null -w '%{http_code}' --max-time 30 -X POST "$APP_URL/login" \
    --data-urlencode "email=$email" --data-urlencode "password=$password" --data-urlencode "csrf_token=$csrf"
}

# mint_token JAR [NAME] -> prints a plaintext personal API token (requires a logged-in JAR).
mint_token() {
  local jar=$1 name=${2:-speakr-tests} csrf resp
  csrf=$(cat "$TEST_TMP/csrf" 2>/dev/null)
  resp=$(curl -s -b "$jar" --max-time 30 -X POST "$APP_URL/api/tokens" \
    -H 'Content-Type: application/json' -H "X-CSRFToken: $csrf" \
    --data "$(jq -nc --arg n "$name" '{name:$n}')")
  jq -r '.token // empty' <<<"$resp"
}

# Bearer-token API helpers.
api_get()  { curl -s --max-time 30 -H "Authorization: Bearer $TOKEN" "$APP_URL$1"; }
api_code() { curl -s -o /dev/null -w '%{http_code}' --max-time 30 -H "Authorization: Bearer $TOKEN" "$@"; }

# Upload the sample recording via the token API; prints the new recording id.
upload_recording() {
  local file=$1 resp
  resp=$(curl -s --max-time 120 -H "Authorization: Bearer $TOKEN" -X POST "$APP_URL/api/v1/recordings/upload" \
    -F "file=@$file" -F "title=template-test")
  jq -r '.id // .recording.id // empty' <<<"$resp"
}

# Poll a recording's status until it reaches COMPLETED (0) or FAILED (1) or times out (2).
wait_for_transcription() {
  local id=$1 timeout=${2:-240} start status
  start=$(date +%s)
  while :; do
    status=$(api_get "/api/v1/recordings/$id/status" | jq -r '.status // empty')
    case "$status" in
      COMPLETED) return 0 ;;
      FAILED)    echo "transcription FAILED: $(api_get "/api/v1/recordings/$id/status")" >&2; return 1 ;;
    esac
    if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then echo "timed out; last status=$status" >&2; return 2; fi
    sleep 3
  done
}
