// Tattoo Gun - тату-машинка для нанесения перманентных татуировок
// В отличие от надписей ручкой, татуировки не смываются водой/мылом
// Для удаления требуется хирургическая операция

/obj/item/tattoo_gun
	name = "tattoo gun"
	desc = "Профессиональная тату-машинка для нанесения перманентных татуировок. Татуировки можно удалить только хирургическим путём."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "pen"
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

	var/list/ink_choices = list(
		"Тёмно-серые" = "#4A4A4A",
		"Белые" = "#FFFFFF",
		"Огненно-красные" = "#FF3232",
		"Алые" = "#DC143C",
		"Бордовые" = "#8B0000",
		"Розовые" = "#FF69B4",
		"Коралловые" = "#FF7F50",
		"Оранжевые" = "#FF8C00",
		"Ярко-жёлтые" = "#FFFF00",
		"Золотые" = "#FFD700",
		"Кислотно-зелёные" = "#00FF00",
		"Изумрудные" = "#50C878",
		"Тёмно-зелёные" = "#228B22",
		"Бирюзовые" = "#40E0D0",
		"Электро-голубые" = "#00FFFF",
		"Небесно-голубые" = "#87CEEB",
		"Синие" = "#4169E1",
		"Тёмно-синие" = "#00008B",
		"Фиолетовые" = "#B900F7",
		"Лавандовые" = "#9B51FF",
		"Пурпурные" = "#800080",
		"Неоново-розовые" = "#FF00FF",
		"Серебряные" = "#C0C0C0",
		"Бронзовые" = "#CD7F32"
	)

	var/choice = input(user, "Выберите цвет чернил для татуировки:", "Цвет чернил") as null|anything in ink_choices
	if(!choice || !user.canUseTopic(src, BE_CLOSE))
		return

	ink_color = ink_choices[choice]
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

	// Проверка на одежду
	var/target_body_part = tattoo_zone_to_body_covered(selected_zone)
	if(!target_body_part)
		to_chat(user, span_warning("Вы должны выбрать часть тела!"))
		return

	var/list/items_on_target = target.get_equipped_items()
	for(var/obj/item/worn_clothes in items_on_target)
		if(worn_clothes.body_parts_covered & target_body_part)
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

	// Нанесение татуировки занимает 8 секунд
	if(!do_mob(user, target, 8 SECONDS))
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

	// Небольшой урон от иглы
	target.apply_damage(1, BRUTE, BP)

	// Немедленное сохранение татуировки (защита от краша сервера)
	target.save_tattoos_now()

/// Генерирует динамическую иконку для органа персонажа
/proc/generate_genital_radial_icon(mob/living/carbon/human/target, organ_slot)
	var/obj/item/organ/genital/G = target.getorganslot(organ_slot)
	if(!G)
		return null

	var/datum/sprite_accessory/S
	var/size = G.size_to_state()

	switch(G.type)
		if(/obj/item/organ/genital/penis)
			S = GLOB.cock_shapes_list[G.shape]
		if(/obj/item/organ/genital/testicles)
			S = GLOB.balls_shapes_list[G.shape]
		if(/obj/item/organ/genital/vagina)
			S = GLOB.vagina_shapes_list[G.shape]
		if(/obj/item/organ/genital/breasts)
			S = GLOB.breasts_shapes_list[G.shape]
		if(/obj/item/organ/genital/butt)
			S = GLOB.butt_shapes_list[G.shape]

	if(!S || S.icon_state == "none")
		return null

	var/icon_state_str = "[G.slot]_[S.icon_state]_[size]_0_FRONT"
	var/image/I = image(icon = S.icon, icon_state = icon_state_str)

	// Применяем цвет органа
	if(target.dna?.species?.use_skintones && target.dna.features["genitals_use_skintone"])
		I.color = SKINTONE2HEX(target.skin_tone)
	else if(S.color_src && target.dna)
		switch(S.color_src)
			if("cock_color")
				I.color = "#[target.dna.features["cock_color"]]"
			if("balls_color")
				I.color = "#[target.dna.features["balls_color"]]"
			if("breasts_color")
				I.color = "#[target.dna.features["breasts_color"]]"
			if("vag_color")
				I.color = "#[target.dna.features["vag_color"]]"
			if("butt_color")
				I.color = "#[target.dna.features["butt_color"]]"

	return I

