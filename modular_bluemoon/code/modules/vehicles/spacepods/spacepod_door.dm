/obj/structure/spacepoddoor
	name = "шлюз"
	desc = "Почему он не открыт?!"
	icon = 'icons/effects/beam.dmi'
	icon_state = "n_beam"
	density = 1
	anchored = 1
	var/id = 1.0
	can_atmos_pass = ATMOS_PASS_NO

/obj/structure/spacepoddoor/Initialize(mapload)
	..()
	air_update_turf(TRUE)

/obj/structure/spacepoddoor/Destroy()
	air_update_turf(TRUE)
	return ..()

/obj/structure/spacepoddoor/CanPass(atom/movable/A, turf/T)
	if(istype(A, /obj/spacepod))
		return TRUE
	return ..()
