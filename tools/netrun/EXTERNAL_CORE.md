# Сборка и запуск внешнего NETRUN Core

Production default — `external`, в том числе при прямом запуске DreamDaemon.
Недоступность Host завершает внешние запросы отказом и не включает DM routing.
`NETRUN_CORE_MODE=dm` оставлен явным diagnostic/test режимом.

## Windows: обычные процессы

Рядом со станцией нужен checkout `netrun-core`. Другой путь задаётся явно:

```powershell
$env:NETRUN_CORE_SOURCE = 'C:/work/netrun-core'
./Build.bat
./RUN_SERVER.bat
```

Обычный Juke `BuildTarget` собирает TGUI/DM, публикует .NET Host и собирает x86
bridge. Нужны уже установленные SDK из `netrun-core/global.json` и portable Zig.
Скрипты ничего не устанавливают. SDK ищется в PATH или существующем user cache
`.codex/cache/netrun-dotnet/sdk`; `NETRUN_DOTNET` и `NETRUN_ZIG` задают точные пути.
Native compiler также использует существующий `.codex/cache/netrun-zig`.
`scripts/build-native.ps1` совместим со штатным Windows PowerShell 5.1.

Host и DLL строятся из одной сохранённой копии source inputs. Manifest содержит
Git revision, SHA-256 каждого input и общий content digest, поэтому учитывает
также незакоммиченные изменения. Секреты, `bin/obj` и user settings в эту копию
не входят. Результаты находятся в ignored `data/netrun-core/builds`; pointer
`data/netrun-core/build.json` публикуется только после успешной сборки обоих
компонентов. Перед запуском проверяются source digest и все artifact hashes.

`RUN_SERVER.bat` использует managed Juke `ServerTarget`: запускает hidden Host,
ждёт его listener и затем запускает hidden DreamDaemon. Завершение любого
процесса закрывает пару. Ctrl+C также завершает принадлежащие launcher процессы.
Процессный launcher не делает автоматический restart. Внутри живой пары protocol
resync открывает fresh binding/full snapshot с physical backoff 1..30 s, сохраняя
client/effects и world epoch. Mutating requests автоматически не replay-ятся. Существующий
`tgstation-server/Start Server.bat` watchdog этим механизмом не изменяется.

Отдельные команды после уже выполненной сборки:

```powershell
node tools/netrun/core-lifecycle.mjs build
node tools/netrun/core-lifecycle.mjs run --no-build
node tools/netrun/probe-host-lifecycle.mjs
```

Последняя команда запускает настоящий опубликованный Host и tiny TCP child;
station world она не запускает. Проверяет порядок готовности и закрытие
listener/processes после завершения child.

`NETRUN_CORE_PORT` задаёт loopback port Host (по умолчанию 18462).
Token автоматически создаётся в ignored `data/netrun-core/session-token.txt`.
`NETRUN_CORE_TOKEN_FILE` позволяет указать внешний или ignored файл. Сам token
не попадает в argv, `world.params`, manifest, build context или stdout.
Тот же file path передаётся Host через `NETRUN_SESSION_TOKEN_FILE`.

`NETRUN_CORE_BUILD=0` явно выбирает только сборку ресурсов/DM, например в
station compile CI либо Docker stage. Runtime fallback эта настройка не даёт:
managed external launch всё равно требует проверенный пакет Host/DLL.
DM unit runners явно задают дочерним test worlds `NETRUN_CORE_MODE=dm`.

## Linux: Docker

