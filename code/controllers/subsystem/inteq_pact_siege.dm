/// Core runtime for InteQ vs PACT siege
#define PACT_SIEGE_TRAIT_SOURCE "pact_siege_mode"

GLOBAL_DATUM_INIT(inteq_pact_siege, /datum/inteq_pact_siege, new)

/datum/inteq_pact_siege
	/// Siege is running
	var/active = FALSE
	var/started_at = 0
	var/end_time = 0
	var/siege_z = 0
	/// At least one defender registered — avoids instant PACT win before ghost roles spawn
	var/defenders_ever_registered = FALSE
	var/datum/gateway_destination/point/pact_siege_battle/battle_dest
	var/datum/gateway_destination/point/pact_siege_station_return/station_return_dest
	var/obj/machinery/gateway/away/pact_siege/return_gateway
	/// CentCom siege announcement has been sent — gateway destination unlocks after prep
	var/gateway_announced = FALSE
	var/list/datum/weakref/defenders = list()
	var/list/datum/weakref/attackers = list()
	/// Visual sync: whether station gateway was already flipped to «open» overlays
	var/gateway_visual_open = FALSE

/datum/inteq_pact_siege/proc/role_check_inteq(mob/living/user)
	if(!user)
		return FALSE
	return (ROLE_INTEQ in user.faction)

/datum/inteq_pact_siege/proc/is_battle_area(area/A)
	return istype(A, /area/InteQ_ship)

/datum/inteq_pact_siege/proc/resolve_siege_z()
	if(siege_z)
		return siege_z
	var/list/levels = SSmapping.levels_by_trait(ZTRAIT_PACT_SIEGE)
	if(length(levels))
		siege_z = levels[1]
		return siege_z
	for(var/area/A as anything in GLOB.all_areas)
		if(!is_battle_area(A))
			continue
		for(var/turf/T in A)
			if(T?.z)
				siege_z = T.z
				return siege_z
	return 0

/datum/inteq_pact_siege/proc/suppress_auto_away_destinations()
	/// Awaystarts on Inteq_base auto-register a gateway destination at mapload — hide it so only the siege channel is used.
	for(var/datum/gateway_destination/point/D as anything in GLOB.gateway_destinations)
		if(!istype(D, /datum/gateway_destination/point))
			continue
		if(istype(D, /datum/gateway_destination/point/pact_siege_battle) || istype(D, /datum/gateway_destination/point/pact_siege_station_return))
			continue
		var/touches_siege = FALSE
		for(var/turf/T as anything in D.target_turfs)
			if(T && (is_pact_siege_level(T.z) || (siege_z && T.z == siege_z)))
				touches_siege = TRUE
				break
		if(!touches_siege)
			continue
		D.enabled = FALSE
		D.hidden = TRUE

/datum/inteq_pact_siege/proc/build_battle_turfs()
	. = list()
	var/z = resolve_siege_z()
	/// Prefer mapped awaystart landmarks (PACT drop points), not a random map center.
	for(var/obj/effect/landmark/awaystart/L as anything in GLOB.landmarks_list)
		if(!istype(L, /obj/effect/landmark/awaystart))
			continue
		var/turf/T = get_turf(L)
		if(!T)
			continue
		if(z && T.z != z)
			continue
		. += T
	if(length(.))
		return uniqueList(.)
	/// Fallback if the map has no awaystarts yet
	for(var/area/A as anything in GLOB.all_areas)
		if(!is_battle_area(A))
			continue
		for(var/turf/open/floor/T in A)
			if(z && T.z != z)
				continue
			if(T.is_blocked_turf(exclude_mobs = TRUE, source_atom = null, ignore_atoms = null))
				continue
			. += T
	if(!length(.))
		for(var/area/A as anything in GLOB.all_areas)
			if(!is_battle_area(A))
				continue
			for(var/turf/open/T in A)
				if(z && T.z != z)
					continue
				. += T
	return uniqueList(.)

