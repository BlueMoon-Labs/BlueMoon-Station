GLOBAL_LIST_INIT(antag_training_pad_presets, list(
	"brig" = list("name" = "Бриг", "desc" = "Приёмная, допросная, три камеры и оружейная с учебным оружием. Камеры и оружейная открываются по ID службы безопасности.", "programs" = list(/datum/antag_training_program/antag/crew/fugitive, /datum/antag_training_program/antag/crew/hunter)),
	"medbay" = list("name" = "Медотсек", "desc" = "Приёмная, палата со слипером и стазисом, химия, хирургия, крио и морг.", "programs" = list(/datum/antag_training_program/creature/blob, /datum/antag_training_program/antag/changeling, /datum/antag_training_program/antag/zombie)),
	"bar" = list("name" = "Бар", "desc" = "Зал со столиками и диванами, стойка с раздатчиками, кухня и кладовая.", "programs" = list(/datum/antag_training_program/antag/devil, /datum/antag_training_program/antag/gang)),
	"bridge" = list("name" = "Мостик", "desc" = "Пульты глав и стол совещаний, кабинет капитана и переговорная. Пульты учебные.", "programs" = list(/datum/antag_training_program/antag/revolution, /datum/antag_training_program/antag/traitor)),
	"vault" = list("name" = "Хранилище", "desc" = "Пост охраны, сейфовая с золотом и деньгами, ячейки и архив за дверями с доступом.", "programs" = list(/datum/antag_training_program/antag/traitor, /datum/antag_training_program/antag/ninja, /datum/antag_training_program/antag/crew/pirate, /datum/antag_training_program/antag/crew/raider, /datum/antag_training_program/antag/crew/vox)),
	"maint" = list("name" = "Техи", "desc" = "Техтоннели с мастерской, щитовой, свалкой и чьей-то норой. Тесно, темно, трубы наружу.", "programs" = list(/datum/antag_training_program/creature/morph, /datum/antag_training_program/antag/bloodsucker, /datum/antag_training_program/creature/xeno, /datum/antag_training_program/creature/terror_spider)),
	"debris" = list("name" = "Обломок в космосе", "desc" = "Шлюз со скафандрами и обломок грузового бота в вакууме и невесомости.", "programs" = list(/datum/antag_training_program/antag/crew/pirate, /datum/antag_training_program/antag/crew/raider, /datum/antag_training_program/antag/crew/vox, /datum/antag_training_program/antag/crew/warmonger, /datum/antag_training_program/creature/swarmer)),
	"maze" = list("name" = "Лабиринт", "desc" = "Узкие коридоры, три ложные стены и ящик с наградой в центре.", "programs" = list(/datum/antag_training_program/antag/hatred, /datum/antag_training_program/antag/wizard)),
	"build" = list("name" = "Пустой зал под стройку", "desc" = "Размеченная площадь под стройку, материалы и инструменты у стены.", "programs" = list(/datum/antag_training_program/heretic, /datum/antag_training_program/antag/cult, /datum/antag_training_program/antag/clockcult, /datum/antag_training_program/creature/swarmer, /datum/antag_training_program/creature/xeno)),
))
GLOBAL_LIST_INIT(antag_training_pad_actions, list("pad_claim", "pad_release", "pad_open", "pad_preset", "pad_reload", "pad_vote"))

/proc/antag_training_pad_map(preset_id)
	return "_maps/templates/antag_training/pads/[preset_id].dmm"

/proc/antag_training_pad_preset_name(preset_id)
	if(preset_id == ANTAG_TRAINING_HUB_PAD_BARE)
		return "Пустая площадка"
	return GLOB.antag_training_pad_presets[preset_id]?["name"]

/proc/antag_training_pad_preset_entries()
	var/static/list/entries
	if(!entries)
		entries = list()
		for(var/preset_id in GLOB.antag_training_pad_presets)
			entries += list(list("id" = preset_id, "name" = GLOB.antag_training_pad_presets[preset_id]["name"], "desc" = GLOB.antag_training_pad_presets[preset_id]["desc"], "programs" = antag_training_preset_program_names(preset_id), "scenarios" = antag_training_venue_scenario_names(null, preset_id)))
	return entries

