#define SMOKE_COST(set, mod) (((((set) * 2) ** 2) + (((set) * 2) + 1) ** 2) / ((mod) * (5 / 4)))
#define POWER_COST(set, eff, mult) (400 * (set) * (1/(mult)) / (eff))

/obj/machinery/smoke_machine
	name = "smoke machine"
	desc = "Центрифужная машина. Создаёт дым из любых реактивов, что вы зальёте внутрь."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "smoke0"
	density = TRUE
	use_power = NO_POWER_USE
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN
	circuit = /obj/item/circuitboard/machine/smoke_machine
	var/obj/item/stock_parts/cell/cell
	var/on = FALSE
	var/efficiency = 1
	var/setting = 1 // displayed range is 2 * setting
	var/max_range = 1 // displayed max range
	var/modifier = 1
	var/max_modifier = 1

/obj/machinery/smoke_machine/get_cell()
	return cell

/obj/machinery/smoke_machine/Initialize(mapload)
	. = ..()
	create_reagents(0)
	RefreshParts()
	AddComponent(/datum/component/plumbing/simple_demand)

/obj/machinery/smoke_machine/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS, null, CALLBACK(src, PROC_REF(can_be_rotated)))

/obj/machinery/smoke_machine/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return
	if(default_unfasten_wrench(user, I, 40))
		if(on)
			on = FALSE
			visible_message("<span class='notice'>[src] гаснет при смене крепления.</span>")
		update_icon()
		SStgui.update_uis(src)
		return TRUE
	return FALSE

/obj/machinery/smoke_machine/proc/can_be_rotated(mob/user, rotation_type)
	return !anchored

/obj/machinery/smoke_machine/proc/get_power_source(cost)
	if(anchored)
		var/area/our_area = get_area(src)
		var/obj/machinery/power/apc/our_apc = our_area?.get_apc()
		if(our_apc?.operating && !QDELETED(our_apc.cell) && our_apc.cell.charge >= cost)
			return "apc_cell"
		var/obj/machinery/power/terminal/our_terminal = our_apc?.terminal
		if(our_terminal?.powernet && our_terminal.delayed_surplus() >= cost)
			return "apc"
	if(!QDELETED(cell) && cell.charge >= cost)
		return "cell"
	return null

/obj/machinery/smoke_machine/proc/consume_power(cost, source)
	switch(source)
		if("apc_cell")
			var/area/our_area = get_area(src)
			var/obj/machinery/power/apc/our_apc = our_area?.get_apc()
			if(!our_apc?.operating || QDELETED(our_apc.cell))
				return FALSE
			if(!our_apc.cell.use(cost))
				return FALSE
			if(our_apc.charging == 2)
				our_apc.charging = 1
			return TRUE
		if("apc")
			var/area/our_area = get_area(src)
			var/obj/machinery/power/apc/our_apc = our_area?.get_apc()
			var/obj/machinery/power/terminal/our_terminal = our_apc?.terminal
			if(!our_terminal?.powernet)
				return FALSE
			our_terminal.add_delayedload(cost)
			return TRUE
		if("cell")
			if(QDELETED(cell) || cell.charge < cost)
				return FALSE
			cell.use(cost)
			return TRUE
	return FALSE

/obj/machinery/smoke_machine/on_construction()
	panel_open = TRUE
	update_icon()
	return ..()

/obj/machinery/smoke_machine/on_deconstruction()
	if(!QDELETED(cell))
		LAZYADD(component_parts, cell)
		cell = null
	return ..()

/obj/machinery/smoke_machine/deconstruct()
	reagents.reaction(loc, TOUCH)
	reagents.clear_reagents()
	return ..()

/obj/machinery/smoke_machine/update_icon_state()
	var/no_power = (anchored ? !get_power_source(1) : (QDELETED(cell) || cell.charge <= 1))
	if(!is_operational() || !on || reagents.total_volume == 0 || no_power)
		icon_state = panel_open ? "smoke0-o" : "smoke0"
	else
		icon_state = "smoke1"

/obj/machinery/smoke_machine/RefreshParts()
	var/new_volume = 0
	for(var/obj/item/reagent_containers/glass/beaker/G in component_parts)
		new_volume += G.volume
	if(!reagents)
		create_reagents(0)
	new_volume = max(new_volume, 1)
	reagents.maximum_volume = new_volume
	if(new_volume < reagents.total_volume)
		reagents.reaction(loc, TOUCH) // if someone manages to downgrade it without deconstructing
		reagents.clear_reagents()
	efficiency = 0
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		efficiency += C.rating
	efficiency = max(efficiency, 1)
	max_range = 1
	max_modifier = 0
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		max_modifier += M.rating
		if(M.rating == 6)
			max_range += 8
		else
			max_range += M.rating
	max_range = max(max_range, 2)
	max_modifier = max(max_modifier, 1)

	setting = min(setting, max_range)
	SStgui.update_uis(src)

/datum/effect_system/smoke_spread/chem/smoke_machine/set_up(datum/reagents/carry, setting=1, modifier=1, loc, silent=FALSE)
	amount = setting * 2
	var/cost = SMOKE_COST(setting, modifier)
	carry.copy_to(chemholder, cost)
	carry.remove_any(cost)
	location = loc

/datum/effect_system/smoke_spread/chem/smoke_machine
	effect_type = /obj/effect/particle_effect/smoke/chem/smoke_machine

/obj/effect/particle_effect/smoke/chem/smoke_machine
	opaque = FALSE
	alpha = 100

