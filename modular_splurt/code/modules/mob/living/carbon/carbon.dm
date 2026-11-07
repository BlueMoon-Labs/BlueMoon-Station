/mob/living/carbon/cuff_resist(obj/item/I, breakouttime = 600, cuff_break = 0)
	if(istype(I, /obj/item/restraints/bondage_rope))
		var/obj/item/restraints/bondage_rope/rope = I
		cuff_break = rope.prepare_resist(src)
		if(cuff_break == -1)
			to_chat(src, "<span class='danger'>You are not able to reach the rope.</span>")
			return
	. = ..()

/mob/living/carbon/clear_cuffs(obj/item/I, cuff_break, is_hidden = FALSE)
	if(istype(I, /obj/item/restraints/bondage_rope))
		var/obj/item/restraints/bondage_rope/rope = I
		if(LAZYLEN(rope.rope_stack) > 1)
			visible_message(span_danger("[src] ослабляет путы!"), vision_distance = INTERACTION_MESSAGE_RANGE(is_hidden), visible_message_flags = INTERACTION_MESSAGE_FLAGS(is_hidden))
			to_chat(src, "<span class='notice'>You successfully loosen up your rope.</span>")

			var/obj/item/restraints/bondage_rope/new_rope = new rope.type()
			new_rope.color = pop(rope.rope_stack)
			new_rope.forceMove(src.loc)
			return
	. = ..()

// Liquid Panty Dropper effect
/mob/living/carbon/proc/clothing_burst(throw_clothes = FALSE, is_hidden = FALSE)
	// Variable for if the action succeeded
	var/user_disrobed = FALSE

	// Get worn items
	var/items = get_contents()

	// BLUEMOON ADD START - нельзя сбросить включенный модсьют
	var/obj/item/mod/control/modsuit = get_item_by_slot(ITEM_SLOT_BACK)
	if(modsuit && istype(modsuit) && modsuit.is_active())
		to_chat(src, "<span class='warning'>Включенный модсьют не даёт сбросить одежду!</span>")
		return
	// BLUEMOON ADD END

	// Iterate over worn items
	for(var/obj/item/item_worn in items)
		// Ignore non-mob (storage)
		if(!ismob(item_worn.loc))
			continue

		// Ignore held items
		if(is_holding(item_worn))
			continue

		// Check for anything covering a body part
		if(item_worn.body_parts_covered)
			// Set the success variable
			user_disrobed = TRUE

			// Drop the target item
			dropItemToGround(item_worn, FALSE)

			// Throw item to a random spot
			if(throw_clothes)
				item_worn.throw_at(pick(oview(7,get_turf(src))),10,1)

	// When successfully disrobing a target
	if(user_disrobed)
		// Display a chat message
		visible_message(span_userlove("[src] вырывается из своей одежды!"), span_userlove("Ты вырываешься из своей одежды!"), vision_distance = INTERACTION_MESSAGE_RANGE(is_hidden), visible_message_flags = INTERACTION_MESSAGE_FLAGS(is_hidden))

		// Play the ripped poster sound
		playsound(loc, 'sound/items/poster_ripped.ogg', 50, 1, INTERACTION_SOUND_EXTRARANGE(is_hidden, 0), local_only = is_hidden)
