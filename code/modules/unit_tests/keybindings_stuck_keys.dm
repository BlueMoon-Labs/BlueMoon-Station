/datum/unit_test/keybindings_stuck_keys/Run()
	var/list/wasd = list(
		"W" = NORTH,
		"A" = WEST,
		"S" = SOUTH,
		"D" = EAST,
	)
	var/list/arrows = list(
		"North" = NORTH,
		"West" = WEST,
		"South" = SOUTH,
		"East" = EAST,
	)
	var/list/custom = list(
		"I" = NORTH,
		"J" = WEST,
		"K" = SOUTH,
		"L" = EAST,
		"Q" = NORTHWEST,
		"E" = NORTHEAST,
	)

	assert_direction("no held keys should not move", NONE, list(), wasd)
	assert_direction("held W keeps moving north until KeyUp clears it", NORTH, list("W"), wasd)
	assert_direction("held A moves west", WEST, list("A"), wasd)
	assert_direction("held S moves south", SOUTH, list("S"), wasd)
	assert_direction("held D moves east", EAST, list("D"), wasd)
	assert_direction("W+D combines into a northeast diagonal", NORTHEAST, list("W", "D"), wasd)
	assert_direction("W+A combines into a northwest diagonal", NORTHWEST, list("W", "A"), wasd)
	assert_direction("S+D combines into a southeast diagonal", SOUTHEAST, list("S", "D"), wasd)
	assert_direction("S+A combines into a southwest diagonal", SOUTHWEST, list("S", "A"), wasd)
	assert_direction("W+S cancel the vertical axis", NONE, list("W", "S"), wasd)
	assert_direction("A+D cancel the horizontal axis", NONE, list("A", "D"), wasd)
	assert_direction("W+S+D leaves only east", EAST, list("W", "S", "D"), wasd)
	assert_direction("A+D+W leaves only north", NORTH, list("A", "D", "W"), wasd)
	assert_direction("all four directions cancel out", NONE, list("W", "A", "S", "D"), wasd)
	assert_direction("Ctrl suppresses movement even while W is dirty", NONE, list("Ctrl", "W"), wasd)
	assert_direction("unbound keys are ignored", NONE, list("Space", "B"), wasd)
	assert_direction("bound and unbound keys can coexist", NORTH, list("W", "Space"), wasd)
	assert_direction("arrow North maps through movement_keys", NORTH, list("North"), arrows)
	assert_direction("arrow East maps through movement_keys", EAST, list("East"), arrows)
	assert_direction("arrow vertical opposites cancel", NONE, list("North", "South"), arrows)
	assert_direction("custom I+L combines into northeast", NORTHEAST, list("I", "L"), custom)
	assert_direction("custom diagonal key Q maps to northwest", NORTHWEST, list("Q"), custom)
	assert_direction("custom diagonal key E maps to northeast", NORTHEAST, list("E"), custom)
	assert_direction("pending add moves when no held key is available yet", EAST, list(), wasd, EAST)
	assert_direction("pending add combines with held key", NORTHEAST, list("W"), wasd, EAST)
	assert_direction("pending sub removes a dirty held key direction", NONE, list("W"), wasd, NONE, NORTH)
	assert_direction("pending sub removes one axis from a diagonal", NORTH, list("W", "D"), wasd, NONE, EAST)
	assert_direction("pending add and sub resolve together", EAST, list("W"), wasd, EAST, NORTH)
	assert_direction("pending opposite add still goes through axis cancellation", NONE, list("W"), wasd, SOUTH)
	assert_direction("pending horizontal opposite add cancels the axis", NONE, list("A"), wasd, EAST)
	assert_direction("null held-key list is treated as empty", NONE, null, wasd)
	assert_direction("null movement map still allows pending add", SOUTH, list("W"), null, SOUTH)

	var/list/stuck_key = held_keys_from(list("W"))
	TEST_ASSERT_EQUAL(keybindings_calculate_movement_dir(stuck_key, wasd), NORTH, "dirty W in keys_held should keep producing NORTH")
	stuck_key -= "W"
	TEST_ASSERT_EQUAL(keybindings_calculate_movement_dir(stuck_key, wasd), NONE, "removing W should stop movement")

	// Lost KeyUp recovery is lease based: a live repeat protects every held
	// movement direction (including the non-repeating half of a diagonal), then
	// expiry selects only movement and leaves modifiers/actions alone.
	var/list/leased_keys = list("W" = 80, "D" = 90, "Shift" = 70)
	TEST_ASSERT(keybindings_has_held_movement_key(leased_keys, wasd), "W+D must be recognized as held movement")
	TEST_ASSERT(!length(keybindings_expired_movement_keys(leased_keys, wasd, 90, 90 + MOVEMENT_KEY_REPEAT_TIMEOUT - 1)), "movement lease must remain live before its timeout")
	var/list/expired = keybindings_expired_movement_keys(leased_keys, wasd, 90, 90 + MOVEMENT_KEY_REPEAT_TIMEOUT)
	TEST_ASSERT_EQUAL(length(expired), 2, "expired lease must select both held movement keys")
	TEST_ASSERT("W" in expired, "expired lease must release W")
	TEST_ASSERT("D" in expired, "expired lease must release D")
	TEST_ASSERT(!("Shift" in expired), "expired lease must not release non-movement keys")
	TEST_ASSERT(!length(keybindings_expired_movement_keys(leased_keys, wasd, null, 1000)), "missing lease must not expire unrelated legacy state")

	// Native macro repeat renews the same lease. Explicit commands retain
	// precedence, and classic input gets repeat only for keys already accepted
	// while the chat box is focused.
	var/list/hotkey_macros = list("Any" = "any", "Tab" = "toggle-input")
	keybindings_add_movement_repeat_macros(hotkey_macros, list("W" = NORTH, "Tab" = EAST), TRUE)
	TEST_ASSERT_EQUAL(hotkey_macros["W+REP"], "\"KeyRepeat W\"", "hotkey movement must receive a repeat keepalive")
	TEST_ASSERT_EQUAL(hotkey_macros["W+UP"], "\"KeyUp W\"", "hotkey movement must receive an explicit release")
	TEST_ASSERT(!hotkey_macros["Tab+REP"], "movement repeat must not override an explicit macro")
	TEST_ASSERT(!hotkey_macros["Tab+UP"], "movement release must not override an explicit macro")
	var/list/classic_input_macros = list("North" = "\"KeyDown North\"")
	keybindings_add_movement_repeat_macros(classic_input_macros, list("W" = NORTH, "North" = NORTH), FALSE)
	TEST_ASSERT_EQUAL(classic_input_macros["North+REP"], "\"KeyRepeat North\"", "classic arrow movement must receive a repeat keepalive")
	TEST_ASSERT_EQUAL(classic_input_macros["North+UP"], "\"KeyUp North\"", "classic arrow movement must receive an explicit release")
	TEST_ASSERT(!classic_input_macros["W+REP"], "classic input must leave typed letters alone")
	TEST_ASSERT(!classic_input_macros["W+UP"], "classic input must not capture typed-letter releases")

