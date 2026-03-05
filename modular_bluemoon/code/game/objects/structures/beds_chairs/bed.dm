//Гига кровати
/obj/structure/bed/giant //corner
	name = "giant bed"
	icon_state = "bed_corner"
	icon = 'modular_bluemoon/icons/obj/giant_bed.dmi'
	buildstackamount = 4

/obj/structure/bed/giant/side
	icon_state = "bed_side"

/obj/structure/bed/giant/middle
	icon_state = "bed_middle"

/obj/structure/bed/giant/pillow //corner
	icon_state = "bed_corner_pillow"

/obj/structure/bed/giant/pillow/side
	icon_state = "bed_side_pillow"

//Копипаст из code\game\objects\structures\beds_chairs\chair.dm dont look on me
/obj/structure/bed/giant/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE, CALLBACK(src, PROC_REF(can_user_rotate)), CALLBACK(src, PROC_REF(can_be_rotated)), null)

/obj/structure/bed/giant/proc/can_be_rotated(mob/user)
	return TRUE

/obj/structure/bed/giant/proc/can_user_rotate(mob/user)
	var/mob/living/L = user
	if(istype(L))
		if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
			return FALSE
		else
			return TRUE
	return FALSE
//Копипаст закончен

//Bed
/obj/structure/bed/pre_buckle_mob(mob/living/M)
	if(buckle_lying)
		switch(dir)
			if(NORTH, WEST) // 1, 8
				buckle_lying = 270
			if(SOUTH, EAST) // 2, 4
				buckle_lying = 90
	. = ..()

/obj/structure/bed/double
	icon = 'modular_bluemoon/icons/obj/objects.dmi'
	icon_state = "bed_double"

/obj/structure/bed/pod
	icon = 'modular_bluemoon/icons/obj/lavaland/survival_pod.dmi'
	icon_state = "bed"

/obj/structure/bed/double/pod
	icon = 'modular_bluemoon/icons/obj/lavaland/survival_pod.dmi'
	icon_state = "bed_double"

/obj/structure/bed/medieval
	desc = "A luxurious bed, inviting you to rest on it, oh traveler."
	icon = 'modular_bluemoon/icons/obj/structures_64x64.dmi'
	icon_state = "bed_1x2"

/obj/structure/bed/medieval/bed_2x2
	icon_state = "bed_2x2"
