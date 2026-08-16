/obj/structure/pool
	name = "pool"
	icon = 'icons/obj/machines/pool.dmi'
	anchored = TRUE
	resistance_flags = UNACIDABLE|INDESTRUCTIBLE

// BLUEMOON: ladders and jump boards are now static decor. The pool itself is a
// liquid basin with free entry/exit, so there is no machinery and no climbing logic.

/obj/structure/pool/ladder
	name = "Ladder"
	icon_state = "ladder"
	desc = "A decorative ladder at the edge of the pool."
	layer = ABOVE_MOB_LAYER
	dir = EAST

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
