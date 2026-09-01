// Clients aren't datums so we have to define these procs indpendently.
// These verbs are called for all key press and release events
/client/verb/keyDown(_key as text)
	SHOULD_NOT_SLEEP(TRUE)
	set instant = TRUE
	set hidden = TRUE

	client_keysend_amount += 1
	last_activity = world.time

	var/cache = client_keysend_amount

	if(keysend_tripped && next_keysend_trip_reset <= world.time)
		keysend_tripped = FALSE

	if(next_keysend_reset <= world.time)
		client_keysend_amount = 0
		next_keysend_reset = world.time + (1 SECONDS)

	//The "tripped" system is to confirm that flooding is still happening after one spike
	//not entirely sure how byond commands interact in relation to lag
	//don't want to kick people if a lag spike results in a huge flood of commands being sent
	if(cache >= MAX_KEYPRESS_AUTOKICK)
		if(!keysend_tripped)
			keysend_tripped = TRUE
			next_keysend_trip_reset = world.time + (2 SECONDS)
		else
			log_admin("Client [ckey] was just autokicked for flooding keysends; likely abuse but potentially lagspike.")
			message_admins("Client [ckey] was just autokicked for flooding keysends; likely abuse but potentially lagspike.")
			qdel(src)
			return

	///Check if the key is short enough to even be a real key
	if(LAZYLEN(_key) > MAX_KEYPRESS_COMMANDLENGTH)
		to_chat(src, "<span class='userdanger'>Invalid KeyDown detected! You have been disconnected from the server automatically.</span>")
		log_admin("Client [ckey] just attempted to send an invalid keypress. Keymessage was over [MAX_KEYPRESS_COMMANDLENGTH] characters, autokicking due to likely abuse.")
		message_admins("Client [ckey] just attempted to send an invalid keypress. Keymessage was over [MAX_KEYPRESS_COMMANDLENGTH] characters, autokicking due to likely abuse.")
		qdel(src)
		return

	if(_key == "Tab")
		ForceAllKeysUp()		//groan, more hacky kevcode
		return

	if(length(keys_held) >= MAX_HELD_KEYS && !(_key in keys_held))
		keyUp(keys_held[1])
	var/was_held = (_key in keys_held)
	keys_held[_key] = world.time
	var/movement = movement_keys[_key]
	if(movement)
		last_movement_key_repeat = world.time
	// Native +REP and browser auto-repeat are keepalives. A held key has already
	// run its bindings and only needs to renew the movement lease.
	if(was_held)
		return
	if(movement && !was_held && !(next_move_dir_sub & movement) && !keys_held["Ctrl"])
		next_move_dir_add |= movement

	// Client-level keybindings are ones anyone should be able to do at any time
	// Things like taking screenshots, hitting tab, and adminhelps.
	var/AltMod = keys_held["Alt"] ? "Alt" : ""
	var/CtrlMod = keys_held["Ctrl"] ? "Ctrl" : ""
	var/ShiftMod = keys_held["Shift"] ? "Shift" : ""
	var/full_key
	switch(_key)
		if("Alt", "Ctrl", "Shift")
			full_key = "[AltMod][CtrlMod][ShiftMod]"
		else
			full_key = "[AltMod][CtrlMod][ShiftMod][_key]"
	var/keycount = 0
	if(prefs.modless_key_bindings[_key])
		var/datum/keybinding/kb = GLOB.keybindings_by_name[prefs.modless_key_bindings[_key]]
		if(kb.can_use(src))
			kb.down(src)
			keycount++
	for(var/kb_name in prefs.key_bindings[full_key])
		keycount++
		var/datum/keybinding/kb = GLOB.keybindings_by_name[kb_name]
		if(kb.can_use(src) && kb.down(src) && keycount >= MAX_COMMANDS_PER_KEY)
			break

	holder?.key_down(_key, src, full_key)
	mob?.focus?.key_down(_key, src, full_key)
	mob?.update_mouse_pointer()

/// Receives legitimate native/TGUI key-repeat events without feeding them into
/// the KeyDown flood counter. The first event still uses normal KeyDown so an
/// invented repeat cannot create held state or bypass its validation.
/client/verb/keyRepeat(_key as text)
	SHOULD_NOT_SLEEP(TRUE)
	set instant = TRUE
	set hidden = TRUE

	if(!(_key in keys_held))
		keyDown(_key)
		return
	last_activity = world.time
	keys_held[_key] = world.time
	if(movement_keys[_key])
		last_movement_key_repeat = world.time

/// Keyup's all keys held down, including modifier keys.
/client/proc/ForceAllKeysUp()
	for(var/key in keys_held.Copy())
		keyUp("[key]")

/client/verb/keyUp(_key as text)
	SHOULD_NOT_SLEEP(TRUE)
	set instant = TRUE
	set hidden = TRUE

	// TGUI/WebView can duplicate orphaned KeyUp events when focus changes; only real releases should touch the movement buffer.
	var/was_held = (_key in keys_held)
	if(!was_held)
		return
	keys_held -= _key
	last_activity = world.time
	var/movement = movement_keys[_key]
	if(movement && was_held && !(next_move_dir_add & movement))
		next_move_dir_sub |= movement
	if(movement && !keybindings_has_held_movement_key(keys_held, movement_keys))
		last_movement_key_repeat = null

	if(prefs.modless_key_bindings[_key])
		var/datum/keybinding/kb = GLOB.keybindings_by_name[prefs.modless_key_bindings[_key]]
		if(kb.can_use(src))
			kb.up(src)

	// We don't do full key for release, because for mod keys you
	// can hold different keys and releasing any should be handled by the key binding specifically
	for(var/kb_name in prefs.key_bindings[_key])
		var/datum/keybinding/kb = GLOB.keybindings_by_name[kb_name]
		if(kb.can_use(src))
			kb.up(src)
	holder?.key_up(_key, src)
	mob?.focus?.key_up(_key, src)
	mob?.update_mouse_pointer()

// Called every game tick
/client/keyLoop()
	release_expired_movement_keys()
	holder?.keyLoop(src)
	mob?.focus?.keyLoop(src)

/// Releases movement whose KeyUp vanished when DreamSeeker lost focus. Other held
/// actions and modifiers keep their ordinary down/up lifetime.
/client/proc/release_expired_movement_keys(now = world.time)
	var/list/expired_keys = keybindings_expired_movement_keys(keys_held, movement_keys, last_movement_key_repeat, now)
	if(!length(expired_keys))
		return FALSE
	for(var/key as anything in expired_keys)
		keyUp(key)
	last_movement_key_repeat = null
	log_game("INPUT: [key_name(src)] force-released stale movement key(s): [expired_keys.Join(", ")].")
	return TRUE
