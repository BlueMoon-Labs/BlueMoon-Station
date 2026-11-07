/// Дальность, с которой участник смотрит экран трибуны с дивана.
#define ANTAG_TRAINING_TRIBUNE_RANGE 10

/// Доска групп и экраны трибуны ставятся на метки вестибюля после каждой загрузки хаба.
/datum/antag_training_hub/proc/place_lobby_machines()
	usr = null
	var/turf/board_spot = landmark_turf("hub_board")
	if(board_spot && !(locate(/obj/structure/sign/antag_training_board/squads) in board_spot))
		new /obj/structure/sign/antag_training_board/squads(board_spot)
	var/turf/tribune = landmark_turf("hub_tribune")
	if(!tribune)
		return
	for(var/offset in list(-2, 0, 2))
		var/turf/spot = locate(tribune.x + offset, tribune.y, tribune.z)
		if(spot && !(locate(/obj/machinery/computer/security/telescreen/antag_training) in spot))
			new /obj/machinery/computer/security/telescreen/antag_training(spot)

/// Группы для доски и каталога: состав, сценарий и его слоты. joinable_only - только открытые группы.
/proc/antag_training_board_entries(datum/antag_training_arena/arena, joinable_only = FALSE)
	. = list()
	if(!arena || arena.finished)
		return
	for(var/datum/antag_training_squad/team as anything in arena.squads)
		if(!joinable_only || team.open)
			. += list(team.board_entry())

/datum/antag_training_squad/proc/board_entry()
	var/list/names = list()
	for(var/datum/antag_training_session/member as anything in members)
		names += member.squad_name()
	var/list/entry = list("id" = REF(src), "name" = name, "color" = color, "open" = open, "leader" = leader?.squad_name(), "members" = names, "sector" = sector?.name, "scenario" = null)
	if(!scenario)
		return entry
	var/list/slot_entries = list()
	for(var/datum/antag_training_scenario_slot/slot as anything in scenario.slots)
		var/list/occupant_names = list()
		for(var/datum/antag_training_session/member as anything in slot.occupants)
			occupant_names += member.squad_name()
		var/datum/antag_training_role/slot_role = antag_training_role(slot.role_id)
		slot_entries += list(list("id" = REF(slot), "label" = slot.label, "side_name" = scenario.side_name(slot.side), "role_name" = slot_role?.name, "program_name" = slot.program_name(), "count" = slot.count, "required" = slot.required, "occupants" = occupant_names, "free" = slot.free_seats(), "joinable" = !antag_training_catalog_join_refusal(src, slot)))
	entry["scenario"] = list("name" = scenario.name, "phase" = scenario.phase, "venue" = scenario.venue?.name(), "slots" = slot_entries)
	return entry

/// Почему призрак из каталога не войдёт в группу и слот, или null.
/proc/antag_training_catalog_join_refusal(datum/antag_training_squad/team, datum/antag_training_scenario_slot/slot)
	if(QDELETED(team) || !team.arena || team.arena.finished)
		return "Этой группы уже нет."
	if(!team.open)
		return "Группа «[team.name]» собирается по приглашениям: войдите на полигон и попросите её лидера позвать вас."
	if(!slot)
		return null
	var/datum/antag_training_scenario/current = team.scenario
	if(QDELETED(slot) || !current || !(slot in current.slots))
		return "Такого слота больше нет: лидер сменил сценарий или лист."
	if(current.phase == ANTAG_TRAINING_SCENARIO_STARTING || current.phase == ANTAG_TRAINING_SCENARIO_RUNNING)
		return "Сценарий «[current.name]» уже идёт: в слоты встают до старта или после итога."
	if(!slot.free_seats())
		return "В слоте «[slot.label]» не осталось мест."
	if(length(current.assigned()) >= current.max_players)
		return "В сценарии «[current.name]» уже [current.max_players] участников, больше не берут."
	var/refusal = antag_training_scenario_slot_refusal(slot.role_id, slot.program_type)
	if(refusal)
		return refusal
	if(!antag_training_role_compatible(/datum/antag_training_program/free, antag_training_role(slot.role_id)))
		return "Роль слота «[slot.label]» нельзя взять при входе."
	return null

