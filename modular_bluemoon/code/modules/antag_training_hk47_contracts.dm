/// Сектор учебных HK: где стоит участник, а из центра и переходов - арена противников.
/datum/antag_training_session/proc/hk47_sector(mob/living/user)
	var/zone_id = arena.match_zone(user)
	if(zone_id == "hub" || !arena.zones[zone_id])
		zone_id = "pve"
	return zone_id

/datum/antag_training_program/hk47/target_created(datum/antag_training_session/session, mob/living/carbon/human/target)
	if(!target.mind)
		return
	enlist_dummy(target)
	recent_target_ref = WEAKREF(target)
	to_chat(session.current_body, span_notice("[target.real_name] - цель учебных контрактов. Ликвидация, захват, кража и охрана в «Моей роли» назначаются на неё."))

/datum/antag_training_program/hk47/proc/enlist_dummy(mob/living/carbon/human/dummy)
	dummy.mind.antag_opt_in_level = ANTAG_OPT_IN_ROUND_REMOVE

/// Последняя отмеченная живая учебная цель участника, иначе последняя созданная.
/datum/antag_training_program/hk47/proc/recent_target(datum/antag_training_session/session)
	var/mob/living/carbon/human/dummy = recent_target_ref?.resolve()
	if(practice_dummy(session, dummy))
		return dummy
	for(var/index in length(session.arena.targets) to 1 step -1)
		dummy = session.arena.targets[index]
		if(practice_dummy(session, dummy))
			return dummy
	return null

/datum/antag_training_program/hk47/proc/practice_dummy(datum/antag_training_session/session, mob/living/carbon/human/dummy)
	return ishuman(dummy) && dummy.mind && dummy.stat != DEAD && session.can_manage_target(dummy)

/datum/antag_training_program/hk47/proc/start_practice_contract(datum/antag_training_session/session, mob/living/user, choice)
	var/datum/antagonist/hk47/training/role = user.mind?.has_antag_datum(/datum/antagonist/hk47/training)
	if(!role)
		to_chat(user, span_warning("Роль HK-47 снята. Начните новым персонажем, чтобы вернуть контракты."))
		return FALSE
	var/list/spec = practice_tasks[choice]
	var/task_type = spec[1]
	var/zone_id = session.hk47_sector(user)
	var/datum/target
	switch(task_type)
		if(/datum/hk_contract_task/sabotage)
			target = role.practice_machine(zone_id)
		if(/datum/hk_contract_task/hunt)
			target = hunt_lineup(session, user, zone_id)
		else
			var/mob/living/carbon/human/dummy = recent_target(session)
			if(!dummy)
				to_chat(user, span_warning("Создайте живую учебную цель в разделе «Цели»: контракт назначается на последнюю из них."))
				return FALSE
			enlist_dummy(dummy)
			if(task_type == /datum/hk_contract_task/theft)
				issue_practice_id(session, dummy)
			target = dummy.mind
	if(!target)
		return FALSE
	role.drop_practice_contract()
	var/datum/hk_contract/contract = role.make_contract(spec[2], task_type, null, target)
	if(!contract || !role.accept(contract))
		qdel(contract)
		return FALSE
	if(task_type == /datum/hk_contract_task/protect)
		role.shorten_protection(contract)
	else if(task_type == /datum/hk_contract_task/hunt)
		contract.update_trace(session.arena.zones[zone_id]["name"])
	to_chat(user, span_notice(practice_hint(task_type, contract)))
	return TRUE