/// Программы, чьи способности удобно тренировать на этом пресете.
/proc/antag_training_preset_program_names(preset_id)
	. = list()
	var/list/preset = GLOB.antag_training_pad_presets[preset_id]
	for(var/datum/antag_training_program/program_type as anything in preset?["programs"])
		. += initial(program_type.name)

/datum/antag_training_hub
	var/list/datum/antag_training_hub_pad/pads = list()

/datum/antag_training_hub/proc/create_pads()
	var/list/area_types = list(/area/antag_training/hub/pad/one, /area/antag_training/hub/pad/two, /area/antag_training/hub/pad/three, /area/antag_training/hub/pad/four)
	for(var/index in 1 to ANTAG_TRAINING_HUB_PADS)
		pads += new /datum/antag_training_hub_pad(src, index, area_types[index])

/// Площадка по id ("pad_2") или номеру; null - такой нет.
/datum/antag_training_hub/proc/pad_by_id(pad_id)
	RETURN_TYPE(/datum/antag_training_hub_pad)
	if(isnum(pad_id))
		return (pad_id == round(pad_id) && pad_id >= 1 && pad_id <= length(pads)) ? pads[pad_id] : null
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		if(pad.id == pad_id)
			return pad
	return null

/// Площадка участника или его группы.
/datum/antag_training_hub/proc/pad_of(datum/antag_training_session/session)
	RETURN_TYPE(/datum/antag_training_hub_pad)
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		if(pad.manages(session))
			return pad
	return null

/datum/antag_training_hub/proc/squad_pad(datum/antag_training_squad/squad)
	RETURN_TYPE(/datum/antag_training_hub_pad)
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		if(squad && pad.owner_squad == squad)
			return pad
	return null

/datum/antag_training_hub/proc/pad_at(turf/tile)
	RETURN_TYPE(/datum/antag_training_hub_pad)
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		if(pad.contains(tile))
			return pad
	return null

/// Площадка как зона учебных целей, в формате зон арены. В закрытую ставит только её владелец, в идущую партию - сама партия и стенд.
/datum/antag_training_hub/proc/pad_zone(zone_id, datum/antag_training_session/creator)
	var/datum/antag_training_hub_pad/pad = istext(zone_id) ? pad_by_id(zone_id) : null
	if(!pad?.ready())
		return null
	if(creator && pad.scenario_running())
		if(!creator.stand_active() && (!pad.manages(creator) || pad.owner_squad.scenario.target_refusal(creator)))
			return null
	else if(creator && !pad.allows(creator))
		return null
	return list("name" = pad.name, "bounds" = pad.bounds, "target" = pad.center_turf())

/datum/antag_training_hub/proc/attach_pads()
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		pad.attach()

/datum/antag_training_hub/proc/detach_pads()
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		pad.detach()

/datum/antag_training_hub/proc/check_pads()
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		pad.check_idle()

/datum/antag_training_hub/proc/pads_busy()
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		if(pad.loading)
			return TRUE
	return FALSE

/datum/antag_training_hub/proc/pads_summary()
	var/list/lines = list()
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		lines += "[pad.index] - [pad.status_text()]"
	return lines.Join("; ")

/// Площадка хаба 15x15: владелец - участник или его группа, пресет комнаты из библиотеки, вход открыт или только своим.
/datum/antag_training_hub_pad
	var/id
	var/index
	var/name
	var/area_type
	var/datum/antag_training_hub/hub
	var/datum/antag_training_arena/arena
	var/list/turf/turfs = list()
	/// list(x1, x2, y1, y2) на z арены.
	var/list/bounds
	var/datum/antag_training_session/owner
	var/datum/antag_training_squad/owner_squad
	var/open = TRUE
	var/preset_id = ANTAG_TRAINING_HUB_PAD_BARE
	var/loading = FALSE
	var/last_active_at = 0
	/// Слабая ссылка на сеанс -> согласие загрузить pending_preset.
	var/list/votes = list()
	var/vote_deadline = 0
	var/vote_timer
	var/pending_preset
	/// Ключ стороны -> list(смещение от угла площадки) из меток пресета.
	var/list/side_offsets = list()
	var/list/mark_offsets = list()
	var/list/obj/structure/antag_training_pad_panel/panels = list()
	var/next_warning_at = 0

