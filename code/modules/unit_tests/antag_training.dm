/datum/unit_test/proc/allocate_training_session(program_type = /datum/antag_training_program/heretic, datum/preferences/selected_preferences)
	for(var/code in GLOB.antag_training_arenas.Copy())
		var/datum/antag_training_arena/closing = GLOB.antag_training_arenas[code]
		if(closing?.finished)
			wait_for_qdeleted(closing, 1 MINUTES)
	var/datum/antag_training_session/session = new(program_type, selected_preferences)
	allocated += session
	return session

/// Своя кукла сохраняет внешность при входе, смене роли и восстановлении, а выход возвращает прежнего призрака.
/datum/unit_test/antag_training_character_appearance/Run()
	var/datum/preferences/preferences = new
	allocated += preferences
	preferences.pref_species = new /datum/species/lizard
	preferences.real_name = "Training Appearance"
	preferences.gender = FEMALE
	preferences.hair_style = "Ponytail"
	preferences.hair_color = "aabbcc"
	preferences.features["mcolor"] = "123456"
	preferences.features["body_size"] = 0.8
	preferences.modified_limbs = list(BODY_ZONE_R_ARM = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic"), BODY_ZONE_L_LEG = list(LOADOUT_LIMB_AMPUTATED))
	preferences.persistent_tattoos = TRUE
	var/tattoo_text = "Учебная татуировка"
	var/mob/living/carbon/human/tattoo_source = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/tattoo_head = tattoo_source.get_bodypart(BODY_ZONE_HEAD)
	tattoo_head.tattoo_text = tattoo_text
	preferences.tattoos_string = tattoo_source.format_tattoos()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free, preferences)
	TEST_ASSERT(session.prepare(), "Полигон создаёт выбранную куклу.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	observer.real_name = "Original Observer"
	observer.can_reenter_corpse = FALSE
	TEST_ASSERT(session.connect(observer), "Призрак входит своей куклой.")
	for(var/stage in list("Вход", "Смена роли", "Восстановление"))
		if(stage == "Смена роли")
			TEST_ASSERT(session.restart(/datum/antag_training_program/heretic), "Смена роли создаёт новую куклу.")
			TEST_ASSERT(IS_HERETIC(session.avatar), "Выбранная кукла получает учебную роль.")
		else if(stage == "Восстановление")
			session.avatar.forceMove(session.arena.zones["melee"]["spawn"])
			session.avatar.death()
			deltimer(session.recovery_timer)
			session.recover()
			TEST_ASSERT_EQUAL(session.avatar.stat, CONSCIOUS, "Кукла восстанавливается после смерти.")
		TEST_ASSERT_EQUAL(session.avatar.real_name, preferences.real_name, "[stage]: имя куклы не заменяется именем призрака.")
		TEST_ASSERT_EQUAL(session.avatar_mind.name, preferences.real_name, "[stage]: разум получает имя куклы.")
		TEST_ASSERT_EQUAL(session.avatar.dna.species.type, /datum/species/lizard, "[stage]: сохраняется раса.")
		TEST_ASSERT_EQUAL(session.avatar.gender, FEMALE, "[stage]: сохраняется пол.")
		TEST_ASSERT_EQUAL(session.avatar.hair_style, preferences.hair_style, "[stage]: сохраняется причёска.")
		TEST_ASSERT_EQUAL(session.avatar.hair_color, preferences.hair_color, "[stage]: сохраняется цвет волос.")
		TEST_ASSERT_EQUAL(session.avatar.dna.features["mcolor"], preferences.features["mcolor"], "[stage]: сохраняется цвет тела.")
		TEST_ASSERT_EQUAL(session.avatar.dna.features["body_size"], preferences.features["body_size"], "[stage]: сохраняется размер тела.")
		var/obj/item/bodypart/arm = session.avatar.get_bodypart(BODY_ZONE_R_ARM)
		TEST_ASSERT(arm?.is_robotic_limb(FALSE), "[stage]: сохраняется протез.")
		TEST_ASSERT_NULL(session.avatar.get_bodypart(BODY_ZONE_L_LEG), "[stage]: сохраняется выбранная ампутация.")
		var/obj/item/bodypart/head = session.avatar.get_bodypart(BODY_ZONE_HEAD)
		TEST_ASSERT_EQUAL(head.tattoo_text, tattoo_text, "[stage]: сохраняется татуировка.")
		TEST_ASSERT(istype(session.avatar.w_uniform, /obj/item/clothing/under/color/grey), "[stage]: кукла получает учебную форму.")
	var/mob/dead/observer/returned = session.finish()
	allocated += returned
	TEST_ASSERT_EQUAL(returned.real_name, "Original Observer", "Выход возвращает прежнее имя призрака.")
	TEST_ASSERT(!returned.can_reenter_corpse, "Своя кукла не снимает запрет возвращения в тело.")
	TEST_ASSERT(!QDELETED(preferences), "Завершение сеанса не удаляет настройки игрока.")

/// Квота подсистемы не блокирует отложенную работу при свободном бюджете тика.
/datum/unit_test/antag_training_work_budget/Run()
	var/datum/antag_training_arena/arena = allocate(/datum/antag_training_arena)
	stoplag()
	var/old_limit = Master.current_ticklimit
	var/old_work_tick = GLOB.antag_training_work_tick
	var/old_work_usage = GLOB.antag_training_work_usage
	GLOB.antag_training_work_tick = world.time
	GLOB.antag_training_work_usage = TICK_USAGE_REAL
	Master.current_ticklimit = -1
	var/start_time = world.time
	arena.yield_work()
	Master.current_ticklimit = old_limit
	GLOB.antag_training_work_tick = old_work_tick
	GLOB.antag_training_work_usage = old_work_usage
	TEST_ASSERT_EQUAL(world.time, start_time, "Остаток квоты MC не откладывает работу на следующий тик.")

/// Вход через призрака сохраняет исходный разум, ограничения и точку возвращения.
/datum/unit_test/antag_training_lifecycle/Run()
	var/mob/living/carbon/human/original = allocate(/mob/living/carbon/human)
	original.mind_initialize()
	allocated += original.mind
	var/datum/mind/original_mind = original.mind
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left, original)
	observer.can_reenter_corpse = FALSE
	observer.started_as_observer = FALSE
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/space_level/level = arena.private_level
	var/area/antag_training/practice_room = arena.room
	var/datum/mind/training_mind = session.avatar_mind
	var/obj/item/pen/item = new(arena.entry_turf)
	TEST_ASSERT(!(SEND_SIGNAL(session.current_body, COMSIG_MOB_PRE_PLAYER_CHANGE, session.current_body, observer) & COMPONENT_STOP_MIND_TRANSFER), "Призрак может получить управление своим учебным персонажем.")
	TEST_ASSERT(session.connect(observer), "Призрак входит в отдельного персонажа.")
	TEST_ASSERT_EQUAL(session.current_body.real_name, observer.real_name, "Учебная кукла сохраняет имя призрака.")
	TEST_ASSERT_EQUAL(session.avatar.dna.species.type, /datum/species/human, "Без своих настроек создаётся стандартная кукла.")
	TEST_ASSERT_EQUAL(original.mind, original_mind, "Исходный разум остаётся у персонажа раунда.")
	TEST_ASSERT(!IS_HERETIC(original), "Учебная роль не принадлежит исходному персонажу.")
	var/mob/dead/observer/returned = session.finish()
	allocated += returned
	TEST_ASSERT_EQUAL(returned.mind, original_mind, "Выход сохраняет ссылку на исходный разум.")
	TEST_ASSERT(!returned.can_reenter_corpse && !returned.started_as_observer, "Нельзя обойти запрет возвращения в тело.")
	TEST_ASSERT_EQUAL(get_turf(returned), run_loc_floor_bottom_left, "Возвращается прежняя точка наблюдения.")
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Очистка полигона завершается.")
	TEST_ASSERT(QDELETED(session) && QDELETED(arena) && QDELETED(training_mind) && QDELETED(item), "Выход последнего удаляет полигон и его содержимое.")
	TEST_ASSERT_EQUAL(GLOB.antag_training_rooms[level], practice_room, "Область сохраняется в ограниченном пуле своего уровня.")
	TEST_ASSERT(!practice_room.arena && !length(practice_room.contents), "Свободная область не держит сеанс или клетки карты.")
	TEST_ASSERT(level in GLOB.antag_training_free_levels, "Освободившийся z-уровень используется повторно.")
	TEST_ASSERT_EQUAL(original.mind, original_mind, "Очистка не меняет исходный разум.")

