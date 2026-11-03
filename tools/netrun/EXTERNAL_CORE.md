# Развёртывание станции с NETRUN Core

NETRUN Core — публичный отдельный [C# репозиторий](https://github.com/Dominig12/netrun-core).
Он вычисляет топологию, APC bindings, маршруты, поиск сервисов и транспорт.
DM передаёт факты мира, импортирует готовые таблицы, проверяет игровые права и
выполняет действия машин. Для работы сети нужен запущенный Host.

## Требования

| Вариант | Установить один раз |
|---|---|
| Windows, обычные процессы | Git, BYOND из `dependencies.sh`, Node.js из сборочных инструментов станции |
| Docker на Windows | Git, Node.js, Docker Desktop с активным **Linux Engine**, Buildx и Compose |
| Docker на Linux amd64 | Git, Node.js, Docker Engine с Buildx и Compose plugin; право запускать Docker |

При первой сборке нужен интернет. Docker получает Linux SDK, Zig, BYOND и
остальные build dependencies внутри images. Для обычной Windows-сборки SDK и
Zig скачиваются автоматически как portable tools. Глобальная установка .NET/Zig
и изменение системного PATH не нужны. NuGet restore использует lock files.

Если `netrun-core` ещё нет рядом со станцией, launcher сам клонирует его.
Публичный URL и полный commit SHA закреплены в `tools/netrun/core-source.json`.
GitHub token и ручной clone не требуются. Существующий checkout используется
как есть: launcher не делает pull/reset и не перезаписывает локальную работу.
Другой путь задаётся `NETRUN_CORE_SOURCE`. Если существующий старый checkout не
содержит bootstrap scripts, обновите его обычным Git workflow либо выберите новый
отсутствующий путь для автоматического clone.

## Быстрый запуск Windows

Из корня станции:

```powershell
./Build.bat
./RUN_SERVER.bat
```

Juke targets собирают ресурсы/DM, публикуют Host и Windows x86 bridge.
Перед запуском проверяются package hashes. Launcher запускает Host, ждёт listener,
затем запускает DreamDaemon. Выход любого процесса закрывает принадлежащую ему
пару. Ctrl+C также закрывает её; существующие чужие процессы не затрагиваются.

Отдельная сборка NETRUN и запуск уже собранного пакета:

```powershell
node tools/netrun/core-lifecycle.mjs build
node tools/netrun/core-lifecycle.mjs run --no-build
```

`--no-build` требует текущий проверенный пакет. Изменённые исходники или
повреждённые artifacts требуют пересборки. `NETRUN_CORE_BUILD=0` пропускает Core
при компиляции ресурсов/DM, например в CI; запуск сети всё равно требует Host.

## Отладка из VS Code на Windows

В корне станции один раз выполните:

```powershell
node tools/netrun/setup-vscode.mjs
```

Команда добавляет переносимые профили **NETRUN + DreamSeeker**, **NETRUN +
DreamDaemon** и варианты существующих сборок, включая LOWMEMORYMODE и TGUI DEV.
Выберите профиль с префиксом **NETRUN +** в Run and Debug и нажмите F5.
Обычные профили и задачи сохраняются; исходные JSON-файлы дополнительно
сохраняются как `.vscode/*.json.netrun-backup`. Повторная установка не дублирует
профили. Шаблоны `tools/netrun/vscode-launch.json` и
`tools/netrun/vscode-tasks.json` позволяют восстановить профили или установить
их поверх локальных настроек на другом компьютере.

Compound сначала выполняет выбранный `Build All`, затем запускает Host и DM
debugger. DM ждёт подтверждения готовности именно живого Host этого workspace.
Launcher проверяет собранный пакет, копирует x86 bridge в
`data/netrun-core/debug/netrun_bridge.dll` и автоматически создаёт ключ в
`data/netrun-core/session-token.txt`, если файла ещё нет. Следующие запуски
используют тот же ключ. Host и DM получают один и тот же token-файл; унаследованный
`NETRUN_SESSION_TOKEN` не подменяет его. Сам ключ не попадает в `launch.json`,
аргументы команд или Git. Пути используют `${workspaceFolder}` и подходят для
другого компьютера.

Пара использует локальный порт 18462. Второй NETRUN debug launch в том же
workspace отклоняется до копирования DLL и запуска второго Host. Остановка
compound завершает оба процесса. Для отдельной ручной остановки предусмотрена
задача **Tasks: Run Task → NETRUN: stop Host**. Старые PID-файлы не используются
для проверки готовности или остановки процессов.

## Автоматические SDK и Zig

`netrun-core/scripts/ensure-toolchains.ps1` проверяет явные
`NETRUN_DOTNET`/`NETRUN_ZIG`, подходящие инструменты в PATH и portable cache.
Несовместимый явный путь считается ошибкой. При отсутствии нужной версии
скачивается закреплённый официальный archive, проверяется SHA-512 для SDK или
SHA-256 для Zig, затем публикуется готовый каталог. Незавершённая загрузка не
становится рабочим инструментом.

Cache по умолчанию: `%LOCALAPPDATA%/NETRUN/toolchains`.
`NETRUN_TOOLCHAIN_CACHE` меняет его. Пути `.codex/cache` больше не используются.
Первая сборка требует времени и места для ZIP и распаковки; последующие используют
готовые tools. Версии: .NET SDK из `global.json` (10.0.403 с совместимыми patch
updates той же feature band), Zig 0.17.0.

Подготовить tools отдельно:

```powershell
../netrun-core/scripts/ensure-toolchains.ps1 -Tool all
../netrun-core/scripts/build-native.ps1 -Target all
```

Для offline-сборки заранее подготовьте checkout, portable и NuGet caches либо
укажите установленные совместимые tools. Ошибка загрузки оставляет существующий
checkout и готовые сборки.

## Docker: одна команда развёртывания

Запустите Docker Desktop и дождитесь Linux Engine. Из корня станции:

```sh
node tools/netrun/docker-lifecycle.mjs deploy
```

Команда проверяет Docker/Compose/Buildx, получает отсутствующий Core, собирает
согласованные station/Host images, создаёт file secret и запускает пару в фоне.
На Windows Docker CLI находится и при per-user установке без обновлённого PATH.
`NETRUN_DOCKER` задаёт точный путь к CLI. Сам Docker launcher не устанавливает.

Station image использует Node 24/bookworm: Node нужен и игровому loadout crypto
helper. BYOND остаётся x86; его архив проверяется по закреплённому SHA-256.
При обрывах полной загрузки downloader получает проверяемые диапазоны с mirror,
собирает архив и повторно проверяет весь hash. Cargo/Juke caches сохраняются между
сборками; несовместимый release NanoMap собирается из закреплённых исходников.
Host работает отдельно от root с read-only filesystem в loopback namespace BYOND.

По умолчанию используются checkout `config`, project `molot-netrun` и игровой
адрес `127.0.0.1:1337`. Проверяйте локально по `byond://127.0.0.1:1337`.
Для доступа с других машин задайте publish address и config **перед deploy**:

```sh
# Linux shell
export NETRUN_GAME_ADDRESS=0.0.0.0
export NETRUN_GAME_PORT=1337
export NETRUN_CONFIG_DIRECTORY=/srv/molot/config
node tools/netrun/docker-lifecycle.mjs deploy
```

```powershell
# PowerShell
$env:NETRUN_GAME_ADDRESS = '0.0.0.0'
$env:NETRUN_GAME_PORT = '1337'
$env:NETRUN_CONFIG_DIRECTORY = 'C:/servers/molot/config'
node tools/netrun/docker-lifecycle.mjs deploy
```

Config directory должен существовать; source mount read-only. Entry point копирует
его в `/tgstation/config`, а secret — в приватный native filesystem file: 32-битный
BYOND не читает Windows bind mounts с inode больше 32 бит. Host читает исходный
secret. Настройки станции редактируются в исходном config до запуска; paired
`restart` получает свежую копию. Для unattended smoke без игроков включите
`RESUME_AFTER_INITIALIZATIONS`: по умолчанию мир засыпает после инициализации,
до первого клиента. Внешняя доступность игрового порта зависит также
от firewall и маршрутизации хоста.

Управление deployment:

```sh
node tools/netrun/docker-lifecycle.mjs status
node tools/netrun/docker-lifecycle.mjs logs
node tools/netrun/docker-lifecycle.mjs config
node tools/netrun/docker-lifecycle.mjs restart
node tools/netrun/docker-lifecycle.mjs stop
node tools/netrun/docker-lifecycle.mjs down
```

`status` показывает контейнеры и health; `logs` — bounded tail.
`config` проверяет Compose без вывода секретов. `restart` пересоздаёт оба
контейнера вместе, поскольку Host использует network namespace станции.
`stop` останавливает их; `down` также удаляет контейнеры и project network.
Named volume с игровыми данными сохраняется.

`data/netrun-core/docker-deployment.json` фиксирует config/token paths, images,
project и параметры порта. Управляющие команды используют этот state; им не
нужны Core checkout, новая сборка или новый token.

Для работы с логами в текущем терминале:

```sh
node tools/netrun/docker-lifecycle.mjs build
node tools/netrun/docker-lifecycle.mjs up --no-build
```

Attached `up` останавливает пару после выхода любого контейнера; Ctrl+C делает
`down` без удаления data volume. Для фонового запуска используйте `deploy`.
Restart policy контейнеров не заменяет paired `restart` после ручной замены
images или namespace станции.

## Обновление, возврат версии и данные

Сохраните config и необходимые игровые данные. Обновите станцию и выбранный Core
checkout обычным Git workflow, затем повторите `deploy`. Обе части получают
одинаковый Core source digest. Незакоммиченные изменения учитываются по bytes.
Launcher не обновляет существующий репозиторий автоматически.

Для возврата выберите нужные согласованные commits в обоих checkout и повторите
`deploy`. Код не откатывает содержимое data volume: backup нужен отдельно.
Удаление volumes и `docker image prune` в launcher не входят.

Не удаляйте `data/netrun-core` между командами управления: там state и generated
token. Игровые данные Docker находятся в volume
`<project>_netrun-station-data`. При переносе сервера подготовьте config, этот
volume и token с подходящими правами. Token не добавляется в Git.

## Настройки

Windows launcher сохраняет структурированный журнал Host в
`data/netrun-core/logs/host.jsonl`. JSONL содержит world/engine/binding,
request/input/output identifiers, безопасные event/code и постоянные telemetry
samples. DM пишет соответствующие `NETRUN_EVENT` и `NETRUN_CORE_REJECT` в
штатный игровой журнал; `binding_epoch` связывает записи обеих сторон.
Payload, содержимое файлов и session token в эти события не попадают.

Host использует неблокирующий bounded log sink и ротацию: 16 MiB активный файл
и четыре архива по умолчанию. Пределы и уровень задаются `NETRUN_LOG_CAPACITY`,
`NETRUN_LOG_MAX_FILE_BYTES`, `NETRUN_LOG_RETAINED_FILES`, `NETRUN_LOG_LEVEL`.
`NETRUN_LOG_FILE` меняет путь; `NETRUN_LOG_TELEMETRY_INTERVAL_MS=0` отключает
постоянные снимки, сохраняя lifecycle/error events. При явном файле default
интервал — 2000 ms. Счётчики dropped/sink failures позволяют обнаружить потери
диагностики при переполнении без остановки игрового обмена.

Compose сохраняет JSONL через stdout/stderr и Docker `json-file` logging с
пределом 16 MiB × 5 файлов на каждый контейнер; telemetry также включена каждые
две секунды. `docker compose logs` позволяет экспортировать сохранённые записи.
Явная загрузка доверенных локальных модов Host задаётся `NETRUN_PLUGIN_PATHS`
(`;` между DLL в Windows, `:` в Linux); пути должны существовать внутри процесса
Host. Автоматического поиска/скачивания исполняемых расширений нет.

| Переменная | Назначение |
|---|---|
| `NETRUN_CORE_SOURCE` | Другой существующий либо автоматически клонируемый путь Core |
| `NETRUN_TOOLCHAIN_CACHE` | Portable .NET/Zig cache Windows |
| `NETRUN_DOTNET`, `NETRUN_ZIG` | Явные пути к совместимым executable |
| `NETRUN_DOCKER` | Docker CLI executable |
| `NETRUN_CORE_PORT` | Windows loopback port Host, default 18462 |
| `NETRUN_CORE_TOKEN_FILE` | External/ignored token file, default `data/netrun-core/session-token.txt` |
| `NETRUN_CONFIG_DIRECTORY` | Docker config, default checkout `config` |
| `NETRUN_COMPOSE_PROJECT` | Имя собственного project, default `molot-netrun` |
| `NETRUN_GAME_ADDRESS`, `NETRUN_GAME_PORT` | Docker address/port, default `127.0.0.1:1337` |
| `NETRUN_HOST_UID`, `NETRUN_HOST_GID` | Non-root Host identity для доступа к file secret |

Token не передаётся через argv, build args, world.params или manifest.
Host получает путь через `NETRUN_SESSION_TOKEN_FILE`. Для собственного файла
на Linux обеспечьте чтение UID/GID Host. Generated token имеет mode 0640;
launcher выбирает текущего пользователя либо UID 1654 при root.

BYOND x86 runtime остаётся в Xenial; TGUI/DM собираются в Node 24 Bookworm stage,
Host запускается в поддерживаемом .NET runtime image. Bridge строится Zig для
x86/glibc 2.17. Контейнеры делят loopback namespace; Host не публикует внешний
порт. DreamDaemon ждёт listener. Host работает non-root с read-only filesystem.
Build context Core ограничен исходниками и SHA manifest, без secrets/user settings.

Разрыв IPC отзывает старую authority и запускает fresh binding/full snapshot
с backoff 1..30 секунд. Mutating requests не replay-ятся автоматически.
Ошибка Host не включает второй сетевой движок в DM.

## Диагностика и проверки

При Docker preflight error проверьте `docker version`, Linux Engine и доступ к
daemon. После установки Docker Desktop может понадобиться перезагрузка.
Если сборка падает с `metadata_v2.db: read-only file system`, запись отвергает
внутреннее хранилище Docker. Проверьте свободное место на диске Docker и выполните
Restart Docker Desktop в [Troubleshoot](https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/),
затем повторите ту же команду. Этот вывод сам по себе не определяет причину
перехода файловой системы в read-only; при повторении нужны диагностика Docker
и `docker system df`.
При download error проверьте Git/интернет/закреплённый commit и повторите команду:
незавершённый staging не публикуется как готовый checkout. При несовместимом tool
проверьте явные `NETRUN_*` overrides.

```sh
node --test tools/netrun/*.test.mjs
node tools/netrun/probe-host-lifecycle.mjs
node tools/netrun/run-live-core-test.mjs
```

Host probe проверяет настоящий published Host и закрытие listener после TCP child.
Live smoke компилирует полный station code на hermetic карте и запускает настоящие
Host/DreamDaemon: discovery, native delivery, GraphSync, source tree и отзыв
маршрута при movement, отдельный контракт доставки `state`, карту нейролинка,
локальный сервисный порт и перенос сознания в резидента с его картой.
`NETRUN_CORE_READY external graph_published` появляется после snapshot/catch-up
и публикации графа Core. `NETRUN_PROJECTION_READY native_graph` подтверждает импорт
графа в DM. Source trees для открытых карт запрашиваются асинхронно после этого;
первый pending ответ ещё не означает отсутствие доступных узлов.
`NETRUN_CORE_RETRY <code>` указывает на восстановление IPC с новой binding epoch.
Открытый game port сам по себе не доказывает готовность Core или карты.
Bounded логи: `data/netrun-core/live-tests`.
Общий `tmp/netrun-tests.lock` предотвращает второй station test world.
Это не нагрузочный тест production раунда с игроками.

В строке NETRUN на панели подсистем выводятся отдельные показатели моста:
`IPC KiB Tx/Rx` — накопленный объём JSON-тел DM → Core / Core → DM;
`ACK ms last/max` — физическое ожидание последнего/самого долгого application ACK,
включая время до очередного прохода DM; `Facts` — оставшиеся записи журнала.
Это диагностика текущего процесса, без содержимого сообщений и ключей. Счётчики
сохраняются при переподключении. Суммарный Docker Network I/O не отделяет этот
обмен от игрового трафика и передачи ресурсов BYOND и не является скоростью.

Изменения мира поступают через события и объединяются до отправки. Во время
запросов и ожидания ACK мост обслуживается каждый игровой тик; без работы
остается только редкий heartbeat. Сохранённые таблицы маршрутов обновляются по
следующему чтению, поэтому закрытые окна не подписывают все прошлые источники
на постоянную повторную передачу таблиц. Host выдаёт до восьми событий за ответ;
продолжения графа делят очередь с discovery и другими запросами.

`tools/deploy.sh` переносит `tgui/public`, `tgui/packages/tgfont/dist` и
`modular_bluemoon/code/modules/lobby/lobby_html.txt` вместе с
игровыми файлами и отклоняет сборку без обязательных bundles/fonts. Они нужны
во время работы мира: наличие только DMB/RSC не обеспечивает загрузку TGUI.
После исправления состава runtime image пересоберите и заново разверните пару.

Live smoke также сохраняет фактический `ui_data` гостя из NTnet-реле в ignored
`data/netrun-core/live-relay-ui.json`. После успешного запуска можно проверить
этот ответ в настоящем TGUI reducer, map stream и контроллере сцены (GPU заменён
test surface):

```powershell
$env:NETRUN_LIVE_UI_PAYLOAD = (Resolve-Path data/netrun-core/live-relay-ui.json).Path
Push-Location tgui
node .yarn/releases/yarn-4.18.1.cjs jest --runInBand --runTestsByPath packages/tgui/interfaces/NetrunTerminal/LiveCoreMap.test.tsx
Pop-Location
Remove-Item Env:NETRUN_LIVE_UI_PAYLOAD
```

Без этого явного artifact test пропускается. Проверка подтверждает цепочку
Host → native bridge → DM projection → public UI payload → frontend graph;
она не подменяет визуальную проверку WebGL в DreamSeeker.
