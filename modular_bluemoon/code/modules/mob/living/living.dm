/mob/living/proc/update_weight(new_weight, cur_weight)
	var/anchor_ticks = 0
	var/cancel_deviation = 0
	var/current_size = get_size(src)
	switch(new_weight)
		if(MOB_WEIGHT_HEAVY_SUPER)
			anchor_ticks = MOB_WEIGHT_HEAVY_SUPER_SLOWDOWN_TICKS
			cancel_deviation = MOB_WEIGHT_HEAVY_SUPER_CANCEL_SIZE - 1 // штраф сходит на нет при росте 170%
			throw_range = 1
			throw_speed = 0.5
			if(current_size < MOB_WEIGHT_HEAVY_SUPER_MIN_SIZE)
				to_chat(src, "Вы поняли, что ваш необъятный вес делает невозможным становление слишком маленьким.")
				update_size(MOB_WEIGHT_HEAVY_SUPER_MIN_SIZE)
				// Штраф считается ниже по current_size, а рост мы только что подняли принудительно -
				// без этого он считался бы по размеру, которого у мобы уже нет.
				current_size = MOB_WEIGHT_HEAVY_SUPER_MIN_SIZE
		if(MOB_WEIGHT_HEAVY)
			anchor_ticks = MOB_WEIGHT_HEAVY_SLOWDOWN_TICKS
			cancel_deviation = MOB_WEIGHT_HEAVY_CANCEL_SIZE - 1 // штраф сходит на нет при росте 120%
			throw_range = 4
			throw_speed = 1
		else
			throw_range = 7
			throw_speed = 2

	// Штраф кратен тику. Цена шага всё равно выравнивается по тику, поэтому
	// дробная добавка либо пропала бы целиком, либо наугад превратилась бы в
	// целый тик - лестница в тиках делает ступени предсказуемыми.
	var/slowdown = movement_weight_slowdown(anchor_ticks, cancel_deviation, current_size, CONFIG_GET(number/body_size_slowdown_multiplier), world.tick_lag)

	if(slowdown > 0)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/heavy_weight_slowdown, TRUE, slowdown)
		if(new_weight > MOB_WEIGHT_HEAVY)
			movespeed_override = MOB_WEIGHT_HEAVY_SUPER_FLOOR - slowdown
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/heavy_weight_slowdown)
		if(new_weight > MOB_WEIGHT_HEAVY)
			movespeed_override = MOB_WEIGHT_HEAVY_SUPER_FLOOR
		else
			movespeed_override = 0

/mob/living/proc/has_tentacles() // проверка на наличие тентаклей (для ебли)
	return has_tentacles

/mob/living/proc/snap_choker(mob/living/M, slot)
	var/obj/item/clothing/neck/C = M.get_item_by_slot(slot)
	if(C)
		if(is_type_in_list(C, snaped))
			C.take_damage(80,BRUTE)
			M.dropItemToGround(C)
			playsound(src,  'modular_bluemoon/sound/effects/snap.ogg', 30, 1, -1)
			visible_message(span_danger("[C] snaps!"))
			return TRUE
