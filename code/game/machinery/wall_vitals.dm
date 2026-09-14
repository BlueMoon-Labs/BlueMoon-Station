/obj/item/wallframe/status_display/vitals
	name = "vitals display frame"
	desc = "Used to build vitals displays. Secure on a wall nearby a stasis bed, operating table, \
		or another machine that can hold patients such as cryo cells or sleepers."
	custom_materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/gold = HALF_SHEET_MATERIAL_AMOUNT * 0.5,
	)
	result_path = /obj/machinery/vitals_reader

/obj/item/wallframe/status_display/vitals/advanced
	name = "advanced vitals display frame"
	desc = "Used to build advanced vitals displays. Performs a more detailed scan of the patient than the basic display."
	custom_materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 4,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/gold = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT * 0.5,
	)
	result_path = /obj/machinery/vitals_reader/advanced

/// A wall mounted screen that showcases the vitals of a patient nearby.
/obj/machinery/vitals_reader
	name = "vitals display"
	desc = "A screen that displays the vitals of a patient."
	icon = 'icons/obj/machines/vitals_monitor.dmi'
	icon_state = "frame"
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	density = FALSE
	layer = ABOVE_WINDOW_LAYER
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON
	use_power = NO_POWER_USE
	idle_power_usage = 5
	active_power_usage = 10
	max_integrity = 150
	payment_department = ACCOUNT_MED
	armor = list(MELEE = 30, BULLET = 20, LASER = 20, ENERGY = 30, BOMB = 10, FIRE = 50, ACID = 80)
	light_range = 1.5
	light_power = 0.75
	light_color = LIGHT_COLOR_CYAN

	/// Whether we perform an advanced scan on examine or not
	var/advanced_scan = FALSE
	/// If TRUE, also append a chemical scan to the readout
	var/chemscan_enabled = TRUE
	/// Typepath to spawn when deconstructed
	var/frame = /obj/item/wallframe/status_display/vitals
	/// Range which we can connect to machines, don't go crazy ok?
	var/connection_range = 3
	/// Static typecache of things the vitals display can connect to.
	var/static/list/connectable_typecache = typecacheof(list(
		/obj/machinery/abductor/experiment,
		/obj/machinery/atmospherics/components/unary/cryo_cell,
		/obj/machinery/dna_scannernew,
		/obj/machinery/gulag_teleporter,
		/obj/machinery/hypnochair,
		/obj/machinery/implantchair,
		/obj/machinery/sleeper,
		/obj/machinery/stasis,
		/obj/structure/table/optable,
	))
	/// The last stat we beeped about
	VAR_FINAL/last_reported_stat = null
	/// CD between beeps
	COOLDOWN_DECLARE(beep_cd)
	/// Reference to the mob that is being tracked / scanned
	VAR_FINAL/mob/living/patient
	/// What machine are we talking to
	VAR_FINAL/obj/machinery/connected

/obj/machinery/vitals_reader/advanced
	name = "advanced vitals display"
	desc = "A screen that displays the vitals of a patient. \
		Performs a more detailed scan of the patient than a basic display."
	frame = /obj/item/wallframe/status_display/vitals/advanced
	advanced_scan = TRUE

/obj/machinery/vitals_reader/Initialize(mapload)
	. = ..()
	register_context()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/vitals_reader/LateInitialize()
	. = ..()
	find_machine()
	if(is_operational)
		set_light_on(TRUE)

/obj/machinery/vitals_reader/Destroy(force)
	set_connection(null)
	set_patient(null) // unset connection also unsets patient, but just in case
	return ..()

/obj/machinery/vitals_reader/proc/comsig_unset_connected(...)
	SIGNAL_HANDLER
	set_connection(null)

/obj/machinery/vitals_reader/proc/connected_occupant_changed(datum/source, mob/living/new_patient)
	SIGNAL_HANDLER
	set_patient(new_patient)

/obj/machinery/vitals_reader/proc/connected_occupant_cleared(datum/source, mob/living/old_patient)
	SIGNAL_HANDLER
	set_patient(null)

