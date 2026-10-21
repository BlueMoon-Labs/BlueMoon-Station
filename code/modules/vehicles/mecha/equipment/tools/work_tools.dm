
//Hydraulic clamp, Kill clamp, Extinguisher, RCD, Cable layer.


/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp
	name = "hydraulic clamp"
	desc = "Оборудование для инженерных экзокостюмов. Поднимает объекты и загружает их в грузовой отсек."
	icon_state = "mecha_clamp"
	equip_cooldown = 15
	energy_drain = 10
	tool_behaviour = TOOL_RETRACTOR
	range = MECHA_MELEE
	toolspeed = 0.8
	harmful = TRUE
	mech_flags = EXOSUIT_MODULE_RIPLEY
	compatible_mecha_types = MECHA_TYPE_RIPLEY
	var/dam_force = 20
	var/obj/vehicle/sealed/mecha/working/ripley/cargo_holder

// Только у рипли есть карго отсек
/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/attach(obj/vehicle/sealed/mecha/working/ripley/M)
	..()
	cargo_holder = istype(M) ? M : null
	return

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/detach(atom/moveto = null)
	..()
	cargo_holder = null

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/action(mob/source, atom/target, params)
	if(!action_checks(target))
		return
	if(ismecha(target))
		if(!cargo_holder)
			to_chat(source, span_warning("У этого меха нет грузового отсека с боезапасом."))
			return
		var/obj/vehicle/sealed/mecha/M = target
		var/have_ammo
		for(var/obj/item/mecha_ammo/box in cargo_holder.cargo)
			if(istype(box, /obj/item/mecha_ammo) && box.rounds)
				have_ammo = TRUE
				if(M.ammo_resupply(box, source, TRUE))
					return
		if(have_ammo)
			to_chat(source, "Боезапас [M] уже заполнен.")
		else
			to_chat(source, "В грузовом отсеке нет подходящих боеприпасов.")
		return
	if(isobj(target))
		var/obj/O = target
		if(istype(O, /obj/machinery/door/firedoor))
			var/obj/machinery/door/firedoor/D = O
			D.try_to_crowbar(src, source)
			return
		if(istype(O, /obj/machinery/door/airlock/))
			var/obj/machinery/door/airlock/D = O
			D.try_to_crowbar(src, source)
			return
		if(!O.anchored)
			if(!cargo_holder)
				to_chat(source, span_warning("У этого меха нет грузового отсека для погрузки."))
				return
			if(cargo_holder.cargo.len < cargo_holder.cargo_capacity)
				chassis.visible_message(span_notice("[chassis] поднимает [target] и начинает погрузку в грузовой отсек."))
				O.set_anchored(TRUE)
				if(do_after_cooldown(target, source))
					cargo_holder.cargo += O
					O.forceMove(chassis)
					O.set_anchored(FALSE)
					to_chat(source, "[icon2html(src, source)][span_notice("[target] успешно погружен.")]")
					log_message("Погружен [O]. Свободных мест в грузовом отсеке: [cargo_holder.cargo_capacity - cargo_holder.cargo.len]", LOG_MECHA)
				else
					O.set_anchored(initial(O.anchored))
			else
				to_chat(source, "[icon2html(src, source)][span_warning("В грузовом отсеке недостаточно места!")]")
		else
			to_chat(source, "[icon2html(src, source)][span_warning("[target] надёжно закреплён!")]")

	else if(isliving(target))
		var/mob/living/M = target
		if(M.stat == DEAD && M.mob_weight < MOB_WEIGHT_HEAVY_SUPER) // BLUEMOON CHANGES, даём возможность толкать сверхтяжёлых персонажей
			return
		if(source.a_intent == INTENT_HARM)
			M.take_overall_damage(dam_force)
			if(!M)
				return
			M.adjustOxyLoss(round(dam_force/2))
			M.updatehealth()
			target.visible_message(span_danger("[chassis] сдавливает [target]!"), \
								span_userdanger("[chassis] сдавливает вас!"),\
								span_hear("Вы слышите хруст."))
			log_combat(source, M, "attacked", "[name]", "(INTENT: [uppertext(source.a_intent)]) (DAMTYPE: [uppertext(damtype)])")
		else
			step_away(M,chassis)
			to_chat(source, "[icon2html(src, source)][span_notice("Вы отталкиваете [target] с дороги.")]")
			chassis.visible_message(span_notice("[chassis] отталкивает [target] с дороги."))
	return ..()



