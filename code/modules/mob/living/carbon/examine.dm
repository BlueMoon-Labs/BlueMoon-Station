/mob/living/carbon/examine(mob/user)
	var/t_He = ru_who(TRUE)
	var/t_His = ru_ego(TRUE)
	var/t_his = ru_ego()
	//var/t_him = ru_na()
	var/t_has = p_have()
	//var/t_is = p_are()

	. = list("<span class='info'>Это [icon2html(src, user)] \a <EM>[src]</EM>!")

	if (handcuffed)
		. += "<span class='warning'>[t_He] [icon2html(handcuffed, user)] в наручниках!</span>"
	if (head)
		. += "[t_He] носит [head.get_examine_string(user)] на [t_his] голове."
	if (wear_mask)
		. += "[t_He] носит [wear_mask.get_examine_string(user)] на [t_his] лице."
	if (wear_neck)
		. += "[t_He] носит [wear_neck.get_examine_string(user)] вокруг [t_his] шеи.\n"

	for(var/obj/item/I in held_items)
		if(!(I.item_flags & ABSTRACT))
			. += "[t_He] держит [I.get_examine_string(user)] в [t_his] [get_held_index_name(get_held_index_of_item(I))]."

	if (back)
		. += "[t_He] [t_has] [back.get_examine_string(user)] на [t_his] спине."
	var/appears_dead = 0
	if (stat == DEAD)
		appears_dead = 1
		if(getorgan(/obj/item/organ/brain))
			. += "<span class='deadsay'>[t_He] не подает признаков жизни.</span>"
		else if(get_bodypart(BODY_ZONE_HEAD))
			. += "<span class='deadsay'>Похоже, что [t_his] мозг отсутствует...</span>"

	var/list/msg = list("<span class='warning'>")
	var/list/missing = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
	var/list/disabled = list()
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		if(BP.disabled)
			disabled += BP
		missing -= BP.body_zone
		for(var/obj/item/I in BP.embedded_objects)
			if(I.isEmbedHarmless())
				msg += "<B>[t_He] \a [icon2html(I, user)] [I] врезался в [t_his] [BP.ru_name_v]!</B>\n"
			else
				msg += "<B>[t_He] \a [icon2html(I, user)] [I] застрял в [t_his] [BP.ru_name_v]!</B>\n"
		for(var/i in BP.wounds)
			var/datum/wound/W = i
			msg += "[W.get_examine_description(user)]\n"

	for(var/X in disabled)
		var/obj/item/bodypart/BP = X
		var/damage_text
		if(!(BP.get_damage(include_stamina = FALSE) >= BP.max_damage)) //Stamina is disabling the limb
			damage_text = "безжизненна"
		else
			damage_text = (BP.brute_dam >= BP.burn_dam) ? BP.heavy_brute_msg : BP.heavy_burn_msg
		msg += "<B>[capitalize(t_his)] [BP.ru_name] [damage_text]!</B>\n"

	for(var/t in missing)
		if(t==BODY_ZONE_HEAD)
			msg += "<span class='deadsay'><B>[t_His] [ru_parse_zone(t)] отсутствует!</B></span>\n"
			continue
		msg += "<span class='warning'><B>[t_His] [ru_parse_zone(t)] отсутствует!</B></span>\n"

	var/temp = getBruteLoss()
	if(!(user == src && src.hal_screwyhud == SCREWYHUD_HEALTHY)) //fake healthy
		if(temp)
			if (temp < 25)
				msg += "[t_He] [t_has] незначительные увечия.\n"
			else if (temp < 50)
				msg += "[t_He] [t_has] увечия!\n"
			else
				msg += "<B>[t_He] [t_has] сильные увечия!</B>\n"

		temp = getFireLoss()
		if(temp)
			if (temp < 25)
				msg += "[t_He] [t_has] слабые ожоги.\n"
			else if (temp < 50)
				msg += "[t_He] [t_has] ожоги!\n"
			else
				msg += "<B>[t_He] [t_has] сильные ожоги!</B>\n"

		temp = getCloneLoss()
		if(temp)
			if(temp < 25)
				msg += "[t_He] имеет слабые деформации.\n"
			else if (temp < 50)
				msg += "[t_He] имеет деформации!\n"
			else
				msg += "<b>[t_He] имеет сильные деформации!</b>\n"

	if(HAS_TRAIT(src, TRAIT_DUMB))
		msg += "[t_He] выглядит не очень разумно.\n"

	if(fire_stacks > 0)
		msg += "[t_He] в чем-то горючем.\n"
	if(fire_stacks < 0)
		msg += "[t_He] выглядит промокше.\n"

	if(pulledby && pulledby.grab_state)
		msg += "[t_He] удерживается хваткой персонажа [pulledby].\n"

	var/scar_severity = 0
	for(var/i in all_scars)
		var/datum/scar/S = i
		if(S.is_visible(user))
			scar_severity += S.severity

	switch(scar_severity)
		if(1 to 2)
			msg += "<span class='smallnoticeital'>[t_He] [t_has] шрамы, стоит присмотреться получше...</span>\n"
		if(3 to 4)
			msg += "<span class='notice'><i>[t_He] [t_has] ужасные шрамы, стоит присмотреться получше...</i></span>\n"
		if(5 to 6)
			msg += "<span class='notice'><b><i>[t_He] [t_has] огромное количество ужасных шрамов, стоит присмотреться получше...</i></b></span>\n"
		if(7 to INFINITY)
			msg += "<span class='notice'><b><i>[t_He] выглядит невероятно изувеченно, стоит присмотреться получше...</i></b></span>\n"

	if(msg.len)
		. += "<span class='warning'>[msg.Join("")]</span>"

	if(!appears_dead)
		if(stat == UNCONSCIOUS)
			. += "[t_He] не реагирует на происходящее вокруг и похоже спит."
		else if(InCritical())
			. += "[t_His] с трудом дышит."

		if(digitalcamo)
			. += "[t_He] двигает неестественно своим телом."

	if(SEND_SIGNAL(src, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE))
		. += "[t_He] напрягается[CHECK_MOBILITY(src, MOBILITY_STAND) ? "." : ", и встает в боевую стойку."]"

	var/trait_exam = common_trait_examine()
	if (!isnull(trait_exam))
		. += trait_exam

	var/datum/component/mood/mood = src.GetComponent(/datum/component/mood)
	if(mood)
		switch(mood.shown_mood)
			if(-INFINITY to MOOD_LEVEL_SAD4)
				. += "[t_He] выглядит депрессивно."
			if(MOOD_LEVEL_SAD4 to MOOD_LEVEL_SAD3)
				. += "[t_He] выглядит грустно."
			if(MOOD_LEVEL_SAD3 to MOOD_LEVEL_SAD2)
				. += "[t_He] выглядит не очень."
			if(MOOD_LEVEL_HAPPY2 to MOOD_LEVEL_HAPPY3)
				. += "[t_He] выглядит хорошо."
			if(MOOD_LEVEL_HAPPY3 to MOOD_LEVEL_HAPPY4)
				. += "[t_He] выглядит очень хорошо."
			if(MOOD_LEVEL_HAPPY4 to INFINITY)
				. += "[t_He] выглядит счастливо."

	if(LAZYLEN(.) > 1)
		.[1] += "<hr>"

	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, .)

/mob/living/carbon/examine_more(mob/user)
	. = ..()
	if(!LAZYLEN(all_scars))
		return
	var/list/visible_scars
	for(var/i in all_scars)
		var/datum/scar/S = i
		if(S.is_visible(user))
			LAZYADD(visible_scars, S)

	if(visible_scars)
		for(var/i in visible_scars)
			var/datum/scar/S = i
			var/scar_text = S.get_examine_description(user)
			if(scar_text)
				. += "[scar_text]"