/datum/inteq_pact_siege/proc/is_on_battlefield(mob/living/L)
	if(!L)
		return FALSE
	var/turf/T = get_turf(L)
	if(!T)
		return FALSE
	if(siege_z && T.z == siege_z)
		return TRUE
	if(is_pact_siege_level(T.z))
		return TRUE
	return is_battle_area(get_area(L))

/datum/inteq_pact_siege/proc/register_defender(mob/living/L)
	if(QDELETED(L) || !(ROLE_INTEQ in L.faction))
		return
	ADD_TRAIT(L, TRAIT_PACT_SIEGE_DEFENDER, PACT_SIEGE_TRAIT_SOURCE)
	defenders |= WEAKREF(L)
	defenders_ever_registered = TRUE

/datum/inteq_pact_siege/proc/register_attacker(mob/living/L)
	if(QDELETED(L) || !isliving(L))
		return
	if(ROLE_INTEQ in L.faction)
		return
	ADD_TRAIT(L, TRAIT_PACT_SIEGE_ATTACKER, PACT_SIEGE_TRAIT_SOURCE)
	attackers |= WEAKREF(L)

/datum/inteq_pact_siege/proc/living_defenders_count()
	. = 0
	for(var/datum/weakref/W as anything in defenders)
		var/mob/living/L = W.resolve()
		if(!QDELETED(L) && L.stat != DEAD && (ROLE_INTEQ in L.faction))
			.++

/datum/inteq_pact_siege/proc/scan_battlefield_participants()
	if(!active || !siege_z)
		return
	for(var/mob/living/L in GLOB.player_list)
		if(QDELETED(L) || L.stat == DEAD)
			continue
		if(!is_on_battlefield(L))
			continue
		if(ROLE_INTEQ in L.faction)
			register_defender(L)
		else
			register_attacker(L)

/datum/inteq_pact_siege/proc/get_station_gateway_arrival()
	if(!GLOB.the_gateway?.portal)
		return null
	return get_step(GLOB.the_gateway.portal, turn(GLOB.the_gateway.dir, 180))

/datum/inteq_pact_siege/proc/station_siege_gateway_linked()
	return GLOB.the_gateway?.target == battle_dest

/datum/inteq_pact_siege/proc/find_return_gateway_turf()
	var/z = resolve_siege_z()
	if(!z)
		return null
	for(var/obj/machinery/gateway/away/G in GLOB.machines)
		if(G.z != z)
			continue
		return get_turf(G)
	for(var/area/A as anything in GLOB.all_areas)
		if(!is_battle_area(A))
			continue
		for(var/turf/open/floor/T in A)
			if(T.z != z)
				continue
			if(T.is_blocked_turf(exclude_mobs = TRUE, source_atom = null, ignore_atoms = null))
				continue
			return T
	return null

/datum/inteq_pact_siege/proc/setup_battlefield_return_gateway()
	if(return_gateway && !QDELETED(return_gateway))
		return
	if(!station_return_dest)
		station_return_dest = new()
		station_return_dest.owner = src
	var/z = resolve_siege_z()
	for(var/obj/machinery/gateway/away/G in GLOB.machines)
		if(G.z != z)
			continue
		if(istype(G, /obj/machinery/gateway/away/pact_siege))
			return_gateway = G
			return
		var/turf/GT = get_turf(G)
		qdel(G)
		return_gateway = new /obj/machinery/gateway/away/pact_siege(GT)
		return
	var/turf/spawn_turf = find_return_gateway_turf()
	if(!spawn_turf)
		message_admins("PACT siege: не удалось найти турф для обратных врат на поле боя.")
		return
	return_gateway = new /obj/machinery/gateway/away/pact_siege(spawn_turf)

/datum/inteq_pact_siege/proc/on_station_siege_gateway_closed()
	if(return_gateway?.target == station_return_dest)
		return_gateway.deactivate()

