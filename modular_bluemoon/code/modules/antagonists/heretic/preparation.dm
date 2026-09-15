/obj/item/forbidden_book/proc/preparation_data(datum/antagonist/heretic/heretic)
	var/mob/living/carbon/human/user = heretic.owner?.current
	if(!istype(user))
		return null
	var/list/items = user.GetAllContents()
	var/has_blade = FALSE
	var/has_robes = FALSE
	var/wearing_robes = FALSE
	var/wearing_hood = FALSE
	for(var/obj/item/item in items)
		if(istype(item, /obj/item/melee/sickly_blade))
			var/obj/item/melee/sickly_blade/blade = item
			if(blade.route == heretic.selected_path)
				if(istype(blade, /obj/item/melee/sickly_blade/duelist))
					var/obj/item/melee/sickly_blade/duelist/duelist = blade
					if(duelist.bound_mind != heretic.owner)
						continue
				has_blade = TRUE
		if(istype(item, /obj/item/clothing/suit/hooded/cultrobes/eldritch) || istype(item, /obj/item/clothing/suit/hooded/cultrobes/void))
			var/obj/item/clothing/suit/hooded/robes = item
			has_robes = TRUE
			if(user.wear_suit == robes)
				wearing_robes = TRUE
				wearing_hood = robes.hood && user.head == robes.hood
	return list(
		"blade_ready" = has_blade,
		"blade_status" = has_blade ? "Клинок вашего пути при вас." : "Клинка вашего пути при вас нет. Изготовьте его по первому рецепту пути в главе «Ритуалы».",
		"armor_ready" = wearing_robes && wearing_hood,
		"armor_status" = wearing_robes ? (wearing_hood ? "Мантия надета, капюшон поднят." : "Мантия надета. Поднимите капюшон для защиты головы.") : (has_robes ? "Мантия при вас: наденьте её и поднимите капюшон." : "Мантии при вас нет. Изучите «Ритуал оружейника — броня» и проведите обряд со столом и противогазом."),
		"heart" = heart_preparation_data(heretic),
	)

/obj/item/forbidden_book/proc/heart_preparation_data(datum/antagonist/heretic/heretic)
	var/mob/living/user = heretic.owner?.current
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/obj/effect/proc_holder/spell/self/heretic_summon/heart/spell = knowledge?.granted_spell
	var/behind_veil = FALSE
	var/blocked = FALSE
	for(var/obj/item/living_heart/heart as anything in GLOB.living_heart_cache)
		if(QDELETED(heart) || heart.owner_mind != heretic.owner)
			continue
		var/atom/movable/holder = get_atom_on_turf(heart, /mob)
		if(GLOB.heretic_ritual_reservations[heart] || (ismob(holder) && holder != user))
			blocked = TRUE
			continue
		if(holder == user || (isturf(heart.loc) && heart.loc == user.loc))
			return list("ready" = TRUE, "can_call" = FALSE, "action_label" = "Сердце доступно", "status" = holder == user ? "Своё сердце при вас. Для подношения положите его рядом с целью на руну." : "Своё сердце на полу под вами. Его можно поднять или оставить для обряда.")
		if(heart in heretic.summon_items)
			behind_veil = TRUE
	var/can_call = !QDELETED(spell) && (spell in user?.mind?.spell_list) && !spell.recovery_in_progress && (behind_veil || !blocked)
	var/status = behind_veil ? "Своё сердце спрятано за завесой. Призовите его без компонентов." : "Своё сердце потеряно или уничтожено. Верните его за 5 секунд неподвижности; цель охоты сохранится."
	if(blocked && !behind_veil)
		status = "Сердце удерживает другой человек или действующий обряд. Сначала освободите его."
	if(spell?.recovery_in_progress)
		status = "Возвращение сердца уже началось. Не двигайтесь."
	return list("ready" = FALSE, "can_call" = can_call, "action_label" = behind_veil ? "Призвать своё сердце" : "Вернуть своё сердце", "status" = status)

/obj/item/forbidden_book/proc/call_heart(mob/living/user, datum/antagonist/heretic/heretic)
	if(IS_HERETIC(user) != heretic || heretic.owner?.current != user || !user.is_holding(src) || user.incapacitated())
		return FALSE
	var/list/heart_data = heart_preparation_data(heretic)
	if(!heart_data["can_call"])
		to_chat(user, span_notice(heart_data["status"]))
		return TRUE
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	knowledge.granted_spell.Trigger(user, FALSE)
	return TRUE