/obj/machinery/vitals_reader/proc/connected_moved(...)
	SIGNAL_HANDLER
	if(get_dist(src, connected) > connection_range)
		set_connection(null)

/// Sets the machine as connected to this vitals reader
/// If there is already a connection, it will be unset first.
/obj/machinery/vitals_reader/proc/set_connection(obj/new_connected)
	if(connected == new_connected)
		return
	if(!isnull(connected))
		UnregisterSignal(connected, COMSIG_PARENT_QDELETING)
		UnregisterSignal(connected, list(COMSIG_MACHINERY_SET_OCCUPANT, COMSIG_MACHINE_EJECT_OCCUPANT))
		UnregisterSignal(connected, COMSIG_MOVABLE_MOVED)
		connected = null
		set_patient(null)
		use_power = NO_POWER_USE
	if(isnull(new_connected))
		return

	connected = new_connected
	RegisterSignal(connected, COMSIG_PARENT_QDELETING, PROC_REF(comsig_unset_connected))
	RegisterSignal(connected, COMSIG_MACHINERY_SET_OCCUPANT, PROC_REF(connected_occupant_changed))
	RegisterSignal(connected, COMSIG_MACHINE_EJECT_OCCUPANT, PROC_REF(connected_occupant_cleared))
	RegisterSignal(connected, COMSIG_MOVABLE_MOVED, PROC_REF(connected_moved))
	use_power = IDLE_POWER_USE

	if(ismachinery(connected))
		var/obj/machinery/connected_machine = connected
		set_patient(connected_machine.occupant)
	else if(istype(connected, /obj/structure/table/optable))
		var/obj/structure/table/optable/connected_table = connected
		set_patient(connected_table.patient)

/obj/machinery/vitals_reader/wrench_act(mob/living/user, obj/item/tool)
	balloon_alert(user, "detaching...")
	if(tool.use_tool(src, user, 6 SECONDS, volume = 50))
		playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
		deconstruct(TRUE)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/vitals_reader/multitool_act(mob/living/user, obj/item/tool)
	if(!is_operational)
		return NONE

	if(isnull(connected))
		if(find_machine())
			balloon_alert(user, "connected to [connected.name]")
		else
			balloon_alert(user, "no connectable machines nearby!")
		return TOOL_ACT_TOOLTYPE_SUCCESS

	balloon_alert(user, "disconnecting...")
	if(!do_after(user, 2 SECONDS, target = src))
		return TOOL_ACT_TOOLTYPE_SUCCESS

	balloon_alert(user, "disconnected from [connected.name]")
	set_connection(null)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/// Find and connects to a nearby machine
/obj/machinery/vitals_reader/proc/find_machine()
	for(var/obj/nearby_thing in view(connection_range, src))
		if(!is_type_in_typecache(nearby_thing, connectable_typecache))
			continue

		set_connection(nearby_thing)
		return nearby_thing
	return null

/obj/machinery/vitals_reader/deconstruct(disassembled = TRUE)
	var/atom/drop_loc = drop_location()
	if(disassembled)
		new frame(drop_loc)
	else
		new /obj/item/stack/sheet/metal(drop_loc, 2)
		new /obj/item/shard(drop_loc)
		new /obj/item/shard(drop_loc)
	qdel(src)

/obj/machinery/vitals_reader/examine(mob/user)
	. = ..()
	if(!is_operational)
		return

	if(isnull(connected))
		. += "<span class='notice'>The display is currently not connected to anything. \
			Use a [EXAMINE_HINT("multitool")] to connect it to a neighboring machine.</span>"
		return

	if(isnull(patient) || user.is_blind())
		return

	if(machine_stat & EMPED)
		. += "<span class='warning'>The display is flickering erratically!</span>"
		return

	if(!issilicon(user) && !isobserver(user) && get_dist(src, user) > 2)
		. += "<span class='notice'><i>You are too far away to read the display.</i></span>"
	else if(HAS_TRAIT(user, TRAIT_DUMB) || !user.can_read(src))
		. += "<span class='warning'>You try to comprehend the display, but it's too complex for you to understand.</span>"
	else
		healthscan(user, patient, advanced = advanced_scan)
		if(chemscan_enabled)
			chemscan(user, patient)

