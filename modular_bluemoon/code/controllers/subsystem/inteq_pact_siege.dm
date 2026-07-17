/// Core runtime for InteQ vs PACT siege (see modular_bluemoon/code/__DEFINES/pact_siege.dm)
#define PACT_SIEGE_TRAIT_SOURCE "pact_siege_mode"

GLOBAL_DATUM_INIT(inteq_pact_siege, /datum/inteq_pact_siege, new)

/datum/inteq_pact_siege
	/// Siege is running
	var/active = FALSE
	var/started_at = 0
	var/end_time = 0
	/// Observed z of battlefield (for recall heuristics)
	var/siege_z = 0
	var/datum/gateway_destination/point/pact_siege_battle/battle_dest
	var/list/datum/weakref/defenders = list()
	var/list/datum/weakref/attackers = list()

/datum/inteq_pact_siege/proc/role_check_inteq(mob/living/user)
	if(!user)
		return FALSE
	return (ROLE_INTEQ in user.faction)

/datum/inteq_pact_siege/proc/build_battle_turfs()
	. = list()
	for(var/area_type in GLOB.pact_siege_battle_area_types)
		var/area/A = GLOB.areas_by_type[area_type]
		if(!A)
			continue
		for(var/turf/open/floor/T in A)
			if(T.is_blocked_turf(exclude_mobs = TRUE, source_atom = null, ignore_atoms = null))
				continue
			. += T
	if(!length(.))
		for(var/area_type in GLOB.pact_siege_battle_area_types)
			var/area/A = GLOB.areas_by_type[area_type]
			if(!A)
				continue
			for(var/turf/open/T in A)
				. += T
	return uniqueList(.)

/datum/inteq_pact_siege/proc/is_on_battlefield(mob/living/L)
	if(!L)
		return FALSE
	var/area/A = get_area(L)
	if(A && (A.type in GLOB.pact_siege_battle_area_types))
		return TRUE
	if(siege_z && L.z == siege_z)
		return TRUE
	return FALSE

/datum/inteq_pact_siege/proc/register_defender(mob/living/L)
	if(QDELETED(L) || !(ROLE_INTEQ in L.faction))
		return
	ADD_TRAIT(L, TRAIT_PACT_SIEGE_DEFENDER, PACT_SIEGE_TRAIT_SOURCE)
	defenders |= WEAKREF(L)

/datum/inteq_pact_siege/proc/register_attacker(mob/living/L)
	if(QDELETED(L) || !isliving(L))
		return
	ADD_TRAIT(L, TRAIT_PACT_SIEGE_ATTACKER, PACT_SIEGE_TRAIT_SOURCE)
	attackers |= WEAKREF(L)

/datum/inteq_pact_siege/proc/living_defenders_count()
	. = 0
	for(var/datum/weakref/W as anything in defenders)
		var/mob/living/L = W.resolve()
		if(!QDELETED(L) && L.stat != DEAD && (ROLE_INTEQ in L.faction))
			.++

/datum/inteq_pact_siege/proc/get_station_gateway_arrival()
	if(!GLOB.the_gateway?.portal)
		return null
	return get_step(GLOB.the_gateway.portal, turn(GLOB.the_gateway.dir, 180))

/datum/inteq_pact_siege/proc/activate(mob/living/user)
	if(active)
		to_chat(user, span_warning("Протокол осады уже активен."))
		return FALSE
	if(!role_check_inteq(user))
		to_chat(user, span_warning("Только персонал InteQ может задействовать этот протокол."))
		return FALSE

	var/list/turfs = build_battle_turfs()
	if(!length(turfs))
		to_chat(user, span_boldwarning("Не найдена карта поля боя (типы зон в pact_siege_battle_area_types). Активация отменена."))
		message_admins("PACT siege: no battlefield turfs — check GLOB.pact_siege_battle_area_types / mapping.")
		return FALSE

	battle_dest = new()
	battle_dest.name = "InteQ — объект осады (ПАКТ)"
	battle_dest.target_turfs = turfs
	battle_dest.wait = 0
	battle_dest.enabled = TRUE
	battle_dest.owner = src
	GLOB.gateway_destinations += battle_dest

	var/turf/open/sample = turfs[1]
	siege_z = sample.z

	started_at = world.time
	end_time = world.time + PACT_SIEGE_TIMER
	active = TRUE

	if(GLOB.the_gateway)
		GLOB.the_gateway.AddElement(/datum/element/pact_siege_red_gateway)
		GLOB.the_gateway.teleportion_possible = TRUE
		GLOB.the_gateway.update_appearance()

	priority_announce(
		"Внимание, обнаружена активность в области объекта InteQ. Зафиксирована подготовка к запуску БС-двигателей. Вычислены координаты. Приоритетная цель: уничтожить выживших. Всем подразделениям ПАКТ в системе [station_name()] приготовиться к зачистке. Станционные Врата откалиброваны на вражеский объект.",
		"Центральное Командование",
		'sound/misc/announce_dig.ogg',
		null,
		null,
		TRUE,
	)
	message_admins("[key_name_admin(user)] активировал(а) протокол осады InteQ/PACT. Поле боя: [length(turfs)] турфов, z=[siege_z].")
	log_game("PACT siege activated by [key_name(user)]; battlefield turfs=[length(turfs)] z=[siege_z].")
	return TRUE

