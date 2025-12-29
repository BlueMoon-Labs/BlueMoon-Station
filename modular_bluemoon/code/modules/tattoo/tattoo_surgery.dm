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
	if(!target.client && user != target)
		return FALSE

	var/target_zone = user.zone_selected
	var/obj/item/bodypart/BP = target.get_bodypart(target_zone == BODY_ZONE_PRECISE_GROIN ? BODY_ZONE_CHEST : target_zone)
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
	var/obj/item/bodypart/BP = target.get_bodypart(target_zone == BODY_ZONE_PRECISE_GROIN ? BODY_ZONE_CHEST : target_zone)
	if(!BP)
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	var/selected_zone = select_tattoo_zone_for_surgery(user, target, target_zone, BP)
	if(!selected_zone)
		return -1

	surgery.selected_tattoo_zone = selected_zone
	var/intimate_zone = zone_to_intimate_zone(selected_zone)

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

	var/zone_name = get_tattoo_zone_name(selected_zone, BP)
	var/choice = tgui_input_list(user, "Выберите татуировку для удаления с [zone_name]:", "Удаление татуировки", display_choices)

	if(!choice)
		return -1

	surgery.tattoo_to_remove = raw_to_display[choice]

	display_results(
		user,
		target,
		span_notice("Вы начинаете аккуратно срезать татуировку \"[choice]\" с [zone_name] [target]..."),
		span_notice("[user] начинает аккуратно срезать кожу на [zone_name] [target]."),
		span_notice("[user] делает надрезы на [zone_name] [target].")
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

	var/zone_name = get_tattoo_zone_name(selected_zone, BP)
	var/removed_display = parse_tattoo_for_selection(surgery.tattoo_to_remove)
	display_results(
		user,
		target,
		span_notice("Вы успешно удалили татуировку \"[removed_display]\" с [zone_name] [target]."),
		span_notice("[user] успешно удаляет татуировку с [zone_name] [target]."),
		span_notice("[user] заканчивает работу на [zone_name] [target].")
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

	// Для торса проверяем грудные татуировки
	if(target_zone == BODY_ZONE_CHEST)
		if(BP.tattoo_text && BP.tattoo_text != "")
			return TRUE
		if(target.getorganslot(ORGAN_SLOT_BREASTS) && BP.breasts_tattoo_text && BP.breasts_tattoo_text != "")
			return TRUE
		return FALSE

	// Для паха проверяем все интимные подзоны (кроме груди)
	if(target_zone == BODY_ZONE_PRECISE_GROIN)
		if(BP.groin_tattoo_text && BP.groin_tattoo_text != "")
			return TRUE
		if(BP.butt_tattoo_text && BP.butt_tattoo_text != "")
			return TRUE
		if(target.getorganslot(ORGAN_SLOT_VAGINA) && BP.pussy_tattoo_text && BP.pussy_tattoo_text != "")
			return TRUE
		if(target.getorganslot(ORGAN_SLOT_TESTICLES) && BP.testicles_tattoo_text && BP.testicles_tattoo_text != "")
			return TRUE
		if(target.getorganslot(ORGAN_SLOT_PENIS) && BP.penis_tattoo_text && BP.penis_tattoo_text != "")
			return TRUE
		return FALSE

	// Для остальных зон - просто проверяем основную татуировку
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/tattoo_text = get_tattoo_text_for_zone(BP, intimate_zone)
	return tattoo_text && tattoo_text != ""

/// Выбор конкретной зоны татуировки для хирургии через радиальное меню
/proc/select_tattoo_zone_for_surgery(mob/user, mob/living/carbon/human/target, target_zone, obj/item/bodypart/BP)
	// Для не-торсовых и не-паховых зон сразу возвращаем выбранную зону
	if(target_zone != BODY_ZONE_CHEST && target_zone != BODY_ZONE_PRECISE_GROIN)
		return target_zone

	var/list/available_zones = list()

	// Статические иконки для основных зон
	var/static/list/base_zone_icons
	if(!base_zone_icons)
		base_zone_icons = list()
		base_zone_icons["Туловище"] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "chest")
		base_zone_icons["Пах"] = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "crotch")

	// Для торса показываем только грудные зоны
	if(target_zone == BODY_ZONE_CHEST)
		if(BP.tattoo_text && BP.tattoo_text != "")
			available_zones["Туловище"] = base_zone_icons["Туловище"]
		if(target.getorganslot(ORGAN_SLOT_BREASTS) && BP.breasts_tattoo_text && BP.breasts_tattoo_text != "")
			var/image/breasts_icon = generate_genital_radial_icon(target, ORGAN_SLOT_BREASTS)
			available_zones["Грудь"] = breasts_icon ? breasts_icon : base_zone_icons["Туловище"]

	// Для паха показываем интимные зоны
	if(target_zone == BODY_ZONE_PRECISE_GROIN)
		if(BP.groin_tattoo_text && BP.groin_tattoo_text != "")
			available_zones["Пах"] = base_zone_icons["Пах"]
		if(BP.butt_tattoo_text && BP.butt_tattoo_text != "")
			var/image/butt_icon = generate_genital_radial_icon(target, ORGAN_SLOT_BUTT)
			available_zones["Ягодицы"] = butt_icon ? butt_icon : base_zone_icons["Пах"]
		if(target.getorganslot(ORGAN_SLOT_VAGINA) && BP.pussy_tattoo_text && BP.pussy_tattoo_text != "")
			var/image/vagina_icon = generate_genital_radial_icon(target, ORGAN_SLOT_VAGINA)
			available_zones["Лобок"] = vagina_icon ? vagina_icon : base_zone_icons["Пах"]
		if(target.getorganslot(ORGAN_SLOT_TESTICLES) && BP.testicles_tattoo_text && BP.testicles_tattoo_text != "")
			var/image/testicles_icon = generate_genital_radial_icon(target, ORGAN_SLOT_TESTICLES)
			available_zones["Яички"] = testicles_icon ? testicles_icon : base_zone_icons["Пах"]
		if(target.getorganslot(ORGAN_SLOT_PENIS) && BP.penis_tattoo_text && BP.penis_tattoo_text != "")
			var/image/penis_icon = generate_genital_radial_icon(target, ORGAN_SLOT_PENIS)
			available_zones["Член"] = penis_icon ? penis_icon : base_zone_icons["Пах"]

	if(!length(available_zones))
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return null

	if(length(available_zones) == 1)
		var/only_zone = available_zones[1]
		return zone_name_to_zone(only_zone)

	var/choice = show_radial_menu(user, target, available_zones, require_near = TRUE, tooltips = TRUE)
	if(!choice)
		return null

	return zone_name_to_zone(choice)

/// Конвертирует название зоны обратно в константу
/proc/zone_name_to_zone(zone_name)
	switch(zone_name)
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
	return null
