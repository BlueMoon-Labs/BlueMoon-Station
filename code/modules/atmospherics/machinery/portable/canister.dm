#define CAN_DEFAULT_RELEASE_PRESSURE (ONE_ATMOSPHERE)

/obj/machinery/portable_atmospherics/canister
	name = "canister"
	desc = "A canister for the storage of gas."
	icon_state = "yellow"
	density = TRUE
	volume = 1000
	armor = list(MELEE = 50, BULLET = 50, LASER = 50, ENERGY = 100, BOMB = 10, BIO = 100, RAD = 100, FIRE = 80, ACID = 50)
	max_integrity = 250
	integrity_failure = 0.4
	pressure_resistance = 7 * ONE_ATMOSPHERE

	var/valve_open = FALSE
	var/release_log = ""

	var/filled = 0.5
	var/gas_type

	var/release_pressure = ONE_ATMOSPHERE
	var/can_max_release_pressure = (ONE_ATMOSPHERE * 10)
	var/can_min_release_pressure = (ONE_ATMOSPHERE / 10)

	// this removes atmos fusion cans**
	///Max amount of heat allowed inside of the canister before it starts to melt (different tiers have different limits)
	// var/heat_limit = 5000
	///Max amount of pressure allowed inside of the canister before it starts to break (different tiers have different limits)
	// var/pressure_limit = 50000

	var/temperature_resistance = 1000 + T0C
	var/starter_temp = T20C
	// Prototype vars
	var/prototype = FALSE
	var/valve_timer = null
	var/timer_set = 30
	var/default_timer_set = 30
	var/minimum_timer_set = 1
	var/maximum_timer_set = 300
	var/timing = FALSE
	var/restricted = FALSE
	///Set the tier of the canister and overlay used
	// var/mode = CANISTER_TIER_1
	req_access = list()

	var/update = 0
	///Pressure band currently shown by the sprite (see update_overlays); process_atmos
	///refreshes the icon only when this moves, instead of rebuilding overlays every fire.
	var/shown_pressure_band = -1
	var/static/list/label2types = list(
		"n2" = /obj/machinery/portable_atmospherics/canister/nitrogen,
		"o2" = /obj/machinery/portable_atmospherics/canister/oxygen,
		"co2" = /obj/machinery/portable_atmospherics/canister/carbon_dioxide,
		"plasma" = /obj/machinery/portable_atmospherics/canister/toxins,
		"n2o" = /obj/machinery/portable_atmospherics/canister/nitrous_oxide,
		"no2" = /obj/machinery/portable_atmospherics/canister/nitryl,
		"bz" = /obj/machinery/portable_atmospherics/canister/bz,
		"air" = /obj/machinery/portable_atmospherics/canister/air,
		"water vapor" = /obj/machinery/portable_atmospherics/canister/water_vapor,
		"tritium" = /obj/machinery/portable_atmospherics/canister/tritium,
		"hyper-noblium" = /obj/machinery/portable_atmospherics/canister/nob,
		"pluoxium" = /obj/machinery/portable_atmospherics/canister/pluoxium,
		"caution" = /obj/machinery/portable_atmospherics/canister,
		"miasma" = /obj/machinery/portable_atmospherics/canister/miasma,
		"methane" = /obj/machinery/portable_atmospherics/canister/methane,
		"hydrogen" = /obj/machinery/portable_atmospherics/canister/hydrogen,
		"helium" = /obj/machinery/portable_atmospherics/canister/helium,
		"freon" = /obj/machinery/portable_atmospherics/canister/freon,
		"halon" = /obj/machinery/portable_atmospherics/canister/halon,
		"antinoblium" = /obj/machinery/portable_atmospherics/canister/antinoblium,
		"proto nitrate" = /obj/machinery/portable_atmospherics/canister/proto_nitrate,
		"zauker" = /obj/machinery/portable_atmospherics/canister/zauker,
		"healium" = /obj/machinery/portable_atmospherics/canister/healium,
		"nitrium" = /obj/machinery/portable_atmospherics/canister/nitrium
	)

