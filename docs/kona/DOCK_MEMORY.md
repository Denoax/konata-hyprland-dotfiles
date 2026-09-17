# Dock memory — Task01 acceptance

The original44.694MiB component alarm was **triggered and investigated**, with no
threshold change. Task01 is PASS. Baseline PSS/private40.631/36.621MiB versus the
original candidate47.104/43.125MiB remains in immutable measurement evidence.

Controlled dock-only restart returned32.187/28.070MiB at30s,2min and5min. Three
ordinary warm-up cycles ended39.252/35.254MiB. Subsequent600s idle (61 samples,
no compositor events or pointer movement) fell39.267→37.241 PSS and35.254→33.125
private; slopes−0.292/−0.292MiB/min. PSS range37.126–39.366MiB. Warm SVG helpers
exited naturally between10–20s; parent retained some allocation and later released
more. Canonical dock binary/config/pins/style and Task01 product files are unchanged.

Historical extra private memory is6.246MiB dirty plus0.258MiB clean. No Task00
maps/smaps exist to identify historical heap/cache objects. New mappings localize
warm-up growth mainly to unnamed private pages and heap. Existing focus-driven
GTK/icon rebuilds provide a workload retention path; exact live cache versus
allocator slack is not established. No continuing idle growth was observed in
this window; this is not a proof against every lifetime leak.

Historical Task01 transient maxima belong to Waybar/udiskie, not dock. The dock
also has its own observed transient glycin trees; input image paths were unavailable.
The isolated Task01 save/refresh/capture probe produced no dock focus/rebuild,
helpers or retained memory increase. No credible Task01-specific causal path remains
supported. The alarm detected workload/cache-state variance rather than a
demonstrated Task01 regression. Aggregate matched Task01 gates remain passed;
restart samples do not replace their historical values.

Full methods, adverse attempts, causal audit, hashes and raw evidence:
`~/.local/state/kona/task01e-dock-20260912-143827/REPORT.md`.
Final acceptance: that directory's ACCEPTANCE.json supersedes the preserved earlier
Task01 PARTIAL decision. Exact next task: **Task02 — Theme Engine**; not started.
