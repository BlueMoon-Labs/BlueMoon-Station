/obj/vehicle/sealed/mecha/working/ripley
	name = "\improper APLU MK-I \"Ripley\""
	desc = "Автономный погрузочный агрегат MK-I. Разработан в первую очередь для тяжёлых подъёмов, Ripley может быть оснащён различным оборудованием для выполнения множества задач."
	icon_state = "ripley"
	silicon_icon_state = "ripley-empty"
	movedelay = 1.5 //Move speed, lower is faster.
	max_temperature = 20000
	max_integrity = 200
	lights_power = 7
	deflect_chance = 15
	armor_type = /datum/armor/ripley
	max_equip = 6
	wreckage = /obj/structure/mecha_wreckage/ripley
	internals_req_access = list(ACCESS_ENGINE, ACCESS_ROBOTICS, ACCESS_MINING)
	enclosed = FALSE //Normal ripley has an open cockpit design
	enter_delay = 10 //can enter in a quarter of the time of other mechs
	exit_delay = 10
	mecha_type = MECHA_TYPE_WORKING | MECHA_TYPE_RIPLEY
	ui_theme = "engineering"
	/// How fast the mech is in low pressure
	var/fast_pressure_step_in = 1.5
	/// How fast the mech is in normal pressure
	var/slow_pressure_step_in = 2
	/// Amount of Goliath hides attached to the mech
	var/hides = 0
	/// List of all things in Ripley's Cargo Compartment
	var/list/cargo = new
	/// How much things Ripley can carry in their Cargo Compartment
	var/cargo_capacity = 15

/obj/vehicle/sealed/mecha/working/ripley/Move()
	. = ..()
	update_pressure()

/obj/vehicle/sealed/mecha/working/ripley/check_for_internal_damage(list/possible_int_damage, ignore_threshold = FALSE)
	if (!enclosed)
		possible_int_damage -= (MECHA_INT_TEMP_CONTROL + MECHA_INT_TANK_BREACH) //if we don't even have an air tank, these two doesn't make a ton of sense.
	. = ..()

/obj/vehicle/sealed/mecha/working/ripley/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/armor_plate,3,/obj/item/stack/sheet/animalhide/goliath_hide,list(MELEE = 10, BULLET = 5, LASER = 5))

/obj/vehicle/sealed/mecha/working/ripley/generate_actions()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_eject)
	if(enclosed)
		initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/mech_toggle_internals, VEHICLE_CONTROL_SETTINGS)
	initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/mech_toggle_lights, VEHICLE_CONTROL_SETTINGS)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/mech_view_stats)
	initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/strafe, VEHICLE_CONTROL_DRIVE)
	initialize_controller_action_type(/datum/action/vehicle/sealed/mecha/toggle_stabilizers, VEHICLE_CONTROL_DRIVE)
	if(max_occupants > 1)
		initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/swap_seat)

/obj/vehicle/sealed/mecha/working/ripley/Destroy()
	for(var/atom/movable/A in cargo)
		A.forceMove(drop_location())
		step_rand(A)
	cargo.Cut()
	return ..()

/obj/vehicle/sealed/mecha/working/ripley/mkii
	desc = "Автономный погрузочный агрегат MK-II. Этот прототип Ripley оснащён герметичной кабиной, жертвуя прежней скоростью ради атмосферной защиты и брони."
	name = "\improper APLU MK-II \"Ripley\""
	icon_state = "ripleymkii"
	fast_pressure_step_in = 2 //step_in while in low pressure conditions
	slow_pressure_step_in = 4 //step_in while in normal pressure conditions
	movedelay = 4
	max_temperature = 30000
	max_integrity = 250
	armor_type = /datum/armor/firefighter_and_mkii
	wreckage = /obj/structure/mecha_wreckage/ripley/mkii
	enclosed = TRUE
	enter_delay = 40
	silicon_icon_state = null
	ui_theme = "mining"

/obj/vehicle/sealed/mecha/working/ripley/firefighter
	desc = "Автономный погрузочный агрегат MK-II-F. Эта модель оснащена дополнительной термозащитой."
	name = "\improper APLU \"Firefighter\""
	icon_state = "firefighter"
	movedelay = 4
	fast_pressure_step_in = 2
	slow_pressure_step_in = 4
	max_temperature = 65000
	max_integrity = 250
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	armor_type = /datum/armor/firefighter_and_mkii
	enclosed = TRUE
	enter_delay = 40
	ui_theme = "mining"

/obj/vehicle/sealed/mecha/working/ripley/deathripley
	desc = "ОХ ЧЁРТ, ЭТО ОТРЯД СМЕРТИ, НАМ ВСЕМ КАБЗДА"
	name = "\improper DEATH-RIPLEY"
	icon_state = "deathripley"
	fast_pressure_step_in = 2 //step_in while in low pressure conditions
	slow_pressure_step_in = 3 //step_in while in normal pressure conditions
	movedelay = 4
	lights_power = 7
	wreckage = /obj/structure/mecha_wreckage/ripley/deathripley
	normal_step_energy_drain = 0
	enclosed = TRUE
	enter_delay = 40
	silicon_icon_state = null