/datum/antag_training_hub_pad/New(datum/antag_training_hub/owner_hub, pad_index, pad_area)
	hub = owner_hub
	arena = hub.arena
	index = pad_index
	id = "pad_[index]"
	name = "Площадка [index]"
	area_type = pad_area

/datum/antag_training_hub_pad/Destroy()
	detach()
	panels.Cut()
	hub = null
	arena = null
	return ..()

/// Клетки своей области после загрузки слота площадок.
/datum/antag_training_hub_pad/proc/attach()
	turfs = list()
	bounds = null
	var/area/place = GLOB.areas_by_type[area_type]
	for(var/turf/tile as anything in hub.turfs)
		if(tile.loc != place)
			continue
		turfs += tile
		if(!bounds)
			bounds = list(tile.x, tile.x, tile.y, tile.y)
		bounds[1] = min(bounds[1], tile.x)
		bounds[2] = max(bounds[2], tile.x)
		bounds[3] = min(bounds[3], tile.y)
		bounds[4] = max(bounds[4], tile.y)
	preset_id = ANTAG_TRAINING_HUB_PAD_BARE
	side_offsets = list()
	mark_offsets = list()
	add_tribune_cameras()
	update_state()

/datum/antag_training_hub_pad/proc/detach()
	cancel_vote()
	drop_owner()
	open = TRUE
	turfs = list()
	bounds = null

/datum/antag_training_hub_pad/proc/ready()
	return !loading && length(turfs) && hub?.station_state == ANTAG_TRAINING_SECTOR_READY && !arena?.finished

/datum/antag_training_hub_pad/proc/contains(atom/thing)
	return bounds && arena?.inside_bounds(get_turf(thing), bounds)

/datum/antag_training_hub_pad/proc/level()
	return arena.private_level.z_value

/datum/antag_training_hub_pad/proc/corner_turf()
	return locate(bounds[1], bounds[3], level())

/datum/antag_training_hub_pad/proc/center_turf()
	return locate(round((bounds[1] + bounds[2]) / 2), round((bounds[3] + bounds[4]) / 2), level())

/// Клетка галереи напротив входа: сюда выходят выселенные и те, кто был внутри при перезагрузке.
/datum/antag_training_hub_pad/proc/gallery_turf()
	return locate(bounds[1] + 7, bounds[3] - 2, level())

/datum/antag_training_hub_pad/proc/door_turf()
	return locate(bounds[1] + 7, bounds[3] - 1, level())

/// В галерею напротив входа; брошенный ветром или рукой не долетает по старой траектории.
/datum/antag_training_hub_pad/proc/evict(datum/antag_training_session/member, message)
	var/mob/body = member.current_body
	body.throwing?.finalize(FALSE)
	body.forceMove(gallery_turf())
	to_chat(body, span_notice(message))

/datum/antag_training_hub_pad/proc/holder_name()
	if(owner_squad)
		return "группа «[owner_squad.name]»"
	return owner?.squad_name()

/datum/antag_training_hub_pad/proc/manages(datum/antag_training_session/session)
	return !!session && (session == owner || (owner_squad && session.squad == owner_squad))

/datum/antag_training_hub_pad/proc/allows(datum/antag_training_session/session)
	return !entry_refusal(session)

/// Почему сеанс не пускают на площадку, или null. Пока идёт сценарий, входят только участники партии и стенд.
/datum/antag_training_hub_pad/proc/entry_refusal(datum/antag_training_session/session)
	if(scenario_running())
		return session?.stand_active() ? null : owner_squad.scenario.entry_refusal(session)
	if(open || manages(session))
		return null
	return "[name] закрыта: внутрь пускают только [holder_name()]."

/datum/antag_training_hub_pad/proc/occupants()
	. = list()
	if(!bounds)
		return
	for(var/datum/antag_training_session/member as anything in arena.members)
		if(member.current_body && arena.inside_bounds(get_turf(member.current_body), bounds))
			. += member

/datum/antag_training_hub_pad/proc/owner_present()
	for(var/datum/antag_training_session/member as anything in occupants())
		if(manages(member))
			return TRUE
	return FALSE

