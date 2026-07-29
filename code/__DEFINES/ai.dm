#define GET_AI_BEHAVIOR(behavior_type) SSai_behaviors.ai_behaviors[behavior_type]
#define HAS_AI_CONTROLLER_TYPE(thing, type) istype(thing?.ai_controller, type)
#define GET_TARGETING_STRATEGY(strategy_type) SSai_behaviors.targeting_strategies[strategy_type]
#define GET_TARGET_SCORER(scorer_type) SSai_behaviors.target_scorers[scorer_type]
#define GET_OBSTACLE_POLICY(policy_type) SSai_behaviors.obstacle_policies[policy_type]

///Инкремент счётчика стоимости AI (см. /datum/ai_metrics); использовать только как statement
#define AI_METRIC_INC(metric_field) if(GLOB.ai_metrics) { GLOB.ai_metrics.metric_field++ }

// Статусы контроллера (порт tg 14140a6355d1 code/__DEFINES/ai/ai.dm).
// ВАЖНО: в отличие от tg, AI_STATUS_IDLE у нас - полный сон: контроллер не
// планируется, не процессится и не бродит, пока клиент не войдёт в его ячейки.
///AI активен: планирование + поведение + фоновое брождение
#define AI_STATUS_ON "ai_on"
///AI выключен: клиент/смерть/пустой z/неспособность работать
#define AI_STATUS_OFF "ai_off"
///AI спит: живой и работоспособный, но рядом нет клиентов - ноль обработки
#define AI_STATUS_IDLE "ai_idle"

///get_able_to_run(): AI не может работать
#define AI_UNABLE_TO_RUN (1<<1)
///set_ai_status(): не отменять текущие действия при выключении
#define AI_PREVENT_CANCEL_ACTIONS (1<<2)

///Дефолтный радиус "интересности" для окна пробуждения (в турфах)
#define AI_DEFAULT_INTERESTING_DIST 10

///Трейт паузы AI (PauseAi/админ-тулинг)
#define TRAIT_AI_PAUSED "ai_paused"
///Источник паузы, выставленной старым toggle_ai(AI_OFF) на controller-мобе
#define AI_PAUSED_LEGACY_TOGGLE "legacy_ai_toggle"

///Monkey checks
#define SHOULD_RESIST(source) (source.on_fire || source.buckled || HAS_TRAIT(source, TRAIT_RESTRAINED) || (source.pulledby && source.pulledby.grab_state > GRAB_PASSIVE))
#define IS_DEAD_OR_INCAP(source) (source.incapacitated() || source.stat)

//Generic BB keys
#define BB_CURRENT_MIN_MOVE_DISTANCE "min_move_distance"

///For JPS pathing, the maximum length of a path we'll try to generate. Should be modularized depending on what we're doing later on
#define AI_MAX_PATH_LENGTH 30 // 30 is possibly overkill since by default we lose interest after 14 tiles of distance, but this gives wiggle room for weaving around obstacles

///Легаси move_to_delay всю жизнь скармливался walk_to(), а его Lag измеряется
///МИРОВЫМИ ТИКАМИ (0.5дс при FPS 20), тогда как move-лупы ждут децисекунды.
///Без конверсии каждый hostile ходит вдвое медленнее легаси ("лагает на месте").
#define AI_LEGACY_MOVE_DELAY_DS(legacy_move_to_delay) (max((legacy_move_to_delay) * world.tick_lag, world.tick_lag))

///Легаси-дефолт move_to_delay: скорость погони, с которой фауна жила годами.
#define AI_PURSUIT_BASELINE_MOVE_TO_DELAY 3

///Пол задержки шага AI-погони (дс) = ровно легаси-дефолт. Хвост move_to_delay 1-2
///(10-20 тайла/с против ~4 у игрока) с событийной погоней читался как "телепорт" -
///его кламп и остаётся. А вот жёсткие 2дс (~1.25x игрока) резали и обычную фауну
///с move_to_delay 3, которая всегда бегала 1.5дс: плейтест ответил "мобы всё ещё
///умные, но не быстрые", "занерфили лаву". Теперь дефолтный моб бежит как раньше,
///а кэп ловит только тех, кто задуман быстрее дефолта. Боссы (megafauna) от кэпа
///отписаны - их скорость это дизайн. См. ai_movement_delay().
#define AI_PURSUIT_MIN_MOVE_DELAY AI_LEGACY_MOVE_DELAY_DS(AI_PURSUIT_BASELINE_MOVE_TO_DELAY)

///Потолок дальности стрельбы AI (тайлы). Экран игрока - радиус 7, а легаси
///стрелял по всему vision_range 9: жертва получала очередь от стрелка, которого
///физически не видит на экране ("меня ебашит хуйло вне моего экрана",
///"бесконечная рэнжа"). Погоня и розыск дальность не теряют - режется только огонь.
#define AI_RANGED_MAX_FIRE_RANGE 7

