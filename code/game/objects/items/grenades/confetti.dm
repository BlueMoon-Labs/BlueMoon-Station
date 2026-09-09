/obj/item/grenade/confetti
	name = "party grenade"
	desc = "Party time!"
	icon_state = "confetti"
	var/spawner_type = /obj/effect/decal/cleanable/confetti

/obj/item/grenade/confetti/prime()
	var/turf/T = get_turf(src)
	playsound(T, 'sound/effects/confetti_partywhistle.ogg', 100, 1)
	for(var/i in 1 to 20)
		var/obj/effect/decal/cleanable/confetti/gib = new spawner_type(loc)
		if(iscarbon(loc))
			var/mob/living/carbon/digester = loc
			digester.add_to_stomach(gib)
		else
			gib.streak(list(NORTH,SOUTH,EAST,WEST))

	qdel(src)
