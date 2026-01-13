/obj/item/pinecone
	name = "Pine cone"
	desc = "Big pine. Cool."
	icon = 'modular_bluemoon/icons/obj/hydroponics/pines.dmi'
	icon_state = "cone"

/obj/structure/flora/stump/pinestump
	icon = 'modular_bluemoon/icons/obj/hydroponics/pines.dmi'
	icon_state = "stump_dark"
	pixel_x = -10
	density = FALSE
	layer = BELOW_MOB_LAYER
	anchored = TRUE

/obj/structure/flora/stump/pinestump_alt
	icon = 'modular_bluemoon/icons/obj/hydroponics/pines.dmi'
	icon_state = "stump"
	pixel_x = -10
	density = FALSE
	layer = BELOW_MOB_LAYER
	anchored = TRUE

/obj/structure/flora/tree/pinetree
	name = "pine tree"
	desc = "Big pine. Cool."
	icon = 'modular_bluemoon/icons/obj/hydroponics/pines.dmi'
	icon_state = "pine"
	spawned_stump = /obj/structure/flora/stump/pinestump
	log_amount = 16
	pixel_x = -10

/obj/structure/flora/tree/pinetree/alt
	name = "pine tree"
	desc = "Big pine. Cool."
	icon = 'modular_bluemoon/icons/obj/hydroponics/pines.dmi'
	icon_state = "pine_alt"
	spawned_stump = /obj/structure/flora/stump/pinestump_alt
	pixel_x = -10

/obj/structure/flora/tree/pinegrow
	name = "Pine sprout"
	desc = "A large tree. (In the near future)"
	icon = 'modular_bluemoon/icons/obj/hydroponics/pines.dmi'
	icon_state = "grow-anim"
	pixel_x = 0

/obj/structure/flora/tree/pinegrow/Initialize(mapload)
	.=..()
	//stage 1
	icon_state="pine-grow1"
	log_amount = 0
	density = FALSE
	layer = BELOW_MOB_LAYER
	anchored = TRUE
	sleep(200)

	//stage 2
	icon_state="pine-grow2"
	sleep(200)

	//stage 3
	icon_state="pine-grow3"
	log_amount = 1
	sleep(200)

	//stage 4
	icon_state="pine-grow4"
	layer = ABOVE_ALL_MOB_LAYER
	log_amount = 3
	density = TRUE
	sleep(200)

	if (istype(get_turf(src),/turf/open/floor/plating/asteroid/snow))
		new /obj/structure/flora/tree/pine(get_turf(src))
	else
		if(prob(50))
			new /obj/structure/flora/tree/pinetree(get_turf(src))
		else
			new /obj/structure/flora/tree/pinetree/alt(get_turf(src))
	qdel(src)

/turf/open/floor/attackby(obj/item/C, mob/user, params)
	if (istype(src,/turf/open/floor/grass) || istype(src,/turf/open/floor/plating/dirt) || istype(src,/turf/open/floor/plating/asteroid) || istype(src,/turf/open/floor/plating/beach/sand))
		if(istype(C,/obj/item/pinecone))
			qdel(C)
			new /obj/structure/flora/tree/pinegrow(get_turf(src))
	if(..())
		return

