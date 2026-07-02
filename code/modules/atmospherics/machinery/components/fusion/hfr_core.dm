/**
 * HFR core - variables, Initialize(), Destroy()
 * BlueMoon: uses gas ID strings and get_moles/set_moles
 */
/obj/machinery/atmospherics/components/unary/hypertorus/core
	name = "HFR core"
	desc = "This is the Hypertorus Fusion Reactor core, an advanced piece of technology to finely tune the reaction inside of the machine. It has I/O for cooling gases."
	icon = 'icons/obj/machines/atmospherics/hypertorus.dmi'
	icon_state = "core_off"
	circuit = /obj/item/circuitboard/machine/HFR_core
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	icon_state_open = "core_open"
	icon_state_off = "core_off"
	icon_state_active = "core_active"

	var/start_power = FALSE
	var/start_cooling = FALSE
	var/start_fuel = FALSE
	var/start_moderator = FALSE

	var/obj/machinery/hypertorus/interface/linked_interface
	var/obj/machinery/atmospherics/components/unary/hypertorus/moderator_input/linked_moderator
	var/obj/machinery/atmospherics/components/unary/hypertorus/fuel_input/linked_input
	var/obj/machinery/atmospherics/components/unary/hypertorus/waste_output/linked_output
	var/list/corners = list()
	var/list/machine_parts = list()
	var/datum/gas_mixture/internal_fusion
	var/datum/gas_mixture/moderator_internal
	var/list/moderator_scrubbing = list(GAS_HELIUM)
	var/moderator_filtering_rate = 20
	var/fusion_filtering_rate = 20 /// Legacy; no longer used for waste removal
	var/datum/hfr_fuel/selected_fuel

	var/energy = 0
	var/core_temperature = T20C
	var/internal_power = 0
	var/power_output = 0
	var/instability = 0
	var/delta_temperature = 0
	var/conduction = 0
	var/radiation = 0
	var/efficiency = 0
	var/heat_limiter_modifier = 0
	var/heat_output_max = 0
	var/heat_output_min = 0
	var/heat_output = 0

	var/waste_remove = FALSE
	var/heating_conductor = 100
	var/magnetic_constrictor = 100
	var/current_damper = 0
	var/power_level = 0
	var/iron_content = 0
	var/fuel_injection_rate = 25
	var/moderator_injection_rate = 25

	var/critical_threshold_proximity = 0
	var/critical_threshold_proximity_archived = 0
	var/safe_alert = "Main containment field returning to safe operating parameters."
	var/warning_point = 50
	var/warning_alert = "Danger! Magnetic containment field faltering!"
	var/emergency_point = 700
	var/emergency_alert = "HYPERTORUS MELTDOWN IMMINENT."
	var/melting_point = 900
	var/has_reached_emergency = FALSE
	var/lastwarning = 0

	var/obj/item/radio/radio
	var/radio_key = /obj/item/encryptionkey/headset_eng
	var/engineering_channel = "Engineering"
	var/common_channel = null

	var/datum/looping_sound/hypertorus/soundloop
	var/last_accent_sound = 0

	var/fusion_temperature_archived = 0
	var/fusion_temperature = 0
	var/moderator_temperature_archived = 0
	var/moderator_temperature = 0
	var/coolant_temperature_archived = 0
	var/coolant_temperature = 0
	var/output_temperature_archived = 0
	var/output_temperature = 0
	var/temperature_period = 1
	var/final_countdown = FALSE

	var/warning_damage_flags = NONE
	/// Last world.time when overmole (5000+) integrity damage was applied
	var/last_overmole_damage = 0

	/// Cached lists reused every process_atmos to avoid allocations (fusion_process)
	var/list/hfr_fuel_list = list()
	var/list/hfr_scaled_fuel_list = list()
	var/list/hfr_moderator_list = list()
	var/list/hfr_scaled_moderator_list = list()
	/// Reused gas_mixture for output each tick instead of new
	var/datum/gas_mixture/hfr_internal_output
	/// Reused for remove_specific in remove_waste and inject_fuel to avoid 10+ allocations per tick
	var/datum/gas_mixture/hfr_removed_waste

/obj/machinery/atmospherics/components/unary/hypertorus/core/Initialize(mapload)
	. = ..()
	internal_fusion = new(5000)
	moderator_internal = new(10000)
	hfr_internal_output = new
	hfr_removed_waste = new

	radio = new(src)
	radio.keyslot = new radio_key
	radio.recalculateChannels()
	investigate_log("has been created.", INVESTIGATE_HYPERTORUS)

/obj/machinery/atmospherics/components/unary/hypertorus/core/Destroy()
	unregister_signals(TRUE)
	if(internal_fusion)
		internal_fusion = null
	if(moderator_internal)
		moderator_internal = null
	if(linked_input)
		QDEL_NULL(linked_input)
	if(linked_output)
		QDEL_NULL(linked_output)
	if(linked_moderator)
		QDEL_NULL(linked_moderator)
	if(linked_interface)
		QDEL_NULL(linked_interface)
	var/list/corners_to_del = corners.Copy()
	for(var/obj/machinery/hypertorus/corner/corner in corners_to_del)
		QDEL_NULL(corner)
	QDEL_NULL(radio)
	QDEL_NULL(soundloop)
	machine_parts = null
	return ..()

/obj/machinery/atmospherics/components/unary/hypertorus/core/on_deconstruction(disassembled)
	var/turf/local_turf = get_turf(loc)
	var/datum/gas_mixture/to_release = moderator_internal || internal_fusion
	if(to_release == moderator_internal && internal_fusion)
		to_release.merge(internal_fusion)
	if(to_release && to_release.total_moles() > 0)
		local_turf.assume_air(to_release)

/obj/machinery/atmospherics/components/unary/hypertorus/core/crowbar_deconstruction_act(mob/living/user, obj/item/tool, internal_pressure = 0)
	if(internal_fusion)
		internal_pressure = max(internal_pressure, internal_fusion.return_pressure())
	if(moderator_internal)
		internal_pressure = max(internal_pressure, moderator_internal.return_pressure())
	if(internal_pressure > 0)
		say("WARNING - Core can contain hazardous gases, deconstruct with caution!")
	return ..(user, tool, internal_pressure)
