#define NORMAL_TOAST_PROB 3
#define BROKEN_TOAST_PROB 33

/// Makes the floor under a tram line zap people who step on it while the tram is approaching
/datum/component/energized
	can_transfer = FALSE
	/// Inbound station
	var/inbound
	/// Outbound station
	var/outbound
	/// Transport ID of the tram
	var/specific_transport_id = TRAMSTATION_LINE_1
	/// Weakref to the tram
	var/datum/weakref/transport_ref

/datum/component/energized/Initialize(plate_inbound, plate_outbound, plate_transport_id)
	if(!isturf(parent))
		return COMPONENT_INCOMPATIBLE

	inbound = plate_inbound
	outbound = plate_outbound
	if(!isnull(plate_transport_id))
		specific_transport_id = plate_transport_id

/datum/component/energized/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_ENTERED, PROC_REF(toast))

/datum/component/energized/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_ENTERED)

/datum/component/energized/proc/find_tram()
	for(var/datum/transport_controller/linear/transport as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		if(transport.specific_transport_id == specific_transport_id)
			transport_ref = WEAKREF(transport)
			return transport

/datum/component/energized/proc/toast(turf/open/floor/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER

	if(!isliving(arrived) || !inbound || !outbound)
		return

	var/mob/living/future_tram_victim = arrived
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve() || find_tram()

	if(isnull(tram) || !tram.controller_operational || !tram.controller_active)
		return

	var/obj/structure/transport/linear/tram/tram_part = tram.return_closest_platform_to(parent)
	if(QDELETED(tram_part))
		return

	var/toast_prob = NORMAL_TOAST_PROB
	if(source.broken || source.burnt || HAS_TRAIT(future_tram_victim, TRAIT_CURSED))
		toast_prob = BROKEN_TOAST_PROB

	if(prob(100 - toast_prob))
		if(prob(25))
			do_sparks(1, FALSE, source)
			playsound(source, "sparks", 40, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
			source.audible_message(span_danger("[capitalize(source.name)] сухо потрескивает электричеством..."))
		return

	var/plate_pos
	var/tram_pos
	var/tram_velocity_sign // 1 for positive axis movement, -1 for negative
	if(tram.travel_direction & (NORTH|SOUTH))
		plate_pos = source.y
		tram_pos = tram_part.y
		tram_velocity_sign = tram.travel_direction & NORTH ? 1 : -1
	else
		plate_pos = source.x
		tram_pos = tram_part.x
		tram_velocity_sign = tram.travel_direction & EAST ? 1 : -1

	// How far away are we? negative if already passed.
	var/approach_distance = tram_velocity_sign * (plate_pos - (tram_pos + DEFAULT_TRAM_MIDPOINT))

	if(approach_distance < 0 || approach_distance >= XING_THRESHOLD_AMBER)
		return
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination = tram.destination_platform
	if(istype(destination))
		if((tram.travel_direction & WEST) && inbound < destination.platform_code)
			return
		if((tram.travel_direction & EAST) && outbound > destination.platform_code)
			return

	do_sparks(4, FALSE, source)
	playsound(source, "sparks", 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	source.audible_message(span_danger("[capitalize(source.name)] громко трещит электричеством!"))
	to_chat(future_tram_victim, span_userdanger("Вы слышите громкий электрический треск!"))
	INVOKE_ASYNC(future_tram_victim, TYPE_PROC_REF(/mob/living, electrocute_act), 15, source, 1)

#undef NORMAL_TOAST_PROB
#undef BROKEN_TOAST_PROB