/obj/machinery/portable_atmospherics/canister/interact(mob/user)
	if(!allowed(user))
		to_chat(user, "<span class='warning'>Error - Unauthorized User</span>")
		playsound(src, 'sound/misc/compiler-failure.ogg', 50, 1)
		return
	..()

/obj/machinery/portable_atmospherics/canister/nitrogen
	name = "n2 canister"
	desc = "Nitrogen. Reportedly useful for something."
	icon_state = "red"
	gas_type = GAS_N2

/obj/machinery/portable_atmospherics/canister/oxygen
	name = "o2 canister"
	desc = "Oxygen. Necessary for human life."
	icon_state = "blue"
	gas_type = GAS_O2

/obj/machinery/portable_atmospherics/canister/carbon_dioxide
	name = "co2 canister"
	desc = "Carbon dioxide. What the fuck is carbon dioxide?"
	icon_state = "black"
	gas_type = GAS_CO2

/obj/machinery/portable_atmospherics/canister/toxins
	name = "plasma canister"
	desc = "Plasma. The reason YOU are here. Highly toxic."
	icon_state = "orange"
	gas_type = GAS_PLASMA

/obj/machinery/portable_atmospherics/canister/bz
	name = "\improper BZ canister"
	desc = "BZ. A powerful hallucinogenic nerve agent."
	icon_state = "purple"
	gas_type = GAS_BZ

/obj/machinery/portable_atmospherics/canister/nitrous_oxide
	name = "n2o canister"
	desc = "Nitrous oxide. Known to cause drowsiness."
	icon_state = "redws"
	gas_type = GAS_NITROUS

/obj/machinery/portable_atmospherics/canister/air
	name = "air canister"
	desc = "Pre-mixed air."
	icon_state = "grey"

/obj/machinery/portable_atmospherics/canister/tritium
	name = "tritium canister"
	desc = "Tritium. Inhalation might cause irradiation."
	icon_state = "green"
	gas_type = GAS_TRITIUM

/obj/machinery/portable_atmospherics/canister/nob
	name = "hyper-noblium canister"
	desc = "Hyper-Noblium. More noble than all other gases."
	icon_state = "freon"
	gas_type = GAS_HYPERNOB

/obj/machinery/portable_atmospherics/canister/nitryl
	name = "nitryl canister"
	desc = "Nitryl. Feels great 'til the acid eats your lungs."
	icon_state = "brown"
	gas_type = GAS_NITRYL

// Убраны из label2types (не заказываются), но оставлены для совместимости с картами (Academy, ihategordon, undergroundoutpost45)
/obj/machinery/portable_atmospherics/canister/stimulum
	name = "stimulum canister"
	desc = "Stimulum. High energy gas, high energy people."
	icon_state = "darkpurple"
	gas_type = GAS_STIMULUM

/obj/machinery/portable_atmospherics/canister/pluoxium
	name = "pluoxium canister"
	desc = "Pluoxium. Like oxygen, but more bang for your buck."
	icon_state = "darkblue"
	gas_type = GAS_PLUOXIUM

/obj/machinery/portable_atmospherics/canister/water_vapor
	name = "water vapor canister"
	desc = "Water vapor. We get it, you vape."
	icon_state = "water_vapor"
	gas_type = GAS_H2O
	filled = 1

/obj/machinery/portable_atmospherics/canister/miasma
	name = "miasma canister"
	desc = "Miasma. Makes you wish your nose were blocked."
	icon_state = "miasma"
	gas_type = GAS_MIASMA
	filled = 1

/obj/machinery/portable_atmospherics/canister/methane
	name = "methane canister"
	desc = "Methane. The simplest of hydrocarbons. Non-toxic but highly flammable."
	icon_state = "greyblackred"
	gas_type = GAS_METHANE

// Убраны из label2types (не заказываются), оставлены для совместимости с картами (undergroundoutpost45)
/obj/machinery/portable_atmospherics/canister/methyl_bromide
	name = "methyl bromide canister"
	desc = "Methyl bromide. A potent toxin to most, essential for the Kharmaan to live."
	icon_state = "purplecyan"
	gas_type = GAS_METHYL_BROMIDE

