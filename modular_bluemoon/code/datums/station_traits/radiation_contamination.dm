/// Area contamination + mandatory CBRN / MOPP response gear.
/datum/station_trait/radiation_contamination
	name = "Reactor cargo contamination"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 4
	show_in_report = TRUE
	report_message = "При транспортировке отработанного топлива и реакторных компонентов произошла утечка. Станция получила повышенный фон; экипажу выдано СИЗ и средства локализации."
	trait_to_give = STATION_TRAIT_RADIATION_CONTAMINATION
	/// Atoms spawned for this trait (waste spawners delete themselves; not tracked).
	var/list/contamination_atoms = list()

/datum/station_trait/radiation_contamination/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_roundstart_spawn))
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_LATEJOIN_SPAWN, PROC_REF(on_job_latejoin_spawn))

/datum/station_trait/radiation_contamination/revert()
	for(var/atom/A as anything in contamination_atoms)
		if(!QDELETED(A))
			qdel(A)
	contamination_atoms.Cut()
	return ..()

/datum/station_trait/radiation_contamination/on_round_start()
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(scatter_contamination))

/// По одному радиоактивному объекту на каждый generic event spawn; тип чередуется.
/datum/station_trait/radiation_contamination/proc/scatter_contamination()
	var/list/event_spawns = GLOB.generic_event_spawns.Copy()
	shuffle_inplace(event_spawns)

	var/placed = 0

	for(var/obj/effect/landmark/event_spawn/mark as anything in event_spawns)
		if(QDELETED(mark))
			continue
		var/turf/spawn_turf = get_rad_spawn_turf(mark)
		if(!spawn_turf)
			continue
		spawn_contamination_payload(spawn_turf, placed)
		placed++

	var/fallback_spawns_wanted = 128
	var/fallback_spawned = 0
	var/pick_budget = 800
	while(fallback_spawned < fallback_spawns_wanted && pick_budget > 0)
		pick_budget--
		var/turf/picked_drop = pick_radioactive_drop_turf()
		if(!picked_drop)
			continue
		spawn_contamination_payload(picked_drop, fallback_spawned)
		fallback_spawned++

/datum/station_trait/radiation_contamination/proc/get_rad_spawn_turf(obj/effect/landmark/event_spawn/mark, allow_offstation = FALSE)
	var/turf/origin = get_turf(mark)
	var/list/options = list()
	if(is_valid_rad_spawn_turf(origin, allow_offstation))
		options += origin
	for(var/direction in GLOB.cardinals)
		var/turf/near = get_step(origin, direction)
		if(is_valid_rad_spawn_turf(near, allow_offstation))
			options += near
	for(var/turf/check in orange(7, origin))
		if(!(check in options) && is_valid_rad_spawn_turf(check, allow_offstation))
			options += check
	if(!length(options) && istype(origin, /turf/open) && !isspaceturf(origin) && !origin.density)
		// Last-resort for dense/busy arena landmarks: still place the payload at the marker turf.
		options += origin
	return length(options) ? pick(options) : null

/datum/station_trait/radiation_contamination/proc/is_valid_rad_spawn_turf(turf/T, allow_offstation = FALSE)
	if(!T || !istype(T, /turf/open))
		return FALSE
	if(!allow_offstation && !is_station_level(T.z))
		return FALSE
	if(isspaceturf(T))
		return FALSE
	if(T.density)
		return FALSE
	if(is_blocked_turf(T, TRUE))
		return FALSE
	return TRUE

/datum/station_trait/radiation_contamination/proc/pick_radioactive_drop_turf()
	for(var/i in 1 to 48)
		var/turf/candidate = get_safe_random_station_turf()
		if(is_valid_rad_spawn_turf(candidate))
			return candidate
	if(LAZYLEN(GLOB.the_station_areas))
		for(var/j in 1 to 120)
			var/turf/wide_pick = get_random_station_turf()
			if(is_valid_rad_spawn_turf(wide_pick))
				return wide_pick
	return null

