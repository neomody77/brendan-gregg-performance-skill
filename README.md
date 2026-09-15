# Brendan Gregg Linux Performance Investigation Skill

An executable Codex skill built around Brendan Gregg's public performance methodologies: problem statement → initial triage → Workload / USE / TSA → execution or waiting paths → hypothesis testing → recovery validation.

This is an independent synthesis, not an official project by the author. It does not include or distribute full books, PDFs, or mirrored third-party reading notes. See the [official sources](skills/linux-performance-investigation/references/sources.md).

## Installation and invocation

Copy the entire `skills/linux-performance-investigation` directory into `~/.codex/skills/` or your project's `.agents/skills/`. Reload skill discovery, then invoke it:

```text
Use $linux-performance-investigation to diagnose increased latency in this Linux service. Start with read-only checks.
Use $linux-performance-investigation to reproduce CPU contention in an isolated Lima Linux instance and verify recovery.
```

The entrypoint is [SKILL.md](skills/linux-performance-investigation/SKILL.md). Dependencies depend on the selected mode; the skill does not automatically install software or weaken system security settings.

## Tested teaching example

On a 4-vCPU Linux VM, a 1-GiB streaming hash took 5.24 → 12.39 → 5.24 seconds. The medians of three 512-MiB trials were 3.03 → 5.90 → 3.03 seconds. These are results from a controlled experiment, not a hardware ranking or a promise of identical numbers elsewhere.

See the [sanitized case study and reproduction guide](skills/linux-performance-investigation/references/cpu-saturation-lab.md).

## Publication boundaries

The repository contains only original guidance, templates, scripts, and a de-identified experiment summary. It excludes local machine paths, actual host or instance names, personal email addresses, exact test timestamps, original PIDs, memory addresses, network identifiers, raw logs, and binary profiling data.

Runtime output is not automatically sanitized. Keep investigation records local and review a separate copy before sharing. Ignore rules are not a substitute for security scanning.
