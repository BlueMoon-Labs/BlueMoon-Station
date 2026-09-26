/obj/item/forbidden_book
	name = "Codex Cicatrix"
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
	. += "Примените кодекс к полу, чтобы за 8 секунд начертить руну 3×3, к разлому - чтобы исследовать его, к руне - чтобы стереть её. Руну стирает и Хватка Мансуса."
	if(heretic.deed && !heretic.deed.complete())
		. += span_notice("[heretic.deed.name]: [heretic.deed.progress]/[heretic.deed.goal()] на ступени [heretic.deed.tier + 1]. [heretic.deed.desc] [heretic.deed.hint]")

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
	var/draw_time = 8 SECONDS * heretic_ritual_speed_multiplier(user, center)
	var/obj/effect/temp_visual/heretic_ritual/trace = new(center, heretic.selected_path, draw_time + 1 SECONDS, HERETIC_RUNE_VISUAL_TRACE)
	var/completed = do_after(user, draw_time, target = center)
	drawing = FALSE
	if(!completed || !can_draw_rune(center, user))
		qdel(trace)
		return FALSE
	trace.finish()
	var/obj/effect/eldritch/big/rune = new(center)
	rune.drawn_by = WEAKREF(user.mind)
	heretic = IS_HERETIC(user)
	rune.inscribe_path(heretic.selected_path)
	new /obj/effect/temp_visual/heretic_script(center, heretic.selected_path)
	log_game("[key_name(user)] чертит руну трансмутации в [AREACOORD(center)].")
	return TRUE

/obj/item/forbidden_book/proc/remove_rune(obj/effect/eldritch/rune, mob/living/user)
	return rune.erase_by(user, src)

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
	var/list/entries = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/datum/heretic_innate/innate = path.innate_type
		data["paths"] += list(list(
			"id" = path.id,
			"name" = path.name,
			"desc" = path.desc,
			"tagline" = path.tagline,
			"craft" = path.craft_summary,
			"capture" = path.capture_summary,
			"escape" = path.escape_summary,
			"strength_points" = path.strength_points?.Copy() || list(),
			"weakness_points" = path.weakness_points?.Copy() || list(),
			"practice" = path.combat_practice,
			"innate_name" = initial(innate.name),
			"innate_desc" = initial(innate.desc),
			"strengths" = list(path.strengths),
			"weaknesses" = list(path.weaknesses),
		))
		for(var/index in 1 to length(path.knowledge))
			entries += list(list(path.knowledge[index], index, "path", path.id))
	for(var/knowledge_type in GLOB.heretic_side_knowledge)
		entries += list(list(knowledge_type, GLOB.heretic_side_knowledge[knowledge_type], "side", PATH_SIDE))
	for(var/knowledge_type in GLOB.heretic_start_knowledge)
		entries += list(list(knowledge_type, 0, "start", "Start"))
	for(var/list/entry as anything in entries)
		var/knowledge_type = entry[1]
		// Списки и собранный из них desc есть только у экземпляра.
		var/datum/eldritch_knowledge/knowledge = new knowledge_type
		data["knowledge"] += list(knowledge_data(knowledge, entry[2], entry[3], entry[4]))
		if(length(knowledge.required_atoms))
			data["rituals"] += list(list(
				"id" = "[knowledge.type]",
				"name" = knowledge.name,
				"desc" = knowledge.summary || knowledge.desc,
				"ingredients" = ritual_ingredients(knowledge),
				"hint" = knowledge.ritual_hint,
				"hints" = knowledge.ritual_hints?.Copy() || list(),
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
			"name" = book_style?.book_name || "Codex Cicatrix",
			"title" = book_style?.book_title || "Кодекс Рубцов",
			"subtitle" = book_style?.book_subtitle || "Пятнадцать дорог за одну завесу",
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
		"combat_abilities" = combat_ability_data(heretic),
		"ability_hotkey_help" = heretic.format_ability_hotkey_help(user.client?.prefs),
		"deed" = heretic.deed_data(),
		"preparation" = preparation_data(heretic),
	)
	if(book_style)
		var/datum/eldritch_knowledge/base_knowledge = heretic.get_knowledge(book_style.knowledge[1])
		data["combat_resource"] = base_knowledge?.get_combat_resource_data()
	var/mob/living/target = heretic.hunt_target?.current
	var/available_target = heretic.hunt_target_available(heretic.hunt_target)
	var/target_status = heretic.hunt_target_unavailable_reason(heretic.hunt_target)
	if(available_target)
		if(target.stat == DEAD)
			target_status = "Цель погибла. Труп принимается за 1 очко знаний без побочного: коснитесь его сердцем или принесите к руне. Тело останется на месте."
		else if(heretic.hunt_target_ready(target))
			target_status = "Цель готова к обряду. Коснитесь её живым сердцем или доставьте к руне: 2 очка знаний и 1 побочное."
		else
			target_status = "Цель жива. Для обряда наденьте на неё наручники, оглушите или сбейте с ног; цель в крите подойдёт и без наручников. Если цель сама легла или уснула, это не считается."
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
		"pocket" = list(
			"duration" = HERETIC_POCKET_DURATION / (1 SECONDS),
			"warning" = HERETIC_POCKET_WARNING / (1 SECONDS),
			"pull" = HERETIC_POCKET_PULL_TIME / (1 SECONDS),
			"tear" = HERETIC_POCKET_TEAR_TIME / (1 SECONDS),
			"cooldown" = HERETIC_POCKET_COOLDOWN / (1 SECONDS),
			"hold" = HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS),
			"grip" = HERETIC_POCKET_DOOR_GRIP / (1 SECONDS),
			"shake" = HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS),
		),
	)
	return data

