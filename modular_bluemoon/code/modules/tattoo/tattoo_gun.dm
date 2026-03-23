// Tattoo Gun - тату-машинка для нанесения перманентных татуировок
// В отличие от надписей ручкой, татуировки не смываются водой/мылом
// Для удаления требуется хирургическая операция

/// Модификатор скорости при нанесении татуировки (боль замедляет)
/datum/movespeed_modifier/tattoo_pain
	multiplicative_slowdown = 0.3

/obj/item/tattoo_gun
	name = "tattoo gun"
	desc = "Профессиональная тату-машинка для нанесения перманентных татуировок. Татуировки можно удалить только хирургическим путём."
	icon = 'icons/obj/tools.dmi'
	icon_state = "tattoo_gun"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	force = 0
	throwforce = 0
	item_flags = NOBLUDGEON

	/// Цвет чернил для татуировки
	var/ink_color = "#4A4A4A"
	/// Название стиля чернил
	var/ink_style = "тёмно-серые"

/obj/item/tattoo_gun/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/item/tattoo_gun/examine(mob/user)
	. = ..()
	. += span_notice("Текущий цвет чернил: <span style='color:[ink_color]'>[ink_style]</span>.")
	. += span_notice("Используйте Alt+ЛКМ чтобы сменить цвет чернил.")
	. += span_warning("Татуировки можно удалить только хирургическим путём!")

/obj/item/tattoo_gun/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	var/choice = input(user, "Выберите цвет чернил для татуировки:", "Цвет чернил") as null|anything in GLOB.tattoo_ink_colors
	if(!choice || !user.canUseTopic(src, BE_CLOSE))
		return

	ink_color = GLOB.tattoo_ink_colors[choice]
	ink_style = lowertext(choice)
	to_chat(user, span_notice("Вы заправили [src] [ink_style] чернилами."))

