// Хирургическая операция по удалению татуировок
// Единственный способ убрать перманентные татуировки

/datum/surgery/tattoo_removal
	name = "Удаление татуировки"
	desc = "Хирургическая процедура по удалению татуировок с кожи."
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/remove_tattoo,
		/datum/surgery_step/close
	)
	possible_locs = list(
		BODY_ZONE_HEAD,
		BODY_ZONE_PRECISE_MOUTH,
		BODY_ZONE_CHEST,
		BODY_ZONE_PRECISE_GROIN,
		BODY_ZONE_L_ARM,
		BODY_ZONE_R_ARM,
		BODY_ZONE_L_LEG,
		BODY_ZONE_R_LEG
	)
	requires_bodypart_type = BODYPART_ORGANIC
	is_healing = FALSE
	icon_state = "surgery_any"
	radial_priority = SURGERY_RADIAL_PRIORITY_OTHER_SECOND

/datum/surgery/tattoo_removal/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	. = ..()
	if(!.)
		return FALSE

	// Проверка на кататоника (SSD/отключённого игрока)
	// Нельзя удалять татуировки у отключённых игроков, т.к. сохранение всё равно не сработает
	if(!target.client && user != target)
		return FALSE

	var/target_zone = user.zone_selected
	// Для паха и рта используем соответствующие части тела
	var/actual_bodypart_zone = target_zone
	switch(target_zone)
		if(BODY_ZONE_PRECISE_GROIN)
			actual_bodypart_zone = BODY_ZONE_CHEST
		if(BODY_ZONE_PRECISE_MOUTH)
			actual_bodypart_zone = BODY_ZONE_HEAD

	var/obj/item/bodypart/BP = target.get_bodypart(actual_bodypart_zone)
	if(!BP)
		return FALSE

	// Проверяем есть ли хоть одна татуировка на этой зоне или её подзонах
	if(has_any_tattoo_on_zone(BP, target_zone, target))
		return TRUE

	return FALSE

// Шаг удаления татуировки (повторяемый)
/datum/surgery_step/remove_tattoo
	name = "Удалить татуировку"
	implements = list(
		TOOL_SCALPEL = 100,
		/obj/item/kitchen/knife = 65,
		TOOL_WIRECUTTER = 40
	)
	time = 40
	repeatable = TRUE

/datum/surgery_step/remove_tattoo/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	// Для паха и рта используем соответствующие части тела
	var/actual_bodypart_zone = target_zone
	switch(target_zone)
		if(BODY_ZONE_PRECISE_GROIN)
			actual_bodypart_zone = BODY_ZONE_CHEST
		if(BODY_ZONE_PRECISE_MOUTH)
			actual_bodypart_zone = BODY_ZONE_HEAD

	var/obj/item/bodypart/BP = target.get_bodypart(actual_bodypart_zone)
	if(!BP)
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	var/selected_zone = select_tattoo_zone_for_surgery(user, target, target_zone, BP)
	if(!selected_zone)
		return -1

	surgery.selected_tattoo_zone = selected_zone
	var/intimate_zone = zone_to_intimate_zone(selected_zone)

	// Для интимных зон (включая губы) татуировки хранятся на груди
	if(intimate_zone)
		BP = target.get_bodypart(BODY_ZONE_CHEST)
		if(!BP)
			to_chat(user, span_warning("На этой части тела нет татуировок!"))
			return -1

	var/tattoo_text_raw = get_tattoo_text_for_zone(BP, intimate_zone)
	if(!tattoo_text_raw)
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	// Парсим татуировки в читаемый формат
	var/list/raw_tattoos = splittext(tattoo_text_raw, "; ")
	var/list/display_choices = list()
	var/list/raw_to_display = list() // Маппинг отображаемого текста к сырому

	for(var/raw_tattoo in raw_tattoos)
		if(!length(raw_tattoo))
			continue
		var/display_text = parse_tattoo_for_selection(raw_tattoo)
		display_choices += display_text
		raw_to_display[display_text] = raw_tattoo

	if(!length(display_choices))
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	var/zone_name = get_tattoo_zone_name_genitive(selected_zone, BP)
	var/choice = tgui_input_list(user, "Выберите татуировку для удаления с [zone_name]:", "Удаление татуировки", display_choices)

	if(!choice)
		return -1

	surgery.tattoo_to_remove = raw_to_display[choice]

	var/zone_name_prep = get_tattoo_zone_name(selected_zone, BP)
	display_results(
		user,
		target,
		span_notice("Вы начинаете аккуратно срезать татуировку \"[choice]\" с [zone_name] [target]..."),
		span_notice("[user] начинает аккуратно срезать кожу на [zone_name_prep] [target]."),
		span_notice("[user] делает надрезы на [zone_name_prep] [target].")
	)