/obj/item/forbidden_book/proc/combat_ability_data(datum/antagonist/heretic/heretic, datum/preferences/preferences)
	preferences ||= heretic.owner?.current?.client?.prefs
	var/list/spells = list()
	heretic.collect_combat_spells(spells)
	var/list/abilities = list()
	for(var/obj/effect/proc_holder/spell/spell as anything in spells)
		if(QDELETED(spell) || !(spell in heretic.owner?.spell_list))
			continue
		var/usage = "Нажмите кнопку этой способности на игровом экране."
		if(istype(spell, /obj/effect/proc_holder/spell/targeted/touch))
			usage = "Освободите активную руку, нажмите кнопку способности, затем коснитесь цели рядом с собой. Другая контактная или прицельная способность заменит подготовленную. Для отмены нажмите «Выбросить» (по умолчанию Q), повторно кнопку способности или активируйте предмет в руке."
		else if(istype(spell, /obj/effect/proc_holder/spell/pointed) || istype(spell, /obj/effect/proc_holder/spell/aimed))
			usage = "Нажмите кнопку способности, затем укажите цель щелчком мыши. Другая контактная или прицельная способность заменит подготовленную. Для отмены нажмите «Выбросить» (по умолчанию Q) или повторно кнопку способности; предмет в руке сохранится."
		var/slot = heretic.ability_hotkey_types.Find(spell.type)
		var/hotkey
		if(istype(spell, /obj/effect/proc_holder/spell/targeted/touch) || istype(spell, /obj/effect/proc_holder/spell/pointed) || istype(spell, /obj/effect/proc_holder/spell/aimed))
			usage += " Подготовка выключает режим броска; включение броска отменяет подготовку."
		if(slot && slot <= ABILITY_HOTKEY_SLOTS)
			var/datum/keybinding/binding = GLOB.keybindings_by_name["ability_slot_[slot]"]
			hotkey = binding.format_keys(preferences)
			usage += " Горячая клавиша: [hotkey]. Переназначение: «Способность [slot]» в настройках клавиш."
		abilities += list(list("id" = "[spell.type]", "name" = spell.name, "summary" = spell.summary, "desc" = spell.desc, "usage" = usage, "hotkey" = hotkey))
	return abilities

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

/obj/item/forbidden_book/proc/knowledge_data(datum/eldritch_knowledge/knowledge, stage, kind, path)
	return list(
		"id" = "[knowledge.type]",
		"name" = knowledge.name,
		"desc" = knowledge.desc,
		"summary" = knowledge.summary,
		"details" = knowledge.details?.Copy() || list(),
		"role" = knowledge.role,
		"flavour" = knowledge.gain_text,
		"cost" = knowledge.cost,
		"sacrifices" = knowledge.sacs_needed,
		"path" = path,
		"stage" = stage,
		"kind" = kind,
		"starter_armor" = knowledge.type == /datum/eldritch_knowledge/armor,
		"passive_description" = knowledge.passive_desc,
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
		if("refresh_preparation")
			return TRUE
		if("call_heart")
			return call_heart(user, heretic)
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
	name = "debug Codex Cicatrix"
	var/debug_knowledge_points = 100

/obj/item/forbidden_book/debug/examine(mob/user)
	. = ..()
	. += "Тестовый кодекс: при открытии еретиком передаёт ему оставшиеся [debug_knowledge_points] очков знаний. Запас расходуется один раз на книгу."

/obj/item/forbidden_book/debug/attack_self(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || heretic.role_removed)
		to_chat(user, span_warning("Сначала выдайте персонажу роль еретика через Show Traitor Panel."))
		return
	if(!user.is_holding(src) || user.incapacitated())
		return
	if(debug_knowledge_points > 0)
		heretic.knowledge_points += debug_knowledge_points
		to_chat(user, span_notice("Тестовый кодекс передал вам [debug_knowledge_points] очков знаний. Цель выбирается в главе «Охота»."))
		log_admin("[key_name(user)] получает [debug_knowledge_points] очков знаний из отладочного кодекса.")
		debug_knowledge_points = 0
		heretic.refresh_book_ui()
	return ..()