///Темп одиночного кайт-шага (step_away). Держится в одном месте с глайдом
///бекстепа: если анимация короче этого такта, моб рывком проскакивает тайл и
///замирает - игроки читают это как телепорт ("не успеваешь понять, на какой
///он клетке"). 0.2с давало непопадаемый зигзаг, поэтому темп остаётся 0.4с.
#define AI_KITE_STEP_CADENCE (0.4 SECONDS)

///Detour allowance added on top of the straight-line distance to a chased target when
///bounding an AI JPS/breach search radius. A failed search (target walled off) otherwise
///explores the full AI_MAX_PATH_LENGTH diamond even for a close target - the bulk of the
///pathfinding cost on open lavaland. Capping the radius to distance + this slack removes
///that waste. A successful search stops at the target, so this value costs nothing on routes
///that are found - it only sets how long a detour we accept before declaring a target
///unreachable, and only failed searches pay for the larger radius. Sized at the weave room the
///flat AI_MAX_PATH_LENGTH design granted at the edge of interest range (30 - 14), so a chase
///around a corner keeps its reach; raise it if playtesting still sees mobs give up on reachable
///prey behind cover, lower it to reclaim more of the failed-search saving.
#define AI_JPS_DETOUR_SLACK 16

///Cooldown on planning if planning failed last time

#define AI_FAILED_PLANNING_COOLDOWN 1.5 SECONDS

///Flags for ai_behavior new()
#define AI_CONTROLLER_INCOMPATIBLE (1<<0)

// Возврат perform() поведения (порт tg):
///Ничего не делать: ни кулдауна, ни завершения
#define AI_BEHAVIOR_INSTANT (NONE)
///Применить кулдаун поведения
#define AI_BEHAVIOR_DELAY (1<<0)
///Завершить поведение успехом (finish_action(TRUE) сделает контроллер)
#define AI_BEHAVIOR_SUCCEEDED (1<<1)
///Завершить поведение провалом (finish_action(FALSE) сделает контроллер)
#define AI_BEHAVIOR_FAILED (1<<2)

///Does this task require movement from the AI before it can be performed?
#define AI_BEHAVIOR_REQUIRE_MOVEMENT (1<<0)
///Требует физической досягаемости цели (CanReach), не только дистанции
#define AI_BEHAVIOR_REQUIRE_REACH (1<<1)
///Does this task let you perform the action while you move closer? (Things like moving and shooting)
#define AI_BEHAVIOR_MOVE_AND_PERFORM (1<<2)

///AI flags (ai_traits контроллера)
#define STOP_MOVING_WHEN_PULLED (1<<0)

///Subtree defines

///This subtree should cancel any further planning, (Including from other subtrees)
#define SUBTREE_RETURN_FINISH_PLANNING 1

// ===== Память и восприятие hostile AI =====

//Блэкборд-ключи контроллера hostile-моба
///Текущая цель
#define BB_AI_CURRENT_TARGET "BB_ai_current_target"
///Контейнер, в котором прячется цель (шкаф/мусорка/слипер)
#define BB_AI_TARGET_HIDING_LOCATION "BB_ai_target_hiding_location"
///Последняя ПОДТВЕРЖДЁННАЯ позиция цели (турф-улика; движение при потере LOS идёт сюда)
#define BB_AI_LAST_KNOWN_POS "BB_ai_last_known_pos"
///world.time последнего подтверждения контакта (своего или доложенного)
#define BB_AI_LAST_SEEN_TIME "BB_ai_last_seen_time"
///Кого мы преследуем по памяти: НЕ цель движения/атаки, а идентичность для
///мгновенного повторного захвата, когда моб снова УВИДИТ этот атом сам
#define BB_AI_CONTACT_TARGET "BB_ai_contact_target"
///Откуда сведения о контакте (AI_CONTACT_*)
#define BB_AI_CONTACT_SOURCE "BB_ai_contact_source"
///Последний, кто нас атаковал
#define BB_AI_LAST_ATTACKER "BB_ai_last_attacker"

//Источники сведений о контакте
///Собственное восприятие (видел сам / получил урон)
#define AI_CONTACT_PERSONAL "contact_personal"
///Доклад союзника (вой/радио/улей): точка и приметы, не GPS-маячок
#define AI_CONTACT_ALLY "contact_ally"
///Громкий звук без опознания источника
#define AI_CONTACT_NOISE "contact_noise"
///Сколько контакт считается свежим для бонуса скоринга при повторном захвате
#define AI_CONTACT_FRESH_TIME (30 SECONDS)
///Счётчик фрустрации (неудачные шаги/недостижимость)
#define BB_AI_FRUSTRATION "BB_ai_frustration"
///Домашний/охраняемый турф
#define BB_AI_HOME_TURF "BB_ai_home_turf"
///Тактическая роль контроллера в группе
#define BB_AI_PACK_ROLE "BB_ai_pack_role"
///Союзная цель, которую support-профиль сейчас обслуживает
#define BB_AI_SUPPORT_TARGET "BB_ai_support_target"
///Текущее состояние FSM (AI_STATE_*)
#define BB_AI_STATE "BB_ai_state"
///Типпас targeting strategy этого контроллера
#define BB_AI_TARGETING_STRATEGY "BB_ai_targeting_strategy"
///Типпас target scorer этого контроллера
#define BB_AI_TARGET_SCORER "BB_ai_target_scorer"
///Радиус поиска целей (задаётся профилем из vision/aggro range моба)
#define BB_AI_AGGRO_RANGE "BB_ai_aggro_range"
///Дедлайн состояния SEARCH (world.time)
#define BB_AI_SEARCH_UNTIL "BB_ai_search_until"
///Персональные обиды: атом -> world.time обиды
#define BB_AI_GRUDGE_LIST "BB_ai_grudge_list"

