/obj/structure/pool
	name = "pool"
	icon = 'icons/obj/machines/pool.dmi'
	anchored = TRUE
	resistance_flags = UNACIDABLE|INDESTRUCTIBLE


/obj/structure/pool/ladder
	name = "Ladder"
	icon_state = "ladder"
	desc = "A ladder at the edge of the pool. Lets you climb out of the water with ease."
	layer = ABOVE_MOB_LAYER
	dir = EAST
	anchored = TRUE
	max_integrity = 100
	integrity_failure = 0.33
	resistance_flags = 0
	obj_flags = CAN_BE_HIT
	var/buildstack = /obj/item/stack/sheet/metal
	var/buildstackamount = 10

/obj/structure/pool/ladder/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/T = get_turf(src)
		if(buildstack)
			new buildstack(T, buildstackamount)
	qdel(src)

/obj/item/pool_ladder
	name = "Pool Ladder"
	desc = "A ladder for a pool. Place it at the pool's edge while standing in the water to climb out safely."
	icon = 'icons/obj/machines/pool.dmi'
	icon_state = "ladder"
	w_class = WEIGHT_CLASS_SMALL
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'

/obj/item/pool_ladder/afterattack(atom/target, mob/user, proximity)
	if(!proximity)
		return
	if(!istype(user.loc, /turf/open/pool))
		to_chat(user, "<span class='warning'>Вы должны находиться в бассейне, чтобы установить лестницу!</span>")
		return
	if(!isturf(target) || istype(target, /turf/open/pool))
		to_chat(user, "<span class='warning'>Лестницу нужно ставить, кликнув по плитке рядом с бассейном!</span>")
		return
	var/turf/pool_tile
	var/press_dir
	for(var/d in GLOB.cardinals)
		var/turf/T = get_step(target, d)
		if(istype(T, /turf/open/pool))
			pool_tile = T
			press_dir = turn(d, 180)
			break
	if(!pool_tile)
		to_chat(user, "<span class='warning'>Лестницу можно ставить только рядом с бассейном!</span>")
		return
	if(locate(/obj/structure/pool/ladder) in pool_tile)
		to_chat(user, "<span class='warning'>Здесь уже есть лестница!</span>")
		return
	var/obj/structure/pool/ladder/L = new(pool_tile)
	L.setDir(turn(press_dir, 180))
	var/pixel_shift = 16
	switch(press_dir)
		if(NORTH)
			L.pixel_y = pixel_shift
		if(SOUTH)
			L.pixel_y = -pixel_shift
	user.visible_message("<span class='notice'>[user] устанавливает [L].</span>")
	qdel(src)

/obj/structure/pool/Rboard
	name = "JumpBoard"
	density = FALSE
	icon_state = "boardright"
	desc = "The less-loved portion of the jumping board."
	dir = EAST

/obj/structure/pool/Lboard
	name = "JumpBoard"
	icon_state = "boardleft"
	desc = "Get on there to jump!"
	layer = FLY_LAYER
	dir = WEST
