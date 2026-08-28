/// Manipulator hand. Effect we animate to show that the manipulator is working and moving something.
/obj/effect/big_manipulator_arm
	name = "mechanical claw"
	desc = "Takes and drops objects."
	icon = 'modular_bluemoon/icons/obj/machines/big_manipulator_parts/big_manipulator_hand.dmi'
	icon_state = "hand"
	layer = LOW_ITEM_LAYER
	appearance_flags = KEEP_TOGETHER | LONG_GLIDE
	anchored = TRUE
	pixel_x = -32
	pixel_y = -32
	/// Current rotation angle of the arm.
	var/arm_angle = 0
	/// Weakref to the item currently held in the claw.
	var/datum/weakref/item_in_my_claw
	/// The overlay showing the held item.
	var/mutable_appearance/held_item_overlay

/// Shows the item in the claw as an overlay copy. Hides the original sprite.
/obj/effect/big_manipulator_arm/proc/show_item(atom/movable/item)
	item_in_my_claw = WEAKREF(item)
	item.invisibility = INVISIBILITY_ABSTRACT
	held_item_overlay = mutable_appearance(icon = item.icon, icon_state = item.icon_state, layer = item.layer, plane = item.plane)
	held_item_overlay.color = item.color
	held_item_overlay.alpha = item.alpha
	held_item_overlay.pixel_x = 32 + calculate_item_offset(is_x = TRUE)
	held_item_overlay.pixel_y = 32 + calculate_item_offset(is_x = FALSE)
	overlays += held_item_overlay

/// Removes the held item overlay and restores the original item sprite.
/obj/machinery/big_manipulator/proc/hide_held_item()
	var/atom/movable/resolved = held_object?.resolve()
	if(resolved)
		resolved.invisibility = initial(resolved.invisibility)
	manipulator_arm.hide_item_overlay()

/// Removes the overlay from the arm.
/obj/effect/big_manipulator_arm/proc/hide_item_overlay()
	if(held_item_overlay)
		overlays -= held_item_overlay
		held_item_overlay = null
	item_in_my_claw = null

/// Updates the claw state when the item changes.
/obj/machinery/big_manipulator/proc/update_claw(clawed_item)
	manipulator_arm.item_in_my_claw = clawed_item

/// Calculate x and y coordinates so that the item icon appears in the claw.
/obj/effect/big_manipulator_arm/proc/calculate_item_offset(is_x = TRUE, pixels_to_offset = 32)
	var/offset
	switch(dir)
		if(NORTH)
			offset = is_x ? 0 : pixels_to_offset
		if(SOUTH)
			offset = is_x ? 0 : -pixels_to_offset
		if(EAST)
			offset = is_x ? pixels_to_offset : 0
		if(WEST)
			offset = is_x ? -pixels_to_offset : 0
	return offset
