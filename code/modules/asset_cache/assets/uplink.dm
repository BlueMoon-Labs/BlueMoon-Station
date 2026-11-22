// спрайтшит превьюшек для аплинка. За основу взят spawnpanel из spawn_panel\assets.dm
#define UPLINK_PREVIEW_SIZE 32

GLOBAL_LIST_EMPTY(uplink_icon_map)

/datum/asset/spritesheet_batched/uplink
	name = "uplink"
/datum/asset/spritesheet_batched/uplink/create_spritesheets()
	var/list/icon_dedup = list()
	var/list/scale_cache = list()
	var/counter = 0

	for(var/datum/uplink_item/I as anything in typesof(/datum/uplink_item))
		var/item_value = initial(I.item)
		if(!ispath(item_value, /atom))
			continue

		var/atom/item_path = item_value
		var/icon_file = initial(item_path.icon)

		if(!icon_file || copytext("[icon_file]", -4) != ".dmi")
			continue

		var/icon_state = initial(item_path.icon_state)
		if(!istext(icon_state) || !(icon_state in icon_states(icon_file)))
			continue

		var/cache_key = "[icon_file]|[icon_state]"
		var/imgid = icon_dedup[cache_key]
		if(!imgid)
			imgid = "up[counter]"
			var/datum/universal_icon/entry = uni_icon(icon_file, icon_state)
			var/needs_scale = scale_cache[icon_file]
			if(isnull(needs_scale))
				var/list/dimensions = dmi_frame_dimensions(icon_file)
				needs_scale = isnull(dimensions) || dimensions["width"] != UPLINK_PREVIEW_SIZE || dimensions["height"] != UPLINK_PREVIEW_SIZE
				scale_cache[icon_file] = needs_scale
			if(needs_scale)
				entry.scale(UPLINK_PREVIEW_SIZE, UPLINK_PREVIEW_SIZE)
			insert_icon(imgid, entry)
			counter++
			icon_dedup[cache_key] = imgid
		GLOB.uplink_icon_map["[item_path]"] = imgid

#undef UPLINK_PREVIEW_SIZE
