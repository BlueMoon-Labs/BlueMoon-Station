// ==========================================
// БАЗОВЫЙ ТИП ДЛЯ ПОЛЕВЫХ НАБОРОВ ВПРАВЛЕНИЯ
// ==========================================

/obj/item/stack/medical/fracture_kit
	name = "Field Fracture Kit"
	desc = "Специализированный набор для вправления переломов в полевых условиях."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "surv-12"
	amount = 1
	max_amount = 12
	w_class = WEIGHT_CLASS_NORMAL

	self_delay = 60
	other_delay = 30
	repeating = TRUE
	bypass_armor = TRUE

	/// Насколько трясти персонажа (в тиках)
	var/jitter_amount = 15
	/// Насколько затуманивать зрение (в тиках)
	/// Насколько контузить (в очках)
	var/confusion_amount = 0

// Переопределяем проверку, чтобы набор "видел" только переломы
/obj/item/stack/medical/fracture_kit/has_healable_damage(mob/living/carbon/patient)
	if(!iscarbon(patient))
		return FALSE
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		for(var/datum/wound/W as anything in limb.wounds)
			if(item_can_treat_wound(W))
				return TRUE
	return FALSE

// Указываем, какие именно раны мы лечим (Severe и Critical blunt wounds)
/obj/item/stack/medical/fracture_kit/item_can_treat_wound(datum/wound/W)
	if(istype(W, /datum/wound/blunt/severe) || istype(W, /datum/wound/blunt/critical))
		return TRUE
	return FALSE

// Переопределяем проверку зоны, чтобы лечить только там, где есть перелом
/obj/item/stack/medical/fracture_kit/try_heal_checks(mob/living/patient, mob/living/user, healed_zone, silent = FALSE)
	if(!iscarbon(patient))
		if(!silent)
			to_chat(user, span_warning("Это можно применять только на людей!"))
		return FALSE

	var/mob/living/carbon/carbon_patient = patient
	var/obj/item/bodypart/affecting = carbon_patient.get_bodypart(healed_zone)
	if(!affecting)
		if(!silent)
			to_chat(user, span_warning("У [patient] отсутствует конечность!"))
		return FALSE

	var/has_fracture = FALSE
	for(var/datum/wound/W as anything in affecting.wounds)
		if(item_can_treat_wound(W))
			has_fracture = TRUE
			break

	if(!has_fracture)
		if(!silent)
			to_chat(user, span_notice("На [ru_parse_zone(healed_zone)] [patient] нет переломов, которые можно вправить этим набором!"))
		return FALSE

	return TRUE

// Переопределяем сам процесс лечения
/obj/item/stack/medical/fracture_kit/heal_carbon_new(mob/living/carbon/C, mob/user, healed_zone)
	var/obj/item/bodypart/affecting = C.get_bodypart(healed_zone)
	if(!affecting)
		return FALSE

	var/datum/wound/fracture_to_treat
	for(var/datum/wound/W as anything in affecting.wounds)
		if(item_can_treat_wound(W))
			fracture_to_treat = W
			break

	if(!fracture_to_treat)
		return FALSE

	// BLUEMOON ADD - Проверяем наличие обезболивания
	var/has_painkiller = HAS_TRAIT(C, TRAIT_PAINKILLER)

	// Сообщения о процессе
	if(user == C)
		user.visible_message(
			span_warning("[user] грубо вправляет перелом на своей [ru_kogo_zone(affecting.name)] с помощью [src]!"),
			span_notice("Вы грубо вправляете перелом на своей [ru_kogo_zone(affecting.name)] с помощью [src].")
		)
	else
		user.visible_message(
			span_warning("[user] грубо вправляет перелом на [ru_kogo_zone(affecting.name)] [C] с помощью [src]!"),
			span_notice("Вы грубо вправляете перелом на [ru_kogo_zone(affecting.name)] [C] с помощью [src].")
		)

	// BLUEMOON ADD - Реакция на боль в зависимости от обезболивания
	if(!has_painkiller)
		to_chat(C, span_userdanger("Невыносимая боль пронзает вашу [ru_kogo_zone(affecting.name)]! Вы кричите от агонии!"))

		// Крик наружу
		C.emote("scream")

		// Временные дебаффы
		C.Jitter(jitter_amount)
		C.blur_eyes(15)

		// Конттузия только если она задана (для Surv12 = 0, для CMS > 0)
		if(confusion_amount > 0)
			C.confused += confusion_amount
	else
		to_chat(C, span_notice("Вы чувствуете давление и хруст в [ru_kogo_zone(affecting.name)], но боль приглушена."))

	// Удаляем перелом
	fracture_to_treat.remove_wound()

	// Добавляем немного урона от самого процесса
	affecting.receive_damage(brute = 10, wound_bonus = CANT_WOUND)

	return TRUE

// ==========================================
// КОНКРЕТНЫЕ НАБОРЫ (CMS и Surv12)
// ==========================================

/obj/item/stack/medical/fracture_kit/cms
	name = "CMS kit"
	desc = "Central Nervous System emergency kit. Compact and fast, but harsh on the nerves. Causes severe disorientation without painkillers."
	icon_state = "cms"
	w_class = WEIGHT_CLASS_SMALL
	amount = 4
	max_amount = 4
	self_delay = 120
	other_delay = 60
	jitter_amount = 25      // Сильная тряска
	confusion_amount = 20   // Сильная контузия

/obj/item/stack/medical/fracture_kit/surv12
	name = "Surv12 kit"
	desc = "Survival-12 emergency fracture kit. Bulky and slow to apply, but gentler on the nervous system."
	icon_state = "surv-12"
	w_class = WEIGHT_CLASS_NORMAL
	amount = 12
	max_amount = 12
	self_delay = 240
	other_delay = 12
	jitter_amount = 10      // Лёгкая тряска
	confusion_amount = 0    // Без контузии