//This is pretty much just for the death-ripley
/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill
	name = "\improper KILL CLAMP"
	desc = "Они даже не поймут, что их схватило!"
	energy_drain = 0
	dam_force = 0
	var/real_clamp = FALSE

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill/real
	desc = "Они даже не поймут, что их схватило! На этот раз по-настоящему!"
	energy_drain = 10
	dam_force = 20
	real_clamp = TRUE

/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill/action(mob/source, atom/target, params)
	if(!action_checks(target))
		return
	if(isobj(target))
		var/obj/O = target
		if(!O.anchored)
			if(!cargo_holder)
				to_chat(source, span_warning("У этого меха нет грузового отсека для погрузки."))
				return
			if(cargo_holder.cargo.len < cargo_holder.cargo_capacity)
				chassis.visible_message(span_notice("[chassis] поднимает [target] и начинает погрузку в грузовой отсек."))
				O.set_anchored(TRUE)
				if(do_after_cooldown(target, source))
					cargo_holder.cargo += O
					O.forceMove(chassis)
					O.set_anchored(FALSE)
					to_chat(source, "[icon2html(src, source)][span_notice("[target] успешно погружен.")]")
					log_message("Погружен [O]. Свободных мест в грузовом отсеке: [cargo_holder.cargo_capacity - cargo_holder.cargo.len]", LOG_MECHA)
				else
					O.set_anchored(initial(O.anchored))
			else
				to_chat(source, "[icon2html(src, source)][span_warning("В грузовом отсеке недостаточно места!")]")
		else
			to_chat(source, "[icon2html(src, source)][span_warning("[target] надёжно закреплён!")]")

	else if(isliving(target))
		var/mob/living/M = target
		if(M.stat == DEAD)
			return
		if(source.a_intent == INTENT_HARM)
			if(real_clamp)
				M.take_overall_damage(dam_force)
				if(!M)
					return
				M.adjustOxyLoss(round(dam_force/2))
				M.updatehealth()
				target.visible_message(span_danger("[chassis] в безумной ярости уничтожает [target]!"), \
									span_userdanger("[chassis] в безумной ярости уничтожает вас!"))
				log_combat(source, M, "attacked", "[name]", "(INTENT: [uppertext(source.a_intent)]) (DAMTYPE: [uppertext(damtype)])")
			else
				target.visible_message(span_danger("[chassis] в безумной ярости уничтожает [target]!"), \
									span_userdanger("[chassis] в безумной ярости уничтожает вас!"))
		else if(source.a_intent == INTENT_DISARM)
			if(real_clamp)
				var/mob/living/carbon/C = target
				var/play_sound = FALSE
				var/limbs_gone = ""
				var/obj/item/bodypart/affected = C.get_bodypart(BODY_ZONE_L_ARM)
				if(affected != null)
					affected.dismember(damtype)
					play_sound = TRUE
					limbs_gone = ", [affected]"
				affected = C.get_bodypart(BODY_ZONE_R_ARM)
				if(affected != null)
					affected.dismember(damtype)
					play_sound = TRUE
					limbs_gone = "[limbs_gone], [affected]"
				if(play_sound)
					playsound(src, get_dismember_sound(), 80, TRUE)
					target.visible_message(span_danger("[chassis] отрывает руки [target]!"), \
								   span_userdanger("[chassis] отрывает вам руки!"))
					log_combat(source, M, "dismembered of[limbs_gone],", "[name]", "(INTENT: [uppertext(source.a_intent)]) (DAMTYPE: [uppertext(damtype)])")
			else
				target.visible_message(span_danger("[chassis] отрывает руки [target]!"), \
								   span_userdanger("[chassis] отрывает вам руки!"))
		else
			step_away(M,chassis)
			target.visible_message(span_danger("[chassis] отбрасывает [target], словно лист бумаги!"), \
								span_userdanger("[chassis] отбрасывает вас, словно лист бумаги!"))
		return ..()



