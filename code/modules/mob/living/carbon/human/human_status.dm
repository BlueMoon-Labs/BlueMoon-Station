/mob/verb/human_status()
	set name = "Состояние"
	set desc = "Посмотреть своё состояние"
	set category = "IC"

	if(!client)
		return

	var/datum/component/human_status/HS = GetComponent(/datum/component/human_status)
	if(!HS)
		HS = AddComponent(/datum/component/human_status)
	HS.ui_interact(src, null)


/datum/component/human_status
	var/mob/living/owner

/datum/component/human_status/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	owner = parent


/datum/component/human_status/ui_interact(mob/living/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HumanStatus")
		ui.open()
		if(user)
			user.playsound_local(user, 'sound/health/menuopen.ogg', 30, 1)
	return


/datum/component/human_status/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/carbon/human/owner = parent
	if(!owner)
		return data

	// MARK: Ментальное состояние
	var/datum/component/mood/M = owner.GetComponent(/datum/component/mood)
	if(!M)
		data["sanity_text"] = "Неизвестно"
		data["mood_text"] = "Неизвестно"
		data["mood_events"] = list("Нет данных о состоянии.")
		data["sanity_value"] = 0
		data["mood_value"] = 0
	else
		var/sanity_text
		switch(M.sanity)
			if(SANITY_GREAT to INFINITY)
				sanity_text = "Мой разум чист и спокоен."
			if(SANITY_NEUTRAL to SANITY_GREAT)
				sanity_text = "Чувствую себя отлично."
			if(SANITY_DISTURBED to SANITY_NEUTRAL)
				sanity_text = "Чувствую себя нормально."
			if(SANITY_UNSTABLE to SANITY_DISTURBED)
				sanity_text = "Мне неспокойно..."
			if(SANITY_CRAZY to SANITY_UNSTABLE)
				sanity_text = "Мои мысли путаются."
			if(SANITY_INSANE to SANITY_CRAZY)
				sanity_text = "Ха-ха! Всё прекрасно!!"
			else
				sanity_text = "Состояние рассудка неопределено."

		var/mood_text
		switch(M.mood_level)
			if(1) mood_text = "Не вижу смысла жить."
			if(2) mood_text = "Мне ужасно."
			if(3) mood_text = "Я расстроен."
			if(4) mood_text = "Мне грустно."
			if(5) mood_text = "Я в порядке."
			if(6) mood_text = "Настроение неплохое."
			if(7) mood_text = "Я доволен."
			if(8) mood_text = "Я счастлив."
			if(9) mood_text = "Жизнь прекрасна!"
			else mood_text = "Неопределённое настроение."

		var/list/event_list = list()
		for(var/k in M.mood_events)
			var/datum/mood_event/E = M.mood_events[k]
			if(E && E.description)
				event_list += E.description
		if(!length(event_list))
			event_list += "Ничего особенного не происходит."

		data["sanity_text"] = sanity_text
		data["mood_text"] = mood_text
		data["mood_events"] = event_list
		data["sanity_value"] = M.sanity
		data["mood_value"] = M.mood_level


	// MARK: Повреждения тела и составление иконки
	var/icon/base_icon = icon('icons/mob/human_status_gen.dmi', "human_doll")
	var/list/zones_checked = list(
		BODY_ZONE_HEAD, BODY_ZONE_CHEST,
		BODY_ZONE_L_ARM, BODY_ZONE_R_ARM,
		BODY_ZONE_L_LEG, BODY_ZONE_R_LEG
	)
	var/list/damage_descriptions = list()

	for(var/zone in zones_checked)
		var/obj/item/bodypart/B = owner.get_bodypart(zone)
		var/state_name = ""
		var/severity = 0
		var/part_name = ""

		switch(zone)
			if(BODY_ZONE_HEAD) part_name = "Голова"
			if(BODY_ZONE_CHEST) part_name = "Грудная клетка"
			if(BODY_ZONE_L_ARM) part_name = "Левая рука"
			if(BODY_ZONE_R_ARM) part_name = "Правая рука"
			if(BODY_ZONE_L_LEG) part_name = "Левая нога"
			if(BODY_ZONE_R_LEG) part_name = "Правая нога"

		if(!B || !B.owner)
			state_name = "[lowertext(part_name)]7"
			damage_descriptions += "[part_name] отсутствует."
			severity = 7
		else
			var/total = B.brute_dam + B.burn_dam
			if(total <= 1)
				continue

			var/ratio = total / max(B.max_damage, 1)
			if(ratio >= 0.8)
				severity = 5
				damage_descriptions += "[part_name]: тяжёлые множественные повреждения."
			else if(ratio >= 0.6)
				severity = 4
				damage_descriptions += "[part_name]: глубокие раны и кровоподтёки."
			else if(ratio >= 0.4)
				severity = 3
				damage_descriptions += "[part_name]: заметные повреждения тканей."
			else if(ratio >= 0.2)
				severity = 2
				damage_descriptions += "[part_name]: лёгкие ушибы и ссадины."
			else if(ratio >= 0.05)
				severity = 1
				damage_descriptions += "[part_name]: небольшие покраснения."
			else
				continue

			// MARK: Вставляем информацию о конкретных травмах
			var/list/wound_notes = list()
			for(var/thing in B.wounds)
				var/datum/wound/W = thing
				if(!W)
					continue

				var/wound_name = lowertext(W.name)

				// Простейшая проверка по названию
				if(findtext(wound_name, "fracture") || findtext(wound_name, "перелом"))
					wound_notes += "<span class='boldwarning'>(ПЕРЕЛОМ)</span>"
				else if(findtext(wound_name, "dislocation") || findtext(wound_name, "вывих"))
					wound_notes += "<span class='boldwarning'>(ВЫВИХ)</span>"

			if(length(wound_notes))
				var/notes_text = jointext(wound_notes, " ")
				damage_descriptions += "[part_name]: [notes_text]"

			switch(zone)
				if(BODY_ZONE_HEAD) state_name = "head[severity]"
				if(BODY_ZONE_CHEST) state_name = "chest[severity]"
				if(BODY_ZONE_L_ARM) state_name = "l_arm[severity]"
				if(BODY_ZONE_R_ARM) state_name = "r_arm[severity]"
				if(BODY_ZONE_L_LEG) state_name = "l_leg[severity]"
				if(BODY_ZONE_R_LEG) state_name = "r_leg[severity]"

		if(state_name)
			var/icon/overlay_icon = new('icons/mob/human_status_gen.dmi', state_name)
			if(overlay_icon)
				base_icon.Blend(overlay_icon, ICON_OVERLAY)

	// MARK: Общие физические показатели
	var/overall_text = "Стабильно"
	var/temp_text = "Норма"

	if(owner.bodytemperature >= 360 && owner.bodytemperature <= 370)
		temp_text = "Температура в норме."
	else if(owner.bodytemperature > 370 && owner.bodytemperature <= 390)
		temp_text = "Небольшая температура."
	else if(owner.bodytemperature > 390)
		temp_text = "Высокая температура, чувствую жар."
	else if(owner.bodytemperature < 360 && owner.bodytemperature > 340)
		temp_text = "Чувствую озноб."
	else if(owner.bodytemperature <= 340)
		temp_text = "Очень холодно, тело немеет."

	var/health_ratio = owner.health / max(owner.maxHealth, 1)
	if(health_ratio >= 0.9)
		overall_text = "Чувствую себя хорошо."
	else if(health_ratio >= 0.7)
		overall_text = "Есть лёгкое недомогание."
	else if(health_ratio >= 0.5)
		overall_text = "Чувствую слабость."
	else if(health_ratio >= 0.3)
		overall_text = "С трудом держусь на ногах."
	else
		overall_text = "На грани потери сознания."

	var/critical_warning = FALSE
	if(overall_text == "С трудом держусь на ногах." || overall_text == "На грани потери сознания.")
		critical_warning = TRUE

	// MARK: Нужды (еда и вода)
	var/hunger_text = "В норме"
	var/thirst_text = "В норме"

	switch(owner.nutrition)
		if(NUTRITION_LEVEL_FULL to INFINITY)
			hunger_text = "Я чувствую, что переел."
		if(NUTRITION_LEVEL_WELL_FED to NUTRITION_LEVEL_FULL)
			hunger_text = "Я сыт и доволен."
		if(NUTRITION_LEVEL_HUNGRY to NUTRITION_LEVEL_FED)
			hunger_text = "Неплохо бы перекусить."
		if(NUTRITION_LEVEL_STARVING to NUTRITION_LEVEL_HUNGRY)
			hunger_text = "Я чувствую сильный голод."
		if(0 to NUTRITION_LEVEL_STARVING)
			hunger_text = "Живот сводит от голода!"

	switch(owner.thirst)
		if(THIRST_LEVEL_FULL to INFINITY)
			thirst_text = "Я перепил воды."
		if(THIRST_LEVEL_QUENCHED to THIRST_LEVEL_FULL)
			thirst_text = "Мне не хочется пить."
		if(THIRST_LEVEL_THIRSTY to THIRST_LEVEL_BIT_THIRSTY)
			thirst_text = "Во рту немного пересохло."
		if(THIRST_LEVEL_PARCHED to THIRST_LEVEL_THIRSTY)
			thirst_text = "Я ощущаю жажду."
		if(0 to THIRST_LEVEL_PARCHED)
			thirst_text = "Горло пересохло, я обезвожен!"

	data["overall_text"] = overall_text
	data["temp_text"] = temp_text
	data["damage_descriptions"] = damage_descriptions
	data["hunger_text"] = hunger_text
	data["thirst_text"] = thirst_text
	data["mob_icon"] = base_icon ? icon2base64(base_icon) : null
	data["critical_warning"] = critical_warning

	return data