/datum/inteq_pact_siege/proc/cleanup_return_gateway()
	on_station_siege_gateway_closed()
	if(return_gateway && !QDELETED(return_gateway))
		/// Restore a standard away gateway so survivors can still walk home after the siege ends.
		var/turf/GT = get_turf(return_gateway)
		QDEL_NULL(return_gateway)
		if(GT)
			var/obj/machinery/gateway/away/home_gate = new /obj/machinery/gateway/away(GT)
			home_gate.desc = "Стабилизированный выход БС-канала к станции. После осады используйте его для возврата."
	QDEL_NULL(station_return_dest)

/datum/inteq_pact_siege/proc/refresh_station_gateway_visuals()
	if(!GLOB.the_gateway)
		return
	var/should_be_open = gates_unlocked()
	if(should_be_open == gateway_visual_open)
		return
	gateway_visual_open = should_be_open
	if(should_be_open)
		priority_announce(
			"Красный канал врат на объект InteQ синхронизирован и открыт. Подразделениям ПАКТ разрешено начать зачистку.",
			"Центральное Командование",
			'sound/misc/announce_dig.ogg',
			null,
			null,
			TRUE,
		)
	if(GLOB.the_gateway.pact_siege_visual)
		GLOB.the_gateway.pact_siege_visual = should_be_open ? "open" : "calibrating"
	GLOB.the_gateway.update_appearance()

/datum/inteq_pact_siege/proc/register_existing_defenders()
	for(var/mob/living/L in GLOB.mob_living_list)
		if(is_on_battlefield(L))
			register_defender(L)

/datum/inteq_pact_siege/proc/gates_unlocked()
	return active && gateway_announced && (world.time >= started_at + PACT_SIEGE_PREP_TIME)

/datum/inteq_pact_siege/proc/time_until_gates()
	return max(0, (started_at + PACT_SIEGE_PREP_TIME) - world.time)

/datum/inteq_pact_siege/proc/time_until_evac()
	return max(0, end_time - world.time)

/datum/inteq_pact_siege/proc/activate(mob/living/user)
	if(active)
		if(user)
			to_chat(user, span_warning("Протокол осады уже активен."))
		return FALSE
	if(!role_check_inteq(user))
		to_chat(user, span_warning("Только персонал InteQ может задействовать этот протокол."))
		return FALSE

	var/list/turfs = build_battle_turfs()
	if(!length(turfs))
		to_chat(user, span_boldwarning("Не найдена карта поля боя InteQ. Активация отменена."))
		message_admins("PACT siege: no battlefield turfs — check Inteq_base.dmm / ZTRAIT_PACT_SIEGE.")
		return FALSE

	battle_dest = new()
	battle_dest.name = "InteQ — объект осады (ПАКТ)"
	battle_dest.target_turfs = turfs
	battle_dest.wait = 0
	battle_dest.enabled = TRUE
	battle_dest.owner = src

	var/turf/sample = turfs[1]
	siege_z = sample.z

	started_at = world.time
	end_time = world.time + PACT_SIEGE_TIMER
	active = TRUE

	setup_battlefield_return_gateway()
	register_existing_defenders()
	suppress_auto_away_destinations()

	priority_announce(
		"Внимание, обнаружена активность в области объекта InteQ. Зафиксирована подготовка к запуску БС-двигателей. Вычислены координаты. Приоритетная цель: уничтожить выживших. Всем подразделениям ПАКТ в области [station_name()] приготовиться к зачистке. Станционные Врата откалиброваны на вражеский объект. Канал откроется через [DisplayTimeText(PACT_SIEGE_PREP_TIME)].",
		"Центральное Командование",
		'sound/misc/announce_dig.ogg',
		null,
		null,
		TRUE,
	)
	set_security_level(SEC_LEVEL_LAMBDA, null, TRUE)
	gateway_announced = TRUE
	gateway_visual_open = FALSE
	GLOB.gateway_destinations += battle_dest

	if(GLOB.the_gateway)
		GLOB.the_gateway.AddElement(/datum/element/pact_siege_red_gateway)
		GLOB.the_gateway.teleportion_possible = TRUE
		GLOB.the_gateway.pact_siege_visual = "calibrating"
		GLOB.the_gateway.update_appearance()
		GLOB.the_gateway.process()
	else
		message_admins("PACT siege: станция без GLOB.the_gateway — пункт назначения осады только в консоли врат.")

	message_admins("[key_name_admin(user)] активировал(а) протокол осады InteQ/PACT. Поле боя: [length(turfs)] турфов, z=[siege_z].")
	log_game("PACT siege activated by [key_name(user)]; battlefield turfs=[length(turfs)] z=[siege_z].")
	return TRUE

