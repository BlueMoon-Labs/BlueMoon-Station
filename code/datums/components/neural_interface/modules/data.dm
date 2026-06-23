// ---------------------------------------------------------------------------
// Neural Data Entry - Temporary data with expiration timer
// ---------------------------------------------------------------------------
/datum/neural_data_entry
	var/key
	var/value
	var/decay_duration // seconds before entry expires
	var/expiry_time // world.time when entry expires
	var/priority = 0 // higher priority = less likely to be removed when at capacity

/datum/neural_data_entry/New(duration=10 SECONDS)
	decay_duration = duration
	expiry_time = world.time + decay_duration
	return ..()

// ---------------------------------------------------------------------------
// Data Module - Data holder
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data
	name = "DATA MODULE"

	// Display configuration
	var/screen_loc = "LEFT+1.5,CENTER-2.5"
	var/maptext_width = 225
	var/maptext_height = 128
	var/separator_color = "#6b7280"
	var/font_size = 12
	var/font_family = "TinyUnicode"

	// Data entries - list of datum/neural_data_entry with expiration
	var/list/datum/neural_data_entry/data_entries = list()
	var/max_data_entries = 10
	var/atom/movable/screen/text/data_view

/datum/neural_interface_module/data/New()
	. = ..()
	data_view = ScreenText(null, "", screen_loc, maptext_height, maptext_width)

/datum/neural_interface_module/data/UpdateVision(mob/user)
	cleanup_expired_data()

	if(!user?.client)
		return

	user.client.screen -= data_view

	if(!visible)
		return

	var/write = ""
	if(data_entries.len)
		write += get_data_section()

	data_view.maptext = write
	user.client.screen += data_view

/datum/neural_interface_module/data/Destroy(force, ...)
	QDEL_NULL(data_view)
	. = ..()

/datum/neural_interface_module/data/proc/get_data_section()
	var/write = {"<span style='font-family: \"[font_family]\"; font-size: [font_size]pt; color: [separator_color]; line-height: 0.8; -dm-text-outline: 1px black;'>├─ DATA</span><br>"}

	for(var/datum/neural_data_entry/entry in data_entries)
		if(world.time < entry.expiry_time)
			write += {"<span style='font-family: \"[font_family]\"; font-size: [font_size]pt; line-height: 0.8; -dm-text-outline: 1px black;'>└ [entry.key]: [entry.value]</span><br>"}

	return {"<table width='100%' height='100%' cellpadding='0' cellspacing='0'><tr><td valign='top' align='left'><div style='height:[maptext_height]px; overflow:hidden; text-align:left;'>[write]</div></td></tr></table>"}

// ---------------------------------------------------------------------------
// Write Data Entry - Creates or updates with decay timer
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/write_data(key, value, decay_duration=3 SECONDS, priority=0)
	// Check if entry with same key already exists
	for(var/datum/neural_data_entry/entry in data_entries)
		if(entry.key == key)
			// Update existing entry - reset timer
			entry.value = value
			entry.decay_duration = decay_duration
			entry.expiry_time = world.time + decay_duration
			entry.priority = priority
			return TRUE

	// Create new entry
	var/datum/neural_data_entry/new_entry = new()
	new_entry.key = key
	new_entry.value = value
	new_entry.decay_duration = decay_duration
	new_entry.expiry_time = world.time + decay_duration
	new_entry.priority = priority

	// Remove oldest/expires-next entry if at capacity
	if(data_entries.len >= max_data_entries)
		remove_oldest_data_entry()

	data_entries += new_entry

	return TRUE

// ---------------------------------------------------------------------------
// Remove oldest data entry - lowest priority first, then earliest expiry
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/remove_oldest_data_entry()
	var/datum/neural_data_entry/target
	var/lowest_priority = INFINITY
	var/latest_expiry = INFINITY

	for(var/datum/neural_data_entry/entry in data_entries)
		if(entry.priority < lowest_priority)
			lowest_priority = entry.priority
			target = entry
			latest_expiry = entry.expiry_time
		else if(entry.priority == lowest_priority && entry.expiry_time < latest_expiry)
			// Same priority, remove the one expiring sooner
			target = entry
			latest_expiry = entry.expiry_time

	if(target)
		data_entries -= target
		QDEL_NULL(target)

// ---------------------------------------------------------------------------
// Remove specific data entry by key
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/remove_data_entry(key)
	for(var/datum/neural_data_entry/entry in data_entries)
		if(entry.key == key)
			data_entries -= entry
			QDEL_NULL(entry)
			return TRUE
	return FALSE

// ---------------------------------------------------------------------------
// Clear all data entries
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/clear_data_entries()
	for(var/datum/neural_data_entry/entry in data_entries)
		QDEL_NULL(entry)
	data_entries = list()
	return TRUE

// ---------------------------------------------------------------------------
// Cleanup expired data entries
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/cleanup_expired_data()
	var/list/to_remove = list()

	for(var/datum/neural_data_entry/entry in data_entries)
		if(world.time >= entry.expiry_time)
			to_remove += entry

	for(var/removed in to_remove)
		data_entries -= removed
		QDEL_NULL(removed)

// ---------------------------------------------------------------------------
// Get active data entries (non-expired)
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/get_active_data_entries()
	var/list/active = list()
	for(var/datum/neural_data_entry/entry in data_entries)
		if(world.time < entry.expiry_time)
			active[entry.key] = entry.value
	return active

// ---------------------------------------------------------------------------
// Check if data entry exists and is not expired
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/data_entry_exists(key)
	for(var/datum/neural_data_entry/entry in data_entries)
		if(entry.key == key && world.time < entry.expiry_time)
			return TRUE
	return FALSE

// ---------------------------------------------------------------------------
// Get data entry value by key (returns null if not found or expired)
// ---------------------------------------------------------------------------
/datum/neural_interface_module/data/proc/get_data_entry_value(key)
	for(var/datum/neural_data_entry/entry in data_entries)
		if(entry.key == key && world.time < entry.expiry_time)
			return entry.value
	return null