/datum/antag_training_program/hk47/proc/practice_hint(task_type, datum/hk_contract/contract)
	switch(task_type)
		if(/datum/hk_contract_task/kill)
			return "Учебная ликвидация: убейте [contract.target_name] и просканируйте тело терминалом. «Исцелить» в «Целях» поднимет манекен для повтора."
		if(/datum/hk_contract_task/capture)
			return "Учебный захват: обездвижьте [contract.target_name] наручниками, оглушением, сном или до крита, встаньте рядом и вызовите капсулу из терминала. Учебная капсула не улетает: держите цель у неё [DisplayTimeText(ANTAG_TRAINING_HK47_CAPTURE_TIME)]."
		if(/datum/hk_contract_task/theft)
			return "Учебная кража: ID-карта [contract.target_name] у неё в слоте карты. Снимите карту, возьмите в руку и просканируйте терминалом."
		if(/datum/hk_contract_task/protect)
			return "Учебная охрана: [contract.target_name] должна прожить [DisplayTimeText(ANTAG_TRAINING_HK47_PROTECT_TIME)], в раунде - [DisplayTimeText(HK47_PROTECT_TIME)]. Вызовите HK-50: они нападут и на подопечного."
		if(/datum/hk_contract_task/sabotage)
			return "Учебный саботаж: сервер стоит в секторе. Выведите его из строя - контракт засчитается в момент поломки."
		if(/datum/hk_contract_task/hunt)
			return "Учебная охота: цель - один из [ANTAG_TRAINING_HK47_SUSPECTS] манекенов рядом. Подойдите на [HK47_IDENTIFY_RANGE] клетки и опознайте подозреваемого в терминале, ошибка - пауза [DisplayTimeText(HK47_IDENTIFY_COOLDOWN)]. Затем ликвидируйте и просканируйте или захватите."

/datum/antag_training_program/hk47/proc/issue_practice_id(datum/antag_training_session/session, mob/living/carbon/human/dummy)
	var/obj/item/card/id/card = dummy.wear_id
	if(istype(card) && card.registered_name == dummy.real_name)
		return card
	card = new(get_turf(dummy))
	card.registered_name = dummy.real_name
	card.assignment = "Учебная цель"
	card.update_label()
	card.training_owner = WEAKREF(session)
	if(!dummy.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE))
		dummy.put_in_hands(card)
	return card

/// Несколько манекенов рядом, цель охоты - один из них.
/datum/antag_training_program/hk47/proc/hunt_lineup(datum/antag_training_session/session, mob/living/user, zone_id)
	var/datum/antag_training_arena/arena = session.arena
	arena.prune_targets()
	if(length(arena.targets) + ANTAG_TRAINING_HK47_SUSPECTS > ANTAG_TRAINING_TARGET_LIMIT)
		to_chat(user, span_warning("Для охоты нужно [ANTAG_TRAINING_HK47_SUSPECTS] свободных места под цели. Удалите лишние в разделе «Цели»."))
		return null
	var/list/lineup = list()
	for(var/index in 1 to ANTAG_TRAINING_HK47_SUSPECTS)
		var/mob/living/carbon/human/suspect = arena.spawn_creature("human", zone_id, FALSE, session)
		if(!suspect)
			break
		enlist_dummy(suspect)
		lineup += suspect
	if(length(lineup) < ANTAG_TRAINING_HK47_SUSPECTS)
		for(var/mob/living/carbon/human/suspect as anything in lineup)
			QDEL_NULL(suspect.mind)
			qdel(suspect)
		to_chat(user, span_warning("В секторе «[arena.zones[zone_id]["name"]]» не встали манекены для охоты. Попробуйте другой сектор."))
		return null
	var/mob/living/carbon/human/hunted = pick(lineup)
	return hunted.mind

/datum/antagonist/hk47/training
	var/datum/antag_training_session/training
	var/list/datum/weakref/practice_machines = list()

/datum/antagonist/hk47/training/Destroy()
	training = null
	practice_machines.Cut()
	return ..()

/datum/antagonist/hk47/training/proc/drop_practice_contract()
	if(active_contract)
		var/datum/hk_contract/dropped = active_contract
		active_contract = null
		note_history(dropped, HK_CONTRACT_DROPPED)
		qdel(dropped)
	QDEL_LIST(offers)

/// Учебная охрана короче раундовой; deadline() считает от accepted_at, поэтому начало сдвигается.
/datum/antagonist/hk47/training/proc/shorten_protection(datum/hk_contract/contract)
	deltimer(contract.protect_timer)
	contract.accepted_at = world.time - (HK47_PROTECT_TIME - ANTAG_TRAINING_HK47_PROTECT_TIME)
	contract.protect_timer = addtimer(CALLBACK(contract, TYPE_PROC_REF(/datum/hk_contract, protect_time_up)), ANTAG_TRAINING_HK47_PROTECT_TIME, TIMER_STOPPABLE)

