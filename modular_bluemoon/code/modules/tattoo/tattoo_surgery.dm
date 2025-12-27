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
		TATTOO_ZONE_BREASTS,
		TATTOO_ZONE_BUTT,
		TATTOO_ZONE_PUSSY,
		TATTOO_ZONE_TESTICLES,
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
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : target_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		return FALSE

	var/tattoo_text = get_tattoo_text_for_zone(BP, intimate_zone)
	if(!tattoo_text || tattoo_text == "")
		return FALSE

	return TRUE

// Шаг удаления татуировки
/datum/surgery_step/remove_tattoo
	name = "Удалить татуировку"
	implements = list(
		TOOL_SCALPEL = 100,
		/obj/item/kitchen/knife = 65,
		TOOL_WIRECUTTER = 40
	)
	time = 80

/datum/surgery_step/remove_tattoo/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : target_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	var/tattoo_text = get_tattoo_text_for_zone(BP, intimate_zone)
	if(!tattoo_text)
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	var/zone_name = get_tattoo_zone_name(target_zone, BP)
	display_results(
		user,
		target,
		span_notice("Вы начинаете аккуратно срезать слои кожи с татуировкой на [zone_name] [target]..."),
		span_notice("[user] начинает аккуратно срезать кожу на [zone_name] [target]."),
		span_notice("[user] делает надрезы на [zone_name] [target].")
	)

/datum/surgery_step/remove_tattoo/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : target_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		return FALSE

	set_tattoo_text_for_zone(BP, intimate_zone, "")

	var/zone_name = get_tattoo_zone_name(target_zone, BP)
	display_results(
		user,
		target,
		span_notice("Вы успешно удалили татуировку с [zone_name] [target]."),
		span_notice("[user] успешно удаляет татуировку с [zone_name] [target]."),
		span_notice("[user] заканчивает работу на [zone_name] [target].")
	)

	target.apply_damage(5, BRUTE, BP)

	// Немедленное сохранение
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.save_tattoos_now()

	return TRUE

/datum/surgery_step/remove_tattoo/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : target_zone

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

	target.apply_damage(15, BRUTE, BP)

// Операция по частичному удалению татуировки (выбор конкретной)
/datum/surgery/tattoo_removal_selective
	name = "Выборочное удаление татуировки"
	desc = "Хирургическая процедура по удалению конкретной татуировки с кожи, оставляя остальные."
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/remove_tattoo_selective,
		/datum/surgery_step/close
	)
	possible_locs = list(
		BODY_ZONE_HEAD,
		BODY_ZONE_CHEST,
		BODY_ZONE_PRECISE_GROIN,
		TATTOO_ZONE_BREASTS,
		TATTOO_ZONE_BUTT,
		TATTOO_ZONE_PUSSY,
		TATTOO_ZONE_TESTICLES,
		BODY_ZONE_L_ARM,
		BODY_ZONE_R_ARM,
		BODY_ZONE_L_LEG,
		BODY_ZONE_R_LEG
	)
	requires_bodypart_type = BODYPART_ORGANIC
	is_healing = FALSE
	icon_state = "surgery_any"
	radial_priority = SURGERY_RADIAL_PRIORITY_OTHER_SECOND + 1

/datum/surgery/tattoo_removal_selective/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	. = ..()
	if(!.)
		return FALSE

	// Проверка на кататоника (SSD/отключённого игрока)
	if(!target.client && user != target)
		return FALSE

	var/target_zone = user.zone_selected
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : target_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		return FALSE

	// Проверяем, есть ли несколько татуировок
	var/tattoo_text_to_check = get_tattoo_text_for_zone(BP, intimate_zone)
	if(!tattoo_text_to_check || tattoo_text_to_check == "")
		return FALSE

	// Показываем эту операцию только если есть несколько татуировок
	if(!findtext(tattoo_text_to_check, ";"))
		return FALSE

	return TRUE

// Шаг выборочного удаления татуировки
/datum/surgery_step/remove_tattoo_selective
	name = "Выборочно удалить татуировку"
	implements = list(
		TOOL_SCALPEL = 100,
		/obj/item/kitchen/knife = 65
	)
	time = 60

/datum/surgery_step/remove_tattoo_selective/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : target_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	var/tattoo_text_to_use = get_tattoo_text_for_zone(BP, intimate_zone)
	if(!tattoo_text_to_use)
		to_chat(user, span_warning("На этой части тела нет татуировок!"))
		return -1

	var/list/tattoos = splittext(tattoo_text_to_use, "; ")
	if(!length(tattoos) || length(tattoos) < 2)
		to_chat(user, span_warning("Недостаточно татуировок для выборочного удаления!"))
		return -1

	var/choice = input(user, "Выберите татуировку для удаления:", "Удаление татуировки") as null|anything in tattoos
	if(!choice)
		return -1

	surgery.tattoo_to_remove = choice

	var/zone_name = get_tattoo_zone_name(target_zone, BP)
	display_results(
		user,
		target,
		span_notice("Вы начинаете аккуратно удалять выбранную татуировку с [zone_name] [target]..."),
		span_notice("[user] начинает аккуратно работать над кожей [zone_name] [target]."),
		span_notice("[user] делает надрезы на [zone_name] [target].")
	)

/datum/surgery_step/remove_tattoo_selective/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/intimate_zone = zone_to_intimate_zone(target_zone)
	var/actual_zone = intimate_zone ? BODY_ZONE_CHEST : target_zone

	var/obj/item/bodypart/BP = target.get_bodypart(actual_zone)
	if(!BP)
		return FALSE

	var/tattoo_text = get_tattoo_text_for_zone(BP, intimate_zone)
	var/list/tattoos = splittext(tattoo_text, "; ")
	tattoos -= surgery.tattoo_to_remove
	set_tattoo_text_for_zone(BP, intimate_zone, jointext(tattoos, "; "))

	var/zone_name = get_tattoo_zone_name(target_zone, BP)
	display_results(
		user,
		target,
		span_notice("Вы успешно удалили выбранную татуировку с [zone_name] [target]."),
		span_notice("[user] успешно удаляет татуировку с [zone_name] [target]."),
		span_notice("[user] заканчивает работу на [zone_name] [target].")
	)

	target.apply_damage(3, BRUTE, BP)

	// Немедленное сохранение (защита от краша сервера)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.save_tattoos_now()

	return TRUE

// Расширение датума хирургии для хранения выбранной татуировки
/datum/surgery
	/// Татуировка, которую нужно удалить (для выборочного удаления)
	var/tattoo_to_remove = ""
