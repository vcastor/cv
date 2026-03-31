#!/usr/bin/env bash
# mk/compile.sh — compile a LaTeX document with a spinner
# Usage: compile.sh LABEL LOGFILE CMD [TEXLOG]
#   LABEL   : human-readable label for the progress line
#   LOGFILE : file to append stdout/stderr of CMD
#   CMD     : full shell command to run (passed to eval)
#   TEXLOG  : .log produced by TeX itself (for last-file hint), optional

LABEL="${1:?label required}"
LOGFILE="${2:?logfile required}"
CMD="${3:?command required}"
TEXLOG="${4:-}"

# ── spinner ────────────────────────────────────────────────────────────────
printf "  \033[36m◉\033[0m  %-48s" "${LABEL}..."

eval "${CMD}" >> "${LOGFILE}" 2>&1 &
PID=$!

i=0
while kill -0 "${PID}" 2>/dev/null; do
  case $((i % 4)) in
    0) c='|' ;; 1) c='/' ;; 2) c='-' ;; *) c='+' ;;
  esac
  printf "\b\033[33m%s\033[0m" "${c}"
  sleep 0.2
  i=$((i + 1))
done

wait "${PID}"; STATUS=$?

# ── result ─────────────────────────────────────────────────────────────────
if [ "${STATUS}" -eq 0 ]; then
  printf "\b \033[32m✓\033[0m\n"
  exit 0
fi

printf "\b \033[31m✗\033[0m\n"
printf "\n  \033[31m>>> Compilation failed — last 20 log lines:\033[0m\n\n"
tail -n 20 "${LOGFILE}"

if [ -n "${TEXLOG}" ] && [ -f "${TEXLOG}" ]; then
  printf "\n  \033[33m>>> Last .tex file referenced:\033[0m\n  "
  grep -oE '[^ ]+\.tex' "${TEXLOG}" 2>/dev/null | tail -1
fi
printf "\n"
exit 1
