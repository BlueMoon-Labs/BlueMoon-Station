# Контрольная версия NETRUN для ручной проверки

Дата: 4 ноября 2026 года.

Станция: ветка `net-feature`. Core: `netrun-core/main`, закреплённый commit
`9bfafbe4ab0546a72f4920d647beb8f034712c04` в `core-source.json`.
Core PR: https://github.com/Dominig12/netrun-core/pull/3.
Основная интеграция станции: https://github.com/Dominig12/MOLOT-BlueMoon-Station/pull/15.

## Запуск на другом компьютере

Нужны Git, BYOND из `dependencies.sh` и штатный Node.js сборочных инструментов.
Из свежего checkout `net-feature`:

```powershell
git clone --branch net-feature https://github.com/Dominig12/MOLOT-BlueMoon-Station.git
cd MOLOT-BlueMoon-Station
.\Build.bat
.\RUN_SERVER.bat
```

Launcher скачает отсутствующий соседний `netrun-core` по закреплённому SHA,
подготовит .NET/Zig и соберёт согласованную пару Host + native bridge.
Существующий Core checkout launcher не переключает и не обновляет сам.
Если рядом уже есть старый/изменённый Core, обновите его `main` либо укажите
новый отсутствующий каталог **в той же PowerShell-сессии перед обеими командами**:

```powershell
$env:NETRUN_CORE_SOURCE = Join-Path (Split-Path (Get-Location) -Parent) 'netrun-core-checkpoint'
.\Build.bat
.\RUN_SERVER.bat
```

Запускайте станцию через `RUN_SERVER.bat`: он поднимает Host вместе с DreamDaemon.
Проверка готовности: игровой лог `NETRUN_CORE_READY external graph_published`.
Администратор: `Debug.1) Logs → NETRUN Library Monitor`.
Структурированные журналы Windows: `data/netrun-core/logs/host.jsonl` и его архивы.
Настройки и Docker: [EXTERNAL_CORE.md](EXTERNAL_CORE.md).

## Проверка контрольной точки

- Release Core: 751/751 тест, сборка без предупреждений.
- Launcher/source/deployment tools: 32/32 теста.
- DM bridge/query/monitor/entity proxy: 40/40 hermetic тестов, BYOND 516.1688.
- Host и Windows x86 native bridge собраны из отдельного чистого checkout
  закреплённого Core, без незакоммиченной работы следующего этапа.
- Live Host + native bridge + DreamDaemon: PASS discovery, native_once,
  projection/source tree, movement/recovery, replaceable state и burst 64.
  Оба сценария настоящего diver также проверяют Core proxy
  register → FIFO damage → новая DM-проекция без синхронного изменения при enqueue.

Полный раунд и нагрузку на целевой станции нужно проверить при ручном запуске.

## Что входит в эту контрольную точку

- Работающая внешняя topology/routing/discovery/transport архитектура сохранена.
- В Core добавлены entity registry, raw access authority, bounded navigation,
  combat/AP/status и файловые/складские owners с общей FIFO-интеграцией.
- Bot profiles/goals/command lifecycle перенесены в отдельный Core-модуль.
- Поддерживаются явные DLL-плагины и stateful моды с cooperative задачами,
  отдельным состоянием binding, scaffold и примерами.
- Host пишет JSONL с корреляцией, ротацией, постоянной telemetry и pressure events.
- DM получил явный entity proxy, raw credential/policy exporter и отдельное
  подтверждение native движения; исправлена потеря общей R&D-подписки при rebind.

## Граница текущей версии

Это рабочая промежуточная версия, а не завершённый перенос всей системы.
Production DM brains/combat/navigation и файловые facades ещё не переключены
целиком на новые owners. Entity bridge включается явно; обычная игра сохраняет
прежнее поведение. Core live test дополнительно проверяет настоящий proxy
register → FIFO damage → immutable projection через DM/native bridge/Host.

Продолжать в новом чате нужно с полного handoff bot/ICE orchestration и inventory,
связывания расходников с exact Core file UID, remote breach/contacts, native
spawn/death/loot и восстановления состояния после reconnect. Затем перенести
оставшиеся сетевые объекты/content/security rules и UI read models, обнулить
production consumers DM scheduler и удалить сам scheduler. DM должен оставить
только факты/намерения, native effects и проекции. Не возвращать локальный
решатель или fallback-симуляцию.

Подробные контракты и ограничения находятся в `netrun-core/docs/ownership.md`,
`entity-migration.md`, `entity-bots.md`, `combat-core.md`, `storage.md`, `plugins.md`.
Локальные незакоммиченные изменения следующей интеграции ботов не входят в
закреплённый SHA и должны сохраняться отдельной работой.

## Следующий локальный участок: production поиск пути

Поверх этой контрольной пары подключён production поиск пути для resident/diver
`navigation.start()`, UI `move`/`hop`/`relay_hop`, преследование и переходы обычных owned agents:
raw access facts → существующий Core bounded
navigation broker → paged result → отложенный native route timer. Частичные
страницы, изменённые raw права/поколения/source и старый binding отбрасываются;
отмена освобождает также cooperative exporter. Потеря Core не включает DM BFS.
EntityWorld proxy ради навигации не создаётся, поэтому HP/status ownership не
смешивается. Core pin остаётся прежним.

При движении преследуемого native актора старый Core запрос/маршрут отменяется,
после coalesced сигнала отправляется новое намерение к его актуальному узлу.
У owned agents убран соседний `can_enter → hop` обход Core planner; pending не
создаёт дубликаты, terminal отказ однократно возвращается в `move_toward` с
проверкой destination/binding/operation. Possession не запускает автономный AI.
Специальные station/visitor console policies пока исключены из этого handoff.
Явный hop не превращается в автопроход: применяется только одношаговый Core
read model. Relay intent дополнительно сохраняет native physical validation.
Login/Logout отменяют прежнюю navigation generation, отделяя AI/player intents.

BotRuntime в соседнем `netrun-core/netrun-bot-integration` сохранён без изменений.
Аудит выявил, что пока нельзя включать его production wire: он принимает готовый
`BotContext` из DM, выдаёт navigation/combat решения как native, не обновляет
brain из Core owners и неполно fingerprint-ит context. Автоматический brain lane
также требует согласования с общей FIFO. Успешные unit tests сами по себе не
доказывают безопасный handoff.

Остаются DM BFS выбора целей ботов и специальных station/visitor profiles,
UI access/admission, hop/AP/cooldown/threat rules,
ICE/бой, файлы и прочие владельцы из раздела выше. Полная миграция не завершена.
Контракт этого участка: [ASYNC_EXTERNAL.md](../../modular_bluemoon/code/modules/netrun/ASYNC_EXTERNAL.md).

Асинхронные проверки также выявили прежнюю ошибку Atmos observer при reconnect:
удалённый service watch оставлял signal на живом source. Замена watch теперь
сначала освобождает прежнюю подписку, без подавления duplicate-signal проверки.

По просьбе пользователя длительные прогоны остановлены для продолжения переноса
механики. Последующие production изменения pursuit/owned agents пока не прогонялись.
Ранее full-map smoke остановился до этапа новой навигации на native handoff
`native_topology_pending`; success fixture дополнена ожиданием текущего Core tree
и application ACK инфраструктуры. Полный игровой раунд, Docker и нагрузка не доказаны.