/datum/station_trait/radiation_contamination/proc/spawn_contamination_payload(turf/spawn_turf, spawn_index)
	switch(spawn_index % 4)
		if(0)
			var/obj/structure/reagent_dispensers/urbanismbarrel/radium/brl = new(spawn_turf)
			contamination_atoms += brl
		if(1)
			var/obj/effect/landmark/nuclear_waste_spawner/spawner = new(spawn_turf)
			spawner.fire()
		if(2)
			var/obj/item/nuke_core/core = new(spawn_turf)
			// Theft core only pulses on SSobj ticks; forcing one immediate pulse avoids "silent until touched" behavior.
			core.cooldown = world.time - 61
			core.process()
			contamination_atoms += core
		if(3)
			var/obj/item/stock_parts/cell/bluespacereactor/cell = new(spawn_turf)
			contamination_atoms += cell

/datum/station_trait/radiation_contamination/proc/on_job_roundstart_spawn(datum/source, datum/job/job, mob/living/spawned, client/player_client)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(apply_response_gear), job, spawned)

/datum/station_trait/radiation_contamination/proc/on_job_latejoin_spawn(datum/source, datum/job/job, mob/living/spawned)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(apply_response_gear), job, spawned)

/datum/station_trait/radiation_contamination/proc/apply_response_gear(datum/job/job, mob/living/L)
	if(!job || !L || QDELETED(L))
		return
	if(!ishuman(L))
		return
	var/mob/living/carbon/human/H = L
	if(HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM))
		return

	strip_rad_response_slots(H)
	var/list/slots = get_response_outfit_slots(job, H)
	if(!length(slots))
		return

	var/obj/item/clothing/suit/suit = slots["suit"]
	var/obj/item/clothing/head/hood = slots["head"]
	var/obj/item/clothing/mask/mask = slots["mask"]
	var/obj/item/clothing/gloves/gloves = slots["gloves"]
	var/obj/item/clothing/shoes/shoes = slots["shoes"]
	var/obj/item/tank/tank = slots["tank"]

	H.equip_to_slot_or_del(gloves, ITEM_SLOT_GLOVES)
	H.equip_to_slot_or_del(shoes, ITEM_SLOT_FEET)
	H.equip_to_slot_or_del(suit, ITEM_SLOT_OCLOTHING)
	H.equip_to_slot_or_del(mask, ITEM_SLOT_MASK)
	H.equip_to_slot_or_del(hood, ITEM_SLOT_HEAD)
	H.equip_to_slot_or_del(tank, ITEM_SLOT_SUITSTORE)

	var/obj/item/broom/liquidator/broom = new(H)
	if(!H.put_in_hands(broom))
		broom.forceMove(get_turf(H))

	to_chat(H, span_warning("Из-за радиационной аномалии вам выдано защитное снаряжение и метла ликвидатора."))

/datum/station_trait/radiation_contamination/proc/strip_rad_response_slots(mob/living/carbon/human/H)
	for(var/slot in list(ITEM_SLOT_OCLOTHING, ITEM_SLOT_HEAD, ITEM_SLOT_MASK, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET, ITEM_SLOT_SUITSTORE))
		var/obj/item/I = H.get_item_by_slot(slot)
		if(I)
			H.dropItemToGround(I, force = TRUE)

