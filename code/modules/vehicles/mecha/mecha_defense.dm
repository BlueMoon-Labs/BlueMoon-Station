/obj/vehicle/sealed/mecha/proc/get_armour_facing(relative_dir)
	switch(relative_dir)
		if(180) // BACKSTAB!
			return facing_modifiers[MECHA_BACK_ARMOUR]
		if(0, 45) // direct or 45 degrees off
			return facing_modifiers[MECHA_FRONT_ARMOUR]
	return facing_modifiers[MECHA_SIDE_ARMOUR] //if its not a front hit or back hit then assume its from the side

/obj/vehicle/sealed/mecha/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && obj_integrity > 0)
		spark_system.start()
		switch(damage_flag)
			if(FIRE)
				check_for_internal_damage(list(MECHA_INT_FIRE,MECHA_INT_TEMP_CONTROL))
			if(MELEE)
				check_for_internal_damage(list(MECHA_INT_TEMP_CONTROL,MECHA_INT_TANK_BREACH,MECHA_INT_CONTROL_LOST))
			else
				check_for_internal_damage(list(MECHA_INT_FIRE,MECHA_INT_TEMP_CONTROL,MECHA_INT_TANK_BREACH,MECHA_INT_CONTROL_LOST,MECHA_INT_SHORT_CIRCUIT))
		if(. >= 5 || prob(33))
			to_chat(occupants, "[icon2html(src, occupants)][span_userdanger("Мех получает повреждения!")]")
		log_message("Получено [damage_amount] ед. урона. Тип урона: [damage_type]", LOG_MECHA)

/obj/vehicle/sealed/mecha/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir)
	. = ..()
	if(!damage_amount)
		return FALSE
	var/booster_deflection_modifier = 1
	var/booster_damage_modifier = 1
	if(damage_flag == BULLET || damage_flag == LASER || damage_flag == ENERGY)
		for(var/obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster/B in equipment)
			if(B.projectile_react())
				booster_deflection_modifier = B.deflect_coeff
				booster_damage_modifier = B.damage_coeff
				break
	else if(damage_flag == MELEE)
		for(var/obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster/B in equipment)
			if(B.attack_react())
				booster_deflection_modifier *= B.deflect_coeff
				booster_damage_modifier *= B.damage_coeff
				break

	if(attack_dir)
		var/facing_modifier = get_armour_facing(abs(dir2angle(dir) - dir2angle(attack_dir)))
		booster_damage_modifier /= facing_modifier
		booster_deflection_modifier *= facing_modifier
	if(prob(deflect_chance * booster_deflection_modifier))
		visible_message(span_danger("Броня [src] отражает атаку!"))
		log_message("Броня отразила удар.", LOG_MECHA)
		return FALSE
	if(.)
		. *= booster_damage_modifier

/obj/vehicle/sealed/mecha/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	playsound(loc, 'sound/weapons/tap.ogg', 40, TRUE, -1)
	user.visible_message(span_danger("[user] ударяет [name]. Ничего не происходит."), null, null, COMBAT_MESSAGE_RANGE)
	log_message("Удар рукой или лапой. Нападавший: [user].", LOG_MECHA, color="red")

/obj/vehicle/sealed/mecha/attack_paw(mob/user as mob)
	return attack_hand(user)

/obj/vehicle/sealed/mecha/attack_alien(mob/living/user)
	log_message("Атака ксеноморфа. Нападавший: [user].", LOG_MECHA, color="red")
	playsound(src.loc, 'sound/weapons/slash.ogg', 100, TRUE)
	attack_generic(user, 15, BRUTE, MELEE, 0)

/obj/vehicle/sealed/mecha/attack_animal(mob/living/simple_animal/user)
	log_message("Атака животного. Нападавший: [user].", LOG_MECHA, color="red")
	if(!user.melee_damage_upper && !user.obj_damage)
		user.emote("custom", message = "[user.friendly_verb_continuous] [src].")
		return FALSE
	else
		var/play_soundeffect = 1
		if(user.environment_smash)
			play_soundeffect = 0
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		var/animal_damage = rand(user.melee_damage_lower,user.melee_damage_upper)
		if(user.obj_damage)
			animal_damage = user.obj_damage
		animal_damage = min(animal_damage, 20*user.environment_smash)
		log_combat(user, src, "attacked")
		attack_generic(user, animal_damage, user.melee_damage_type, MELEE, play_soundeffect)
		return TRUE