/obj/machinery/vitals_reader/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	if(held_item?.tool_behaviour == TOOL_WRENCH)
		context[SCREENTIP_CONTEXT_LMB] = "Detach"
		. = CONTEXTUAL_SCREENTIP_SET
	if(is_operational)
		if(isnull(connected) && held_item?.tool_behaviour == TOOL_MULTITOOL)
			context[SCREENTIP_CONTEXT_LMB] = "Connect to nearby machine"
			. = CONTEXTUAL_SCREENTIP_SET
		if(!isnull(patient))
			context[SCREENTIP_CONTEXT_SHIFT_LMB] = "Examine vitals"
			. = CONTEXTUAL_SCREENTIP_SET
	return .

#define LOWER_BAR_OFFSET -3

/**
 * Returns all overlays to be shown when a simple / basic animal patient is detected
 *
 * * hp_color - color being used for general, overrall health
 */
/obj/machinery/vitals_reader/proc/get_simple_mob_overlays(hp_color)
	return list(
		construct_overlay("mob", hp_color),
		construct_overlay("blood", COLOR_GRAY),
		construct_overlay("bar9", COLOR_GRAY),
		construct_overlay("bar9", COLOR_GRAY, LOWER_BAR_OFFSET),
	)

/**
 * Returns all overlays to be shown when a humanoid patient is detected
 *
 * * hp_color - color being used for general, overrall health
 */
/obj/machinery/vitals_reader/proc/get_humanoid_overlays(hp_color)
	var/list/returned_overlays = list()

	var/static/list/body_zones = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	for(var/body_zone in body_zones)
		var/obj/item/bodypart/real_part = patient.get_bodypart(body_zone)
		var/bodypart_color = isnull(real_part) ? COLOR_GRAY : percent_to_color((real_part.brute_dam + real_part.burn_dam) / real_part.max_damage)
		returned_overlays += construct_overlay("human_[body_zone]", bodypart_color)

	if(iscarbon(patient))
		var/blood_color = "#a51919"
		switch((patient.blood_volume - BLOOD_VOLUME_SURVIVE) / (BLOOD_VOLUME_NORMAL - BLOOD_VOLUME_SURVIVE))
			if(-INFINITY to 0.2)
				blood_color = "#a1a1a1"
			if(0.2 to 0.4)
				blood_color = "#a18282"
			if(0.4 to 0.6)
				blood_color = "#a16363"
			if(0.6 to 0.8)
				blood_color = "#a14444"
			if(0.8 to INFINITY)
				blood_color = "#a51919"

		returned_overlays += construct_overlay("blood", blood_color)
	else
		returned_overlays += construct_overlay("blood", COLOR_GRAY)

	if(HAS_TRAIT(patient, TRAIT_NOBREATH))
		returned_overlays += construct_overlay("bar9", COLOR_GRAY)
	else
		var/oxy_percent = patient.getOxyLoss() / patient.maxHealth
		returned_overlays += construct_overlay(percent_to_bar(oxy_percent), "#2A72AA")

	if(HAS_TRAIT(patient, TRAIT_TOXIMMUNE))
		returned_overlays += construct_overlay("bar9", COLOR_GRAY, LOWER_BAR_OFFSET)
	else
		var/tox_percent = patient.getToxLoss() / patient.maxHealth
		returned_overlays += construct_overlay(percent_to_bar(tox_percent), "#5d9c11", LOWER_BAR_OFFSET)

	return returned_overlays

/**
 * Returns the EKG and Respiration overlays
 *
 * * hp_color - color being used for general, overrall health
 */
/obj/machinery/vitals_reader/proc/get_ekg_and_resp(hp_color)
	var/ekg_icon_state = "ekg"
	var/resp_icon_state = "resp"
	if(patient.stat == DEAD || HAS_TRAIT(patient, TRAIT_FAKEDEATH))
		ekg_icon_state = "ekg_flat"
		resp_icon_state = "resp_flat"

	else if(patient.health <= HEALTH_THRESHOLD_CRIT)
		ekg_icon_state = "ekg_fast"

	if(patient.losebreath || HAS_TRAIT(patient, TRAIT_NOBREATH))
		resp_icon_state = "resp_flat"

	return list(
		construct_overlay(ekg_icon_state, hp_color),
		construct_overlay(resp_icon_state, "#00f7ff"),
	)