Dockerfile содержит targets `netrun-station` и `netrun-host`. Старый BYOND runtime
Ubuntu Xenial сохранён: .NET 10 работает в отдельном поддерживаемом runtime image.
Сборка TGUI/DM выполняется в отдельном `node:24.16.0-bookworm` с BYOND compiler;
Node 24 не запускается внутри Xenial, поскольку требует более новую glibc.
Источник: [Node 24.16.0 toolchains](https://github.com/nodejs/node/blob/v24.16.0/BUILDING.md#official-binary-platforms-and-toolchains).
BYOND stage также содержит 32-bit libcurl (`libcurl3:i386` в Xenial), необходимую
начиная с [BYOND 516.1664](https://www.byond.com/docs/notes/516.html).
Оба image получают один и тот же Core digest. Native bridge собирается portable
Zig 0.17.0 для x86/glibc 2.17; официальный archive проверяется SHA-256
`1cbe9df9f27e6b78d14ccbca43b6703a404ef79ef1c463de901d7f088d4e2026`.
Источник pin: [официальный Zig manifest](https://ziglang.org/download/index.json).

Из корня станции на Docker Engine с Linux amd64 и Buildx:

```sh
export NETRUN_CORE_SOURCE=/reviewed/checkouts/netrun-core
export NETRUN_CONFIG_DIRECTORY=/reviewed/station/config
node tools/netrun/docker-lifecycle.mjs build
node tools/netrun/docker-lifecycle.mjs up --no-build
```

Launcher создаёт минимальный named context `netrun_core` с точными bytes и
`source-files.sha256`; Docker проверяет общий digest, каждый файл и отсутствие
лишних inputs. Git clone/pull/latest здесь не используется. Named context явно
подменяет пустой stage: обычный `docker build .` без контекста завершается
отказом. Это штатный
[Buildx named context](https://docs.docker.com/reference/cli/docker/buildx/build/#build-context).

Compose объединяет network namespace двух контейнеров. Контейнер станции
сначала создаёт namespace и ждёт Host; DreamDaemon стартует после listener.
Host слушает только общий `127.0.0.1`, наружу опубликован игровой port 1337
(`NETRUN_GAME_PORT` меняет host port). `up --abort-on-container-exit` завершает
всю пару при остановке любого участника; launcher выполняет `down` в cleanup.
Named game-data volume при `down` сохраняется. Config mount read-only.

Session token передаётся двум участникам через file secret. Generated file имеет
mode 0640; non-root Host UID/GID выбираются из текущего пользователя, а при запуске
launcher от root используется UID 1654 и группа владельца файла. Для заранее
подготовленного секрета задайте подходящие `NETRUN_HOST_UID`/`NETRUN_HOST_GID`,
чтобы Host мог читать файл. Содержимое секрета не копируется в images.

Проверка конфигурации и явная остановка принадлежащего project:

```sh
node tools/netrun/docker-lifecycle.mjs config
node tools/netrun/docker-lifecycle.mjs down
```

`NETRUN_COMPOSE_PROJECT` меняет имя project (по умолчанию `molot-netrun`).
Новые скрипты не применялись к существующему серверу. Здесь локально проверены
Windows build/process lifecycle, Node tests и shell syntax. Docker CLI отсутствует,
поэтому Docker build, `compose config/up` и Linux BYOND runtime ещё не выполнялись.

## Проверки

```sh
node --test tools/netrun/core-lifecycle.test.mjs tools/netrun/docker-lifecycle.test.mjs tools/netrun/run-tests.test.mjs tools/netrun/run-live-core-test.test.mjs
```

Сохранённый полный BYOND/bridge/Host tiny-world E2E находится в соседнем Core repo:

```sh
python tests/native/test_external_dm.py
```

Он компилирует production DM client/effects в отдельном temp world, проверяет
snapshot/catchup с заменой source component, graph-ready, native message lifecycle
и отказ от ACK неизвестного эффекта. Station test runner и production world
этот тест не запускает.

Отдельный live smoke использует полный station code и настоящий subsystem/runtime
на hermetic test map:

```sh
node tools/netrun/run-live-core-test.mjs
# Использовать уже проверенный текущий published bundle:
node tools/netrun/run-live-core-test.mjs --no-build
```

Он добавляет compile define `NETRUN_CORE_LIVE_TEST` и выбирает ровно
`/datum/unit_test/netrun_core_live`. Обычная test selection этот opt-in файл
исключает. Smoke проверяет live snapshot readiness, асинхронный C# service
discovery, однократный native receive/terminal callback, импорт graph/source tree,
немедленный отзыв старого tree при movement и восстановление новой проекции.
Native topology rebuild, APC prebuild и machine tree-build counters не должны
увеличиваться.

Launcher использует общий `tmp/netrun-tests.lock`, поэтому не запускает второй
station test world поверх текущего. Compile ограничен пятью минутами, runtime —
десятью. Полный вывод сохраняется в bounded ignored
`data/netrun-core/live-tests/...`; stdout содержит только фиксированные stages и
итог. Host и DreamDaemon запускаются hidden и принадлежат одной managed паре.
Production map или существующий сервер этим smoke не запускаются.
