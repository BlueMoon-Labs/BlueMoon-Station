/obj/machinery/recharger
	name = "recharger"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "recharger"
	base_icon_state = "recharger"
	desc = "Зарядная станция для энерговооружения."
	use_power = IDLE_POWER_USE
	idle_power_usage = 4
	active_power_usage = 250
	circuit = /obj/item/circuitboard/machine/recharger
	pass_flags = PASSTABLE
	var/obj/item/charging = null
	var/recharge_coeff = 1
	var/using_power = FALSE //Did we put power into "charging" last process()?
	///Did we finish recharging the currently inserted item?
	var/finished_recharging = FALSE

	var/static/list/allowed_devices = typecacheof(list(
		/obj/item/gun/energy,
		/obj/item/melee/baton,
		/obj/item/ammo_box/magazine/recharge,
		/obj/item/modular_computer,
		/obj/item/ammo_casing/mws_batt,
		/obj/item/ammo_box/magazine/mws_mag,
		/obj/item/electrostaff,
		/obj/item/melee/tomahawk,
		/obj/item/gun/ballistic/automatic/magrifle,
		/obj/item/paicard))

/obj/machinery/recharger/RefreshParts()
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		recharge_coeff = C.rating

/obj/machinery/recharger/examine(mob/user)
	. = ..()
	if(!in_range(user, src) && !issilicon(user) && !isobserver(user))
		. += span_warning("Вы слишком далеко от [src] для проверки содержимого и дисплея!</span>")
		return

	if(charging)
		. += span_notice("\The [src] содержит: \n\
		– \A [charging].")

	if(!(machine_stat & (NOPOWER|BROKEN)))
		if(charging)
			// Часть заряжаемого (например, самозарядные энергопушки) вовсе не имеет ячейки.
			var/obj/item/stock_parts/cell/charging_cell = charging.get_cell()
			if(charging_cell)
				. += span_notice("– Батарея [charging] заряжена на <b>[charging_cell.percent()]%</b>.")
			else
				. += span_notice("– \The [charging] не имеет считываемой батареи.")

/obj/machinery/recharger/examine_display_content()
	. += "– Заряжается <b>[recharge_coeff*10]%</b> заряда батареи за цикл."

/obj/machinery/recharger/proc/setCharging(new_charging)
	// Уведомляем старый айтем если это talking gun
	if(charging && istype(charging, /obj/item/gun/energy/e_gun/hos/dreadmk3/talking))
		var/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/old_gun = charging
		old_gun.exit_recharger()

	charging = new_charging
	if (new_charging)
		// Уведомляем новый айтем если это talking gun
		if(istype(new_charging, /obj/item/gun/energy/e_gun/hos/dreadmk3/talking))
			var/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/new_gun = new_charging
			new_gun.enter_recharger()

		START_PROCESSING(SSmachines, src)
		finished_recharging = FALSE
		use_power = ACTIVE_POWER_USE
		using_power = TRUE
		update_appearance()
	else
		use_power = IDLE_POWER_USE
		using_power = FALSE
		update_appearance()

/obj/machinery/recharger/Exited(atom/movable/M, atom/newloc)
	. = ..()
	if(charging == M)
		setCharging()

/obj/machinery/recharger/attackby(obj/item/G, mob/user, params)
	var/allowed = is_type_in_typecache(G, allowed_devices)

	if(allowed)
		if(anchored)
			if(charging || panel_open)
				return TRUE

			//Checks to make sure he's not in space doing it, and that the area got proper power.
			var/area/a = get_area(src)
			if(!a || !a.powered(EQUIP))
				to_chat(user, span_notice("[src] мигает красным при попытке вставить [G]."))
				return TRUE

			if (istype(G, /obj/item/gun/energy))
				var/obj/item/gun/energy/E = G
				if(!E.can_charge)
					to_chat(user, span_notice("Ваше оружие не имеет внешнего зарядного разъёма."))
					return TRUE

			if(!user.transferItemToLoc(G, src))
				return TRUE
			setCharging(G)

		else
			to_chat(user, span_notice("[src] не имеет подключения!"))
		return TRUE

	if(anchored && !charging)
		if(default_deconstruction_screwdriver(user, "recharger", "recharger", G))
			update_appearance()
			return

		if(panel_open && G.tool_behaviour == TOOL_CROWBAR)
			default_deconstruction_crowbar(G)
			return

	return ..()

