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

/datum/round_event/ghost_role/operative/proc/should_spawn_disk_defender()
	return GLOB.round_type == ROUNDTYPE_DYNAMIC_LIGHT

/datum/round_event/ghost_role/operative/proc/get_disk_defender_spawn_turf()
	for(var/obj/item/disk/nuclear/nuke_disk in GLOB.poi_list)
		return get_turf(nuke_disk)
	for(var/obj/effect/landmark/start/captain/captain_start in GLOB.start_landmarks_list)
		return get_turf(captain_start)
	for(var/obj/effect/landmark/start/head_of_security/hos_start in GLOB.start_landmarks_list)
		return get_turf(hos_start)
	return null

/datum/round_event/ghost_role/operative/proc/spawn_event_operative(mob/dead/selected, turf/spawn_loc, assigned_role, special_role, antag_path)
	var/mob/living/carbon/human/new_character = new(spawn_loc)
	var/datum/preferences/A = new
	A.copy_to(new_character)
	new_character.dna.update_dna_identity()
	var/datum/mind/new_mind = new /datum/mind(selected.key)
	new_mind.assigned_role = assigned_role
	new_mind.special_role = special_role
	new_mind.active = 1
	new_mind.transfer_to(new_character)
	new_mind.add_antag_datum(antag_path)
	spawned_mobs += new_character
	return new_character

/datum/round_event/ghost_role/operative/spawn_role()
	var/spawn_disk_defender = should_spawn_disk_defender()
	minimum_required = spawn_disk_defender ? 2 : initial(minimum_required)
	var/list/candidates = get_candidates(ROLE_OPERATIVE, null, ROLE_OPERATIVE)
	if(length(candidates) < minimum_required)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)
	var/mob/dead/selected_defender
	var/turf/defender_spawn
	if(spawn_disk_defender)
		selected_defender = pick_n_take(candidates)
		defender_spawn = get_disk_defender_spawn_turf()
		if(!selected_defender)
			return NOT_ENOUGH_PLAYERS
		if(!defender_spawn)
			return MAP_ERROR

	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc
	for(var/obj/effect/landmark/loneopspawn/L in GLOB.landmarks_list)
		spawn_locs += L.loc
	if(!spawn_locs.len)
		return MAP_ERROR

	var/mob/living/carbon/human/operative = spawn_event_operative(
		selected,
		pick(spawn_locs),
		"Lone Operative",
		"Lone Operative",
		/datum/antagonist/nukeop/lone
	)

	if(spawn_disk_defender)
		var/mob/living/carbon/human/disk_defender = spawn_event_operative(
			selected_defender,
			defender_spawn,
			"Nuclear Disk Defender",
			"Nuclear Disk Defender",
			/datum/antagonist/nukeop/lone/disk_defender
		)
		message_admins("[ADMIN_LOOKUPFLW(disk_defender)] has been made into nuclear disk defender by a Dynamic Light lone operative event.")
		log_game("[key_name(disk_defender)] was spawned as a nuclear disk defender by a Dynamic Light lone operative event.")

	message_admins("[ADMIN_LOOKUPFLW(operative)] has been made into lone operative by an event.")
	log_game("[key_name(operative)] was spawned as a lone operative by an event.")
	return SUCCESSFUL_SPAWN
