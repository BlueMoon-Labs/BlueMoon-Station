// ---------------------------------------------------------------------------
// Image Holder - Highlight objects
// ---------------------------------------------------------------------------
/datum/image_holder_data
	var/key
	var/target_loc
	var/image/overlay
	var/atom/movable/screen/text/screen_text
	var/decay_duration
	var/expire_time
	var/enabled = TRUE
	var/font_size = 12
	var/font_family = "TinyUnicode"

/datum/image_holder_data/New(key_target, image/overlay_target, atom/target_loc_ref, text_target = "", duration=5 SECONDS, pixel_x_text=0, pixel_y_text=0, text_size=12)
	key = key_target
	target_loc = REF(target_loc_ref)
	decay_duration = duration
	expire_time = world.time + decay_duration
	font_size = text_size

	overlay = overlay_target
	overlay.loc = target_loc_ref
	overlay.plane = BYOND_LIGHTING_PLANE
	overlay.alpha = 150

	screen_text = new /atom/movable/screen/text()
	screen_text.maptext = {"<span style='font-family: \"[font_family]\"; font-size: [font_size]pt; line-height: 0.8; -dm-text-outline: 1px black;'>[text_target]</span>"}
	screen_text.maptext_height = 64
	screen_text.maptext_width = 96
	screen_text.pixel_x = pixel_x_text
	screen_text.pixel_y = pixel_y_text

	overlay.add_overlay(screen_text)

/datum/image_holder_data/proc/change_text(text)
	if(screen_text)
		screen_text.maptext = text

/datum/image_holder_data/proc/toggle()
	if(!overlay)
		return

	if(!enabled)
		overlay?.alpha = 150
		enabled = TRUE
	else
		overlay?.alpha = 0
		enabled = FALSE

/datum/image_holder_data/Destroy()
	if(screen_text)
		overlay.cut_overlay(screen_text)
		QDEL_NULL(screen_text)
	QDEL_NULL(overlay)
	target_loc = null
	return ..()


// ---------------------------------------------------------------------------
// Image Module - Image holder
// ---------------------------------------------------------------------------
/datum/neural_interface_module/image_highlight
	name = "IMAGE MODULE"
	var/list/datum/image_holder_data/image_data_entries = list()
	var/list/datum/image_holder_data/removed = list()
	var/max_image_data_entries = 20
	var/image_next_switch_time = 0
	var/image_next_switch_periodic = 2 SECONDS

/datum/neural_interface_module/image_highlight/Destroy(force, ...)
	if(owner?.host_mob)
		clean_entries(owner.host_mob)
	for(var/datum/image_holder_data/entry in image_data_entries)
		if(entry.overlay && owner?.host_mob?.client)
			owner?.host_mob?.client.images -= entry.overlay
	. = ..()


/datum/neural_interface_module/image_highlight/UpdateVision(mob/user)
	cleanup_expired_image_data()
	clean_entries(user)
	next_vision_images_data()
	for(var/datum/image_holder_data/entry in image_data_entries)
		if(entry.overlay && user?.client)
			if(visible)
				user.client.images |= entry.overlay
			else
				user.client.images -= entry.overlay

// ---------------------------------------------------------------------------
// Write Image Data Entry - Creates or replaces image with decay timer
// ---------------------------------------------------------------------------
/datum/neural_interface_module/image_highlight/proc/write_image_data(key, image/overlay, atom/target, text, decay_duration=30 SECONDS, pixel_x_text = 0, pixel_y_text = 0, text_size = 12)

	// Check if entry with same key already exists
	var/datum/image_holder_data/removed = get_image_data_entry_by_key(key)
	var/visible_image = TRUE
	if(removed)
		visible_image = removed.enabled
		remove_image_data_entry(removed)

	// Create new entry
	var/datum/image_holder_data/new_entry = new(key, overlay, target, text, decay_duration, pixel_x_text, pixel_y_text, text_size)

	if(!visible_image)
		new_entry.toggle()

	// Remove oldest/expires-next entry if at capacity
	if(image_data_entries.len > max_image_data_entries)
		remove_oldest_image_data_entry()

	image_data_entries += new_entry

	return TRUE

