/obj/item/forbidden_book
	name = "Кодекс Рубцов"
	desc = "Страницы покрыты рубцами вместо строк. Между ними проступают имена, ритуалы и дороги в Мансус."
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	icon_state = "codex"
	item_state = "codex"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/drawing = FALSE
	var/knowledge_state_key
	var/list/cached_knowledge_state
	var/datum/weakref/book_reader
	var/datum/weakref/observed_hunt_mind
	var/datum/weakref/observed_hunt_body
	var/datum/weakref/observed_hunt_antag
	var/hunt_update_timer

/obj/item/forbidden_book/Destroy()
	clear_hunt_tracking()
	return ..()

/obj/item/forbidden_book/examine(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	. += "Доступно очков знаний: [heretic.knowledge_points]. Прогресс принадлежит вам и сохраняется при потере книги."
	. += "Откройте кодекс в руке для выбора пути, исследований и рецептов."
	. += "Примените к полу, чтобы начертить руну 3×3 за 8 секунд; к разлому — чтобы исследовать его; к руне — чтобы стереть её."

/obj/item/forbidden_book/attack_self(mob/user)
	ui_interact(user)

/obj/item/forbidden_book/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || !IS_HERETIC(user))
		return
	if(istype(target, /obj/effect/eldritch))
		remove_rune(target, user)
	else if(istype(target, /obj/effect/reality_smash))
		get_power_from_influence(target, user)
	else if(isopenturf(target))
		draw_rune(target, user)

/obj/item/forbidden_book/proc/get_power_from_influence(obj/effect/reality_smash/influence, mob/living/user)
	return influence.harvest(user, src)

/obj/item/forbidden_book/proc/can_draw_rune(turf/center, mob/living/user)
	if(QDELETED(src) || !center || !IS_HERETIC(user) || user.incapacitated() || !user.is_holding(src) || !user.Adjacent(center))
		return FALSE
	var/turf_count = 0
	for(var/turf/tile in range(1, center))
		turf_count++
		if(!isopenturf(tile) || isspaceturf(tile) || istype(tile, /turf/open/lava))
			return FALSE
	if(turf_count != 9)
		return FALSE
	for(var/obj/effect/eldritch/rune in range(2, center))
		return FALSE
	return TRUE

/obj/item/forbidden_book/proc/draw_rune(turf/center, mob/living/user)
	if(drawing)
		return FALSE
	if(!can_draw_rune(center, user))
		to_chat(user, span_warning("Для руны нужен участок пола 3×3 без стен, космоса, лавы и других рун. Держите кодекс в руке."))
		return FALSE
	drawing = TRUE
	to_chat(user, span_notice("Вы начинаете чертить руну трансмутации."))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/obj/effect/temp_visual/heretic_ritual/trace = new(center, heretic.selected_path, 9 SECONDS)
	var/completed = do_after(user, 8 SECONDS, target = center)
	qdel(trace)
	drawing = FALSE
	if(!completed || !can_draw_rune(center, user))
		return FALSE
	var/obj/effect/eldritch/big/rune = new(center)
	heretic = IS_HERETIC(user)
	rune.inscribe_path(heretic.selected_path)
	new /obj/effect/temp_visual/heretic_script(center, heretic.selected_path)
	log_game("[key_name(user)] чертит руну трансмутации в [AREACOORD(center)].")
	return TRUE

/obj/item/forbidden_book/proc/remove_rune(obj/effect/eldritch/rune, mob/living/user)
	if(rune.is_in_use)
		to_chat(user, span_warning("Сейчас руна проводит ритуал."))
		return FALSE
	if(!do_after(user, 2 SECONDS, target = rune) || QDELETED(rune) || rune.is_in_use || !IS_HERETIC(user) || !user.is_holding(src))
		return FALSE
	log_game("[key_name(user)] стирает руну трансмутации в [AREACOORD(rune)].")
	qdel(rune)
	return TRUE

/obj/item/forbidden_book/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/forbidden_book/ui_status(mob/user, datum/ui_state/state)
	if(!IS_HERETIC(user))
		return UI_CLOSE
	return ..()

