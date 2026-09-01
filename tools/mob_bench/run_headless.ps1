param(
	[ValidatePattern('^[A-Za-z0-9._-]+$')]
	[string]$Tag = "run",
	[ValidateRange(1, 20)]
	[int]$Runs = 1,
	[ValidateSet("All", "Synthetic", "Arena", "ArenaRound16", "ArenaRound20", "ArenaHarddel", "ArenaRound16Harddel", "ArenaRound20Harddel", "Scenes")]
	[string]$Mode = "All",
	[ValidateRange(1, 100)]
	[int]$Top = 15,
	[switch]$SkipReferenceScan,
	[switch]$ProfileMachines
)

$ErrorActionPreference = "Stop"
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$reportPath = Join-Path $repoRoot "data\mob_benchmark_v3.json"
$arenaReportPath = Join-Path $repoRoot "data\mob_arena_benchmark_v2.json"
$scenesReportPath = Join-Path $repoRoot "data\ai_behavior_scenes_v1.json"
$logDirectory = Join-Path $repoRoot "data\logs"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$resultDirectory = Join-Path $repoRoot "data\mob_bench_results\${timestamp}_${Tag}"
$runSynthetic = $Mode -in @("All", "Synthetic")
$runScenes = $Mode -eq "Scenes"
$runArena = $Mode -in @("All", "Arena", "ArenaRound16", "ArenaRound20", "ArenaHarddel", "ArenaRound16Harddel", "ArenaRound20Harddel")
$runArenaRound16 = $Mode -in @("ArenaRound16", "ArenaRound16Harddel")
$runArenaRound20 = $Mode -in @("ArenaRound20", "ArenaRound20Harddel")
$runArenaHarddel = $Mode -in @("ArenaHarddel", "ArenaRound16Harddel", "ArenaRound20Harddel")
$failedRuns = @()