/datum/antag_training_hub_pad/proc/scenario_running()
	var/datum/antag_training_scenario/current = owner_squad?.scenario
	return current && current.venue?.id() == id && current.in_play()

/datum/antag_training_hub_pad/proc/touch()
	last_active_at = world.time

/datum/antag_training_hub_pad/proc/notify_owners(message)
	if(owner_squad)
		owner_squad.announce(message)
	else if(owner)
		to_chat(owner.current_body, span_notice(message))

/datum/antag_training_hub_pad/proc/claim_refusal(datum/antag_training_session/session)
	if(!ready())
		return loading ? "[name] загружается, подождите несколько секунд." : "Площадки хаба ещё не готовы: они загружаются, когда на полигон входит игрок."
	if(owner || owner_squad)
		return "[name] занята: [holder_name()]."
	var/datum/antag_training_hub_pad/held = hub.pad_of(session)
	if(held)
		return "У [session.squad ? "вашей группы" : "вас"] уже есть [held.name]. Освободите её, чтобы занять другую."
	return null

/// Занимает площадку для сеанса, а если он в группе - для группы.
/datum/antag_training_hub_pad/proc/claim(datum/antag_training_session/session)
	if(!session || session.finished || !(session in arena?.members))
		return FALSE
	if(manages(session))
		return TRUE
	var/refusal = claim_refusal(session)
	if(refusal)
		session.practice_message(refusal)
		return FALSE
	if(session.squad)
		owner_squad = session.squad
		RegisterSignal(owner_squad, COMSIG_PARENT_QDELETING, PROC_REF(owner_gone))
	else
		owner = session
		RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(owner_gone))
	open = TRUE
	touch()
	log_game("Полигон: [key_name(session.current_body)] занимает [name], владелец - [holder_name()].")
	notify_owners("[name] теперь [owner_squad ? "у группы «[owner_squad.name]»" : "ваша"]. Пресет комнаты, вход для остальных и освобождение - на пульте у входа и во вкладке «Площадки» пульта полигона. Если на площадке не будет никого из владельцев и пультом её не тронут [ANTAG_TRAINING_HUB_PAD_IDLE / (1 MINUTES)] минут, она освободится сама.")
	update_state()
	return TRUE

/datum/antag_training_hub_pad/proc/owner_gone(datum/source)
	SIGNAL_HANDLER
	release(source == owner_squad ? "Группа распущена, [name] освобождена." : null)

/datum/antag_training_hub_pad/proc/drop_owner()
	if(owner)
		UnregisterSignal(owner, COMSIG_PARENT_QDELETING)
	if(owner_squad)
		UnregisterSignal(owner_squad, COMSIG_PARENT_QDELETING)
	owner = null
	owner_squad = null

/// Снимает владельца и возвращает пустую площадку. Не спит.
/datum/antag_training_hub_pad/proc/release(reason)
	if(!owner && !owner_squad)
		return FALSE
	if(reason)
		notify_owners(reason)
	log_game("Полигон: [name] освобождена, владелец был [holder_name()].")
	drop_owner()
	open = TRUE
	cancel_vote()
	if(preset_id != ANTAG_TRAINING_HUB_PAD_BARE && ready())
		INVOKE_ASYNC(src, PROC_REF(load_preset), ANTAG_TRAINING_HUB_PAD_BARE)
	update_state()
	return TRUE

/datum/antag_training_hub_pad/proc/request_release(datum/antag_training_session/session)
	if(!manages(session))
		session.practice_message("Освободить [name] может её владелец.")
		return FALSE
	if(scenario_running())
		session.practice_message("На [name] идёт сценарий «[owner_squad.scenario.name]»: сначала завершите его.")
		return FALSE
	return release("[session.squad_name()] освобождает [name].")

/datum/antag_training_hub_pad/proc/set_open(datum/antag_training_session/session, value)
	if(!manages(session))
		session.practice_message("Открыть или закрыть [name] может её владелец.")
		return FALSE
	open = !!value
	touch()
	if(!open)
		for(var/datum/antag_training_session/member as anything in occupants())
			if(!manages(member))
				evict(member, "[name] закрыта владельцем: вы в галерее.")
	update_state()
	return TRUE

