/*
 * Balloons — ported from tgstation (icons/obj/toys/balloons.dmi)
 */

/obj/item/toy/waterballoon
	name = "water balloon"
	desc = "A translucent balloon. There's nothing in it."
	icon = 'icons/obj/toys/balloons.dmi'
	icon_state = "balloon_red-e"
	item_state = "balloon-empty"

/obj/item/toy/waterballoon/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	create_reagents(10)

/obj/item/toy/waterballoon/attack(mob/living/carbon/human/M, mob/user)
	return

/obj/item/toy/waterballoon/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!istype(A, /obj/structure/reagent_dispensers))
		return
	var/obj/structure/reagent_dispensers/RD = A
	if(RD.reagents.total_volume <= 0)
		to_chat(user, span_warning("[RD] is empty."))
	else if(reagents.total_volume >= 10)
		to_chat(user, span_warning("[src] is full."))
	else
		RD.reagents.trans_to(src, 10)
		to_chat(user, span_notice("You fill the balloon with the contents of [RD]."))
		desc = "A translucent balloon with some form of liquid sloshing around in it."
		update_icon()

/obj/item/toy/waterballoon/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/glass) || istype(I, /obj/item/reagent_containers/cup))
		if(I.reagents)
			if(I.reagents.total_volume <= 0)
				to_chat(user, span_warning("[I] is empty."))
			else if(reagents.total_volume >= 10)
				to_chat(user, span_warning("[src] is full."))
			else
				desc = "A translucent balloon with some form of liquid sloshing around in it."
				to_chat(user, span_notice("You fill the balloon with the contents of [I]."))
				I.reagents.trans_to(src, 10)
				update_icon()
	else if(I.get_sharpness())
		balloon_burst()
	else
		return ..()

/obj/item/toy/waterballoon/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!..())
		balloon_burst(hit_atom)

/obj/item/toy/waterballoon/proc/balloon_burst(atom/AT)
	if(reagents.total_volume >= 1)
		var/turf/T = AT ? get_turf(AT) : get_turf(src)
		T.visible_message(span_danger("[src] bursts!"), span_hear("You hear a pop and a splash."))
		reagents.reaction(T)
		for(var/atom/A in T)
			reagents.reaction(A)
		icon_state = "burst"
		qdel(src)

/obj/item/toy/waterballoon/update_icon_state()
	if(reagents.total_volume >= 1)
		icon_state = "waterballoon"
		item_state = "balloon"
	else
		icon_state = "balloon_red-e"
		item_state = "balloon-empty"
	return ..()

#define BALLOON_COLORS list("red", "blue", "green", "yellow", "orange", "purple")

/obj/item/toy/balloon
	name = "balloon"
	desc = "No birthday is complete without it. Sealed with a mechanical bluespace wrap so it remains floating no matter what."
	icon = 'icons/obj/toys/balloons.dmi'
	icon_state = "balloon"
	item_state = "balloon"
	lefthand_file = 'icons/mob/inhands/items/balloons_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/balloons_righthand.dmi'
	w_class = WEIGHT_CLASS_BULKY
	var/random_color = TRUE
	/// The balloon's current colour name, if any.
	var/current_color

/obj/item/toy/balloon/long
	name = "long balloon"
	desc = "A perfect balloon to contort into goofy forms. Sealed with a mechanical bluespace wrap so it remains floating no matter what."
	icon_state = "balloon_long"
	item_state = "balloon"
	w_class = WEIGHT_CLASS_NORMAL
	var/list/balloon_combos = list(
		list("red", "blue") = /obj/item/toy/balloon_animal/guy,
		list("red", "green") = /obj/item/toy/balloon_animal/nukie,
		list("red", "yellow") = /obj/item/toy/balloon_animal/clown,
		list("red", "orange") = /obj/item/toy/balloon_animal/cat,
		list("red", "purple") = /obj/item/toy/balloon_animal/fly,
		list("blue", "green") = /obj/item/toy/balloon_animal/podguy,
		list("blue", "yellow") = /obj/item/toy/balloon_animal/ai,
		list("blue", "orange") = /obj/item/toy/balloon_animal/dog,
		list("blue", "purple") = /obj/item/toy/balloon_animal/xeno,
		list("green", "yellow") = /obj/item/toy/balloon_animal/banana,
		list("green", "orange") = /obj/item/toy/balloon_animal/lizard,
		list("green", "purple") = /obj/item/toy/balloon_animal/slime,
		list("yellow", "orange") = /obj/item/toy/balloon_animal/moth,
		list("yellow", "purple") = /obj/item/toy/balloon_animal/ethereal,
		list("orange", "purple") = /obj/item/toy/balloon_animal/plasmaman,
	)