//Состояния FSM hostile-профилей
#define AI_STATE_IDLE "ai_state_idle"
#define AI_STATE_ALERT "ai_state_alert"
#define AI_STATE_ENGAGE "ai_state_engage"
#define AI_STATE_SEARCH "ai_state_search"
#define AI_STATE_RETREAT "ai_state_retreat"
#define AI_STATE_GUARD "ai_state_guard"

///Длительность читаемой ALERT-паузы на холодном обнаружении (моб замечает и
///разворачивается прежде чем броситься - у жертвы есть момент реакции)
#define AI_ALERT_REACTION_TIME (0.8 SECONDS)
///Сколько дополнительных точек осмотра SEARCH обходит вокруг улики
#define AI_SEARCH_INVESTIGATE_POINTS 2
///Радиус разброса точек осмотра вокруг последней подтверждённой позиции
#define AI_SEARCH_WANDER_RADIUS 3
///Текущая точка осмотра SEARCH (турф)
#define BB_AI_SEARCH_POINT "BB_ai_search_point"
///Сколько точек осмотра осталось обойти
#define BB_AI_SEARCH_POINTS_LEFT "BB_ai_search_points_left"
///Доля здоровья, ниже которой профиль уходит в RETREAT (0 = не отступает)
#define BB_AI_RETREAT_HEALTH_FRAC "BB_ai_retreat_health_frac"
///Гистерезис выхода из RETREAT: восстановиться надо выше входного порога на эту долю
#define AI_RETREAT_RECOVER_MARGIN 0.2
///world.time, до которого загнанный в угол моб дерётся вместо бегства
#define BB_AI_RETREAT_BACKOFF_UNTIL "BB_ai_retreat_backoff_until"
///Сколько загнанный в угол моб не пытается бежать снова
#define AI_RETREAT_BACKOFF_TIME (15 SECONDS)
///Турф последнего плана RETREAT (детект "бегу, но не сдвинулся")
#define BB_AI_RETREAT_LAST_POS "BB_ai_retreat_last_pos"
///Счётчик планов RETREAT без смещения
#define BB_AI_RETREAT_FAILS "BB_ai_retreat_fails"
///Столько планов бегства без сдвига разворачивают моба драться
#define AI_RETREAT_CORNERED_FRUSTRATION 3

///Сколько живёт персональная обида (после - вычищается из грид-обхода)
#define AI_GRUDGE_TIMEOUT (3 MINUTES)

///Троттл оповещения союзников об обидчике: очередь из автомата не должна
///превращать каждый импакт в новый грид-скан вокруг жертвы
#define AI_ALLY_ALERT_COOLDOWN (5 SECONDS)

///Потолок радиуса зова союзников. Легаси summon_backup ходил oview(15), то есть
///15 тайлов ПО ПРЯМОЙ ВИДИМОСТИ; грид-канал стен не знает, и 15 сквозь стены -
///это половина аванпоста ("они с другого конца ломают шлюзы и бегут").
///7 = экран: зов остаётся отрядным, а не общебазовым.
#define AI_ALLY_ALERT_RANGE 7

///Сколько моб, поднятый чужим зовом, сам не рассылает зов дальше. Без этого
///каждый прибежавший союзник открывал собственный пузырь оповещения вокруг
///себя, и волна агра шла по карте эстафетой.
#define AI_ALLY_RELAY_MUTE_TIME (30 SECONDS)
///world.time, до которого зов от этого моба подавлен (он сам пришёл по зову)
#define BB_AI_ALLY_RELAY_MUTED_UNTIL "BB_ai_ally_relay_muted_until"

///Компромиссный темп мили-атак контроллерного AI: доля от легаси-каденса NPC-пула.
///Легаси бил раз в SSnpcpool.wait (2с - "дубово, постоял-ударил"), багованный
///CLICK_CD_MELEE молотил каждые 0.8с ("имба, два карпа съедают за секунды").
///0.8 = 1.6с для rapid_melee 1; ключевое - rapid_melee 2 встаёт ровно в паритет с
///клик-кулдауном игрока (SSnpcpool.wait 20 * 0.8 / 2 = 8 = CLICK_CD_MELEE), а не
///переигрывает его (жалоба "бьют в 2 раза быстрее"). Раньше было 0.7.
#define AI_MELEE_CADENCE_SCALE 0.8