/obj/machinery/portable_atmospherics/canister/hydrogen
	name = "hydrogen canister"
	desc = "Hydrogen. Flammable and used in fusion. Ionizing radiation converts it into tritium."
	icon_state = "green"
	gas_type = GAS_HYDROGEN

/obj/machinery/portable_atmospherics/canister/helium
	name = "helium canister"
	desc = "Helium. Inert gas, byproduct of fusion."
	icon_state = "grey"
	gas_type = GAS_HELIUM

/obj/machinery/portable_atmospherics/canister/freon
	name = "freon canister"
	desc = "Freon. Coolant gas. Breathing causes burn damage and slowdown."
	icon_state = "darkblue"
	gas_type = GAS_FREON

/obj/machinery/portable_atmospherics/canister/halon
	name = "halon canister"
	desc = "Halon. Fire suppressant. Heavy slowdown and heat proof when inhaled."
	icon_state = "purple"
	gas_type = GAS_HALON

/obj/machinery/portable_atmospherics/canister/antinoblium
	name = "antinoblium canister"
	desc = "Antinoblium. Rare fuel for fusion, replicates by consuming other gases."
	icon_state = "darkpurple"
	gas_type = GAS_ANTINOBLIUM

/obj/machinery/portable_atmospherics/canister/proto_nitrate
	name = "proto nitrate canister"
	desc = "Proto nitrate. Highly reactive gas, catalyst for many reactions."
	icon_state = "brown"
	gas_type = GAS_PROTO_NITRATE

/obj/machinery/portable_atmospherics/canister/zauker
	name = "zauker canister"
	desc = "Zauker. Incredibly deadly if inhaled."
	icon_state = "black"
	gas_type = GAS_ZAUKER

/obj/machinery/portable_atmospherics/canister/healium
	name = "healium canister"
	desc = "Healium. Healing gas, stronger sleeping agent than N2O."
	icon_state = "red"
	gas_type = GAS_HEALIUM

/obj/machinery/portable_atmospherics/canister/nitrium
	name = "nitrium canister"
	desc = "Nitrium. Gaseous stimulant, enhances speed and endurance."
	icon_state = "orange"
	gas_type = GAS_NITRIUM

/obj/machinery/portable_atmospherics/canister/proc/get_time_left()
	if(timing)
		. = round(max(0, valve_timer - world.time) / 10, 1)
	else
		. = timer_set

/obj/machinery/portable_atmospherics/canister/proc/set_active()
	timing = !timing
	if(timing)
		valve_timer = world.time + (timer_set * 10)
	excite()
	update_icon()

/obj/machinery/portable_atmospherics/canister/proto
	name = "prototype canister"


/obj/machinery/portable_atmospherics/canister/proto/default
	name = "prototype canister"
	desc = "The best way to fix an atmospheric emergency... or the best way to introduce one."
	icon_state = "proto"
	volume = 5000
	max_integrity = 300
	temperature_resistance = 2000 + T0C
	can_max_release_pressure = (ONE_ATMOSPHERE * 30)
	can_min_release_pressure = (ONE_ATMOSPHERE / 30)
	prototype = TRUE

/obj/machinery/portable_atmospherics/canister/proto/default/oxygen
	name = "prototype canister"
	desc = "A prototype canister for a prototype bike, what could go wrong?"
	icon_state = "proto"
	gas_type = GAS_O2
	filled = 1
	release_pressure = ONE_ATMOSPHERE*2

/obj/machinery/portable_atmospherics/canister/New(loc, datum/gas_mixture/existing_mixture)
	..()

	if(existing_mixture)
		air_contents.copy_from(existing_mixture)
	else
		create_gas()
	update_icon()


/obj/machinery/portable_atmospherics/canister/proc/create_gas()
	if(gas_type)
		// air_contents.add_gas(gas_type)
		if(starter_temp)
			air_contents.set_temperature(starter_temp)
		if(!air_contents.return_volume())
			CRASH("Auxtools is failing somehow! Gas with pointer [air_contents._extools_pointer_gasmixture] is not valid.")
		air_contents.set_moles(gas_type,(maximum_pressure * filled) * air_contents.return_volume() / (R_IDEAL_GAS_EQUATION * air_contents.return_temperature()))

