# Асинхронная внешняя обработка NETRUN

DM передаёт facts и команды без глобального ожидания ACK. Native bridge имеет
независимые socket read/write очереди. Host разделяет reader, одного владельца
runtime и writer: игровые объекты не создают отдельные threads/tasks.

Соседние world-fact кадры применяются группой перед одним пересчётом топологии.
Перед зависимой командой новая топология публикуется. Готовые результаты и
страницы графа Host отправляет сам; новый запрос для получения ответа не нужен.
ACK-only кадр не вызывает ответный пустой output.

У каждой операции сохраняются request ID, binding и собственный terminal outcome.
Ожидание native result одного устройства не блокирует другие устройства.
Повторы сохраняют исходный first-attempt порядок; непринятый producer head не
может быть пропущен более новым запросом. Отмена освобождает и admission fence.

DM receiver валидирует и резервирует invocation, но не запускает игровой handler
в JSON decoder. Отдельный native execution pump вызывает handler после проверки
актуальных поколений, revisions и causal proof. Receive/send/native pumps
кооперативно уступают CPU планировщику BYOND. Queued work содержит IDs и scalar
proof; после disconnect внешние ссылки снимаются перед удалением объектов.
Уже исполняемый callback удерживает message до возврата и не выполняется повторно.

## Настройки по умолчанию

Искусственные work/count/queue quotas отключены. Для DM и bridge `0` означает
отсутствие квоты; положительные значения позволяют позже измерять backpressure.
В Core используются ленивые collections с машинным maximum вместо прежних
ограничений active requests, queries, events, candidates и topology counts.

Это относится также к journal, native contexts, asynchronous query consumers,
readiness/wake waves, discovery filtering/fanout и worker CPU/item budgets.
Внутренние deadlines отключены по умолчанию. Ошибка/закрытие socket обрабатывается
независимо от deadline, после дренирования уже полученных полных outcomes.

Размеры wire frame, страницы и encoding-группы задают сегментацию протокола,
а не скорость обмена. Exact sequences, hash, поколения и application ACK
сохраняют целостность. Cache/history eviction управляет lifetime/replay;
кэш может вытеснить таблицу, но не запрещает новое вычисление.

## Мониторинг библиотеки

Администратору с `R_DEBUG` доступно окно **Debug.1) Logs → NETRUN Library Monitor**.
Оно автоматически показывает подключение и последний отказ, свежесть Host,
input/output/bridge очереди, facts и machine contexts, native invocations,
query backlog и продвижение GraphSync до интерфейса. Доступны времена Apply/Pump,
память процесса и managed heap, GC, CPU процесса и графики трафика/очередей.
CPU 100% соответствует одному полностью занятому ядру. История хранит последние
60 скалярных снимков с периодом две секунды, без ссылок на игровые объекты.

Host получает opt-in `hello.monitoring: true` и раз в две секунды отправляет
отдельный `monitor`. Он не требует ACK, не занимает replay journal и не продвигает
simulation time. Если writer занят, наблюдение пропускается; старые samples
не накапливаются. Поэтому возраст полного снимка показан отдельно от доступности
Host: свежий application output тоже подтверждает, что соединение работает.
После 10 секунд без обоих типов ответа окно показывает stale, не закрывая Core.
Нулевая метрика отличается от отсутствующей; OS counters могут быть недоступны.

Монитор использует штатное обновление SStgui только для открытых окон. Его чтение
не открывает библиотеку, не делает native вызовов, не запрашивает topology и
не меняет очереди. Нужны обновлённые Host и DM adapter.

## Диагностика в VV

- `inflight_frames`, `inflight_frame_bytes`, `peak_inflight_frames`: принятые
  bridge кадры до Host ACK; ledger не удерживает их JSON или native объекты.
- `native_inbound_frames/bytes`, `native_outbound_frames/bytes`: очереди bridge.
- `host_apply_ms`, `host_pump_ms`, `host_input_unacked`, `host_output_unacked`:
  Core CPU и очереди отдельно от socket wait.
- `last_ack_ms`, `max_ack_ms`: наблюдавшееся ожидание обработки input.
- `native_invocation_queue`, `native_started_count`, `native_max_queue_wait_ms`:
  применение игровых эффектов отдельно от получения результата.

После обновления нужны согласованные Host и DLL из новой версии `netrun-core`.
Обновите оба репозитория и пересоберите Core перед запуском `NETRUN + DreamDaemon`.
Новый DM требует подтверждённый duplex и не включает stop-and-wait fallback.

Длительные Windows/Docker прогоны новой архитектуры отложены по запросу пользователя.
Результаты прежнего batch-only runtime не являются проверкой этой версии.


## Event-driven subscriptions for local NETRUN machine services