/// SSinput drives keyLoop for every client on every tick — 425k calls in six
/// minutes of round 9800, of which only 15k produced an actual mob move. The
/// loop now skips the whole Move() chain when there is nothing to act on, which
/// is only correct if the pending-direction buffers are still counted as input:
/// a pending sub can cancel the held keys down to NONE and would otherwise never
/// be flushed.
/datum/unit_test/keybindings_movement_input_gate/Run()
	TEST_ASSERT(!keybindings_has_movement_input(NONE, NONE, NONE), "An idle client with no held keys has nothing to do")
	TEST_ASSERT(keybindings_has_movement_input(NORTH, NONE, NONE), "A held direction is movement input")
	TEST_ASSERT(keybindings_has_movement_input(NONE, EAST, NONE), "A pending add must still be flushed")
	TEST_ASSERT(keybindings_has_movement_input(NONE, NONE, NORTH), "A pending sub must still be flushed even though it resolves to NONE")
	TEST_ASSERT(keybindings_has_movement_input(NORTH, EAST, WEST), "Held keys plus pending buffers is movement input")

/datum/unit_test/keybindings_stuck_keys/proc/assert_direction(test_name, expected_direction, list/pressed_keys, list/movement_keys, next_move_dir_add = NONE, next_move_dir_sub = NONE)
	var/actual_direction = keybindings_calculate_movement_dir(held_keys_from(pressed_keys), movement_keys, next_move_dir_add, next_move_dir_sub)
	TEST_ASSERT_EQUAL(actual_direction, expected_direction, test_name)

/datum/unit_test/keybindings_stuck_keys/proc/held_keys_from(list/pressed_keys)
	var/list/held_keys = list()
	for(var/key in pressed_keys)
		held_keys[key] = TRUE
	return held_keys