/// Сменить пресет или загрузить его заново: с согласия всех участников внутри, одному хватает своего нажатия.
/datum/antag_training_hub_pad/proc/request_load(datum/antag_training_session/session, new_preset)
	if(!ready())
		session.practice_message(loading ? "[name] уже загружается." : "[name] сейчас недоступна.")
		return FALSE
	if(scenario_running())
		session.practice_message("На [name] идёт сценарий «[owner_squad.scenario.name]»: пресет меняется после итога.")
		return FALSE
	var/target_preset = new_preset || preset_id
	if(target_preset != ANTAG_TRAINING_HUB_PAD_BARE && !GLOB.antag_training_pad_presets[target_preset])
		return FALSE
	var/list/inside = occupants()
	if(!manages(session) && (target_preset != preset_id || !(session in inside)))
		session.practice_message(target_preset != preset_id ? "Пресет для [name] выбирает её владелец." : "Перезагрузку [name] просят владелец или те, кто внутри.")
		return FALSE
	if(manages(session))
		touch()
	if(world.time < vote_deadline && pending_preset == target_preset && !isnull(votes[WEAKREF(session)]))
		return approve(session)
	cancel_vote()
	pending_preset = target_preset
	for(var/datum/antag_training_session/member as anything in inside | session)
		votes[WEAKREF(member)] = member == session
	vote_deadline = world.time + ANTAG_TRAINING_VOTE_TIME
	vote_timer = addtimer(CALLBACK(src, PROC_REF(cancel_vote)), ANTAG_TRAINING_VOTE_TIME, TIMER_STOPPABLE)
	var/what = target_preset == preset_id ? "перезагрузить [name]" : "загрузить на [name] пресет «[antag_training_pad_preset_name(target_preset)]»"
	for(var/datum/antag_training_session/member as anything in inside)
		if(member != session)
			to_chat(member.current_body, span_notice("[session.squad_name()] просит [what]. Согласиться - кнопкой во вкладке «Площадки» пульта или на пульте у входа. Нужно согласие всех, кто внутри, за [ANTAG_TRAINING_VOTE_TIME / (1 SECONDS)] с; всех внутри выведут в галерею."))
	if(!check_votes())
		session.practice_message("Запрос отправлен: [what]. Ждём согласия остальных на площадке.")
	return TRUE

/datum/antag_training_hub_pad/proc/approve(datum/antag_training_session/session)
	var/datum/weakref/voter_ref = WEAKREF(session)
	if(world.time >= vote_deadline || isnull(votes[voter_ref]))
		return FALSE
	if(votes[voter_ref])
		session.practice_message("Вы уже согласились. Ждём остальных на площадке.")
		return TRUE
	votes[voter_ref] = TRUE
	check_votes()
	return TRUE

/// Все голосующие, кто ещё внутри или владеет площадкой, согласны: пресет грузится. Ушедшие гости голосование не держат.
/datum/antag_training_hub_pad/proc/check_votes()
	if(!length(votes) || world.time >= vote_deadline || loading)
		return FALSE
	var/list/inside = occupants()
	for(var/datum/weakref/voter_ref as anything in votes)
		var/datum/antag_training_session/voter = voter_ref.resolve()
		if(voter && !votes[voter_ref] && ((voter in inside) || manages(voter)))
			return FALSE
	var/target_preset = pending_preset
	cancel_vote()
	INVOKE_ASYNC(src, PROC_REF(load_preset), target_preset)
	return TRUE

/datum/antag_training_hub_pad/proc/vote_progress()
	var/approved = 0
	var/total = 0
	var/list/inside = occupants()
	for(var/datum/weakref/voter_ref as anything in votes)
		var/datum/antag_training_session/voter = voter_ref.resolve()
		if(!voter || (!(voter in inside) && !manages(voter)))
			continue
		total++
		if(votes[voter_ref])
			approved++
	return list(approved, total)

/datum/antag_training_hub_pad/proc/cancel_vote()
	deltimer(vote_timer)
	vote_timer = null
	vote_deadline = 0
	votes = list()
	pending_preset = null