/// Выбор части тела через радиальное меню
/obj/item/tattoo_gun/proc/select_body_zone_radial(mob/user, mob/living/carbon/human/target)
	var/list/body_zones = list()

	// Статические иконки для основных частей тела
	var/static/list/base_zone_icons
	if(!base_zone_icons)
		base_zone_icons = list()
		base_zone_icons[BODY_ZONE_HEAD] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "head")
		base_zone_icons[BODY_ZONE_CHEST] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "chest")
		base_zone_icons[BODY_ZONE_PRECISE_GROIN] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "crotch")
		base_zone_icons[BODY_ZONE_L_ARM] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_arm")
		base_zone_icons[BODY_ZONE_R_ARM] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_arm")
		base_zone_icons[BODY_ZONE_L_LEG] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_leg")
		base_zone_icons[BODY_ZONE_R_LEG] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_leg")

	// Добавляем только те части тела, которые есть у цели
	if(target.get_bodypart(BODY_ZONE_HEAD))
		body_zones["Голова"] = base_zone_icons[BODY_ZONE_HEAD]
	if(target.get_bodypart(BODY_ZONE_CHEST))
		body_zones["Туловище"] = base_zone_icons[BODY_ZONE_CHEST]
		body_zones["Пах"] = base_zone_icons[BODY_ZONE_PRECISE_GROIN]
		// Интимные зоны - генерируем динамические иконки на основе органов персонажа
		var/image/breasts_icon = generate_genital_radial_icon(target, ORGAN_SLOT_BREASTS)
		if(breasts_icon)
			body_zones["Грудь"] = breasts_icon
		var/image/butt_icon = generate_genital_radial_icon(target, ORGAN_SLOT_BUTT)
		if(butt_icon)
			body_zones["Ягодицы"] = butt_icon
		var/image/vagina_icon = generate_genital_radial_icon(target, ORGAN_SLOT_VAGINA)
		if(vagina_icon)
			body_zones["Лобок"] = vagina_icon
		var/image/testicles_icon = generate_genital_radial_icon(target, ORGAN_SLOT_TESTICLES)
		if(testicles_icon)
			body_zones["Яички"] = testicles_icon
		var/image/penis_icon = generate_genital_radial_icon(target, ORGAN_SLOT_PENIS)
		if(penis_icon)
			body_zones["Член"] = penis_icon
	if(target.get_bodypart(BODY_ZONE_L_ARM))
		body_zones["Левая рука"] = base_zone_icons[BODY_ZONE_L_ARM]
	if(target.get_bodypart(BODY_ZONE_R_ARM))
		body_zones["Правая рука"] = base_zone_icons[BODY_ZONE_R_ARM]
	if(target.get_bodypart(BODY_ZONE_L_LEG))
		body_zones["Левая нога"] = base_zone_icons[BODY_ZONE_L_LEG]
	if(target.get_bodypart(BODY_ZONE_R_LEG))
		body_zones["Правая нога"] = base_zone_icons[BODY_ZONE_R_LEG]

	if(!length(body_zones))
		to_chat(user, span_warning("У [target] нет доступных частей тела для татуировки!"))
		return null

	var/choice = show_radial_menu(user, target, body_zones, require_near = TRUE, tooltips = TRUE)
	if(!choice)
		return null

	switch(choice)
		if("Голова")
			return BODY_ZONE_HEAD
		if("Туловище")
			return BODY_ZONE_CHEST
		if("Пах")
			return BODY_ZONE_PRECISE_GROIN
		if("Грудь")
			return TATTOO_ZONE_BREASTS
		if("Ягодицы")
			return TATTOO_ZONE_BUTT
		if("Лобок")
			return TATTOO_ZONE_PUSSY
		if("Яички")
			return TATTOO_ZONE_TESTICLES
		if("Член")
			return TATTOO_ZONE_PENIS
		if("Левая рука")
			return BODY_ZONE_L_ARM
		if("Правая рука")
			return BODY_ZONE_R_ARM
		if("Левая нога")
			return BODY_ZONE_L_LEG
		if("Правая нога")
			return BODY_ZONE_R_LEG

	return null

