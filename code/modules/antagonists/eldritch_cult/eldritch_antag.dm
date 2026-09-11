/datum/antagonist/heretic
	name = "Еретик"
	roundend_category = "Heretics"
	antagpanel_category = "Heretic"
	antag_moodlet = /datum/mood_event/heretics
	job_rank = ROLE_HERETIC
	antag_hud_type = ANTAG_HUD_HERETIC
	antag_hud_name = "heretic"
	threat = 10
	var/give_equipment = TRUE
	var/list/researched_knowledge = list()
	var/total_sacrifices = 0
	var/list/sac_targetted = list()		//Which targets did living hearts give them, but they did not sac?
	var/list/actually_sacced = list()	//Which targets did they actually sac?
	var/ascended = FALSE
	var/knowledge_points = HERETIC_STARTING_KNOWLEDGE
	/// Награда за охоту для побочных знаний и улучшений пассивок.
	var/side_knowledge_points = 0
	var/selected_path
	var/path_stage = 0
	var/role_removed = FALSE
	var/mob/living/innate_body
	var/list/summon_items = list()

	reminded_times_left = 2 // BLUEMOON ADD

/datum/antagonist/heretic/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = TRUE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has heresized [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has heresized [key_name(new_owner)].")

/datum/antagonist/heretic/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ecult_op.ogg', 100, FALSE, pressure_affected = FALSE)
	to_chat(owner, span_eldritch_big("Вы — еретик!"))
	to_chat(owner, span_eldritch("Призовите кодекс и выберите свой путь. Выбор необратим. В кодексе есть описание всех способностей, рецепты и руководство."))
	to_chat(owner, span_notice("Начальное число разломов на станции: [HERETIC_INFLUENCE_INITIAL_COUNT]. Затем появляется ещё один каждые [DisplayTimeText(HERETIC_INFLUENCE_INTERVAL)]. Лимит исследований за раунд: [HERETIC_INFLUENCE_LIMIT]. Чередуйте поиск с охотой: живое сердце назначает и отслеживает цель. Доставьте её живой и без сознания на руну: на время канала она погрузится в стазис, после Мансуса вернётся живой, а вы получите два очка знаний и одно очко побочных знаний. Каждая душа принимается только один раз."))
	owner.announce_objectives()

/datum/antagonist/heretic/on_gain()
	var/mob/living/current = owner.current
	owner.teach_crafting_recipe(/datum/crafting_recipe/heretic/codex)
	owner.special_role = ROLE_HERETIC
	if(ishuman(current))
		forge_primary_objectives()
		for(var/knowledge_type in GLOB.heretic_start_knowledge)
			gain_knowledge(knowledge_type)
	current.log_message("has been converted to the cult of the forgotten ones!", LOG_ATTACK, color="#960000")
	GLOB.reality_smash_track.AddMind(owner)
	START_PROCESSING(SSprocessing,src)
	if(give_equipment)
		equip_cultist()
	return ..()

/datum/antagonist/heretic/on_removal()
	clear_heretic()
	return ..()

/datum/antagonist/heretic/Destroy()
	clear_heretic()
	for(var/knowledge_type in researched_knowledge)
		qdel(researched_knowledge[knowledge_type])
	researched_knowledge.Cut()
	return ..()

/datum/antagonist/heretic/proc/clear_heretic()
	if(role_removed)
		return
	role_removed = TRUE
	clear_combat_resource_alert()
	if(innate_body)
		remove_innate_effects(innate_body)
	STOP_PROCESSING(SSprocessing, src)
	if(owner)
		GLOB.reality_smash_track.RemoveMind(owner)
		if(owner.special_role == ROLE_HERETIC)
			owner.special_role = null
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		knowledge.on_lose(owner?.current)
	QDEL_LIST(summon_items)
	clear_hunt()
	if(!silent && owner?.current)
		to_chat(owner.current, span_userdanger("Запретные знания покидают ваш разум."))

/datum/antagonist/heretic/on_body_transfer(mob/living/old_body, mob/living/new_body)
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		knowledge.on_body_lose(old_body)
	. = ..()
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		knowledge.on_body_gain(new_body)
	update_combat_resource_alert(FALSE, new_body)

/datum/antagonist/heretic/proc/equip_cultist()
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	
	var/static/list/sm_items = list(
		/obj/item/living_heart,
		/obj/item/forbidden_book,
	)

	// Да, спавн в null, ничего не перепутано
	for(var/path in sm_items)
		if(locate(path) in summon_items)
			continue
		if(length(H.GetAllContents(path)))
			continue
		var/obj/item/item = new path(null)
		if(istype(item, /obj/item/living_heart))
			var/obj/item/living_heart/heart = item
			heart.bind(owner)
		summon_items += item

/datum/antagonist/heretic/proc/ecult_give_item(obj/item/item_path, mob/living/carbon/human/H)
	var/static/list/slots = list(
		"рюкзак" = ITEM_SLOT_BACKPACK,
		"левый карман" = ITEM_SLOT_LPOCKET,
		"правый карман" = ITEM_SLOT_RPOCKET
	)

	var/T = new item_path(H)
	var/item_name = initial(item_path.name)
	var/where = H.equip_in_one_of_slots(T, slots, qdel_on_fail = TRUE, critical = TRUE)
	if(!where)
		to_chat(H, "<span class='userdanger'>Не удалось выдать [item_name]. Обратитесь к администратору через F1.</span>")
		return null
	else
		to_chat(H, "<span class='danger'>Вы получаете [item_name]. Место: [where].</span>")
		if(where == "рюкзак")
			SEND_SIGNAL(H.back, COMSIG_TRY_STORAGE_SHOW, H)
		return T

/datum/antagonist/heretic/process()
	if(role_removed || !owner?.current || owner.current.stat == DEAD)
		return

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_life(owner.current)

/datum/antagonist/heretic/proc/on_death(mob/living/dying_body)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(handle_death), dying_body)