/obj/vehicle/sealed/mecha/hulk_damage()
	return 15

/obj/vehicle/sealed/mecha/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		log_message("Атака халка. Нападавший: [user].", LOG_MECHA, color="red")
		log_combat(user, src, "punched", "hulk powers")

/obj/vehicle/sealed/mecha/blob_act(obj/structure/blob/B)
	log_message("Атака блоба. Нападавший: [B].", LOG_MECHA, color="red")
	take_damage(30, BRUTE, MELEE, 0, get_dir(src, B))

/obj/vehicle/sealed/mecha/attack_tk()
	return

/obj/vehicle/sealed/mecha/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum) //wrapper
	log_message("Попадание [AM].", LOG_MECHA, color="red")
	return ..()

/obj/vehicle/sealed/mecha/bullet_act(obj/item/projectile/Proj) //wrapper
	if(!enclosed && LAZYLEN(occupants) && !(mecha_flags  & SILICON_PILOT) && !Proj.force_hit && (Proj.def_zone == BODY_ZONE_HEAD || Proj.def_zone == BODY_ZONE_CHEST)) //allows bullets to hit the pilot of open-canopy mechs
		for(var/m in occupants)
			var/mob/living/hitmob = m
			hitmob.bullet_act(Proj) //If the sides are open, the occupant can be hit
		return BULLET_ACT_HIT
	log_message("Попадание снаряда. Тип: [Proj.name] ([Proj.flag]).", LOG_MECHA, color="red")
	. = ..()

/obj/vehicle/sealed/mecha/ex_act(severity, target)
	log_message("Попадание под взрыв. Сила воздействия: [severity].", LOG_MECHA, color="red")
	if(prob(deflect_chance))
		severity++
		log_message("Броня снизила силу воздействия до [severity]", LOG_MECHA)
	. = ..()


/obj/vehicle/sealed/mecha/contents_explosion(severity, target, origin)
	severity++
	for(var/X in equipment)
		var/obj/item/mecha_parts/mecha_equipment/ME = X
		ME.ex_act(severity, target, origin)
	for(var/Y in trackers)
		var/obj/item/mecha_parts/mecha_tracking/MT = Y
		MT.ex_act(severity, target, origin)
	for(var/Z in occupants)
		var/mob/living/occupant = Z
		occupant.ex_act(severity, target, origin)

/obj/vehicle/sealed/mecha/handle_atom_del(atom/A)
	if(A in occupants)
		LAZYREMOVE(occupants, A)
		icon_state = initial(icon_state)+"-open"
		setDir(dir_in)

/obj/vehicle/sealed/mecha/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(get_charge())
		use_power((cell.charge/3)*(severity*0.005))
		take_damage(severity/3, BURN, ENERGY, 1)
	log_message("Обнаружен электромагнитный импульс", LOG_MECHA, color="red")

	if(istype(src, /obj/vehicle/sealed/mecha/combat))
		mouse_pointer = 'icons/effects/mouse_pointers/mecha_mouse-disable.dmi'
		for(var/occus in occupants)
			var/mob/living/occupant = occus
			occupant.update_mouse_pointer()
	if(!equipment_disabled && LAZYLEN(occupants)) //prevent spamming this message with back-to-back EMPs
		to_chat(occupants, span_danger("Ошибка: связь с блоком управления оборудованием потеряна."))
	if(!QDELETED(src))
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/vehicle/sealed/mecha, restore_equipment)), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	equipment_disabled = 1

/obj/vehicle/sealed/mecha/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature>max_temperature)
		log_message("Воздействие опасной температуры.", LOG_MECHA, color="red")
		take_damage(5, BURN, 0, 1)

