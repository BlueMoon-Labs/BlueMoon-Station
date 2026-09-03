//CLOCKCULT PROOF OF CONCEPT
/datum/antagonist/clockcult
	name = "Clock Cultist"
	roundend_category = "clock cultists"
	antagpanel_category = "Clockcult"
	job_rank = ROLE_SERVANT_OF_RATVAR
	antag_moodlet = /datum/mood_event/cult
	skill_modifiers = list(/datum/skill_modifier/job/level/wiring, /datum/skill_modifier/job/level/dwarfy/blacksmithing)
	ui_name = "AntagInfoClockwork"
	var/datum/action/innate/hierophant/hierophant_network = new
	threat = 3
	var/datum/team/clockcult/clock_team
	var/make_team = TRUE //This should be only false for tutorial scarabs
	var/neutered = FALSE			//can not use round ending, gibbing, converting, or similar things with unmatched round impact
	var/ignore_eligibility_check = FALSE
	var/ignore_holy_water = FALSE
	var/give_equipment = FALSE

/datum/antagonist/clockcult/ui_data(mob/user)
	. = ..()
	if(!.)
		return
	.["HONOR_RATVAR"] = GLOB.ratvar_awakens

/datum/antagonist/clockcult/neutered
	name = "Neutered Clock Cultist"
	neutered = TRUE
	soft_antag = TRUE
	ui_name = null // no.

/datum/antagonist/clockcult/neutered/traitor
	name = "Traitor Clock Cultist"
	ignore_eligibility_check = TRUE
	ignore_holy_water = TRUE
	show_in_roundend = FALSE
	make_team = FALSE

/datum/antagonist/clockcult/Destroy()
	qdel(hierophant_network)
	return ..()

/datum/antagonist/clockcult/get_team()
	return clock_team

/datum/antagonist/clockcult/create_team(datum/team/clockcult/new_team)
	if(!new_team && make_team)
		//TODO blah blah same as the others, allow multiple
		for(var/datum/antagonist/clockcult/H in GLOB.antagonists)
			if(!H.owner)
				continue
			if(H.clock_team)
				clock_team = H.clock_team
				return
		clock_team = new /datum/team/clockcult
		return
	if(make_team && !istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	clock_team = new_team

/datum/antagonist/clockcult/can_be_owned(datum/mind/new_owner)
	. = ..()
	if(. && !ignore_eligibility_check)
		. = is_eligible_servant(new_owner.current)

/datum/antagonist/clockcult/on_gain()
	var/mob/living/current = owner.current
	SSticker.mode.servants_of_ratvar += owner
	SSticker.mode.update_servant_icons_added(owner)
	owner.special_role = ROLE_SERVANT_OF_RATVAR
	owner.current.log_message("has been converted to the cult of Ratvar!", LOG_ATTACK, color="#BE8700")
	if(give_equipment)
		equip_cultist(TRUE)
	if(issilicon(current))
		if(iscyborg(current) && !silent)
			var/mob/living/silicon/robot/R = current
			if(R.connected_ai && !is_servant_of_ratvar(R.connected_ai))
				to_chat(R, "<span class='boldwarning'>Ваша синхронизация с главным ИИ была отключена.<br>\
				Кроме того, ваша встроенная камера больше не активна, и вы получили ограниченный набор часовых механизмов, в том числе часовую плиту.</span>")
			else
				to_chat(R, "<span class='boldwarning'>Ваша встроенная камера больше не активна, и вы получили ограниченный набор часовых механизмов, в том числе часовую плиту.</span>")
		if(isAI(current))
			to_chat(current, "<span class='boldwarning'>Теперь вы можете использовать свои камеры для прослушивания разговоров, но больше не можете говорить ни на каком другом языке, кроме ратварского.</span>")
		to_chat(current, "<span class='heavy_brass'>Вы можете общаться с другими слугами, используя кнопку сети Иерофанта в левом верхнем углу.</span>")
	else if(isbrain(current) || isclockmob(current))
		to_chat(current, "<span class='nezbere'>Вы можете общаться с другими слугами, используя кнопку сети Иерофанта в левом верхнем углу.</span>")
	..()
	to_chat(current, "<b>Воля Ратвара:</b> [CLOCKCULT_OBJECTIVE]")
	antag_memory += "<b>Воля Ратвара:</b> [CLOCKCULT_OBJECTIVE]<br>" //Memorize the objectives
	if(clock_team)
		clock_team.check_size()

/datum/antagonist/clockcult/proc/equip_cultist()
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	if (owner.assigned_role == "Clown")
		to_chat(owner, "Тренировки позволили вам отринуть клоунскую натуру, теперь вы можете использовать оружие без риска ранить себя.")
		H.dna.remove_mutation(CLOWNMUT)
	. += cult_give_item(/obj/item/clockwork/slab, H)
	. += cult_give_item(/obj/item/clockwork/replica_fabricator, H)
	to_chat(owner, "Они помогут вам создать культ на этой станции. Используйте их с умом и помните - вы не единственный.</span>")

/datum/antagonist/clockcult/proc/cult_give_item(obj/item/item_path, mob/living/carbon/human/mob)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET
	)

	var/T = new item_path(mob)
	var/item_name = initial(item_path.name)
	var/where = mob.equip_in_one_of_slots(T, slots, critical = TRUE)
	if(!where)
		to_chat(mob, "<span class='userdanger'>К сожалению, вы не получили [item_name]. Это очень плохо, и вы должны немедленно обратиться за помощью к администратору (нажмите F1).</span>")
		return 0
	else
		to_chat(mob, "<span class='danger'>У вас есть [item_name] в вашем [where].</span>")
		if(where == "backpack")
			SEND_SIGNAL(mob.back, COMSIG_TRY_STORAGE_SHOW, mob)
		return TRUE