///Радиус слышимости выстрела для AI-мобов (сквозь стены). Было 9 (весь экран) -
///стрельба в одного мобa собирала всех со всего уровня сквозь стены ("сбегается
///карта"). 5 = ~полэкрана: рядом всё ещё слышат, но не с другого конца z-уровня.
#define AI_NOISE_GUNSHOT_RANGE 5
///Радиус слышимости открытия шлюза (тихо: только совсем рядом)
#define AI_NOISE_DOOR_RANGE 4
///Троттл разведки шума: одна проверка точки за это время на моба
#define AI_NOISE_INVESTIGATE_COOLDOWN (15 SECONDS)
///world.time окончания троттла разведки шума
#define BB_AI_NOISE_COOLDOWN "BB_ai_noise_cooldown"
///Окно коалесцирования шума: повторный выстрел из того же места за это время
///не сканирует грид заново (очередь из автомата = один поисковый запрос)
#define AI_NOISE_COALESCE_WINDOW (0.4 SECONDS)
///Окно коалесцирования оповещения союзников: AoE по стае = один скан, а не N
#define AI_ALLY_ALERT_COALESCE_WINDOW (2 SECONDS)

///Фрустрация пути, после которой зажатый под огнём моб предпочитает укрытие
#define AI_PINNED_FRUSTRATION 3
///Дальность ЛОС-проверки при поиске укрытия от стрелка
#define AI_HIDING_LOS_RANGE 14
///Бонус тайлу, с которого стрелка не видно (разрыв линии огня)
#define AI_HIDING_LOS_BONUS 10

///Гистерезис направления кайта: продолжение прошлого направления отступления
///получает бонус - стрейф читаемой линией вместо рваного зигзага
#define AI_RETREAT_DIR_HYSTERESIS 2
///Прошлое направление отступления (для гистерезиса кайта)
#define BB_AI_LAST_RETREAT_DIR "BB_ai_last_retreat_dir"

///Якорь мирного патруля: турф, вокруг которого моб бродит в покое
#define BB_AI_PATROL_ANCHOR "BB_ai_patrol_anchor"
///Дальше этого от якоря мирный моб не уходит - не рейдит чужие базы и руины
#define AI_PATROL_LEASH 6
///Турф, с которого была последняя попытка вернуться к якорю (детект прогресса)
#define BB_AI_PATROL_RETURN_FROM "BB_ai_patrol_return_from"
///Счётчик возвратов к якорю без прогресса
#define BB_AI_PATROL_RETURN_FAILS "BB_ai_patrol_return_fails"
///Столько безуспешных попыток дойти до якоря переносят дом на текущее место
#define AI_PATROL_RETURN_GIVE_UP 4

///Счётчик неудачных шагов прямого режима гибридного движения
#define BB_AI_DIRECT_FAILS "BB_ai_direct_fails"
///Типпас obstacle policy контроллера
#define BB_AI_OBSTACLE_POLICY "BB_ai_obstacle_policy"
///Типкэш объектов, которые МОЖНО ломать на пути (null = любые плотные)
#define BB_AI_OBSTACLE_WHITELIST "BB_ai_obstacle_whitelist"

// ===== Тактические сабтри =====

