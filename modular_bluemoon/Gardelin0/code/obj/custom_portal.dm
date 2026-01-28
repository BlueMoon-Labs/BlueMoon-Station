/obj/effect/custom_portal
	name = "Portal?"
	icon = 'modular_bluemoon/Gardelin0/icons/effects/effects.dmi'
	icon_state = "portal"
	desc = "A strange portal"

/obj/effect/custom_portal/Station
	name = "Portal to Station"

/obj/effect/custom_portal/Hotel
	name = "Portal to Hotel"

/obj/effect/custom_portal/Station/Crossed(atom/movable/AM)
	if(isnull(AM))
		return

	for(var/obj/item/hilbertshotel/ghostdojo/g in SShilbertshotel.all_hilbert_spheres)
		if(g.is_ghost_cafe || g.ruinSpawned)
			continue
		AM.forceMove(g.loc)
		playsound(src.loc, get_sfx("spark"), 100, 1)

/obj/effect/custom_portal/Hotel/Crossed(atom/movable/AM)
	if(isnull(AM))
		return

	for(var/obj/effect/mob_spawn/human/hotel_staff/splurt/guest/g in world)
		AM.forceMove(g.loc)
		playsound(src.loc, get_sfx("spark"), 100, 1)