/// Целый учебный сервер в секторе: прежний, если он ещё работает, иначе новый.
/datum/antagonist/hk47/training/proc/practice_machine(zone_id)
	var/list/zone = training.arena.zones[zone_id]
	for(var/obj/machinery/antag_training_server/server as anything in sabotage_targets())
		if(training.arena.inside_bounds(get_turf(server), zone["bounds"]))
			return server
	var/turf/spot = training.arena.free_spot(zone["target"], zone["bounds"])
	if(!spot)
		to_chat(owner.current, span_warning("Учебному серверу негде встать в секторе «[zone["name"]]»."))
		return null
	var/obj/machinery/antag_training_server/server = new(spot)
	server.training_owner = WEAKREF(training)
	practice_machines += WEAKREF(server)
	return server

/datum/antagonist/hk47/training/crew_minds()
	var/list/minds = list()
	for(var/datum/mind/dummy as anything in training?.arena?.target_minds)
		if(!QDELETED(dummy) && training.can_manage_target(dummy.current))
			minds += dummy
	return minds

/datum/antagonist/hk47/training/hunt_pool()
	return crew_minds()

/datum/antagonist/hk47/training/counts_as_crew(datum/mind/candidate)
	return (candidate in training?.arena?.target_minds) || ..()

/// Манекены охоты играют роль засветившихся антагонистов.
/datum/antagonist/hk47/training/is_antag_mind(datum/mind/candidate)
	return (candidate in training?.arena?.target_minds) || ..()

/datum/antagonist/hk47/training/report_reprogram(mob/living/droid, datum/mind/new_master)
	return

/// Ценностей станции на полигоне нет: обход мира за ними не нужен.
/datum/antagonist/hk47/training/relic_pool()
	return list()

/datum/antagonist/hk47/training/counts_as_player(mob/living/someone)
	return ..() || (someone?.mind && (someone.mind in training?.arena?.target_minds))

/datum/antagonist/hk47/training/in_contract_zone(atom/thing)
	return training?.arena?.room && get_area(thing) == training.arena.room

/datum/antagonist/hk47/training/sabotage_targets()
	var/list/machines = list()
	for(var/datum/weakref/machine_ref as anything in practice_machines)
		var/obj/machinery/machine = machine_ref.resolve()
		if(machine && !(machine.machine_stat & BROKEN))
			machines += machine
	return machines

/datum/antagonist/hk47/training/suspect_pool(turf/center)
	return SSspatial_grid.orthogonal_range_search(center, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, HK47_IDENTIFY_RANGE)

/datum/antagonist/hk47/training/start_capture_extraction(datum/hk_contract/contract, mob/living/carbon/human/victim)
	var/turf/landing = get_turf(victim)
	do_sparks(3, FALSE, landing)
	addtimer(CALLBACK(src, PROC_REF(finish_practice_capture), WEAKREF(contract), WEAKREF(victim), landing), ANTAG_TRAINING_HK47_CAPTURE_TIME)
	return TRUE

/// Учебная капсула не покидает сектор: цель, удержанная рядом, засчитывается на месте.
/datum/antagonist/hk47/training/proc/finish_practice_capture(datum/weakref/contract_ref, datum/weakref/victim_ref, turf/landing)
	var/datum/hk_contract/contract = contract_ref?.resolve()
	var/mob/living/victim = victim_ref?.resolve()
	if(!contract || contract != active_contract || !victim)
		return FALSE
	if(get_dist(victim, landing) > 1 || !hk47_capture_ready(victim))
		contract.capture_called = FALSE
		to_chat(owner.current, span_warning("Утверждение: цель ушла от учебной капсулы. Обездвижьте её и вызовите капсулу снова."))
		return FALSE
	do_sparks(3, FALSE, landing)
	playsound(landing, 'sound/effects/podwoosh.ogg', 50, FALSE)
	to_chat(owner.current, span_notice("Учебная капсула приняла цель. В раунде она увезла бы её со станции на [DisplayTimeText(HK47_CAPTURE_RETURN_TIME)]."))
	return capture_loaded(contract, victim)