New-Item -ItemType Directory -Path $resultDirectory -Force | Out-Null
Push-Location $repoRoot
try {
	for ($run = 1; $run -le $Runs; $run++) {
		Write-Host "=== mob headless benchmark $run/$Runs ($Mode) ==="
		$machineProfilesBefore = @(Get-ChildItem -LiteralPath "data" -Filter "machines_benchmark_*.jsonl" -ErrorAction SilentlyContinue | ForEach-Object FullName)
		Remove-Item -LiteralPath $reportPath -Force -ErrorAction SilentlyContinue
		Remove-Item -LiteralPath $arenaReportPath -Force -ErrorAction SilentlyContinue
		Get-ChildItem -Path "data\ai_benchmark_profile_*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
		Get-ChildItem -Path "data\mob_arena_profile_*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
		Get-ChildItem -LiteralPath $logDirectory -Filter "gc_profiler*.csv" -ErrorAction SilentlyContinue | Remove-Item -Force

		$buildArguments = @("--define=LOWMEMORYMODE")
		if ($runSynthetic) {
			$buildArguments += "--define=AI_HEADLESS_BENCH"
		}
		if ($runScenes) {
			$buildArguments += "--define=AI_BEHAVIOR_SCENE_BENCH"
			Remove-Item -LiteralPath $scenesReportPath -Force -ErrorAction SilentlyContinue
		}
		if ($runArena) {
			$buildArguments += "--define=AI_MOB_ARENA_BENCH"
			$buildArguments += "--define=GC_PROFILER"
			if ($runArenaRound16) {
				$buildArguments += "--define=AI_MOB_ARENA_ROUND16_BENCH"
			}
			if ($runArenaRound20) {
				$buildArguments += "--define=AI_MOB_ARENA_ROUND20_BENCH"
			}
			if ($runArenaHarddel) {
				$buildArguments += "--define=AI_MOB_ARENA_HARDDEL_BENCH"
				if ($SkipReferenceScan) {
					$buildArguments += "--define=AI_MOB_ARENA_SKIP_REFSCAN_BENCH"
				}
			}
			if ($ProfileMachines) {
				$buildArguments += "--define=AI_MOB_ARENA_MACHINES_BENCH"
			}
		}
		$buildArguments += "dm-test"
		& "tools\build\build.bat" @buildArguments
		$buildExitCode = $LASTEXITCODE
		if ($buildExitCode -ne 0) {
			$failedRuns += $run
			Write-Warning "Headless benchmark process exited with code $buildExitCode. Reports will still be archived when the benchmark reached teardown; inspect runtime_$run.log."
		}

		if ($runArena) {
			$arenaProfileDirectory = Join-Path $resultDirectory "arena_profiles_$run"
			New-Item -ItemType Directory -Path $arenaProfileDirectory -Force | Out-Null
			Get-ChildItem -Path "data\mob_arena_profile_*.json" -ErrorAction SilentlyContinue | Copy-Item -Destination $arenaProfileDirectory
			if ($ProfileMachines) {
				Get-ChildItem -LiteralPath "data" -Filter "machines_benchmark_*.jsonl" -ErrorAction SilentlyContinue |
					Where-Object { $_.FullName -notin $machineProfilesBefore } |
					Copy-Item -Destination $arenaProfileDirectory
			}
			Get-ChildItem -LiteralPath $logDirectory -Filter "gc_profiler*.csv" -ErrorAction SilentlyContinue | Copy-Item -Destination $arenaProfileDirectory
			$harddelLog = Join-Path $logDirectory "ci\harddels.log"
			if (Test-Path -LiteralPath $harddelLog) {
				Copy-Item -LiteralPath $harddelLog -Destination (Join-Path $resultDirectory "harddels_$run.log")
			}
			$runtimeLog = Join-Path $logDirectory "ci\runtime.log"
			if (Test-Path -LiteralPath $runtimeLog) {
				Copy-Item -LiteralPath $runtimeLog -Destination (Join-Path $resultDirectory "runtime_$run.log")
			}
			$testsLog = Join-Path $logDirectory "ci\tests.log"
			if (Test-Path -LiteralPath $testsLog) {
				Copy-Item -LiteralPath $testsLog -Destination (Join-Path $resultDirectory "tests_$run.log")
			}
		}

		if ($runSynthetic -and !(Test-Path -LiteralPath $reportPath)) {
			throw "Headless benchmark run $run did not produce $reportPath"
		}
		if ($runArena -and !(Test-Path -LiteralPath $arenaReportPath)) {
			throw "Arena benchmark run $run did not produce $arenaReportPath"
		}
		if ($runScenes) {
			if (!(Test-Path -LiteralPath $scenesReportPath)) {
				throw "Behavior scenes run $run did not produce $scenesReportPath"
			}
			Copy-Item -LiteralPath $scenesReportPath -Destination (Join-Path $resultDirectory "scenes_run_$run.json")
			$scenesTestsLog = Join-Path $logDirectory "ci\tests.log"
			if (Test-Path -LiteralPath $scenesTestsLog) {
				Copy-Item -LiteralPath $scenesTestsLog -Destination (Join-Path $resultDirectory "scenes_tests_$run.log")
			}
		}

		if ($runSynthetic) {
			Copy-Item -LiteralPath $reportPath -Destination (Join-Path $resultDirectory "run_$run.json")
			$profileDirectory = Join-Path $resultDirectory "profiles_$run"
			New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
			Get-ChildItem -Path "data\ai_benchmark_profile_*.json" | Copy-Item -Destination $profileDirectory
		}
		if ($runArena) {
			Copy-Item -LiteralPath $arenaReportPath -Destination (Join-Path $resultDirectory "arena_run_$run.json")
		}
	}
}
finally {
	Pop-Location
}

