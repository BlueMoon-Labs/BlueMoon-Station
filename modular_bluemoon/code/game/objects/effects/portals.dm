/obj/effect/custom_portal
	name = "Portal?"
	icon = 'modular_bluemoon/icons/effects/effects.dmi'
	icon_state = "portal"
	desc = "A strange portal"

/obj/effect/custom_portal/Station
	name = "Portal to Station"

/obj/effect/custom_portal/Hotel
	name = "Portal to Hotel"

/obj/effect/custom_portal/Station/Crossed(atom/movable/AM)
	if(isnull(AM))
		return
	var/turf/destination = find_station_destination()
	if(!destination)
		return
	AM.forceMove(destination)
	playsound(src.loc, get_sfx("spark"), 100, 1)

/// Станционная сфера ghostdojo, а на картах без неё - прибытие станции.
/obj/effect/custom_portal/Station/proc/find_station_destination()
	for(var/obj/item/hilbertshotel/ghostdojo/sphere in SShilbertshotel.all_hilbert_spheres)
		if(sphere.is_ghost_cafe || sphere.ruinSpawned)
			continue
		var/turf/sphere_turf = get_turf(sphere)
		if(sphere_turf)
			return sphere_turf
	var/list/arrival_turfs = list()
	for(var/turf/open/arrival_turf in get_area_turfs(/area/hallway/secondary/entry))
		if(is_station_level(arrival_turf.z) && !isgroundlessturf(arrival_turf) && !arrival_turf.is_blocked_turf(TRUE))
			arrival_turfs += arrival_turf
	if(length(arrival_turfs))
		return pick(arrival_turfs)
	if(length(SSjob.latejoin_trackers))
		return get_turf(pick(SSjob.latejoin_trackers))
	return get_turf(SSjob.get_last_resort_spawn_points())

/obj/effect/custom_portal/Hotel/Crossed(atom/movable/AM)
	if(isnull(AM))
		return

	for(var/obj/effect/mob_spawn/human/hotel_staff/splurt/guest/g in world)
		AM.forceMove(g.loc)
		playsound(src.loc, get_sfx("spark"), 100, 1)