/datum/antag_training_catalog/ui_data(mob/user)
	return list("squads" = antag_training_board_entries(GLOB.antag_training_arenas["shared"], TRUE))

/// «Войти в группу» каталога: проверка до входа, затем обычный вход программой «Снаряжение и бой».
/datum/antag_training_catalog/proc/join_squad(list/params)
	var/atom/entry = entry_ref?.resolve()
	if(QDELETED(entry))
		return FALSE
	var/datum/antag_training_arena/shared = GLOB.antag_training_arenas["shared"]
	var/datum/antag_training_squad/team = (shared && istext(params["squad"])) ? (locate(params["squad"]) in shared.squads) : null
	var/datum/antag_training_scenario_slot/slot = (team?.scenario && istext(params["slot"])) ? (locate(params["slot"]) in team.scenario.slots) : null
	var/refusal
	if(!team)
		refusal = "Этой группы уже нет."
	else if(!isnull(params["slot"]) && !slot)
		refusal = "Такого слота больше нет: лидер сменил сценарий или лист."
	else
		refusal = antag_training_catalog_join_refusal(team, slot)
	if(refusal)
		to_chat(viewer, span_warning(refusal))
		return TRUE
	var/role_id = slot ? slot.role_id : ((istext(params["role"]) && antag_training_role(params["role"])) ? params["role"] : ANTAG_TRAINING_ROLE_DEFAULT)
	var/mob/user = viewer
	qdel(src)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(antag_training_catalog_join), user, entry, params["use_character"] == TRUE, WEAKREF(team), slot ? WEAKREF(slot) : null, role_id)
	return FALSE

/proc/antag_training_catalog_join(mob/user, atom/entry, use_character, datum/weakref/team_ref, datum/weakref/slot_ref, role_id)
	// Вход - спавнер или капсула, begin_training ищется по имени.
	var/obj/effect/mob_spawn/antag_training/spawner = entry
	var/datum/antag_training_session/session = spawner.begin_training(user, /datum/antag_training_program/free, use_character, role_id)
	if(QDELETED(session) || session.finished)
		return null
	session.join_from_catalog(team_ref.resolve(), slot_ref?.resolve(), !!slot_ref)
	return session

/// Пока готовился полигон, слот могли занять, а группу закрыть: проверка повторяется на месте.
/datum/antag_training_session/proc/join_from_catalog(datum/antag_training_squad/team, datum/antag_training_scenario_slot/slot, wanted_slot)
	var/refusal = (wanted_slot && !slot) ? "Такого слота больше нет: лидер сменил сценарий или лист." : antag_training_catalog_join_refusal(team, slot)
	if(!refusal && team.arena != arena)
		refusal = "Этой группы уже нет."
	if(refusal)
		practice_message("[refusal] Вы на полигоне без группы: группы и слоты - во вкладках «Участники» и «Сценарий» пульта.")
		return FALSE
	if(!team.join(src))
		return FALSE
	log_game("Полигон: [key_name(current_body)] входит из каталога в группу «[team.name]»[slot ? ", слот «[slot.label]»" : ""].")
	if(!slot)
		return TRUE
	if(!team.scenario.take_slot(src, slot))
		return FALSE
	practice_message("Вы в слоте «[slot.label]» сценария «[team.scenario.name]». Роль и программу слота вы получите, когда лидер нажмёт «Старт».")
	return TRUE

/// Доска групп и сценариев в вестибюле: то же, что вкладки «Участники» и «Сценарий» пульта. Призраки смотрят, не меняя.
/obj/structure/sign/antag_training_board/squads
	name = "squad board"
	desc = "Доска групп и сценариев хаба: собрать группу или войти в открытую, выбрать шаблон сценария и занять слот. Призраки видят доску, но ничего на ней не меняют."

/obj/structure/sign/antag_training_board/squads/examine(mob/user)
	. = list("[get_examine_string(user, TRUE)].<hr>", desc)
	var/datum/antag_training_arena/arena = training_arena()
	if(!arena)
		return
	var/open_slots = 0
	for(var/datum/antag_training_squad/team as anything in arena.squads)
		for(var/datum/antag_training_scenario_slot/slot as anything in team.scenario?.slots)
			if(!antag_training_catalog_join_refusal(team, slot))
				open_slots += slot.free_seats()
	. += span_notice("Групп на полигоне: [length(arena.squads)]. Свободных мест в слотах открытых групп: [open_slots].")
	if(session_for(user))
		. += span_notice("Нажмите на доску, чтобы открыть группы и сценарии.")

