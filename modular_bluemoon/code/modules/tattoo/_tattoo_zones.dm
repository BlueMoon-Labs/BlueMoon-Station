// Централизованные хелперы для зон татуировок
// Единый источник истины для маппинга зон, имён и органов

/// Глобальные данные зон татуировок - инициализируются один раз
GLOBAL_LIST_INIT(tattoo_zone_data, init_tattoo_zone_data())

/// Кэш иконок для радиального меню
GLOBAL_LIST_INIT(tattoo_radial_icons, init_tattoo_radial_icons())

/// Глобальный список цветов чернил для татуировок (название = hex-код)
GLOBAL_LIST_INIT(tattoo_ink_colors, list(
	// Чёрные и серые
	"Угольно-чёрные" = "#1A1A1A",
	"Тёмно-серые" = "#4A4A4A",
	"Графитовые" = "#696969",
	"Пепельные" = "#A0A0A0",
	"Серебряные" = "#C0C0C0",
	"Белые" = "#FFFFFF",
	// Красные
	"Кровавые" = "#8A0303",
	"Бордовые" = "#8B0000",
	"Алые" = "#DC143C",
	"Огненно-красные" = "#FF3232",
	"Рубиновые" = "#E0115F",
	// Розовые
	"Малиновые" = "#C71585",
	"Розовые" = "#FF69B4",
	"Нежно-розовые" = "#FFB6C1",
	"Неоново-розовые" = "#FF00FF",
	"Фуксия" = "#FF1493",
	// Оранжевые
	"Коралловые" = "#FF7F50",
	"Оранжевые" = "#FF8C00",
	"Мандариновые" = "#FF6347",
	"Янтарные" = "#FFBF00",
	// Жёлтые
	"Лимонные" = "#FFF44F",
	"Ярко-жёлтые" = "#FFFF00",
	"Золотые" = "#FFD700",
	"Медовые" = "#EB9605",
	"Бронзовые" = "#CD7F32",
	// Зелёные
	"Оливковые" = "#808000",
	"Тёмно-зелёные" = "#228B22",
	"Изумрудные" = "#50C878",
	"Травяные" = "#7CFC00",
	"Кислотно-зелёные" = "#00FF00",
	"Мятные" = "#98FB98",
	// Голубые и бирюзовые
	"Бирюзовые" = "#40E0D0",
	"Аквамариновые" = "#7FFFD4",
	"Электро-голубые" = "#00FFFF",
	"Небесно-голубые" = "#87CEEB",
	"Ледяные" = "#B0E0E6",
	// Синие
	"Синие" = "#4169E1",
	"Сапфировые" = "#0F52BA",
	"Тёмно-синие" = "#00008B",
	"Индиго" = "#4B0082",
	"Полуночные" = "#191970",
	// Фиолетовые
	"Лавандовые" = "#9B51FF",
	"Фиолетовые" = "#B900F7",
	"Пурпурные" = "#800080",
	"Аметистовые" = "#9966CC",
	"Сливовые" = "#8E4585",
	// Коричневые
	"Шоколадные" = "#7B3F00",
	"Каштановые" = "#954535",
	"Кофейные" = "#6F4E37",
	"Песочные" = "#C2B280"
))

