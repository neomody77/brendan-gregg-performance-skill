# Publication privacy review

The publication set is limited to this repository's original Markdown, YAML, and Bash text. It excludes PDFs, archives, CSV files, raw logs, binary profiling data, and personal configuration from the original research collection.

Manual review removed or avoided introducing personal accounts and email addresses, local machine paths, actual host or instance names, observed PIDs/UIDs, network addresses, internal domains, exact test timestamps, and stack addresses.
The GitHub owner specified in the publication target is the only intentionally public account association; the content does not include personal biography or device identifiers.
Git commits use a generic project identity rather than inheriting a personal email address from the machine's global configuration.

Runtime output is not automatically sanitized. Generic /proc, /sys, and /tmp paths and PID variables in scripts are not observed environment identifiers.
The teaching summary preserves technical versions and measurements without raw event context. Ignore rules only reduce accidental additions; they do not replace manual review, secret scanning, or confirmation before publication.