/obj/structure/sign/antag_training_board/squads/proc/session_for(mob/user)
	var/datum/antag_training_arena/arena = training_arena()
	var/datum/antag_training_session/session = arena?.session_of(user)
	return session?.can_control(user) ? session : null

/obj/structure/sign/antag_training_board/squads/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	if(!session_for(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/structure/sign/antag_training_board/squads/attack_ai(mob/user)
	if(!session_for(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/structure/sign/antag_training_board/squads/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AntagTrainingBoard", "Доска групп и сценариев")
		ui.open()

/obj/structure/sign/antag_training_board/squads/ui_status(mob/user, datum/ui_state/state)
	if(isobserver(user))
		return UI_UPDATE
	if(!session_for(user))
		return UI_CLOSE
	return ..()

/obj/structure/sign/antag_training_board/squads/ui_static_data(mob/user)
	var/list/programs = list()
	var/list/sector_names = antag_training_sector_names()
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		if(antag_training_program_selectable(program_type))
			programs += list(antag_training_program_entry(program_type, sector_names))
	return list("roles" = antag_training_role_entries(), "programs" = programs)

/obj/structure/sign/antag_training_board/squads/ui_data(mob/user)
	var/datum/antag_training_arena/arena = training_arena()
	var/datum/antag_training_session/session = session_for(user)
	var/list/data = list("participant" = !!session)
	if(!session)
		data["board"] = antag_training_board_entries(arena)
		return data
	session.squad_ui_data(data)
	session.pads_ui_data(data)
	session.scenario_ui_data(data)
	var/list/members = list()
	for(var/datum/antag_training_session/member as anything in arena.members)
		members += list(list("id" = REF(member), "name" = member.squad_name(), "self" = member == session, "connected" = !!member.current_body?.client))
	data["members"] = members
	var/list/sectors = list()
	for(var/sector_id in arena.sectors)
		var/datum/antag_training_sector/sector = arena.sectors[sector_id]
		sectors += list(list("id" = sector_id, "name" = sector.name))
	data["sectors"] = sectors
	return data

/obj/structure/sign/antag_training_board/squads/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/datum/antag_training_session/session = session_for(usr)
	if(!session || world.time < session.next_action_at || session.arena.resetting)
		return FALSE
	for(var/param in list("id", "slot", "member"))
		if(!isnull(params[param]) && !istext(params[param]))
			return FALSE
	if(action in GLOB.antag_training_squad_actions)
		session.next_action_at = world.time + 0.5 SECONDS
		return session.squad_act(action, params)
	if(action in GLOB.antag_training_scenario_actions)
		session.next_action_at = world.time + 0.5 SECONDS
		return session.scenario_intercepts(action, params)
	return FALSE

/// Скрытая камера обзора: сектора и площадки без своих камер показываются на трибуне через неё.
/obj/machinery/camera/training/tribune
	name = "tribune camera"
	desc = "Скрытая камера обзора: её картинку показывают экраны трибуны хаба."
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	use_power = NO_POWER_USE
	invuln = TRUE
	internal_light = FALSE
	start_active = TRUE

/obj/machinery/camera/training/tribune/emp_act(severity)
	return

/// Камеры обзора в точках fractions (доли ширины и высоты), если в границах ещё нет ни одной учебной камеры.
/proc/antag_training_add_tribune_cameras(datum/antag_training_arena/arena, list/bounds, place_name, list/fractions)
	if(!arena?.private_level || arena.finished || !bounds)
		return 0
	var/list/network_cameras = GLOB.cameranet.get_cameras_by_network("training")
	for(var/tag in network_cameras)
		var/obj/machinery/camera/camera = network_cameras[tag]
		if(!QDELETED(camera) && arena.inside_bounds(get_turf(camera), bounds))
			return 0
	var/placed = 0
	var/previous_usr = usr
	usr = null
	for(var/list/point as anything in fractions)
		var/turf/target = locate(bounds[1] + round((bounds[2] - bounds[1]) * point[1]), bounds[3] + round((bounds[4] - bounds[3]) * point[2]), arena.private_level.z_value)
		var/turf/spot = arena.free_spot(target, bounds)
		if(!spot)
			continue
		var/obj/machinery/camera/training/tribune/camera = new(spot)
		placed++
		camera.c_tag = "[place_name]: обзор [placed]"
	usr = previous_usr
	GLOB.cameranet.invalidate_camera_cache()
	return placed

/datum/antag_training_sector/proc/add_tribune_cameras(datum/antag_training_arena/owner)
	antag_training_add_tribune_cameras(owner, bounds, name, list(list(0.5, 0.5), list(0.25, 0.25), list(0.75, 0.25), list(0.25, 0.75), list(0.75, 0.75)))

/datum/antag_training_hub_pad/proc/add_tribune_cameras()
	antag_training_add_tribune_cameras(arena, bounds, name, list(list(0.5, 0.5), list(0.2, 0.2), list(0.8, 0.8)))

/// Экран трибуны: камеры забронированных секторов и занятых площадок, место выбирают на самом экране.
/obj/machinery/computer/security/telescreen/antag_training
	name = "tribune screen"
	desc = "Экран трибуны хаба: камеры забронированных секторов и занятых площадок. Участник выбирает, за кем смотреть, хоть с дивана, призраки смотрят то же, не переключая; станционная сеть сюда не выводится."
	icon = 'icons/obj/status_display.dmi'
	icon_state = "entertainment_blank"
	icon_screen = null
	pixel_y = 32
	network = list("training")
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// id сектора или площадки, за которой смотрит экран.
	var/venue_id
	/// Камера, чьё удаление ждёт экран: сброс сектора убирает её вместе с обстановкой.
	var/obj/machinery/camera/watched

/obj/machinery/computer/security/telescreen/antag_training/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_CLICK, PROC_REF(on_click))

/obj/machinery/computer/security/telescreen/antag_training/Destroy()
	UnregisterSignal(src, COMSIG_CLICK)
	set_camera(null)
	return ..()

/obj/machinery/computer/security/telescreen/antag_training/proc/set_camera(obj/machinery/camera/camera)
	if(watched)
		UnregisterSignal(watched, COMSIG_PARENT_QDELETING)
	watched = camera
	active_camera = camera
	if(camera)
		RegisterSignal(camera, COMSIG_PARENT_QDELETING, PROC_REF(camera_gone))

/obj/machinery/computer/security/telescreen/antag_training/proc/camera_gone(datum/source)
	SIGNAL_HANDLER
	watched = null
	if(active_camera == source)
		active_camera = null
		show_camera_static()

/obj/machinery/computer/security/telescreen/antag_training/update_icon_state()
	. = ..()
	icon_state = venue_id ? "entertainment" : "entertainment_blank"

/// Экран над рядами диванов: нажатие издалека открывает его, как у развлекательного монитора.
/obj/machinery/computer/security/telescreen/antag_training/proc/on_click(datum/source, location, control, params, mob/user)
	SIGNAL_HANDLER
	if(!isobserver(user) && ui_status(user) == UI_INTERACTIVE)
		INVOKE_ASYNC(src, TYPE_PROC_REF(/datum, ui_interact), user)

/obj/machinery/computer/security/telescreen/antag_training/ui_state(mob/user)
	return GLOB.always_state

/// Призраки, и админские тоже, только смотрят: экран один на всех зрителей трибуны.
/obj/machinery/computer/security/telescreen/antag_training/ui_status(mob/user, datum/ui_state/state)
	if(isobserver(user))
		return UI_UPDATE
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/datum/antag_training_session/session = arena?.session_of(user)
	if(session?.can_control(user) && user.z == z && get_dist(user, src) <= ANTAG_TRAINING_TRIBUNE_RANGE)
		return UI_INTERACTIVE
	return UI_CLOSE

/obj/machinery/computer/security/telescreen/antag_training/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	update_active_camera_screen()
	if(ui || !user.client)
		return
	if(isliving(user))
		concurrent_users += REF(user)
	user.client.register_map_obj(cam_screen)
	if(!cam_plane_group)
		cam_plane_group = new /datum/plane_master_group/popup(PLANE_GROUP_POPUP_WINDOW(src), map_name)
	for(var/plane_key in cam_plane_group.plane_masters)
		var/atom/movable/screen/plane_master/plane = cam_plane_group.plane_masters[plane_key]
		plane.refresh_backdrop(user)
	cam_plane_group.register_to_client(user.client)
	user.client.register_map_obj(cam_background)
	ui = new(user, src, "AntagTrainingTribune", name)
	ui.open()

/// id места -> list(запись для окна, границы).
/obj/machinery/computer/security/telescreen/antag_training/proc/venues()
	. = list()
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	if(!arena || arena.finished)
		return
	for(var/sector_id in arena.sectors)
		var/datum/antag_training_sector/sector = arena.sectors[sector_id]
		if(!sector.booked_by || sector.state != ANTAG_TRAINING_SECTOR_READY || !sector.bounds)
			continue
		var/datum/antag_training_scenario/current = sector.booked_by.scenario
		var/scenario_name = (current?.venue?.id() == sector.id) ? current.name : null
		.[sector.id] = list(list("id" = sector.id, "name" = sector.name, "kind" = "sector", "holder" = "группа «[sector.booked_by.name]»", "scenario" = scenario_name), sector.bounds)
	for(var/datum/antag_training_hub_pad/pad as anything in arena.hub?.pads)
		if(!pad.ready() || !pad.bounds || (!pad.owner && !pad.owner_squad))
			continue
		.[pad.id] = list(list("id" = pad.id, "name" = pad.name, "kind" = "pad", "holder" = pad.holder_name(), "scenario" = pad.scenario_running() ? pad.owner_squad.scenario.name : null), pad.bounds)

/obj/machinery/computer/security/telescreen/antag_training/get_available_cameras()
	. = list()
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/list/place = venue_id ? venues()[venue_id] : null
	if(!place)
		return
	var/list/network_cameras = GLOB.cameranet.get_cameras_by_network("training")
	for(var/tag in network_cameras)
		var/obj/machinery/camera/camera = network_cameras[tag]
		if(!QDELETED(camera) && antag_training_camera_visible(camera, src) && arena.inside_bounds(get_turf(camera), place[2]))
			.[tag] = camera

/obj/machinery/computer/security/telescreen/antag_training/ui_static_data(mob/user)
	return list("mapRef" = map_name)

/obj/machinery/computer/security/telescreen/antag_training/ui_data(mob/user)
	var/list/places = venues()
	var/list/venue_entries = list()
	for(var/place_id in places)
		venue_entries += list(places[place_id][1])
	var/list/cameras = get_available_cameras()
	var/list/camera_entries = list()
	for(var/tag in cameras)
		camera_entries += list(list("name" = tag))
	var/list/data = list("venues" = venue_entries, "venue" = places[venue_id] ? venue_id : null, "cameras" = camera_entries, "activeCamera" = null)
	if(active_camera && cameras["[active_camera.c_tag]"] == active_camera)
		data["activeCamera"] = list("name" = active_camera.c_tag, "status" = active_camera.status)
	return data

/obj/machinery/computer/security/telescreen/antag_training/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(ui_status(usr) != UI_INTERACTIVE)
		return FALSE
	// Переключение камер родителя ищет по всей сети, а не по месту трибуны: ему уходит только отметка о действии.
	if(..("tribune_[action]", params, ui, state))
		return TRUE
	switch(action)
		if("select_venue")
			if(!istext(params["id"]) || !venues()[params["id"]])
				return FALSE
			venue_id = params["id"]
			var/list/cameras = get_available_cameras()
			set_camera(length(cameras) ? cameras[cameras[1]] : null)
		if("switch_camera")
			var/list/cameras = get_available_cameras()
			var/obj/machinery/camera/selected = istext(params["name"]) ? cameras[params["name"]] : null
			if(!selected)
				return FALSE
			set_camera(selected)
		else
			return FALSE
	playsound(src, get_sfx("terminal_type"), 25, FALSE)
	update_active_camera_screen()
	update_appearance()
	return TRUE

#undef ANTAG_TRAINING_TRIBUNE_RANGE