/datum/antagonist/heretic/proc/handle_death(mob/living/dying_body)
	if(QDELETED(src) || QDELETED(dying_body))
		return
	for(var/knowledge_type in researched_knowledge.Copy())
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		if(QDELETED(src) || QDELETED(dying_body))
			return
		if(!QDELETED(knowledge))
			knowledge.on_death(dying_body)

/// Returns the heretic's codex whether it is carried or hidden via Summon Codex.
/datum/antagonist/heretic/proc/get_forbidden_book()
	var/mob/living/owner_mob = owner?.current
	if(owner_mob)
		for(var/obj/item/forbidden_book/FB in owner_mob.GetAllContents(/obj/item/forbidden_book))
			return FB
	for(var/obj/item/I in summon_items)
		if(istype(I, /obj/item/forbidden_book))
			return I
	return null

// needs to be refactored to base /datum/antagonist sometime..
/datum/antagonist/heretic/proc/add_objective(datum/objective/O)
	objectives += O

/datum/antagonist/heretic/proc/forge_single_objective(datum/antagonist/heretic/heretic)
	var/datum/objective/protect/protection_objective = new
	protection_objective.owner = heretic.owner
	heretic.add_objective(protection_objective)
	protection_objective.find_target()

/datum/antagonist/heretic/proc/forge_primary_objectives()
	var/datum/objective/sacrifice_ecult/SE = new
	SE.owner = owner
	SE.update_explanation_text()
	objectives += SE
	var/datum/objective/ascend_ecult/ascension = new
	ascension.owner = owner
	ascension.update_explanation_text()
	objectives += ascension

/datum/antagonist/heretic/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner?.current
	if(!current || innate_body == current)
		return
	if(innate_body)
		remove_innate_effects(innate_body)
	innate_body = current
	add_antag_hud(antag_hud_type, antag_hud_name, current)
	handle_clown_mutation(current, "Знания Мансуса помогают преодолеть клоунскую неуклюжесть.")
	current.faction |= "heretics"
	RegisterSignal(current, COMSIG_MOB_DEATH, PROC_REF(on_death))
	RegisterSignal(current, COMSIG_PARENT_QDELETING, PROC_REF(on_innate_body_deleted))
	update_combat_resource_alert(FALSE, current)

/datum/antagonist/heretic/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || innate_body
	if(!current || current != innate_body)
		return
	innate_body = null
	clear_combat_resource_alert(current)
	remove_antag_hud(antag_hud_type, current)
	if(owner)
		handle_clown_mutation(current, removing = FALSE)
	current.faction -= "heretics"
	UnregisterSignal(current, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING))

/datum/antagonist/heretic/proc/on_innate_body_deleted(mob/living/source)
	SIGNAL_HANDLER
	remove_innate_effects(source)

/datum/antagonist/heretic/get_admin_commands()
	. = ..()
	.["Equip"] = CALLBACK(src,PROC_REF(equip_cultist))