/// Returns suit, head, mask, gloves, shoes, tank types for new().
/datum/station_trait/radiation_contamination/proc/get_response_outfit_slots(datum/job/job, mob/living/carbon/human/H)
	. = list()
	if((job.title == "AI") || (job.title == "Cyborg"))
		return

	var/chosen_tank_path = pick_internals_tank(H)

	if(job.title in GLOB.command_positions)
		var/command_advance = FALSE
		var/obj/item/clothing/suit/suit_path = /obj/item/clothing/suit/cbrn/mopp
		switch(job.title)
			if("Captain", "NanoTrasen Representative", "Blueshield", "Bridge Officer")
				suit_path = /obj/item/clothing/suit/cbrn/mopp/advance/commander
				command_advance = TRUE
			if("Head of Security")
				suit_path = /obj/item/clothing/suit/cbrn/mopp/advance/security
				command_advance = TRUE
			if("Chief Medical Officer")
				suit_path = /obj/item/clothing/suit/cbrn/mopp/advance/medical
				command_advance = TRUE
			if("Chief Engineer")
				suit_path = /obj/item/clothing/suit/cbrn/mopp/advance/engi
				command_advance = TRUE

		if(command_advance)
			.["suit"] = new suit_path(H)
			.["head"] = new /obj/item/clothing/head/helmet/cbrn/mopp/advance(H)
			.["mask"] = new /obj/item/clothing/mask/gas/sechailer/mopp/advance(H)
			.["gloves"] = new /obj/item/clothing/gloves/cbrn/mopp/advance(H)
			.["shoes"] = new /obj/item/clothing/shoes/jackboots/cbrn/mopp/advance(H)
		else
			.["suit"] = new suit_path(H)
			.["head"] = new /obj/item/clothing/head/helmet/cbrn/mopp(H)
			.["mask"] = new /obj/item/clothing/mask/gas/sechailer/mopp(H)
			.["gloves"] = new /obj/item/clothing/gloves/cbrn/mopp(H)
			.["shoes"] = new /obj/item/clothing/shoes/jackboots/cbrn/mopp(H)
		.["tank"] = new chosen_tank_path(H)
		return

	var/suit_type = /obj/item/clothing/suit/cbrn
	var/hood_type = /obj/item/clothing/head/helmet/cbrn
	var/gloves_type = /obj/item/clothing/gloves/cbrn

	if(job.departments & DEPARTMENT_BITFLAG_SECURITY)
		suit_type = /obj/item/clothing/suit/cbrn/security
		hood_type = /obj/item/clothing/head/helmet/cbrn/sec
		gloves_type = /obj/item/clothing/gloves/cbrn/mopp
	else if(job.departments & DEPARTMENT_BITFLAG_ENGINEERING)
		suit_type = /obj/item/clothing/suit/cbrn/engineering
		hood_type = /obj/item/clothing/head/helmet/cbrn/eng
		gloves_type = /obj/item/clothing/gloves/cbrn/engineer
	else if(job.departments & DEPARTMENT_BITFLAG_MEDICAL)
		suit_type = /obj/item/clothing/suit/cbrn/medical
		hood_type = /obj/item/clothing/head/helmet/cbrn/med
		gloves_type = /obj/item/clothing/gloves/cbrn/medical
	else if(job.departments & DEPARTMENT_BITFLAG_SCIENCE)
		suit_type = /obj/item/clothing/suit/cbrn/science
		hood_type = /obj/item/clothing/head/helmet/cbrn/sci
	else if(job.departments & DEPARTMENT_BITFLAG_SUPPLY)
		suit_type = /obj/item/clothing/suit/cbrn/cargo
		hood_type = /obj/item/clothing/head/helmet/cbrn/cargo
	else if(job.departments & DEPARTMENT_BITFLAG_SERVICE)
		suit_type = /obj/item/clothing/suit/cbrn/service
		hood_type = /obj/item/clothing/head/helmet/cbrn/serv

	.["suit"] = new suit_type(H)
	.["head"] = new hood_type(H)
	.["mask"] = new /obj/item/clothing/mask/gas/cbrn(H)
	.["gloves"] = new gloves_type(H)
	.["shoes"] = new /obj/item/clothing/shoes/jackboots/cbrn(H)
	.["tank"] = new chosen_tank_path(H)

/datum/station_trait/radiation_contamination/proc/pick_internals_tank(mob/living/carbon/human/H)
	if(is_species(H, /datum/species/plasmaman))
		return /obj/item/tank/internals/plasmamandouble
	return /obj/item/tank/internals/doubleoxygen