/// Вещи, существа и разумы не пересекают границы полигона даже через nullspace.
/datum/unit_test/antag_training_containment/Run()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/target = arena.spawn_target()
	var/obj/item/pen/item = new(arena.entry_turf)
	var/obj/item/storage/backpack/container = new(arena.entry_turf)
	var/obj/item/pen/nested = new(container)
	target.forceMove(run_loc_floor_bottom_left)
	item.forceMove(run_loc_floor_bottom_left)
	session.avatar.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(get_area(target), arena.room, "Манекен остаётся внутри.")
	TEST_ASSERT_EQUAL(get_area(item), arena.room, "Предмет остаётся внутри.")
	TEST_ASSERT_EQUAL(get_area(session.avatar), arena.room, "Участник остаётся внутри.")
	container.moveToNullspace()
	var/obj/item/pen/late_nested = new(null)
	late_nested.loc = container
	late_nested.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(get_turf(late_nested), "Новый предмет в изолированном контейнере наследует границу даже в nullspace.")
	TEST_ASSERT_EQUAL(late_nested.training_origin, container.training_origin, "Отложенная привязка наследуется от контейнера.")
	nested.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(get_turf(nested), "Содержимое контейнера не выходит из nullspace на станцию.")
	item.moveToNullspace()
	item.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(item.loc, "Предмет не выходит из nullspace на станцию.")
	TEST_ASSERT(item.forceMove(arena.entry_turf), "Возвращение внутрь разрешено.")
	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human)
	outsider.mind_initialize()
	allocated += outsider.mind
	outsider.forceMove(arena.entry_turf)
	TEST_ASSERT_EQUAL(get_turf(outsider), run_loc_floor_bottom_left, "Посторонний не входит телепортом.")
	session.avatar_mind.transfer_to(outsider)
	TEST_ASSERT_EQUAL(session.avatar_mind.current, session.avatar, "Учебный разум не переносится на станцию.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer)
	TEST_ASSERT(isobserver(observer), "Фикстура должна быть наблюдателем.")
	TEST_ASSERT(get_area(observer) != arena.room, "Призрак создан вне полигона.")
	TEST_ASSERT_EQUAL(arena.room.arena, arena, "Комната сохраняет своего владельца.")
	TEST_ASSERT(GLOB.antag_training_arenas[arena.code] == arena, "Полигон зарегистрирован до последнего выхода.")
	TEST_ASSERT(observer.training_move_allowed(arena.entry_turf), "Призрак может наблюдать за тренировкой.")
	observer.forceMove(arena.entry_turf)
	TEST_ASSERT_EQUAL(get_area(observer), arena.room, "Наблюдатель находится внутри.")
	TEST_ASSERT_NULL(observer.training_origin, "Наблюдение не привязывает призрака к полигону.")
	observer.abstract_move(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(get_turf(observer), run_loc_floor_bottom_left, "Призрак свободно покидает полигон.")
	observer.ManualFollow(session.current_body)
	TEST_ASSERT_EQUAL(get_area(observer), arena.room, "Следование за участником доступно.")
	var/mob/camera/camera = allocate(/mob/camera)
	camera.forceMove(arena.entry_turf)
	TEST_ASSERT(get_area(camera) != arena.room, "Удалённая камера не входит на полигон.")
	var/mob/dead/observer/inside_observer = allocate(/mob/dead/observer, arena.entry_turf)
	TEST_ASSERT_EQUAL(get_area(inside_observer), arena.room, "Наблюдателя можно создать внутри полигона.")
	TEST_ASSERT(!(arena.room.area_flags & NOTELEPORT), "Внутренние телепорты разрешены.")
	TEST_ASSERT(arena.room.area_flags & RADIO_BLACKOUT, "Радио изолировано.")
	TEST_ASSERT(!SSmapping.level_trait(arena.private_level.z_value, ZTRAIT_RESERVED), "Чужие резервирования не используют тренировочный z.")
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(arena, 10 SECONDS), "Очистка полигона завершается.")
	TEST_ASSERT(!QDELETED(observer) && !QDELETED(inside_observer), "Очистка не удаляет наблюдателей.")
	TEST_ASSERT(get_area(inside_observer) != arena.room, "После закрытия наблюдатель возвращается на станцию.")
	TEST_ASSERT(QDELETED(container) && QDELETED(nested) && QDELETED(late_nested), "Очистка находит содержимое в nullspace.")

/// Вход без кода использует общий полигон, личная смена роли не затрагивает других.
/datum/unit_test/antag_training_multiplayer/Run()
	var/initial_teams = length(GLOB.antagonist_teams)
	var/datum/antag_training_session/first = allocate_training_session()
	TEST_ASSERT(first.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(), "Второй участник входит без кода.")
	var/datum/antag_training_arena/shared = first.arena
	TEST_ASSERT_EQUAL(second.arena, shared, "Участники используют один полигон.")
	var/mob/living/second_body = second.current_body
	first.restart(/datum/antag_training_program/free)
	TEST_ASSERT_EQUAL(second.current_body, second_body, "Смена роли сохраняет другого участника.")
	TEST_ASSERT(!IS_HERETIC(first.current_body), "Смена программы снимает прежнюю роль.")
	qdel(first)
	TEST_ASSERT(!QDELETED(shared) && !QDELETED(second_body), "Выход одного сохраняет общую тренировку.")
	qdel(second)
	TEST_ASSERT(wait_for_qdeleted(shared, 10 SECONDS), "Последний выход удаляет полигон.")
	TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), initial_teams, "Учебные роли не создают общие команды раунда.")

/// Выдача ограничена каталогом и квотами, а сброс затрагивает только выбранный сектор.
/datum/unit_test/antag_training_tools/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	TEST_ASSERT_NULL(arena.spawn_creature("unknown", "pve"), "Произвольные типы запрещены.")
	TEST_ASSERT_NULL(arena.spawn_creature("human", "hub"), "В центре нельзя создавать цели.")
	TEST_ASSERT(!session.issue_equipment("/obj/item/gun", session.current_body), "Выдача принимает только ключ каталога.")
	for(var/item_id in GLOB.antag_training_equipment)
		session.next_supply_at = 0
		TEST_ASSERT(session.issue_equipment(item_id, session.current_body), "Выдаётся [item_id].")
	var/obj/item/pen/kept = new(arena.zones["laboratory"]["spawn"])
	var/obj/item/pen/removed = new(arena.zones["pve"]["spawn"])
	session.current_body.forceMove(arena.zones["pve"]["spawn"])
	TEST_ASSERT(!(session.current_body.status_flags & GODMODE), "В боевом секторе нет защиты центра.")
	for(var/creature_id in GLOB.antag_training_creatures)
		TEST_ASSERT(arena.spawn_creature(creature_id, "pve"), "Создаётся [creature_id].")
	for(var/index in length(arena.targets) to 11)
		arena.spawn_target()
	TEST_ASSERT_NULL(arena.spawn_target(), "Квота целей не превышается.")
	TEST_ASSERT(arena.reset_zone("pve"), "Сектор сбрасывается.")
	TEST_ASSERT_EQUAL(get_turf(session.current_body), arena.entry_turf, "Перед сбросом участник выходит в центр.")
	TEST_ASSERT(session.current_body.status_flags & GODMODE, "Центр защищает участника.")
	TEST_ASSERT(QDELETED(removed) && !QDELETED(kept), "Очистка не трогает соседний сектор.")

