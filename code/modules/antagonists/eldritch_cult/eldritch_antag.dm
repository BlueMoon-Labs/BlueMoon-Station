/datum/antagonist/heretic
	name = "Heretic"
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
	var/datum/mind/yandere

	reminded_times_left = 2 // BLUEMOON ADD

/datum/antagonist/heretic/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = TRUE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has heresized [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has heresized [key_name(new_owner)].")

/datum/antagonist/heretic/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ecult_op.ogg', 100, FALSE, pressure_affected = FALSE)//subject to change
	to_chat(owner, "<span class='boldannounce'>Ты Еретик!</span><br>\
	<B>Забытые боги дали вам следующие задания:</B>")
	owner.announce_objectives()
	to_chat(owner, "<span class='cult'>Книга шепчет мне, её запретные знания вновь появились в этом мире!<br>\
	Книга позволит мне исследовать новые способности. Нужно читать очень внимательно, ибо то что сделано уже не вернуть!<br>\
	Я получу нужные мне знания собирая их из разломов или принося в жертву цели которое укажет мне живое сердце.<br> \
	Основное руководство : https://tgstation13.org/wiki/Heresy_101 </span>")

/datum/antagonist/heretic/on_gain()
	var/mob/living/current = owner.current
	owner.teach_crafting_recipe(/datum/crafting_recipe/heretic/codex)
	owner.special_role = ROLE_HERETIC
	if(ishuman(current))
		forge_primary_objectives()
		gain_knowledge(/datum/eldritch_knowledge/spell/basic)
		gain_knowledge(/datum/eldritch_knowledge/living_heart)
		gain_knowledge(/datum/eldritch_knowledge/codex_cicatrix)
	current.log_message("has been converted to the cult of the forgotten ones!", LOG_ATTACK, color="#960000")
	GLOB.reality_smash_track.AddMind(owner)
	START_PROCESSING(SSprocessing,src)
	if(give_equipment)
		equip_cultist()
	return ..()

/datum/antagonist/heretic/on_removal()

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_lose(owner.current)
	owner.special_role = null
	if(!silent)
		to_chat(owner.current, "<span class='userdanger'>Your mind begins to flare as the otherwordly knowledge escapes your grasp!</span>")
		owner.current.log_message("has renounced the cult of the old ones!", LOG_ATTACK, color="#960000")
	GLOB.reality_smash_track.RemoveMind(owner)
	STOP_PROCESSING(SSprocessing,src)
	on_death()

	return ..()


/datum/antagonist/heretic/proc/equip_cultist()
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	. += ecult_give_item(/obj/item/forbidden_book, H)
	. += ecult_give_item(/obj/item/living_heart, H)

/datum/antagonist/heretic/proc/ecult_give_item(obj/item/item_path, mob/living/carbon/human/H)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET
	)

	var/T = new item_path(H)
	var/item_name = initial(item_path.name)
	var/where = H.equip_in_one_of_slots(T, slots, critical = TRUE)
	if(!where)
		to_chat(H, "<span class='userdanger'>К сожалению, тебе не удалось получить [item_name]. Это очень плохо и тебе нужно срочно попросить помощи у администратора (press F1).</span>")
		return FALSE
	else
		to_chat(H, "<span class='danger'>Я получил [item_name] в мой [where].</span>")
		if(where == "backpack")
			SEND_SIGNAL(H.back, COMSIG_TRY_STORAGE_SHOW, H)
		return TRUE

/datum/antagonist/heretic/process()
	if(!owner?.current || owner.current.stat == DEAD)
		return

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_life(owner.current)

///What happens to the heretic once he dies, used to remove any custom perks
/datum/antagonist/heretic/proc/on_death()
	if(!owner?.current)
		return

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_death(owner.current)

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

/datum/antagonist/heretic/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	add_antag_hud(antag_hud_type, antag_hud_name, current)
	handle_clown_mutation(current, mob_override ? null : "Древние знания из моей книги позволяют преодолеть клоунскую природу и использовать эффективно даже сложные предметы.")
	current.faction |= "heretics"

/datum/antagonist/heretic/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	remove_antag_hud(antag_hud_type, current)
	handle_clown_mutation(current, removing = FALSE)
	current.faction -= "heretics"

/datum/antagonist/heretic/get_admin_commands()
	. = ..()
	.["Equip"] = CALLBACK(src,PROC_REF(equip_cultist))

/datum/antagonist/heretic/roundend_report()
	var/list/parts = list()

	var/cultiewin = TRUE

	parts += printplayer(owner)
	parts += "<b>Жертв принесено:</b> [total_sacrifices]"

	if(length(objectives))
		var/count = 1
		for(var/o in objectives)
			var/datum/objective/objective = o
			if(objective.check_completion())
				parts += "<b>Цель #[count]</b>: [objective.explanation_text] <span class='greentext'>Выполнена!</b></span>"
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

	parts += "<b>Цели поставленные живым сердцем но не принесённые в жертву:</b>"
	if(!sac_targetted.len)
		parts += "Отсутствуют."
	else
		parts += sac_targetted.Join(",")
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
	if(get_knowledge(EK))
		return FALSE
	var/datum/eldritch_knowledge/initialized_knowledge = new EK
	researched_knowledge[initialized_knowledge.type] = initialized_knowledge
	initialized_knowledge.on_gain(owner.current)
	return TRUE

/datum/antagonist/heretic/proc/get_researchable_knowledge()
	var/list/researchable_knowledge = list()
	var/list/banned_knowledge = list()
	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		researchable_knowledge |= EK.next_knowledge
		banned_knowledge |= EK.banned_knowledge
		banned_knowledge |= EK.type
	researchable_knowledge -= banned_knowledge
	return researchable_knowledge

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
	parts += "<b>Цели которые в данный момент обозначило живое сердце (Результат может быть ложным если вы украли чужое сердце):</b>"
	if(!sac_targetted.len)
		parts += "Отсутствует."
	else
		parts += sac_targetted.Join(",")
	parts += "<b>Принесенные в жертву цели:</b>"
	if(!actually_sacced.len)
		parts += "Отсутствует."
	else
		parts += actually_sacced.Join(",")

	return (parts.Join("<br>") + "<br>")


////////////////
// Objectives //
////////////////

/datum/objective/sacrifice_ecult
	name = "sacrifice"

/datum/objective/sacrifice_ecult/update_explanation_text()
	. = ..()
	target_amount = rand(2,3)
	explanation_text = "Принеси в жертву как минимум [target_amount] живых существ."

/datum/objective/sacrifice_ecult/check_completion()
	if(!owner)
		return FALSE
	var/datum/antagonist/heretic/cultie = owner.has_antag_datum(/datum/antagonist/heretic)
	if(!cultie)
		return FALSE
	return cultie.total_sacrifices >= target_amount
