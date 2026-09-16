/obj/item/toy/balloon/long/attackby(obj/item/attacking_item, mob/user, params)
	if(!istype(attacking_item, /obj/item/toy/balloon/long) || !HAS_TRAIT(user, TRAIT_BALLOON_SUTRA))
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