/obj/item/mecha_parts/mecha_equipment/extinguisher
	name = "exosuit extinguisher"
	desc = "Пенный огнетушитель для инженерных экзокостюмов с резервуаром на 1000 единиц. Восстанавливает полный запас за 10 минут, расходуя около 10 000 энергии батареи меха."
	icon_state = "mecha_exting"
	equip_cooldown = 5
	energy_drain = 0
	range = MECHA_MELEE|MECHA_RANGED
	mech_flags = EXOSUIT_MODULE_WORKING
	compatible_mecha_types = MECHA_TYPE_WORKING
	var/foam_regeneration_rate = 1000 / 600
	var/energy_per_unit = 10

/obj/item/mecha_parts/mecha_equipment/extinguisher/Initialize(mapload)
	. = ..()
	create_reagents(1000)
	reagents.add_reagent(/datum/reagent/firefighting_foam, reagents.maximum_volume)

/obj/item/mecha_parts/mecha_equipment/extinguisher/attach(obj/vehicle/sealed/mecha/M)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/mecha_parts/mecha_equipment/extinguisher/detach(atom/moveto)
	. = ..()
	if(!chassis)
		STOP_PROCESSING(SSobj, src)

/obj/item/mecha_parts/mecha_equipment/extinguisher/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/extinguisher/process(delta_time)
	if(!chassis)
		return PROCESS_KILL
	if(chassis.equipment_disabled)
		return
	var/amount = min(reagents.maximum_volume - reagents.total_volume, foam_regeneration_rate * delta_time, max(0, chassis.get_charge()) / energy_per_unit)
	if(amount < CHEMICAL_QUANTISATION_LEVEL || !chassis.has_charge(amount * energy_per_unit) || !chassis.use_power(amount * energy_per_unit))
		return
	reagents.add_reagent(/datum/reagent/firefighting_foam, amount)
	update_equip_info()

/obj/item/mecha_parts/mecha_equipment/extinguisher/action(mob/source, atom/target, params)
	if(!action_checks(target))
		return

	if(istype(target, /obj/structure/reagent_dispensers/foamtank) && get_dist(chassis, target) <= 1)
		var/obj/structure/reagent_dispensers/foamtank/foam_tank = target
		foam_tank.reagents.trans_to(src, reagents.maximum_volume)
		to_chat(chassis.occupants, span_notice("Огнетушитель заправлен."))
		playsound(chassis, 'sound/effects/refill.ogg', 50, 1, -6)
	else
		if(reagents.total_volume < 1)
			return
		playsound(chassis, 'sound/effects/extinguish.ogg', 75, 1, -3)
		spray_extinguisher(chassis, target, reagents, precision = TRUE)
	return ..()

/obj/item/mecha_parts/mecha_equipment/extinguisher/get_ui_data()
	. = ..()
	.["snowflake"] = list("kind" = "extinguisher", "reagents" = round(reagents.total_volume, 0.1), "total_reagents" = reagents.maximum_volume)