///Минимальная дистанция кайт-band рейнджера
#define BB_AI_MIN_DISTANCE "BB_ai_min_distance"
///Максимальная дистанция кайт-band рейнджера
#define BB_AI_MAX_DISTANCE "BB_ai_max_distance"
///Ближайшая позиция, освобождающая линию огня от союзников
#define BB_AI_SAFE_FIRE_POSITION "BB_ai_safe_fire_position"
///Дистанция, с которой начинается бегство
#define BB_AI_FLEE_DISTANCE "BB_ai_flee_distance"
///Флаг запрета бегства (приказ/скрипт)
#define BB_AI_STOP_FLEEING "BB_ai_stop_fleeing"
///Дефолтная дистанция бегства
#define AI_DEFAULT_FLEE_DISTANCE 9
///Дедлайн (world.time) реактивного флага "по мне стреляют"
#define BB_AI_UNDER_FIRE_UNTIL "BB_ai_under_fire_until"
///Как долго держится флаг "по мне стреляют" после попадания снаряда
#define AI_UNDER_FIRE_DURATION (4 SECONDS)
///Тайл подхода мили-моба: свободная клетка вплотную к цели (фланг/окружение)
#define BB_AI_APPROACH_TILE "BB_ai_approach_tile"
///world.time следующего перевыбора тайла подхода (анти-джиттер)
#define BB_AI_APPROACH_TILE_AT "BB_ai_approach_tile_at"
///Как часто мили-моб перевыбирает тайл подхода
#define AI_APPROACH_REPICK_COOLDOWN (1 SECONDS)
///Дальше этого виляние/окружение не планируем - просто бежим к цели
#define AI_WEAVE_MAX_DIST 7
///Максимум сородичей, координирующих окружение одной цели (кап смертоносности стаи)
#define AI_ENCIRCLE_MAX 4
///Чокпоинт (дверь/сужение), на котором сталкер караулит скрывшуюся цель (A.3)
#define BB_AI_AMBUSH_TILE "BB_ai_ambush_tile"
///Вент-вход, к которому идём
#define BB_AI_ENTRY_VENT "BB_ai_entry_vent"
///Вент-выход (тактический краул к цели)
#define BB_AI_EXIT_VENT "BB_ai_exit_vent"
///Боевая цель, возле которой должен быть выбран выход из трубы
#define BB_AI_VENT_FINAL_TARGET "BB_ai_vent_final_target"
///Гард от повторного входа в вентиляцию
#define BB_AI_CURRENTLY_VENTING "BB_ai_currently_venting"
///Кулдаун призыва подкреплений
#define BB_AI_REINFORCEMENTS_COOLDOWN "BB_ai_reinforcements_cooldown"
///Фраза при призыве подкреплений
#define BB_AI_REINFORCEMENTS_SAY "BB_ai_reinforcements_say"
///Эмоут при призыве подкреплений
#define BB_AI_REINFORCEMENTS_EMOTE "BB_ai_reinforcements_emote"
///Таргетируемая способность профиля
#define BB_AI_TARGETED_ACTION "BB_ai_targeted_action"
///Способность смены облика (ambusher)
#define BB_AI_SHAPESHIFT_ACTION "BB_ai_shapeshift_action"
///Последний увиденный контроллером легаси-режим майнбота (сбор/бой)
#define BB_AI_MINEBOT_MODE "BB_ai_minebot_mode"
///world.time следующей посадки сорняков (дела улья ксеноморфов)
#define BB_AI_NEXT_PLANT_AT "BB_ai_next_plant_at"
///world.time следующей кладки яйца (королева ксеноморфов)
#define BB_AI_NEXT_EGG_AT "BB_ai_next_egg_at"

///Радиус, в котором дальник считает окружающие угрозы для позиционирования
#define AI_THREAT_SCAN_RANGE 5
///Бонус тайла с чистой фактической линией огня до цели
#define AI_FIRE_TILE_LANE_BONUS 1000
///Бонус тайла, чья линия огня идёт через ДАЛЬНЕЕ пробиваемое укрытие (мешки/
///баррикады): стрелять можно, но неидеально - меньше чистой линии, но много
///больше нуля, чтобы стрелок предпочёл подставить под огонь укрытие, а не стену
#define AI_FIRE_TILE_COVER_LANE_BONUS 600
///Штраф за каждую угрозу вплотную (<=1 тайл) к кандидату-тайлу
#define AI_FIRE_TILE_ADJACENT_THREAT_PENALTY 40
///Штраф за своего AI-стрелка вплотную (<=1) к тайлу: разносит огневые позиции,
///чтобы два стрелка не толкались за один тайл (мал против линии огня: не гонит
///из укрытия, лишь разбивает симметрию одинаково хороших тайлов)
#define AI_FIRE_TILE_ALLY_CROWD_PENALTY 25
///Бонус за каждого плотного соседа тайла (укрытие/коридор, тяжелее окружить)
#define AI_FIRE_TILE_COVER_BONUS 3
///Радиус, в котором стрелок считает своих для разноса огневых позиций
#define AI_ALLY_SPACING_RANGE 2
///Насколько лучше должен быть новый тайл, чтобы бросить текущую позицию (анти-джиттер)
#define AI_HOLD_TOLERANCE 8

///Классификация трассы линии огня из гипотетического тайла (ranged_fire_lane_state)
///чистая линия ИЛИ только вплотную-к-стрелку укрытие (пуля гарантированно проходит)
#define AI_FIRE_LANE_CLEAR 0
///на пути только ДАЛЬНЕЕ пробиваемое укрытие: стрелять можно, но неидеально
#define AI_FIRE_LANE_COVER 1
///жёсткая геометрия/стена или союзник на линии: стрелять нельзя
#define AI_FIRE_LANE_BLOCKED 2
///Радиус поиска маршрута отхода при зажиме
#define AI_BREAK_AWAY_RANGE 6
///Сколько дальник держит огневую позицию, поджидая скрывшуюся цель
#define AI_RANGED_HOLD_TIME (12 SECONDS)
///Кэш ближних угроз (list) на один тик планирования
#define BB_AI_THREAT_CACHE "BB_ai_threat_cache"
///world.time, на который посчитан BB_AI_THREAT_CACHE
#define BB_AI_THREAT_CACHE_AT "BB_ai_threat_cache_at"
///Кэш ближних союзников (list) на один тик планирования (разнос огневых позиций)
#define BB_AI_ALLY_CACHE "BB_ai_ally_cache"
///world.time, на который посчитан BB_AI_ALLY_CACHE
#define BB_AI_ALLY_CACHE_AT "BB_ai_ally_cache_at"
///Кэш выбранного огневого/укрывающего тайла (best_reposition_tile)
#define BB_AI_COVER_CACHE "BB_ai_cover_cache"
///Ключ валидности кэша: позиции пауна/цели и параметры запроса
#define BB_AI_COVER_CACHE_KEY "BB_ai_cover_cache_key"
///world.time расчёта кэша огневого тайла
#define BB_AI_COVER_CACHE_AT "BB_ai_cover_cache_at"
///Сколько живёт кэш огневого тайла при неподвижных пауне и цели
#define AI_COVER_CACHE_TIME (1 SECONDS)
///world.time окончания удержания огневой позиции (поджидание)
#define BB_AI_HOLD_UNTIL "BB_ai_hold_until"