/// Смерть восстанавливает участника, а удаление тела завершает сеанс без потери наблюдателя.
/datum/unit_test/antag_training_recovery/Run()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer)
	TEST_ASSERT(session.connect(observer), "Призрак подключается.")
	session.current_body.forceMove(session.arena.zones["melee"]["spawn"])
	session.current_body.death()
	TEST_ASSERT_EQUAL(session.defeats, 1, "Смерть учитывается в тренировочном счётчике.")
	deltimer(session.recovery_timer)
	session.recover()
	TEST_ASSERT_EQUAL(session.current_body.stat, CONSCIOUS, "Участник восстанавливается.")
	TEST_ASSERT_EQUAL(get_turf(session.current_body), session.arena.entry_turf, "Восстановление происходит в центре.")
	session.auto_recover = FALSE
	session.current_body.forceMove(session.arena.zones["melee"]["spawn"])
	session.current_body.death()
	TEST_ASSERT_NULL(session.recovery_timer, "Для экспериментов с телом можно отключить автовосстановление.")
	TEST_ASSERT(session.can_control(session.current_body), "Пульт остаётся доступен после смерти.")
	session.heal_self()
	TEST_ASSERT_EQUAL(session.current_body.stat, CONSCIOUS, "Ручное восстановление доступно после смерти.")
	var/mob/living/body = session.current_body
	qdel(body)
	TEST_ASSERT(session.finished, "Удаление тела завершает сеанс.")
	TEST_ASSERT(wait_for_qdeleted(session), "После удаления тела освобождается сеанс.")

/// Все пути проходят исследование и вознесение без изменения общей угрозы станции.
/datum/unit_test/antag_training_all_paths/Run()
	var/old_warning = GLOB.heretic_threat_warning_until
	for(var/path_id in GLOB.heretic_paths)
		var/datum/antag_training_session/session = allocate_training_session()
		TEST_ASSERT(session.prepare(), "Полигон пути [path_id] должен подготовиться.")
		var/datum/antagonist/heretic/heretic = IS_HERETIC(session.avatar)
		TEST_ASSERT(heretic.simulated && !heretic.show_in_roundend && heretic.soft_antag, "Учебная роль исключена из итогов и активных антагонистов.")
		TEST_ASSERT(!(heretic.owner in GLOB.reality_smash_track.targets), "Тренировка не создаёт станционные разломы.")
		TEST_ASSERT_EQUAL(length(heretic.objectives), 0, "Учебной роли не нужны раундовые задания.")
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[1], session.avatar), "Путь [path_id] доступен через обычное исследование.")
		session.program.handle_choice(session, session.avatar, "Подготовить вознесение")
		TEST_ASSERT_EQUAL(heretic.path_stage, length(path.knowledge), "Все ступени [path_id] должны изучаться.")
		var/datum/eldritch_knowledge/final_eldritch/final_knowledge = heretic.get_knowledge(path.knowledge[length(path.knowledge)])
		var/list/bodies = list()
		for(var/index in 1 to HERETIC_ASCENSION_BODIES)
			bodies += session.arena.spawn_target(dead = TRUE)
		var/obj/effect/eldritch/big/rune = new(session.arena.entry_turf)
		TEST_ASSERT(final_knowledge.begin_ascension_ritual(session.avatar, rune), "Учебный обряд [path_id] запускается без станционного ожидания.")
		TEST_ASSERT(final_knowledge.on_finished_recipe(session.avatar, bodies, session.arena.entry_turf), "Вознесение [path_id] завершается.")
		TEST_ASSERT(heretic.ascended && final_knowledge.simulated, "Вознесение остаётся учебным.")
		TEST_ASSERT_EQUAL(heretic.threat(), 0, "Изученные знания не повышают угрозу учебной роли.")
		TEST_ASSERT_EQUAL(GLOB.heretic_threat_warning_until, old_warning, "Путь [path_id] не меняет общую угрозу.")
		var/datum/antag_training_arena/arena = session.arena
		allocated -= session
		qdel(session)
		TEST_ASSERT(wait_for_qdeleted(arena, 10 SECONDS), "Очистка после вознесения завершается.")

