#!/usr/bin/env bash
set -Eeuo pipefail

# ---- Config ----
SESSION_NAME="${SESSION_NAME:-main}"
APP_ID="${APP_ID:-foot-terminal}"
TERM_FOR_FOOT="${TERM_FOR_FOOT:-foot-direct}"

# ---- Dependencies check ----
for bin in tmux foot pgrep ps awk; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "Error: required command '$bin' not found in PATH." >&2
    exit 1
  }
done

# ---- Snapshot existing Foot windows BEFORE spawning a new one ----
readarray -t FOOT_PIDS < <(ps -eo pid,comm | awk '$2=="foot"{print $1}')

# ---- Ensure tmux session exists (detached) ----
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux new-session -d -s "$SESSION_NAME"
fi

# ---- Get panes; if none, create a default shell pane ----
PANE_INFO="$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index} #{pane_pid} #{pane_current_command}" || true)"
if [[ -z "$PANE_INFO" ]]; then
  tmux new-session -d -t "$SESSION_NAME" || true
  PANE_INFO="$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index} #{pane_pid} #{pane_current_command}")"
fi

# ---- Choose the pane to preserve: current heuristic = first pane ----
TARGET_PANE_LINE="$(printf "%s\n" "$PANE_INFO" | head -n 1)"
TARGET_PANE_INDEX="$(awk '{print $1}' <<<"$TARGET_PANE_LINE")"
TARGET_PANE_PID="$(awk '{print $2}' <<<"$TARGET_PANE_LINE")"

echo "Preserving tmux pane index $TARGET_PANE_INDEX (PID=$TARGET_PANE_PID)"

# ---- Launch a new Foot window attached to that pane ----
foot --app-id="$APP_ID" \
  env TERM="$TERM_FOR_FOOT" \
  tmux new-session -A -t "$SESSION_NAME" \; \
  select-pane -t "$TARGET_PANE_INDEX" &

sleep 1

# ---- Kill all Foot windows that DO NOT own the preserved pane's PID ----
for foot_pid in "${FOOT_PIDS[@]:-}"; do
  [[ -n "${foot_pid:-}" ]] || continue

  PRESERVE=false
  while read -r child || [[ -n "${child:-}" ]]; do
    [[ -n "${child:-}" ]] || continue
    if [[ "$child" == "$TARGET_PANE_PID" ]]; then
      PRESERVE=true
      break
    fi
  done < <(pgrep -P "$foot_pid" || true)

  if [[ "$PRESERVE" == true ]]; then
    echo "Skipping preserved Foot window PID=$foot_pid"
  else
    echo "Killing Foot window PID=$foot_pid"
    kill "$foot_pid" 2>/dev/null || true
    sleep 0.2
    kill -0 "$foot_pid" 2>/dev/null && kill -9 "$foot_pid" 2>/dev/null || true
  fi
done
