#!/usr/bin/env bash
# Three repetitions per phase; 512 MiB streamed, never written to disk.
set -euo pipefail

# Explicit opt-in: never inject load during a read-only investigation.
if [[ ${1:-} != --run || $# != 1 ]]; then
  echo 'Usage: bash SCRIPT --run (authorized isolated Linux only)' >&2
  exit 2
fi
[[ $(uname -s) == Linux ]] || { echo 'Run this script in Linux.' >&2; exit 1; }
for tool in sha256sum dd bash uname; do
  command -v "$tool" >/dev/null || { printf 'Missing tool: %s\n' "$tool" >&2; exit 1; }
done
[[ -x /usr/bin/time ]] || { echo '/usr/bin/time is required.' >&2; exit 1; }
export LC_ALL=C
load_pids=()
cleanup() {
  if ((${#load_pids[@]})); then
    kill "${load_pids[@]}" 2>/dev/null || true
    for p in "${load_pids[@]}"; do wait "$p" 2>/dev/null || true; done
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
measure() {
  for trial in 1 2 3; do
    /usr/bin/time -f "phase=$1 trial=$trial bytes=536870912 elapsed_s=%e user_s=%U sys_s=%S" \
      bash -c 'dd if=/dev/zero bs=1M count=512 status=none | sha256sum >/dev/null'
  done
}
measure baseline
for _ in {1..8}; do sha256sum /dev/zero >/dev/null & load_pids+=("$!"); done
measure saturated
cleanup
load_pids=()
measure recovered
echo 'cleanup=all injected workloads stopped'