/datum/inteq_pact_siege/proc/reward_pact_winner(mob/living/L)
	if(!L?.client || L.stat == DEAD || !HAS_TRAIT(L, TRAIT_PACT_SIEGE_ATTACKER))
		return
	L.client.give_award(/datum/award/score/pact_siege_pact, L, PACT_SIEGE_REWARD_PACT_WIN)
	to_chat(L, span_greenannounce("ПАКТ победил в протоколе осады. Награда начислена в прогресс достижений (учёт на сервере)."))

/datum/inteq_pact_siege/proc/reward_inteq_winner(mob/living/L)
	if(!L?.client || L.stat == DEAD || !(ROLE_INTEQ in L.faction) || !HAS_TRAIT(L, TRAIT_PACT_SIEGE_DEFENDER))
		return
	L.client.give_award(/datum/award/score/pact_siege_inteq, L, PACT_SIEGE_REWARD_INTEQ_WIN)
	to_chat(L, span_greenannounce("InteQ удержал объект. Награда начислена в прогресс достижений (учёт на сервере)."))

/datum/inteq_pact_siege/proc/recall_attackers()
	var/turf/dest = get_station_gateway_arrival()
	if(!dest)
		priority_announce("Блюспейс-отзыв с зоны осады недоступен: станционный шлюз не отвечает. ПАКТу эвакуироваться самостоятельно.", "Центральное Командование", 'sound/misc/announce_dig.ogg', null, null, TRUE)
		return
	for(var/mob/living/L in GLOB.player_list)
		if(QDELETED(L) || !HAS_TRAIT(L, TRAIT_PACT_SIEGE_ATTACKER))
			continue
		if(!is_on_battlefield(L))
			continue
		L.forceMove(dest)
		to_chat(L, span_notice("Импульс экстренного отзыва ПАКТ переносит вас к станционным вратам."))

/datum/inteq_pact_siege/proc/cleanup_gateway()
	var/datum/gateway_destination/old_dest = battle_dest
	battle_dest = null
	if(old_dest)
		GLOB.gateway_destinations -= old_dest
	if(GLOB.the_gateway)
		if(GLOB.the_gateway.target == old_dest)
			GLOB.the_gateway.deactivate()
		GLOB.the_gateway.RemoveElement(/datum/element/pact_siege_red_gateway)
		GLOB.the_gateway.process()
	QDEL_NULL(old_dest)

/datum/inteq_pact_siege/proc/conclude(side, reason)
	if(!active)
		return
	active = FALSE

	priority_announce("Протокол осады InteQ/ПАКТ завершён: [reason]", "Центральное Командование", 'sound/misc/announce_dig.ogg', null, null, TRUE)

	if(side == PACT_SIEGE_SIDE_PACT)
		for(var/datum/weakref/W as anything in attackers)
			var/mob/living/L = W.resolve()
			reward_pact_winner(L)
	else if(side == PACT_SIEGE_SIDE_INTEQ)
		for(var/datum/weakref/W as anything in defenders)
			var/mob/living/L = W.resolve()
			reward_inteq_winner(L)

	recall_attackers()
	cleanup_gateway()
	remove_siege_traits()
	attackers.Cut()
	defenders.Cut()
	siege_z = 0
	started_at = 0
	end_time = 0
	log_game("PACT siege concluded: [side] — [reason]")

/datum/inteq_pact_siege/proc/remove_siege_traits()
	for(var/datum/weakref/W as anything in attackers + defenders)
		var/mob/living/L = W.resolve()
		if(QDELETED(L))
			continue
		REMOVE_TRAIT(L, TRAIT_PACT_SIEGE_ATTACKER, PACT_SIEGE_TRAIT_SOURCE)
		REMOVE_TRAIT(L, TRAIT_PACT_SIEGE_DEFENDER, PACT_SIEGE_TRAIT_SOURCE)

/datum/inteq_pact_siege/proc/process_tick()
	if(!active)
		return
	if(!living_defenders_count())
		conclude(PACT_SIEGE_SIDE_PACT, "все обороняющиеся InteQ нейтрализованы; ПАКТ выполнил цель.")
		return
	if(world.time >= end_time)
		conclude(PACT_SIEGE_SIDE_INTEQ, "силы InteQ удержали позиции до истечения окна осады.")


/// Gateway destination: station -> InteQ battlefield
/datum/gateway_destination/point/pact_siege_battle
	var/datum/inteq_pact_siege/owner

/datum/gateway_destination/point/pact_siege_battle/incoming_pass_check(atom/movable/AM)
	if(!isliving(AM))
		return ..()
	var/mob/living/L = AM
	if(ROLE_INTEQ in L.faction)
		to_chat(L, span_warning("Синхронизация врат отклонена: ваш идентификатор InteQ заблокирован на канале ПАКТ."))
		return FALSE
	return TRUE

/datum/gateway_destination/point/pact_siege_battle/post_transfer(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		GLOB.inteq_pact_siege.register_attacker(AM)

/// Processing — win checks
SUBSYSTEM_DEF(inteq_pact_siege)
	name = "InteQ PACT Siege"
	flags = SS_BACKGROUND | SS_NO_INIT
	wait = 2 SECONDS
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

/datum/controller/subsystem/inteq_pact_siege/fire(resumed)
	if(!GLOB.inteq_pact_siege?.active)
		return
	GLOB.inteq_pact_siege.process_tick()