//Роли hostile AI. Пока это дешёвая общая семантика для координации и
//резервирования задач; профили выставляют её один раз при создании.
#define AI_ROLE_FRONTLINE "frontline"
#define AI_ROLE_TANK "tank"
#define AI_ROLE_SKIRMISHER "skirmisher"
#define AI_ROLE_HUNTER "hunter"
#define AI_ROLE_AMBUSHER "ambusher"
#define AI_ROLE_SCAVENGER "scavenger"
#define AI_ROLE_GUARD "guard"
#define AI_ROLE_SUPPORT "support"
///world.time момента взятия текущей цели (ставит find_potential_targets)
#define BB_AI_TARGET_ACQUIRED_AT "BB_ai_target_acquired_at"
///world.time следующего планового сравнения текущей цели с альтернативами
#define BB_AI_TARGET_REFRESH_AT "BB_ai_target_refresh_at"
///world.time до новой попытки взять цель после доказанно недоступного маршрута
#define BB_AI_ROUTE_RETRY_AT "BB_ai_route_retry_at"
///Цель, к которой последний прямой шаг подряд перекрывали другие мобы
#define BB_AI_MOB_BLOCKED_TARGET "BB_ai_mob_blocked_target"
///Число последовательных попыток пройти к BB_AI_MOB_BLOCKED_TARGET через моба
#define BB_AI_MOB_BLOCKED_STEPS "BB_ai_mob_blocked_steps"
///Текущая цель, для которой подтверждён затор из мобов и разрешён локальный ретаргет
#define BB_AI_CONGESTED_TARGET "BB_ai_congested_target"
///world.time конца короткого окна congestion-aware ретаргета
#define BB_AI_CONGESTED_UNTIL "BB_ai_congested_until"
///Каденс живого ретаргетинга: достаточно редкий для грида, достаточно быстрый для боя
#define AI_TARGET_REFRESH_COOLDOWN (6 SECONDS)
///Разносит массово созданных мобов по разным тикам полного LOS/score refresh.
#define AI_TARGET_REFRESH_JITTER (2 SECONDS)
///Каденс поиска, пока жив свежий контакт: реакквизиция должна быть быстрой.
#define AI_TARGET_LOST_REFRESH_COOLDOWN (2 SECONDS)
///Короткая пауза перед перестроением доказанно недоступного маршрута.
#define AI_UNREACHABLE_ROUTE_RETRY (1 SECONDS)
///Одиночный bump в движущейся толпе не должен запускать пересмотр цели.
#define AI_MOB_CONGESTION_RETRY_THRESHOLD 3
///Сколько живёт доказательство затора, пока target finder ждёт своего cadence.
#define AI_MOB_CONGESTION_MEMORY (4 SECONDS)
///Ищем только действительно близкую замену, а не меняем один дальний маршрут на другой.
#define AI_MOB_CONGESTION_RETARGET_RANGE 4
///world.time входа в текущее состояние FSM
#define BB_AI_STATE_ENTERED_AT "BB_ai_state_entered_at"
///Длительность поиска на последней известной позиции
#define BB_AI_SEARCH_TIME "BB_ai_search_time"
///Дефолтная длительность поиска
#define AI_DEFAULT_SEARCH_TIME (15 SECONDS)
///Радиус привязки охранника к дому
#define BB_AI_GUARD_LEASH "BB_ai_guard_leash"
///Таблица атак босса (list of /datum/boss_attack)
#define BB_AI_BOSS_ATTACKS "BB_ai_boss_attacks"
///Выбранная запись таблицы на исполнение
#define BB_AI_BOSS_CHOSEN_ATTACK "BB_ai_boss_chosen_attack"
///Последняя исполненная запись таблицы (анти-повтор колоды)
#define BB_AI_BOSS_LAST_ATTACK "BB_ai_boss_last_attack"
///Множитель веса только что использованной атаки в колоде (анти-повтор)
#define AI_BOSS_ANTI_REPEAT_MULT 0.3
///Закреплённая жертва сценарного сталкера (insane clown): переживает потерю
///LOS и смерть жертвы - снимается только qdel-ом атома или новым обидчиком
#define BB_AI_STALK_VICTIM "BB_ai_stalk_victim"
///Мех, которым сейчас управляет пилот-контроллер: держим отдельно от
///pawn.mecha, чтобы finish_action мог остановить мув-лупы меха даже после
///того, как смерть/выброс уже разорвали связь пилот-мех
#define BB_AI_PILOTED_MECHA "BB_ai_piloted_mecha"

