#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016
# Static validation: syntax, shellcheck, compose, image pin and configuration. No Docker build.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
cd "$REPO_ROOT"
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"

section "syntax"
for f in tests/*.sh; do
  if bash -n "$f" 2>/dev/null; then pass "parses: $f"; else fail "syntax error: $f"; fi
done
if command -v python3 >/dev/null; then
  if python3 -m py_compile tests/mock/mock_openai.py; then pass "mock server compiles"; else fail "mock server syntax error"; fi
fi

section "shellcheck"
if command -v shellcheck >/dev/null; then
  if shellcheck -x -s bash tests/*.sh; then pass "shellcheck tests"; else fail "shellcheck tests"; fi
else
  echo "  SKIP  shellcheck not installed"
fi

section "compose"
if docker compose -f compose.yaml config -q; then pass "compose config"; else fail "compose config"; fi
cfg=$(docker compose -f compose.yaml config --format json)
assert_eq "the expected services are defined" "app mock" "$(jq -r '[.services | keys[]] | sort | join(" ")' <<<"$cfg")"
assert_eq "the app port binds to loopback" "127.0.0.1" "$(jq -r '[.services.app.ports[]? | .host_ip] | join(" ")' <<<"$cfg")"
assert_eq "the app listens on 8899" "8899" "$(jq -r '[.services.app.ports[]? | .target] | join(" ")' <<<"$cfg")"
assert_eq "the /data volume is mounted" "/data" "$(jq -r '[.services.app.volumes[]? | .target] | join(" ")' <<<"$cfg")"
assert_contains "the image is the official Speakr image, pinned by digest" \
  '^\(docker.io/\)\?learnedmachine/speakr:.*@sha256:[0-9a-f]\{64\}$' "$(jq -r '.services.app.image' <<<"$cfg")"

section "configuration"
env_json=$(jq -r '.services.app.environment' <<<"$cfg")
assert_contains "the admin account is wired" 'ADMIN_PASSWORD' "$env_json"
assert_contains "the email deliverability check is skipped" 'true' "$(jq -r '.SKIP_EMAIL_DOMAIN_CHECK' <<<"$env_json")"
assert_contains "a text/LLM model is wired" 'TEXT_MODEL_BASE_URL' "$env_json"
assert_contains "a transcription provider is wired" 'TRANSCRIPTION_BASE_URL' "$env_json"

section "auth posture"
assert_eq "registration is closed by default" "false" "$(jq -r '.services.app.environment.ALLOW_REGISTRATION' <<<"$cfg")"
assert_contains "the compose admin password is a placeholder" 'local-test-only' "$(jq -r '.services.app.environment.ADMIN_PASSWORD' <<<"$cfg")"

section "secrets hygiene"
mapfile -t tracked < <(git ls-files 2>/dev/null | grep . || find . -type f -not -path './.git/*' -not -path './test-output/*')
if [ "${#tracked[@]}" -gt 0 ] && grep -lE '(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' "${tracked[@]}" 2>/dev/null; then
  fail "a credential-shaped string is in the repository"
else
  pass "no credential-shaped strings in ${#tracked[@]} files"
fi

summary
