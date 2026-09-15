#!/usr/bin/env bash
# Run inside a disposable/stopped-before-use Linux Lima instance.
# CPU-only workload; no package/configuration changes and no disk benchmark.
set -euo pipefail

# Explicit opt-in: never inject load during a read-only investigation.
if [[ ${1:-} != --run || $# != 1 ]]; then
  echo 'Usage: bash SCRIPT --run (authorized isolated Linux only)' >&2
  exit 2
fi
[[ $(uname -s) == Linux ]] || { echo 'Run this script in Linux.' >&2; exit 1; }
for tool in sha256sum dd bash vmstat mpstat pidstat free iostat sar perf sudo awk sed mktemp rm rmdir; do
  command -v "$tool" >/dev/null || { printf 'Missing tool: %s\n' "$tool" >&2; exit 1; }
done
[[ -x /usr/bin/time ]] || { echo '/usr/bin/time is required.' >&2; exit 1; }
sudo -n true || { echo 'Existing non-interactive sudo is required; no settings changed.' >&2; exit 1; }
export LC_ALL=C

task_dir=$(mktemp -d /tmp/gregg-cpu-lab.XXXXXX)
load_pids=()
cleanup() {
  if ((${#load_pids[@]})); then
    kill "${load_pids[@]}" 2>/dev/null || true
    for p in "${load_pids[@]}"; do wait "$p" 2>/dev/null || true; done
  fi
  rm -f -- "$task_dir/perf.data" "$task_dir/perf.data.old"
  rmdir -- "$task_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

benchmark() {
  /usr/bin/time -f "phase=$1 elapsed_s=%e user_s=%U sys_s=%S maxrss_kb=%M" \
    bash -c 'dd if=/dev/zero bs=1M count=1024 status=none | sha256sum >/dev/null'
}

date -Is
benchmark baseline
for _ in {1..8}; do sha256sum /dev/zero >/dev/null & load_pids+=("$!"); done
target_pid=${load_pids[0]}
pid_list=$(IFS=,; echo "${load_pids[*]}")
printf 'load_pids=%s target_pid=%s\n' "$pid_list" "$target_pid"
read -r run_before wait_before slices_before < "/proc/$target_pid/schedstat"

vmstat 1 6
read -r run_after wait_after slices_after < "/proc/$target_pid/schedstat"
awk -v a="$run_before" -v b="$run_after" -v c="$wait_before" -v d="$wait_after" \
  -v x="$slices_before" -v y="$slices_after" \
  'BEGIN { printf "TSA target run_ms=%.2f runqueue_wait_ms=%.2f timeslices=%d\n", (b-a)/1e6, (d-c)/1e6, y-x }'
mpstat -P ALL 1 3
pidstat -u -p "$pid_list" 1 3
free -m
iostat -xz -y 1 2
sar -n DEV,TCP,ETCP 1 2

cg_path=$(awk -F: '$1=="0" {print $3}' "/proc/$target_pid/cgroup")
printf 'cgroup=%s\n' "$cg_path"
for f in cpu.max cpu.stat; do
  if [[ -f "/sys/fs/cgroup$cg_path/$f" ]]; then
    printf '%s\n' "$f"
    sed -n '1,12p' "/sys/fs/cgroup$cg_path/$f"
  fi
done

sudo -n perf record -q -e cpu-clock -F 99 --call-graph dwarf \
  -p "$target_pid" -o "$task_dir/perf.data" -- sleep 5
sudo -n perf report -i "$task_dir/perf.data" --stdio --no-children \
  --sort comm,dso,symbol --percent-limit 1 | sed -n '1,45p'
benchmark saturated

kill "${load_pids[@]}"
for p in "${load_pids[@]}"; do wait "$p" 2>/dev/null || true; done
load_pids=()
vmstat 1 4
benchmark recovered
printf 'cleanup=all injected CPU workloads stopped; temporary perf data removed on exit\n'
