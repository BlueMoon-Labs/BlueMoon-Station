/**
 * HFR procs: build, destroy, control. BlueMoon: gas IDs, get_moles/set_moles.
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_part_connectivity()
	. = TRUE
	if(!anchored || panel_open)
		return FALSE
	corners.Cut()
	machine_parts.Cut()

	for(var/obj/machinery/hypertorus/object in orange(1,src))
		if(. == FALSE)
			break
		if(object.panel_open)
			. = FALSE
		if(istype(object,/obj/machinery/hypertorus/corner))
			var/dir = get_dir(src,object)
			if(dir in GLOB.cardinals)
				. = FALSE
			switch(dir)
				if(SOUTHEAST)
					if(object.dir != SOUTH)
						. = FALSE
				if(SOUTHWEST)
					if(object.dir != WEST)
						. = FALSE
				if(NORTHEAST)
					if(object.dir != EAST)
						. = FALSE
				if(NORTHWEST)
					if(object.dir != NORTH)
						. = FALSE
			corners |= object
			continue
		if(get_step(object,REVERSE_DIR(object.dir)) != loc)
			. = FALSE
		if(istype(object,/obj/machinery/hypertorus/interface))
			if(linked_interface && linked_interface != object)
				. = FALSE
			linked_interface = object

	for(var/obj/machinery/atmospherics/components/unary/hypertorus/object in orange(1,src))
		if(. == FALSE)
			break
		if(object.panel_open)
			. = FALSE
		if(get_step(object,REVERSE_DIR(object.dir)) != loc)
			. = FALSE
		if(istype(object,/obj/machinery/atmospherics/components/unary/hypertorus/fuel_input))
			if(linked_input && linked_input != object)
				. = FALSE
			linked_input = object
			machine_parts |= object
		if(istype(object,/obj/machinery/atmospherics/components/unary/hypertorus/waste_output))
			if(linked_output && linked_output != object)
				. = FALSE
			linked_output = object
			machine_parts |= object
		if(istype(object,/obj/machinery/atmospherics/components/unary/hypertorus/moderator_input))
			if(linked_moderator && linked_moderator != object)
				. = FALSE
			linked_moderator = object
			machine_parts |= object

	if(!linked_interface || !linked_input || !linked_moderator || !linked_output || corners.len != 4)
		. = FALSE

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/register_part_deletion_signal(atom/part)
	if(!part)
		return
	UnregisterSignal(part, COMSIG_PARENT_QDELETING)
	RegisterSignal(part, COMSIG_PARENT_QDELETING, PROC_REF(unregister_signals), override = TRUE)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/activate(mob/living/user)
	if(active)
		to_chat(user, span_notice("You already activated the machine."))
		return
	if(!check_part_connectivity())
		to_chat(user, span_notice("Check all parts and then try again."))
		return
	active = TRUE
	unregister_signals(TRUE)
	to_chat(user, span_notice("You link all parts together."))
	update_appearance(UPDATE_ICON)
	linked_interface.active = TRUE
	linked_interface.update_appearance(UPDATE_ICON)
	register_part_deletion_signal(linked_interface)
	linked_input.active = TRUE
	linked_input.update_appearance(UPDATE_ICON)
	register_part_deletion_signal(linked_input)
	linked_output.active = TRUE
	linked_output.update_appearance(UPDATE_ICON)
	register_part_deletion_signal(linked_output)
	linked_moderator.active = TRUE
	linked_moderator.update_appearance(UPDATE_ICON)
	register_part_deletion_signal(linked_moderator)
	for(var/obj/machinery/hypertorus/corner/corner in corners)
		corner.active = TRUE
		corner.update_appearance(UPDATE_ICON)
		register_part_deletion_signal(corner)
	soundloop = new(src, TRUE)
	soundloop.volume = 5
	connect_atmos_ports()

/// Reconnects I/O ports and the core cooling loop to adjacent pipenets after assembly or re-activation.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/connect_atmos_ports()
	if(!SSair.initialized)
		return
	reconnect_nodes()
	if(linked_input)
		linked_input.reconnect_nodes()
	if(linked_moderator)
		linked_moderator.reconnect_nodes()
	if(linked_output)
		linked_output.reconnect_nodes()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/unregister_signals(only_signals = FALSE)
	SIGNAL_HANDLER
	if(linked_interface)
		UnregisterSignal(linked_interface, COMSIG_PARENT_QDELETING)
	if(linked_input)
		UnregisterSignal(linked_input, COMSIG_PARENT_QDELETING)
	if(linked_output)
		UnregisterSignal(linked_output, COMSIG_PARENT_QDELETING)
	if(linked_moderator)
		UnregisterSignal(linked_moderator, COMSIG_PARENT_QDELETING)
	for(var/obj/machinery/hypertorus/corner/corner in corners)
		UnregisterSignal(corner, COMSIG_PARENT_QDELETING)
	if(!only_signals)
		deactivate()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/deactivate()
	if(!active)
		return
	unregister_signals(TRUE)
	active = FALSE
	update_appearance(UPDATE_ICON)
	if(linked_interface)
		linked_interface.active = FALSE
		linked_interface.update_appearance(UPDATE_ICON)
		linked_interface = null
	if(linked_input)
		linked_input.active = FALSE
		linked_input.update_appearance(UPDATE_ICON)
		linked_input = null
	if(linked_output)
		linked_output.active = FALSE
		linked_output.update_appearance(UPDATE_ICON)
		linked_output = null
	if(linked_moderator)
		linked_moderator.active = FALSE
		linked_moderator.update_appearance(UPDATE_ICON)
		linked_moderator = null
	if(corners.len)
		for(var/obj/machinery/hypertorus/corner/corner in corners)
			corner.active = FALSE
			corner.update_appearance(UPDATE_ICON)
		corners = list()
	QDEL_NULL(soundloop)

/// Removed: was iterating GLOB.gas_data.ids every tick and doing set_moles(get_moles(...)) — no-op and major perf sink. get_moles() already returns 0 for missing gases.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/assert_gases()
	return

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/update_pipenets()
	update_parents()
	linked_input.update_parents()
	linked_output.update_parents()
	linked_moderator.update_parents()

/// Обновляет архивные темпы и выставляет power_level по температуре fusion (диапазоны 500, 1e3, 1e4, ... до 6).
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/update_temperature_status(seconds_per_tick)
	fusion_temperature_archived = fusion_temperature
	fusion_temperature = internal_fusion.return_temperature()
	moderator_temperature_archived = moderator_temperature
	moderator_temperature = moderator_internal.return_temperature()
	coolant_temperature_archived = coolant_temperature
	coolant_temperature = airs[1].return_temperature()
	output_temperature_archived = output_temperature
	output_temperature = linked_output.airs[1].return_temperature()
	temperature_period = seconds_per_tick
	switch(fusion_temperature)
		if(-INFINITY to 500)
			power_level = 0
		if(500 to 1e3)
			power_level = 1
		if(1e3 to 1e4)
			power_level = 2
		if(1e4 to 1e5)
			power_level = 3
		if(1e5 to 1e6)
			power_level = 4
		if(1e6 to 1e7)
			power_level = 5
		else
			power_level = 6

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/play_ambience(seconds_per_tick)
	if(last_accent_sound < world.time && SPT_PROB(10, seconds_per_tick))
		var/aggression = min(((critical_threshold_proximity / 800) * ((power_level) / 5)), 1.0) * 100
		if(critical_threshold_proximity >= 300)
			playsound(src, SFX_HYPERTORUS_MELTING, max(50, aggression), FALSE, 40, 30, falloff_distance = 10)
		else
			playsound(src, SFX_HYPERTORUS_CALM, max(50, aggression), FALSE, 25, 25, falloff_distance = 10)
		var/next_sound = round((100 - aggression) * 5) + 5
		last_accent_sound = world.time + max(HYPERTORUS_ACCENT_SOUND_MIN_COOLDOWN, next_sound)
	var/ambient_hum = 1
	if(check_fuel())
		ambient_hum = power_level + 1
	soundloop.volume = clamp(ambient_hum * 8, 0, 50)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_fuel()
	if(!selected_fuel)
		return FALSE
	if(!internal_fusion.total_moles())
		return FALSE
	for(var/gas_id in selected_fuel.requirements)
		if(internal_fusion.get_moles(gas_id) < HFR_FUSION_MOLE_THRESHOLD)
			return FALSE
	return TRUE

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_power_use()
	if(machine_stat & (NOPOWER|BROKEN))
		return FALSE
	if(use_power == ACTIVE_POWER_USE)
		use_power = ACTIVE_POWER_USE
		active_power_usage = (power_level + 1) * MIN_POWER_USAGE
	return TRUE

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_gas_requirements()
	var/datum/gas_mixture/contents = linked_input.airs[1]
	for(var/gas_id in selected_fuel.requirements)
		if(contents.get_moles(gas_id) <= 0)
			return FALSE
	return TRUE

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/dump_gases()
	var/datum/gas_mixture/remove = internal_fusion.remove(internal_fusion.total_moles())
	if(remove)
		linked_output.airs[1].merge(remove)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/get_status()
	var/integrity = get_integrity_percent()
	if(integrity < HYPERTORUS_MELTING_PERCENT)
		return HYPERTORUS_MELTING
	if(integrity < HYPERTORUS_EMERGENCY_PERCENT)
		return HYPERTORUS_EMERGENCY
	if(integrity < HYPERTORUS_DANGER_PERCENT)
		return HYPERTORUS_DANGER
	if(integrity < HYPERTORUS_WARNING_PERCENT)
		return HYPERTORUS_WARNING
	if(power_level > 0)
		return HYPERTORUS_NOMINAL
	return HYPERTORUS_INACTIVE

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/alarm()
	switch(get_status())
		if(HYPERTORUS_MELTING)
			playsound(src, 'sound/misc/bloblarm.ogg', 100, FALSE, 40, 30, falloff_distance = 10)
		if(HYPERTORUS_EMERGENCY)
			playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
		if(HYPERTORUS_DANGER)
			playsound(src, 'sound/machines/engine_alert2.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
		if(HYPERTORUS_WARNING)
			playsound(src, 'sound/machines/terminal_alert.ogg', 75)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/get_integrity_percent()
	var/integrity = critical_threshold_proximity / melting_point
	integrity = round(100 - integrity * 100, 0.01)
	integrity = integrity < 0 ? 0 : integrity
	return integrity

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/get_area_cell_percent()
	var/area/area = get_area(src)
	if(!area)
		return 0
	var/obj/machinery/power/apc/apc = area.get_apc()
	if(!apc)
		return 0
	var/obj/item/stock_parts/cell/cell = apc.cell
	if(!cell)
		return 0
	return cell.percent()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_alert()
	if(critical_threshold_proximity < warning_point)
		return
	if((REALTIMEOFDAY - lastwarning) / 10 >= WARNING_TIME_DELAY)
		alarm()
		if(critical_threshold_proximity > emergency_point)
			radio.talk_into(src, "[emergency_alert] Integrity: [get_integrity_percent()]%", common_channel)
			lastwarning = REALTIMEOFDAY
			if(!has_reached_emergency)
				investigate_log("has reached the emergency point for the first time.", INVESTIGATE_HYPERTORUS)
				message_admins("[src] has reached the emergency point [ADMIN_JMP(src)].")
				has_reached_emergency = TRUE
			send_radio_explanation()
		else if(critical_threshold_proximity >= critical_threshold_proximity_archived)
			radio.talk_into(src, "[warning_alert] Integrity: [get_integrity_percent()]%", engineering_channel)
			lastwarning = REALTIMEOFDAY - (WARNING_TIME_DELAY * 5)
			send_radio_explanation()
		else
			radio.talk_into(src, "[safe_alert] Integrity: [get_integrity_percent()]%", engineering_channel)
			lastwarning = REALTIMEOFDAY
	if(critical_threshold_proximity >= melting_point)
		countdown()

/obj/machinery/atmospherics/components/unary/hypertorus/core/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	warning_damage_flags |= HYPERTORUS_FLAG_EMPED

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/send_radio_explanation()
	if(warning_damage_flags & HYPERTORUS_FLAG_EMPED)
		var/list/characters = list()
		characters += GLOB.alphabet
		for(var/c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
			characters += c
		for(var/c in "0123456789")
			characters += c
		characters += " "
		characters += " "
		var/message = random_string(rand(50,70), characters)
		radio.talk_into(src, "[message]", engineering_channel)
		return
	if(warning_damage_flags & HYPERTORUS_FLAG_HIGH_POWER_DAMAGE)
		radio.talk_into(src, "Warning! Shield destabilizing due to excessive power!", engineering_channel)
	if(warning_damage_flags & HYPERTORUS_FLAG_IRON_CONTENT_DAMAGE)
		radio.talk_into(src, "Warning! Iron shards are damaging the internal core shielding!", engineering_channel)
	if(warning_damage_flags & HYPERTORUS_FLAG_HIGH_FUEL_MIX_MOLE)
		radio.talk_into(src, "Warning! Fuel mix moles reaching critical levels!", engineering_channel)
	if(warning_damage_flags & HYPERTORUS_FLAG_IRON_CONTENT_INCREASE)
		radio.talk_into(src, "Warning! Iron amount inside the core is increasing!", engineering_channel)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/countdown()
	set waitfor = FALSE
	if(QDELETED(src) || final_countdown)
		return
	final_countdown = TRUE
	if(!selected_fuel)
		final_countdown = FALSE
		return
	var/critical = selected_fuel.meltdown_flags & HYPERTORUS_FLAG_CRITICAL_MELTDOWN
	if(critical)
		priority_announce("ВНИМАНИЕ! Взрыв ХФР, скорее всего, охватит большую часть станции, а грядущий ЭМИ уничтожит большую часть электроники. \
				Отойдите как можно дальше от реактора или найдите способ его остановить от расщепления.", "ВНИМАНИЕ", 'sound/announcer/notice/notice3.ogg')
	var/speaking = "[emergency_alert] The Hypertorus fusion reactor has reached critical integrity failure. Emergency magnetic dampeners online."
	radio.talk_into(src, speaking, common_channel)
	notify_ghosts("The [src] has begun melting down!", 'sound/machines/warning-buzzer.ogg', FALSE, src, header = "Meltdown Incoming")
	for(var/i in HYPERTORUS_COUNTDOWN_TIME to 0 step -10)
		if(QDELETED(src))
			return
		if(critical_threshold_proximity < melting_point)
			radio.talk_into(src, "[safe_alert] Failsafe has been disengaged.", common_channel)
			final_countdown = FALSE
			return
		else if((i % 50) != 0 && i > 50)
			sleep(1 SECONDS)
			continue
		else if(i > 50)
			if(i == 10 SECONDS && critical)
				sound_to_playing_players('sound/machines/warning-buzzer.ogg')
			speaking = "[DisplayTimeText(i, TRUE)] remain before total integrity failure."
		else
			speaking = "[i*0.1]..."
		radio.talk_into(src, speaking, common_channel)
		sleep(1 SECONDS)
	if(QDELETED(src))
		return
	meltdown()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/meltdown()
	var/flash_explosion = 0
	var/light_impact_explosion = 0
	var/heavy_impact_explosion = 0
	var/devastating_explosion = 0
	var/em_pulse = selected_fuel.meltdown_flags & HYPERTORUS_FLAG_EMP
	var/rad_pulse = selected_fuel.meltdown_flags & HYPERTORUS_FLAG_RADIATION_PULSE
	var/emp_heavy_size = 0
	var/rad_pulse_size = 0
	var/gas_spread = 0
	var/gas_pockets = 0
	var/critical = selected_fuel.meltdown_flags & HYPERTORUS_FLAG_CRITICAL_MELTDOWN
	if(selected_fuel.meltdown_flags & HYPERTORUS_FLAG_BASE_EXPLOSION)
		flash_explosion = power_level * 3
		light_impact_explosion = power_level * 2
	if(selected_fuel.meltdown_flags & HYPERTORUS_FLAG_MEDIUM_EXPLOSION)
		flash_explosion = power_level * 6
		light_impact_explosion = power_level * 5
		heavy_impact_explosion = power_level * 0.5
	if(selected_fuel.meltdown_flags & HYPERTORUS_FLAG_DEVASTATING_EXPLOSION)
		flash_explosion = power_level * 8
		light_impact_explosion = power_level * 7
		heavy_impact_explosion = power_level * 2
		devastating_explosion = power_level
	if(selected_fuel.meltdown_flags & HYPERTORUS_FLAG_MINIMUM_SPREAD)
		if(em_pulse)
			emp_heavy_size = power_level * 1
		if(rad_pulse)
			rad_pulse_size = 2 * power_level + 8
		gas_pockets = 5
		gas_spread = power_level * 2
	if(selected_fuel.meltdown_flags & HYPERTORUS_FLAG_MEDIUM_SPREAD)
		if(em_pulse)
			emp_heavy_size = power_level * 3
		if(rad_pulse)
			rad_pulse_size = power_level + 24
		gas_pockets = 7
		gas_spread = power_level * 4
	if(selected_fuel.meltdown_flags & HYPERTORUS_FLAG_BIG_SPREAD)
		if(em_pulse)
			emp_heavy_size = power_level * 5
		if(rad_pulse)
			rad_pulse_size = power_level + 34
		gas_pockets = 10
		gas_spread = power_level * 6
	if(selected_fuel.meltdown_flags & HYPERTORUS_FLAG_MASSIVE_SPREAD)
		if(em_pulse)
			emp_heavy_size = power_level * 7
		if(rad_pulse)
			rad_pulse_size = power_level + 44
		gas_pockets = 15
		gas_spread = power_level * 8
	var/list/around_turfs = spiral_range_turfs(gas_spread, src)
	var/list/turfs_to_remove = list()
	for(var/turf/turf as anything in around_turfs)
		if(isclosedturf(turf) || isspaceturf(turf))
			turfs_to_remove += turf
	around_turfs -= turfs_to_remove
	var/turf/core_turf = get_turf(src)
	var/datum/gas_mixture/remove_fusion
	if(internal_fusion.total_moles() > 0)
		remove_fusion = internal_fusion.remove_ratio(0.2)
		var/datum/gas_mixture/remove
		for(var/i in 1 to gas_pockets)
			remove = remove_fusion.remove_ratio(1/gas_pockets)
			var/turf/local = length(around_turfs) ? pick(around_turfs) : core_turf
			if(local)
				local.assume_air(remove)
		if(core_turf)
			core_turf.assume_air(internal_fusion)
	var/datum/gas_mixture/remove_moderator
	if(moderator_internal.total_moles() > 0)
		remove_moderator = moderator_internal.remove_ratio(0.2)
		var/datum/gas_mixture/remove
		for(var/i in 1 to gas_pockets)
			remove = remove_moderator.remove_ratio(1/gas_pockets)
			var/turf/local = length(around_turfs) ? pick(around_turfs) : core_turf
			if(local)
				local.assume_air(remove)
		if(core_turf)
			core_turf.assume_air(moderator_internal)
	explosion(loc, critical ? devastating_explosion * 2 : devastating_explosion, critical ? heavy_impact_explosion * 2 : heavy_impact_explosion, light_impact_explosion, flash_explosion, TRUE, TRUE)
	if(rad_pulse)
		radiation_pulse(src, 3000, rad_pulse_size, TRUE)
	if(em_pulse)
		empulse_using_range(loc, critical ? emp_heavy_size * 2 : emp_heavy_size, TRUE)
	qdel(src)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_cracked_parts()
	for(var/obj/machinery/atmospherics/components/unary/hypertorus/part in machine_parts)
		if(part.cracked)
			return part

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/create_crack() as /obj/machinery/atmospherics/components/unary/hypertorus
	var/obj/machinery/atmospherics/components/unary/hypertorus/part = pick(machine_parts)
	part.cracked = TRUE
	part.update_appearance(UPDATE_ICON)
	return part

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/spill_gases(obj/origin, datum/gas_mixture/target_mix, ratio)
	var/datum/gas_mixture/remove_mixture = target_mix.remove_ratio(ratio)
	var/turf/origin_turf = origin.loc
	if(!origin_turf)
		return
	origin_turf.assume_air(remove_mixture)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/process_moderator_overflow(seconds_per_tick)
	var/obj/machinery/atmospherics/components/unary/hypertorus/cracked_part = check_cracked_parts()
	if(cracked_part)
		var/leak_rate
		if(moderator_internal.return_pressure() < HYPERTORUS_MEDIUM_SPILL_PRESSURE)
			if(!prob(HYPERTORUS_WEAK_SPILL_CHANCE))
				return
			leak_rate = HYPERTORUS_WEAK_SPILL_RATE
		else if(moderator_internal.return_pressure() < HYPERTORUS_STRONG_SPILL_PRESSURE)
			leak_rate = HYPERTORUS_MEDIUM_SPILL_RATE
		else
			leak_rate = HYPERTORUS_STRONG_SPILL_RATE
		spill_gases(cracked_part, moderator_internal, ratio = 1 - (1 - leak_rate) ** seconds_per_tick)
		return
	if(moderator_internal.total_moles() < HYPERTORUS_HYPERCRITICAL_MOLES)
		return
	cracked_part = create_crack()
	if(moderator_internal.return_pressure() < HYPERTORUS_MEDIUM_SPILL_PRESSURE)
		return
	if(moderator_internal.return_pressure() < HYPERTORUS_STRONG_SPILL_PRESSURE)
		explosion(get_turf(cracked_part), 0, 0, 1, 3, TRUE, FALSE, 3)
		spill_gases(cracked_part, moderator_internal, ratio = HYPERTORUS_MEDIUM_SPILL_INITIAL)
		return
	explosion(get_turf(cracked_part), 0, 1, 3, 5, TRUE, FALSE, 5)
	spill_gases(cracked_part, moderator_internal, ratio = HYPERTORUS_STRONG_SPILL_INITIAL)