/proc/init_tattoo_zone_data()
	return list(
		// zone_id = list(var_name, display_name_prepositional, display_name_nominative, organ_slot, body_covered, display_name_genitive)
		// prepositional - предложный падеж ("на паху"), genitive - родительный падеж ("с паха")
		TATTOO_ZONE_GROIN = list("groin_tattoo_text", "паху", "Пах", null, GROIN, "паха"),
		TATTOO_ZONE_BUTT = list("butt_tattoo_text", "ягодицах", "Ягодицы", ORGAN_SLOT_BUTT, GROIN, "ягодиц"),
		TATTOO_ZONE_PUSSY = list("pussy_tattoo_text", "лобке", "Лобок", ORGAN_SLOT_VAGINA, GROIN, "лобка"),
		TATTOO_ZONE_TESTICLES = list("testicles_tattoo_text", "яичках", "Яички", ORGAN_SLOT_TESTICLES, GROIN, "яичек"),
		TATTOO_ZONE_BREASTS = list("breasts_tattoo_text", "груди", "Грудь", ORGAN_SLOT_BREASTS, CHEST, "груди"),
		TATTOO_ZONE_PENIS = list("penis_tattoo_text", "члене", "Член", ORGAN_SLOT_PENIS, GROIN, "члена"),
		TATTOO_ZONE_LIPS = list("lips_tattoo_text", "губах", "Губы", null, TATTOO_COVERED_MOUTH, "губ"),
		TATTOO_ZONE_HORNS = list("horns_tattoo_text", "рогах", "Рога", null, HEAD, "рогов"),
		TATTOO_ZONE_TAIL = list("tail_tattoo_text", "хвосте", "Хвост", ORGAN_SLOT_TAIL, TATTOO_COVERED_TAIL, "хвоста"),
		TATTOO_ZONE_LEFT_THIGH = list("left_thigh_tattoo_text", "левом бедре", "Левое бедро", null, LEG_LEFT, "левого бедра"),
		TATTOO_ZONE_RIGHT_THIGH = list("right_thigh_tattoo_text", "правом бедре", "Правое бедро", null, LEG_RIGHT, "правого бедра"),
		TATTOO_ZONE_EARS = list("ears_tattoo_text", "ушах", "Уши", null, HEAD, "ушей"),
		TATTOO_ZONE_WINGS = list("wings_tattoo_text", "крыльях", "Крылья", null, CHEST, "крыльев"),
		TATTOO_ZONE_BELLY = list("belly_tattoo_text", "животе", "Живот", ORGAN_SLOT_BELLY, CHEST, "живота"),
		TATTOO_ZONE_CHEEKS = list("cheeks_tattoo_text", "щеках", "Щёки", null, TATTOO_COVERED_FACE, "щёк"),
		TATTOO_ZONE_FOREHEAD = list("forehead_tattoo_text", "лбу", "Лоб", null, HEAD, "лба"),
		TATTOO_ZONE_CHIN = list("chin_tattoo_text", "подбородке", "Подбородок", null, TATTOO_COVERED_MOUTH, "подбородка"),
		TATTOO_ZONE_LEFT_HAND = list("left_hand_tattoo_text", "левой кисти", "Левая кисть", null, HAND_LEFT, "левой кисти"),
		TATTOO_ZONE_RIGHT_HAND = list("right_hand_tattoo_text", "правой кисти", "Правая кисть", null, HAND_RIGHT, "правой кисти"),
		TATTOO_ZONE_LEFT_FOOT = list("left_foot_tattoo_text", "левой ступне", "Левая ступня", null, FOOT_LEFT, "левой ступни"),
		TATTOO_ZONE_RIGHT_FOOT = list("right_foot_tattoo_text", "правой ступне", "Правая ступня", null, FOOT_RIGHT, "правой ступни")
	)

/proc/init_tattoo_radial_icons()
	return list(
		BODY_ZONE_HEAD = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "head"),
		BODY_ZONE_PRECISE_MOUTH = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "head"),
		BODY_ZONE_CHEST = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "chest"),
		BODY_ZONE_PRECISE_GROIN = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "groin"),
		BODY_ZONE_L_ARM = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_arm"),
		BODY_ZONE_R_ARM = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_arm"),
		BODY_ZONE_L_LEG = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_leg"),
		BODY_ZONE_R_LEG = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_leg")
	)

#define TATTOO_DATA_VAR 1
#define TATTOO_DATA_NAME_PREP 2      // предложный падеж ("на губах")
#define TATTOO_DATA_NAME_NOM 3       // именительный падеж ("Губы")
#define TATTOO_DATA_ORGAN 4
#define TATTOO_DATA_COVERED 5
#define TATTOO_DATA_NAME_GEN 6       // родительный падеж ("с губ")

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

/// Получает название зоны в предложном падеже (для "на ...")
/proc/get_tattoo_zone_name(zone, obj/item/bodypart/BP)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(zone_data)
		return zone_data[TATTOO_DATA_NAME_PREP]
	if(zone == BODY_ZONE_PRECISE_GROIN)
		return "паху"
	return BP?.ru_name_v

