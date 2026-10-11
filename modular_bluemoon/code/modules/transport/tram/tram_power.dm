/obj/machinery/transport/power_rectifier
	name = "tram power rectifier"
	desc = "Электрический выпрямитель: превращает переменный ток в постоянный, чтобы питать трамвай."
	icon = 'modular_bluemoon/icons/obj/tram/tram_controllers.dmi'
	icon_state = "rectifier"
	idle_power_usage = 1140
	active_power_usage = 11400
	power_channel = ENVIRON
	anchored = TRUE
	density = FALSE
	armor = list(MELEE = 80, BULLET = 90, LASER = 0, ENERGY = 0, BOMB = 70, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	max_integrity = 750
	pixel_y = 32
	init_process = FALSE
	/// The tram platform we're connected to and providing power
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/connected_platform

/obj/machinery/transport/power_rectifier/LateInitialize()
	. = ..()
	RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(power_tram))
	find_platform()

/obj/machinery/transport/power_rectifier/Destroy()
	connected_platform = null
	return ..()

/// Links to the platform landmark in the same area
/obj/machinery/transport/power_rectifier/proc/find_platform()
	var/area/my_area = get_area(src)
	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/candidate_platform in SStransport.nav_beacons[configured_transport_id])
		if(get_area(candidate_platform) == my_area)
			connected_platform = candidate_platform
			RegisterSignal(connected_platform, COMSIG_PARENT_QDELETING, PROC_REF(on_landmark_qdel))
			log_transport("[id_tag]: Power rectifier linked to landmark [connected_platform.name]")
			return

/obj/machinery/transport/power_rectifier/proc/power_tram(datum/source, datum/transport_controller/linear/tram/controller, controller_active, controller_status, travel_direction, obj/effect/landmark/transport/nav_beacon/tram/destination_platform)
	SIGNAL_HANDLER

	var/new_use_power = (controller_active && destination_platform == connected_platform) ? ACTIVE_POWER_USE : IDLE_POWER_USE
	if(new_use_power == use_power)
		return
	use_power = new_use_power
	if(use_power == ACTIVE_POWER_USE && !(machine_stat & NOPOWER))
		use_power(active_power_usage)
	update_appearance()

/// Update the lights based on the rectifier status.
/obj/machinery/transport/power_rectifier/update_overlays()
	. = ..()

	if(machine_stat & NOPOWER)
		. += mutable_appearance(icon, "rec-power-0")
		. += emissive_appearance(icon, "rec-power-0", alpha = src.alpha, offset_spokesman = src)
		return

	. += mutable_appearance(icon, "rec-power-1")
	. += emissive_appearance(icon, "rec-power-1", alpha = src.alpha, offset_spokesman = src)

	var/is_active = use_power == ACTIVE_POWER_USE
	. += mutable_appearance(icon, "rec-active-[is_active]")
	. += emissive_appearance(icon, "rec-active-[is_active]", alpha = src.alpha, offset_spokesman = src)

/// Clear reference to the connected landmark if it gets destroyed.
/obj/machinery/transport/power_rectifier/proc/on_landmark_qdel(datum/source)
	SIGNAL_HANDLER
	log_transport("[id_tag]: Power rectifier received QDEL from landmark [connected_platform.name]")
	connected_platform = null