// ===== AI-контроллер слаймов =====

///Текущая добыча погони слайма (зеркало Target из мозга Life, см. handle_targets)
#define BB_SLIME_TARGET "BB_slime_target"
///Радиус "вплотную", где работает решающее дерево кормёжки/атаки (легаси view(1) AIprocess)
#define SLIME_AI_FEED_RANGE 1
///Дальше этого радиуса слайм бросает погоню (легаси view(7) AIprocess)
#define SLIME_AI_PURSUIT_RANGE 7
///Добыча со здоровьем ниже этого "дожата" - слайм теряет к ней интерес (легаси AIprocess)
#define SLIME_AI_TARGET_SPENT_HEALTH -70
///Игрока со здоровьем не ниже этого слайм сперва глушит атакой, а не кормится (легаси AIprocess)
#define SLIME_AI_WARY_CLIENT_HEALTH 20
///Шанс осторожной ветки решения против стоящей цели (легаси prob(80) AIprocess)
#define SLIME_AI_STANDING_CAUTION_PROB 80
///Кулдаун атаки слайма из погони (легаси Atkcool: 45 децисекунд)
#define SLIME_AI_ATTACK_COOLDOWN (4.5 SECONDS)
///Добавка к movement_delay() на шаг погони: "примерно так же быстро, как слайм-игрок" (легаси sleep(delay + 2))
#define SLIME_AI_STEP_DELAY_SLACK (0.2 SECONDS)
///Минимальная база шага погони при неположительном movement_delay (легаси-паритет)
#define SLIME_AI_STEP_DELAY_FLOOR 1

//for songs

///song datum blackboard, set by instrument subtrees
#define BB_SONG_DATUM "BB_SONG_DATUM"

// Monkey AI controller blackboard keys

#define BB_MONKEY_AGRESSIVE "BB_monkey_agressive"
#define BB_MONKEY_GUN_NEURONS_ACTIVATED "BB_monkey_gun_aware"
#define BB_MONKEY_GUN_WORKED "BB_monkey_gun_worked"
#define BB_MONKEY_BEST_FORCE_FOUND "BB_monkey_bestforcefound"
#define BB_MONKEY_ENEMIES "BB_monkey_enemies"
#define BB_MONKEY_BLACKLISTITEMS "BB_monkey_blacklistitems"
#define BB_MONKEY_PICKUPTARGET "BB_monkey_pickuptarget"
#define BB_MONKEY_PICKPOCKETING "BB_monkey_pickpocketing"
#define BB_MONKEY_CURRENT_ATTACK_TARGET "BB_monkey_current_attack_target"
#define BB_MONKEY_CURRENT_GIVE_TARGET "BB_monkey_current_give_target"
#define BB_MONKEY_TARGET_DISPOSAL "BB_monkey_target_disposal"
#define BB_MONKEY_DISPOSING "BB_monkey_disposing"
#define BB_MONKEY_RECRUIT_COOLDOWN "BB_monkey_recruit_cooldown"
#define BB_MONKEY_NEXT_HUNGRY "BB_monkey_next_hungry"


///Haunted item controller defines

///Chance for haunted item to haunt someone
#define HAUNTED_ITEM_ATTACK_HAUNT_CHANCE 10
///Chance for haunted item to try to get itself let go.
#define HAUNTED_ITEM_ESCAPE_GRASP_CHANCE 20
///Chance for haunted item to warp somewhere new
#define HAUNTED_ITEM_TELEPORT_CHANCE 4
///Amount of aggro you get when picking up a haunted item
#define HAUNTED_ITEM_AGGRO_ADDITION 2

///Blackboard keys for haunted items
#define BB_TO_HAUNT_LIST "BB_to_haunt_list"
///Actual mob the item is haunting at the moment
#define BB_HAUNT_TARGET "BB_haunt_target"
///Amount of successful hits in a row this item has had
#define BB_HAUNTED_THROW_ATTEMPT_COUNT "BB_haunted_throw_attempt_count"

///Cursed item controller defines

//defines
///how far a cursed item will still try to chase a target
#define CURSED_VIEW_RANGE 7
#define CURSED_ITEM_TELEPORT_CHANCE 4
//blackboards

///Actual mob the item is haunting at the moment
#define BB_CURSE_TARGET "BB_haunt_target"
///Where the item wants to land on
#define BB_TARGET_SLOT "BB_target_slot"
///Amount of successful hits in a row this item has had
#define BB_CURSED_THROW_ATTEMPT_COUNT "BB_cursed_throw_attempt_count"

