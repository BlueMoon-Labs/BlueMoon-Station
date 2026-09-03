// Профили hostile AI: именованные наборы сабтри + тюнинг.
// Порядок planning_subtrees = порядок планирования: поиск целей -> FSM ->
// (тактика) -> преодоление препятствий -> атака. Назначение профиля мобу -
// select_ai_profile() в hostile.dm (авто-таблица по легаси-флагам) либо
// явный ai_profile_type на сабтипе.

///Обычное преследование и милишная атака
/datum/ai_controller/hostile_adapter/melee_chaser
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/hostile_dodge,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Для сабтипов с техническим retaliate-родителем, но агрессивным legacy Found().
/datum/ai_controller/hostile_adapter/melee_chaser/aggressive_retaliate/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy

///Разгон, телеграф, попытка прижать цель + обычный милишный добив
/datum/ai_controller/hostile_adapter/brute_charger
	ai_pack_role = AI_ROLE_TANK
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/hostile_charge,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Стрельба в движении с удержанием min/max дистанции; если реального пути
///отхода вплотную нет, стрелок защищается в мили. Поджидание скрывшейся цели
///(covering hold) планирует SEARCH-состояние hostile_fsm.
/datum/ai_controller/hostile_adapter/ranged_skirmisher
	ai_pack_role = AI_ROLE_SKIRMISHER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Стрелок без кайта: жмёт дистанцию, стреляет на ходу, добивает в милишке
/datum/ai_controller/hostile_adapter/ranged_chaser
	ai_pack_role = AI_ROLE_SKIRMISHER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Стайный охотник: делится агро с сородичами.
///
///Мили-хвост обязателен: цель движения мили-пауну ставит только hostile_melee, а без него
///стая агрилась, звала сородичей и стояла на месте, кусая лишь того, кто сам подошёл вплотную.
///Прод-раунд 9832: миграция из ~38 карпов дала 7 атак за смену против 79 у одного кота-хирурга,
///а мегакарп 54 минуты эмоутил "gnashes at" с одной клетки рядом с членом экипажа.
/datum/ai_controller/hostile_adapter/pack_hunter
	ai_pack_role = AI_ROLE_HUNTER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/call_reinforcements,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away/adaptive,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee/melee_only,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Засадчик: смена облика/ожидание, взрыв активности по созревшей цели.
///На шум не расчехляется - его сила в неподвижной маскировке.
/datum/ai_controller/hostile_adapter/ambusher
	ai_pack_role = AI_ROLE_AMBUSHER
	investigates_noise = FALSE
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/shapechange_ambush,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Закрытый crate-мимик, как и раньше, замечает только того, кто подошёл
///вплотную. После trigger() его обычная дальность восстанавливается.
/datum/ai_controller/hostile_adapter/ambusher/mimic/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	if(istype(new_pawn, /mob/living/simple_animal/hostile/mimic/crate))
		blackboard[BB_AI_AGGRO_RANGE] = 1

///Неподвижный захватчик (тентакли): вкопан на месте - никакого преследования,
///поиска и брождения, бьёт/хватает только то, что стоит вплотную; цель на
///дистанции просто пережидается. Движение дополнительно заперто хуком
///can_ai_controller_move() пауна.
/datum/ai_controller/hostile_adapter/stationary_grappler
	ai_pack_role = AI_ROLE_AMBUSHER
	investigates_noise = FALSE
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_melee_stationary,
	)

///Динамически скопированные мимики могут стать стрелками уже после Initialize.
///Один профиль поэтому проверяет runtime ranged-флаг, но для обычных копий
///остаётся простым мили-охотником.
/datum/ai_controller/hostile_adapter/adaptive_hunter
	ai_pack_role = AI_ROLE_AMBUSHER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away/adaptive,
		// Тот же мили-хвост, что у pack_hunter: комментарий выше обещает "простого мили-охотника"
		// для обычных копий, но без этих сабтри цель движения им не ставилась вовсе, и
		// анимированные предметы не преследовали жертву. Гейт melee_only оставляет
		// скопировавшим дальнобойность мимикам их ranged-ветку.
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee/melee_only,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Трус/падальщик: ест слабых, при просевшем здоровье уходит в RETREAT
///(гистерезис и разворот при зажиме - в hostile_fsm)
/datum/ai_controller/hostile_adapter/coward_scavenger
	ai_pack_role = AI_ROLE_SCAVENGER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