if ($runScenes) {
	$scenesReport = Get-Content -Raw (Join-Path $resultDirectory "scenes_run_1.json") | ConvertFrom-Json
	$sceneRows = foreach ($scenario in $scenesReport.PSObject.Properties) {
		if ($scenario.Name.StartsWith("_")) {
			continue
		}
		$metrics = $scenario.Value.metrics
		[pscustomobject]@{
			Scenario = $scenario.Name
			Metrics = ($metrics.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; "
		}
	}
	$sceneRows | Format-Table -AutoSize -Wrap
}

$rows = @()
if ($runSynthetic) {
	$reports = foreach ($run in 1..$Runs) {
		Get-Content -Raw (Join-Path $resultDirectory "run_$run.json") | ConvertFrom-Json
	}
	$rows = foreach ($scenario in $reports[0].PSObject.Properties) {
		if ($scenario.Name.StartsWith("_")) {
			continue
		}
		$medianSamples = $reports | ForEach-Object { $_.($scenario.Name).median_ms }
		$p95Samples = $reports | ForEach-Object { $_.($scenario.Name).p95_ms }
		$p99Samples = $reports | ForEach-Object { $_.($scenario.Name).p99_ms }
		[pscustomobject]@{
			Scenario = $scenario.Name
			MedianMs = [math]::Round(($medianSamples | Measure-Object -Average).Average, 3)
			P95Ms = [math]::Round(($p95Samples | Measure-Object -Average).Average, 3)
			P99Ms = [math]::Round(($p99Samples | Measure-Object -Average).Average, 3)
		}
	}
	$rows | Format-Table -AutoSize
}

if ($runArena) {
	$hotspots = foreach ($run in 1..$Runs) {
		$profileDirectory = Join-Path $resultDirectory "arena_profiles_$run"
		foreach ($profileFile in Get-ChildItem -LiteralPath $profileDirectory -Filter "mob_arena_profile_*.json") {
			$phase = $profileFile.BaseName -replace '^mob_arena_profile_', ''
			$rank = 0
			# Windows PowerShell 5.1 keeps a top-level JSON array boxed as one
			# pipeline object. Assignment unwraps it before Sort-Object.
			$profileRows = Get-Content -Raw -LiteralPath $profileFile.FullName | ConvertFrom-Json
			$profileRows |
				Sort-Object -Property @{ Expression = { [double]$_.self }; Descending = $true } |
				Select-Object -First $Top |
				ForEach-Object {
					$rank++
					[pscustomobject]@{
						Run = $run
						Phase = $phase
						Rank = $rank
						Proc = $_.name
						Self = $_.self
						Over = $_.over
						Total = $_.total
						Calls = $_.calls
					}
				}
		}
	}
	$hotspots | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $resultDirectory "arena_hotspots.csv")
	$hotspots | Format-Table -AutoSize

	foreach ($run in 1..$Runs) {
		$arenaReport = Get-Content -Raw -LiteralPath (Join-Path $resultDirectory "arena_run_$run.json") | ConvertFrom-Json
		$lastSample = $arenaReport.combat.samples | Select-Object -Last 1
		Write-Host "Arena run ${run}: attempted=$($arenaReport.catalog.attempted_count), combatants=$($arenaReport.spawn.combatants_after_initialize), alive_end=$($lastSample.alive), spikes=$($arenaReport.tick_spikes.spike_count), harddel_candidates=$($arenaReport.gc.totals.hard_delete_candidates), harddels=$($arenaReport.gc.totals.hard_deletes), pending_harddels=$($arenaReport.gc.totals.pending_hard_deletes), worst_harddel_ms=$($arenaReport.gc.totals.highest_hard_delete_ms)"
		$harddelTypes = $arenaReport.gc.types.PSObject.Properties |
			Where-Object { $_.Value.hard_deletes -gt 0 -or $_.Value.hard_delete_candidates -gt 0 } |
			ForEach-Object {
				[pscustomobject]@{
					Type = $_.Name
					Hard = $_.Value.hard_deletes
					Candidates = $_.Value.hard_delete_candidates
					HardMs = $_.Value.hard_delete_ms
					MaxMs = $_.Value.hard_delete_max_ms
				}
			}
		if ($harddelTypes) {
			$sortedHarddelTypes = $harddelTypes | Sort-Object -Property @{ Expression = "HardMs"; Descending = $true }, @{ Expression = "Candidates"; Descending = $true }
			$sortedHarddelTypes | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $resultDirectory "arena_gc_hotspots_$run.csv")
			$sortedHarddelTypes | Select-Object -First $Top | Format-Table -AutoSize
		}

		$failureDetails = @($arenaReport.gc.failures) | ForEach-Object {
			[pscustomobject]@{
				Type = $_.type
				Name = $_.name
				Ref = $_.ref
				ExternalRefs = $_.external_refs
				ActiveTimers = $_.active_timers
				References = @($_.references) -join " | "
				WorldScanDone = $_.world_scan_done
				WorldScanObjects = $_.world_scan_objects
				Timers = $_.timers
				Components = $_.components
				Signals = $_.signals
				Contents = $_.contents
				LocChain = $_.loc_chain
				CascadeParent = $_.cascade_parent_type
				CascadeChildren = $_.cascade_children
			}
		}
		if ($failureDetails) {
			$failureDetails | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $resultDirectory "arena_gc_failures_$run.csv")
			$failureDetails |
				Sort-Object -Property @{ Expression = "ExternalRefs"; Descending = $true }, @{ Expression = "ActiveTimers"; Descending = $true } |
				Select-Object -First $Top Type, ExternalRefs, ActiveTimers, References, Timers, CascadeParent |
				Format-Table -Wrap -AutoSize
		}
	}
}

Write-Host "Results: $resultDirectory"
if ($failedRuns.Count) {
	throw "Mob benchmark completed with failed game runs: $($failedRuns -join ', '). Artifacts were preserved in $resultDirectory"
}