///Mob the MOD is trying to attach to
#define BB_MOD_TARGET "BB_mod_target"
///The implant the AI was created from
#define BB_MOD_IMPLANT "BB_mod_implant"
///Range for a MOD AI controller.
#define MOD_AI_RANGE 200

///Vending machine AI controller blackboard keys
#define BB_VENDING_CURRENT_TARGET "BB_vending_current_target"
#define BB_VENDING_TILT_COOLDOWN "BB_vending_tilt_cooldown"
#define BB_VENDING_UNTILT_COOLDOWN "BB_vending_untilt_cooldown"
#define BB_VENDING_BUSY_TILTING "BB_vending_busy_tilting"
#define BB_VENDING_LAST_HIT_SUCCESFUL "BB_vending_last_hit_succesful"

///Robot customer AI controller blackboard keys
#define BB_CUSTOMER_CURRENT_ORDER "BB_customer_current_order"
#define BB_CUSTOMER_MY_SEAT "BB_customer_my_seat"
#define BB_CUSTOMER_PATIENCE "BB_customer_patience"
#define BB_CUSTOMER_CUSTOMERINFO "BB_customer_customerinfo"
#define BB_CUSTOMER_EATING "BB_customer_eating"
#define BB_CUSTOMER_ATTENDING_VENUE "BB_customer_attending_avenue"
#define BB_CUSTOMER_LEAVING "BB_customer_leaving"
#define BB_CUSTOMER_CURRENT_TARGET "BB_customer_current_target"
/// Robot customer has said their can't find seat line at least once. Used to rate limit how often they'll complain after the first time.
#define BB_CUSTOMER_SAID_CANT_FIND_SEAT_LINE "BB_customer_said_cant_find_seat_line"


///Hostile AI controller blackboard keys
#define BB_HOSTILE_ORDER_MODE "BB_HOSTILE_ORDER_MODE"
#define BB_HOSTILE_FRIEND "BB_HOSTILE_FRIEND"
#define BB_HOSTILE_ATTACK_WORD "BB_HOSTILE_ATTACK_WORD"

/// Basically, what is our vision/hearing range.
#define BB_HOSTILE_VISION_RANGE 10
/// After either being given a verbal order or a pointing order, ignore further of each for this duration
#define AI_HOSTILE_COMMAND_COOLDOWN 2 SECONDS

// hostile command modes (what pointing at something/someone does depending on the last order the carp heard)
/// Don't do anything (will still react to stuff around them though)
#define HOSTILE_COMMAND_NONE 0
/// Will attack a target.
#define HOSTILE_COMMAND_ATTACK 1
/// Will follow a target.
#define HOSTILE_COMMAND_FOLLOW 2

///Dog AI controller blackboard keys

#define BB_SIMPLE_CARRY_ITEM "BB_SIMPLE_CARRY_ITEM"
#define BB_FETCH_TARGET "BB_FETCH_TARGET"
#define BB_FETCH_IGNORE_LIST "BB_FETCH_IGNORE_LISTlist"
#define BB_FETCH_DELIVER_TO "BB_FETCH_DELIVER_TO"
#define BB_DOG_FRIENDS "BB_DOG_FRIENDS"
#define BB_DOG_ORDER_MODE "BB_DOG_ORDER_MODE"
#define BB_DOG_PLAYING_DEAD "BB_DOG_PLAYING_DEAD"
#define BB_DOG_HARASS_TARGET "BB_DOG_HARASS_TARGET"

/// Basically, what is our vision/hearing range for picking up on things to fetch/
#define AI_DOG_VISION_RANGE	10
/// What are the odds someone petting us will become our friend?
#define AI_DOG_PET_FRIEND_PROB 15
/// After this long without having fetched something, we clear our ignore list
#define AI_FETCH_IGNORE_DURATION 30 SECONDS
/// After being ordered to heel, we spend this long chilling out
#define AI_DOG_HEEL_DURATION 20 SECONDS
/// After either being given a verbal order or a pointing order, ignore further of each for this duration
#define AI_DOG_COMMAND_COOLDOWN	2 SECONDS

// dog command modes (what pointing at something/someone does depending on the last order the dog heard)
/// Don't do anything (will still react to stuff around them though)
#define DOG_COMMAND_NONE 0
/// Will try to pick up and bring back whatever you point to
#define DOG_COMMAND_FETCH 1
/// Will get within a few tiles of whatever you point at and continually growl/bark. If the target is a living mob who gets too close, the dog will attack them with bites
#define DOG_COMMAND_ATTACK 2

//enumerators for parsing command speech
#define COMMAND_HEEL "Heel"
#define COMMAND_FETCH "Fetch"
#define COMMAND_FOLLOW "Follow"
#define COMMAND_STOP "Stop"
#define COMMAND_ATTACK "Attack"
#define COMMAND_DIE "Play Dead"
