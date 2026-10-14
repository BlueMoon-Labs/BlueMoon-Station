/datum/round_event_control/hk47
	name = "HK-47 Assassin Droid"
	typepath = /datum/round_event/ghost_role/hk47
	max_occurrences = 1
	weight = 10
	earliest_start = 30 MINUTES
	min_players = 30
	category = EVENT_CATEGORY_INVASION
	severity = DIRECTOR_SEVERITY_GHOST
	cost = 12
	intensity = 20
	director_ghost_jobban = ROLE_HK47
	director_ghost_preference = ROLE_HK47
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM)
	description = "Дроид-ассасин HK-47 прибывает по легенде с уже принятым первым контрактом: тайно капсулой или крушением в техтоннели, по лицензии ЦК посылкой в карго или телохранителем посылкой в отдел охраняемого - и берёт контракты на экипаж станции."

/datum/round_event_control/hk47/director_preflight()
	if(!hk47_find_maintenance_turf(first_only = TRUE))
		director_preflight_detail = "На станции нет техтоннелей с воздухом, куда может сесть капсула HK-47."
		director_preflight_failure = director_preflight_detail
		return FALSE
	return ..()

/datum/round_event/ghost_role/hk47
	role_name = "дроид-ассасин HK-47"
	minimum_required = 1

/datum/round_event/ghost_role/hk47/proc/pick_landing_turf()
	return hk47_find_maintenance_turf()

/datum/round_event/ghost_role/hk47/spawn_role()
	if(!pick_landing_turf())
		return MAP_ERROR
	var/mob/dead/selected
	for(var/mob/dead/candidate as anything in get_candidates(ROLE_HK47, null, ROLE_HK47))
		if(candidate.key && candidate.client)
			selected = candidate
			break
	if(!selected)
		return NOT_ENOUGH_PLAYERS
	var/turf/landing = pick_landing_turf()
	if(!landing)
		return MAP_ERROR
	var/mob/living/carbon/human/droid = launch_hk47(selected.key, landing)
	spawned_mobs += droid
	var/datum/antagonist/hk47/antag = droid.mind.has_antag_datum(/datum/antagonist/hk47)
	message_admins("[ADMIN_LOOKUPFLW(droid)] прибывает на станцию как HK-47: легенда «[hk47_status_name(antag?.status)]», [arrival_text] в [get_area_name(arrival_turf, TRUE)].")
	log_game("[key_name(droid)] was spawned as HK-47 by an event, legend [antag?.status], arrives at [AREACOORD(arrival_turf)].")
	return SUCCESSFUL_SPAWN

/datum/round_event/ghost_role/hk47/proc/create_hk47(atom/spawn_loc)
	var/mob/living/carbon/human/droid = new(spawn_loc)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.gender = MALE
	droid.real_name = HK47_NAME
	droid.name = HK47_NAME
	droid.dna.real_name = HK47_NAME
	droid.dna.update_dna_identity()
	droid.equipOutfit(/datum/outfit/hk47)
	droid.AddComponent(/datum/component/hk_loyalty)
	return droid

/// Случайный пол техтоннелей станции с пригодным воздухом, никогда не космос; first_only - для preflight.
/proc/hk47_find_maintenance_turf(first_only = FALSE)
	for(var/area/tunnel as anything in shuffle(get_areas(/area/maintenance)))
		var/list/floors = minor_crew_area_floors(tunnel, first_only)
		if(length(floors))
			return pick(floors)
	return null

/datum/outfit/hk47
	name = "HK-47 Assassin Droid"
	back = /obj/item/gun/energy/hk_rifle

/obj/structure/closet/supplypod/hk47
	style = STYLE_SYNDICATE
	bluespace = TRUE
	effectQuiet = TRUE
	explosionSize = list(0, 0, 0, 0)
	delays = list(POD_TRANSIT = 8 SECONDS, POD_FALLING = 4, POD_OPENING = 2 SECONDS, POD_LEAVING = 2 SECONDS)
