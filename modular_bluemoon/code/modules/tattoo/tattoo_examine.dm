// Отображение татуировок при осмотре персонажа
// Татуировки видны только на открытых частях тела (не закрытых одеждой)

// Хук для отображения татуировок - вызывается в examine.dm
// + Добавляем сигнал для модульного расширения examine

/// Парсит текст татуировок и возвращает список отформатированных строк
/// Каждая татуировка форматируется по стилю: [T] = надпись (в кавычках), [D] = описание (без кавычек)
/proc/parse_tattoos_for_display(raw_text)
	. = list()
	if(!raw_text || raw_text == "")
		return

	// Татуировки разделены через "; "
	var/list/tattoos = splittext(raw_text, "; ")

	for(var/tattoo in tattoos)
		if(!length(tattoo))
			continue

		// Проверяем стиль: [T] = текст (кавычки), [D] = описание (без кавычек)
		// Формат: <span style='color:#COLOR'>[T]текст</span> или <span style='color:#COLOR'>[D]описание</span>
		var/is_description = findtext(tattoo, "\[D\]")

		// Удаляем маркеры стиля из текста для отображения
		var/display_text = replacetext(tattoo, "\[T\]", "")
		display_text = replacetext(display_text, "\[D\]", "")

		if(is_description)
			// Описание - без кавычек
			. += display_text
		else
			// Надпись - в кавычках
			. += "\"[display_text]\""

/// Добавляет строки татуировок для указанной зоны в выходной текст
/proc/append_tattoo_lines(output, raw_text, zone_prefix)
	var/list/tattoos = parse_tattoos_for_display(raw_text)
	for(var/tattoo in tattoos)
		output += span_notice("[zone_prefix][tattoo].\n")
	return output

/mob/living/carbon/human/proc/get_tattoo_examine_text()
	var/tattoo_text_output = ""
	var/list/items_on_self = get_equipped_items()

	for(var/obj/item/bodypart/BP as anything in bodyparts)
		// Обычные татуировки на части тела
		if(BP.tattoo_text && BP.tattoo_text != "")
			var/covered_area = tattoo_zone_to_body_covered(BP.body_zone)
			if(!covered_area)
				covered_area = CHEST

			var/show_tattoo = TRUE
			for(var/obj/item/worn_clothes in items_on_self)
				if(worn_clothes.body_parts_covered & covered_area)
					show_tattoo = FALSE
					break

			if(show_tattoo)
				tattoo_text_output = append_tattoo_lines(tattoo_text_output, BP.tattoo_text, "На [ru_ego()] [BP.ru_name_v] набита татуировка: ")

		// Интимные татуировки (хранятся на груди)
		if(BP.body_zone == BODY_ZONE_CHEST)
			// Татуировки на груди (проверяем CHEST покрытие)
			var/chest_covered = FALSE
			for(var/obj/item/worn_clothes in items_on_self)
				if(worn_clothes.body_parts_covered & CHEST)
					chest_covered = TRUE
					break

			if(!chest_covered && BP.breasts_tattoo_text && BP.breasts_tattoo_text != "")
				tattoo_text_output = append_tattoo_lines(tattoo_text_output, BP.breasts_tattoo_text, "На [ru_ego()] груди набита татуировка: ")

			// Татуировки в паховой области (проверяем GROIN покрытие)
			var/groin_covered = FALSE
			for(var/obj/item/worn_clothes in items_on_self)
				if(worn_clothes.body_parts_covered & GROIN)
					groin_covered = TRUE
					break

			if(!groin_covered)
				if(BP.groin_tattoo_text && BP.groin_tattoo_text != "")
					tattoo_text_output = append_tattoo_lines(tattoo_text_output, BP.groin_tattoo_text, "На [ru_ego()] паху набита татуировка: ")
				if(BP.butt_tattoo_text && BP.butt_tattoo_text != "")
					tattoo_text_output = append_tattoo_lines(tattoo_text_output, BP.butt_tattoo_text, "На [ru_ego()] ягодицах набита татуировка: ")
				if(BP.pussy_tattoo_text && BP.pussy_tattoo_text != "")
					tattoo_text_output = append_tattoo_lines(tattoo_text_output, BP.pussy_tattoo_text, "На [ru_ego()] лобке набита татуировка: ")
				if(BP.testicles_tattoo_text && BP.testicles_tattoo_text != "")
					tattoo_text_output = append_tattoo_lines(tattoo_text_output, BP.testicles_tattoo_text, "На [ru_ego()] яичках набита татуировка: ")

	return tattoo_text_output