/obj/item/forbidden_book/ui_interact(mob/user, datum/tgui/ui = null)
	if(!IS_HERETIC(user) || !user.is_holding(src))
		ui?.close()
		return
	attune_book(user)
	track_hunt_target(user)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		open_book(user)
		var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
		var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
		ui = new(user, src, "ForbiddenLore", path?.book_title || "Кодекс Рубцов")
		ui.set_autoupdate(FALSE)
		ui.open()
	else
		ui.set_autoupdate(FALSE)

/datum/antagonist/heretic/proc/refresh_book_ui()
	var/mob/reader = owner?.current
	if(!length(reader?.tgui_open_uis))
		return
	for(var/datum/tgui/ui as anything in reader.tgui_open_uis.Copy())
		if(istype(ui.src_object, /obj/item/forbidden_book))
			SStgui.update_uis(ui.src_object)

/obj/item/forbidden_book/proc/track_hunt_target(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/mind/target_mind = heretic?.hunt_target
	var/mob/living/target_body = target_mind?.current
	var/datum/antagonist/target_antag = target_mind?.has_antag_datum(/datum/antagonist/heretic) || target_mind?.has_antag_datum(/datum/antagonist/heretic_monster)
	if(book_reader?.resolve() == user && observed_hunt_mind?.resolve() == target_mind && observed_hunt_body?.resolve() == target_body && observed_hunt_antag?.resolve() == target_antag)
		return
	clear_hunt_tracking()
	book_reader = WEAKREF(user)
	if(!QDELETED(target_mind))
		observed_hunt_mind = WEAKREF(target_mind)
		RegisterSignal(target_mind, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING), PROC_REF(on_hunt_target_changed))
	if(!QDELETED(target_body))
		observed_hunt_body = WEAKREF(target_body)
		RegisterSignal(target_body, list(COMSIG_MOB_STATCHANGE, COMSIG_MOVABLE_Z_CHANGED, COMSIG_MOB_ON_NEW_MIND, COMSIG_MOB_ANTAG_ON_GAIN, COMSIG_ATOM_UPDATE_NAME, COMSIG_PARENT_QDELETING), PROC_REF(on_hunt_target_changed))
	if(!QDELETED(target_antag))
		observed_hunt_antag = WEAKREF(target_antag)
		RegisterSignal(target_antag, COMSIG_PARENT_QDELETING, PROC_REF(on_hunt_target_changed))

/obj/item/forbidden_book/proc/clear_hunt_tracking()
	var/datum/mind/target_mind = observed_hunt_mind?.resolve()
	var/mob/living/target_body = observed_hunt_body?.resolve()
	var/datum/antagonist/target_antag = observed_hunt_antag?.resolve()
	if(target_mind)
		UnregisterSignal(target_mind, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING))
	if(target_body)
		UnregisterSignal(target_body, list(COMSIG_MOB_STATCHANGE, COMSIG_MOVABLE_Z_CHANGED, COMSIG_MOB_ON_NEW_MIND, COMSIG_MOB_ANTAG_ON_GAIN, COMSIG_ATOM_UPDATE_NAME, COMSIG_PARENT_QDELETING))
	if(target_antag)
		UnregisterSignal(target_antag, COMSIG_PARENT_QDELETING)
	book_reader = null
	observed_hunt_mind = null
	observed_hunt_body = null
	observed_hunt_antag = null
	deltimer(hunt_update_timer)
	hunt_update_timer = null

/obj/item/forbidden_book/proc/on_hunt_target_changed(datum/source)
	SIGNAL_HANDLER
	if(!hunt_update_timer)
		hunt_update_timer = addtimer(CALLBACK(src, PROC_REF(refresh_hunt_ui)), 0, TIMER_STOPPABLE)

/obj/item/forbidden_book/proc/refresh_hunt_ui()
	hunt_update_timer = null
	SStgui.update_uis(src)

/obj/item/forbidden_book/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/heretic_book))