/datum/surgery_step/remove_tattoo/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/selected_zone = surgery.selected_tattoo_zone || target_zone
	var/intimate_zone = zone_to_intimate_zone(selected_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : selected_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		return FALSE

	var/tattoo_text = get_tattoo_text_for_zone(BP, intimate_zone)
	var/list/tattoos = splittext(tattoo_text, "; ")
	tattoos -= surgery.tattoo_to_remove
	set_tattoo_text_for_zone(BP, intimate_zone, jointext(tattoos, "; "))

	var/zone_name_gen = get_tattoo_zone_name_genitive(selected_zone, BP)
	var/zone_name_prep = get_tattoo_zone_name(selected_zone, BP)
	var/removed_display = parse_tattoo_for_selection(surgery.tattoo_to_remove)
	display_results(
		user,
		target,
		span_notice("Вы успешно удалили татуировку \"[removed_display]\" с [zone_name_gen] [target]."),
		span_notice("[user] успешно удаляет татуировку с [zone_name_gen] [target]."),
		span_notice("[user] заканчивает работу на [zone_name_prep] [target].")
	)

	target.apply_damage(3, BRUTE, BP)

	// Немедленное сохранение
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.save_tattoos_now()

	// Очищаем для следующей итерации
	surgery.tattoo_to_remove = ""
	surgery.selected_tattoo_zone = ""

	return TRUE

/datum/surgery_step/remove_tattoo/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	var/selected_zone = surgery.selected_tattoo_zone || target_zone
	var/intimate_zone = zone_to_intimate_zone(selected_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : selected_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		return

	display_results(
		user,
		target,
		span_warning("Вы случайно порезали кожу слишком глубоко!"),
		span_warning("[user] случайно режет слишком глубоко!"),
		span_warning("[user] делает резкое движение скальпелем!")
	)

	target.apply_damage(10, BRUTE, BP)

// Расширение датума хирургии для хранения данных татуировки
/datum/surgery
	/// Татуировка, которую нужно удалить (сырой текст)
	var/tattoo_to_remove = ""
	/// Выбранная зона для удаления татуировки (включая интимные подзоны)
	var/selected_tattoo_zone = ""

/// Парсит сырой текст татуировки в читаемый формат для выбора
/// Убирает HTML-теги и показывает тип: [Надпись] или [Описание]
/proc/parse_tattoo_for_selection(raw_tattoo)
	if(!raw_tattoo || raw_tattoo == "")
		return ""

	var/is_description = findtext(raw_tattoo, "\[D]")
	var/type_prefix = is_description ? "\[Описание]" : "\[Надпись]"

	var/clean_text = raw_tattoo

	// Убираем <span style='...'> - ищем начало и конец тега
	var/span_start = findtext(clean_text, "<span style='")
	while(span_start)
		var/span_end = findtext(clean_text, "'>", span_start)
		if(span_end)
			clean_text = copytext(clean_text, 1, span_start) + copytext(clean_text, span_end + 2)
		else
			break
		span_start = findtext(clean_text, "<span style='")

	clean_text = replacetext(clean_text, "</span>", "")

	// Убираем маркеры типа
	clean_text = replacetext(clean_text, "\[T]", "")
	clean_text = replacetext(clean_text, "\[D]", "")

	// Убираем лишние пробелы
	clean_text = trim(clean_text)

	return "[type_prefix] [clean_text]"

/// Проверяет, есть ли хоть одна татуировка на зоне или её подзонах
/proc/has_any_tattoo_on_zone(obj/item/bodypart/BP, target_zone, mob/living/carbon/human/target)
	if(!BP)
		return FALSE

	var/obj/item/bodypart/chest = target.get_bodypart(BODY_ZONE_CHEST)

	// Для головы - только обычная татуировка на голове
	if(target_zone == BODY_ZONE_HEAD)
		return length(BP.tattoo_text)

	// Для рта - губы (хранятся на груди)
	if(target_zone == BODY_ZONE_PRECISE_MOUTH)
		return chest && length(chest.lips_tattoo_text)

	// Для торса - туловище + груди (breasts)
	if(target_zone == BODY_ZONE_CHEST)
		if(length(BP.tattoo_text))
			return TRUE
		var/list/breast_data = GLOB.tattoo_zone_data[TATTOO_ZONE_BREASTS]
		if(target.getorganslot(breast_data[TATTOO_DATA_ORGAN]) && length(BP.vars[breast_data[TATTOO_DATA_VAR]]))
			return TRUE
		return FALSE

	// Для паха - пах + ягодицы + член + яички + лобок (всё кроме груди и губ)
	if(target_zone == BODY_ZONE_PRECISE_GROIN)
		if(chest && length(chest.groin_tattoo_text))
			return TRUE
		for(var/zone in GLOB.tattoo_zone_data)
			if(zone == TATTOO_ZONE_BREASTS || zone == TATTOO_ZONE_GROIN || zone == TATTOO_ZONE_LIPS)
				continue
			var/list/data = GLOB.tattoo_zone_data[zone]
			var/organ_slot = data[TATTOO_DATA_ORGAN]
			if(organ_slot && !target.getorganslot(organ_slot))
				continue
			if(chest && length(chest.vars[data[TATTOO_DATA_VAR]]))
				return TRUE
		return FALSE

	// Для остальных зон (руки, ноги) - просто проверяем основную татуировку
	return length(BP.tattoo_text)

/// Выбор конкретной зоны татуировки для хирургии через радиальное меню
/proc/select_tattoo_zone_for_surgery(mob/user, mob/living/carbon/human/target, target_zone, obj/item/bodypart/BP)
	// Для простых зон без подзон - сразу возвращаем
	// Голова, рот, руки, ноги - не имеют подзон для выбора
	if(target_zone == BODY_ZONE_HEAD)
		return target_zone
	if(target_zone == BODY_ZONE_PRECISE_MOUTH)
		return TATTOO_ZONE_LIPS
	if(target_zone != BODY_ZONE_CHEST && target_zone != BODY_ZONE_PRECISE_GROIN)
		return target_zone

	var/list/available_zones = list()
	var/obj/item/bodypart/chest = target.get_bodypart(BODY_ZONE_CHEST)

	// Для торса показываем туловище + груди (breasts)
	if(target_zone == BODY_ZONE_CHEST)
		if(length(BP.tattoo_text))
			available_zones["Туловище"] = GLOB.tattoo_radial_icons[BODY_ZONE_CHEST]
		// Проверяем грудь через GLOB.tattoo_zone_data
		var/list/breast_data = GLOB.tattoo_zone_data[TATTOO_ZONE_BREASTS]
		if(target.getorganslot(breast_data[TATTOO_DATA_ORGAN]) && chest && length(chest.vars[breast_data[TATTOO_DATA_VAR]]))
			var/image/icon = generate_genital_radial_icon(target, breast_data[TATTOO_DATA_ORGAN])
			available_zones[breast_data[TATTOO_DATA_NAME_NOM]] = icon ? icon : GLOB.tattoo_radial_icons[BODY_ZONE_CHEST]

	// Для паха показываем пах + ягодицы + член + яички + лобок (всё кроме груди и губ)
	if(target_zone == BODY_ZONE_PRECISE_GROIN)
		if(chest && length(chest.groin_tattoo_text))
			available_zones["Пах"] = GLOB.tattoo_radial_icons[BODY_ZONE_PRECISE_GROIN]
		// Итерируем через интимные зоны паха
		for(var/zone in GLOB.tattoo_zone_data)
			if(zone == TATTOO_ZONE_BREASTS || zone == TATTOO_ZONE_GROIN || zone == TATTOO_ZONE_LIPS)
				continue
			var/list/data = GLOB.tattoo_zone_data[zone]
			if(!chest || !length(chest.vars[data[TATTOO_DATA_VAR]]))
				continue
			var/organ_slot = data[TATTOO_DATA_ORGAN]
			if(organ_slot && !target.getorganslot(organ_slot))
				continue
			var/image/icon = organ_slot ? generate_genital_radial_icon(target, organ_slot) : null
			available_zones[data[TATTOO_DATA_NAME_NOM]] = icon ? icon : GLOB.tattoo_radial_icons[BODY_ZONE_PRECISE_GROIN]

	if(!length(available_zones))
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return null

	if(length(available_zones) == 1)
		return zone_name_to_zone(available_zones[1])

	var/choice = show_radial_menu(user, target, available_zones, require_near = TRUE, tooltips = TRUE)
	return choice ? zone_name_to_zone(choice) : null

// zone_name_to_zone перенесён в tattoo_zones.dm
