/datum/round_event_control/anomaly/tear/honk
	name = "Honked Dimensional Tear"
	typepath = /datum/round_event/anomaly/tear/honk
	weight = 5
	max_occurrences = 1
	min_players = 30
	category = EVENT_CATEGORY_ANOMALIES
	admin_setup = list(/datum/event_admin_setup/set_location/anomaly)

/datum/round_event/anomaly/tear/honk
	var/obj/effect/tear/honk/HE //i could just inherit but its being finicky.

/datum/round_event/anomaly/tear/honk/announce()
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("На борту станции зафиксирована Хонканомалия. Предполагаемая локация: [impact_area.name].", "ВНИМАНИЕ: ХОНК-АНОМАЛИЯ.", 'sound/items/AirHorn.ogg')

/datum/round_event/anomaly/tear/honk/start()
	var/turf/tear_turf
	if(spawn_location)
		impact_area = get_area(spawn_location)
		tear_turf = spawn_location
	else
		impact_area = placer.findValidArea()
		tear_turf = placer.findValidTurf(impact_area)

	if(!tear_turf)
		return

	HE = new /obj/effect/tear/honk(tear_turf)

/datum/round_event/anomaly/tear/honk/end()
	if(HE)
		qdel(HE)

/obj/effect/tear/honk
	name = "Honkmensional Tear"
	desc = "A tear in the dimensional fabric of sanity."

/obj/effect/tear/honk/spew_critters()
	for(var/i in 1 to 6)
		var/mob/living/simple_animal/hostile/retaliate/clown/mutant/goblin/G = new(get_turf(src))
		if(prob(50))
			for(var/j = 1, j <= rand(1, 3), j++)
				step(G, pick(NORTH, SOUTH, EAST, WEST))
