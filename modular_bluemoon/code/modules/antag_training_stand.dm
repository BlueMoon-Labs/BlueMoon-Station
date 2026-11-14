/// Во сколько раз стенд кодера и ментора поднимает лимиты целей, вещей и построек.
#define ANTAG_TRAINING_STAND_LIMIT_SCALE 2

// Стоп-лист стенда для кодеров и менторов без R_ADMIN: всё, что бьёт по станции целиком, трогает её экономику, записи и связь, зовёт призраков или ломает карту. Подтипы входят.
GLOBAL_LIST_INIT(antag_training_stand_blacklist, typecacheof(list(
	/obj/singularity,
	/obj/machinery/the_singularitygen,
	/obj/machinery/power/singularity_beacon,
	/obj/machinery/power/tesla_coil,
	/obj/machinery/gravity_generator,
	/obj/docking_port,
	/obj/machinery/computer/shuttle,
	/obj/machinery/computer/shuttle_flight,
	/obj/machinery/computer/emergency_shuttle,
	/obj/machinery/computer/camera_advanced/shuttle_docker,
	/obj/machinery/shuttle,
	/obj/structure/shuttle,
	/obj/item/shuttle_creator,
	/obj/item/shuttle_curse,
	/obj/item/transfer_valve,
	/obj/machinery/syndicatebomb,
	/obj/item/bombcore,
	/obj/item/sbeacondrop,
	/obj/item/grenade/syndieminibomb,
	/obj/effect/anomaly,
	/obj/machinery/nuclearbomb,
	/obj/item/disk/nuclear,
	/obj/item/nuke_core,
	/obj/machinery/power/supermatter_crystal,
	/obj/machinery/doomsday_device,
	/obj/machinery/computer/communications,
	/obj/machinery/requests_console,
	/obj/machinery/keycard_auth,
	/obj/machinery/computer/robotics,
	/obj/machinery/computer/upload,
	/mob/camera/blob,
	/mob/living/simple_animal/revenant,
	/mob/living/silicon/ai,
	/mob/living/silicon/robot,
	/obj/effect/landmark,
	/obj/machinery/computer/bank_machine,
	/obj/machinery/computer/cargo,
	/obj/machinery/computer/bounty,
	/obj/machinery/computer/piratepad_control,
	/obj/machinery/piratepad,
	/obj/machinery/computer/account_database,
	/obj/item/card/id/departmental_budget,
	/obj/item/card/id/captains_spare,
	/obj/item/station_charter,
	/obj/machinery/ore_silo,
	/obj/machinery/computer/secure_data,
	/obj/machinery/computer/med_data,
	/obj/machinery/computer/prisoner,
	/obj/machinery/gulag_teleporter,
	/obj/machinery/computer/crew,
	/obj/machinery/cryopod,
	/obj/machinery/computer/cryopod,
	/obj/machinery/telecomms,
	/obj/machinery/computer/telecomms,
	/obj/machinery/computer/message_monitor,
	/obj/machinery/announcement_system,
	/obj/machinery/computer/apc_control,
	/obj/machinery/computer/mecha,
	/obj/machinery/computer/rdconsole,
	/obj/machinery/computer/rdservercontrol,
	/obj/machinery/rnd/server,
	/obj/machinery/computer/teleporter,
	/obj/item/hand_tele,
	/obj/machinery/computer/gateway_control,
	/obj/machinery/gateway,
	/obj/machinery/bsa,
	/obj/machinery/computer/bsa_control,
	/obj/machinery/computer/custom_shuttle,
	/obj/machinery/computer/auxiliary_base,
	/obj/machinery/computer/camera_advanced/base_construction,
	/obj/machinery/computer/holodeck,
	/obj/item/uplink,
	/obj/effect/mob_spawn,
	/obj/item/antag_spawner,
	/obj/item/guardiancreator,
	/obj/item/slimepotion/slime/sentience,
	/obj/item/mmi/posibrain,
	/obj/item/circuitboard/computer/cargo,
	/obj/item/circuitboard/computer/bounty,
	/obj/item/circuitboard/computer/secure_data,
	/obj/item/circuitboard/computer/med_data,
	/obj/item/circuitboard/computer/prisoner,
	/obj/item/circuitboard/computer/crew,
	/obj/item/circuitboard/computer/communications,
	/obj/item/circuitboard/computer/message_monitor,
	/obj/item/circuitboard/computer/comm_monitor,
	/obj/item/circuitboard/computer/comm_server,
	/obj/item/circuitboard/machine/telecomms,
	/obj/item/circuitboard/machine/announcement_system,
	/obj/item/circuitboard/computer/apc_control,
	/obj/item/circuitboard/computer/mecha_control,
	/obj/item/circuitboard/computer/rdconsole,
	/obj/item/circuitboard/computer/rdservercontrol,
	/obj/item/circuitboard/machine/rdserver,
	/obj/item/circuitboard/computer/teleporter,
	/obj/item/circuitboard/computer/bsa_control,
	/obj/item/circuitboard/computer/robotics,
	/obj/item/circuitboard/computer/aiupload,
	/obj/item/circuitboard/computer/borgupload,
	/obj/item/circuitboard/computer/shuttle,
	/obj/item/circuitboard/machine/ore_silo,
)))