Machine adapters can subscribe to one service family without scanning the entire
registry or polling the Host. `subscribe_service(owner, family, tag, replay)`
returns a `/datum/netrun_service_subscription` handle. The optional tag limits
notifications to a specific service tag; `replay=TRUE` announces existing
matching services once, using the same deferred delivery path as future events.

```dm
/datum/my_adapter
    var/datum/netrun_service_subscription/watch

/datum/my_adapter/New()
    ..()
    watch = SSnetrun.get_machine_transport().subscribe_service(src, "atmos.controller")

/datum/my_adapter/netrun_service_changed(event, family, tag, identity, datum/netrun_machine_service/service)
    if(event == "removed")
        // identity identifies the withdrawn service; service is null
        return
    // "added" or "updated": service is currently registered.
    // Recheck actual route, online state, and authorization before sending.

/datum/my_adapter/Destroy()
    QDEL_NULL(watch)
    return ..()
```

`register()`, `unregister()` and service state notifications publish events
automatically. A provider can explicitly announce a state change with
`SSnetrun.get_machine_transport().announce_service(service, "updated")`.
A tag change emits a tombstone for the old tag before the new observation.

Notifications carry weak identities, are deduplicated until delivery, and run
after the registration signal stack. Unsubscribing or deleting the owner drops
pending notifications. A notification is **not** a C# discovery or route proof;
the existing C# Core remains authoritative for network reachability and
all native gameplay authorization.

Under backpressure, DM coalesces only never-sent opt-in `state` operations;
real `message` commands keep their own request IDs. Completed or retrying
network submissions are never rewritten. Atmospheric device registration also
keeps at most one uncompleted status per controller and schedules one latest-state
refresh when a suppressed update needs resending.


## Core-owned service lifecycle subscriptions

Services still publish authoritative `service_upsert/service_remove` facts through the
native exporter. Persistent family/tag watches are registered in **C# Core**;
DM does not calculate routes or poll discovery to maintain these subscriptions.

```dm
/datum/my_adapter
    var/datum/netrun_core_service_watch/watch

/datum/my_adapter/proc/start_watch(datum/netrun_machine_service/my_service)
    watch = SSnetrun.watch_core_service(src, my_service, "atmos.controller")

/datum/my_adapter/netrun_core_service_changed(change, family, advertised_tag, identity, datum/netrun_machine_service/service)
    if(change == "added" || change == "updated")
        // Service advertisement only. Real action must use send/request_submit,
        // which checks network reachability and native permission on execution.
        return
    if(change == "removed")
        // identity identifies a tombstoned service generation; service is null.
        return
    if(change == "resync_required" || change == "source_unavailable")
        // Register a new watch once the source/connection is ready.
        return

/datum/my_adapter/Destroy()
    QDEL_NULL(watch)
    return ..()
```

The watch is bound to one exact source generation and live Core binding. Initial
`added` notifications are followed by `snapshot_end`. Further notifications
(`added`, `updated`, `removed`) arrive asynchronously through the existing
output journal; DM schedules callbacks outside JSON decoding. A missing/deleted
subscriber or explicit handle deletion invokes `service_unwatch`.

A service can request that its changed advertisement be exported by invoking
`SSnetrun.get_machine_transport().index_service(service)`. Identical full facts
do not produce new Core events. Existing local `subscribe_service` callbacks
remain available for native lifecycle events before the Core is ready.

This phase migrates **service discovery observation**. Actual network effects,
authentication, routing, and permission checks still use the established
`DM -> Core request -> service_invocation -> DM provider -> invocation_result`
contract. Route/visibility-aware subscriptions will follow separately.


### Первая реальная миграция потребителя: атмосфера

`atmos.controller` теперь отслеживается **одной** Core-подпиской на всю
атмосферную сеть станции, а не отдельной подпиской на каждую вентиляцию.
`netrun_atmos_core_observer` размещается в локальном transport и выбирает
одну живую `atmos.device` как источник. На события `added/updated/removed`
от Core он будит устройства только соответствующей native area, используя
существующие индексы; доставку `status` и всё сетевое принятие выполняет Core.

После `snapshot_end` при отсутствии совместимого alarm контроллера
индивидуальные устройства больше не создают бесконечные регистрации каждые
30 секунд. Когда Core объявляет новый контроллер, watcher автоматически
перезапускает регистрацию в затронутой области. Если Core/watch недоступны,
остаётся исходный редкий 30-секундный fallback. Если совместимый контроллер
есть, но сетевой маршрут недоступен, сохраняются попытки доставки и revalidation.

Observer пересоздаёт подписку после смены binding, потери узла-источника и
терминального уведомления `resync_required` с единственным отложенным retry.
Отписка из старого binding не может отменить команду другого, нового binding.
Native callbacks по-прежнему не исполняются в IPC decoder.
