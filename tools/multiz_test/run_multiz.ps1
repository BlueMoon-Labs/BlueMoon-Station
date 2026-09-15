# Поднимает локальный сервер на трёхэтажной карте, чтобы мульти-Z можно было
# посмотреть глазами. Обычная станция односложная, и куб на ней не проверить.
#
#   powershell -ExecutionPolicy Bypass -File tools/multiz_test/run_multiz.ps1
#   powershell -ExecutionPolicy Bypass -File tools/multiz_test/run_multiz.ps1 -Map icemoonstation
#   powershell -ExecutionPolicy Bypass -File tools/multiz_test/run_multiz.ps1 -Port 3000 -SkipBuild
#
# После старта подключаться на byond://localhost:<порт>.

param(
	# На стенде multiz_debug у верхних двух уровней включён "Transparent Space":
	# космос там показывает этаж под собой, так что видимую многослойность видно
	# сразу, стоит выйти наружу.
	#
	# multiz_debug - синтетический стенд на три уровня, грузится за секунды.
	# icemoonstation - настоящая прод-карта с трёхэтажным стеком, грузится долго,
	# зато показывает то, что реально увидят игроки.
	[string]$Map = "multiz_debug",
	[int]$Port = 1337,
	[switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repo

$mapConfig = Join-Path $repo "_maps\$Map.json"
if (-not (Test-Path $mapConfig)) {
	Write-Error "Нет конфига карты: $mapConfig. Доступные: $((Get-ChildItem "_maps\*.json" | ForEach-Object { $_.BaseName }) -join ', ')"
}

New-Item -ItemType Directory -Force -Path (Join-Path $repo "data") | Out-Null
$nextMap = Join-Path $repo "data\next_map.json"
# data/next_map.json читает не только сервер, но и dm-test - он гоняет тесты на
# той же карте. Подменять её насовсем нельзя: часть тестов привязана к станции
# и на отладочной карте падает. Поэтому старую сохраняем и возвращаем на выходе.
$savedMap = if (Test-Path $nextMap) { Get-Content $nextMap -Raw } else { $null }
Copy-Item $mapConfig $nextMap -Force
Write-Host "Карта на следующий раунд: $Map" -ForegroundColor Cyan

try {
	if (-not $SkipBuild) {
		Write-Host "Собираю..." -ForegroundColor Cyan
		& node tools/build/build.js
		if ($LASTEXITCODE -ne 0) { Write-Error "Сборка упала" }
	}

	Write-Host ""
	Write-Host "Стартую сервер на порту $Port. Подключаться: byond://localhost:$Port" -ForegroundColor Green
	Write-Host "В игре: Debug -> 7) Testing -> 'Multi-Z: панель'" -ForegroundColor Green
	Write-Host ""

	& node tools/build/build.js server --port=$Port
}
finally {
	if ($null -ne $savedMap) {
		Set-Content -Path $nextMap -Value $savedMap -NoNewline
		Write-Host "Карта следующего раунда возвращена как была." -ForegroundColor DarkGray
	}
	else {
		Remove-Item $nextMap -ErrorAction SilentlyContinue
	}
}