/// Пути всех типов, которые стенд умеет создавать; собирается при первом поиске.
GLOBAL_LIST_EMPTY(antag_training_stand_types)

/datum/antag_training_session
	var/stand_mode = FALSE
	var/stand_query
	var/list/stand_results
	var/stand_more = FALSE

/// Права стенда по клиенту владельца сеанса, а не по телу: тело могут сменить или занять.
/datum/antag_training_session/proc/stand_access()
	var/client/player = GLOB.directory[player_key] || current_body?.mock_client
	if(!player)
		return ANTAG_TRAINING_STAND_NONE
	if(check_rights_for(player, R_ADMIN))
		return ANTAG_TRAINING_STAND_FULL
	if(check_rights_for(player, R_DEBUG | R_SPAWN) || player.mentor_datum)
		return ANTAG_TRAINING_STAND_LIMITED
	return ANTAG_TRAINING_STAND_NONE

/datum/antag_training_session/proc/stand_active()
	return stand_mode && stand_access() != ANTAG_TRAINING_STAND_NONE

/// Множитель лимитов полигона в режиме стенда: 0 - лимитов нет.
/datum/antag_training_session/proc/stand_limit_scale()
	if(!stand_active())
		return 1
	return stand_access() == ANTAG_TRAINING_STAND_FULL ? 0 : ANTAG_TRAINING_STAND_LIMIT_SCALE

/// Лимит полигона для сеанса: стенд админа его снимает, стенд кодера и ментора умножает.
/datum/antag_training_arena/proc/limit_for(limit, datum/antag_training_session/session)
	if(!session)
		return limit
	var/scale = session.stand_limit_scale()
	return scale ? limit * scale : INFINITY

/proc/antag_training_stand_forbidden(path, access)
	if(!ispath(path, /obj) && !ispath(path, /mob/living))
		return TRUE
	return access != ANTAG_TRAINING_STAND_FULL && GLOB.antag_training_stand_blacklist[path]

/// Снять бронь сектора ("booking", id сектора), распустить группу ("squad", REF группы), закрыть её сценарий ("scenario", REF группы) или освободить площадку хаба ("pad", номер или id площадки). Возвращает запись для лога или null.
/datum/antag_training_arena/proc/stand_force_release(kind, target_id)
	switch(kind)
		if("booking")
			var/datum/antag_training_sector/sector = istext(target_id) ? sectors[target_id] : null
			var/datum/antag_training_squad/holder = sector?.booked_by
			if(!holder || !holder.release("Режим стенда: бронь сектора «[sector.name]» снята."))
				return null
			return "снял бронь сектора «[sector.name]» с группы «[holder.name]»"
		if("squad")
			var/datum/antag_training_squad/team = locate(target_id) in squads
			if(!team)
				return null
			var/squad_name = team.name
			team.disband("Режим стенда: группа распущена.")
			return "распустил группу «[squad_name]»"
		if("scenario")
			var/datum/antag_training_squad/team = locate(target_id) in squads
			var/datum/antag_training_scenario/running = team?.scenario
			if(!running)
				return null
			var/scenario_name = running.name
			if(!running.force_end("Режим стенда: сценарий «[scenario_name]» завершён, все возвращаются в вестибюль хаба с прежними ролями."))
				return null
			return "завершил сценарий «[scenario_name]» группы «[team.name]»"
		if("pad")
			var/datum/antag_training_hub_pad/pad = hub?.pad_by_id(target_id)
			var/holder = pad?.holder_name()
			if(!holder || !pad.release("Режим стенда: [pad.name] освобождена."))
				return null
			return "освободил [pad.name], владелец был [holder]"
	return null

