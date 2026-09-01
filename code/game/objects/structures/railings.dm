/obj/structure/railing
	name = "railing"
	desc = "Basic railing meant to protect idiots like you from falling."
	icon = 'icons/obj/railings.dmi'
	icon_state = "railing"
	density = TRUE
	anchored = TRUE
	climbable = TRUE
	layer = RAILING_LAYER
	///Initial direction of the railing.
	var/ini_dir

/obj/structure/railing/unbreakable
	resistance_flags = INDESTRUCTIBLE

/obj/structure/railing/corner //aesthetic corner sharp edges hurt oof ouch
	icon_state = "railing_corner"
	density = FALSE
	climbable = FALSE

/obj/structure/railing/corner/unbreakable
	resistance_flags = INDESTRUCTIBLE

/obj/structure/railing/corner/end //end of a segment of railing without making a loop
	icon_state = "railing_end"

/obj/structure/railing/corner/end/unbreakable
	resistance_flags = INDESTRUCTIBLE

/obj/structure/railing/corner/end/flip //same as above but flipped around
	icon_state = "railing_end_flip"

/obj/structure/railing/corner/end/flip/unbreakable
	resistance_flags = INDESTRUCTIBLE

/obj/structure/railing/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/simple_rotation,ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS ,null,CALLBACK(src, PROC_REF(can_be_rotated)),CALLBACK(src, PROC_REF(after_rotation)))

/obj/structure/railing/examine(mob/user)
	. = ..()
	if(anchored == TRUE)
		. += span_notice("The railing is <b>bolted</b> to the floor.")
	else
		. += span_notice("The railing is <i>unbolted</i> from the floor and can be deconstructed with <b>wirecutters</b>.")

/obj/structure/railing/Initialize(mapload)
	. = ..()

	var/static/list/tool_behaviors = list(
		TOOL_WELDER = list(
			SCREENTIP_CONTEXT_LMB = list(INTENT_HELP = "Repair"),
		),
		TOOL_WRENCH = list(
			SCREENTIP_CONTEXT_LMB = list(INTENT_ANY = "Anchor/Unanchor"),
		),
		TOOL_WIRECUTTER= list(
			SCREENTIP_CONTEXT_LMB = list(INTENT_ANY = "Cut"),
		)
	)

	AddElement(/datum/element/contextual_screentip_tools, tool_behaviors)

	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_change_layer))
	adjust_dir_layer(dir)

/obj/structure/railing/attackby(obj/item/I, mob/living/user, params)
	..()
	add_fingerprint(user)
	if(I.tool_behaviour == TOOL_WELDER && user.a_intent == INTENT_HELP)
		if(obj_integrity < max_integrity)
			if(!I.tool_start_check(user, amount=0))
				return
			to_chat(user, "<span class='notice'>Вы начинаете чинить [src]...</span>")
			if(I.use_tool(src, user, 40, volume=50))
				obj_integrity = max_integrity
				to_chat(user, "<span class='notice'>Вы починили [src].</span>")
		else
			to_chat(user, "<span class='warning'>[src] выглядит целым.</span>")
		return

/obj/structure/railing/wirecutter_act(mob/living/user, obj/item/I)
	. = ..()
	if(!anchored)
		to_chat(user, "<span class='warning'>Вы перекусываете крепление [src].</span>")
		I.play_tool_sound(src, 100)
		deconstruct()
		return TRUE

/obj/structure/railing/deconstruct(disassembled)
	. = ..()
	if(!loc) //quick check if it's qdeleted already.
		return
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/rods(loc, 2)
		qdel(src)
///Implements behaviour that makes it possible to unanchor the railing.
/obj/structure/railing/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(flags_1&NODECONSTRUCT_1)
		return
	to_chat(user, "<span class='notice'>You begin to [anchored ? "unfasten the railing from":"fasten the railing to"] the floor...</span>")
	if(I.use_tool(src, user, volume = 75, extra_checks = CALLBACK(src, PROC_REF(check_anchored), anchored)))
		setAnchored(!anchored)
		to_chat(user, "<span class='notice'>You [anchored ? "fasten the railing to":"unfasten the railing from"] the floor.</span>")
	return TRUE

/obj/structure/railing/CanPass(atom/movable/mover, turf/target)
	. = ..()
	if(get_dir(loc, target) & dir)
		var/checking = FLYING | FLOATING
		return . || mover.throwing || mover.movement_type & checking || (mover.pass_flags & PASSJUMP)
	return TRUE

/obj/structure/railing/corner/CanPass()
	..()
	return TRUE

/obj/structure/railing/CheckExit(atom/movable/mover, turf/target)
	..()
	if(get_dir(loc, target) & dir)
		var/checking = PHASING | FLYING | FLOATING
		return !density || mover.throwing || mover.movement_type & checking || mover.move_force >= MOVE_FORCE_EXTREMELY_STRONG || (mover.pass_flags & PASSJUMP)
	return TRUE

/obj/structure/railing/corner/CheckExit()
	return TRUE

/obj/structure/railing/proc/can_be_rotated(mob/user,rotation_type)
	if(anchored)
		to_chat(user, "<span class='warning'>[src] cannot be rotated while it is fastened to the floor!</span>")
		return FALSE

	var/target_dir = turn(dir, rotation_type == ROTATION_CLOCKWISE ? -90 : 90)

	if(!valid_window_location(loc, target_dir)) //Expanded to include rails, as well!
		to_chat(user, "<span class='warning'>[src] cannot be rotated in that direction!</span>")
		return FALSE
	return TRUE

/obj/structure/railing/proc/check_anchored(checked_anchored)
	if(anchored == checked_anchored)
		return TRUE

/obj/structure/railing/proc/after_rotation(mob/user,rotation_type)
	air_update_turf(TRUE)
	ini_dir = dir
	add_fingerprint(user)

/obj/structure/railing/proc/on_change_layer(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	adjust_dir_layer(new_dir)

/obj/structure/railing/proc/adjust_dir_layer(direction)
	layer = (direction & SOUTH) ? TURF_LAYER : initial(layer)




