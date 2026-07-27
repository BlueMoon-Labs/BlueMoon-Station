# Mob headless benchmark

The benchmark boots Runtime Station without clients. Synthetic workloads use
an isolated 24x24 arena and 100 samples; live combat modes use a sealed 48x48
arena. Together they cover SSmobs Life processing, legacy NPC/idle pools,
controller planning and target acquisition, ranged AI, machine targets,
obstacle/JPS routing, boss selection, and dense spatial-grid acquisition.

Run it from PowerShell:

```powershell
tools\mob_bench\run_headless.ps1 -Tag candidate -Runs 3
```

`-Mode Arena` runs the 30-second live all-hostile fight with a fast diagnostic
GC settle. `-Mode ArenaRound16` reproduces the expensive round-16 cohort: 59
InteQ shotgun commandos fight 10 demonic frost miners while a harmless active
weather datum scans the combat population. `-Mode ArenaHarddel` waits 130
seconds after teardown before forcing the surviving Q3 entries through `del()`,
separating real harddel candidates from temporary references held by sleeping
DM frames. `-Mode ArenaRound16Harddel` combines the exact combat cohort with
that long GC and reference-scan phase. After one diagnostic scan has identified
the owner, add `-SkipReferenceScan` to repeated harddel A/B runs so the same
multi-minute full-world scan does not contaminate their cleanup profiles.

Each run produces `median_ms`, `p95_ms`, `p99_ms`, raw samples, semantic AI
counters, and a native BYOND proc profile. Results are archived under
`data/mob_bench_results/<timestamp>_<tag>/`; the `data` directory is ignored by
git. The final table averages each percentile over all requested runs. Compare
only runs made with the same BYOND build, map, defines, scenario version, and
profiler mode.