/// Чистит площадку и грузит пресет; спит. Участников внутри выводит в галерею, созданное на площадке убирает.
/datum/antag_training_hub_pad/proc/load_preset(target_preset)
	if(loading || !ready() || (target_preset != ANTAG_TRAINING_HUB_PAD_BARE && !GLOB.antag_training_pad_presets[target_preset]))
		return FALSE
	var/datum/antag_training_arena/owner_arena = arena
	loading = TRUE
	cancel_vote()
	update_state()
	for(var/datum/antag_training_session/member as anything in occupants())
		evict(member, "[name] перезагружается: вы в галерее.")
	hub.drop_networks(turfs)
	for(var/turf/tile as anything in turfs)
		owner_arena.clear_tile(tile, TRUE)
		owner_arena.yield_work()
	if(QDELETED(src))
		return FALSE
	if(owner_arena.finished || !length(turfs))
		loading = FALSE
		return FALSE
	var/datum/map_template/template = antag_training_map_template(antag_training_pad_map(target_preset), antag_training_pad_preset_name(target_preset))
	usr = null
	var/placed = template.load(corner_turf())
	if(QDELETED(src))
		return FALSE
	if(!placed || owner_arena.finished)
		loading = FALSE
		update_state()
		return FALSE
	// Воздух сразу на всей площадке: при раздаче с паузами между клетками ветер разносит обстановку.
	for(var/turf/open/floor in turfs)
		if(!isspaceturf(floor))
			floor.air.copy_from_turf(floor)
			floor.air_update_turf(FALSE, FALSE)
	collect_marks()
	hub.settle(turfs)
	add_tribune_cameras()
	var/area/antag_training/hub/place = GLOB.areas_by_type[area_type]
	place?.reset_state()
	owner_arena.prune_targets()
	preset_id = target_preset
	loading = FALSE
	log_game("Полигон: на [name] загружен пресет «[antag_training_pad_preset_name(preset_id)]».")
	update_state()
	return TRUE

/// Метки сторон и места пресета считаются от угла площадки: на четырёх площадках один пресет даёт разные клетки.
/datum/antag_training_hub_pad/proc/collect_marks()
	side_offsets = list()
	mark_offsets = list()
	for(var/turf/tile as anything in turfs)
		for(var/obj/effect/landmark/antag_training/mark in tile)
			var/list/offset = list(tile.x - bounds[1], tile.y - bounds[3])
			var/obj/effect/landmark/antag_training/side/side_mark = mark
			if(istype(side_mark) && side_mark.side)
				if(!side_offsets[side_mark.side])
					side_offsets[side_mark.side] = list()
				side_offsets[side_mark.side] += list(offset)
			else if(mark.mark_id)
				mark_offsets[mark.mark_id] = offset
			qdel(mark)

/datum/antag_training_hub_pad/proc/offset_turf(list/offset)
	return locate(bounds[1] + offset[1], bounds[3] + offset[2], level())

/datum/antag_training_hub_pad/proc/check_idle()
	if(loading || (!owner && !owner_squad))
		return
	if(owner_present() || scenario_running())
		touch()
		return
	if(world.time >= last_active_at + ANTAG_TRAINING_HUB_PAD_IDLE)
		release("[name] освобождена: [ANTAG_TRAINING_HUB_PAD_IDLE / (1 MINUTES)] минут на ней не было владельцев и действий с пульта.")

/datum/antag_training_hub_pad/proc/idle_remaining()
	return max(0, last_active_at + ANTAG_TRAINING_HUB_PAD_IDLE - world.time)

/datum/antag_training_hub_pad/proc/status_text()
	if(!ready())
		return loading ? "загружается" : "не загружена"
	var/preset_text = "пресет «[antag_training_pad_preset_name(preset_id)]»"
	if(!owner && !owner_squad)
		return "свободна, [preset_text]"
	if(scenario_running())
		return "занята: [holder_name()], идёт сценарий «[owner_squad.scenario.name]»"
	return "занята: [holder_name()], [preset_text], [open ? "открыта для всех" : "только для владельцев"], без владельцев освободится через [antag_training_clock(idle_remaining())]"

/datum/antag_training_hub_pad/proc/update_state()
	for(var/obj/structure/antag_training_pad_panel/panel as anything in panels)
		panel.update_appearance()
	if(!bounds)
		return
	var/obj/structure/antag_training_barrier/hub/pad/door = locate() in door_turf()
	door?.update_appearance()

