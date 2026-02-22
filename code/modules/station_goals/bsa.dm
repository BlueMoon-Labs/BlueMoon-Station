// Crew has to build a bluespace cannon
// Cargo orders part for high price
// Requires high amount of power (modular: power scales with energy fed to BSA)
// Requires high level stock parts

// BSA modular system states and constants
#define BSA_SYSTEM_READY "SYSTEM READY"
#define BSA_SYSTEM_PREFIRE "! SYSTEM PREFIRING !"
#define BSA_SYSTEM_FIRING "SYSTEM FIRING"
#define BSA_SYSTEM_RELOADING "SYSTEM RELOADING"
#define BSA_SYSTEM_LOW_POWER "SYSTEM POWER LOW"
#define BSA_SYSTEM_CHARGE_CAPACITORS "SYSTEM CHARGING CAPACITORS"
#define BSA_RELOAD_TIME 20 SECONDS
#define BSA_FIRE_POWER_THRESHOLD 1000000 // 1 MW minimum to fire

/datum/station_goal/bluespace_cannon
	name = "Bluespace Artillery"

/datum/station_goal/bluespace_cannon/get_report()
	return {" <b>Наше военное присутствие в вашем секторе недостаточно.</b><br>
	Нам нужно, чтобы вы построили артиллерийскую установку BSA-[rand(1,99)] на борту вашей станции.
	После постройки необходимо проверить работоспособность, выстрелив по любой цели.
	<br><br>
	Основа для артиллерии доступна к заказу в карго.
	<br>
	- Флотское командование Нанотрейзен"}

/datum/station_goal/bluespace_cannon/on_report()
	//Unlock BSA parts
	var/datum/supply_pack/engineering/bsa/P = SSshuttle.supply_packs[/datum/supply_pack/engineering/bsa]
	P.special_enabled = TRUE

/datum/station_goal/bluespace_cannon/check_completion()
	if(!..())
		return FALSE
	for(var/obj/machinery/bsa/full/B in SSmachines.get_machines_by_type(/obj/machinery/bsa/full))
		if(B && !B.machine_stat && (is_station_level(B.z) || is_mining_level(B.z)))
			return TRUE
	return FALSE

/obj/machinery/bsa
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	density = TRUE
	anchored = TRUE

/obj/machinery/bsa/wrench_act(mob/living/user, obj/item/I)
	..()
	default_unfasten_wrench(user, I, 10)
	return TRUE

/obj/machinery/bsa/back
	name = "Bluespace Artillery Generator"
	desc = "Generates cannon pulse. Needs to be linked with a fusor."
	icon_state = "power_box"

/obj/machinery/bsa/back/multitool_act(mob/living/user, obj/item/I)
	if(I.tool_behaviour == TOOL_MULTITOOL) // Lies and deception
		I.buffer = src
		to_chat(user, "<span class='notice'>You store linkage information in [I]'s buffer.</span>")
	else
		to_chat(user, "<span class='warning'>[I] has no data buffer!</span>")
	return TRUE

/obj/machinery/bsa/front
	name = "Bluespace Artillery Bore"
	desc = "Do not stand in front of cannon during operation. Needs to be linked with a fusor."
	icon_state = "emitter_center"

/obj/machinery/bsa/front/multitool_act(mob/living/user, obj/item/I)
	if(I.tool_behaviour == TOOL_MULTITOOL) // Lies and deception
		I.buffer = src
		to_chat(user, "<span class='notice'>You store linkage information in [I]'s buffer.</span>")
	else
		to_chat(user, "<span class='warning'>[I] has no data buffer!</span>")
	return TRUE

/obj/machinery/bsa/middle
	name = "Bluespace Artillery Fusor"
	desc = "Contents classified by Nanotrasen Naval Command. Needs to be linked with the other BSA parts using multitool."
	icon_state = "fuel_chamber"
	var/obj/machinery/bsa/back/back
	var/obj/machinery/bsa/front/front

/obj/machinery/bsa/middle/multitool_act(mob/living/user, obj/item/I)
	if(I.tool_behaviour == TOOL_MULTITOOL) // Lies and deception
		if(I.buffer)
			if(istype(I.buffer, /obj/machinery/bsa/back))
				back = I.buffer
				I.buffer = null
				to_chat(user, "<span class='notice'>You link [src] with [back].</span>")
			else if(istype(I.buffer, /obj/machinery/bsa/front))
				front = I.buffer
				I.buffer = null
				to_chat(user, "<span class='notice'>You link [src] with [front].</span>")
		else
			to_chat(user, "<span class='warning'>[I]'s data buffer is empty!</span>")
	else
		to_chat(user, "<span class='warning'>[I] has no data buffer!</span>")
	return TRUE

/obj/machinery/bsa/middle/proc/check_completion()
	if(!front || !back)
		return "No linked parts detected!"
	if(!front.anchored || !back.anchored || !anchored)
		return "Linked parts unwrenched!"
	if(front.y != y || back.y != y || !(front.x > x && back.x < x || front.x < x && back.x > x) || front.z != z || back.z != z)
		return "Parts misaligned!"
	if(!has_space())
		return "Not enough free space!"

/obj/machinery/bsa/middle/proc/has_space()
	var/cannon_dir = get_cannon_direction()
	var/x_min
	var/x_max
	switch(cannon_dir)
		if(EAST)
			x_min = x - 4 //replace with defines later
			x_max = x + 6
		if(WEST)
			x_min = x + 4
			x_max = x - 6

	for(var/turf/T in block(locate(x_min,y-1,z),locate(x_max,y+1,z)))
		if(T.density || isspaceturf(T))
			return FALSE
	return TRUE

/obj/machinery/bsa/middle/proc/get_cannon_direction()
	if(front.x > x && back.x < x)
		return EAST
	else if(front.x < x && back.x > x)
		return WEST


/obj/machinery/bsa/full
	name = "Bluespace Artillery"
	desc = "Long range bluespace artillery. Modular: blast power scales with energy fed into the capacitors."
	icon = 'icons/obj/lavaland/cannon.dmi'
	icon_state = "orbital_cannon1"
	use_power = NO_POWER_USE
	pixel_y = -32
	pixel_x = -192
	bound_width = 352
	bound_x = -192
	appearance_flags = NONE
	max_integrity = 2000

	var/static/mutable_appearance/top_layer
	var/capacitor_power = 0
	var/power_suck_cap = 1000000
	var/target_power = 1000000
	var/max_charge = 300000000 // 300 MW
	var/system_state = BSA_SYSTEM_READY
	var/obj/machinery/computer/bsa_control/control_computer

/obj/machinery/bsa/full/Initialize(mapload, cannon_direction = WEST)
	. = ..()
	top_layer = top_layer || mutable_appearance(icon, layer = ABOVE_MOB_LAYER)
	switch(cannon_direction)
		if(WEST)
			setDir(WEST)
			top_layer.icon_state = "top_west"
			icon_state = "cannon_west"
		if(EAST)
			setDir(EAST)
			pixel_x = -128
			bound_x = -128
			top_layer.icon_state = "top_east"
			icon_state = "cannon_east"
	add_overlay(top_layer)
	reload()
	START_PROCESSING(SSobj, src)

/obj/machinery/bsa/full/Destroy()
	control_computer = null
	return ..()

/obj/machinery/bsa/full/wrench_act(mob/living/user, obj/item/I)
	return FALSE

/obj/machinery/bsa/full/proc/get_front_turf()
	switch(dir)
		if(WEST)
			return locate(x - 7,y,z)
		if(EAST)
			return locate(x + 7,y,z)
	return get_turf(src)

/obj/machinery/bsa/full/proc/get_back_turf()
	switch(dir)
		if(WEST)
			return locate(x + 5,y,z)
		if(EAST)
			return locate(x - 5,y,z)
	return get_turf(src)

/obj/machinery/bsa/full/proc/get_target_turf()
	switch(dir)
		if(WEST)
			return locate(1,y,z)
		if(EAST)
			return locate(world.maxx,y,z)
	return get_turf(src)

/obj/machinery/bsa/full/proc/charge_capacitors()
	if(capacitor_power >= target_power)
		if(capacitor_power < BSA_FIRE_POWER_THRESHOLD)
			system_state = BSA_SYSTEM_LOW_POWER
		else
			system_state = BSA_SYSTEM_READY
		return
	var/area/our_area = get_area(src)
	if(!our_area)
		return
	var/obj/machinery/power/apc/our_apc = our_area.get_apc()
	if(!our_apc)
		return
	var/obj/machinery/power/terminal/our_terminal = our_apc.terminal
	if(!our_terminal)
		return
	var/datum/powernet/our_powernet = our_terminal.powernet
	if(!our_powernet)
		return
	var/charge_to_pull = power_suck_cap
	var/charge_to_full = max_charge - capacitor_power
	if(charge_to_full < power_suck_cap)
		charge_to_pull = charge_to_full
	var/max_power_draw = charge_to_pull > our_powernet.avail ? our_powernet.avail : charge_to_pull
	our_powernet.avail -= max_power_draw
	capacitor_power += max_power_draw

/obj/machinery/bsa/full/proc/get_available_powercap()
	var/area/our_area = get_area(src)
	if(!our_area)
		return
	var/obj/machinery/power/apc/our_apc = our_area.get_apc()
	if(!our_apc)
		return
	var/obj/machinery/power/terminal/our_terminal = our_apc.terminal
	if(!our_terminal)
		return
	var/datum/powernet/our_powernet = our_terminal.powernet
	if(!our_powernet)
		return
	return our_powernet.avail

/obj/machinery/bsa/full/process()
	if(system_state == BSA_SYSTEM_CHARGE_CAPACITORS)
		charge_capacitors()
		if(capacitor_power >= target_power)
			return

/obj/machinery/bsa/full/proc/pre_fire(mob/user, turf/bullseye)
	if(system_state != BSA_SYSTEM_READY)
		return
	system_state = BSA_SYSTEM_PREFIRE
	priority_announce("ПАРАМЕТРЫ НАЦЕЛЕНИВАНИЯ BSA УСТАНОВЛЕНЫ, ПРОВОДИТСЯ ПОДГОТОВКА К ВЫСТРЕЛУ... ЗАРЯД КОНДЕНСАТОРА НА [round(capacitor_power / 1000000, 0.1)] МВт, ВЫСТРЕЛ ЧЕРЕЗ 20 СЕКУНД!", "ВНИМАНИЕ: БЛЮСПЕЙС-АРТИЛЛЕРИЯ")
	sound_to_playing_players('sound/effects/bsa/superlaser_prefire.ogg', 80)
	message_admins("[user] has started the fire cycle of [src]! Firing at: [ADMIN_VERBOSEJMP(bullseye)]")
	set_light(5, 5, "#6A97B0")
	addtimer(CALLBACK(src, PROC_REF(fire), user, bullseye), 20 SECONDS, TIMER_CLIENT_TIME)

/obj/machinery/bsa/full/proc/fire(mob/user, turf/bullseye)
	if(system_state != BSA_SYSTEM_PREFIRE || machine_stat)
		minor_announce("ВЫСТРЕЛ ИЗ БЛЮСПЕЙС-АРТИЛЛЕРИИ НЕУДАЧЕН!", "ВНИМАНИЕ: Блюспейс-Артиллерия", TRUE)
		system_state = BSA_SYSTEM_READY
		return
	system_state = BSA_SYSTEM_FIRING
	reload()
	var/turf/point = get_front_turf()
	var/turf/target = get_target_turf()
	var/atom/movable/blocker
	for(var/turf/iterating_turf in get_line(get_step(point, dir), target))
		if(SEND_SIGNAL(iterating_turf, COMSIG_ATOM_BSA_BEAM) & COMSIG_ATOM_BLOCKS_BSA_BEAM)
			blocker = iterating_turf
		else
			for(var/atom/movable/iterating_atom in iterating_turf)
				if(SEND_SIGNAL(iterating_atom, COMSIG_ATOM_BSA_BEAM) & COMSIG_ATOM_BLOCKS_BSA_BEAM)
					blocker = iterating_atom
					break
		if(blocker)
			target = iterating_turf
			break
		else
			iterating_turf.ex_act(EXPLODE_DEVASTATE)
	point.Beam(target, icon_state = "bsa_beam", time = 5 SECONDS, maxdistance = world.maxx)
	new /obj/effect/temp_visual/bsa_splash(point, dir)

	if(!blocker)
		message_admins("[ADMIN_LOOKUPFLW(user)] has launched an artillery strike targeting [ADMIN_VERBOSEJMP(bullseye)].")
		log_game("[key_name(user)] has launched an artillery strike targeting [AREACOORD(bullseye)].")
		minor_announce("ВЫСТРЕЛ ИЗ БЛЮСПЕЙС-АРТИЛЛЕРИИ УСПЕШЕН! ПРЯМОЕ ПОПАДАНИЕ!", "ВНИМАНИЕ: Блюспейс-Артиллерия", TRUE)
		sound_to_playing_players('sound/effects/bsa/superlaser_firing.ogg', 80)
		create_calculated_explosion(bullseye)
		capacitor_power = 0
		if(is_station_level(z) || is_mining_level(z))
			var/datum/station_goal/bluespace_cannon/B = locate() in SSticker.mode?.station_goals
			B?.completed = TRUE
	else
		message_admins("[ADMIN_LOOKUPFLW(user)] has launched an artillery strike targeting [ADMIN_VERBOSEJMP(bullseye)] but it was blocked by [blocker] at [ADMIN_VERBOSEJMP(target)].")
		log_game("[key_name(user)] has launched an artillery strike targeting [AREACOORD(bullseye)] but it was blocked by [blocker] at [AREACOORD(target)].")
		minor_announce("БЛЮСПЕЙС-АРТИЛЛЕРИЯ НЕИСПРАВНА!", "ВНИМАНИЕ: Блюспейс-Артиллерия", TRUE)

/obj/machinery/bsa/full/proc/create_calculated_explosion(atom/target)
	var/calculated_explosion_power = capacitor_power / 10000000
	explosion(target, calculated_explosion_power, calculated_explosion_power * 2, calculated_explosion_power * 4, ignorecap = TRUE)

/obj/machinery/bsa/full/proc/reload()
	system_state = BSA_SYSTEM_RELOADING
	set_light(0)
	STOP_PROCESSING(SSobj, src)
	addtimer(CALLBACK(src, PROC_REF(ready_cannon)), BSA_RELOAD_TIME)

/obj/machinery/bsa/full/proc/ready_cannon()
	if(capacitor_power < BSA_FIRE_POWER_THRESHOLD)
		system_state = BSA_SYSTEM_LOW_POWER
	else
		system_state = BSA_SYSTEM_READY
	STOP_PROCESSING(SSobj, src)

/obj/structure/filler
	name = "big machinery part"
	density = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/obj/machinery/parent

/obj/structure/filler/ex_act(severity, target, origin)
	return

/obj/machinery/computer/bsa_control
	name = "bluespace artillery control"
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/computer/bsa_control
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "control_boxp"
	unique_icon = TRUE
	icon_keyboard = null

	var/datum/weakref/connected_cannon
	var/notice
	var/target
	var/area_aim = FALSE

/obj/machinery/computer/bsa_control/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/computer/bsa_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BluespaceArtillery", name)
		ui.open()

/obj/machinery/computer/bsa_control/ui_data()
	var/list/data = list()
	var/obj/machinery/bsa/full/cannon = connected_cannon?.resolve()
	data["connected"] = cannon
	data["notice"] = notice
	data["unlocked"] = GLOB.bsa_unlock
	data["powernet_power"] = cannon?.get_available_powercap()
	data["power_suck_cap"] = cannon?.power_suck_cap
	data["status"] = cannon?.system_state
	data["capacitor_charge"] = cannon?.capacitor_power
	data["target_capacitor_charge"] = cannon?.target_power
	data["max_capacitor_charge"] = cannon?.max_charge
	if(target)
		data["target"] = get_target_name()
	return data

/obj/machinery/computer/bsa_control/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("build")
			deploy()
			. = TRUE
		if("fire")
			fire(usr)
			. = TRUE
		if("recalibrate")
			calibrate(usr)
			. = TRUE
		if("charge")
			charge()
			. = TRUE
		if("capacitor_target_change")
			change_capacitor_target(params["capacitor_target"])
			. = TRUE
	update_icon()

/obj/machinery/computer/bsa_control/proc/change_capacitor_target(new_target)
	var/obj/machinery/bsa/full/cannon = connected_cannon?.resolve()
	if(!cannon)
		return
	var/num = text2num(new_target)
	cannon.target_power = min(cannon.max_charge, max(BSA_FIRE_POWER_THRESHOLD, num))

/obj/machinery/computer/bsa_control/proc/charge()
	var/obj/machinery/bsa/full/cannon = connected_cannon?.resolve()
	if(!cannon)
		return
	if(cannon.system_state != BSA_SYSTEM_READY && cannon.system_state != BSA_SYSTEM_LOW_POWER)
		return
	cannon.system_state = BSA_SYSTEM_CHARGE_CAPACITORS
	START_PROCESSING(SSobj, cannon)

/obj/machinery/computer/bsa_control/proc/calibrate(mob/user)
	if(!GLOB.bsa_unlock)
		return
	var/list/gps_locators = list()
	for(var/datum/component/gps/G in GLOB.GPS_list) //nulls on the list somehow
		if(G.tracking)
			gps_locators[G.gpstag] = G

	var/list/options = gps_locators
	if(area_aim)
		options += GLOB.teleportlocs
	var/V = input(user,"Select target", "Select target",null) in options|null
	target = options[V]


/obj/machinery/computer/bsa_control/proc/get_target_name()
	if(istype(target, /area))
		return get_area_name(target, TRUE)
	else if(istype(target, /datum/component/gps))
		var/datum/component/gps/G = target
		return G.gpstag

/obj/machinery/computer/bsa_control/proc/get_impact_turf()
	if(istype(target, /area))
		return pick(get_area_turfs(target))
	else if(istype(target, /datum/component/gps))
		var/datum/component/gps/G = target
		return get_turf(G.parent)

/obj/machinery/computer/bsa_control/proc/fire(mob/user)
	var/obj/machinery/bsa/full/cannon = connected_cannon?.resolve()
	if(!cannon)
		notice = "System error"
		return
	if(cannon.machine_stat & BROKEN)
		notice = "Cannon integrity failure!"
		return
	if(cannon.machine_stat & NOPOWER)
		notice = "Cannon unpowered!"
		return
	var/turf/target_turf = get_impact_turf()
	notice = cannon.pre_fire(user, target_turf)

/obj/machinery/computer/bsa_control/proc/deploy(force=FALSE)
	var/obj/machinery/bsa/full/prebuilt = locate() in range(7)
	if(prebuilt)
		prebuilt.control_computer = src
		connected_cannon = WEAKREF(prebuilt)
		return

	var/obj/machinery/bsa/middle/centerpiece = locate() in range(7)
	if(!centerpiece)
		notice = "No BSA parts detected nearby."
		return
	notice = centerpiece.check_completion()
	if(notice)
		return
	var/datum/effect_system/smoke_spread/s = new
	s.set_up(4, get_turf(centerpiece))
	s.start()
	var/obj/machinery/bsa/full/cannon = new(get_turf(centerpiece), centerpiece.get_cannon_direction())
	cannon.control_computer = src
	if(centerpiece.front)
		qdel(centerpiece.front)
	if(centerpiece.back)
		qdel(centerpiece.back)
	qdel(centerpiece)
	connected_cannon = WEAKREF(cannon)