/// Манекен становится целью от касания сердцем, а живое учебное подношение выдаёт обычную награду без отправки манекена на станцию.
/datum/unit_test/antag_training_hunt/Run()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.avatar
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user)
	var/mob/living/carbon/human/victim = session.arena.spawn_target()
	victim.forceMove(session.arena.entry_turf)
	victim.Paralyze(10 SECONDS)
	var/obj/item/living_heart/heart = new(session.arena.entry_turf)
	heart.bind(user.mind)
	heart.attack(victim, user)
	TEST_ASSERT_EQUAL(heretic.hunt_target, victim.mind, "Касание сердцем делает обездвиженный манекен целью.")
	var/obj/effect/eldritch/big/rune = new(session.arena.entry_turf)
	var/list/selected = list(victim, heart)
	TEST_ASSERT(rune.reserve_atoms(selected), "Руна резервирует учебную цель и сердце.")
	rune.ritual_user = user
	var/old_points = heretic.knowledge_points
	TEST_ASSERT(heretic.complete_hunt_ritual(user, selected, session.arena.entry_turf), "Учебное подношение должно засчитаться.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Подношение увеличивает число душ.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, old_points + HERETIC_LIVE_SACRIFICE_KNOWLEDGE, "Живая цель даёт обычную награду.")
	TEST_ASSERT_EQUAL(get_area(victim), session.arena.room, "Манекен остаётся внутри тренировки.")
	TEST_ASSERT(!heretic.hunt_target_available(victim.mind), "Одну учебную душу нельзя сдать повторно.")
	TEST_ASSERT(!(victim.mind in GLOB.heretic_sacrificed_minds), "Учебная душа не попадает в общий список подношений.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[victim.mind], "Для манекена не создаётся отдельный Мансус.")
	rune.release_atoms()

/// Созданный ритуалом учебный слуга получает хозяина без ожидания игрока.
/datum/unit_test/antag_training_summon/Run()
	var/objectives_before = length(GLOB.objectives)
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antagonist/heretic/heretic = IS_HERETIC(session.avatar)
	var/datum/eldritch_knowledge/summon/raw_prophet/ritual = allocate(/datum/eldritch_knowledge/summon/raw_prophet)
	heretic.researched_knowledge[ritual.type] = ritual
	TEST_ASSERT(ritual.on_finished_recipe(session.avatar, list(), session.arena.entry_turf), "Учебный призыв должен завершаться сразу.")
	TEST_ASSERT_EQUAL(length(ritual.flesh_servants), 1, "Слуга учитывается в обычном лимите свиты.")
	var/datum/antagonist/heretic_monster/servant = ritual.flesh_servants[1]
	TEST_ASSERT_EQUAL(servant.master, heretic, "Учебный слуга связан с хозяином.")
	TEST_ASSERT(!servant.show_in_roundend && servant.soft_antag, "Учебный слуга не влияет на итоги раунда.")
	TEST_ASSERT_EQUAL(length(servant.objectives), 0, "Учебный слуга не создаёт раундовые цели.")
	TEST_ASSERT_EQUAL(length(GLOB.objectives), objectives_before, "Призыв не меняет глобальный список целей.")
	var/servant_mind_ref = text_ref(servant.owner)
	var/datum/antag_training_arena/arena = session.arena
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(arena, 10 SECONDS), "Полигон со слугой очищается.")
	sleep(1 SECONDS)
	var/datum/mind/remaining_mind = locate(servant_mind_ref)
	TEST_ASSERT(!remaining_mind || !QDELING(remaining_mind), "Разум удалённого слуги освобождается без hard delete.")

/// Рабочие места дают девять разных ключей и позволяют завершить дело Духа Хваткой Мансуса.
/datum/unit_test/antag_training_deed/Run()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antagonist/heretic/heretic = IS_HERETIC(session.avatar)
	heretic.research_knowledge(/datum/eldritch_knowledge/base_spirit, session.avatar)
	var/datum/eldritch_knowledge/base_spirit/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/list/keys = list()
	for(var/column in list(5, 11, 17))
		for(var/row in list(33, 39, 45))
			var/turf/tile = locate(column, row, session.arena.private_level.z_value)
			var/obj/structure/bed/bed = locate() in tile
			TEST_ASSERT(bed, "На каждом рабочем месте есть кровать.")
			session.avatar.forceMove(get_step(tile, NORTH))
			keys |= heretic.deed_key_for(bed)
			if(!heretic.deed.complete())
				COOLDOWN_RESET(heretic.deed, progress_cooldown)
				TEST_ASSERT(knowledge.on_mansus_grasp(bed, session.avatar, TRUE), "Кровать рабочего места засчитывается обычным действием.")
	TEST_ASSERT_EQUAL(length(keys), 9, "Все рабочие места имеют разные ключи.")
	TEST_ASSERT(heretic.deed.complete(), "Лаборатория позволяет завершить все ступени дела.")

/// Замеряет перемещения станции и заполненный полигон с шестью участниками.
/datum/unit_test/antag_training_performance/Run()
	var/obj/item/pen/probe = allocate(/obj/item/pen)
	var/turf/first = run_loc_floor_bottom_left
	var/turf/second = get_step(first, NORTH)
	measure_moves(probe, first, second, "empty")
	var/start_time = REALTIMEOFDAY
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	log_test("TRAINING BENCH cold prepare: [(REALTIMEOFDAY - start_time) * 100] ms")
	var/datum/antag_training_arena/arena = session.arena
	for(var/index in 2 to 6)
		var/datum/antag_training_session/guest = allocate_training_session(/datum/antag_training_program/free)
		TEST_ASSERT(guest.prepare(arena), "Полигон вмещает всех участников.")
	for(var/index in 1 to ANTAG_TRAINING_TARGET_LIMIT)
		TEST_ASSERT(arena.spawn_creature("gunner", "pve", TRUE), "Создаётся активный противник.")
	for(var/index in 1 to ANTAG_TRAINING_SUPPLY_LIMIT)
		TEST_ASSERT(arena.issue_item(/obj/item/gun/energy/laser, arena.entry_turf), "Выдаётся оружие.")
	measure_moves(probe, first, second, "populated")
	for(var/pass in 1 to 3)
		var/start_usage = TICK_USAGE_REAL
		for(var/index in 1 to 100)
			session.ui_data(session.current_body)
		log_test("TRAINING BENCH ui x100 pass [pass]: [round(TICK_USAGE_TO_MS(start_usage), 0.01)] ms")
		stoplag()
	log_test("TRAINING BENCH populated atoms: [length(arena.created_atoms)]")
	start_time = REALTIMEOFDAY
	TEST_ASSERT(arena.reset_zone("pve"), "Сектор сбрасывается под нагрузкой.")
	log_test("TRAINING BENCH reset: [(REALTIMEOFDAY - start_time) * 100] ms")
	start_time = REALTIMEOFDAY
	for(var/datum/antag_training_session/member as anything in arena.members.Copy())
		qdel(member)
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Комната освобождается после последнего участника.")
	log_test("TRAINING BENCH cleanup: [(REALTIMEOFDAY - start_time) * 100] ms")
	start_time = REALTIMEOFDAY
	var/datum/antag_training_session/reused = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(reused.prepare(), "Освобождённый полигон можно использовать повторно.")
	log_test("TRAINING BENCH warm prepare: [(REALTIMEOFDAY - start_time) * 100] ms")

/datum/unit_test/antag_training_performance/proc/measure_moves(obj/item/probe, turf/first, turf/second, label)
	for(var/pass in 1 to 5)
		stoplag()
		var/start_usage = TICK_USAGE_REAL
		for(var/index in 1 to 1000)
			probe.forceMove(first)
			probe.forceMove(second)
		log_test("TRAINING BENCH [label] forceMove x2000 pass [pass]: [round(TICK_USAGE_TO_MS(start_usage), 0.01)] ms")
		stoplag()
		start_usage = TICK_USAGE_REAL
		for(var/index in 1 to 1000)
			probe.Move(first)
			probe.Move(second)
		log_test("TRAINING BENCH [label] Move x2000 pass [pass]: [round(TICK_USAGE_TO_MS(start_usage), 0.01)] ms")

/// Восьмой участник входит в ту же комнату без создания дополнительного уровня.
/datum/unit_test/antag_training_capacity/Run()
	var/initial_z = world.maxz
	var/datum/antag_training_session/host = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(host.prepare(), "Полигон должен подготовиться.")
	for(var/index in 2 to 8)
		var/datum/antag_training_session/guest = allocate_training_session(/datum/antag_training_program/free)
		TEST_ASSERT(guest.prepare(host.arena), "Вход участника [index] доступен.")
	var/datum/antag_training_session/opponent = host.arena.members[2]
	host.current_body.forceMove(host.arena.zones["melee"]["spawn"])
	opponent.current_body.forceMove(get_step(host.current_body, NORTH))
	var/health_before = opponent.current_body.health
	opponent.current_body.apply_damage(20, BRUTE)
	TEST_ASSERT(opponent.current_body.health < health_before, "Участник в боевом секторе получает настоящий урон.")
	TEST_ASSERT_EQUAL(host.current_body.health, host.current_body.maxHealth, "Урон сопернику не задевает другого участника.")
	TEST_ASSERT_EQUAL(length(host.arena.members), 8, "Полигон принимает больше шести участников.")
	TEST_ASSERT_EQUAL(length(GLOB.antag_training_arenas), 1, "Все участники используют единственную комнату.")
	TEST_ASSERT_EQUAL(world.maxz, initial_z, "Входы используют подготовленные уровни без расширения карты раунда.")

/// Учебные цели исключены из населения, угрозы, глобальных смертей и удалённых проклятий.
/datum/unit_test/antag_training_station_isolation
	var/death_signals = 0
	var/mob/living/watched_body
	var/list/added_players = list()

/datum/unit_test/antag_training_station_isolation/Run()
	var/datum/director_signals/before = allocate(/datum/director_signals)
	before.update()
	var/before_players = living_player_count()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/target = session.arena.spawn_target()
	target.mind.assigned_role = "Captain"
	GLOB.player_list |= target
	added_players += target
	target.add_to_current_living_players()
	target.add_to_current_living_antags()
	target.add_to_current_dead_players()
	TEST_ASSERT_EQUAL(living_player_count(), before_players, "Учебный персонаж не занимает место населения станции.")
	TEST_ASSERT(!is_effective_crew_mob(target), "Учебная должность не считается экипажем.")
	for(var/player_group in SSticker.mode.current_players)
		TEST_ASSERT(!(target in SSticker.mode.current_players[player_group]), "Учебная цель не попадает в кэш игроков режима.")
	var/datum/director_signals/after = allocate(/datum/director_signals)
	after.update()
	TEST_ASSERT_EQUAL(after.living_antags, before.living_antags, "Еретик и манекены не увеличивают число антагонистов директора.")
	var/mob/living/carbon/human/station_target = allocate(/mob/living/carbon/human)
	GLOB.player_list |= station_target
	added_players += station_target
	TEST_ASSERT_EQUAL(living_player_count(), before_players + 1, "Обычный живой игрок по-прежнему учитывается.")
	var/datum/eldritch_knowledge/curse/curse = allocate(/datum/eldritch_knowledge/curse)
	TEST_ASSERT(curse.can_target(session.current_body, target), "Проклятие работает внутри общей площадки.")
	TEST_ASSERT(!curse.can_target(session.current_body, station_target), "Проклятие не затрагивает станцию.")
	TEST_ASSERT(!curse.can_target(station_target, target), "Проклятие станции не затрагивает полигон.")
	watched_body = target
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_global_death))
	target.death()
	TEST_ASSERT_EQUAL(death_signals, 0, "Учебная смерть не вызывает глобальный сигнал раунда.")
	watched_body = station_target
	station_target.death()
	TEST_ASSERT_EQUAL(death_signals, 1, "Обычная смерть по-прежнему вызывает глобальный сигнал.")
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)