/datum/neural_interface_module/image_highlight/proc/get_image_data_entry_by_key(key)
	for(var/datum/image_holder_data/entry in image_data_entries)
		if(entry.key == key)
			return entry

	return FALSE

// ---------------------------------------------------------------------------
// Remove oldest image data entry - lowest priority first, then earliest expiry
// ---------------------------------------------------------------------------
/datum/neural_interface_module/image_highlight/proc/remove_oldest_image_data_entry()
	var/datum/image_holder_data/target
	var/earliest_expiry = INFINITY

	// Find entry with lowest priority (lower number = less important) and earliest expiry
	for(var/datum/image_holder_data/entry in image_data_entries)
		if(entry.expire_time < earliest_expiry)
			earliest_expiry = entry.expire_time
			target = entry

	remove_image_data_entry(target)

// ---------------------------------------------------------------------------
// Remove specific image data entry by key
// ---------------------------------------------------------------------------
/datum/neural_interface_module/image_highlight/proc/remove_image_data_entry_by_key(key)
	for(var/datum/image_holder_data/entry in image_data_entries)
		if(entry.key == key)
			removed += entry
			image_data_entries -= entry
			return TRUE
	return FALSE

/datum/neural_interface_module/image_highlight/proc/remove_image_data_entry(datum/image_holder_data/entry)
	removed += entry
	image_data_entries -= entry
	return TRUE

// ---------------------------------------------------------------------------
// Clear all image data entries
// ---------------------------------------------------------------------------
/datum/neural_interface_module/image_highlight/proc/clear_image_data_entries()
	for(var/datum/image_holder_data/entry in image_data_entries)
		remove_image_data_entry(entry)
	image_data_entries = list()
	return TRUE

// ---------------------------------------------------------------------------
// Cleanup expired image data entries
// ---------------------------------------------------------------------------
/datum/neural_interface_module/image_highlight/proc/cleanup_expired_image_data()
	for(var/datum/image_holder_data/entry in image_data_entries)
		if(world.time >= entry.expire_time)
			remove_image_data_entry(entry)

/datum/neural_interface_module/image_highlight/proc/clean_entries(mob/user)
	LAZYINITLIST(removed)
	for(var/datum/image_holder_data/entry in removed)
		if(entry.overlay && user?.client)
			user.client.images -= entry.overlay
	QDEL_NULL_LIST(removed)
	removed = list()

/datum/neural_interface_module/image_highlight/proc/next_vision_images_data()
	if(image_next_switch_time > world.time)
		return
	image_next_switch_time = world.time + image_next_switch_periodic

	var/list/map = list()
	for(var/datum/image_holder_data/entry in image_data_entries)
		LAZYINITLIST(map[entry.target_loc])
		map[entry.target_loc] += entry

	for(var/loc in map)
		var/list/datum/image_holder_data/map_entries = map[loc]
		var/lenght = map_entries.len
		if(lenght < 2)
			if(lenght == 1)
				var/datum/image_holder_data/entry = map_entries[1]
				if(!entry.enabled)
					entry.toggle()
			continue

		var/datum/image_holder_data/current_enabled
		for(var/datum/image_holder_data/entry in map_entries)
			if(entry.enabled)
				current_enabled = entry
				break
		if(!current_enabled)
			current_enabled = map_entries[1]
			current_enabled.toggle()
			continue

		var/index = map_entries.Find(current_enabled)
		if(index == lenght)
			index = 1
		else
			index += 1

		var/datum/image_holder_data/next_enabled = map_entries[index]

		if(!next_enabled.enabled)
			next_enabled.toggle()

		current_enabled.toggle()