/obj/machinery/portable_atmospherics/canister/air/create_gas()
	air_contents.set_moles(GAS_O2, (O2STANDARD * maximum_pressure * filled) * air_contents.return_volume() / (R_IDEAL_GAS_EQUATION * air_contents.return_temperature()))
	air_contents.set_moles(GAS_N2, (N2STANDARD * maximum_pressure * filled) * air_contents.return_volume() / (R_IDEAL_GAS_EQUATION * air_contents.return_temperature()))

/obj/machinery/portable_atmospherics/canister/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "[icon_state]-1"

/obj/machinery/portable_atmospherics/canister/update_overlays()
	. = ..()
	if(holding)
		. += "can-open"
	if(connected_port)
		. += "can-connector"
	shown_pressure_band = pressure_band()
	switch(shown_pressure_band)
		if(4)
			. += "can-o3"
		if(3)
			. += "can-o2"
		if(2)
			. += "can-o1"
		if(1)
			. += "can-o0"

///Bucket of the pressure indicator lights on the sprite; process_atmos redraws only on change.
/obj/machinery/portable_atmospherics/canister/proc/pressure_band()
	var/pressure = air_contents?.return_pressure()
	if(pressure >= 40 * ONE_ATMOSPHERE)
		return 4
	if(pressure >= 10 * ONE_ATMOSPHERE)
		return 3
	if(pressure >= 5 * ONE_ATMOSPHERE)
		return 2
	if(pressure >= 10)
		return 1
	return 0

/obj/machinery/portable_atmospherics/canister/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > temperature_resistance)
		take_damage(5, BURN, 0)


/obj/machinery/portable_atmospherics/canister/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(!(machine_stat & BROKEN))
			canister_break()
		if(disassembled)
			new /obj/item/stack/sheet/metal (loc, 10)
		else
			new /obj/item/stack/sheet/metal (loc, 5)
	qdel(src)

/obj/machinery/portable_atmospherics/canister/welder_act(mob/living/user, obj/item/I)
	..()
	if(user.a_intent == INTENT_HARM)
		return FALSE

	if(!I.tool_start_check(user, amount=0))
		return TRUE
	var/pressure = air_contents.return_pressure()
	if(pressure > 300)
		to_chat(user, "<span class='alert'>The pressure gauge on \the [src] indicates a high pressure inside... maybe you want to reconsider?</span>")
	to_chat(user, "<span class='notice'>You begin cutting \the [src] apart...</span>")
	if(I.use_tool(src, user, 3 SECONDS, volume=50))
		to_chat(user, "<span class='notice'>You cut \the [src] apart.</span>")
		deconstruct(TRUE)
		message_admins("[src] deconstructed by [ADMIN_LOOKUPFLW(user)]")
		log_game("[src] deconstructed by [key_name(user)]")

	return TRUE

/obj/machinery/portable_atmospherics/canister/obj_break(damage_flag)
	if((machine_stat & BROKEN) || (flags_1 & NODECONSTRUCT_1))
		return
	set_machine_stat(machine_stat | BROKEN)
	canister_break()

/obj/machinery/portable_atmospherics/canister/proc/canister_break()
	disconnect()
	var/turf/T = get_turf(src)
	T.assume_air(air_contents)
	air_update_turf()

	obj_break()
	density = FALSE
	playsound(src.loc, 'sound/effects/spray.ogg', 10, TRUE, -3)
	investigate_log("was destroyed.", INVESTIGATE_ATMOS)
	update_icon_state()

	if(holding)
		holding.forceMove(T)
		holding = null

/obj/machinery/portable_atmospherics/canister/replace_tank(mob/living/user, close_valve)
	. = ..()
	if(.)
		if(close_valve)
			valve_open = FALSE
			update_icon()
			investigate_log("Valve was <b>closed</b> by [key_name(user)].<br>", INVESTIGATE_ATMOS)
		else if(valve_open && holding)
			investigate_log("[key_name(user)] started a transfer into [holding].<br>", INVESTIGATE_ATMOS)

