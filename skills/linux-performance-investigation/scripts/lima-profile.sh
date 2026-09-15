#!/usr/bin/env bash
# Symbol-aware sampling without installing a compiler or changing guest config.
set -euo pipefail

# Explicit opt-in: never inject load during a read-only investigation.
if [[ ${1:-} != --run || $# != 1 ]]; then
  echo 'Usage: bash SCRIPT --run (authorized isolated Linux only)' >&2
  exit 2
fi
[[ $(uname -s) == Linux ]] || { echo 'Run this script in Linux.' >&2; exit 1; }
for tool in openssl perf bpftrace sudo mktemp rm rmdir; do
  command -v "$tool" >/dev/null || { printf 'Missing tool: %s\n' "$tool" >&2; exit 1; }
done
sudo -n true || { echo 'Existing non-interactive sudo is required; no settings changed.' >&2; exit 1; }
export LC_ALL=C
task_dir=$(mktemp -d /tmp/gregg-profile-lab.XXXXXX)
target_pid=''
cleanup() {
  if [[ -n $target_pid ]]; then
    kill "$target_pid" 2>/dev/null || true
    wait "$target_pid" 2>/dev/null || true
  fi
  rm -f -- "$task_dir/perf.data" "$task_dir/perf.data.old"
  rmdir -- "$task_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

openssl speed -seconds 60 -bytes 16384 -evp sha256 &
target_pid=$!
printf 'profile_target_pid=%s\n' "$target_pid"
sudo -n perf record -q -e cpu-clock -F 99 --call-graph dwarf \
  -p "$target_pid" -o "$task_dir/perf.data" -- sleep 5
sudo -n perf report -i "$task_dir/perf.data" --stdio --no-children \
  --call-graph none --sort comm,dso,symbol --percent-limit 1
sudo -n bpftrace -e "profile:hz:99 /pid == $target_pid/ { @[ustack(8)] = count(); } interval:s:5 { exit(); }"
printf 'cleanup=profile workload and temporary data removed on exit\n'