/obj/machinery/vitals_reader/update_overlays()
	. = ..()
	if(!is_operational)
		return

	. += emissive_appearance(icon, "outline", src, alpha = src.alpha)
	if(isnull(patient))
		return

	. += "buttons"

	var/hp_color = percent_to_color((patient.maxHealth - patient.health) / patient.maxHealth)
	. += get_ekg_and_resp(hp_color)
	if(ishuman(patient))
		. += get_humanoid_overlays(hp_color)
	else
		. += get_simple_mob_overlays(hp_color)

/// Converts a percentage to a color
/obj/machinery/vitals_reader/proc/percent_to_color(percent)
	if(machine_stat & EMPED)
		percent = rand(1, 100) * 0.01

	if(percent == 0)
		return "#2A72AA"

	switch(percent)
		if(0 to 0.125)
			return "#A6BD00"
		if(0.125 to 0.25)
			return "#BDA600"
		if(0.25 to 0.375)
			return "#BD7E00"
		if(0.375 to 0.5)
			return "#BD4200"

	return "#BD0600"

/// Converts a percentage to a bar icon state
/obj/machinery/vitals_reader/proc/percent_to_bar(percent)
	if(machine_stat & EMPED)
		percent = rand(1, 100) * 0.01

	if(percent >= 1)
		return "bar9"
	if(percent <= 0)
		return "bar1"

	switch(percent)
		if(0 to 0.125)
			return "bar1"
		if(0.125 to 0.25)
			return "bar2"
		if(0.25 to 0.375)
			return "bar3"
		if(0.375 to 0.5)
			return "bar4"
		if(0.5 to 0.625)
			return "bar5"
		if(0.625 to 0.75)
			return "bar6"
		if(0.75 to 0.875)
			return "bar7"
		if(0.875 to 1)
			return "bar8"

	return "bar9" // ??

/**
 * Helper to construct an overlay for the vitals display
 *
 * * state_to_use - icon state to use, required
 * * color_to_use - color to use, optional
 * * y_offset - offset to apply to the y position of the overlay, defaults to 0
 */
/obj/machinery/vitals_reader/proc/construct_overlay(state_to_use, color_to_use, y_offset = 0)
	var/mutable_appearance/overlay = mutable_appearance(icon, state_to_use, alpha = src.alpha)
	overlay.appearance_flags |= RESET_COLOR
	overlay.color = color_to_use
	overlay.pixel_z += 32
	overlay.pixel_y += -32 + y_offset
	return overlay

#undef LOWER_BAR_OFFSET

/obj/machinery/vitals_reader/on_set_is_operational(old_value)
	update_appearance()
	set_light_on(is_operational)

/obj/machinery/vitals_reader/process()
	if(isnull(patient))
		return PROCESS_KILL

	if(!COOLDOWN_FINISHED(src, beep_cd) || !is_operational)
		return

	var/patient_stat = patient.stat
	if(machine_stat & EMPED)
		patient_stat = pick(CONSCIOUS, SOFT_CRIT, DEAD, DEAD, DEAD)

	switch(patient_stat)
		if(DEAD)
			COOLDOWN_START(src, beep_cd, 11 SECONDS)
			if(last_reported_stat != DEAD)
				beep_message("lets out a droning beep.")
				last_reported_stat = DEAD
		if(SOFT_CRIT)
			COOLDOWN_START(src, beep_cd, 5 SECONDS)
			if(last_reported_stat != SOFT_CRIT)
				beep_message("lets out an alternating beep.")
				last_reported_stat = SOFT_CRIT
		if(UNCONSCIOUS)
			COOLDOWN_START(src, beep_cd, 7 SECONDS)
			if(last_reported_stat != UNCONSCIOUS)
				beep_message("lets out a high pitch beep.")
				last_reported_stat = UNCONSCIOUS
		else
			COOLDOWN_START(src, beep_cd, 7 SECONDS)
			if(last_reported_stat != CONSCIOUS)
				beep_message("lets out a beep.")
				last_reported_stat = CONSCIOUS