/obj/item/toy/balloon/long/attackby(obj/item/attacking_item, mob/user, params)
	if(!istype(attacking_item, /obj/item/toy/balloon/long))
		return ..()
	var/obj/item/toy/balloon/long/hit_by = attacking_item
	if(hit_by.current_color == current_color)
		to_chat(user, span_warning("You must use balloons of different colours to do that!"))
		return ..()
	user.visible_message(
		span_notice("[user] starts contorting up a balloon animal!"),
		span_hear("You hear balloons being contorted."),
		vision_distance = 3,
		ignored_mobs = user,
	)
	for(var/list/pair_of_colors in balloon_combos)
		if((hit_by.current_color == pair_of_colors[1] && current_color == pair_of_colors[2]) || (current_color == pair_of_colors[1] && hit_by.current_color == pair_of_colors[2]))
			var/path_to_spawn = balloon_combos[pair_of_colors]
			user.put_in_hands(new path_to_spawn)
			break
	qdel(hit_by)
	qdel(src)
	return TRUE

/obj/item/toy/balloon/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/ammo_casing/caseless/foam_dart) && ismonkey(user))
		pop_balloon(monkey_pop = TRUE)
	else
		return ..()

/obj/item/toy/balloon/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	var/mob/thrower = throwingdatum?.thrower
	if(ismonkey(thrower) && istype(AM, /obj/item/ammo_casing/caseless/foam_dart))
		pop_balloon(monkey_pop = TRUE)
	else
		return ..()

/obj/item/toy/balloon/bullet_act(obj/item/projectile/P)
	if((istype(P, /obj/item/projectile/bullet/p50) || istype(P, /obj/item/projectile/bullet/reusable/foam_dart)) && ismonkey(P.firer))
		pop_balloon(monkey_pop = TRUE)
		return BULLET_ACT_HIT
	return ..()

/obj/item/toy/balloon/proc/pop_balloon(monkey_pop = FALSE)
	playsound(src, 'sound/effects/cartoon_sfx/cartoon_pop.ogg', 50, TRUE)
	if(monkey_pop)
		new /obj/item/coin/iron(get_turf(src))
	qdel(src)

/obj/item/toy/balloon/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	if(!random_color)
		return
	current_color = pick(BALLOON_COLORS)
	update_icon()

/obj/item/toy/balloon/update_name(updates)
	. = ..()
	name = "[current_color ? "[current_color] " : ""][initial(name)]"

/obj/item/toy/balloon/vv_edit_var(vname, vval)
	. = ..()
	if(vname == NAMEOF(src, current_color))
		update_icon()

/obj/item/toy/balloon/update_icon_state()
	. = ..()
	var/base_state = initial(icon_state)
	var/new_icon = "[base_state][current_color ? "_[current_color]" : ""]"
	item_state = new_icon
	icon_state = "[new_icon][isturf(loc) ? "" : "_storage"]"

/obj/item/toy/balloon/Moved(atom/oldloc, dir, forced)
	. = ..()
	update_icon()

/obj/item/toy/balloon/corgi
	name = "corgi balloon"
	desc = "A balloon in the shape of a corgi's head. For the all year good boys."
	icon_state = "corgi"
	item_state = "corgi"
	random_color = FALSE

/obj/item/toy/balloon/heart
	name = "heart balloon"
	desc = "A balloon in the shape of a heart. How lovely."
	icon_state = "heart"
	item_state = "heart"
	random_color = FALSE

/obj/item/toy/balloon/syndicate
	name = "syndicate balloon"
	desc = "There is a tag on the back that reads \"FUK NT!11!\"."
	icon_state = "syndballoon"
	item_state = "syndballoon"
	random_color = FALSE

/obj/item/toy/balloon/syndicate/pickup(mob/living/user)
	. = ..()
	if(user?.mind?.has_antag_datum(/datum/antagonist, TRUE))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "badass_antag", /datum/mood_event/badass_antag)

/obj/item/toy/balloon/syndicate/dropped(mob/living/user)
	if(user)
		SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "badass_antag")
	. = ..()