/obj/machinery/portable_atmospherics/canister/process_atmos()
	if(machine_stat & BROKEN)
		return PROCESS_KILL
	if(timing)
		// An armed valve timer must keep ticking even when nothing else happens.
		excited = TRUE
		if(valve_timer < world.time)
			valve_open = !valve_open
			timing = FALSE
	if(valve_open)
		// An open valve watches outside pressure (breach -> resume leaking);
		// there is no wake event for that, so never sleep while open.
		excited = TRUE
		var/turf/T = get_turf(src)
		var/datum/gas_mixture/target_air = holding ? holding.air_contents : T.return_air()

		if(release_gas_to(air_contents, target_air, release_pressure) && !holding)
			air_update_turf()

	// var/our_pressure = air_contents.return_pressure()
	// var/our_temperature = air_contents.return_temperature()

	///function used to check the limit of the canisters and also set the amount of damage that the canister can receive, if the heat and pressure are way higher than the limit the more damage will be done
	// currently unused
	// if(our_temperature > heat_limit || our_pressure > pressure_limit)
	// 	take_damage(clamp((our_temperature/heat_limit) * (our_pressure/pressure_limit) * delta_time * 2, 5, 50), BURN, 0)

	// Rebuilding identical overlays every fire costs more than the whole gas
	// step; redraw only when the indicator lights actually move.
	if(pressure_band() != shown_pressure_band)
		update_icon()
	return ..()

/obj/machinery/portable_atmospherics/canister/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/portable_atmospherics/canister/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Canister", name)
		ui.open()

		var/client/client = user.client
		if (CONFIG_GET(flag/use_exp_tracking) && client && client.get_exp_living(TRUE) < 480) // Player with less than 8 hours playtime is interacting with this canister.
			if(client.next_canister_grief_warning < world.time)
				var/turf/T = get_turf(src)
				client.next_canister_grief_warning = world.time + 15 MINUTES // Wait 15 minutes before alerting admins again
				message_antigrif("New player [ADMIN_LOOKUPFLW(user)] has touched \a [src] at [ADMIN_VERBOSEJMP(T)].")
				client.touched_canister = TRUE

/obj/machinery/portable_atmospherics/canister/ui_static_data(mob/user)
	return list(
		"defaultReleasePressure" = round(CAN_DEFAULT_RELEASE_PRESSURE),
		"minReleasePressure" = round(can_min_release_pressure),
		"maxReleasePressure" = round(can_max_release_pressure),
		"pressureLimit" = round(1e14),
		"holdingTankLeakPressure" = round(TANK_LEAK_PRESSURE),
		"holdingTankFragPressure" = round(TANK_FRAGMENT_PRESSURE)
	)

/obj/machinery/portable_atmospherics/canister/ui_data()
	. = list(
		"portConnected" = !!connected_port,
		"tankPressure" = round(air_contents.return_pressure()),
		"releasePressure" = round(release_pressure),
		"valveOpen" = !!valve_open,
		"isPrototype" = !!prototype,
		"hasHoldingTank" = !!holding
	)

	if (prototype)
		. += list(
			"restricted" = restricted,
			"timing" = timing,
			"time_left" = get_time_left(),
			"timer_set" = timer_set,
			"timer_is_not_default" = timer_set != default_timer_set,
			"timer_is_not_min" = timer_set != minimum_timer_set,
			"timer_is_not_max" = timer_set != maximum_timer_set
		)

	if (holding)
		. += list(
			"holdingTank" = list(
				"name" = holding.name,
				"tankPressure" = round(holding.air_contents.return_pressure())
			)
		)