/obj/machinery/recharger/wrench_act(mob/living/user, obj/item/tool)
	if(charging)
		to_chat(user, span_notice("Сначала извлеките заряжаемый предмет!"))
		return FALSE

	setAnchored(!anchored)
	power_change()
	to_chat(user, span_notice("Вы [anchored ? "прикрепили" : "открепили"] [src]."))
	tool.play_tool_sound(src)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/recharger/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)

	add_fingerprint(user)
	if(charging)
		charging.update_icon()
		user.put_in_hands(charging)

/obj/machinery/recharger/attack_tk(mob/user)
	if(charging)
		charging.update_icon()
		charging.forceMove(drop_location())

/obj/machinery/recharger/process()
	if(machine_stat & (NOPOWER|BROKEN) || !anchored)
		return PROCESS_KILL

	using_power = FALSE
	if(charging)
		var/obj/item/stock_parts/cell/C = charging.get_cell()
		if(C)
			if(C.charge < C.maxcharge)
				C.give(C.chargerate * recharge_coeff)
				use_power(250 * recharge_coeff)
				using_power = TRUE
			update_appearance()

		if(istype(charging, /obj/item/ammo_box/magazine/recharge))
			var/obj/item/ammo_box/magazine/recharge/R = charging
			if(R.stored_ammo.len < R.max_ammo)
				R.stored_ammo += new R.ammo_type(R)
				use_power(1000 * recharge_coeff)
				using_power = TRUE
			update_appearance()
			return

		if(istype(charging, /obj/item/ammo_casing/mws_batt))
			var/obj/item/ammo_casing/mws_batt/R = charging
			if(R.cell.charge < R.cell.maxcharge)
				R.cell.give(R.cell.chargerate * recharge_coeff)
				use_power(250 * recharge_coeff)
				using_power = 1
			if(R.BB == null)
				R.chargeshot()
			update_appearance()

		if(istype(charging, /obj/item/ammo_box/magazine/mws_mag))
			var/obj/item/ammo_box/magazine/mws_mag/R = charging
			for(var/B in R.stored_ammo)
				var/obj/item/ammo_casing/mws_batt/batt = B
				if(batt.cell.charge < batt.cell.maxcharge)
					batt.cell.give(batt.cell.chargerate * recharge_coeff)
					use_power(250 * recharge_coeff)
					using_power = 1
				if(batt.BB == null)
					batt.chargeshot()
			update_appearance()

		if(!using_power && !finished_recharging) //Inserted thing is at max charge/ammo, notify those around us
			finished_recharging = TRUE
			playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
			say("Зарядка [charging] завершена!")

	else
		return PROCESS_KILL

/obj/machinery/recharger/power_change()
	..()
	update_appearance()

/obj/machinery/recharger/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_CONTENTS)
		return
	if(!(machine_stat & (NOPOWER|BROKEN)) && anchored)
		if(istype(charging,  /obj/item/gun/energy))
			var/obj/item/gun/energy/E = charging
			if(E.cell)
				E.cell.emp_act(severity)

		else if(istype(charging, /obj/item/melee/baton))
			var/obj/item/melee/baton/B = charging
			if(B.cell)
				B.cell.charge = 0

/obj/machinery/recharger/update_appearance(updates)
	. = ..()
	if((machine_stat & (NOPOWER|BROKEN)) || panel_open || !anchored)
		luminosity = 0
		return
	luminosity = 1

/obj/machinery/recharger/update_overlays()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || !anchored)
		return
	if(panel_open)
		. += mutable_appearance(icon, "[base_icon_state]-open", alpha = src.alpha)
		return

	if(!charging)
		. += mutable_appearance(icon, "[base_icon_state]-empty", alpha = src.alpha)
		. += emissive_appearance(icon, "[base_icon_state]-empty", alpha = src.alpha)
		return
	if(using_power)
		. += mutable_appearance(icon, "[base_icon_state]-charging", alpha = src.alpha)
		. += emissive_appearance(icon, "[base_icon_state]-charging", alpha = src.alpha)
		return

	. += mutable_appearance(icon, "[base_icon_state]-full", alpha = src.alpha)
	. += emissive_appearance(icon, "[base_icon_state]-full", alpha = src.alpha)
