# Kona performance execution policy

Mani's explicit 2026-09-14 policy applies to Task07 and later Kona tasks. It supersedes
routine idle-ready, fixed-cursor and frozen-application requirements in prior task plans.
Historical Task00–Task06 baselines, rejected windows and adverse evidence remain intact.

Do not ask Mani to stop using the desktop for routine measurements. Do not freeze the
browser, editor, Steam or normal apps without separate authorization. Prefer per-component
PSS/private memory and CPU, persistent counts, ancestry/cgroups, service lifecycle and
activation/termination, duplicate/orphan/zombie checks, logs and recovery evidence.

Aggregate observations should use short opportunistic windows during normal use, with
user workload recorded separately. Reject obviously contaminated aggregate comparisons
without asking for idle confirmation. When non-disruptive matched idle is unavailable,
report exactly: **aggregate matched-idle measurement deferred**. This does not block
implementation or technical acceptance on its own.

A task can technically pass when intended runtime behavior is proven, no new persistent
daemon/poller is introduced, component evidence shows no material regression, existing
functionality remains healthy, and no performance alarm is newly triggered by an
attributable change. Functional, recovery, visual and architectural validation remain
required. Aggregate observations must not be presented as controlled causal comparisons.

Preserve and investigate real attributable alarms. Request dedicated idle measurement
only for a critical unresolved regression that cannot be attributed another way, explaining
the specific evidence and necessity first. Full controlled end-to-end idle benchmarking
may be consolidated into Task10 Final QA; this policy does not authorize starting Task10.

Existing absolute core613.65234375MiB / dock44.694MiB and incremental +10%CPU / +64MiB
alarms remain unchanged. Accepted Task06 Hyprpaper and animated Showcase costs remain
explicitly documented. Do not claim savings by changing workload, functionality or warming.

## V4 roadmap pivot — 2026-09-14

The reference-supremacy pass supersedes waiting for Task07 managed login and proceeding
through the old Task08–10 sequence. Task07 remains PARTIAL with managed startup/logout
validation deferred. The earlier suggestion to consolidate benchmarking into Task10
remains historical guidance, not an active task authorization. V4 uses the component
policy above; all thresholds, rejected observations and attribution remain unchanged.
Open Deck/Studio/Mosaic costs must be disclosed separately from closed DAILY residency.
