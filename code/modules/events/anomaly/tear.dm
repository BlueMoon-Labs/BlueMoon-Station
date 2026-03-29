/datum/round_event_control/anomaly/tear
	name = "Dimensional Tear"
	typepath = /datum/round_event/anomaly/tear
	weight = 15
	max_occurrences = 1
	min_players = 30
	category = EVENT_CATEGORY_ANOMALIES
	admin_setup = list(/datum/event_admin_setup/set_location/anomaly)

/datum/round_event/anomaly/tear
	start_when = 3
	announce_when = 20
	end_when = 50
	var/obj/effect/tear/TE

/datum/round_event/anomaly/tear/announce()
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("На борту станции зафиксирован пространственно-временной разрыв. Предполагаемая локация: [impact_area.name].", "ВНИМАНИЕ: ОБНАРУЖЕНА АНОМАЛИЯ")

/datum/round_event/anomaly/tear/start()
	var/turf/tear_turf
	if(spawn_location)
		impact_area = get_area(spawn_location)
		tear_turf = spawn_location
	else
		impact_area = placer.findValidArea()
		tear_turf = placer.findValidTurf(impact_area)

	if(!tear_turf)
		return

	TE = new /obj/effect/tear(tear_turf)

/datum/round_event/anomaly/tear/end()
	if(TE)
		qdel(TE)

/obj/effect/tear
	name="Dimensional Tear"
	desc="A tear in the dimensional fabric of space and time."
	icon='icons/effects/tear.dmi'
	icon_state="tear"
	density = 0
	anchored = 1
	light_range = 3
	pixel_x = -96
	pixel_y = -96
	layer = BYOND_LIGHTING_LAYER

/obj/effect/tear/Initialize(mapload)
	. = ..()
	var/obj/effect/overlay/animation = new(loc)
	animation.icon_state = "newtear"
	animation.icon = 'icons/effects/tear.dmi'
	animation.pixel_x = pixel_x
	animation.pixel_y = pixel_y
	animation.layer = layer + 0.01
	spawn(15)
		if(animation)
			qdel(animation)

	addtimer(CALLBACK(src, PROC_REF(spew_critters)), rand(30, 120))

/obj/effect/tear/proc/spew_critters()
	for(var/i in 1 to 5)
		var/mob/living/simple_animal/S
		S = create_random_mob(get_turf(src), HOSTILE_SPAWN)
		S.faction |= "chemicalsummon"
		if(prob(50))
			for(var/j = 1, j <= rand(1, 3), j++)
				step(S, pick(NORTH, SOUTH, EAST, WEST))
