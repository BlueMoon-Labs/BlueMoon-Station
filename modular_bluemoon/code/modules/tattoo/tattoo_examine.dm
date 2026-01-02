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

/mob/living/carbon/human/proc/get_tattoo_examine_text()
	var/tattoo_text_output = ""
	var/list/items_on_self = get_equipped_items()

	for(var/obj/item/bodypart/BP as anything in bodyparts)
		// Обычные татуировки на части тела
		if(length(BP.tattoo_text))
			// Для обычных частей тела используем BODY_ZONE как зону
			if(!is_tattoo_zone_covered(BP.body_zone, items_on_self, src))
				for(var/tattoo in parse_tattoos_for_display(BP.tattoo_text))
					tattoo_text_output += span_notice("На [ru_ego()] [BP.ru_name_v] набита татуировка: [tattoo].\n")

		// Интимные татуировки (хранятся на груди)
		if(BP.body_zone != BODY_ZONE_CHEST)
			continue

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

			// Проверяем покрытие одеждой
			if(is_tattoo_zone_covered(zone, items_on_self, src))
				continue

			for(var/tattoo in parse_tattoos_for_display(text))
				tattoo_text_output += span_notice("На [ru_ego()] [data[TATTOO_DATA_NAME_PREP]] набита татуировка: [tattoo].\n")

	return tattoo_text_output