/datum/antagonist/clockcult/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(istype(mob_override))
		current = mob_override
	GLOB.all_clockwork_mobs += current
	current.faction |= "ratvar"
	current.grant_language(/datum/language/ratvar, source = LANGUAGE_CLOCKIE)
	current.update_action_buttons_icon() //because a few clockcult things are action buttons and we may be wearing/holding them for whatever reason, we need to update buttons
	if(issilicon(current))
		var/mob/living/silicon/S = current
		if(iscyborg(S))
			var/mob/living/silicon/robot/R = S
			if(!R.shell)
				R.UnlinkSelf()
			R.module.rebuild_modules()
		else if(isAI(S))
			var/mob/living/silicon/ai/A = S
			A.grant_language(/datum/language/ratvar, TRUE, TRUE, LANGUAGE_CLOCKIE)
			A.can_be_carded = FALSE
			A.requires_power = POWER_REQ_CLOCKCULT
			var/list/AI_frame = list(mutable_appearance('icons/mob/clockwork_mobs.dmi', "aiframe")) //make the AI's cool frame
			for(var/d in GLOB.cardinals)
				AI_frame += image('icons/mob/clockwork_mobs.dmi', A, "eye[rand(1, 10)]", dir = d) //the eyes are randomly fast or slow
			A.add_overlay(AI_frame)
			if(!A.lacks_power())
				A.ai_restore_power()
			if(A.eyeobj)
				A.eyeobj.relay_speech = TRUE
			for(var/mob/living/silicon/robot/R in A.connected_robots)
				if(R.connected_ai == A)
					add_servant_of_ratvar(R)
		S.laws = new/datum/ai_laws/ratvar
		S.laws.associate(S)
		S.update_icons()
		S.show_laws()
		hierophant_network.title = "Silicon"
		hierophant_network.span_for_name = "nezbere"
		hierophant_network.span_for_message = "brass"
	else if(isbrain(current))
		hierophant_network.title = "Vessel"
		hierophant_network.span_for_name = "nezbere"
		hierophant_network.span_for_message = "alloy"
	else if(isclockmob(current))
		hierophant_network.title = "Construct"
		hierophant_network.span_for_name = "nezbere"
		hierophant_network.span_for_message = "brass"
	hierophant_network.Grant(current)
	current.throw_alert("clockinfo", /atom/movable/screen/alert/clockwork/infodump)
	var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar
	if(G && G.active && ishuman(current))
		current.add_overlay(mutable_appearance('icons/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER))
	else if(clock_team?.clock_ascendent && ishuman(current))
		current.add_overlay(mutable_appearance('icons/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER))

/datum/antagonist/clockcult/remove_innate_effects(mob/living/mob_override)
	var/mob/living/current = owner.current
	if(istype(mob_override))
		current = mob_override
	GLOB.all_clockwork_mobs -= current
	current.faction -= "ratvar"
	current.remove_language(/datum/language/ratvar, source = LANGUAGE_CLOCKIE)
	current.clear_alert("clockinfo")
	for(var/datum/action/innate/clockwork_armaments/C in owner.current.actions) //Removes any bound clockwork armor
		qdel(C)
	for(var/datum/action/innate/call_weapon/W in owner.current.actions) //and weapons too
		qdel(W)
	if(issilicon(current))
		var/mob/living/silicon/S = current
		if(isAI(S))
			var/mob/living/silicon/ai/A = S
			A.remove_blocked_language(subtypesof(/datum/language) - /datum/language/ratvar, LANGUAGE_CLOCKIE)
			A.can_be_carded = initial(A.can_be_carded)
			A.requires_power = initial(A.requires_power)
			A.cut_overlays()
		S.make_laws()
		S.update_icons()
		S.show_laws()
	var/mob/living/temp_owner = current
	..()
	if(iscyborg(temp_owner))
		var/mob/living/silicon/robot/R = temp_owner
		R.module.rebuild_modules()
	if(temp_owner)
		temp_owner.update_action_buttons_icon() //because a few clockcult things are action buttons and we may be wearing/holding them, we need to update buttons
	temp_owner.cut_overlays()
	temp_owner.regenerate_icons()

/datum/antagonist/clockcult/on_removal()
	SSticker.mode.servants_of_ratvar -= owner
	SSticker.mode.update_servant_icons_removed(owner)
	if(!silent)
		owner.current.visible_message("<span class='deconversion_message'>[owner.current] выглядит так, будто бы верну[owner.current.ru_sya()] в своё исходное состояние!</span>", null, null, null, owner.current)
		to_chat(owner, "<span class='userdanger'>Холодная, холодная тьма проникает в ваш разум, погасив свет Юстициара Ратвара и все ваши воспоминания как его слуги.</span>")
	owner.current.log_message("has renounced the cult of Ratvar!", LOG_ATTACK, color="#BE8700")
	owner.special_role = null
	if(iscyborg(owner.current))
		to_chat(owner.current, "<span class='warning'>Несмотря на то, что вы свободны от влияния Ратвара, вы все еще непоправимо повреждены и больше не обладаете определенными функциями, такими как привязка к ИИ.</span>")
	. = ..()


/datum/antagonist/clockcult/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = TRUE
	add_servant_of_ratvar(new_owner.current, TRUE, override_type = type)
	message_admins("[key_name_admin(admin)] has made [new_owner.current] into a servant of Ratvar.")
	log_admin("[key_name(admin)] has made [new_owner.current] into a servant of Ratvar.")

/datum/antagonist/clockcult/admin_remove(mob/user)
	var/mob/target = owner.current
	if(!target)
		return
	remove_servant_of_ratvar(target, TRUE)
	message_admins("[key_name_admin(user)] has removed clockwork servant status from [target].")
	log_admin("[key_name(user)] has removed clockwork servant status from [target].")

/datum/antagonist/clockcult/get_admin_commands()
	. = ..()
	.["Give slab"] = CALLBACK(src,PROC_REF(admin_give_slab))

/datum/antagonist/clockcult/proc/admin_give_slab(mob/admin)
	if(!SSticker.mode.equip_servant(owner.current))
		to_chat(admin, "<span class='warning'>Не удалось экипировать [owner.current]!</span>")
	else
		to_chat(admin, "<span class='notice'>Экипировка слуги для [owner.current] успешно выдана!</span>")

/datum/team/clockcult
	name = "Clockcult"
	var/list/objective
	var/datum/mind/eminence
	var/clock_risen = FALSE
	var/clock_ascendent = FALSE

/datum/team/clockcult/proc/check_size()
	if(clock_ascendent)
		return
	var/alive = 0
	var/servantplayers = 0
	for(var/I in GLOB.player_list)
		var/mob/M = I
		if(M.stat != DEAD)
			if(is_servant_of_ratvar(M))
				++servantplayers
			else
				++alive
	if(!alive)
		return
	var/ratio = servantplayers / alive
	if(ratio > CLOCK_RISEN && !clock_risen)
		for(var/datum/mind/B in members)
			if(B.current)
				SEND_SOUND(B.current, 'sound/hallucinations/i_see_you2.ogg')
				to_chat(B.current, "<span class='heavy_brass'>Покров реальности истончается по мере роста вашего культа - ваши глаза начинают светиться...</span>")
				addtimer(CALLBACK(src, PROC_REF(rise), B.current), 200)
		clock_risen = TRUE

	if(ratio > CLOCK_ASCENDENT && !clock_ascendent)
		for(var/datum/mind/B in members)
			if(B.current)
				SEND_SOUND(B.current, 'sound/hallucinations/im_here1.ogg')
				to_chat(B.current, "<span class='large_brass'>Ваш культ достиг расцвета, и приближается час Юстициара. Вы уже не можете скрывать свою истинную природу!</span>")
				addtimer(CALLBACK(src, PROC_REF(ascend), B.current), 200)
		priority_announce("На вашей станции зафиксирована аномальная активность, связанная с культом Ратвара. Данные свидетельствуют о том, что около десятой части экипажа станции уже служит Часовому Юстициару. Служба безопасности получает право свободно применять летальную силу против слуг Ратвара. Прочий персонал должен быть готов защищать себя и свои рабочие места от нападений культистов, в том числе используя летальную силу в качестве крайней меры самообороны, но не должен выслеживать культистов и охотиться на них. Погибшие члены экипажа должны быть оживлены и деконвертированы, как только ситуация будет взята под контроль.", "Центральное Командование, Отдел Работы с Реальностью", 'sound/magic/clockwork/ark_activation_sequence.ogg')
		clock_ascendent = TRUE

/datum/team/clockcult/proc/rise(servant)
	if(ishuman(servant))
		var/mob/living/carbon/human/H = servant
		H.left_eye_color = "be8"
		H.right_eye_color = "be8"
		H.dna?.update_ui_block(DNA_LEFT_EYE_COLOR_BLOCK)
		H.dna?.update_ui_block(DNA_RIGHT_EYE_COLOR_BLOCK)
		H.update_body()

/datum/team/clockcult/proc/ascend(servant)
	var/mob/living/carbon/human/H = servant
	if(!ishuman(H))
		return
	H.add_overlay(mutable_appearance('icons/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER))

/datum/team/clockcult/proc/check_clockwork_victory()
	if(GLOB.clockwork_gateway_activated)
		return TRUE
	return FALSE

/datum/team/clockcult/roundend_report()
	var/list/parts = list()

	if(check_clockwork_victory())
		parts += "<span class='greentext big'>Слуги Ратвара защищали Ковчег до его активации!</span>"
	else
		parts += "<span class='redtext big'>Ковчег был уничтожен! Ратвар будет ржаветь вечно!</span>"
	parts += " "
	parts += "<b>Целью слуг было:</b> [CLOCKCULT_OBJECTIVE]."
	parts += "<b>Стоимость строительства(CV)</b> была: <b>[GLOB.clockwork_construction_value]</b>"
	for(var/i in SSticker.scripture_states)
		if(i != SCRIPTURE_DRIVER)
			parts += "<b>Писания [i]</b> были: <b>[SSticker.scripture_states[i] ? "РАЗ":""]БЛОКИРОВАНЫ</b>"
	if(eminence)
		parts += "<span class='header'>Епископом был:</span> [printplayer(eminence)]"
	if(members.len)
		parts += "<span class='header'>Слугами Ратвара были:</span>"
		parts += printplayerlist(members - eminence)

	return "<div class='panel clockborder'>[parts.Join("<br>")]</div>"

//I have no idea where to put this so I'm leaving it here. Loads reebe. Only one reebe can exist, so it's checked via a global var.
/proc/load_reebe()
	if(GLOB.reebe_loaded)
		return TRUE
	var/list/errorList = list()
	var/list/reebes = SSmapping.LoadGroup(errorList, "Reebe", "map_files/generic", "City_of_Cogs.dmm", default_traits = ZTRAITS_REEBE, silent = TRUE)
	if(errorList.len)	// reebe failed to load
		message_admins("Риб не удалось загрузить")
		log_game("Reebe failed to load!")
		return FALSE
	for(var/datum/parsed_map/PM in reebes)
		PM.initTemplateBounds()
	GLOB.reebe_loaded = TRUE
	return TRUE