/obj/item/forbidden_book/ui_static_data(mob/user)
	var/static/list/catalog
	if(catalog)
		return catalog
	var/list/data = list("paths" = list(), "knowledge" = list(), "rituals" = list())
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		data["paths"] += list(list(
			"id" = path.id,
			"name" = path.name,
			"desc" = path.desc,
			"strengths" = list(path.strengths),
			"weaknesses" = list(path.weaknesses),
		))
		for(var/index in 1 to length(path.knowledge))
			data["knowledge"] += list(knowledge_data(path.knowledge[index], index, "path", path.id))
	for(var/knowledge_type in GLOB.heretic_side_knowledge)
		data["knowledge"] += list(knowledge_data(knowledge_type, GLOB.heretic_side_knowledge[knowledge_type], "side", PATH_SIDE))
	for(var/knowledge_type in GLOB.heretic_start_knowledge)
		data["knowledge"] += list(knowledge_data(knowledge_type, 0, "start", "Start"))
	for(var/list/entry as anything in data["knowledge"])
		var/knowledge_type = text2path(entry["id"])
		// Списки рецепта создаются на экземпляре и недоступны через initial() пути типа.
		var/datum/eldritch_knowledge/knowledge = new knowledge_type
		if(length(knowledge.required_atoms))
			data["rituals"] += list(list(
				"id" = entry["id"],
				"name" = entry["name"],
				"desc" = entry["desc"],
				"ingredients" = ritual_ingredients(knowledge),
				"hint" = knowledge.ritual_hint,
				"duration" = knowledge.ritual_time / (1 SECONDS),
				"ascension" = istype(knowledge, /datum/eldritch_knowledge/final_eldritch),
			))
		qdel(knowledge)
	catalog = data
	return data