/obj/item/tattoo_gun/attack(mob/living/M, mob/living/user)
	if(!istype(M) || !iscarbon(M))
		return ..()

	if(user.a_intent == INTENT_HARM)
		return ..()

	var/mob/living/carbon/human/target = M
	if(!ishuman(target))
		to_chat(user, span_warning("Вы не можете набить татуировку этому существу!"))
		return

	// Проверка на кататоника (SSD/отключённого игрока)
	if(!target.client && user != target)
		to_chat(user, span_warning("[target] находится без сознания (SSD). Вы не можете набить татуировку отключённому игроку!"))
		return

	// Проверка согласия на татуировки (только если набиваем другому игроку)
	if(user != target && target.client?.prefs?.tattoopref == "No")
		to_chat(user, span_warning("[target] не разрешает делать себе татуировки!"))
		return

	// Если у цели стоит "Ask", спрашиваем разрешение
	if(user != target && target.client?.prefs?.tattoopref == "Ask")
		var/consent = tgui_alert(target, "[user] хочет набить вам татуировку. Разрешить?", "Запрос на татуировку", list("Да", "Нет"))
		if(consent != "Да")
			to_chat(user, span_warning("[target] отказался от татуировки."))
			return
		if(!user.canUseTopic(src, BE_CLOSE))
			return

	// Выбор части тела через радиальное меню
	var/selected_zone = select_body_zone_radial(user, target)
	if(!selected_zone)
		return

	// Проверка на одежду (используем централизованную функцию)
	var/list/items_on_target = target.get_equipped_items()
	if(is_tattoo_zone_covered(selected_zone, items_on_target, target))
		var/body_covered = tattoo_zone_to_body_covered(selected_zone)
		if(body_covered == TATTOO_COVERED_MOUTH)
			to_chat(user, span_warning("Вам мешает маска [target]!"))
		else
			to_chat(user, span_warning("Вам мешает одежда [target]!"))
		return

	// Определяем тип зоны и реальную часть тела
	var/actual_zone = selected_zone
	var/intimate_zone = null // Для интимных зон: TATTOO_ZONE_GROIN, TATTOO_ZONE_BUTT, TATTOO_ZONE_PUSSY, TATTOO_ZONE_TESTICLES

	switch(selected_zone)
		if(BODY_ZONE_PRECISE_GROIN)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_GROIN
		if(TATTOO_ZONE_BUTT)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_BUTT
		if(TATTOO_ZONE_PUSSY)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_PUSSY
		if(TATTOO_ZONE_TESTICLES)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_TESTICLES
		if(TATTOO_ZONE_BREASTS)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_BREASTS
		if(TATTOO_ZONE_PENIS)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_PENIS
		if(TATTOO_ZONE_LIPS)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_LIPS
		if(TATTOO_ZONE_HORNS)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_HORNS
		if(TATTOO_ZONE_TAIL)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_TAIL
		if(TATTOO_ZONE_LEFT_THIGH)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_LEFT_THIGH
		if(TATTOO_ZONE_RIGHT_THIGH)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_RIGHT_THIGH
		if(TATTOO_ZONE_EARS)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_EARS
		if(TATTOO_ZONE_WINGS)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_WINGS
		if(TATTOO_ZONE_BELLY)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_BELLY
		if(TATTOO_ZONE_CHEEKS)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_CHEEKS
		if(TATTOO_ZONE_FOREHEAD)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_FOREHEAD
		if(TATTOO_ZONE_CHIN)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_CHIN
		if(TATTOO_ZONE_LEFT_HAND)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_LEFT_HAND
		if(TATTOO_ZONE_RIGHT_HAND)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_RIGHT_HAND
		if(TATTOO_ZONE_LEFT_FOOT)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_LEFT_FOOT
		if(TATTOO_ZONE_RIGHT_FOOT)
			actual_zone = BODY_ZONE_CHEST
			intimate_zone = TATTOO_ZONE_RIGHT_FOOT

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		to_chat(user, span_warning("У [target] отсутствует эта часть тела!"))
		return

	var/zone_name = get_tattoo_zone_name(selected_zone, BP)
	var/tattoo_text = tgui_input_text(user, "Введите текст или описание татуировки (макс. 150 символов):", "Татуировка на [zone_name]", max_length = 150)
	if(!tattoo_text)
		return

	if(!user.canUseTopic(src, BE_CLOSE))
		return

	// Выбор стиля татуировки: надпись (в кавычках) или описание (без кавычек)
	var/list/style_choices = list(
		"Надпись" = "T",
		"Описание" = "D"
	)
	var/style_choice = tgui_alert(user, "Выберите стиль отображения татуировки:\n\n\"Надпись\" - текст в кавычках (например: \"ACAB\")\n\"Описание\" - описание узора (например: кельтский узор)", "Стиль татуировки", list("Надпись", "Описание"))
	if(!style_choice)
		return

	if(!user.canUseTopic(src, BE_CLOSE))
		return

	var/style_prefix = "\[[style_choices[style_choice]]\]"

	if(user != target)
		user.visible_message(span_notice("[user] начинает набивать татуировку на [zone_name] [target]."), \
			span_notice("Вы начинаете набивать татуировку на [zone_name] [target]."))
	else
		to_chat(user, span_notice("Вы начинаете набивать себе татуировку на [zone_name]."))

	// Эффекты боли во время нанесения
	to_chat(target, span_warning("Вы чувствуете острую боль от иглы тату-машинки!"))
	target.Jitter(10)

	target.add_movespeed_modifier(/datum/movespeed_modifier/tattoo_pain)

	var/success = do_mob(user, target, 8 SECONDS)

	target.remove_movespeed_modifier(/datum/movespeed_modifier/tattoo_pain)

	if(!success)
		to_chat(user, span_warning("Процесс нанесения татуировки прерван!"))
		return

	// Проверяем лимит символов на части тела
	var/new_tattoo = "<span style='color:[ink_color]'>[style_prefix][html_encode(tattoo_text)]</span>"
	var/current_tattoo = get_tattoo_text_for_zone(BP, intimate_zone)
	if((length(current_tattoo) + length(new_tattoo)) > 500)
		to_chat(user, span_warning("На [zone_name] [target] недостаточно места для ещё одной татуировки!"))
		return

	// Добавляем татуировку в соответствующую переменную
	set_tattoo_text_for_zone(BP, intimate_zone, current_tattoo ? (current_tattoo + "; " + new_tattoo) : new_tattoo)

	if(user != target)
		user.visible_message(span_notice("[user] набил[user.ru_a()] татуировку на [zone_name] [target]."), \
			span_notice("Вы набили татуировку на [zone_name] [target]."))
		to_chat(target, span_notice("[user] набил[user.ru_a()] вам татуировку на [zone_name]!"))
	else
		to_chat(user, span_notice("Вы набили себе татуировку на [zone_name]."))

	// Урон от иглы
	target.apply_damage(2, BRUTE, BP)

	// Немедленное сохранение татуировки (защита от краша сервера)
	target.save_tattoos_now()