/obj/machinery/smoke_machine/process()
	..()

	if(!is_operational())
		return
	if(reagents.total_volume == 0)
		on = FALSE
		update_icon()
		return
	var/turf/T = get_turf(src)
	var/smoke_test = locate(/obj/effect/particle_effect/smoke) in T
	var/mult = (modifier == 0.25 || modifier == 0.5) ? modifier : 1
	var/cost = POWER_COST(setting, efficiency, mult)
	if(on && !smoke_test)
		if(reagents.total_volume < SMOKE_COST(setting, modifier))
			on = FALSE
			visible_message("<span class='warning'>[src] гаснет - недостаточно реагентов.</span>")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
			update_icon()
			return
		var/source = get_power_source(cost)
		if(!source)
			on = FALSE
			if(anchored)
				visible_message("<span class='warning'>[src] гаснет — нет нагрузки в сети и батарея разряжена.</span>")
			else
				visible_message("<span class='warning'>[src] гаснет — разряжена батарея.</span>")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
			update_icon()
			return

		update_icon()
		var/datum/effect_system/smoke_spread/chem/smoke_machine/smoke = new()
		smoke.set_up(reagents, setting, modifier, T)
		smoke.start()
		consume_power(cost, source)

/obj/machinery/smoke_machine/attackby(obj/item/I, mob/user, params)
	add_fingerprint(user)

	if(istype(I, /obj/item/stock_parts/cell))
		if(panel_open)
			if(!QDELETED(cell))
				to_chat(user, "<span class='warning'>Внутри уже есть батарея!</span>")
				return
			if(!user.transferItemToLoc(I, src))
				return
			cell = I
			I.add_fingerprint(user)
			user.visible_message(
				"[user] вставляет батарею в [src].",
				"<span class='notice'>Вы вставили батарею в [src].</span>"
			)
			SStgui.update_uis(src)
		else
			to_chat(user, "<span class='warning'>Сначала откройте панель отвёрткой!</span>")
		return

	if(istype(I, /obj/item/reagent_containers) && I.is_open_container())
		var/obj/item/reagent_containers/RC = I
		var/units = RC.reagents.trans_to(src, RC.amount_per_transfer_from_this) //, transfered_by = user)
		if(units)
			to_chat(user, "<span class='notice'>Вы залили [units] u раствора внутрь [src].</span>")
			return
	if(default_deconstruction_screwdriver(user, "smoke0-o", "smoke0", I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/smoke_machine/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SmokeMachine", name)
		ui.open()

/obj/machinery/smoke_machine/ui_data(mob/user)
	var/data = list()
	var/TankContents[0]
	var/TankCurrentVolume = 0
	for(var/datum/reagent/R in reagents.reagent_list)
		TankContents.Add(list(list("name" = R.name, "volume" = R.volume))) // list in a list because Byond merges the first list...
		TankCurrentVolume += R.volume
	data["TankContents"] = TankContents
	data["isTankLoaded"] = reagents.total_volume ? TRUE : FALSE
	data["TankCurrentVolume"] = TankCurrentVolume || null
	data["TankMaxVolume"] = reagents.maximum_volume
	data["active"] = on
	data["setting"] = setting
	data["maxSetting"] = max_range
	data["modifier"] = modifier
	data["maxModifier"] = max_modifier

	data["open"] = panel_open
	data["hasPowercell"] = !QDELETED(cell)
	if(!QDELETED(cell))
		data["powerLevel"] = round(cell.percent(), 1)
	return data

/obj/machinery/smoke_machine/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("purge")
			reagents.clear_reagents()
			update_icon()
			. = TRUE
		if("setting")
			var/amount = text2num(params["amount"])
			if(amount in 1 to max_range)
				if(amount >= 3 && (modifier == 0.25 || modifier == 0.5))
					modifier = 1
				if(amount >= 2 && modifier == 0.25)
					modifier = 0.5
				setting = amount
				. = TRUE
		if("modifier")
			var/mod = text2num(params["multiplier"])
			if(!(mod in 1 to max_modifier) && !(mod in list(0.25, 0.5)))
				return
			if(mod == 0.25 && setting >= 2)
				return
			if(mod == 0.5 && setting >= 3)
				return
			modifier = mod
			. = TRUE
		if("power")
			if(!on)
				if(!get_power_source(1))
					to_chat(usr, "<span class='warning'>Нет доступного источника питания.</span>")
					return TRUE
				if(reagents.total_volume == 0)
					to_chat(usr, "<span class='warning'>Отсутствуют реагенты.</span>")
					return TRUE
			on = !on
			update_icon()
			if(on)
				message_admins("[ADMIN_LOOKUPFLW(usr)] activated a smoke machine that contains [english_list(reagents.reagent_list)] at [ADMIN_VERBOSEJMP(src)].")
				log_game("[key_name(usr)] activated a smoke machine that contains [english_list(reagents.reagent_list)] at [AREACOORD(src)].")
				log_combat(usr, src, "has activated [src] which contains [english_list(reagents.reagent_list)] at [AREACOORD(src)].")
			. = TRUE
		if("eject")
			if(panel_open && !QDELETED(cell))
				on = FALSE
				cell.forceMove(drop_location())
				cell = null
				update_icon()
				. = TRUE
	SStgui.update_uis(src)

/obj/machinery/smoke_machine/emp_act(severity)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_CONTENTS)
		return
	if(!QDELETED(cell))
		cell.emp_act(severity)

#undef SMOKE_COST
#undef POWER_COST