/datum/unit_test/antag_training_station_isolation/proc/on_global_death(datum/source, mob/living/victim)
	SIGNAL_HANDLER
	if(victim == watched_body)
		death_signals++

/datum/unit_test/antag_training_station_isolation/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	GLOB.player_list -= added_players
	added_players.Cut()
	watched_body = null
	return ..()

/// Во время поэтапного сброса участники не могут войти в очищаемый сектор или выдать предметы.
/datum/unit_test/antag_training_reset_lock/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	arena.resetting = TRUE
	arena.reset_zone_id = "pve"
	session.current_body.forceMove(arena.zones["pve"]["spawn"])
	var/turf/locked_position = get_turf(session.current_body)
	var/mob/living/spawned = arena.spawn_creature("human", "pve")
	var/obj/item/issued = arena.issue_item(/obj/item/pen, arena.entry_turf)
	var/can_control = session.can_control(session.current_body)
	var/list/data = session.ui_data(session.current_body)
	arena.resetting = FALSE
	arena.reset_zone_id = null
	TEST_ASSERT_EQUAL(locked_position, arena.entry_turf, "Вход в очищаемый сектор закрыт.")
	TEST_ASSERT_NULL(spawned, "Спавн во время сброса заблокирован.")
	TEST_ASSERT_NULL(issued, "Выдача во время сброса заблокирована.")
	TEST_ASSERT(can_control, "Пульт и выход остаются доступны.")
	TEST_ASSERT(data["busy"], "Пульт показывает восстановление сектора.")
	session.current_body.forceMove(arena.zones["pve"]["spawn"])
	TEST_ASSERT_EQUAL(get_turf(session.current_body), arena.zones["pve"]["spawn"], "После восстановления вход снова доступен.")

/// ИИ с клиентским каналом грида действительно атакует шестерых участников, оставаясь в комнате.
/datum/unit_test/antag_training_live_ai
	var/list/fake_players = list()
	var/training_z

/datum/unit_test/antag_training_live_ai/Run()
	var/datum/antag_training_session/host = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(host.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = host.arena
	training_z = arena.private_level.z_value
	for(var/index in 2 to 6)
		var/datum/antag_training_session/member = allocate_training_session(/datum/antag_training_program/free)
		TEST_ASSERT(member.prepare(arena), "Создаётся участник [index].")
	for(var/datum/antag_training_session/member as anything in arena.members)
		member.auto_recover = FALSE
		member.current_body.forceMove(locate(45, 42, training_z))
		fake_players += member.current_body
		SSmobs.clients_by_zlevel[training_z] |= member.current_body
		member.current_body.enable_client_mobs_in_contents()
	for(var/index in 1 to ANTAG_TRAINING_TARGET_LIMIT)
		var/mob/living/simple_animal/hostile/target = arena.spawn_creature("gunner", "pve", TRUE)
		TEST_ASSERT(target?.ai_controller, "Активный противник получает контроллер ИИ.")
		target.ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, fake_players[((index - 1) % length(fake_players)) + 1])
		target.ai_controller.set_ai_status(AI_STATUS_ON)
	var/start_time = world.time
	sleep(10 SECONDS)
	var/hurt = 0
	for(var/mob/living/player as anything in fake_players)
		if(player.health < player.maxHealth)
			hurt++
		TEST_ASSERT_EQUAL(get_area(player), arena.room, "Участник остаётся в своём полигоне после боя.")
	TEST_ASSERT(hurt > 0, "Противники наносят реальный урон, а не спят на пустом z.")
	arena.prune_targets()
	for(var/mob/living/target as anything in arena.targets)
		TEST_ASSERT_EQUAL(get_area(target), arena.room, "Активные противники не выходят с полигона.")
	log_test("TRAINING LOAD: [length(fake_players)] participants, [length(arena.targets)] active NPCs, [hurt] damaged participants in [(world.time - start_time) / 10] seconds")

/datum/unit_test/antag_training_live_ai/Destroy()
	if(training_z)
		SSmobs.clients_by_zlevel[training_z] -= fake_players
	for(var/mob/living/player as anything in fake_players)
		player.clear_important_client_contents()
	fake_players.Cut()
	return ..()

/// Общий сброс требует единогласия и отменяется при изменении состава или истечении времени.
/datum/unit_test/antag_training_shared_reset/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(first.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(), "Второй участник входит на полигон.")
	var/datum/antag_training_arena/shared = first.arena
	var/obj/item/pen/experiment = new(shared.zones["pve"]["spawn"])
	TEST_ASSERT(shared.request_reset(first, "pve"), "Участник запрашивает сброс.")
	TEST_ASSERT(!QDELETED(experiment) && !shared.resetting, "Одного голоса недостаточно.")
	TEST_ASSERT(shared.approve_reset(first), "Повторный голос не заменяет второго участника.")
	TEST_ASSERT(!QDELETED(experiment), "Повторный голос не запускает сброс.")
	shared.cancel_reset()
	TEST_ASSERT_NULL(shared.pending_reset_zone, "Возражение отменяет предложение.")
	shared.next_reset_request_at = 0
	TEST_ASSERT(shared.request_reset(first, "pve"), "Можно запросить новый сброс.")
	var/datum/antag_training_session/third = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(third.prepare(), "Новый участник входит во время обсуждения.")
	TEST_ASSERT_NULL(shared.pending_reset_zone, "Вход отменяет прежнее голосование.")
	shared.next_reset_request_at = 0
	TEST_ASSERT(shared.request_reset(first, "pve"), "Новое предложение учитывает всех троих.")
	shared.reset_vote_deadline = world.time
	TEST_ASSERT(!shared.approve_reset(second), "Просроченное предложение не принимает голоса.")
	shared.cancel_reset()
	shared.next_reset_request_at = 0
	TEST_ASSERT(shared.request_reset(first, "all"), "Начинается итоговое голосование о полном сбросе.")
	TEST_ASSERT(shared.approve_reset(second), "Второй участник согласился.")
	TEST_ASSERT(!QDELETED(experiment), "Третий участник ещё не согласился.")
	qdel(third)
	var/deadline = world.time + 30 SECONDS
	while(shared.resetting && world.time < deadline)
		stoplag()
	TEST_ASSERT(QDELETED(experiment), "После выхода последнего несогласовавшего все оставшиеся согласны, сектор очищается.")
	TEST_ASSERT_NULL(shared.pending_reset_zone, "Завершённое голосование освобождает ссылки.")
	TEST_ASSERT(!QDELETED(first.current_body) && !QDELETED(second.current_body), "Полный сброс сохраняет участников.")