/datum/inteq_pact_siege/proc/resolve_reward_client(mob/living/L)
	if(QDELETED(L))
		return null
	if(L.client)
		return L.client
	/// Dead / ghosted participants keep the mind key — client lives on the ghost.
	if(L.mind?.key)
		return GLOB.directory[ckey(L.mind.key)]
	if(L.ckey)
		return GLOB.directory[L.ckey]
	return null

/datum/inteq_pact_siege/proc/grant_siege_metadollars(mob/living/L, amount, category)
	if(QDELETED(L) || amount <= 0)
		return FALSE
	if(!SSmetadollars)
		return FALSE
	var/client/C = resolve_reward_client(L)
	if(C?.ckey)
		/// add_amount also tracks round_earnings, but requires prefs.
		if(C.prefs)
			SSmetadollars.add_amount(C, amount, category)
		else
			SSmetadollars.metadollar_adjust(amount, C.ckey, C.key)
		return TRUE
	/// Offline but still has a mind — persist balance without round_earnings UI.
	var/raw_key = L.mind?.key || L.ckey
	if(!raw_key)
		return FALSE
	SSmetadollars.metadollar_adjust(amount, ckey(raw_key), raw_key)
	return TRUE

/datum/inteq_pact_siege/proc/reward_pact_winner(mob/living/L)
	if(QDELETED(L) || !HAS_TRAIT(L, TRAIT_PACT_SIEGE_ATTACKER))
		return
	if(!grant_siege_metadollars(L, PACT_SIEGE_REWARD_PACT_WIN, "pact_siege"))
		log_game("PACT siege: failed to grant PACT reward to [key_name(L)]")
		return
	var/client/C = resolve_reward_client(L)
	if(C)
		to_chat(C, span_greentext("<b>ПАКТ победил в протоколе осады. Начислено [PACT_SIEGE_REWARD_PACT_WIN] метадолларов.</b>"))

/datum/inteq_pact_siege/proc/reward_inteq_winner(mob/living/L)
	if(QDELETED(L) || !(ROLE_INTEQ in L.faction) || !HAS_TRAIT(L, TRAIT_PACT_SIEGE_DEFENDER))
		return
	if(!grant_siege_metadollars(L, PACT_SIEGE_REWARD_INTEQ_WIN, "pact_siege"))
		log_game("PACT siege: failed to grant InteQ reward to [key_name(L)]")
		return
	var/client/C = resolve_reward_client(L)
	if(C)
		to_chat(C, span_greentext("<b>InteQ успешно эвакуировался с объекта. Начислено [PACT_SIEGE_REWARD_INTEQ_WIN] метадолларов.</b>"))

/datum/inteq_pact_siege/proc/recall_attackers()
	/// After the siege, attackers return via the battlefield gateway (standard away gate).
	priority_announce(
		"Протокол штурма завершён. Силам ПАКТ на объекте InteQ надлежит вернуться на станцию через врата на поле боя.",
		"Центральное Командование",
		'sound/misc/announce_dig.ogg',
		null,
		null,
		TRUE,
	)
	for(var/mob/living/L in GLOB.player_list)
		if(QDELETED(L) || !HAS_TRAIT(L, TRAIT_PACT_SIEGE_ATTACKER))
			continue
		if(!is_on_battlefield(L))
			continue
		to_chat(L, span_notice("Осада завершена. Вернитесь на станцию через ГЕЙТ на объекте InteQ."))