/datum/antag_training_session/proc/stand_log(text, atom/where)
	var/turf/spot = get_turf(where || current_body)
	log_admin("[key_name(current_body)] стенд полигона: [text] ([AREACOORD(spot)])")
	message_admins("[key_name_admin(current_body)] стенд полигона: [text] [ADMIN_VERBOSEJMP(spot)]")
	log_game("[key_name(current_body)] стенд полигона: [text] ([AREACOORD(spot)])")

/datum/antag_training_session/proc/stand_data()
	var/access = stand_access()
	if(access == ANTAG_TRAINING_STAND_NONE)
		stand_mode = FALSE
		return null
	var/list/data = list("enabled" = stand_mode, "full" = access == ANTAG_TRAINING_STAND_FULL, "limit_scale" = access == ANTAG_TRAINING_STAND_FULL ? 0 : ANTAG_TRAINING_STAND_LIMIT_SCALE, "query" = stand_query, "results" = stand_results || list(), "more" = stand_more)
	data["members"] = list()
	data["squads"] = list()
	if(!stand_mode)
		return data
	for(var/datum/antag_training_session/member as anything in arena.members)
		data["members"] += list(list("id" = REF(member), "name" = member.current_body?.real_name || "Смена персонажа", "role" = member.role?.id, "program_id" = "[member.program?.type]", "self" = member == src))
	for(var/datum/antag_training_squad/team as anything in arena.squads)
		data["squads"] += list(list("id" = REF(team), "name" = team.name, "members" = length(team.members), "sector_id" = team.sector?.id, "sector" = team.sector?.name, "scenario" = team.scenario?.name))
	data["pads"] = list()
	for(var/datum/antag_training_hub_pad/pad as anything in arena.hub?.pads)
		if(pad.owner || pad.owner_squad)
			data["pads"] += list(list("id" = pad.id, "name" = pad.name, "owner" = pad.holder_name(), "preset" = antag_training_pad_preset_name(pad.preset_id)))
	return data

/datum/antag_training_session/proc/stand_act(action, list/params)
	var/access = stand_access()
	if(access == ANTAG_TRAINING_STAND_NONE)
		stand_mode = FALSE
		return FALSE
	if(action == "stand_toggle")
		stand_mode = !stand_mode
		stand_log(stand_mode ? "включил режим стенда, лимиты [access == ANTAG_TRAINING_STAND_FULL ? "сняты" : "удвоены"]" : "выключил режим стенда")
		return TRUE
	if(!stand_mode)
		return FALSE
	switch(action)
		if("stand_search")
			return stand_search(params["query"], access)
		if("stand_spawn")
			return !!stand_spawn(params["path"], access)
		if("stand_role")
			var/datum/antag_training_session/member = locate(params["id"]) in arena.members
			if(!member || !istext(params["role"]))
				return FALSE
			member.next_restart_at = 0
			if(!member.set_role(params["role"], access == ANTAG_TRAINING_STAND_FULL))
				return FALSE
			stand_log("сменил должность участнику [key_name(member.current_body)] на [params["role"]]", member.current_body)
			stand_notify(member, "Режим стенда: вам сменили должность.")
			return TRUE
		if("stand_program")
			var/datum/antag_training_session/member = locate(params["id"]) in arena.members
			if(!member || !istext(params["program"]))
				return FALSE
			for(var/program_type in subtypesof(/datum/antag_training_program))
				if("[program_type]" != params["program"] || !antag_training_program_selectable(program_type))
					continue
				member.next_restart_at = 0
				if(!member.restart(program_type, access == ANTAG_TRAINING_STAND_FULL))
					return FALSE
				stand_log("сменил программу участнику [key_name(member.current_body)] на [program_type]", member.current_body)
				stand_notify(member, "Режим стенда: вам сменили программу на «[member.program.name]».")
				return TRUE
			return FALSE
		if("stand_reset")
			var/zone_id = params["zone"]
			if(!istext(zone_id) || zone_id == "hub" || (zone_id != "all" && !arena.zones[zone_id] && !arena.sectors[zone_id]) || arena.resetting)
				return FALSE
			arena.cancel_reset()
			arena.next_reset_at = 0
			stand_log("сбросил без голосования зону [zone_id]")
			INVOKE_ASYNC(arena, TYPE_PROC_REF(/datum/antag_training_arena, reset_zone), zone_id)
			return TRUE
		if("stand_release")
			var/released = arena.stand_force_release(params["kind"], params["id"])
			if(!released)
				return FALSE
			stand_log(released)
			return TRUE
	return FALSE