/datum/antagonist/heretic/roundend_report()
	var/list/parts = list()

	var/cultiewin = TRUE

	parts += printplayer(owner)
	parts += "<b>Душ принято:</b> [total_sacrifices]"
	var/datum/heretic_path/path = GLOB.heretic_paths[selected_path]
	parts += "<b>Путь:</b> [path ? path.name : "не выбран"]. <b>Очков знаний осталось:</b> [knowledge_points], побочных: [side_knowledge_points]"

	if(length(objectives))
		var/count = 1
		for(var/o in objectives)
			var/datum/objective/objective = o
			if(objective.check_completion())
				parts += "<b>Цель #[count]</b>: [objective.explanation_text] <span class='greentext'>Выполнена!</span>"
			else
				parts += "<b>Цель #[count]</b>: [objective.explanation_text] <span class='redtext'>Провалена.</span>"
				cultiewin = FALSE
			count++
	if(ascended)
		parts += "<span class='greentext big'>ЕРЕТИК СОВЕРШИЛ ВОЗНЕСЕНИЕ!</span>"
	else
		if(cultiewin)
			parts += "<span class='greentext'>Еретик успешен!</span>"
		else
			parts += "<span class='redtext'>Еретик потерпел неудачу.</span>"

	parts += "<b>Исследованные знания:</b> "

	var/list/knowledge_message = list()
	var/list/knowledge = get_all_knowledge()
	for(var/X in knowledge)
		var/datum/eldritch_knowledge/EK = knowledge[X]
		knowledge_message += "[EK.name]"
	parts += knowledge_message.Join(", ")

	parts += "<b>Цели, назначенные живым сердцем, но не принесённые в жертву:</b>"
	if(!sac_targetted.len)
		parts += "Отсутствуют."
	else
		var/list/target_names = list()
		for(var/target_ref in sac_targetted)
			target_names += sac_targetted[target_ref]
		parts += target_names.Join(", ")
	parts += "<b>Совершённые жертвоприношения:</b>"
	if(!actually_sacced.len)
		parts += "<span class='redtext'>Отсутствуют!</span>"
	else
		parts += actually_sacced.Join(",")

	return parts.Join("<br>")
////////////////
// Knowledge //
////////////////

/datum/antagonist/heretic/proc/gain_knowledge(datum/eldritch_knowledge/EK)
	if(!ispath(EK, /datum/eldritch_knowledge) || get_knowledge(EK))
		return FALSE
	var/datum/eldritch_knowledge/initialized_knowledge = new EK
	researched_knowledge[initialized_knowledge.type] = initialized_knowledge
	initialized_knowledge.combat_resource_owner = WEAKREF(src)
	initialized_knowledge.on_gain(owner?.current)
	update_combat_resource_alert()
	return TRUE

/datum/antagonist/heretic/proc/get_knowledge(wanted)
	return researched_knowledge[wanted]

/datum/antagonist/heretic/proc/get_all_knowledge()
	return researched_knowledge

/datum/antagonist/heretic/threat()
	. = ..()
	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		. += EK.cost
	if(ascended)
		. += 20

/datum/antagonist/heretic/antag_panel()
	var/list/parts = list()
	parts += ..()
	parts += "<b>Текущие цели живого сердца:</b>"
	if(!hunt_target)
		parts += "Отсутствует."
	else
		parts += hunt_target.current?.real_name || hunt_target.name
	parts += "<b>Принесённые в жертву цели:</b>"
	if(!actually_sacced.len)
		parts += "Отсутствует."
	else
		parts += actually_sacced.Join(",")

	return (parts.Join("<br>") + "<br>")

////////////////
// Objectives //
////////////////

/datum/objective/sacrifice_ecult
	name = "Жертвоприношения"
	target_amount = HERETIC_ASCENSION_SACRIFICES

/datum/objective/sacrifice_ecult/update_explanation_text()
	. = ..()
	explanation_text = "Принесите [target_amount] разных назначенных душ на руне трансмутации. Доставьте живые цели без сознания: после ритуала они вернутся живыми на станцию."

/datum/objective/sacrifice_ecult/check_completion()
	if(!owner)
		return FALSE
	var/datum/antagonist/heretic/cultie = owner.has_antag_datum(/datum/antagonist/heretic)
	if(!cultie)
		return FALSE
	return cultie.total_sacrifices >= target_amount

/datum/objective/ascend_ecult
	name = "Вознесение"

/datum/objective/ascend_ecult/update_explanation_text()
	. = ..()
	explanation_text = "Вознеситесь: принесите [HERETIC_ASCENSION_SACRIFICES] назначенных душ, изучите финал своего пути и завершите обряд с [HERETIC_ASCENSION_BODIES] человеческими трупами."

/datum/objective/ascend_ecult/check_completion()
	var/datum/antagonist/heretic/heretic = owner?.has_antag_datum(/datum/antagonist/heretic)
	return heretic?.ascended || completed