/obj/vehicle/sealed/mecha/attackby(obj/item/W, mob/user, params)

	if(istype(W, /obj/item/storage/part_replacer))
		if(construction_state != MECHA_OPEN_HATCH)
			to_chat(user, span_warning("Сначала откройте люк силового отсека."))
			return
		var/obj/item/storage/part_replacer/replacer = W
		var/list/needed_parts = list()
		if(!cell)
			needed_parts[/obj/item/stock_parts/cell] = 1
		if(!scanmod)
			needed_parts[/obj/item/stock_parts/scanning_module] = 1
		if(!capacitor)
			needed_parts[/obj/item/stock_parts/capacitor] = 1
		replacer.install_parts(src, user, needed_parts)
		return

	if(istype(W, /obj/item/mmi))
		if(mmi_move_inside(W,user))
			to_chat(user, span_notice("Соединение между [src] и [W] успешно установлено."))
		else
			to_chat(user, span_warning("Не удалось установить соединение между [src] и [W]."))
		return

	if(istype(W, /obj/item/mecha_ammo))
		ammo_resupply(W, user)
		return

	if(W.GetID())
		open_maintenance_panel(W, user)
		return

	if(istype(W, /obj/item/stock_parts/cell))
		if(construction_state == MECHA_OPEN_HATCH)
			if(!cell)
				if(!(istype(W.loc, /obj/item/storage/part_replacer) ? W.remove_item_from_storage(src) : user.transferItemToLoc(W, src, silent = FALSE)))
					return
				var/obj/item/stock_parts/cell/C = W
				to_chat(user, span_notice("Вы устанавливаете батарею."))
				playsound(src, 'sound/items/screwdriver2.ogg', 50, FALSE)
				cell = C
				log_message("Батарея установлена", LOG_MECHA)
				return TRUE
			else
				to_chat(user, span_warning("Батарея уже установлена!"))
		return

	if(istype(W, /obj/item/stock_parts/scanning_module))
		if(construction_state == MECHA_OPEN_HATCH)
			if(!scanmod)
				if(!(istype(W.loc, /obj/item/storage/part_replacer) ? W.remove_item_from_storage(src) : user.transferItemToLoc(W, src)))
					return
				to_chat(user, span_notice("Вы устанавливаете сканирующий модуль."))
				playsound(src, 'sound/items/screwdriver2.ogg', 50, FALSE)
				scanmod = W
				log_message("[W] установлен", LOG_MECHA)
				update_part_values()
				return TRUE
			else
				to_chat(user, span_warning("Сканирующий модуль уже установлен!"))
		return

	if(istype(W, /obj/item/stock_parts/capacitor))
		if(construction_state == MECHA_OPEN_HATCH)
			if(!capacitor)
				if(!(istype(W.loc, /obj/item/storage/part_replacer) ? W.remove_item_from_storage(src) : user.transferItemToLoc(W, src)))
					return
				to_chat(user, span_notice("Вы устанавливаете конденсатор."))
				playsound(src, 'sound/items/screwdriver2.ogg', 50, FALSE)
				capacitor = W
				log_message("[W] установлен", LOG_MECHA)
				update_part_values()
				return TRUE
			else
				to_chat(user, span_warning("Конденсатор уже установлен!"))
		return

	if(istype(W, /obj/item/stack/cable_coil))
		if(construction_state == MECHA_OPEN_HATCH && (internal_damage & MECHA_INT_SHORT_CIRCUIT))
			var/obj/item/stack/cable_coil/CC = W
			if(CC.use(2))
				clearInternalDamage(MECHA_INT_SHORT_CIRCUIT)
				to_chat(user, span_notice("Вы заменяете оплавленные провода."))
			else
				to_chat(user, span_warning("Для ремонта меха нужны два отрезка кабеля!"))
		return

	if(istype(W, /obj/item/mecha_parts))
		var/obj/item/mecha_parts/P = W
		P.try_attach_part(user, src)
		return
	if(istype(W, /obj/item/analyzer))
		if(construction_state)
			var/datum/gas_mixture/GasNux = internal_tank.return_air()
			atmosanalyzer_scan(GasNux,user,src,TRUE)
		else
			atmosanalyzer_scan(cabin_air,user,src,TRUE)
		return
	log_message("Атака с помощью [W]. Нападавший: [user]", LOG_MECHA)
	return ..()

/obj/vehicle/sealed/mecha/wrench_act(mob/living/user, obj/item/I)
	..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE
	if(construction_state != MECHA_SECURE_BOLTS && construction_state != MECHA_LOOSE_BOLTS)
		return
	if(!I.use_tool(src, user, 0, volume = 50))
		return
	if(construction_state == MECHA_SECURE_BOLTS)
		construction_state = MECHA_LOOSE_BOLTS
		to_chat(user, span_notice("Вы ослабляете крепёжные болты."))
		return
	if(construction_state == MECHA_LOOSE_BOLTS)
		construction_state = MECHA_SECURE_BOLTS
		to_chat(user, span_notice("Вы затягиваете крепёжные болты."))