/datum/antag_training_session/proc/stand_notify(datum/antag_training_session/member, message)
	if(member != src)
		to_chat(member.current_body, span_notice(message))

/datum/antag_training_session/proc/stand_search(query, access)
	if(!istext(query))
		return FALSE
	query = lowertext(trim(query))
	stand_query = query
	stand_results = list()
	stand_more = FALSE
	if(length(query) < ANTAG_TRAINING_STAND_QUERY_MIN)
		return TRUE
	if(!length(GLOB.antag_training_stand_types))
		for(var/path in typesof(/obj) + typesof(/mob/living))
			GLOB.antag_training_stand_types += "[path]"
	for(var/path_text in GLOB.antag_training_stand_types)
		if(!findtext(path_text, query))
			continue
		var/atom/path = text2path(path_text)
		if(antag_training_stand_forbidden(path, access))
			continue
		if(length(stand_results) >= ANTAG_TRAINING_STAND_RESULTS)
			stand_more = TRUE
			break
		stand_results += list(list("path" = path_text, "name" = initial(path.name)))
	return TRUE

/// Клетка перед участником, если она свободна, иначе его собственная; только внутри своего полигона.
/datum/antag_training_session/proc/stand_spawn_turf()
	var/turf/ahead = get_step(current_body, current_body.dir)
	if(isopenturf(ahead) && arena.owns_area(get_area(ahead)) && !ahead.is_blocked_turf(TRUE))
		return ahead
	var/turf/here = get_turf(current_body)
	return arena.owns_area(get_area(here)) ? here : null

/datum/antag_training_session/proc/stand_spawn(path_text, access)
	var/path = istext(path_text) ? text2path(path_text) : null
	if(!path)
		return null
	if(antag_training_stand_forbidden(path, access))
		to_chat(current_body, span_warning("Этот тип в стоп-листе стенда: его создают только администраторы."))
		stand_log("пытался создать запрещённый [path]")
		return null
	var/turf/spot = stand_spawn_turf()
	if(!spot || arena.resetting || arena.finished)
		to_chat(current_body, span_warning("Создавать можно только на полигоне и не во время сброса."))
		return null
	var/atom/movable/thing = new path(spot)
	if(QDELETED(thing))
		to_chat(current_body, span_warning("[path] удалился сразу после создания."))
		return null
	if(thing.training_origin?.resolve() != arena || !arena.owns_area(get_area(thing)))
		qdel(thing)
		to_chat(current_body, span_warning("[path] покинул полигон при создании и удалён."))
		return null
	for(var/atom/movable/content as anything in thing.GetAllContents())
		content.training_owner = WEAKREF(src)
	if(isliving(thing) && !arena.claim_target(thing, src))
		var/mob/living/body = thing
		QDEL_NULL(body.mind)
		qdel(thing)
		return null
	stand_log("создал [path]", thing)
	return thing

#undef ANTAG_TRAINING_STAND_LIMIT_SCALE
