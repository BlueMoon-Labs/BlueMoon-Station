# Контрольная версия NETRUN для ручной проверки

Дата: 3 ноября 2026 года.

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