/datum/inteq_pact_siege/proc/evacuate_defenders()
	/// Living InteQ leave the round via goodbye() when the shuttle departs.
	for(var/datum/weakref/W as anything in defenders)
		var/mob/living/L = W.resolve()
		if(QDELETED(L) || L.stat == DEAD)
			continue
		to_chat(L, span_notice("Эвакуационный шаттл InteQ покидает зону боя..."))
		L.goodbye()

/datum/inteq_pact_siege/proc/play_evac_hyperspace_sound(sound_file)
	var/z = siege_z || resolve_siege_z()
	if(!z)
		return
	var/atom/source = locate(round(world.maxx * 0.5), round(world.maxy * 0.5), z)
	if(!source)
		return
	for(var/mob/M as anything in SSmobs.clients_by_zlevel[z])
		if(QDELETED(M) || !M.client)
			continue
		M.playsound_local(source, sound_file, 100, FALSE)

/datum/inteq_pact_siege/proc/warn_evac_shuttle_departure()
	priority_announce(
		"Эвакуационный шаттл InteQ готовится к отлёту. Всем, кто находится на его палубе: у вас [DisplayTimeText(PACT_SIEGE_EVAC_WARNING)] до запуска. Не успевшие будут унесены вместе с кораблём.",
		"Центральное Командование",
		'sound/misc/announce_dig.ogg',
		null,
		null,
		TRUE,
	)
	play_evac_hyperspace_sound('sound/effects/hyperspace_begin.ogg')
	for(var/mob/living/L in GLOB.player_list)
		if(QDELETED(L))
			continue
		var/area/A = get_area(L)
		if(!istype(A, /area/ruin/space/has_grav/bluemoon/inteq_forgotten_ship))
			continue
		to_chat(L, span_userdanger("Эвакуационный шаттл InteQ стартует через [DisplayTimeText(PACT_SIEGE_EVAC_WARNING)]! Покиньте палубу через ГЕЙТ или будете уничтожены вместе с кораблём."))

/datum/inteq_pact_siege/proc/depart_evac_shuttle()
	play_evac_hyperspace_sound('sound/effects/hyperspace_progress.ogg')
	priority_announce(
		"Эвакуационный шаттл InteQ покинул зону боя.",
		"Центральное Командование",
		'sound/misc/announce_dig.ogg',
		null,
		null,
		TRUE,
	)
	evacuate_defenders()
	/// goodbye() needs a moment; then wipe the shuttle volume (PACT still aboard are deleted with it)
	addtimer(CALLBACK(src, PROC_REF(wipe_inteq_forgotten_ship)), 10 SECONDS)

/// Delete the InteQ forgotten-ship shuttle volume — it has left the battlefield.
/datum/inteq_pact_siege/proc/wipe_inteq_forgotten_ship()
	var/area/ship = GLOB.areas_by_type[/area/ruin/space/has_grav/bluemoon/inteq_forgotten_ship]
	if(!ship)
		return
	var/area/space_area = GLOB.areas_by_type[/area/space]
	if(!space_area)
		for(var/area/A as anything in GLOB.all_areas)
			if(istype(A, /area/space))
				space_area = A
				break
	var/list/coords = list()
	for(var/turf/T in ship)
		coords += list(list(T.x, T.y, T.z))
	for(var/list/C as anything in coords)
		var/turf/T = locate(C[1], C[2], C[3])
		if(!T)
			continue
		/// Mid-goodbye InteQ are ignored; anyone else still aboard (включая ПАКТ) удаляется с шаттлом.
		T.empty(/turf/open/space/basic, ignore_typecache = typecacheof(list(/mob/dead)))
		T = locate(C[1], C[2], C[3])
		if(!T || !space_area || istype(T.loc, /area/space))
			continue
		var/area/old_area = T.loc
		space_area.contents += T
		T.change_area(old_area, space_area)
	log_game("PACT siege: wiped /area/ruin/space/has_grav/bluemoon/inteq_forgotten_ship ([length(coords)] turfs).")

