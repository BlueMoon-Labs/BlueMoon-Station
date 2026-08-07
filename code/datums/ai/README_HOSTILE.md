# Hostile AI: событийные контроллеры

Оверхол AI hostile-мобов: событийный сон/пробуждение вместо поллинга,
поиск целей через спатиал-грид вместо hearers(), скоринг вместо случайного
выбора, гибридное direct/JPS движение, профили поведения из
переиспользуемых сабтри. Донор архитектуры - tgstation@14140a6355d1
(атрибуция в шапках портированных файлов), вент-механика частично
Paradise@6323ddd65be9.

## Карта системы

### Восприятие и пробуждение
- **Канал AI_TARGETS** (`code/controllers/subsystem/spatial_grid.dm`,
  `code/modules/mob/living/ai_targetable.dm`): живые мобы числятся в ячейках
  грида; смерть/оживление двигают членство через `set_stat`.
- **Окно интересности** (`/datum/cell_tracker`): контроллер подписан на
  вход/выход клиентов из ячеек вокруг пауна радиусом
  `max(vision_range, aggro_vision_range)`. Клиент вошёл - контроллер
  проснулся синхронно; ушёл - уснул. Спящий (`AI_STATUS_IDLE`) контроллер
  не состоит ни в одной очереди обработки.
- **Другие пути пробуждения**: урон (`note_attacker`, `adjustHealth`),
  новая обида (`add_enemy`), доклад союзника о контакте
  (`report_contact_to_allies` -> `receive_combat_contact`: передаётся точка
  и приметы, не сам атом), шум (`ai_broadcast_noise`), приход клиентов на
  z-уровень (`update_z`).

### Решения
- **Поиск целей** (`behaviors/find_potential_targets.dm`): грубый пул из
  ячеек грида + реестр `GLOB.hostile_machines` -> точная дистанция ->
  стратегия -> LOS последним. Никаких hearers()/view().
- **Стратегии** (`targeting/_targeting_strategy.dm`): `hostile_legacy`
  делегирует `mob.CanAttack()` (все сабтиповые переопределения работают);
  варианты: `ignore_sight` (смэшеры), `retaliate` (только обидчики),
  `ignore_sight/megafauna` (peaceful/enemies-гейт: без обидчиков босс
  замечает цели только в живом vision_range и с LOS, с обидчиками -
  строго их, на полном радиусе и сквозь стены). Стратегия может
  переопределить радиус (`get_aggro_range`) и требование зрения
  (`ignores_sight`) по состоянию конкретного моба.
- **Скорер** (`targeting/target_scorer.dm`): одно ранжирование за проход
  (`rank()`), липкая текущая цель (детерминированный гистерезис), бонусы
  непротухшей обиде и разыскиваемому контакту, штраф дистанции и фрустрации;
  случайность только среди почти равных. После нескольких подряд столкновений
  с союзной очередью target finder разово предпочитает близкого противника,
  которого уже можно атаковать или свободно начать преследовать; одиночный
  bump и отсутствие альтернатив цель не меняют.
- **Combat contact** (`hostile_memory.dm`): живая цель и сведения о ней
  разделены. Потеря LOS немедленно разжалует цель в контакт: weak-идентичность,
  последняя ПОДТВЕРЖДЁННАЯ точка, время и источник (personal/ally/noise);
  движение дальше идёт только к точке-улике, а атом снова становится целью
  исключительно через собственный LOS в find_potential_targets.
- **FSM** (`subtrees/hostile_fsm.dm`): IDLE -> ALERT (читаемая пауза
  обнаружения на холодном контакте) -> ENGAGE -> SEARCH (дальники сначала
  держат прикрывающую позицию, потом 2-3 точки осмотра вокруг улики) ->
  RETREAT (порог здоровья с гистерезисом и разворотом при зажиме) -> GUARD
  (leash к дому). Мирный патруль возвращается к якорю штатным мувером;
  якорь переезжает только при явном телепорте/смене z.

### Движение
- **Гибрид** (`movement/ai_movement_hybrid.dm`): прямой шаг в открытом
  пространстве; дистанция сама по себе не запускает JPS. После 2 настоящих
  неудач подряд или перед статической преградой включается JPS с кэшем пути
  и кулдауном перепрокладки `controller.repath_delay` (1.5с). Временная
  пробка из мобов остаётся на дешёвом direct-loop; JPS бюджетируется
  lease-семафором SSpathfinder.
- **Препятствия** (`obstacle_policy.dm`, `subtrees/attack_obstacle_in_path.dm`):
  политика открыть/форсить/поддеть/сломать/сдаться; атакуется реальный
  следующий турф кэшированного JPS-пути, а не догадка по направлению.
  Общий gate учитывает access, атмосферу, вакуум, лаву, пропасти и способности
  конкретного моба; исчерпанный маршрут освобождает цель с коротким backoff.