/obj/item/mecha_parts/mecha_equipment/rcd
	name = "mounted RCD"
	desc = "Промышленное устройство для быстрого строительства, установленное на экзокостюм. Возводит стены, полы, шлюзы, окна, фаерлоки и каркасы оборудования. Работает от батареи меха."
	icon_state = "mecha_rcd"
	equip_cooldown = 0
	energy_drain = 200
	range = MECHA_MELEE|MECHA_RANGED
	item_flags = NO_MAT_REDEMPTION
	var/energy_drain_deconstruct = 400
	var/obj/item/construction/rcd/mecha/rcd
	var/static/list/rcd_modes = list(
		"Демонтаж" = RCD_DECONSTRUCT,
		"Стены и пол" = RCD_FLOORWALL,
		"Шлюзы" = RCD_AIRLOCK,
		"Решётки и окна" = RCD_WINDOWGRILLE,
		"Стеклянные фаерлоки" = RCD_FIRELOCK,
		"Оконные фаерлоки" = RCD_WINDOW_FIRELOCK,
		"Каркасы машин" = RCD_MACHINE,
		"Каркасы компьютеров" = RCD_COMPUTER,
	)

/obj/item/mecha_parts/mecha_equipment/rcd/Initialize(mapload)
	. = ..()
	rcd = new(src)
	rcd.set_mode(rcd.mode)

/obj/item/mecha_parts/mecha_equipment/rcd/Destroy()
	QDEL_NULL(rcd)
	return ..()

/obj/item/mecha_parts/mecha_equipment/rcd/attack_self(mob/user)
	if(!rcd.check_menu(user))
		return
	rcd.attack_self(user)
	if(!QDELETED(src))
		update_equip_info()

/obj/item/mecha_parts/mecha_equipment/rcd/action(mob/source, atom/target, params)
	target = rcd.resolve_construction_target(target)
	if(!action_checks(target) || !construction_checks(target, source))
		return FALSE
	// Каждая параллельная операция проверяет стоимость режима на момент запуска.
	var/energy_cost = energy_drain
	var/completed = rcd.rcd_create(target, source, CALLBACK(src, PROC_REF(construction_checks), target, source, energy_cost))
	if(QDELETED(src))
		return FALSE
	if(completed && chassis)
		chassis.spark_system.start()
	update_equip_info()
	return completed

/obj/item/mecha_parts/mecha_equipment/rcd/proc/can_operate(mob/user)
	return chassis && user?.loc == chassis && (chassis.occupants[user] & VEHICLE_CONTROL_EQUIPMENT) && !user.incapacitated() && !chassis.completely_disabled && !chassis.is_currently_ejecting && !chassis.equipment_disabled && !chassis.construction_state && !chassis.phasing && !(chassis.mecha_flags & CANNOT_INTERACT)

/obj/item/mecha_parts/mecha_equipment/rcd/proc/construction_checks(atom/target, mob/user, energy_cost)
	if(!can_operate(user) || QDELETED(target) || istype(target, /turf/open/space/transit))
		return FALSE
	var/turf/chassis_turf = get_turf(chassis)
	var/turf/target_turf = get_turf(target)
	return chassis_turf && target_turf && chassis_turf.z == target_turf.z && get_dist(chassis, target) <= rcd.custom_range && do_after_checks(target) && chassis.has_charge(isnull(energy_cost) ? energy_drain : energy_cost)

/obj/item/mecha_parts/mecha_equipment/rcd/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/rcd_upgrade))
		rcd.attackby(W, user, params)
		update_equip_info()
		return TRUE
	return ..()

/obj/item/mecha_parts/mecha_equipment/rcd/handle_ui_act(action, list/params)
	. = ..()
	if(.)
		return TRUE
	if(!equip_ready || !can_operate(usr))
		return FALSE
	switch(action)
		if("menu")
			attack_self(usr)
		if("mode")
			var/new_mode = text2num(params["mode"])
			if(!(new_mode in flatten_list(rcd_modes)))
				return FALSE
			rcd.set_mode(new_mode)
		if("window_type")
			rcd.toggle_window_type(usr)
		if("airlock_type")
			rcd.change_airlock_setting(usr)
		if("computer_direction")
			rcd.change_computer_dir(usr)
		if("one_access")
			rcd.toggle_access("one")
		if("clear_access")
			rcd.toggle_access("all")
		if("access")
			var/access = text2num(params["access"])
			if(!(access in get_all_accesses()))
				return FALSE
			rcd.toggle_access(params["access"])
		else
			return FALSE
	update_equip_info()
	return TRUE

