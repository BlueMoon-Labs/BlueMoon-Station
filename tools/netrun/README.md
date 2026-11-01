# Проверка Netrun

Из корня репозитория, Node.js и BYOND из [dependencies.sh](../../dependencies.sh):

```powershell
node tools/netrun/run-tests.mjs --list
node tools/netrun/run-tests.mjs
node tools/netrun/run-tests.mjs --filter scheduler
node tools/netrun/run-tests.mjs --filter execution
node tools/netrun/run-tests.mjs --filter interaction
node tools/netrun/run-tests.mjs --peace-map
```

Runner находит `netrun_*` тесты с `Run()` только в файлах `netrun*.dm`,
подключённых из `_unit_tests.dm`, и записывает выборку в игнорируемый
`tmp/netrun-tests.txt`. Затем вызывает штатный `tools/build/build.js dm-test`
с профилем `hermetic`. Проверяется свежий `data/logs/ci-hermetic/unit_tests.json`:
ошибка сборки, отсутствие отчёта, пропущенный тест, SKIPPED или FAIL дают exit 1.
Production `_compile_options.dm` не меняется. Для нестандартного расположения
BYOND задайте `DM_EXE`: штатный build runner ищет DreamDaemon рядом с компилятором.

`--peace-map` отдельно загружает настоящую «Мирную Синдикат Станцию» через
`full-map` и проверяет стартовую регистрацию R&D и всех питаемых доступных
вентиляций/скрубберов с совместимой тревогой. Частоты и состояние машин тест
не подменяет; устройства без контроллера в своём отсеке не считаются ошибкой
регистрации. Отчёт: `data/logs/ci-full-map/unit_tests.json`. Команда использует
тот же замок запуска и отвергает старый, отсутствующий или пропущенный результат.

`execution` проверяет изменяемые лимиты подсистемы, CPU-бюджет и справедливость
очередей; `interaction` — немедленный ответ, токен receipt, допуск TGUI и отличие
опроса от ввода. `ice_reactive` проверяет событийный запуск защиты с сохранением
телеграфа и cooldown. Тесты `provider_native` проверяют штатные `ui_status`,
доступ по настоящему ID и привязку native UI к исходному устройству.
Настройки и диагностика сервера описаны в
[DEVELOPMENT.md](../../modular_bluemoon/code/modules/netrun/DEVELOPMENT.md).

`--list` только печатает выборку; `--filter` ищет подстроку без учёта регистра.
Пустая выборка считается ошибкой. Не запускайте несколько DM миров одновременно
на одном checkout: общий build runner использует общую папку логов. Собственные
запуски этого runner защищены `tmp/netrun-tests.lock`; после аварийного завершения
удаляйте этот файл только после остановки оставшегося DreamDaemon.

Frontend проверяется отдельно:

```powershell
# Один раз установить зависимости TGUI (используйте yarnPath из tgui/.yarnrc.yml).
cd tgui
node .yarn/releases/yarn-4.18.1.cjs install --immutable
cd ..
node tools/netrun/run-tests.mjs --frontend
node tools/netrun/run-tests.mjs --frontend --filter SessionStatus
```

`--frontend` запускает только Jest для файлов `NetrunTerminal/**/*.test.*`
и `*.spec.*`; BYOND при этом не нужен. Если вы поменяли версии зависимостей,
снова установите их перед запуском.

Самопроверка обнаружения тестов и проверки отчётов (без BYOND):

```powershell
node --test tools/netrun/run-tests.test.mjs
```