/obj/item/forbidden_book/ui_data(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return list()
	var/datum/heretic_path/book_style = GLOB.heretic_paths[heretic.selected_path]
	var/list/data = list(
		"book" = list(
			"name" = book_style?.book_name || "Кодекс Рубцов",
			"title" = book_style?.book_title || "Кодекс Рубцов",
			"subtitle" = book_style?.book_subtitle || "Двенадцать дорог за одну завесу",
			"path" = book_style?.id,
			"cover_state" = book_style?.book_cover || "codex",
		),
		"points" = heretic.knowledge_points,
		"side_points" = heretic.side_knowledge_points,
		"total_sacrifices" = heretic.total_sacrifices,
		"ascended" = heretic.ascended,
		"selected_path" = heretic.selected_path,
		"path_stage" = heretic.path_stage,
		"knowledge_state" = knowledge_state(heretic),
		"passive_upgrades" = heretic.passive_upgrade_data(),
		"combat_resource" = null,
		"deed" = heretic.deed_data(),
	)
	if(book_style)
		var/datum/eldritch_knowledge/base_knowledge = heretic.get_knowledge(book_style.knowledge[1])
		data["combat_resource"] = base_knowledge?.get_combat_resource_data()
	var/mob/living/target = heretic.hunt_target?.current
	var/available_target = heretic.hunt_target_available(heretic.hunt_target)
	var/target_status = "Цель недоступна: призовите новое имя."
	if(available_target)
		if(target.stat == DEAD)
			target_status = "Цель погибла. Труп принимается за 1 очко знаний без побочного; тело останется на месте."
		else if(target.stat >= UNCONSCIOUS)
			target_status = "Цель можно принести на руну живой: 2 очка знаний и 1 побочное."
		else
			target_status = "Цель жива. Для обряда подойдут наручники, оглушение или положение лёжа."
	data["hunt"] = list(
		"target_name" = target?.real_name,
		"target_role" = heretic.hunt_target?.assigned_role,
		"target_status" = target_status,
		"can_retarget" = !available_target || COOLDOWN_FINISHED(heretic, hunt_refresh_cooldown),
		"retarget_seconds" = available_target ? max(0, CEILING(COOLDOWN_TIMELEFT(heretic, hunt_refresh_cooldown) / (1 SECONDS), 1)) : 0,
		"sacrifices_required" = HERETIC_ASCENSION_SACRIFICES,
		"deed_tiers" = HERETIC_DEED_TIERS,
		"ascension_bodies" = HERETIC_ASCENSION_BODIES,
		"influences_harvested" = heretic.influences_harvested,
		"influence_limit" = HERETIC_INFLUENCE_LIMIT,
		"influence_initial_count" = HERETIC_INFLUENCE_INITIAL_COUNT,
		"influence_interval_minutes" = HERETIC_INFLUENCE_INTERVAL / (1 MINUTES),
	)
	return data

/obj/item/forbidden_book/proc/knowledge_state(datum/antagonist/heretic/heretic)
	var/state_key = "[REF(heretic)]|[heretic.role_removed]|[heretic.selected_path]|[heretic.path_stage]|[heretic.knowledge_points]|[heretic.side_knowledge_points]|[heretic.total_sacrifices]|[jointext(heretic.researched_knowledge, "|")]"
	if(state_key == knowledge_state_key)
		return cached_knowledge_state
	knowledge_state_key = state_key
	cached_knowledge_state = list()
	var/list/knowledge_types = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		knowledge_types |= path.knowledge
	knowledge_types |= GLOB.heretic_side_knowledge
	knowledge_types |= GLOB.heretic_start_knowledge
	for(var/knowledge_type in knowledge_types)
		var/reason = heretic.research_error(knowledge_type)
		cached_knowledge_state["[knowledge_type]"] = list(
			"known" = !!heretic.get_knowledge(knowledge_type),
			"available" = !reason,
			"reason" = reason,
		)
	return cached_knowledge_state

/obj/item/forbidden_book/proc/knowledge_data(datum/eldritch_knowledge/knowledge_type, stage, kind, path)
	return list(
		"id" = "[knowledge_type]",
		"name" = initial(knowledge_type.name),
		"desc" = initial(knowledge_type.desc),
		"flavour" = initial(knowledge_type.gain_text),
		"cost" = initial(knowledge_type.cost),
		"sacrifices" = initial(knowledge_type.sacs_needed),
		"path" = path,
		"stage" = stage,
		"kind" = kind,
		"passive_description" = initial(knowledge_type.passive_desc),
	)

/obj/item/forbidden_book/proc/ritual_ingredients(datum/eldritch_knowledge/knowledge)
	var/list/counts = list()
	var/list/required_atoms = knowledge.required_atoms
	for(var/ingredient_type in required_atoms)
		var/amount = required_atoms[ingredient_type]
		counts[ingredient_type] = (counts[ingredient_type] || 0) + (isnum(amount) ? amount : 1)
	if(istype(knowledge, /datum/eldritch_knowledge/final_eldritch))
		counts[/mob/living/carbon/human] = HERETIC_ASCENSION_BODIES
	var/list/ingredients = list()
	if(knowledge.type == /datum/eldritch_knowledge/spell/basic)
		ingredients += list(list("name" = "Назначенная цель (живая или мёртвая)", "amount" = 1))
	if(istype(knowledge, /datum/eldritch_knowledge/curse))
		ingredients += list(list("name" = "Предмет с отпечатками цели", "amount" = 1))
	for(var/atom/ingredient_type as anything in counts)
		ingredients += list(list("name" = heretic_ritual_ingredient_name(ingredient_type), "amount" = counts[ingredient_type]))
	return ingredients

/obj/item/forbidden_book/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui?.user
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !user.is_holding(src) || user.incapacitated())
		return FALSE
	switch(action)
		if("turn_page")
			return turn_page(user)
		if("research")
			if(!istext(params["id"]))
				return FALSE
			if(!heretic.research_knowledge(text2path(params["id"]), user))
				return FALSE
			user.playsound_local(get_turf(user), 'sound/effects/magic.ogg', 25, TRUE)
			return TRUE
		if("retarget")
			return heretic.ensure_hunt_target(user, force_replace = TRUE)
		if("upgrade_passive")
			if(!istext(params["id"]) || !isnum(params["level"]))
				return FALSE
			if(!heretic.upgrade_passive(text2path(params["id"]), user, params["level"]))
				return FALSE
			user.playsound_local(get_turf(user), 'sound/effects/magic.ogg', 25, TRUE)
			return TRUE
	return FALSE

/obj/item/forbidden_book/ui_close(mob/user)
	if(book_reader?.resolve() == user)
		clear_hunt_tracking()
	if(user?.is_holding(src))
		close_book(user)
	return ..()

/obj/item/forbidden_book/debug
	name = "Отладочный Кодекс Рубцов"