/obj/machinery/vitals_reader/proc/beep_message(message)
	for(var/mob/viewer as anything in viewers(src))
		if(isnull(viewer.client) || HAS_TRAIT(viewer, TRAIT_DEAF))
			continue
		viewer.create_chat_message(src, null, message, list("emote", "italics"), null)

/// Sets the passed mob as the active patient
/// If there is already a patient, it will be unset first.
/obj/machinery/vitals_reader/proc/set_patient(mob/living/new_patient)
	if(patient == new_patient)
		return
	if(!isnull(patient))
		UnregisterSignal(patient, list(
			COMSIG_PARENT_QDELETING,
			COMSIG_CARBON_REMOVE_LIMB,
			COMSIG_CARBON_ATTACH_LIMB,
			COMSIG_CARBON_UPDATEHEALTH,
		))

		patient = null
		STOP_PROCESSING(SSmachines, src)
		if(!QDELING(src))
			use_power = IDLE_POWER_USE
			update_appearance()
	if(isnull(new_patient))
		return
	if(QDELING(src))
		CRASH("[src] is qdeleting but tried to set a new patient ([new_patient])!")

	patient = new_patient
	RegisterSignal(patient, COMSIG_PARENT_QDELETING, PROC_REF(comsig_unset_patient))
	RegisterSignals(patient, list(
		COMSIG_CARBON_REMOVE_LIMB,
		COMSIG_CARBON_ATTACH_LIMB,
		COMSIG_CARBON_UPDATEHEALTH,
	), PROC_REF(update_overlay_on_signal))
	update_appearance()
	START_PROCESSING(SSmachines, src)
	use_power = ACTIVE_POWER_USE
	last_reported_stat = null

/obj/machinery/vitals_reader/proc/comsig_unset_patient(...)
	SIGNAL_HANDLER
	set_patient(null)

/// Signal proc to update the display when a signal is received.
/obj/machinery/vitals_reader/proc/update_overlay_on_signal(...)
	SIGNAL_HANDLER
	update_appearance()

/obj/machinery/vitals_reader/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return

	var/high_severity = severity >= 80
	COOLDOWN_START(src, beep_cd, 1 SECONDS * rand(10, (high_severity ? 120 : 60)))
	set_machine_stat(machine_stat | EMPED)
	addtimer(CALLBACK(src, PROC_REF(fix_emp)), (high_severity ? 150 SECONDS : 75 SECONDS), TIMER_DELETE_ME)

/obj/machinery/vitals_reader/proc/fix_emp()
	set_machine_stat(machine_stat & ~EMPED)

/obj/machinery/vitals_reader/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(machine_stat & BROKEN)
				playsound(src, 'sound/effects/hit_on_shattered_glass.ogg', 70, TRUE)
			else
				playsound(src, 'sound/effects/glasshit.ogg', 75, TRUE)
		if(BURN)
			playsound(src, 'sound/items/welder.ogg', 100, TRUE)

// Directional variants for mapping. Defined manually because the
// MAPPING_DIRECTIONAL_HELPERS macro lives in lighting.dm, which is compiled
// after this file (see the comment in status_display.dm).
/obj/machinery/vitals_reader/directional/north
	dir = NORTH
	pixel_y = 32

/obj/machinery/vitals_reader/directional/south
	dir = SOUTH
	pixel_y = -32

/obj/machinery/vitals_reader/directional/east
	dir = EAST
	pixel_x = 32

/obj/machinery/vitals_reader/directional/west
	dir = WEST
	pixel_x = -32

/obj/machinery/vitals_reader/advanced/directional/north
	dir = NORTH
	pixel_y = 32

/obj/machinery/vitals_reader/advanced/directional/south
	dir = SOUTH
	pixel_y = -32

/obj/machinery/vitals_reader/advanced/directional/east
	dir = EAST
	pixel_x = 32

/obj/machinery/vitals_reader/advanced/directional/west
	dir = WEST
	pixel_x = -32
