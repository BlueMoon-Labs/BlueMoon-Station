// You might be wondering why this isn't client level. If focus is null, we don't want you to move.
// Only way to do that is to tie the behavior into the focus's keyLoop().

/// Calculates the movement direction from a client's held keys and pending movement buffers.
/proc/keybindings_calculate_movement_dir(list/keys_held, list/movement_keys, next_move_dir_add = NONE, next_move_dir_sub = NONE)
	var/movement_dir = NONE
	if(keys_held && keys_held["Ctrl"])
		return movement_dir

	if(keys_held && movement_keys)
		for(var/_key in keys_held)
			var/key_movement = movement_keys[_key]
			if(key_movement)
				movement_dir |= key_movement

	if(next_move_dir_add)
		movement_dir |= next_move_dir_add
	if(next_move_dir_sub)
		movement_dir &= ~next_move_dir_sub

	// Sanity checks in case you hold left and right and up to make sure you only go up.
	if((movement_dir & NORTH) && (movement_dir & SOUTH))
		movement_dir &= ~(NORTH|SOUTH)
	if((movement_dir & EAST) && (movement_dir & WEST))
		movement_dir &= ~(EAST|WEST)

	return movement_dir

/atom/movable/keyLoop(client/user)
	var/movement_dir = keybindings_calculate_movement_dir(user.keys_held, user.movement_keys, user.next_move_dir_add, user.next_move_dir_sub)

	if(user.movement_locked)
		keybind_face_direction(movement_dir)
		user.next_move_dir_add = NONE
		user.next_move_dir_sub = NONE
	else
		user.Move(get_step(src, movement_dir), movement_dir)
