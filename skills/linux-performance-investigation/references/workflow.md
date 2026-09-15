# Investigation workflow

## Problem statement and initial triage

Record user-visible metrics, baseline and current values, sampling windows, affected boundaries, input workload, and recent changes. Distinguish symptoms, measurements, and interpretations.

The Linux checklist proceeds through `uptime`, `dmesg -T | tail`, `vmstat 1`, `mpstat -P ALL 1`, `pidstat 1`, `iostat -xz 1`, `free -m`, `sar -n DEV 1`, `sar -n TCP,ETCP 1`, and `top`.
When running it, use bounded sample counts and batch-mode top. Record insufficient permissions or missing tools as unknowns.
The first vmstat/iostat report may cover time since boot rather than the incident window.
Load includes runnable tasks and some uninterruptible waits; it is not CPU utilization. Low free memory alone does not establish memory pressure.

## Workload and USE

Workload: Who generates the work; Why it is triggered and which code paths are involved; What its volume, types, and sizes are; How it changes over time. Align input changes with the observed service regression.

| Resource | Utilization | Saturation | Errors |
|---|---|---|---|
| CPU | Per-core busy time / effective quota | Run queues, scheduling waits, throttling | Hardware/CPU errors |
| Memory | Physical/cgroup usage and limits | Reclaim, swap, page waits | OOM, allocation failures |
| Storage I/O | Busy time, throughput relative to capability | Queues, completion latency | Timeouts, resets, I/O errors |
| Capacity/inodes | Used proportion | No generic queue metric; N/A or system-specific metric | ENOSPC, read-only mounts |
| Network | RX/TX relative to link capacity/limits | Queues, drops | Interface errors; TCP retransmission clues |
| Software resources | Pool, lock, FD usage | Queuing, lock waits, rate limiting | Acquisition failures, rejections |

For containers, inspect both the process's cgroup and ancestor limits. Checking only the current layer cannot rule out parent-level throttling.
For virtual machines, consider steal time, unsupported events, host contention, and clock disturbances. Utilization across different devices is not directly comparable.

## TSA and deeper investigation

| Dominant time state | Investigation direction |
|---|---|
| Executing | User/system time, CPU stacks, syscall/kernel paths |
| Runnable | Scheduling waits, CPU pressure, affinity, quotas |
| Anonymous Paging | Capacity, reclaim, anonymous paging |
| Sleeping | I/O, blocking stacks, wakeup paths |
| Lock | Holders, contention stacks, critical sections |
| Idle | Waiting for new work; not request blocking |

Deltas from `/proc/PID/schedstat` can show executing time and runqueue waits. They do not cover all six states or provide a complete end-to-end latency breakdown.
State whether per-process CPU percentages are normalized to one CPU or the whole machine.

For CPU profiling, select a supported event, target PID/cgroup, sampling frequency, and window. Check lost samples, symbols, and overhead.
When a VM does not support hardware events, software cpu-clock may be usable, but it does not establish physical cycle counts.
List unresolved paths accounting for roughly 1% or more as coverage gaps; do not guess function names from addresses.
Interpret off-CPU data by blocked time rather than sample count and exclude idle workers. Summed blocking time across threads can exceed wall-clock time.

For a slow individual request, break synchronous latency down through the application, dependencies, syscalls, kernel, and devices. Avoid adding nested times or directly subtracting parallel CPU time from wall time.

## Validation and closure

Write a falsifiable prediction first. Change one key variable at a time and retain a rollback path.
Repeat baseline → intervention → recovery with the same inputs, windows, and metrics. Observe the limiting component while the benchmark runs in steady state.
Queuing/resource pressure and user-visible results should change together as predicted. Estimate the proportion of time that can be eliminated; do not promise gains beyond that fraction.

Distinguish confirmed root causes, mitigation, ruled-out hypotheses, and insufficient evidence. Explicitly list unmeasured resources, missing symbols, permission limits, and background disturbances.
In experiments, clean up only this run's owned PIDs and exact temporary files, and restore the VM's initial running state. Do not kill same-named services or delete user data.