/obj/vehicle/sealed/mecha/crowbar_act(mob/living/user, obj/item/I)
	..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE
	if(construction_state != MECHA_LOOSE_BOLTS && construction_state != MECHA_OPEN_HATCH)
		return
	if(!I.use_tool(src, user, 0, volume = 50))
		return
	if(construction_state == MECHA_LOOSE_BOLTS)
		construction_state = MECHA_OPEN_HATCH
		to_chat(user, span_notice("Вы открываете люк силового отсека."))
		return
	if(construction_state == MECHA_OPEN_HATCH)
		construction_state = MECHA_LOOSE_BOLTS
		to_chat(user, span_notice("Вы закрываете люк силового отсека."))

/obj/vehicle/sealed/mecha/screwdriver_act(mob/living/user, obj/item/I)
	..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		clearInternalDamage(MECHA_INT_TEMP_CONTROL)
		to_chat(user, span_notice("Вы чините повреждённый терморегулятор."))
		return

/obj/vehicle/sealed/mecha/welder_act(mob/living/user, obj/item/W)
	. = ..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE
	if (user in occupants)
		to_chat(user, span_notice("Внешние повреждения не починить изнутри!"))
		return
	if(internal_damage & MECHA_INT_TANK_BREACH)
		if(!W.use_tool(src, user, 0, volume=50, amount=1))
			return
		clearInternalDamage(MECHA_INT_TANK_BREACH)
		to_chat(user, span_notice("Вы починили повреждённую газовую канистру."))
		if(obj_integrity >= max_integrity)
			return
	if(obj_integrity < max_integrity)
		if(INTERACTING_WITH(user, src))
			return
		var/proficient_worker = HAS_TRAIT(user.mind, TRAIT_MECHA_EXPERT)
		if(!W.tool_start_check(user, amount = 1))
			return
		while(obj_integrity < max_integrity)
			if(!W.use_tool(src, user, proficient_worker ? 3 SECONDS : 6 SECONDS, volume = 50, amount = 1))
				return
			user.visible_message(span_notice("[user] чинит часть повреждений [name]."), span_notice("Вы чините часть повреждений [src]."))
			obj_integrity += min(10, max_integrity - obj_integrity)
		to_chat(user, span_notice("Похоже, повреждений больше нет."))
		return
	to_chat(user, span_warning("Целостность [name] не нарушена!"))

/obj/vehicle/sealed/mecha/proc/mech_toxin_damage(mob/living/target)
	playsound(src, 'sound/effects/spray2.ogg', 50, TRUE)
	if(target.reagents)
		if(target.reagents.get_reagent_amount(/datum/reagent/cryptobiolin) + force < force*2)
			target.reagents.add_reagent(/datum/reagent/cryptobiolin, force/2)
		if(target.reagents.get_reagent_amount(/datum/reagent/toxin) + force < force*2)
			target.reagents.add_reagent(/datum/reagent/toxin, force/2.5)


/obj/vehicle/sealed/mecha/mech_melee_attack(obj/vehicle/sealed/mecha/M, mob/user)
	if(!has_charge(melee_energy_drain))
		return NONE
	use_power(melee_energy_drain)
	if(M.damtype == BRUTE || M.damtype == BURN)
		log_combat(user, src, "attacked", M, "(INTENT: [uppertext(user ? user.a_intent : INTENT_HARM)]) (DAMTYPE: [uppertext(M.damtype)])")
		. = ..()

/obj/vehicle/sealed/mecha/proc/full_repair(charge_cell)
	obj_integrity = max_integrity
	if(cell && charge_cell)
		cell.charge = cell.maxcharge
	if(internal_damage & MECHA_INT_FIRE)
		clearInternalDamage(MECHA_INT_FIRE)
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		clearInternalDamage(MECHA_INT_TEMP_CONTROL)
	if(internal_damage & MECHA_INT_SHORT_CIRCUIT)
		clearInternalDamage(MECHA_INT_SHORT_CIRCUIT)
	if(internal_damage & MECHA_INT_TANK_BREACH)
		clearInternalDamage(MECHA_INT_TANK_BREACH)
	if(internal_damage & MECHA_INT_CONTROL_LOST)
		clearInternalDamage(MECHA_INT_CONTROL_LOST)

/obj/vehicle/sealed/mecha/narsie_act()
	emp_act(80)

/obj/vehicle/sealed/mecha/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect)
		if(selected)
			used_item = selected
		else if(!visual_effect_icon)
			visual_effect_icon = ATTACK_EFFECT_SMASH
			if(damtype == BURN)
				visual_effect_icon = ATTACK_EFFECT_MECHFIRE
			else if(damtype == TOX)
				visual_effect_icon = ATTACK_EFFECT_MECHTOXIN
	..()