/obj/item/toy/balloon/syndicate/Destroy()
	if(ismob(loc))
		var/mob/living/M = loc
		SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "badass_antag")
	return ..()

/obj/item/toy/balloon/arrest
	name = "arreyst balloon"
	desc = "A half inflated balloon about a boyband named Arreyst that was popular about ten years ago, famous for making fun of red jumpsuits as unfashionable."
	icon_state = "arrestballoon"
	item_state = "arrestballoon"
	random_color = FALSE

/// Legacy typepath; identical to /obj/item/toy/balloon/syndicate.
/obj/item/toy/syndicateballoon
	parent_type = /obj/item/toy/balloon/syndicate

#undef BALLOON_COLORS

/*
 * Balloon animals
 */

/obj/item/toy/balloon_animal
	name = "balloon animal"
	desc = "You shouldn't have this."
	icon = 'icons/obj/toys/balloons.dmi'
	item_state = "balloon"
	lefthand_file = 'icons/mob/inhands/items/balloons_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/balloons_righthand.dmi'
	throwforce = 0
	throw_speed = 2
	throw_range = 5
	force = 0

/obj/item/toy/balloon_animal/guy
	name = "balloon guy"
	desc = "A balloon effigy of the everyday standard issue human guy. Wonder if he pays balloon taxes. He probably evades them."
	icon_state = "balloon_guy"
	item_state = "balloon_guy"

/obj/item/toy/balloon_animal/nukie
	name = "balloon nukie"
	desc = "A balloon effigy of syndicate's nuclear operative. Either made to appease them and pray for survival, or to poke fun at them."
	icon_state = "balloon_nukie"
	item_state = "balloon_nukie"

/obj/item/toy/balloon_animal/clown
	name = "balloon clown"
	desc = "A balloon clown, smiling from ear to ear and beyond!"
	icon_state = "balloon_clown"
	item_state = "balloon_clown"

/obj/item/toy/balloon_animal/cat
	name = "balloon cat"
	desc = "Without the sharp claws, balloon cats are possibly cuter than their live counterparts."
	icon_state = "balloon_cat"
	item_state = "balloon_cat"

/obj/item/toy/balloon_animal/fly
	name = "balloon fly"
	desc = "A balloon effigy of a flyperson. Thankfully, it doesn't come with balloon vomit."
	icon_state = "balloon_fly"
	item_state = "balloon_fly"

/obj/item/toy/balloon_animal/podguy
	name = "balloon podguy"
	desc = "A balloon effigy of a podperson."
	icon_state = "balloon_podguy"
	item_state = "balloon_podguy"

/obj/item/toy/balloon_animal/ai
	name = "balloon ai core"
	desc = "A somewhat unrealistic balloon effigy of the station's AI core."
	icon_state = "balloon_ai"
	item_state = "balloon_ai"

/obj/item/toy/balloon_animal/dog
	name = "balloon dog"
	desc = "A balloon effigy of the best boy."
	icon_state = "balloon_dog"
	item_state = "balloon_dog"

/obj/item/toy/balloon_animal/xeno
	name = "balloon xeno"
	desc = "A balloon effigy of a spooky xeno!"
	icon_state = "balloon_xeno"
	item_state = "balloon_xeno"

/obj/item/toy/balloon_animal/banana
	name = "balloon banana"
	desc = "A balloon banana. This one can't be slipped on."
	icon_state = "balloon_banana"
	item_state = "balloon_banana"

/obj/item/toy/balloon_animal/lizard
	name = "balloon lizard"
	desc = "A balloon effigy of a lizard."
	icon_state = "balloon_lizard"
	item_state = "balloon_lizard"

/obj/item/toy/balloon_animal/slime
	name = "balloon slime"
	desc = "A balloon effigy of a purple slime."
	icon_state = "balloon_slime"
	item_state = "balloon_slime"

/obj/item/toy/balloon_animal/moth
	name = "balloon moth"
	desc = "A balloon effigy of a moth."
	icon_state = "balloon_moth"
	item_state = "balloon_moth"

/obj/item/toy/balloon_animal/ethereal
	name = "balloon ethereal"
	desc = "A balloon effigy of an ethereal artisan."
	icon_state = "balloon_ethereal"
	item_state = "balloon_ethereal"

/obj/item/toy/balloon_animal/plasmaman
	name = "balloon plasmaman"
	desc = "A balloon effigy of a plasmaman."
	icon_state = "balloon_plasmaman"
	item_state = "balloon_plasmaman"