/obj/vehicle/sealed/mecha/working/ripley/deathripley/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill
	ME.attach(src)

/obj/vehicle/sealed/mecha/working/ripley/deathripley/real
	desc = "ОХ ЧЁРТ, ЭТО ОТРЯД СМЕРТИ, НАМ ВСЕМ КАБЗДА. НА САМОМ ДЕЛЕ"

/obj/vehicle/sealed/mecha/working/ripley/deathripley/real/Initialize(mapload)
	. = ..()
	for(var/obj/item/mecha_parts/mecha_equipment/E in equipment)
		E.detach()
		qdel(E)
	LAZYCLEARLIST(equipment)
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/kill/real
	ME.attach(src)

/obj/vehicle/sealed/mecha/working/ripley/mining
	desc = "Старый, пыльный шахтёрский Ripley."
	name = "\improper APLU \"Miner\""
	obj_integrity = 75 //Low starting health

/obj/vehicle/sealed/mecha/working/ripley/mining/Initialize(mapload)
	. = ..()
	if(cell)
		cell.charge = FLOOR(cell.charge * 0.25, 1) //Starts at very low charge
	if(prob(70)) //Maybe add a drill
		if(prob(15)) //Possible diamond drill... Feeling lucky?
			var/obj/item/mecha_parts/mecha_equipment/drill/diamonddrill/D = new
			D.attach(src)
		else
			var/obj/item/mecha_parts/mecha_equipment/drill/D = new
			D.attach(src)

	else //Add plasma cutter if no drill
		var/obj/item/mecha_parts/mecha_equipment/weapon/energy/plasma/P = new
		P.attach(src)

	//Add ore box to cargo
	cargo.Add(new /obj/structure/ore_box(src))

	//Attach hydraulic clamp
	var/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp/HC = new
	HC.attach(src)
	for(var/obj/item/mecha_parts/mecha_tracking/B in trackers)//Deletes the beacon so it can't be found easily
		qdel(B)

	var/obj/item/mecha_parts/mecha_equipment/mining_scanner/scanner = new
	scanner.attach(src)

/obj/vehicle/sealed/mecha/working/ripley/Exit(atom/movable/O)
	if(O in cargo)
		return FALSE
	return ..()

/obj/vehicle/sealed/mecha/working/ripley/get_cargo_ui_data()
	var/list/cargo_list = list()
	for(var/atom/movable/item as anything in cargo)
		var/obj/item/stack/stack = item
		cargo_list += list(list("name" = item.name, "amount" = istype(stack) ? stack.amount : 1, "ref" = REF(item)))
	return list("capacity" = cargo_capacity, "cargo_list" = cargo_list)

/obj/vehicle/sealed/mecha/working/ripley/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || action != "drop_from_cargo" || ui_status(ui.user, state) != UI_INTERACTIVE || !(occupants[ui.user] & VEHICLE_CONTROL_EQUIPMENT))
		return
	var/atom/movable/item = locate(params["cargo_item"]) in cargo
	if(!item)
		return FALSE
	item.forceMove(drop_location())
	cargo -= item
	log_message("Выгружен [item]. Свободных мест в грузовом отсеке: [cargo_capacity - length(cargo)]", LOG_MECHA)
	return TRUE


/obj/vehicle/sealed/mecha/working/ripley/contents_explosion(severity, target, origin)
	for(var/X in cargo)
		var/obj/O = X
		if(prob(30/severity))
			cargo -= O
			O.forceMove(drop_location())
	. = ..()

/obj/vehicle/sealed/mecha/working/ripley/relay_container_resist(mob/living/user, obj/O)
	to_chat(user, span_notice("Вы упираетесь в [O] и начинаете выталкивать его из [src]."))
	if(INTERACTING_WITH(user, O))
		to_chat(user, span_warning("Вы уже взаимодействуете с [O]!"))
		return
	if(do_after(user, 300, target = O))
		if(!user || user.stat != CONSCIOUS || user.loc != src || O.loc != src )
			return
		to_chat(user, span_notice("Вам удалось вытолкнуть [O] из [src]!"))
		O.forceMove(drop_location())
		cargo -= O
	else
		if(user.loc == src) //so we don't get the message if we resisted multiple times and succeeded.
			to_chat(user, span_warning("Вам не удалось вытолкнуть [O] из [src]!"))

/**
  * Makes the mecha go faster and halves the mecha drill cooldown if in Lavaland pressure.
  *
  * Checks for Lavaland pressure, if that works out the mech's speed is equal to fast_pressure_step_in and the cooldown for the mecha drill is halved. If not it uses slow_pressure_step_in and drill cooldown is normal.
  */
/obj/vehicle/sealed/mecha/working/ripley/proc/update_pressure()
	var/turf/T = get_turf(loc)

	if(lavaland_equipment_pressure_check(T))
		movedelay = fast_pressure_step_in
		for(var/obj/item/mecha_parts/mecha_equipment/drill/drill in equipment)
			drill.equip_cooldown = initial(drill.equip_cooldown) * 0.5

	else
		movedelay = slow_pressure_step_in
		for(var/obj/item/mecha_parts/mecha_equipment/drill/drill in equipment)
			drill.equip_cooldown = initial(drill.equip_cooldown)
