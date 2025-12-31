// Отображение татуировок при осмотре персонажа
// Татуировки видны только на открытых частях тела (не закрытых одеждой)

/// Парсит текст татуировок и возвращает список отформатированных строк
/// Каждая татуировка форматируется по стилю: [T] = надпись (в кавычках), [D] = описание (без кавычек)
/proc/parse_tattoos_for_display(raw_text)
	. = list()
	if(!length(raw_text))
		return

	for(var/tattoo in splittext(raw_text, "; "))
		if(!length(tattoo))
			continue

		var/is_description = findtext(tattoo, "\[D\]")
		var/display_text = replacetext(replacetext(tattoo, "\[T\]", ""), "\[D\]", "")

		. += is_description ? display_text : "\"[display_text]\""

/// Проверяет, закрыта ли зона одеждой
/proc/is_zone_covered(list/items, body_covered_flag)
	for(var/obj/item/worn in items)
		if(worn.body_parts_covered & body_covered_flag)
			return TRUE
	return FALSE

/// Проверяет, закрыт ли рот маской или шлемом (flags_cover)
/proc/is_mouth_covered(mob/living/carbon/human/H)
	// Проверяем маску
	if(H.wear_mask?.flags_cover & MASKCOVERSMOUTH)
		return TRUE
	// Проверяем шлем/головной убор
	if(H.head?.flags_cover & HEADCOVERSMOUTH)
		return TRUE
	return FALSE

/mob/living/carbon/human/proc/get_tattoo_examine_text()
	var/tattoo_text_output = ""
	var/list/items_on_self = get_equipped_items()

	for(var/obj/item/bodypart/BP as anything in bodyparts)
		// Обычные татуировки на части тела
		if(length(BP.tattoo_text))
			var/covered_area = tattoo_zone_to_body_covered(BP.body_zone) || CHEST
			if(!is_zone_covered(items_on_self, covered_area))
				for(var/tattoo in parse_tattoos_for_display(BP.tattoo_text))
					tattoo_text_output += span_notice("На [ru_ego()] [BP.ru_name_v] набита татуировка: [tattoo].\n")

		// Интимные татуировки (хранятся на груди)
		if(BP.body_zone != BODY_ZONE_CHEST)
			continue

		// Проверяем покрытие один раз для каждой области
		var/chest_covered = is_zone_covered(items_on_self, CHEST)
		var/groin_covered = is_zone_covered(items_on_self, GROIN)
		var/head_covered = is_zone_covered(items_on_self, HEAD)
		var/left_leg_covered = is_zone_covered(items_on_self, LEG_LEFT)
		var/right_leg_covered = is_zone_covered(items_on_self, LEG_RIGHT)
		var/mouth_covered = is_mouth_covered(src)

		// Итерируем через все интимные зоны используя centralized data
		for(var/zone in GLOB.tattoo_zone_data)
			var/list/data = GLOB.tattoo_zone_data[zone]
			var/text = BP.vars[data[TATTOO_DATA_VAR]]
			if(!length(text))
				continue

			// Проверяем наличие органа если требуется (татуировка на органе не видна без органа)
			var/organ_slot = data[TATTOO_DATA_ORGAN]
			if(organ_slot && !getorganslot(organ_slot))
				continue

			// Для рогов проверяем наличие мутантной части вида
			if(zone == TATTOO_ZONE_HORNS)
				if(!dna?.species?.mutant_bodyparts["horns"] || !dna.features["horns"] || dna.features["horns"] == "None")
					continue

			// Для ушей проверяем наличие мутантной части вида
			if(zone == TATTOO_ZONE_EARS)
				var/has_ears = FALSE
				if(dna?.species?.mutant_bodyparts["ears"] && dna.features["ears"] && dna.features["ears"] != "None")
					has_ears = TRUE
				else if(dna?.species?.mutant_bodyparts["mam_ears"] && dna.features["mam_ears"] && dna.features["mam_ears"] != "None")
					has_ears = TRUE
				if(!has_ears)
					continue

			// Для крыльев проверяем наличие мутантной части вида
			if(zone == TATTOO_ZONE_WINGS)
				var/has_wings = FALSE
				if(dna?.species?.mutant_bodyparts["wings"] && dna.features["wings"] && dna.features["wings"] != "None")
					has_wings = TRUE
				else if(dna?.species?.mutant_bodyparts["deco_wings"] && dna.features["deco_wings"] && dna.features["deco_wings"] != "None")
					has_wings = TRUE
				else if(dna?.species?.mutant_bodyparts["insect_wings"] && dna.features["insect_wings"] && dna.features["insect_wings"] != "None")
					has_wings = TRUE
				if(!has_wings)
					continue

			// Проверяем покрытие
			var/body_covered = data[TATTOO_DATA_COVERED]
			var/is_covered = FALSE
			switch(body_covered)
				if(CHEST)
					is_covered = chest_covered
				if(GROIN)
					is_covered = groin_covered
				if(HEAD)
					is_covered = head_covered
				if(LEG_LEFT)
					is_covered = left_leg_covered
				if(LEG_RIGHT)
					is_covered = right_leg_covered
				if(TATTOO_COVERED_MOUTH)
					is_covered = mouth_covered
				if(null)
					is_covered = FALSE // Хвост и прочее без покрытия всегда видны

			if(is_covered)
				continue

			for(var/tattoo in parse_tattoos_for_display(text))
				tattoo_text_output += span_notice("На [ru_ego()] [data[TATTOO_DATA_NAME_PREP]] набита татуировка: [tattoo].\n")

	return tattoo_text_output