/// Личная очистка сохраняет других игроков, их цели и одолженные предметы.
/datum/unit_test/antag_training_personal_cleanup/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(first.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(), "Второй участник входит.")
	var/datum/antag_training_arena/shared = first.arena
	var/obj/item/owned = shared.issue_item(/obj/item/pen, shared.entry_turf, creator = first)
	var/obj/item/borrowed = shared.issue_item(/obj/item/pen, shared.entry_turf, creator = first)
	borrowed.forceMove(second.current_body)
	var/obj/item/foreign = shared.issue_item(/obj/item/pen, shared.entry_turf, creator = second)
	var/obj/item/storage/box/container = shared.issue_item(/obj/item/storage/box, shared.entry_turf, creator = first)
	foreign.forceMove(container)
	var/mob/living/owned_target = shared.spawn_creature("human", "pve", creator = first)
	var/mob/living/foreign_target = shared.spawn_creature("human", "pve", creator = second)
	TEST_ASSERT(!first.can_manage_target(foreign_target), "Чужую цель нельзя удалить пультом.")
	TEST_ASSERT(first.can_manage_target(owned_target), "Своей целью можно управлять.")
	TEST_ASSERT(first.clear_personal_entities(), "Личная очистка завершается.")
	TEST_ASSERT(QDELETED(owned) && QDELETED(owned_target), "Свои предмет и цель удаляются.")
	TEST_ASSERT(!QDELETED(borrowed) && !QDELETED(foreign) && !QDELETED(container) && !QDELETED(foreign_target), "Одолженный предмет, чужая цель и контейнер с чужим предметом сохраняются.")
	TEST_ASSERT(!QDELETED(first.current_body) && !QDELETED(second.current_body), "Оба персонажа сохраняются.")
	second.avatar_mind.transfer_to(foreign_target)
	TEST_ASSERT(!second.can_manage_target(foreign_target), "После переноса разума цель становится участником и защищена от пульта.")
	TEST_ASSERT(second.clear_personal_entities(), "Очистка после смены тела завершается.")
	TEST_ASSERT(!QDELETED(foreign_target), "Личная очистка не удаляет действующее тело участника.")

/// Выход очищает оставленное имущество, а одолженные вещи переходят оставшемуся участнику.
/datum/unit_test/antag_training_departure/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(first.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(), "Второй участник входит.")
	var/datum/antag_training_arena/shared = first.arena
	first.avatar_mind.transfer_to(second.current_body)
	TEST_ASSERT_EQUAL(first.current_body.mind, first.avatar_mind, "Прямой захват занятого тела не лишает игрока собственного персонажа.")
	TEST_ASSERT_EQUAL(second.current_body.mind, second.avatar_mind, "Второй игрок сохраняет управление.")
	var/obj/item/left_item = shared.issue_item(/obj/item/pen, shared.entry_turf, creator = first)
	var/obj/item/borrowed = shared.issue_item(/obj/item/pen, shared.entry_turf, creator = first)
	borrowed.forceMove(second.current_body)
	var/mob/living/left_target = shared.spawn_creature("human", "pve", creator = first)
	var/mob/living/other_target = shared.spawn_creature("human", "pve", creator = second)
	first.disconnected_at = world.time - ANTAG_TRAINING_DISCONNECT_GRACE - 1
	first.process()
	TEST_ASSERT(QDELETED(first), "Истёкший таймер отключения завершает сеанс.")
	var/deadline = world.time + 10 SECONDS
	while((!QDELETED(left_item) || !QDELETED(left_target)) && world.time < deadline)
		stoplag()
	TEST_ASSERT(QDELETED(left_item) && QDELETED(left_target), "Оставленные предметы и NPC удаляются после выхода.")
	TEST_ASSERT(!QDELETED(borrowed) && !QDELETED(other_target) && !QDELETED(second.current_body), "Чужая тренировка и одолженная вещь сохраняются.")
	TEST_ASSERT_EQUAL(borrowed.training_owner?.resolve(), second, "Одолженная вещь получает нового владельца для последующей очистки.")
	TEST_ASSERT_EQUAL(length(shared.members), 1, "Вышедший участник удаляется из состава.")

/// Очистка учебных тел не создаёт brainmob и не обращается к удалённым навыкам.
/datum/unit_test/antag_training_mind_cleanup/Run()
	var/datum/skill_modifier/modifier = GLOB.skill_modifiers[/datum/skill_modifier/brain_damage] || new /datum/skill_modifier/brain_damage(null, TRUE)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/body = session.current_body
	var/obj/item/organ/brain/brain = body.getorganslot(ORGAN_SLOT_BRAIN)
	var/datum/mind/soul = body.mind
	soul.add_skill_modifier(modifier.identifier)
	var/start_usage = TICK_USAGE_REAL
	qdel(session)
	log_test("TRAINING BENCH mind cleanup: [round(TICK_USAGE_TO_MS(start_usage), 0.01)] ms")
	TEST_ASSERT(QDELETED(body) && QDELETED(soul) && QDELETED(brain), "Тело, разум и мозг удаляются при выходе.")
	TEST_ASSERT_NULL(body.mind, "Учебное тело отпускает удалённый разум.")
	TEST_ASSERT_NULL(brain.brainmob, "Очистка не создаёт нового моба внутри удаляемого мозга.")

/// Мастерская создаёт только каталог, учитывает лимиты и сохраняет изоляцию объектов.
/datum/unit_test/antag_training_workshop/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/user = session.current_body
	TEST_ASSERT_NULL(session.build_structure("table", user), "В центре установка запрещена.")
	user.forceMove(arena.zones["melee"]["spawn"])
	user.setDir(NORTH)
	TEST_ASSERT_NULL(session.build_structure("/obj/machinery/nuclearbomb", user), "Произвольный тип не принимается.")
	var/turf/destination = get_step(user, NORTH)
	var/obj/structure/chair/obstacle = new(destination)
	TEST_ASSERT_NULL(session.build_structure("table", user), "Занятая клетка не застраивается.")
	qdel(obstacle)
	for(var/structure_id in GLOB.antag_training_structures)
		session.next_supply_at = 0
		var/obj/placed = session.build_structure(structure_id, user)
		TEST_ASSERT(placed, "Создаётся [structure_id].")
		TEST_ASSERT_EQUAL(get_turf(placed), destination, "Объект ставится перед участником.")
		TEST_ASSERT_EQUAL(placed.training_owner?.resolve(), session, "Объект принадлежит создателю.")
		TEST_ASSERT_EQUAL(placed.training_origin?.resolve(), arena, "Объект привязан к полигону.")
		TEST_ASSERT(!placed.forceMove(run_loc_floor_bottom_left), "Объект не выходит на станцию.")
		TEST_ASSERT_EQUAL(arena.supply_count, 1, "Установка занимает место в общем лимите.")
		qdel(placed)
		// Шкаф с шансом 1% получает хэллоуинскую ловушку и при удалении выпускает моба на эту клетку.
		for(var/mob/living/trap_mob in destination)
			qdel(trap_mob)
		arena.prune_supplies()
		TEST_ASSERT_EQUAL(length(arena.placed_structures), 0, "Удаление освобождает лимит мастерской.")
		TEST_ASSERT_EQUAL(arena.supply_count, 0, "Удаление освобождает общий лимит.")
	for(var/index in 1 to ANTAG_TRAINING_STRUCTURE_LIMIT)
		session.next_supply_at = 0
		var/obj/placed = session.build_structure("chair", user)
		TEST_ASSERT(placed, "Создаются объекты в пределах квоты.")
		placed.moveToNullspace()
	session.next_supply_at = 0
	TEST_ASSERT_NULL(session.build_structure("chair", user), "Превышение квоты отклоняется сервером.")
	TEST_ASSERT(session.clear_personal_entities(), "Личная очистка завершена.")
	TEST_ASSERT_EQUAL(length(arena.placed_structures), 0, "Личная очистка находит объекты в nullspace.")
	TEST_ASSERT(session.build_structure("chair", user), "После очистки доступна новая установка.")
	TEST_ASSERT_NULL(session.build_structure("table", user), "Быстрая повторная выдача ограничена.")
	session.next_supply_at = 0
	arena.resetting = TRUE
	var/obj/during_reset = session.build_structure("table", user)
	arena.resetting = FALSE
	TEST_ASSERT_NULL(during_reset, "Во время сброса установка запрещена.")