/datum/ai_controller/hostile_adapter/coward_scavenger/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGET_SCORER] = /datum/target_scorer/prefer_vulnerable
	blackboard[BB_AI_RETREAT_HEALTH_FRAC] = 0.4

///Голдграб: падальщик руды. Руду ищет штатным find_potential_targets
///(search_objects/wanted_objects-путь) и ест милишным делегатом, а любую
///живую цель пугается и убегает (сабтри flee_target/goldgrub, легаси-испуг
///GiveTarget с Burrow-таймером сохраняется зеркалированием цели).
/datum/ai_controller/hostile_adapter/coward_scavenger/goldgrub
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/flee_target/goldgrub,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

/datum/ai_controller/hostile_adapter/coward_scavenger/goldgrub/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	//страх голдграба типовой, не по здоровью: живая цель ВСЕГДА обращает в
	//бегство, поэтому health-гейт RETREAT-фазы кауарда ему не нужен
	blackboard -= BB_AI_RETREAT_HEALTH_FRAC
	//легаси retreat_distance = 10: докуда убегаем от живых
	blackboard[BB_AI_FLEE_DISTANCE] = 10

///Охранник: держит территорию, leash к дому
/datum/ai_controller/hostile_adapter/guard_defender
	ai_pack_role = AI_ROLE_GUARD
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

/datum/ai_controller/hostile_adapter/guard_defender/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	var/turf/home = get_turf(new_pawn)
	if(home)
		set_blackboard_key(BB_AI_HOME_TURF, home)

///Honour guard - территориальный охранник, но не retaliate-пацифист.
/datum/ai_controller/hostile_adapter/guard_defender/aggressive_retaliate/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy

///Поддержка: приоритет - способность по цели, потом милишка
/datum/ai_controller/hostile_adapter/support
	ai_pack_role = AI_ROLE_SUPPORT
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/targeted_mob_ability,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Мелкий венткраулер: дальнюю цель обходит через связанную сеть, рядом дерётся обычно.
/datum/ai_controller/hostile_adapter/vent_hunter
	ai_pack_role = AI_ROLE_HUNTER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/opportunistic_ventcrawler,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Artificer сначала резервирует и чинит одного раненого союзного конструкта,