/obj/machinery/portable_atmospherics/canister/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("relabel")
			var/label = input("New canister label:", name) as null|anything in sort_list(label2types)
			if(label && !..())
				var/newtype = label2types[label]
				if(newtype)
					var/obj/machinery/portable_atmospherics/canister/replacement = newtype
					investigate_log("was relabelled to [initial(replacement.name)] by [key_name(usr)].", INVESTIGATE_ATMOS)
					name = initial(replacement.name)
					desc = initial(replacement.desc)
					icon_state = initial(replacement.icon_state)
		if("restricted")
			restricted = !restricted
			if(restricted)
				req_access = list(ACCESS_ENGINE)
			else
				req_access = list()
				. = TRUE
		if("pressure")
			var/pressure = params["pressure"]
			if(pressure == "reset")
				pressure = CAN_DEFAULT_RELEASE_PRESSURE
				. = TRUE
			else if(pressure == "min")
				pressure = can_min_release_pressure
				. = TRUE
			else if(pressure == "max")
				pressure = can_max_release_pressure
				. = TRUE
			else if(pressure == "input")
				pressure = input("New release pressure ([can_min_release_pressure]-[can_max_release_pressure] kPa):", name, release_pressure) as num|null
				if(!isnull(pressure) && !..())
					. = TRUE
			else if(text2num(pressure) != null)
				pressure = text2num(pressure)
				. = TRUE
			if(.)
				release_pressure = clamp(round(pressure), can_min_release_pressure, can_max_release_pressure)
				investigate_log("was set to [release_pressure] kPa by [key_name(usr)].", INVESTIGATE_ATMOS)
		if("valve")
			var/logmsg
			valve_open = !valve_open
			if(valve_open)
				logmsg = "Valve was <b>opened</b> by [key_name(usr)], starting a transfer into \the [holding || "air"].<br>"
				if(!holding)
					var/list/danger = list()
					for(var/id in air_contents.get_gases())
						var/gas = air_contents.get_moles(id)
						if(!(GLOB.gas_data.flags[id] & GAS_FLAG_DANGEROUS))
							continue
						if(gas > (GLOB.gas_data.visibility[id] || MOLES_GAS_VISIBLE)) //if moles_visible is undefined, default to default visibility
							danger[GLOB.gas_data.names[id]] = gas //ex. "plasma" = 20

					if(danger.len)
						message_admins("[ADMIN_LOOKUPFLW(usr)] opened a canister that contains the following at [ADMIN_VERBOSEJMP(src)]:")
						log_admin("[key_name(usr)] opened a canister that contains the following at [AREACOORD(src)]:")
						for(var/name in danger)
							var/msg = "[name]: [danger[name]] moles."
							log_admin(msg)
							message_admins(msg)
			else
				logmsg = "Valve was <b>closed</b> by [key_name(usr)], stopping the transfer into \the [holding || "air"].<br>"
			investigate_log(logmsg, INVESTIGATE_ATMOS)
			release_log += logmsg
			. = TRUE
		if("timer")
			var/change = params["change"]
			switch(change)
				if("reset")
					timer_set = default_timer_set
				if("decrease")
					timer_set = max(minimum_timer_set, timer_set - 10)
				if("increase")
					timer_set = min(maximum_timer_set, timer_set + 10)
				if("input")
					var/user_input = input(usr, "Set time to valve toggle.", name) as null|num
					if(!user_input)
						return
					var/N = text2num(user_input)
					if(!N)
						return
					timer_set = clamp(N,minimum_timer_set,maximum_timer_set)
					log_admin("[key_name(usr)] has activated a prototype valve timer")
					. = TRUE
				if("toggle_timer")
					set_active()
		if("eject")
			if(holding)
				if(valve_open)
					message_admins("[ADMIN_LOOKUPFLW(usr)] removed [holding] from [src] with valve still open at [ADMIN_VERBOSEJMP(src)] releasing contents into the [span_antigrif("AIR")].")
					investigate_log("[key_name(usr)] removed the [holding], leaving the valve open and transferring into the [span_antigrif("AIR")].", INVESTIGATE_ATMOS)
				replace_tank(usr, FALSE)
				. = TRUE
	// Any UI interaction may have opened the valve or armed the timer on a
	// sleeping canister.
	excite()
	update_icon()
