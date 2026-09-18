#!/usr/bin/env bash
# shellcheck disable=SC2015
# Persistence: the admin account, recordings and transcripts live in SQLite plus files on the
# /data volume. Upload and transcribe a recording, take the stack down keeping the volume, bring
# it back, and confirm the admin still logs in and the recording and its transcript survived. Standalone.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"
trap 'compose logs --no-color --tail 100 || true; compose down -v --remove-orphans >/dev/null 2>&1 || true; rm -rf "$TEST_TMP"' EXIT

section "bring the stack up"
compose up -d --pull always >/dev/null 2>&1 || die "compose up failed"
wait_for_code "$APP_URL/login" 200 240 || die "app never became healthy"

section "before restart"
jar="$TEST_TMP/jar"
login "$jar" || die "admin login failed"
TOKEN=$(mint_token "$jar"); export TOKEN
[ -n "$TOKEN" ] || die "could not mint an API token"
rid=$(upload_recording "$REPO_ROOT/tests/fixtures/sample.wav")
[ -n "$rid" ] || die "upload did not return a recording id"
wait_for_transcription "$rid" 240 && pass "recording $rid transcribed before restart" || die "transcription did not complete"

section "full restart (volume preserved)"
compose down >/dev/null 2>&1
compose up -d >/dev/null 2>&1 || die "compose up failed"
wait_for_code "$APP_URL/login" 200 240 && pass "healthy again after restart" || die "not healthy after restart"

section "after restart"
jar2="$TEST_TMP/jar2"
login "$jar2" && pass "the admin account persisted (login still works)" || die "admin login failed after restart"
TOKEN=$(mint_token "$jar2"); export TOKEN
[ -n "$TOKEN" ] || die "could not mint an API token after restart"
assert_eq "the recording still exists after restart" "200" "$(api_code "$APP_URL/api/v1/recordings/$rid")"
assert_contains "the transcript survived the restart (SQLite persisted)" "mock transcript" "$(api_get "/api/v1/recordings/$rid")"

summary
