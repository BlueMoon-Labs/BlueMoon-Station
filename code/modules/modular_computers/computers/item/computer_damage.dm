/obj/item/modular_computer/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1)
	. = ..()
	var/component_probability = min(50, max(damage_amount*0.1, 1 - obj_integrity/max_integrity))
	switch(damage_flag)
		if(BULLET)
			component_probability = damage_amount * 0.5
		if(LASER)
			component_probability = damage_amount * 0.66
	if(component_probability)
		for(var/I in all_components)
			var/obj/item/computer_hardware/H = all_components[I]
			if(prob(component_probability))
				H.take_damage(round(damage_amount*0.5), damage_type, damage_flag, 0)


/obj/item/modular_computer/deconstruct(disassembled = TRUE)
	break_apart()

/obj/item/modular_computer/proc/break_apart()
	if(!(flags_1 & NODECONSTRUCT_1))
		physical.visible_message(span_notice("\The [src] breaks apart!"))
		var/turf/newloc = get_turf(src)
		new /obj/item/stack/sheet/metal(newloc, round(steel_sheet_cost/2))
		// Обход по копии: uninstall_component вычёркивает деталь из all_components
		// прямо в теле цикла, а BYOND на удалении текущего элемента сдвигает индекс
		// и пропускает каждую вторую.
		for(var/C in all_components.Copy())
			var/obj/item/computer_hardware/H = all_components[C]
			if(QDELETED(H))
				continue
			uninstall_component(H)
			// uninstall_component сам переносит деталь на турф, зовёт on_remove() и
			// при потере питания глушит компьютер - после этой цепочки деталь может
			// быть уже удалена, и второй forceMove бил по трупу.
			if(QDELETED(H))
				continue
			H.forceMove(newloc)
			if(prob(25))
				H.take_damage(rand(10,30), BRUTE, 0, 0)
	relay_qdel()
	qdel(src)