/// Получает название зоны для отображения
/proc/get_tattoo_zone_name(zone, obj/item/bodypart/BP)
	switch(zone)
		if(BODY_ZONE_PRECISE_GROIN)
			return "паху"
		if(TATTOO_ZONE_BUTT)
			return "ягодицах"
		if(TATTOO_ZONE_PUSSY)
			return "лобке"
		if(TATTOO_ZONE_TESTICLES)
			return "яичках"
		if(TATTOO_ZONE_BREASTS)
			return "груди"
		if(TATTOO_ZONE_PENIS)
			return "члене"
	return BP?.ru_name_v

/// Получает текст татуировки для указанной зоны
/proc/get_tattoo_text_for_zone(obj/item/bodypart/BP, intimate_zone)
	if(!BP)
		return ""
	switch(intimate_zone)
		if(TATTOO_ZONE_GROIN)
			return BP.groin_tattoo_text
		if(TATTOO_ZONE_BUTT)
			return BP.butt_tattoo_text
		if(TATTOO_ZONE_PUSSY)
			return BP.pussy_tattoo_text
		if(TATTOO_ZONE_TESTICLES)
			return BP.testicles_tattoo_text
		if(TATTOO_ZONE_BREASTS)
			return BP.breasts_tattoo_text
		if(TATTOO_ZONE_PENIS)
			return BP.penis_tattoo_text
	return BP.tattoo_text

/// Устанавливает текст татуировки для указанной зоны
/proc/set_tattoo_text_for_zone(obj/item/bodypart/BP, intimate_zone, text)
	if(!BP)
		return
	switch(intimate_zone)
		if(TATTOO_ZONE_GROIN)
			BP.groin_tattoo_text = text
		if(TATTOO_ZONE_BUTT)
			BP.butt_tattoo_text = text
		if(TATTOO_ZONE_PUSSY)
			BP.pussy_tattoo_text = text
		if(TATTOO_ZONE_TESTICLES)
			BP.testicles_tattoo_text = text
		if(TATTOO_ZONE_BREASTS)
			BP.breasts_tattoo_text = text
		if(TATTOO_ZONE_PENIS)
			BP.penis_tattoo_text = text
		else
			BP.tattoo_text = text

/// Проверяет, является ли зона интимной
/proc/is_intimate_tattoo_zone(zone)
	return zone in list(BODY_ZONE_PRECISE_GROIN, TATTOO_ZONE_BUTT, TATTOO_ZONE_PUSSY, TATTOO_ZONE_TESTICLES, TATTOO_ZONE_BREASTS, TATTOO_ZONE_PENIS)

/// Преобразует зону татуировки в интимную зону (для persistence)
/proc/zone_to_intimate_zone(zone)
	switch(zone)
		if(BODY_ZONE_PRECISE_GROIN)
			return TATTOO_ZONE_GROIN
		if(TATTOO_ZONE_BUTT, TATTOO_ZONE_PUSSY, TATTOO_ZONE_TESTICLES, TATTOO_ZONE_BREASTS, TATTOO_ZONE_PENIS)
			return zone
	return null

/// Получает флаг покрытия тела для зоны татуировки
/proc/tattoo_zone_to_body_covered(zone)
	switch(zone)
		if(BODY_ZONE_HEAD)
			return HEAD
		if(BODY_ZONE_CHEST)
			return CHEST
		if(TATTOO_ZONE_BREASTS)
			return CHEST
		if(BODY_ZONE_PRECISE_GROIN, TATTOO_ZONE_GROIN, TATTOO_ZONE_BUTT, TATTOO_ZONE_PUSSY, TATTOO_ZONE_TESTICLES, TATTOO_ZONE_PENIS)
			return GROIN
		if(BODY_ZONE_L_ARM)
			return ARM_LEFT
		if(BODY_ZONE_R_ARM)
			return ARM_RIGHT
		if(BODY_ZONE_L_LEG)
			return LEG_LEFT
		if(BODY_ZONE_R_LEG)
			return LEG_RIGHT
	return null