/datum/antag_training_hub_pad/proc/ui_entry(datum/antag_training_session/viewer)
	var/list/entry = list("id" = id, "name" = name, "preset" = preset_id, "preset_name" = antag_training_pad_preset_name(preset_id), "owner" = holder_name(), "squad" = !!owner_squad, "mine" = manages(viewer), "open" = open, "can_enter" = allows(viewer), "loading" = loading, "ready" = !!ready(), "inside" = length(occupants()))
	entry["scenario"] = scenario_running() ? owner_squad.scenario.name : null
	entry["idle_remaining"] = (owner || owner_squad) ? round(idle_remaining() / (1 SECONDS)) : null
	entry["vote"] = null
	if(world.time < vote_deadline)
		var/list/progress = vote_progress()
		var/datum/weakref/viewer_ref = WEAKREF(viewer)
		entry["vote"] = list("preset_name" = antag_training_pad_preset_name(pending_preset), "reload" = pending_preset == preset_id, "approved" = progress[1], "total" = progress[2], "remaining" = round((vote_deadline - world.time) / (1 SECONDS)), "voted" = !!votes[viewer_ref], "can_vote" = !isnull(votes[viewer_ref]))
	return entry

/datum/antag_training_session/proc/pads_ui_data(list/data)
	var/datum/antag_training_hub/hub = arena.hub
	data["pads"] = list()
	for(var/datum/antag_training_hub_pad/pad as anything in hub?.pads)
		data["pads"] += list(pad.ui_entry(src))
	data["pad_presets"] = antag_training_pad_preset_entries()
	data["pad_idle_minutes"] = ANTAG_TRAINING_HUB_PAD_IDLE / (1 MINUTES)
	data["pads_ready"] = hub?.station_state == ANTAG_TRAINING_SECTOR_READY
	data["pad_mine"] = hub?.pad_of(src)?.id

/datum/antag_training_session/proc/pad_act(action, list/params)
	var/datum/antag_training_hub_pad/pad = istext(params["id"]) ? arena.hub?.pad_by_id(params["id"]) : null
	if(!pad)
		return FALSE
	switch(action)
		if("pad_claim")
			pad.claim(src)
		if("pad_release")
			pad.request_release(src)
		if("pad_open")
			pad.set_open(src, !pad.open)
		if("pad_preset")
			if(!istext(params["preset"]) || !GLOB.antag_training_pad_presets[params["preset"]])
				return FALSE
			pad.request_load(src, params["preset"])
		if("pad_reload")
			pad.request_load(src, null)
		if("pad_vote")
			pad.approve(src)
	return TRUE

/// Вход на площадку: участник проходит, если площадка открыта или она его, а во время сценария - если он в партии; выйти можно всегда.
/obj/structure/antag_training_barrier/hub/pad
	desc = "Вход на площадку хаба: участники проходят, если площадка открыта для всех или она ваша. Пока на площадке идёт сценарий, внутрь пускают только его участников, выбывшие смотрят партию с трибуны. Снаряды, цели и воздух остаются по свою сторону."

/obj/structure/antag_training_barrier/hub/pad/proc/pad()
	RETURN_TYPE(/datum/antag_training_hub_pad)
	return arena?.hub?.pad_at(get_step(src, NORTH))

/obj/structure/antag_training_barrier/hub/pad/CanPass(atom/movable/mover, turf/target)
	. = ..()
	if(!.)
		return
	var/datum/antag_training_hub_pad/pad = pad()
	if(!pad || pad.contains(mover))
		return TRUE
	var/datum/antag_training_session/session = arena.session_of(mover)
	var/refusal = pad.entry_refusal(session)
	if(!refusal)
		return TRUE
	if(world.time >= pad.next_warning_at)
		pad.next_warning_at = world.time + 2 SECONDS
		to_chat(mover, span_warning(refusal))
	return FALSE

/obj/structure/antag_training_barrier/hub/pad/update_appearance(updates)
	. = ..()
	var/datum/antag_training_hub_pad/pad = pad()
	color = (pad && (pad.scenario_running() || (!pad.open && (pad.owner || pad.owner_squad)))) ? "#ff6a6a" : null