/datum/inteq_pact_siege/proc/cleanup_gateway()
	cleanup_return_gateway()
	var/datum/gateway_destination/old_dest = battle_dest
	battle_dest = null
	if(old_dest)
		GLOB.gateway_destinations -= old_dest
	if(GLOB.the_gateway)
		if(GLOB.the_gateway.target == old_dest)
			GLOB.the_gateway.deactivate()
		GLOB.the_gateway.RemoveElement(/datum/element/pact_siege_red_gateway)
		GLOB.the_gateway.pact_siege_visual = null
		GLOB.the_gateway.teleportion_possible = FALSE
		/// Re-evaluate other destinations so the gate can return to a normal idle/ready look
		GLOB.the_gateway.process()
		GLOB.the_gateway.update_appearance()
	QDEL_NULL(old_dest)
	gateway_visual_open = FALSE

/datum/inteq_pact_siege/proc/conclude(side, reason)
	if(!active)
		return
	active = FALSE

	priority_announce("Протокол осады InteQ/ПАКТ завершён: [reason]", "Центральное Командование", 'sound/misc/announce_dig.ogg', null, null, TRUE)

	scan_battlefield_participants()

	if(side == PACT_SIEGE_SIDE_PACT)
		for(var/datum/weakref/W as anything in attackers)
			var/mob/living/L = W.resolve()
			reward_pact_winner(L)
	else if(side == PACT_SIEGE_SIDE_INTEQ)
		for(var/datum/weakref/W as anything in defenders)
			var/mob/living/L = W.resolve()
			reward_inteq_winner(L)

	/// InteQ leave via goodbye when the shuttle actually departs; PACT still aboard are wiped with it.
	warn_evac_shuttle_departure()
	addtimer(CALLBACK(src, PROC_REF(depart_evac_shuttle)), PACT_SIEGE_EVAC_WARNING)
	recall_attackers()
	cleanup_gateway()
	remove_siege_traits()
	attackers.Cut()
	/// defenders kept until depart_evac_shuttle() for goodbye targeting
	defenders_ever_registered = FALSE
	gateway_announced = FALSE
	/// siege_z kept until wipe so hyperspace sound / wipe can resolve the battlefield
	started_at = 0
	end_time = 0
	log_game("PACT siege concluded: [side] — [reason]")
	addtimer(CALLBACK(src, PROC_REF(finish_siege_cleanup)), PACT_SIEGE_EVAC_WARNING + 12 SECONDS)

/datum/inteq_pact_siege/proc/finish_siege_cleanup()
	defenders.Cut()
	siege_z = 0

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
	refresh_station_gateway_visuals()
	scan_battlefield_participants()
	if(defenders_ever_registered && !living_defenders_count())
		conclude(PACT_SIEGE_SIDE_PACT, "все обороняющиеся InteQ нейтрализованы; ПАКТ выполнил цель.")
		return
	if(world.time >= end_time)
		if(living_defenders_count())
			conclude(PACT_SIEGE_SIDE_INTEQ, "силы InteQ удержали позиции и эвакуировались до истечения окна осады.")
		else
			conclude(PACT_SIEGE_SIDE_PACT, "все обороняющиеся InteQ нейтрализованы к моменту эвакуации; ПАКТ выполнил цель.")


/// Gateway destination: station -> InteQ battlefield
/datum/gateway_destination/point/pact_siege_battle
	var/datum/inteq_pact_siege/owner

