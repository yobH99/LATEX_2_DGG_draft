#!/usr/bin/env bash

set -u

FILE="${1:-main.tex}"
INTERVAL="${INTERVAL:-1}"

if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE" >&2
  exit 1
fi

file_mtime() {
  stat -c %Y "$1" 2>/dev/null
}

run_checks() {
  local target="$1"
  local stem
  local tex_log
  local chk_log
  local tex_status

  stem="${target%.tex}"
  tex_log="/tmp/${stem##*/}.watch.pdflatex.log"
  chk_log="/tmp/${stem##*/}.watch.chktex.log"

  printf '\n[%s] Detected save: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$target"

  pdflatex -interaction=nonstopmode "$target" >"$tex_log" 2>&1
  tex_status=$?

  if [[ $tex_status -eq 0 ]]; then
    echo "pdflatex: OK"
  else
    echo "pdflatex: ERROR"
    grep -E '^!|^l\.[0-9]+' "$tex_log" | head -n 20
  fi

  chktex -q -n1 -n8 -n24 "$target" >"$chk_log" 2>&1 || true

  if [[ -s "$chk_log" ]]; then
    echo "chktex:"
    head -n 20 "$chk_log"
  else
    echo "chktex: clean"
  fi
}

last_mtime=""

echo "Watching $FILE"
echo "Press Ctrl-C to stop."

while true; do
  current_mtime="$(file_mtime "$FILE")"

  if [[ -n "$current_mtime" && "$current_mtime" != "$last_mtime" ]]; then
    last_mtime="$current_mtime"
    run_checks "$FILE"
  fi

  sleep "$INTERVAL"
done
