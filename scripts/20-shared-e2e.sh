#!/usr/bin/env bash
# Live end-to-end test of the runzivo skill through the OpenHands CLI, on Runzivo shared.
# Each step is one headless OpenHands run in a project that has the skill in
# .agents/skills/runzivo. The agent drives rzv; this script checks the result with rzv.
#
#   OPENHANDS_BIN=<openhands 1.16.0> OPENAI_KEY_FILE=<mode-600 key file> E2E_DIR=<empty dir> \
#     RZV_PROFILE=shared scripts/20-shared-e2e.sh
#
# Optional: MODEL (default openai/gpt-5-nano), RZV_E2E_LOCK (default
# ~/runzivo/tmp/shared-sandbox.lock, a directory used so one test at a time uses sandboxes).
set -euo pipefail

: "${OPENHANDS_BIN:?set OPENHANDS_BIN}" "${OPENAI_KEY_FILE:?set OPENAI_KEY_FILE}" "${E2E_DIR:?set E2E_DIR}"
repo=$(cd "$(dirname "$0")/.." && pwd)
model=${MODEL:-openai/gpt-5-nano}
lock=${RZV_E2E_LOCK:-$HOME/runzivo/tmp/shared-sandbox.lock}
run_id=e2e$(date -u +%H%M%S)
name=openhands-$run_id
log() { printf '== %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

rzv whoami | grep -q '^Environment: shared ' || fail "rzv whoami must show Environment: shared"
mode=$(python3 -I -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$OPENAI_KEY_FILE")
[ "$mode" = 0o600 ] || fail "key file must be mode 600"
"$OPENHANDS_BIN" --version | grep -q 'OpenHands CLI' || fail "OPENHANDS_BIN is not the OpenHands CLI"

ids() { rzv sandboxes list --json | python3 -I -c 'import sys,json
for s in json.load(sys.stdin)["sandboxes"]: print(s["id"], s["name"])'; }
leak() { grep -rqF -f "$OPENAI_KEY_FILE" "$E2E_DIR"; }
settle() { # settle <status>: wait up to 3 minutes for the sandbox to reach it
  for _ in $(seq 36); do [ "$(field status)" = "$1" ] && return 0; sleep 5; done
  log "expected $1, got $(field status)"; return 1
}
field() { rzv sandboxes get "$sid" --json | python3 -I -c 'import sys,json; print(json.load(sys.stdin)["sandbox"][sys.argv[1]])' "$1"; }

mkdir -p "$(dirname "$lock")"
until mkdir "$lock" 2>/dev/null; do log "waiting for $lock (remove it if no test is running)"; sleep 20; done
printf 'rzv-openhands skill e2e, pid %s, since %s\n' "$$" "$(date -u +%FT%TZ)" >"$lock/owner"
sid=""
cleanup() {
  set +e
  # Delete only what this run made: sandboxes named openhands-<run>.
  ids | while read -r id n; do
    case "$n" in "$name"*) log "cleanup: deleting $id ($n)"; rzv sandboxes delete "$id" >/dev/null ;; esac
  done
  rm -rf "$E2E_DIR/state"   # OpenHands settings and conversations; keep only the logs
  if leak; then printf 'FAIL: the API key appears under %s\n' "$E2E_DIR" >&2; fi
  rm -f "$lock/owner"; rmdir "$lock"
}
trap cleanup EXIT

proj=$E2E_DIR/proj state=$E2E_DIR/state
mkdir -p "$proj/.agents/skills" "$state"
cp -R "$repo/skills/runzivo" "$proj/.agents/skills/runzivo"
export OPENHANDS_PERSISTENCE_DIR=$state PERSISTENCE_DIR=$state OPENHANDS_CONVERSATIONS_DIR=$state/conversations \
  OPENHANDS_WORK_DIR=$proj OPENHANDS_SUPPRESS_BANNER=1 LLM_MODEL=$model

n=0
turn() { # turn <prompt> [conversation-id]; JSONL events in $E2E_DIR/turn-N.jsonl; at most 10 minutes each
  n=$((n + 1)); log "turn $n: $1${2:+ (resuming $2)}"
  local resume=()
  [ -n "${2:-}" ] && resume=(--resume "$2")
  (cd "$proj" && LLM_API_KEY=$(cat "$OPENAI_KEY_FILE") exec "$OPENHANDS_BIN" --headless --json --override-with-envs ${resume[@]+"${resume[@]}"} -t "$1") \
    >"$E2E_DIR/turn-$n.jsonl" 2>"$E2E_DIR/turn-$n.err" &
  local pid=$! waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge 600 ]; then log "turn $n timed out"; pkill -TERM -P "$pid" || true; kill "$pid" || true; break; fi
    sleep 5; waited=$((waited + 5))
  done
  wait "$pid" || true
  last=$E2E_DIR/turn-$n.jsonl
}
cmds() { # the terminal commands the agent ran in the given turn logs
  python3 -I -c 'import sys,json
for f in sys.argv[1:]:
    for l in open(f):
        try: e=json.loads(l)
        except ValueError: continue
        a=e.get("action") or {}
        if e.get("kind")=="ActionEvent" and a.get("command"): print(a["command"])' "$@"
}
ran() { cmds "$last" | grep -- "$1" >/dev/null; }
conv() { grep -o 'Conversation ID: [0-9a-f]*' "$last" | head -n 1 | awk '{print $3}'; }

step() { # step <check-function> <prompt>: one headless run; if the check fails, resume it with "Continue" up to 3 times
  local c tries=0
  turn "$2"
  until "$1"; do
    tries=$((tries + 1)); c=$(conv)
    [ "$tries" -le 3 ] && [ -n "$c" ] || fail "turn $n: $1 failed"
    log "turn $n: $1 not done yet; the model stopped early, resuming the conversation"
    turn "Continue until the task is done." "$c"
  done
}
created() { sid=$(ids | awk -v n="$name" '$2 == n {print $1}'); [ -n "$sid" ] && settle running; }
wrote() { ran "ssh-config" && rzv sandboxes exec "$sid" -- 'cat /workspace/e2e.txt' 2>/dev/null | grep -q skill-ok; }
showed() { ran "sandboxes get" && grep -qi "credit" "$last"; }
stopped() { ran "sandboxes stop" && settle stopped; }
woke() { cmds "$E2E_DIR"/turn-*.jsonl | grep "sandboxes start" >/dev/null && settle running && grep -q skill-ok "$last"; }
asked() { [ "$(field status)" = running ] && ! ran "sandboxes delete"; }
deleted() { ran "sandboxes delete"; }

step created "In the terminal, use rzv to create a Runzivo sandbox named exactly $name and wait until it is running. Reply with its id."
log "created $sid, status $(field status)"
step wrote "In the terminal, use rzv to set up the SSH alias for Runzivo sandbox $sid, then over SSH run uname -sm and write the text skill-ok to /workspace/e2e.txt."
step showed "In the terminal, use rzv to show the status of Runzivo sandbox $sid: status, time left and credits used."
log "metering: runtime_seconds=$(field runtime_seconds) credits_used=$(field credits_used) expires_at=$(field expires_at)"
step stopped "In the terminal, use rzv to stop Runzivo sandbox $sid."
step woke "In the terminal, use rzv to start Runzivo sandbox $sid, wait until it is running, then print /workspace/e2e.txt from it."
log "/workspace survived stop and start"
turn "In the terminal, use rzv to delete Runzivo sandbox $sid."
asked || fail "delete ran without the user's confirmation"
log "delete without confirmation was not run; sandbox still $(field status)"
step deleted "Yes, I confirm. In the terminal, use rzv to delete Runzivo sandbox $sid (named $name) now."
if rzv sandboxes get "$sid" --json >/dev/null 2>&1; then log "after delete: $(field status)"; else log "after delete: not found"; fi

if leak; then fail "the API key appears under $E2E_DIR"; fi
log "PASS ($n turns, sandbox $sid)"
