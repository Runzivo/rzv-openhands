#!/usr/bin/env bash
# Live end-to-end test of bin/rzv-openhands-backend on Runzivo shared: start an Agent Server
# in a sandbox, run one task through it with the OpenHands SDK, stop, start, reconnect, delete.
#
#   SDK_PYTHON=<python with openhands-sdk and openhands-tools 1.60.1> OPENAI_KEY_FILE=<mode-600 file> \
#     E2E_DIR=<empty dir> RZV_PROFILE=shared scripts/30-backend-e2e.sh
#
# Optional: MODEL (default openai/gpt-5-nano), PORT (default 18000), RZV_E2E_LOCK.
set -euo pipefail

: "${SDK_PYTHON:?set SDK_PYTHON}" "${OPENAI_KEY_FILE:?set OPENAI_KEY_FILE}" "${E2E_DIR:?set E2E_DIR}"
repo=$(cd "$(dirname "$0")/.." && pwd)
helper=$repo/bin/rzv-openhands-backend
model=${MODEL:-openai/gpt-5-nano} port=${PORT:-18000}
lock=${RZV_E2E_LOCK:-$HOME/runzivo/tmp/shared-sandbox.lock}
slug=e2e$(date -u +%H%M%S) name=""
log() { printf '== %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

rzv whoami | grep -q '^Environment: shared ' || fail "rzv whoami must show Environment: shared"
mode=$(python3 -I -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$OPENAI_KEY_FILE")
[ "$mode" = 0o600 ] || fail "key file must be mode 600"
export RZV_OPENHANDS_STATE=$E2E_DIR/state OPENHANDS_SUPPRESS_BANNER=1
name=openhands-$slug
leak() { grep -rqF -f "$OPENAI_KEY_FILE" "$E2E_DIR"; }
sid() { rzv sandboxes list --json | python3 -I -c 'import sys,json
for s in json.load(sys.stdin)["sandboxes"]:
    if s["name"] == sys.argv[1] and s["status"] != "deleted": print(s["id"])' "$name"; }

mkdir -p "$(dirname "$lock")"
until mkdir "$lock" 2>/dev/null; do log "waiting for $lock (remove it if no test is running)"; sleep 20; done
printf 'rzv-openhands backend e2e, pid %s, since %s\n' "$$" "$(date -u +%FT%TZ)" >"$lock/owner"
cleanup() {
  set +e
  local id; id=$(sid)
  if [ -n "$id" ]; then log "cleanup: deleting $id ($name)"; "$helper" down "$id" --yes >/dev/null; fi
  if leak; then printf 'FAIL: the API key appears under %s\n' "$E2E_DIR" >&2; fi
  rm -rf "$E2E_DIR/state"; rm -f "$lock/owner"; rmdir "$lock"
}
trap cleanup EXIT

log "up $name"
"$helper" up --name "$slug" --port "$port" 2>&1 | grep -v 'API key:'
id=$(sid); [ -n "$id" ] || fail "no sandbox named $name"
curl -fsS "http://127.0.0.1:$port/health" >/dev/null || fail "backend not reachable on 127.0.0.1:$port"
code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/api/conversations/search")
[ "$code" = 401 ] || [ "$code" = 403 ] || fail "backend answered $code without the API key"
log "backend up on 127.0.0.1:$port; requests without the key get $code"

"$helper" key "$id" OPENAI_API_KEY <"$OPENAI_KEY_FILE" 2>&1
"$helper" connect "$id" --port "$port" 2>&1 | grep -v 'API key:'
"$SDK_PYTHON" -I "$repo/scripts/31-backend-task.py" "http://127.0.0.1:$port" "$E2E_DIR/state/$id.key" "$model" \
  >"$E2E_DIR/task.log" 2>&1 || { tail -n 30 "$E2E_DIR/task.log"; fail "task did not complete"; }
grep -E '^(server|result):' "$E2E_DIR/task.log"
log "metering: $(rzv sandboxes get "$id" | grep -i 'credits')"

"$helper" stop "$id" >/dev/null
for _ in $(seq 36); do rzv sandboxes get "$id" | head -n 1 | grep -q ': stopped$' && break; sleep 5; done
rzv sandboxes get "$id" | head -n 1
"$helper" start "$id" >/dev/null 2>&1
"$helper" connect "$id" --port "$port" 2>&1 | grep -v 'API key:'
rzv sandboxes exec "$id" -- 'cat /workspace/backend-ok.txt' | grep -q runzivo-backend-ok || fail "/workspace lost after stop and start"
log "after stop, start and reconnect the backend answers and /workspace kept the task's file"

"$helper" down "$id" </dev/null >/dev/null 2>&1 && fail "down deleted without --yes or a prompt"
"$helper" down "$id" --yes
log "after down: $(rzv sandboxes get "$id" | head -n 1)"
if leak; then fail "the API key appears under $E2E_DIR"; fi
log PASS
