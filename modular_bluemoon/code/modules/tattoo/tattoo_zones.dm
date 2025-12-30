// Централизованные хелперы для зон татуировок
// Единый источник истины для маппинга зон, имён и органов

/// Глобальные данные зон татуировок - инициализируются один раз
GLOBAL_LIST_INIT(tattoo_zone_data, init_tattoo_zone_data())

/// Кэш иконок для радиального меню
GLOBAL_LIST_INIT(tattoo_radial_icons, init_tattoo_radial_icons())

/proc/init_tattoo_zone_data()
	return list(
		// zone_id = list(var_name, display_name_genetive, display_name_nominative, organ_slot, body_covered)
		TATTOO_ZONE_GROIN = list("groin_tattoo_text", "паху", "Пах", null, GROIN),
		TATTOO_ZONE_BUTT = list("butt_tattoo_text", "ягодицах", "Ягодицы", ORGAN_SLOT_BUTT, GROIN),
		TATTOO_ZONE_PUSSY = list("pussy_tattoo_text", "лобке", "Лобок", ORGAN_SLOT_VAGINA, GROIN),
		TATTOO_ZONE_TESTICLES = list("testicles_tattoo_text", "яичках", "Яички", ORGAN_SLOT_TESTICLES, GROIN),
		TATTOO_ZONE_BREASTS = list("breasts_tattoo_text", "груди", "Грудь", ORGAN_SLOT_BREASTS, CHEST),
		TATTOO_ZONE_PENIS = list("penis_tattoo_text", "члене", "Член", ORGAN_SLOT_PENIS, GROIN)
	)

/proc/init_tattoo_radial_icons()
	return list(
		BODY_ZONE_HEAD = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "head"),
		BODY_ZONE_CHEST = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "chest"),
		BODY_ZONE_PRECISE_GROIN = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "groin"),
		BODY_ZONE_L_ARM = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_arm"),
		BODY_ZONE_R_ARM = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_arm"),
		BODY_ZONE_L_LEG = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_leg"),
		BODY_ZONE_R_LEG = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_leg")
	)

#define TATTOO_DATA_VAR 1
#define TATTOO_DATA_NAME_GEN 2
#define TATTOO_DATA_NAME_NOM 3
#define TATTOO_DATA_ORGAN 4
#define TATTOO_DATA_COVERED 5

/// Получает текст татуировки для любой зоны (обычной или интимной)
/proc/get_tattoo_text_for_zone(obj/item/bodypart/BP, intimate_zone)
	if(!BP)
		return ""
	if(!intimate_zone)
		return BP.tattoo_text

	var/list/zone_data = GLOB.tattoo_zone_data[intimate_zone]
	if(!zone_data)
		return BP.tattoo_text

	return BP.vars[zone_data[TATTOO_DATA_VAR]]

/// Устанавливает текст татуировки для любой зоны
/proc/set_tattoo_text_for_zone(obj/item/bodypart/BP, intimate_zone, text)
	if(!BP)
		return

	if(!intimate_zone)
		BP.tattoo_text = text
		return

	var/list/zone_data = GLOB.tattoo_zone_data[intimate_zone]
	if(!zone_data)
		BP.tattoo_text = text
		return

	BP.vars[zone_data[TATTOO_DATA_VAR]] = text

/// Получает название зоны в родительном падеже (для "на ...")
/proc/get_tattoo_zone_name(zone, obj/item/bodypart/BP)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(zone_data)
		return zone_data[TATTOO_DATA_NAME_GEN]
	if(zone == BODY_ZONE_PRECISE_GROIN)
		return "паху"
	return BP?.ru_name_v

/// Получает название зоны в именительном падеже
/proc/get_tattoo_zone_name_nominative(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	return zone_data ? zone_data[TATTOO_DATA_NAME_NOM] : null

/// Проверяет, является ли зона интимной
/proc/is_intimate_tattoo_zone(zone)
	return zone in GLOB.tattoo_zone_data

/// Преобразует зону татуировки в интимную зону (для persistence)
/proc/zone_to_intimate_zone(zone)
	if(zone == BODY_ZONE_PRECISE_GROIN)
		return TATTOO_ZONE_GROIN
	if(zone in GLOB.tattoo_zone_data)
		return zone
	return null

/// Получает флаг покрытия тела для зоны татуировки
/proc/tattoo_zone_to_body_covered(zone)
	// Проверяем интимные зоны
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(zone_data)
		return zone_data[TATTOO_DATA_COVERED]

	// Стандартные зоны
	switch(zone)
		if(BODY_ZONE_HEAD)
			return HEAD
		if(BODY_ZONE_CHEST)
			return CHEST
		if(BODY_ZONE_PRECISE_GROIN)
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

/// Конвертирует название зоны в константу
/proc/zone_name_to_zone(zone_name)
	switch(zone_name)
		if("Голова")
			return BODY_ZONE_HEAD
		if("Туловище")
			return BODY_ZONE_CHEST
		if("Пах")
			return BODY_ZONE_PRECISE_GROIN
		if("Левая рука")
			return BODY_ZONE_L_ARM
		if("Правая рука")
			return BODY_ZONE_R_ARM
		if("Левая нога")
			return BODY_ZONE_L_LEG
		if("Правая нога")
			return BODY_ZONE_R_LEG

	// Проверяем интимные зоны
	for(var/zone in GLOB.tattoo_zone_data)
		var/list/data = GLOB.tattoo_zone_data[zone]
		if(data[TATTOO_DATA_NAME_NOM] == zone_name)
			return zone
	return null

/// Генерирует динамическую иконку для органа персонажа (для радиального меню)
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

/// Итерирует по всем татуировкам на части тела (включая интимные)
/// Вызывает callback для каждой непустой татуировки
/proc/iterate_bodypart_tattoos(obj/item/bodypart/BP, mob/living/carbon/human/H, datum/callback/CB)
	if(!BP || !CB)
		return

	// Обычная татуировка
	if(length(BP.tattoo_text))
		CB.Invoke(null, BP.tattoo_text, BP.ru_name_v)

	// Интимные татуировки (только для груди)
	if(BP.body_zone != BODY_ZONE_CHEST)
		return

	for(var/zone in GLOB.tattoo_zone_data)
		var/list/data = GLOB.tattoo_zone_data[zone]
		var/organ_slot = data[TATTOO_DATA_ORGAN]
		var/text = BP.vars[data[TATTOO_DATA_VAR]]

		if(!length(text))
			continue

		// Проверяем наличие органа если требуется
		if(organ_slot && H && !H.getorganslot(organ_slot))
			continue

		CB.Invoke(zone, text, data[TATTOO_DATA_NAME_GEN])