/obj/item/mecha_parts/mecha_equipment/rcd/get_ui_data()
	. = ..()
	var/list/modes = list()
	for(var/mode_name in rcd_modes)
		modes += list(list("name" = mode_name, "id" = rcd_modes[mode_name]))
	var/list/access_regions = list()
	if(rcd.mode == RCD_AIRLOCK)
		for(var/region in 1 to 7)
			var/list/accesses = list()
			for(var/access in get_region_accesses(region))
				accesses += list(list("id" = access, "name" = get_access_desc(access)))
			access_regions += list(list("name" = get_region_accesses_name(region), "accesses" = accesses))
	var/obj/machinery/door/airlock/airlock = rcd.airlock_type
	.["snowflake"] = list(
		"kind" = "rcd",
		"mode" = rcd.mode,
		"modes" = modes,
		"airlock_mode" = rcd.mode == RCD_AIRLOCK,
		"window_mode" = rcd.mode == RCD_WINDOWGRILLE,
		"computer_mode" = rcd.mode == RCD_COMPUTER,
		"airlock_name" = initial(airlock.name),
		"reinforced_windows" = rcd.window_type == /obj/structure/window/reinforced/fulltile,
		"computer_direction" = rcd.computer_dir,
		"one_access" = rcd.use_one_access,
		"access_regions" = access_regions,
		"selected_accesses" = rcd.conf_access || list(),
	)

//Dunno where else to put this so shrug
/obj/item/mecha_parts/mecha_equipment/ripleyupgrade
	name = "Ripley MK-II Conversion Kit"
	desc = "Комплект для переоборудования автономного погрузчика APLU MK-I в более медлительную, но пригодную для космоса модель MK-II. Этот комплект нельзя удалить после установки."
	icon_state = "tesla"
	mech_flags = EXOSUIT_MODULE_RIPLEY
	compatible_mecha_types = MECHA_TYPE_RIPLEY

/obj/item/mecha_parts/mecha_equipment/ripleyupgrade/attach(obj/vehicle/sealed/mecha/M)
	var/obj/vehicle/sealed/mecha/working/ripley/mkii/N = new /obj/vehicle/sealed/mecha/working/ripley/mkii(get_turf(M),1)
	if(!N)
		return
	QDEL_NULL(N.cell)
	if (M.cell)
		N.cell = M.cell
		M.cell.forceMove(N)
		M.cell = null
	QDEL_NULL(N.scanmod)
	if (M.scanmod)
		N.scanmod = M.scanmod
		M.scanmod.forceMove(N)
		M.scanmod = null
	QDEL_NULL(N.capacitor)
	if (M.capacitor)
		N.capacitor = M.capacitor
		M.capacitor.forceMove(N)
		M.capacitor = null
	N.update_part_values()
	for(var/obj/item/mecha_parts/E in M.contents)
		if(istype(E, /obj/item/mecha_parts/concealed_weapon_bay)) //why is the bay not just a variable change who did this
			E.forceMove(N)
	for(var/obj/item/mecha_parts/mecha_equipment/E in M.equipment) //Move the equipment over...
		E.detach(M)
		E.attach(N)
	N.dna_lock = M.dna_lock
	N.dna_lock_name = M.dna_lock_name
	N.mecha_flags = M.mecha_flags
	if(M.is_emagged())
		N.obj_flags |= EMAGGED
		N.max_equip++
	N.strafe = M.strafe
	N.stabilizers = M.stabilizers
	N.obj_integrity = M.obj_integrity //This is not a repair tool
	if (M.name != "\improper APLU MK-I \"Ripley\"")
		N.name = M.name
	M.wreckage = 0
	qdel(M)
	playsound(get_turf(N),'sound/items/ratchet.ogg',50,TRUE)
	return
