# CPU contention teaching lab: sanitized case and reproduction

## Recorded results

A 4-vCPU, aarch64, VZ Linux VM running Ubuntu 25.10, kernel 6.17, sysstat, perf 6.17.13, bpftrace 0.23.5, and OpenSSL 3.5.3.
The hash program was uutils coreutils 0.2.2, not the GNU implementation. These versions describe the recorded experiment; they are not required versions.

Data streams from /dev/zero into sha256sum. There is no on-disk dataset read or write.

| Workload | Baseline seconds | With 8 competing processes | After stopping competitors |
|---|---:|---:|---:|
| 1 GiB, single trial | 5.24 | 12.39 | 5.24 |
| 512 MiB, median of three trials | 3.03 | 5.90 | 3.03 |

The three-trial measurements were: baseline 2.21 / 3.03 / 3.03; contention 5.84 / 6.58 / 5.90; recovery 3.03 / 3.03 / 2.23 seconds.

CPU busy time reached 100%, with 8 runnable tasks. One competing thread recorded 2262.06 ms executing and 2364.09 ms waiting on the runqueue; waiting accounted for 51.1% of these two states combined.
No paging, block-device activity, network bottleneck, or current-session quota throttling was observed. Ancestor cgroups, controllers, and hardware errors were not fully audited.

The original hash CPU profile contained 242 samples and 0 lost samples, but hotspot symbols were unresolved.
An independent supplementary OpenSSL BPF profile collected 496 samples; 485 stacks included EVP_Digest → SHA256_Update. Symbols for the innermost assembly were still incomplete.
The supplementary experiment was not a profile captured from the original hash workload and was not off-CPU analysis.

The conclusion is limited to controlled CPU contention slowing the same task, followed by recovery when competitors were removed. Exact timestamps, hosts/instances, PIDs, observed paths, addresses, and raw logs are excluded from the published case.

## Requirements and safety boundaries

Run only in an authorized isolated Linux instance. Scripts do not run by default: pass --run explicitly. The contention scripts use a fixed 8 competing CPU processes, suitable for this 4-vCPU case; saturation is not guaranteed on other CPU counts.
Requirements include bash, /usr/bin/time, and coreutils. The main experiment additionally needs sysstat, perf, and existing non-interactive sudo; the supplementary profile needs OpenSSL, perf, bpftrace, and sudo. No tools are installed and no sysctl settings are changed.

Each script typically takes about 30–90 seconds, depending on CPU performance and contention. Output may still contain PIDs, cgroup paths, and stack addresses. Keep it local and sanitize a separate copy before sharing; do not directly upload perf data.

Run the following from the repository root. INSTANCE is an isolated instance you have inspected and authorized; paths are resolved at runtime:

```sh
limactl list
INSTANCE=performance-lab
# Start only if this isolated instance was stopped; authorize/configure creation separately if absent.
limactl start "$INSTANCE"
limactl shell "$INSTANCE" -- bash "$PWD/skills/linux-performance-investigation/scripts/lima-cpu-saturation.sh" --run
limactl shell "$INSTANCE" -- bash "$PWD/skills/linux-performance-investigation/scripts/lima-repeat.sh" --run
limactl shell "$INSTANCE" -- bash "$PWD/skills/linux-performance-investigation/scripts/lima-profile.sh" --run
# Stop only if you started it for this run, restoring its initial state.
limactl stop "$INSTANCE"
```

The script paths must be readable through Lima mounts. Without shared mounts, copy the entire scripts directory into the guest through an authorized mechanism and run it there. Do not stop an instance that was already running other services before the experiment.

Scripts use traps to stop their own workloads and remove only their own temporary perf files. Traps cannot handle SIGKILL or host crashes. After an abnormal exit, inspect this run's actual PIDs/paths before cleanup; do not use pkill, killall, or recursive directory deletion.