/// Личная очистка не удаляет созданную мебель, пока на ней сидит другой участник.
/datum/unit_test/antag_training_occupied_furniture/Run()
	var/datum/antag_training_session/creator = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(creator.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_session/guest = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(guest.prepare(), "Второй участник входит.")
	creator.current_body.forceMove(creator.arena.zones["melee"]["spawn"])
	creator.current_body.setDir(NORTH)
	var/obj/structure/chair/chair = creator.build_structure("chair", creator.current_body)
	TEST_ASSERT(chair, "Создан стул.")
	guest.current_body.forceMove(get_turf(chair))
	TEST_ASSERT(chair.buckle_mob(guest.current_body), "Гость садится на стул.")
	TEST_ASSERT(creator.clear_personal_entities(), "Личная очистка завершена.")
	TEST_ASSERT(!QDELETED(chair), "Занятый стул сохраняется.")
	chair.unbuckle_mob(guest.current_body)
	TEST_ASSERT(creator.clear_personal_entities(), "Повторная очистка завершена.")
	TEST_ASSERT(QDELETED(chair), "Свободный стул удаляется.")

/// Повреждения задаются своей живой учебной цели и не затрагивают участников.
/datum/unit_test/antag_training_patient/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_session/guest = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(guest.prepare(), "Второй участник входит.")
	var/mob/living/target = session.arena.spawn_creature("human", "laboratory", creator = session)
	TEST_ASSERT(target, "Создан пациент.")
	target.adjustStaminaLoss(30)
	var/list/data = session.ui_data(session.current_body)
	var/list/target_data = data["targets"][1]
	TEST_ASSERT_EQUAL(target_data["stamina"], target.getStaminaLoss(), "Пульт показывает фактический урон выносливости человека.")
	var/mob/living/operative = session.arena.spawn_creature("operative", "pve", creator = session)
	TEST_ASSERT(operative, "Создан оперативник для сравнения.")
	data = session.ui_data(session.current_body)
	target_data = data["targets"][2]
	TEST_ASSERT_NULL(target_data["stamina"], "Отсутствие выносливости у оперативника не показывается как нулевой урон.")
	TEST_ASSERT(!guest.injure_target(target, "brute"), "Другой участник не меняет чужую цель.")
	TEST_ASSERT(!session.injure_target(target, "unknown"), "Неизвестный вид повреждения отклоняется.")
	TEST_ASSERT(!session.injure_target(session.current_body, "brute"), "Свой персонаж не становится пациентом пульта.")
	for(var/injury_id in GLOB.antag_training_injuries)
		target.revive(full_heal = TRUE, admin_revive = TRUE)
		var/list/injury = GLOB.antag_training_injuries[injury_id]
		TEST_ASSERT(session.injure_target(target, injury_id), "Применяется [injury_id].")
		TEST_ASSERT_EQUAL(target.get_damage_amount(injury["type"]), injury["amount"], "Количество урона совпадает с описанием.")
	target.death()
	TEST_ASSERT(!session.injure_target(target, "burn"), "Мёртвую цель сначала нужно восстановить.")
	target.revive(full_heal = TRUE, admin_revive = TRUE)
	guest.avatar_mind.transfer_to(target)
	TEST_ASSERT(!session.injure_target(target, "burn"), "После переноса разума участник защищён от подготовки пациента.")

/// После строительства и сброса в каждом секторе сохраняется пригодный для дыхания воздух.
/datum/unit_test/antag_training_air/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	for(var/zone_id in arena.zones)
		var/turf/open/tile = arena.zones[zone_id]["spawn"]
		TEST_ASSERT(tile.air.return_pressure() >= ONE_ATMOSPHERE * 0.8, "В секторе [zone_id] есть воздух после строительства.")
	sleep(5 SECONDS)
	for(var/zone_id in arena.zones)
		var/turf/open/tile = arena.zones[zone_id]["spawn"]
		TEST_ASSERT(tile.air.return_pressure() >= ONE_ATMOSPHERE * 0.8, "В секторе [zone_id] воздух не уходит в космос.")
	var/turf/open/laboratory = arena.zones["laboratory"]["spawn"]
	laboratory.air.clear()
	TEST_ASSERT(arena.reset_zone("laboratory"), "Сектор сбрасывается.")
	TEST_ASSERT(laboratory.air.return_pressure() >= ONE_ATMOSPHERE * 0.8, "Сброс восстанавливает воздух сектора.")

/// Учебная выдача на всех путях сохраняет владельца, ограничения реликвий и изоляцию.
/datum/unit_test/antag_training_recipe_results/Run()
	var/datum/antag_training_session/anchor = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(anchor.prepare(), "Полигон подготовлен.")
	var/old_warning = GLOB.heretic_threat_warning_until
	for(var/path_id in GLOB.heretic_paths)
		var/datum/antag_training_session/session = allocate_training_session()
		TEST_ASSERT(session.prepare(anchor.arena), "Участник входит на общий полигон.")
		TEST_ASSERT(session.prepare_path(path_id, 9), "Подготовлен путь [path_id].")
		var/datum/antagonist/heretic/heretic = IS_HERETIC(session.current_body)
		TEST_ASSERT_EQUAL(heretic.path_stage, 9, "Открыты девять ступеней [path_id].")
		TEST_ASSERT(!heretic.ascended, "Подготовка не возносит персонажа.")
		for(var/knowledge_type in heretic.researched_knowledge)
			var/datum/eldritch_knowledge/recipe = heretic.researched_knowledge[knowledge_type]
			if(!length(recipe.result_atoms))
				continue
			session.next_supply_at = 0
			TEST_ASSERT(session.issue_recipe(recipe), "Выдан результат [recipe.name].")
			var/datum/weakref/item_ref = session.arena.issued_items[length(session.arena.issued_items)]
			var/obj/item/item = item_ref.resolve()
			TEST_ASSERT(item, "Выдача учтена в общем лимите.")
			TEST_ASSERT_EQUAL(item.training_owner?.resolve(), session, "Выдача принадлежит сеансу.")
			item.forceMove(run_loc_floor_bottom_left)
			TEST_ASSERT_EQUAL(get_area(item), session.arena.room, "Предмет не покидает полигон.")
			if(istype(item, /obj/item/heretic_path_relic))
				var/obj/item/heretic_path_relic/relic = item
				TEST_ASSERT_EQUAL(relic.creator?.resolve(), session.avatar_mind, "Реликвия привязана к разуму.")
				TEST_ASSERT_EQUAL(relic.knowledge_ref?.resolve(), recipe, "Реликвия привязана к знанию.")
				session.next_supply_at = 0
				TEST_ASSERT(!session.issue_recipe(recipe), "Вторая уникальная реликвия не выдаётся.")
			if(istype(item, /obj/item/melee/sickly_blade/duelist))
				var/obj/item/melee/sickly_blade/duelist/blade = item
				TEST_ASSERT_EQUAL(blade.bound_mind, session.avatar_mind, "Клинок привязан к владельцу.")
				var/mob/living/carbon/human/user = session.avatar
				user.drop_all_held_items()
				user.put_in_hands(blade)
				var/datum/eldritch_knowledge/base_blade/duelist = recipe
				TEST_ASSERT_EQUAL(duelist.held_blade(user), blade, "Способности признают выданный клинок.")
			qdel(item)
		qdel(session)
	TEST_ASSERT_EQUAL(GLOB.heretic_threat_warning_until, old_warning, "Подготовка путей не предупреждает станцию.")

/// Рецепты, комплекты и упражнения соблюдают квоты и не трогают чужие цели.
/datum/unit_test/antag_training_practice_limits/Run()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(session.arena), "Второй участник вошёл.")
	var/mob/living/foreign = session.arena.spawn_creature("human", "laboratory", FALSE, other)
	TEST_ASSERT(session.issue_kit("medicine"), "Выдан комплект первой помощи.")
	TEST_ASSERT_EQUAL(session.arena.supply_count, 3, "Комплект учитывает каждый предмет.")
	TEST_ASSERT(!session.issue_kit("medicine"), "Частая выдача отклоняется.")
	TEST_ASSERT(session.start_practice("medicine"), "Подготовлен пациент.")
	var/mob/living/patient = session.practice_target.resolve()
	TEST_ASSERT(patient.health < patient.maxHealth, "У пациента есть повреждения.")
	patient.revive(full_heal = TRUE, admin_revive = TRUE)
	session.update_practice()
	TEST_ASSERT(session.practice_complete, "Восстановление пациента завершает упражнение.")
	TEST_ASSERT(session.measurement.healing > 0, "Лечение измерено отдельно.")
	session.arena.next_spawn_at = 0
	TEST_ASSERT(session.start_practice("combat"), "Повтор заменяет личную цель.")
	TEST_ASSERT(QDELETED(patient), "Прежний пациент удалён.")
	TEST_ASSERT(!QDELETED(foreign), "Чужая цель остаётся.")
	TEST_ASSERT_EQUAL(length(session.arena.targets), 2, "Повтор не накапливает цели.")
	var/datum/antagonist/heretic/heretic = IS_HERETIC(session.current_body)
	var/datum/eldritch_knowledge/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/living_heart)
	session.next_supply_at = 0
	var/supplies_before = session.arena.supply_count
	TEST_ASSERT(session.issue_recipe(recipe, TRUE), "Компоненты сердца, включая лужу крови, выдаются.")
	TEST_ASSERT_EQUAL(session.arena.supply_count - supplies_before, 3, "Каждый компонент учитывается в квоте.")
	session.next_supply_at = 0
	TEST_ASSERT(session.prepare_path(PATH_ASH, 9), "Подготовлен путь для проверки обряда.")
	session.program.handle_choice(session, session.current_body, "Подготовить вознесение")
	var/datum/eldritch_knowledge/final_eldritch/final_recipe = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/ash_final)
	session.next_supply_at = 0
	session.arena.next_spawn_at = 0
	TEST_ASSERT(session.issue_recipe(final_recipe, TRUE), "Выданы тела для настоящего обряда.")
	TEST_ASSERT_EQUAL(length(session.arena.targets), 2 + HERETIC_ASCENSION_BODIES, "Повторяющиеся компоненты создают нужное число тел.")
	TEST_ASSERT(!heretic.ascended, "Выдача компонентов сама не проводит обряд.")
	var/mob/living/occupied = session.practice_target.resolve()
	other.avatar_mind.transfer_to(occupied)
	session.update_practice()
	TEST_ASSERT(session.measurement.stopped, "Замер прекращается, если цель занята участником.")
	session.arena.next_spawn_at = 0
	TEST_ASSERT(!session.start_practice("combat"), "Повтор не удаляет занятое тело.")
	TEST_ASSERT(!QDELETED(occupied), "Занятое тело сохраняется после попытки повтора.")
	while(session.arena.supply_count < ANTAG_TRAINING_SUPPLY_LIMIT)
		session.arena.issue_item(/obj/item/pen, session.arena.entry_turf, creator = session)
	session.next_supply_at = 0
	TEST_ASSERT(!session.issue_recipe(recipe), "Рецепт не превышает общий лимит.")
	TEST_ASSERT(!session.issue_kit("medicine"), "Комплект не выдаётся частично при нехватке квоты.")
	TEST_ASSERT_EQUAL(session.arena.supply_count, ANTAG_TRAINING_SUPPLY_LIMIT, "Лимит сохранён.")