/datum/antagonist/hk47/training/send_pod(obj/structure/closet/supplypod/pod, turf/landing)
	var/obj/structure/closet/supplypod/hk47/reinforcement/reinforcement = pod
	var/datum/callback/landed = istype(reinforcement) ? reinforcement.on_open : null
	if(landed)
		reinforcement.on_open = null
	qdel(pod)
	var/mob/living/droid = owner.current
	var/zone_id = training.hk47_sector(droid)
	var/list/zone = training.arena.zones[zone_id]
	var/turf/near = training.arena.inside_bounds(landing, zone["bounds"]) ? landing : zone["target"]
	var/turf/drop = training.arena.free_spot(near, zone["bounds"]) || zone["target"]
	do_sparks(3, FALSE, drop)
	landed?.Invoke(drop)
	for(var/mob/living/servant as anything in hk50_servants_of(droid))
		servant.training_owner = WEAKREF(training)

/datum/antagonist/hk47/training/upgrade_refusal(datum/hk47_upgrade/upgrade)
	if(istype(upgrade, /datum/hk47_upgrade/ghost_servant))
		return "на полигоне призраков не зовут: HK-50 с разумом доступен только в раунде."
	return null

/datum/antagonist/hk47/training/on_contract_completed(mob/living/source, datum/hk_contract/contract, witnessed)
	if(contracts_done == HK47_CONTRACTS_TO_WIN)
		to_chat(source, span_notice("Учебный режим: в раунде после [HK47_CONTRACTS_TO_WIN] контрактов открылась бы эвакуация, а каждая новая грязная работа раскрывала бы вас и без свидетелей. На полигоне эвакуации нет, тренируйтесь дальше."))
	if(contract_reveals(contract, witnessed))
		INVOKE_ASYNC(src, PROC_REF(escalate))

/// Раскрытие на полигоне только считается: объявлений, записей СБ, пеленгатора, ящика с ионным оружием и заказа на ядро нет.
/datum/antagonist/hk47/training/escalate()
	reveals++
	var/consequence = "ЦК объявил бы станции о дроиде-ассасине, а СБ получила бы приказ на арест"
	if(reveals >= HK47_EXECUTE_REVEAL)
		consequence = "СБ получила бы приказ вас уничтожить и ящик с ионной винтовкой и ЭМИ-гранатами в бриг"
	else if(reveals >= HK47_TRACKER_REVEAL)
		consequence = "СБ получила бы пеленгатор вашего сигнала, а карго - заказ на ядро памяти"
	to_chat(owner.current, span_warning("Учебный режим: грязную работу заметили (раскрытие [reveals]). В раунде [consequence]."))

/datum/antagonist/hk47/training/station_announce(text, title, sound)
	return

/datum/antagonist/hk47/training/terminal_status_data()
	. = ..()
	.["status_name"] = "учебный режим"
	.["status_text"] = "полигон изолирован: объявлений ЦК, записей СБ, пеленгатора и заказа на ядро здесь не будет. Раскрытий за тренировку: [reveals]."

/datum/antagonist/hk47/training/extraction_refusal(mob/living/droid)
	return "на полигоне эвакуации нет: в раунде капсулу вызывают у края станции после [HK47_CONTRACTS_TO_WIN] контрактов."

/obj/machinery/antag_training_server
	name = "training server"
	desc = "Учебная копия сервера РнД для практики саботажа HK-47. Ничего не считает и ни к чему не подключена: выведите её из строя, и учебный контракт засчитается."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server-on"
	density = TRUE
	integrity_failure = 0.5
	use_power = NO_POWER_USE

/obj/machinery/antag_training_server/update_icon_state()
	icon_state = (machine_stat & BROKEN) ? "server-nopower" : "server-on"
	return ..()
