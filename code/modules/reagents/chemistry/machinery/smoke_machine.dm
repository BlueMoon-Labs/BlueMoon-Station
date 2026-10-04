#define REAGENTS_BASE_VOLUME 75 // actual volume is REAGENTS_BASE_VOLUME plus REAGENTS_BASE_VOLUME * rating for each matterbin
#define SMOKE_COST(set, eff) ((((set) ** 2) + (((set) + 1) ** 2)) / ((eff) * (5 / 4)))
#define POWER_COST(set, eff) (400 * (set) / (eff))

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

/obj/machinery/smoke_machine/get_cell()
	return cell

/obj/machinery/smoke_machine/Initialize(mapload)
	. = ..()
	create_reagents(REAGENTS_BASE_VOLUME)
	RefreshParts()
	AddComponent(/datum/component/plumbing/simple_demand)

/obj/machinery/smoke_machine/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS, null, CALLBACK(src, PROC_REF(can_be_rotated)))

/obj/machinery/smoke_machine/proc/can_be_rotated(mob/user, rotation_type)
	return !anchored

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
	if(!is_operational() || !on || reagents.total_volume == 0 || QDELETED(cell) || cell.charge <= 1)
		if(panel_open)
			icon_state = "smoke0-o"
		else
			icon_state = "smoke0"
	else
		icon_state = "smoke1"

/obj/machinery/smoke_machine/RefreshParts()
	var/new_volume = 0
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		new_volume += REAGENTS_BASE_VOLUME * B.rating
	new_volume = max(new_volume, REAGENTS_BASE_VOLUME)
	if(!reagents)
		create_reagents(new_volume)
	reagents.maximum_volume = new_volume
	if(new_volume < reagents.total_volume)
		reagents.reaction(loc, TOUCH) // if someone manages to downgrade it without deconstructing
		reagents.clear_reagents()
	efficiency = 0
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		efficiency += C.rating
	efficiency = max(efficiency, 1)
	max_range = 1
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		if(M.rating == 6)
			max_range += 8
		else
			max_range += M.rating
	max_range = max(max_range, 2)

	setting = min(setting, max_range)
	SStgui.update_uis(src)

/datum/effect_system/smoke_spread/chem/smoke_machine/set_up(datum/reagents/carry, setting=1, efficiency=1, loc, silent=FALSE)
	amount = setting * 2
	carry.copy_to(chemholder, (SMOKE_COST(setting, efficiency) / amount))
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
	if(QDELETED(cell) || cell.charge <= 1)
		if(on)
			on = FALSE
			update_icon()
		return
	if(reagents.total_volume == 0)
		on = FALSE
		update_icon()
		return
	var/turf/T = get_turf(src)
	var/smoke_test = locate(/obj/effect/particle_effect/smoke) in T
	if(on && !smoke_test)
		if(reagents.total_volume < SMOKE_COST(setting, efficiency))
			on = FALSE
			visible_message("<span class='warning'>[src] гаснет - недостаточно реагентов.</span>")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
			update_icon()
			return
		if(cell.charge < POWER_COST(setting, efficiency))
			on = FALSE
			visible_message("<span class='warning'>[src] гаснет — разряжена батарея.</span>")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
			update_icon()
			return

		update_icon()
		var/datum/effect_system/smoke_spread/chem/smoke_machine/smoke = new()
		smoke.set_up(reagents, setting, efficiency, T)
		smoke.start()
		cell.use(POWER_COST(setting, efficiency))

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
	if(default_unfasten_wrench(user, I, 40))
		on = FALSE
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
				setting = amount
				. = TRUE
		if("power")
			if(!on)
				if(QDELETED(cell))
					to_chat(usr, "<span class='warning'>Нет батареи.</span>")
					return TRUE
				if(cell.charge <= 1)
					to_chat(usr, "<span class='warning'>Батарея разряжена.</span>")
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

/obj/machinery/smoke_machine/emp_act(severity)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_CONTENTS)
		return
	if(!QDELETED(cell))
		cell.emp_act(severity)

#undef REAGENTS_BASE_VOLUME
#undef SMOKE_COST
#undef POWER_COST