///а при отсутствии работы использует обычный defensive combat-план.
/datum/ai_controller/hostile_adapter/support/artificer
	planning_subtrees = list(
		/datum/ai_planning_subtree/support_repair_construct,
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/flee_target,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Curseblob: снаряд проклятия с закреплённой жертвой. Целей не ищет (жертва
///задаётся спавном через set_target/GiveTarget и незаменима), не спит (жертва
///может убежать за окно интересности, а живёт блоб всё равно 60 секунд),
///движется собственным телепорт-циклом через сабтри-делегат.
/datum/ai_controller/hostile_adapter/curseblob
	can_idle = FALSE
	planning_subtrees = list(
		/datum/ai_planning_subtree/curseblob_pursuit,
	)

/datum/ai_controller/hostile_adapter/curseblob/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/curseblob_victim

///AI-сварнеры лавалендского маяка. Боевой контур штатной машиной (диззаблер
///базы через делегацию OpenFire); лавовые катвоки и бросок из пропасти живут
///в легаси-Move override пауна, поэтому опасные турфы обязаны быть
///проходимыми - легаси walk_to свободно шёл в лаву, а Move сам стелил катвок.
/datum/ai_controller/hostile_adapter/swarmer
	cross_dangerous_turfs = TRUE
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Ресурсник: фуражирский цикл (починка/репликация/постройки/поедание
///объектов) при отсутствии живой угрозы; стрельба только по живым -
///его OpenFire гейтит неживое.
/datum/ai_controller/hostile_adapter/swarmer/resource
	ai_pack_role = AI_ROLE_SCAVENGER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/ranged_skirmish/living_only,
		/datum/ai_planning_subtree/swarmer_forage,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Боевой стрелок роя: кайт-band из легаси retreat/minimum_distance (3..5)
/datum/ai_controller/hostile_adapter/swarmer/skirmisher
	ai_pack_role = AI_ROLE_SKIRMISHER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Мили-боец роя: электрошок/телепорт-диспёрс живут в его AttackingTarget
/datum/ai_controller/hostile_adapter/swarmer/brawler
	ai_pack_role = AI_ROLE_HUNTER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Floor cluwne: сценарный призрак-сталкер. Жертву назначает собственный
///сценарий (Acquire_Victim/Kill), фазы/явления/утаскивание ведёт его Life() -
///контроллер лишь ведёт пауна к жертве, пока тот не явлен (легаси-гейт Goto
///переехал в can_ai_controller_move). Целей не ищет (жертва закреплена) и не
///спит: жертва может быть в другом конце станции, а сценарий обязан идти.
/datum/ai_controller/hostile_adapter/floor_cluwne
	can_idle = FALSE
	planning_subtrees = list(
		/datum/ai_planning_subtree/floor_cluwne_stalk,
	)

/datum/ai_controller/hostile_adapter/floor_cluwne/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/floor_cluwne_victim

///Пилот меха: FSM пилотирования сабтри-делегатом (curseblob-паттерн).
///Вне меха - обычный мили-пехотинец штатной машины (угон свободного меха
///через CanAttack/AttackingTarget-делегацию плюс легаси-скан
///ai_seek_stolen_mecha). В мехе паун живёт внутри объекта: штатный мувер
///шаги запрещает (loc - не турф), а его собственный Moved не стреляет, и
///окно интересности не переезжает за мехом - поэтому can_idle = FALSE
///(будить уснувшего было бы некому). Движение в мехе - мув-лупы самого
///меха, фазы (дым/щит/отступление/эвакуация) - легаси-прок
///ai_operate_mecha_phase, атаки - делегация MeleeAction/OpenFire.
/datum/ai_controller/hostile_adapter/mecha_pilot
	can_idle = FALSE
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/mecha_pilot_fsm,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/pack_encircle,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

///Escape-иллюзия: приманка, уводящая погоню от кастера. Спавнится с
///GiveTarget(владелец) - закрепление зеркалируется в блэкборд, дальше
///штатный finder может перехватить на видимого преследователя. Не дерётся
///вовсе (её AttackingTarget = FALSE), поэтому профиль без милишки и FSM:
///только удержание цели и бегство до легаси-кольца retreat_distance = 10;
///дальше кольца приманка стоит и дразнит погоню.
/datum/ai_controller/hostile_adapter/decoy_escape
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/flee_target/illusion_decoy,
	)

/datum/ai_controller/hostile_adapter/decoy_escape/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	//легаси-кольцо бегства из retreat_distance приманки (10)
	var/mob/living/simple_animal/hostile/decoy_pawn = new_pawn
	if(!isnull(decoy_pawn.retreat_distance))
		blackboard[BB_AI_FLEE_DISTANCE] = decoy_pawn.retreat_distance

///Боссовый профиль: мегафауна и элитки. Без таблицы способностей дальний
///OpenFire сохраняется отдельным legacy-сабтри; снос окружения -
///каденсом destroy_surroundings; peaceful/enemies-механика через
///megafauna-стратегию; лава не преграда.
/datum/ai_controller/hostile_adapter/boss
	ai_pack_role = AI_ROLE_TANK
	can_idle = FALSE //боссы не спят: их арены и так далеко от рутинного трафика
	cross_dangerous_turfs = TRUE
	//Босс не бросает погоню: она и есть содержание боя, а убежать от него
	//полагается разрывом линии и ареной, а не выносливостью.
	pursuit_leashed = FALSE
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/boss_ability_selection,
		/datum/ai_planning_subtree/boss_legacy_ranged,
		/datum/ai_planning_subtree/destroy_surroundings,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)

/datum/ai_controller/hostile_adapter/boss/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	//peaceful/enemies-гейт modular_sand действует на всю мегафауну
	if(istype(new_pawn, /mob/living/simple_animal/hostile/megafauna))
		blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/ignore_sight/megafauna
	//таблица способностей: ситуативный селектор вместо rand()-цепочек OpenFire;
	//без таблицы босс стреляет по-старому из AttackingTarget
	var/mob/living/simple_animal/hostile/boss_pawn = new_pawn
	var/list/attack_table = boss_pawn.build_ai_attack_table()
	if(length(attack_table))
		blackboard[BB_AI_BOSS_ATTACKS] = attack_table
		boss_pawn.ai_attack_tables_active = TRUE
