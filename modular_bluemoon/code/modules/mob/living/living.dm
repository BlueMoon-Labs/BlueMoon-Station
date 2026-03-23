/mob/living/proc/update_weight(new_weight, cur_weight)
	var/searched_slowdown
	var/user_slowdown = (abs(get_size(src) - 1) * CONFIG_GET(number/body_size_slowdown_multiplier))
	switch(new_weight)
		if(MOB_WEIGHT_HEAVY_SUPER)
			searched_slowdown = 0.7 * CONFIG_GET(number/body_size_slowdown_multiplier) // проверка как для размера в 170%
			throw_range = 1
			throw_speed = 0.5
			if(get_size(src) < 0.8) // Самый маленький размер для сверхтяжёлых - 80%
				to_chat(src, "Вы поняли, что ваш необъятный вес делает невозможным становление слишком маленьким.")
				update_size(0.8)
		if(MOB_WEIGHT_HEAVY)
			searched_slowdown = 0.2 * CONFIG_GET(number/body_size_slowdown_multiplier) // проверка как для размера в 120%
			throw_range = 4
			throw_speed = 1
		else
			throw_range = 7
			throw_speed = 2

	if(searched_slowdown && searched_slowdown - user_slowdown > 0) //подсчёт наличия разницы в росте с искомой и её начисление для замедления персонажа
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/heavy_weight_slowdown, TRUE, searched_slowdown - user_slowdown)
		if(new_weight > MOB_WEIGHT_HEAVY)
			movespeed_override = 3 - (searched_slowdown - user_slowdown)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/heavy_weight_slowdown)
		if(new_weight > MOB_WEIGHT_HEAVY)
			movespeed_override = 3
		else
			movespeed_override = 0

/mob/living/proc/has_tentacles() // проверка на наличие тентаклей (для ебли)
	return has_tentacles

/mob/living/proc/snap_choker(mob/living/M, slot)
	var/obj/item/clothing/neck/C = list(/obj/item/clothing/neck/petcollar/choker, /obj/item/clothing/neck/petcollar/locked/choker, /obj/item/clothing/neck/petcollar/donorchoker, /obj/item/clothing/neck/syntech/choker, /obj/item/clothing/neck/undertale)
	C = M.get_item_by_slot(slot)
	if(C)
		if(prob(15))
			M.dropItemToGround(C)
			playsound(src,  'modular_bluemoon/sound/effects/snap.ogg', 30, 1, -1)
			visible_message(span_danger("[C] snaps!"))
			return TRUE