/// Замер разделяет повреждения и лечение и прекращается вместе с упражнением.
/datum/unit_test/antag_training_measurement/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/datum/antag_training_measurement/measurement = allocate(/datum/antag_training_measurement, target)
	target.adjustOxyLoss(30)
	TEST_ASSERT_EQUAL(measurement.damage, 30, "Зафиксирован фактический урон.")
	target.adjustOxyLoss(-10)
	TEST_ASSERT_EQUAL(measurement.healing, 10, "Лечение посчитано отдельно.")
	TEST_ASSERT_EQUAL(measurement.last_damage, 30, "Лечение не становится последним ударом.")
	target.adjustOxyLoss(100)
	TEST_ASSERT_NOTNULL(measurement.critical_after, "Зафиксировано время до крита, включая нулевое.")
	measurement.stop()
	target.adjustOxyLoss(10)
	TEST_ASSERT_EQUAL(measurement.damage, 130, "После остановки обработчик отключён.")

/// Вызов требует согласия соперника, арена закрывается для посторонних, крит завершает бой.
/datum/unit_test/antag_training_duel/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(first.prepare(), "Полигон подготовлен.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(first.arena), "Второй участник вошёл.")
	var/datum/antag_training_session/outsider = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(outsider.prepare(first.arena), "Третий участник вошёл.")
	TEST_ASSERT(first.request_duel(second), "Создано приглашение.")
	var/datum/antag_training_duel/duel = first.arena.duel
	TEST_ASSERT(!duel.accept(first), "Сам инициатор не принимает приглашение.")
	TEST_ASSERT(!duel.accept(outsider), "Посторонний не принимает приглашение.")
	TEST_ASSERT(duel.accept(second), "Соперник принимает вызов.")
	TEST_ASSERT_EQUAL(duel.phase, "countdown", "Перед боем идёт отсчёт.")
	outsider.current_body.forceMove(first.arena.zones["melee"]["spawn"])
	TEST_ASSERT_NOTEQUAL(first.arena.match_zone(outsider.current_body), "melee", "Посторонний не входит на занятую арену.")
	TEST_ASSERT_NULL(first.arena.spawn_creature("bear", "melee", TRUE, outsider), "В занятой арене нельзя создать противника.")
	duel.deadline = world.time
	duel.process()
	TEST_ASSERT_EQUAL(duel.phase, "active", "Отсчёт завершён.")
	second.current_body.adjustOxyLoss(110)
	TEST_ASSERT_NULL(first.arena.duel, "Крит завершает дуэль.")
	TEST_ASSERT(findtext(first.last_duel_result, first.current_body.real_name), "Победитель записан в результате.")
	first.next_duel_at = 0
	second.heal_self()
	TEST_ASSERT(first.request_duel(second), "После восстановления доступен реванш.")
	TEST_ASSERT(first.arena.duel.accept(second), "Соперник согласен на реванш.")
	first.heal_self()
	TEST_ASSERT_NULL(first.arena.duel, "Кнопка лечения завершает попытку.")
	outsider.current_body.forceMove(first.arena.zones["melee"]["spawn"])
	TEST_ASSERT_EQUAL(first.arena.match_zone(outsider.current_body), "melee", "После дуэли арена открыта.")