### Дальний бой
- **Трасса выстрела** (`subtrees/ranged_skirmish.dm`, `hostile.dm`):
  controller-стрелки проверяют позицию и каждый снаряд по фактическому
  pixel-step маршруту projectile, включая обе кардинальные половины
  диагонального `Move()`. Стена или союзник вызывают боковое перестроение;
  projectile pass/phasing/piercing-флаги и кастомные `OpenFire()` без снаряда сохраняются.

### Профили (`hostile_adapter/profiles.dm`)
melee_chaser, brute_charger, ranged_skirmisher, ranged_chaser, pack_hunter,
ambusher, adaptive_hunter, coward_scavenger, guard_defender, support,
vent_hunter, boss, terror_spider, а также сценарные: curseblob,
floor_cluwne, insane_clown, swarmer, bee, minebot, leaper, decoy_escape
(escape-иллюзия), mecha_pilot (FSM пилотирования сабтри-делегатом).
Автоназначение по легаси-флагам в `select_ai_profile()`
(charger/ranged/retreat_distance); специализированные назначения собраны в
`hostile_adapter/profile_assignments.dm`.

### Адаптер (`hostile_adapter/hostile_adapter.dm`)
Поддерживает легаси-состояние моба (`pawn.target`, Aggro/LoseAggro,
in_melee) и делегирует исполнение ударов мобу (MeleeAction/OpenFire/
enter_charge/sidestep) - сабтиповые переопределения атак работают без
изменений.

### Боссы (`boss/boss_attack.dm`, `boss/boss_attack_tables.dm`)
Таблицы атак с весами/дальностями/фазами по здоровью/кулдаунами вместо
rand()-цепочек; записи оборачивают легаси-проки атак. `ai_ability_prelude()`
сохраняет прелюдии OpenFire (anger, фазовые бафы, blood_warp). Без таблицы
босс стреляет по-старому. Путь игрока (client/chosen_attack) не тронут.

## Как назначить специализированный профиль

1. Добавить `ai_profile_type` в `hostile_adapter/profile_assignments.dm`
   либо непосредственно на сабтипе.
2. Если у моба кастомный CanAttack/AttackingTarget/OpenFire - они
   продолжают работать через делегацию; особый выбор целей делается
   стратегией/скорером (см. terror_controller.dm как образец
   декомпозиции).
3. Спец-idle-механики - в сабтри с гейтом "нет цели" (образец: терроры).
4. Прогнать `hostile_ai_baseline` и профильные тесты.

## Легаси-пулы

Легаси-планировщика hostile больше нет: цепочка
handle_automated_action -> ListTargets/FindTarget/PickTarget ->
MoveToTarget/Goto удалена вместе с SSchunks. SSnpcpool/SSidlenpcpool
обслуживают только мирных simple animals и ботов. Каждый hostile-тип либо
на адаптер-контроллере, либо задокументирован как AI_OFF-исключение без
собственного NPC-AI (`hostile_adapter/MIGRATION_EXCEPTIONS.md`).
Мобы с контроллером жёстко AI_OFF для легаси-пулов (гвард в toggle_ai).

## Диагностика

- `GLOB.ai_metrics` - счётчики (planning_cycles, candidates_examined,
  targets_acquired, los_checks, jps_requests/repaths, failed_moves,
  successful_moves, hearers_calls).
- Бенчмарк - `/datum/unit_test/ai_benchmark_baseline`
  (`data/mob_benchmark_v3.json`): SSmobs Life, idle-пулы мирных NPC,
  controller AI, spatial targeting, obstacle/JPS routing и boss selector.
  Live arena - `/datum/unit_test/ai_mob_arena_benchmark`: все типы
  `/mob/living/simple_animal/hostile` в герметичной арене, реальный бой через
  Master Controller, отдельные профили spawn/combat/cleanup и per-type GC/harddel-кандидаты.
  Headless-запуск всего набора: `tools\mob_bench\run_headless.ps1 -Tag candidate -Runs 3`;
  только арены: `tools\mob_bench\run_headless.ps1 -Mode Arena -Tag candidate`.
  Стресс-профили из раундов: `-Mode ArenaRound16` и `-Mode ArenaRound20`;
  per-type SSmachines-профиль подключается флагом `-ProfileMachines`.
  Для настоящего harddel-прохода (130 секунд на освобождение спящих DM-фреймов,
  затем принудительный и профилируемый Q3) используется отдельный режим
  `tools\mob_bench\run_headless.ps1 -Mode ArenaHarddel -Tag harddel`; для
  раундовых составов доступны `ArenaRound16Harddel` и `ArenaRound20Harddel`.
- Статусы контроллеров - stat entry SSai_controllers (ON/IDLE/OFF).
