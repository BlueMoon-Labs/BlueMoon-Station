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

/// Shows the item in the claw via vis_contents. Call BEFORE moving the item into the machine.
/obj/effect/big_manipulator_arm/proc/show_item(atom/movable/item)
	item_in_my_claw = WEAKREF(item)
	item.pixel_w = 32 + calculate_item_offset(is_x = TRUE)
	item.pixel_z = 32 + calculate_item_offset(is_x = FALSE)
	vis_contents += item

/// Hides the item from the claw. Call BEFORE moving the item to its final destination.
/obj/machinery/big_manipulator/proc/hide_held_item()
	var/atom/movable/resolved = held_object?.resolve()
	if(resolved)
		manipulator_arm.vis_contents -= resolved
		resolved.pixel_w = initial(resolved.pixel_w)
		resolved.pixel_z = initial(resolved.pixel_z)
	manipulator_arm.item_in_my_claw = null

/// Updates the claw state when the item changes.
/obj/machinery/big_manipulator/proc/update_claw(clawed_item)
	manipulator_arm.item_in_my_claw = clawed_item

/// Calculate x and y coordinates so that the item icon appears in the claw and not somewhere in the corner.
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