/datum/gateway_destination/point/pact_siege_battle/deactivate(obj/machinery/gateway/deactivated)
	owner?.on_station_siege_gateway_closed()

/datum/gateway_destination/point/pact_siege_battle/is_available()
	if(!owner?.gates_unlocked())
		return FALSE
	return ..()

/datum/gateway_destination/point/pact_siege_battle/get_available_reason()
	if(!owner?.active || !owner.gateway_announced)
		return "Ожидание объявления Центрального Командования."
	if(!owner.gates_unlocked())
		return "Калибровка красного канала. Открытие через [DisplayTimeText(owner.time_until_gates())]."
	return ..()

/datum/gateway_destination/point/pact_siege_battle/get_ui_data()
	. = ..()
	if(owner?.active && !owner.gates_unlocked())
		var/prep = PACT_SIEGE_PREP_TIME
		.["timeout"] = clamp(1 - owner.time_until_gates() / prep, 0, 1)

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

/// Gateway destination: InteQ battlefield -> random station turf
/datum/gateway_destination/point/pact_siege_station_return
	var/datum/inteq_pact_siege/owner

/datum/gateway_destination/point/pact_siege_station_return/is_available()
	return owner?.active && owner.station_siege_gateway_linked()

/datum/gateway_destination/point/pact_siege_station_return/get_target_turf()
	return get_safe_random_station_turf()

/datum/gateway_destination/point/pact_siege_station_return/incoming_pass_check(atom/movable/AM)
	if(!is_available())
		return FALSE
	if(isliving(AM))
		var/mob/living/L = AM
		if(ROLE_INTEQ in L.faction)
			to_chat(L, span_warning("Синхронизация врат отклонена: канал возврата недоступен для идентификаторов InteQ."))
			return FALSE
		if(check_exile_implant(L))
			return FALSE
	else
		for(var/mob/living/L in AM.contents)
			if(check_exile_implant(L))
				return FALSE
	if(AM.has_buckled_mobs())
		for(var/mob/living/L in AM.buckled_mobs)
			if(check_exile_implant(L))
				return FALSE
	return TRUE

/datum/gateway_destination/point/pact_siege_station_return/proc/check_exile_implant(mob/living/L)
	for(var/obj/item/implant/exile/E in L.implants)
		to_chat(L, span_userdanger("The station gate has detected your exile implant and is blocking your entry."))
		return TRUE
	return FALSE

/// Away gateway on the InteQ battlefield — opens a return link while the station gate targets the siege.
/obj/machinery/gateway/away/pact_siege
	desc = "Стабилизированный выход БС-канала к станции. Работает, пока станционные Врата откалиброваны на объект InteQ."

/obj/machinery/gateway/away/pact_siege/interact(mob/user)
	if(!is_operational)
		return
	if(!target)
		var/datum/inteq_pact_siege/siege = GLOB.inteq_pact_siege
		if(!siege?.active || !siege.station_return_dest)
			to_chat(user, span_warning("Обратный канал к станции сейчас недоступен."))
			return
		if(!siege.station_siege_gateway_linked())
			to_chat(user, span_warning("Станционные Врата не настроены на объект InteQ — возврат заблокирован."))
			return
		activate(siege.station_return_dest)
	else
		deactivate()

/// Processing — win checks
SUBSYSTEM_DEF(inteq_pact_siege)
	name = "InteQ PACT Siege"
	flags = SS_BACKGROUND
	wait = 2 SECONDS
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

/datum/controller/subsystem/inteq_pact_siege/Initialize()
	. = ..()
	/// Resolve siege z early so ghost roles / tools can query it
	GLOB.inteq_pact_siege.resolve_siege_z()
	GLOB.inteq_pact_siege.suppress_auto_away_destinations()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/inteq_pact_siege/fire(resumed)
	if(!GLOB.inteq_pact_siege?.active)
		return
	GLOB.inteq_pact_siege.process_tick()