/// Партия на месте закончилась или сорвалась: вход перестаёт быть закрытым для чужих.
/datum/antag_training_venue/proc/phase_changed()
	return

/datum/antag_training_venue/pad/phase_changed()
	place?.update_state()

/obj/structure/antag_training_barrier/hub/pad/examine(mob/user)
	. = ..()
	var/datum/antag_training_hub_pad/pad = pad()
	if(pad)
		. += span_notice("[pad.name]: [pad.status_text()].")

/// Пульт у входа на площадку: состояние на экране, по нажатию - то же окно площадок, что во вкладке пульта полигона.
/obj/structure/antag_training_pad_panel
	name = "pad console"
	desc = "Пульт площадки хаба: кто её занял, какой пресет загружен и каким программам он подходит, пускают ли остальных и когда она освободится. Нажмите, чтобы занять площадку, выбрать пресет, открыть или закрыть вход."
	icon = 'icons/obj/status_display.dmi'
	icon_state = "frame"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_WINDOW_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/pad_index = 1

/obj/structure/antag_training_pad_panel/Initialize(mapload)
	. = ..()
	pad()?.panels += src
	update_appearance()

/obj/structure/antag_training_pad_panel/Destroy()
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	for(var/datum/antag_training_hub_pad/pad as anything in arena?.hub?.pads)
		pad.panels -= src
	return ..()

/obj/structure/antag_training_pad_panel/proc/pad()
	RETURN_TYPE(/datum/antag_training_hub_pad)
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	return arena?.hub?.pad_by_id(pad_index)

/obj/structure/antag_training_pad_panel/update_overlays()
	. = ..()
	var/datum/antag_training_hub_pad/pad = pad()
	var/screen = "lockdown"
	if(pad?.ready())
		screen = (pad.owner || pad.owner_squad) ? (pad.open ? "greenalert" : "redalert") : "bluealert"
	. += mutable_appearance(icon, screen)

/obj/structure/antag_training_pad_panel/examine(mob/user)
	. = ..()
	var/datum/antag_training_hub_pad/pad = pad()
	if(!pad)
		return
	. += span_notice("[pad.name]: [pad.status_text()].")
	if(pad.ready())
		var/list/programs = antag_training_preset_program_names(pad.preset_id)
		var/list/scenarios = antag_training_venue_scenario_names(null, pad.preset_id)
		if(length(programs))
			. += span_notice("Пресет «[antag_training_pad_preset_name(pad.preset_id)]» подходит программам: [programs.Join(", ")].")
		if(length(scenarios))
			. += span_notice("Сценарии на этом пресете: [scenarios.Join(", ")].")
	if(pad.ready() && !pad.owner && !pad.owner_squad)
		. += span_notice("Занять площадку может любой участник, без группы тоже. Одна площадка на игрока или группу; без владельцев она освобождается через [ANTAG_TRAINING_HUB_PAD_IDLE / (1 MINUTES)] минут.")

/obj/structure/antag_training_pad_panel/proc/session_for(mob/user)
	var/datum/antag_training_arena/arena = antag_training_area_arena(src)
	var/datum/antag_training_session/session = arena?.session_of(user)
	return session?.can_control(user) ? session : null

/obj/structure/antag_training_pad_panel/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	if(!session_for(user))
		return ..()
	ui_interact(user)
	return TRUE

/obj/structure/antag_training_pad_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AntagTrainingPads", name)
		ui.open()

/obj/structure/antag_training_pad_panel/ui_data(mob/user)
	var/list/data = list("focus" = pad()?.id)
	var/datum/antag_training_session/session = session_for(user)
	if(session)
		session.pads_ui_data(data)
	return data

/obj/structure/antag_training_pad_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !(action in GLOB.antag_training_pad_actions))
		return
	var/datum/antag_training_session/session = session_for(usr)
	if(!session || world.time < session.next_action_at || session.arena.resetting)
		return FALSE
	session.next_action_at = world.time + 0.5 SECONDS
	return session.pad_act(action, params)

/obj/structure/antag_training_pad_panel/one
	pad_index = 1

/obj/structure/antag_training_pad_panel/two
	pad_index = 2

/obj/structure/antag_training_pad_panel/three
	pad_index = 3

/obj/structure/antag_training_pad_panel/four
	pad_index = 4