/// Выбор части тела через радиальное меню
/obj/item/tattoo_gun/proc/select_body_zone_radial(mob/user, mob/living/carbon/human/target)
	var/list/body_zones = list()

	// Добавляем только те части тела, которые есть у цели
	if(target.get_bodypart(BODY_ZONE_HEAD))
		body_zones["Голова"] = GLOB.tattoo_radial_icons[BODY_ZONE_HEAD]
		body_zones["Губы"] = GLOB.tattoo_radial_icons[BODY_ZONE_PRECISE_MOUTH]
		body_zones["Щёки"] = GLOB.tattoo_radial_icons[BODY_ZONE_HEAD]
		body_zones["Лоб"] = GLOB.tattoo_radial_icons[BODY_ZONE_HEAD]
		body_zones["Подбородок"] = GLOB.tattoo_radial_icons[BODY_ZONE_HEAD]
		// Рога - проверяем через мутантные части вида
		if(target.dna?.species?.mutant_bodyparts["horns"] && target.dna.features["horns"] && target.dna.features["horns"] != "None")
			body_zones["Рога"] = GLOB.tattoo_radial_icons[BODY_ZONE_HEAD]
		// Уши - проверяем через мутантные части вида
		var/has_ears = FALSE
		if(target.dna?.species?.mutant_bodyparts["ears"] && target.dna.features["ears"] && target.dna.features["ears"] != "None")
			has_ears = TRUE
		else if(target.dna?.species?.mutant_bodyparts["mam_ears"] && target.dna.features["mam_ears"] && target.dna.features["mam_ears"] != "None")
			has_ears = TRUE
		if(has_ears)
			body_zones["Уши"] = GLOB.tattoo_radial_icons[BODY_ZONE_HEAD]
	if(target.get_bodypart(BODY_ZONE_CHEST))
		body_zones["Туловище"] = GLOB.tattoo_radial_icons[BODY_ZONE_CHEST]
		body_zones["Пах"] = GLOB.tattoo_radial_icons[BODY_ZONE_PRECISE_GROIN]
		// Хвост - проверяем через орган
		if(target.getorganslot(ORGAN_SLOT_TAIL))
			body_zones["Хвост"] = GLOB.tattoo_radial_icons[BODY_ZONE_PRECISE_GROIN]
		// Крылья - проверяем через мутантные части вида
		var/has_wings = FALSE
		if(target.dna?.species?.mutant_bodyparts["wings"] && target.dna.features["wings"] && target.dna.features["wings"] != "None")
			has_wings = TRUE
		else if(target.dna?.species?.mutant_bodyparts["deco_wings"] && target.dna.features["deco_wings"] && target.dna.features["deco_wings"] != "None")
			has_wings = TRUE
		else if(target.dna?.species?.mutant_bodyparts["insect_wings"] && target.dna.features["insect_wings"] && target.dna.features["insect_wings"] != "None")
			has_wings = TRUE
		if(has_wings)
			body_zones["Крылья"] = GLOB.tattoo_radial_icons[BODY_ZONE_CHEST]
		// Живот - проверяем через орган
		if(target.getorganslot(ORGAN_SLOT_BELLY))
			body_zones["Живот"] = GLOB.tattoo_radial_icons[BODY_ZONE_CHEST]
		// Интимные зоны - генерируем динамические иконки на основе органов персонажа
		for(var/zone in GLOB.tattoo_zone_data)
			var/list/data = GLOB.tattoo_zone_data[zone]
			var/organ_slot = data[TATTOO_DATA_ORGAN]
			if(!organ_slot || organ_slot == ORGAN_SLOT_TAIL || organ_slot == ORGAN_SLOT_BELLY)
				continue
			var/image/organ_icon = generate_genital_radial_icon(target, organ_slot)
			if(organ_icon)
				body_zones[data[TATTOO_DATA_NAME_NOM]] = organ_icon
	if(target.get_bodypart(BODY_ZONE_L_ARM))
		body_zones["Левая рука"] = GLOB.tattoo_radial_icons[BODY_ZONE_L_ARM]
		body_zones["Левая кисть"] = GLOB.tattoo_radial_icons[BODY_ZONE_L_ARM]
	if(target.get_bodypart(BODY_ZONE_R_ARM))
		body_zones["Правая рука"] = GLOB.tattoo_radial_icons[BODY_ZONE_R_ARM]
		body_zones["Правая кисть"] = GLOB.tattoo_radial_icons[BODY_ZONE_R_ARM]
	if(target.get_bodypart(BODY_ZONE_L_LEG))
		body_zones["Левая нога"] = GLOB.tattoo_radial_icons[BODY_ZONE_L_LEG]
		body_zones["Левое бедро"] = GLOB.tattoo_radial_icons[BODY_ZONE_L_LEG]
		body_zones["Левая ступня"] = GLOB.tattoo_radial_icons[BODY_ZONE_L_LEG]
	if(target.get_bodypart(BODY_ZONE_R_LEG))
		body_zones["Правая нога"] = GLOB.tattoo_radial_icons[BODY_ZONE_R_LEG]
		body_zones["Правое бедро"] = GLOB.tattoo_radial_icons[BODY_ZONE_R_LEG]
		body_zones["Правая ступня"] = GLOB.tattoo_radial_icons[BODY_ZONE_R_LEG]

	if(!length(body_zones))
		to_chat(user, span_warning("У [target] нет доступных частей тела для татуировки!"))
		return null

	var/choice = show_radial_menu(user, target, body_zones, require_near = TRUE, tooltips = TRUE)
	if(!choice)
		return null

	return zone_name_to_zone(choice)