/// Получает название зоны в родительном падеже (для "с ...")
/proc/get_tattoo_zone_name_genitive(zone, obj/item/bodypart/BP)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(zone_data)
		return zone_data[TATTOO_DATA_NAME_GEN]
	if(zone == BODY_ZONE_PRECISE_GROIN)
		return "паха"
	// Маппинг для обычных зон тела
	switch(zone)
		if(BODY_ZONE_HEAD)
			return "головы"
		if(BODY_ZONE_CHEST)
			return "туловища"
		if(BODY_ZONE_L_ARM)
			return "левой руки"
		if(BODY_ZONE_R_ARM)
			return "правой руки"
		if(BODY_ZONE_L_LEG)
			return "левой ноги"
		if(BODY_ZONE_R_LEG)
			return "правой ноги"
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
		if(BODY_ZONE_PRECISE_MOUTH)
			return TATTOO_COVERED_MOUTH
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

		CB.Invoke(zone, text, data[TATTOO_DATA_NAME_PREP])

/// Проверяет, закрыта ли зона одеждой (простая проверка)
/proc/is_zone_covered(list/items, body_covered_flag)
	for(var/obj/item/worn in items)
		if(worn.body_parts_covered & body_covered_flag)
			return TRUE
	return FALSE

/// Проверяет, закрыта ли грудь "существенной" одеждой (не нижним бельём)
/// Существенная одежда - это та, что покрывает грудь И хотя бы руки или пах (рубашка, комбинезон)
/// Нижнее бельё (бра, топ) покрывает только грудь без дополнительных зон
/proc/is_chest_substantially_covered(list/items)
	for(var/obj/item/worn in items)
		if(!(worn.body_parts_covered & CHEST))
			continue
		// Если одежда покрывает грудь + руки или грудь + пах - это существенное покрытие
		if(worn.body_parts_covered & (ARM_LEFT|ARM_RIGHT|GROIN))
			return TRUE
	return FALSE

/// Проверяет, закрыт ли рот маской или шлемом (flags_cover)
/proc/is_mouth_covered(mob/living/carbon/human/H)
	if(H.wear_mask?.flags_cover & MASKCOVERSMOUTH)
		return TRUE
	if(H.head?.flags_cover & HEADCOVERSMOUTH)
		return TRUE
	return FALSE

/// Проверяет, закрыто ли лицо маской или шлемом (HIDEFACE через flags_inv)
/// Используется для татуировок на щеках
/proc/is_face_covered(mob/living/carbon/human/H)
	if(H.wear_mask?.flags_inv & HIDEFACE)
		return TRUE
	if(H.head?.flags_inv & HIDEFACE)
		return TRUE
	return FALSE

/// Проверяет, закрыт ли хвост костюмом (HIDETAUR через flags_inv)
/// Используется для татуировок на хвосте
/proc/is_tail_covered(mob/living/carbon/human/H)
	if(H.wear_suit?.flags_inv & HIDETAUR)
		return TRUE
	return FALSE

/// Проверяет, закрыта ли конкретная зона татуировки одеждой
/proc/is_tattoo_zone_covered(zone, list/items, mob/living/carbon/human/H)
	var/body_covered = tattoo_zone_to_body_covered(zone)

	// Специальная проверка для губ/подбородка - маска закрывает рот
	if(body_covered == TATTOO_COVERED_MOUTH)
		return is_mouth_covered(H)

	// Специальная проверка для щёк - полнолицевая маска или шлем
	if(body_covered == TATTOO_COVERED_FACE)
		return is_face_covered(H)

	// Специальная проверка для хвоста - скафандр и подобная одежда
	if(body_covered == TATTOO_COVERED_TAIL)
		return is_tail_covered(H)

	// Нет покрытия - всегда видны
	if(!body_covered)
		return FALSE

	// Для CHEST используем разную логику в зависимости от зоны
	if(body_covered == CHEST)
		// Груди покрываются бра, остальное (живот, крылья, туловище) - только существенной одеждой
		if(zone == TATTOO_ZONE_BREASTS)
			return is_zone_covered(items, CHEST)
		else
			return is_chest_substantially_covered(items)

	// Для остальных зон - простая проверка
	return is_zone_covered(items, body_covered)
