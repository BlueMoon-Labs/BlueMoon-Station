// You might be wondering why this isn't client level. If focus is null, we don't want you to move.
// Only way to do that is to tie the behavior into the focus's keyLoop().

/// TRUE if at least one currently held key maps to movement.
/proc/keybindings_has_held_movement_key(list/keys_held, list/movement_keys)
	if(!keys_held || !movement_keys)
		return FALSE
	for(var/key as anything in keys_held)
		if(movement_keys[key])
			return TRUE
	return FALSE

/// Movement keys whose repeat lease has expired. A single repeat renews the
/// shared lease so holding two directions for a diagonal does not time one out:
/// desktop keyboard repeat normally belongs to only the most recently pressed key.
/proc/keybindings_expired_movement_keys(list/keys_held, list/movement_keys, last_repeat, now, timeout = MOVEMENT_KEY_REPEAT_TIMEOUT)
	. = list()
	if(isnull(last_repeat) || now < last_repeat + timeout || !keys_held || !movement_keys)
		return
	for(var/key as anything in keys_held)
		if(movement_keys[key])
			. += key

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

/// TRUE when this tick's key state has something for keyLoop to act on. Pending
/// buffers count even when they resolve to no direction, because they still have
/// to be consumed.
/proc/keybindings_has_movement_input(movement_dir, next_move_dir_add, next_move_dir_sub)
	return movement_dir || next_move_dir_add || next_move_dir_sub

/// Baseline /client/Move() would have left behind on a tick with no movement input.
///
/// Its prologue set `move_delay = world.time + world.tick_lag` before bailing out
/// on `!direction`, so an idle client's baseline stayed pinned just ahead of now.
/// Once keyLoop started skipping the call, the baseline fell into the past and
/// /client/Move()'s catch-up buffer reused it - handing the next keypress a second
/// step for free. See keybindings_idle_move_delay.dm.
/proc/keybindings_idle_move_delay(current_delay, now, tick_lag)
	if(now < current_delay)
		return current_delay // a real move's cooldown is still running, leave it
	return now + tick_lag

/atom/movable/keyLoop(client/user)
	var/movement_dir = keybindings_calculate_movement_dir(user.keys_held, user.movement_keys, user.next_move_dir_add, user.next_move_dir_sub)

	// SSinput runs this for every client on every tick. An idle client has
	// nothing to face and nothing to flush, so don't walk the whole Move() chain -
	// but do keep the movement baseline current, which is the only other thing
	// /client/Move() did on an idle tick.
	if(!keybindings_has_movement_input(movement_dir, user.next_move_dir_add, user.next_move_dir_sub))
		user.move_delay = keybindings_idle_move_delay(user.move_delay, world.time, world.tick_lag)
		return

	if(user.movement_locked)
		keybind_face_direction(movement_dir)
		user.next_move_dir_add = NONE
		user.next_move_dir_sub = NONE
	else
		user.Move(get_step(src, movement_dir), movement_dir)
