---
name: linux-performance-investigation
description: Diagnose Linux performance regressions using Brendan Gregg's Problem Statement, Workload, USE, TSA, and CPU/Off-CPU methods, or practice CPU contention, profiling, and recovery validation in an explicitly authorized isolated Linux/Lima environment.
---

# Linux performance investigation

Build a verifiable evidence chain from user-visible symptoms to resource pressure or execution/waiting paths, rather than collecting tool output without a question. The methods come from Brendan Gregg; the combined stages, experiments, and recording format are this project's engineering synthesis, not an author-certified procedure.

## Select the mode

- Real incident: read the [investigation workflow](references/workflow.md) and use the [record template](assets/investigation-template.md). A diagnostic request authorizes diagnosis, not implementation.
- Teaching or Lima practice: read the [lab guide](references/cpu-saturation-lab.md) first. Run scripts only in an explicitly authorized isolated environment. Do not inject competing workloads as an automatic step in diagnosing a real service.
- Method attribution: read the [official sources](references/sources.md). Public tables of contents or sample chapters do not authorize unrestricted redistribution of books.

## Decision requirements

Establish the baseline, regression metric, time window, affected scope, and recent changes. Record sampling intervals and measurement conventions during triage. Load average, high CPU usage, or a single error does not establish a root cause.

Choose Workload / USE / TSA views according to the evidence:
when execution dominates, sample CPU stacks; when runnable time dominates, investigate scheduling queues, CPU affinity, quotas, and ancestor cgroups;
when sleeping or lock time dominates, investigate blocking and wakeup paths. Low CPU usage does not rule out a bottleneck, and aggregate off-CPU time is not directly equivalent to request latency.

Before perf/BPF tracing, verify tools, kernel, permissions, target filters, event support, duration, and overhead. Record missing tools or unsupported events instead of automatically installing packages, changing sysctl settings, or widening the target.
Report missing symbols as unresolved paths. Do not present an independent supplementary experiment as evidence captured from the original incident.

For each iteration, write “hypothesis → falsifiable prediction → observation/intervention → result.” Perform reversible interventions only when the request authorizes a fix or experiment. User-visible results and the suspected waiting/resource pressure should improve together under the same workload; check errors and regressions in neighboring workloads.

## Delivery and data boundaries

Lead with the conclusion status: root cause confirmed / mitigated but unconfirmed / hypothesis ruled out / insufficient evidence.
Then give before-and-after metrics, key evidence, ruled-out hypotheses, coverage gaps, and rollback/cleanup results.

Keep raw logs, perf data, call stacks, and request identifiers in a local non-publication directory. Remove accounts/email addresses, hosts, IP/MAC addresses, internal domains, paths, tenant/request identifiers, exact timestamps, and unnecessary addresses from shared copies. Preserve versions, measurement conventions, and measured values; use consistent, non-reversible placeholders when correlation is needed. Automated scanning does not replace manual review or authorize publication.
