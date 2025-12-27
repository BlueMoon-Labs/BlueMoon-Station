// Отображение татуировок при осмотре персонажа
// Татуировки видны только на открытых частях тела (не закрытых одеждой)

// Хук для отображения татуировок - вызывается в examine.dm
// + Добавляем сигнал для модульного расширения examine

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
				tattoo_text_output += span_notice("На [ru_ego()] [BP.ru_name_v] набита татуировка: \"[BP.tattoo_text]\".\n")

		// Интимные татуировки (хранятся на груди)
		if(BP.body_zone == BODY_ZONE_CHEST)
			// Татуировки на груди (проверяем CHEST покрытие)
			var/chest_covered = FALSE
			for(var/obj/item/worn_clothes in items_on_self)
				if(worn_clothes.body_parts_covered & CHEST)
					chest_covered = TRUE
					break

			if(!chest_covered && BP.breasts_tattoo_text && BP.breasts_tattoo_text != "")
				tattoo_text_output += span_notice("На [ru_ego()] груди набита татуировка: \"[BP.breasts_tattoo_text]\".\n")

			// Татуировки в паховой области (проверяем GROIN покрытие)
			var/groin_covered = FALSE
			for(var/obj/item/worn_clothes in items_on_self)
				if(worn_clothes.body_parts_covered & GROIN)
					groin_covered = TRUE
					break

			if(!groin_covered)
				if(BP.groin_tattoo_text && BP.groin_tattoo_text != "")
					tattoo_text_output += span_notice("На [ru_ego()] паху набита татуировка: \"[BP.groin_tattoo_text]\".\n")
				if(BP.butt_tattoo_text && BP.butt_tattoo_text != "")
					tattoo_text_output += span_notice("На [ru_ego()] ягодицах набита татуировка: \"[BP.butt_tattoo_text]\".\n")
				if(BP.pussy_tattoo_text && BP.pussy_tattoo_text != "")
					tattoo_text_output += span_notice("На [ru_ego()] лобке набита татуировка: \"[BP.pussy_tattoo_text]\".\n")
				if(BP.testicles_tattoo_text && BP.testicles_tattoo_text != "")
					tattoo_text_output += span_notice("На [ru_ego()] яичках набита татуировка: \"[BP.testicles_tattoo_text]\".\n")

	return tattoo_text_output
