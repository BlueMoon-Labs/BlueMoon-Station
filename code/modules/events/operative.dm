/datum/round_event_control/operative
	name = "Lone Operative"
	typepath = /datum/round_event/ghost_role/operative
	weight = 0 //Admin only
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION
	description = "A single nuclear operative assaults the station."

/datum/round_event/ghost_role/operative
	minimum_required = 1
	role_name = "lone operative"
	fakeable = FALSE

/datum/round_event/ghost_role/operative/spawn_role()
	return spawn_operative()

/datum/round_event/ghost_role/operative/proc/spawn_operative(keeper_force = FALSE, turf/last_spawn_loc)
	var/list/candidates = get_candidates(ROLE_OPERATIVE, null, ROLE_OPERATIVE)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)

	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc
	for(var/obj/effect/landmark/loneopspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc

	if(keeper_force && spawn_locs.len > 1 && !QDELETED(last_spawn_loc))
		spawn_locs -= last_spawn_loc

	if(!spawn_locs.len)
		return MAP_ERROR

	var/spawn_loc = pick(spawn_locs)

	var/mob/living/carbon/human/operative = new(spawn_loc)
	var/datum/preferences/A = new
	A.copy_to(operative)
	operative.dna.update_dna_identity()

	var/datum/antagonist/nukeop/lone/antag_type = keeper_force ? /datum/antagonist/nukeop/lone/syndicate : /datum/antagonist/nukeop/lone
	if(GLOB.master_mode == ROUNDTYPE_EXTENDED)
		antag_type = new /datum/antagonist/nukeop/lone/syndicate
		antag_type.nukeop_outfit = /datum/outfit/syndicate/lone/extended
	else if(GLOB.master_mode == ROUNDTYPE_DYNAMIC_LIGHT && !keeper_force)
		addtimer(CALLBACK(src, PROC_REF(spawn_operative), TRUE, get_turf(spawn_loc)), 10 SECONDS)

	var/antag_name = initial(antag_type.name)
	var/datum/mind/Mind = new(selected.key)
	Mind.assigned_role = antag_name
	Mind.special_role = antag_name
	Mind.active = 1
	Mind.transfer_to(operative)

	Mind.add_antag_datum(antag_type)

	message_admins("[ADMIN_LOOKUPFLW(operative)] has been made into [antag_name] by an event.")
	log_game("[key_name(operative)] was spawned as a [antag_name] by an event.")
	spawned_mobs += operative
	return SUCCESSFUL_SPAWN
