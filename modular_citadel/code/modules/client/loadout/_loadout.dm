// Loadout system. All items are children of /datum/gear. To make a new item, you usually just define a new item like /datum/gear/example
// then set required vars like name(string), category(slot define, take them from code/__DEFINES/inventory.dm (the lowertext ones) (be sure that there is an entry in
// slot_to_string(slot) proc in hippiestation/code/_HELPERS/mobs.dm to show the category name in preferences menu) and path (the actual item path).
// description defaults to the path initial desc, cost defaults to 1 point but if you think your item requires more points, the framework allows that
// and lastly, restricted_roles list allows you to let someone spawn with certain items only if the job they spawned with is on the list.

GLOBAL_LIST_EMPTY(loadout_items)
GLOBAL_LIST_EMPTY(loadout_whitelist_ids)

/// Fixes gear_category/gear_subcategory after navigation (same display name e.g. "Jobs" under Uniform/Suit/Head; empty item tables).
/proc/sanitize_loadout_navigation(datum/preferences/prefs)
	if(!prefs || !length(GLOB.loadout_items))
		return
	if(!GLOB.loadout_categories[prefs.gear_category])
		prefs.gear_category = GLOB.loadout_categories[1]
	var/list/subcats = GLOB.loadout_categories[prefs.gear_category]
	if(!length(subcats))
		prefs.gear_subcategory = LOADOUT_SUBCATEGORY_NONE
		return
	if(!(prefs.gear_subcategory in subcats))
		prefs.gear_subcategory = subcats[1]
	var/list/cat_items = GLOB.loadout_items[prefs.gear_category]
	if(!cat_items)
		prefs.gear_subcategory = subcats[1]
		return
	var/list/sub_items = cat_items[prefs.gear_subcategory]
	if(sub_items && length(sub_items))
		return
	for(var/sc in subcats)
		var/list/try_items = cat_items[sc]
		if(try_items && length(try_items))
			prefs.gear_subcategory = sc
			return

/proc/load_loadout_config(loadout_config)
	if(!loadout_config)
		loadout_config = "config/loadout_config.txt"
	var/list/file_lines = world.file2list(loadout_config)
	for(var/line in file_lines)
		if(!line || line[1] == "#")
			continue
		var/list/lineinfo = splittext(line, "|")
		var/lineID = lineinfo[1]
		for(var/subline in lineinfo)
			var/sublinetypedef = findtext(subline, "=")
			if(sublinetypedef)
				var/sublinetype = copytext(subline, 1, sublinetypedef)
				var/list/sublinecontent = splittext(copytext(subline, sublinetypedef+ length(sublinetypedef)), ",")
				if(sublinetype == "WHITELIST")
					GLOB.loadout_whitelist_ids["[lineID]"] = sublinecontent

/proc/initialize_global_loadout_items()
	load_loadout_config()
	for(var/item in subtypesof(/datum/gear))
		var/datum/gear/I = item
		if(!initial(I.name))
			continue
		I = new item
		LAZYINITLIST(GLOB.loadout_items[I.category])
		LAZYINITLIST(GLOB.loadout_items[I.category][I.subcategory])
		GLOB.loadout_items[I.category][I.subcategory][I.name] = I
		if(islist(I.geargroupID))
			var/list/ggidlist = I.geargroupID
			I.ckeywhitelist = list()
			for(var/entry in ggidlist)
				if(entry in GLOB.loadout_whitelist_ids)
					I.ckeywhitelist |= GLOB.loadout_whitelist_ids["[entry]"]
		else if(I.geargroupID in GLOB.loadout_whitelist_ids)
			I.ckeywhitelist = GLOB.loadout_whitelist_ids["[I.geargroupID]"]


/datum/gear
	var/name
	var/category = LOADOUT_CATEGORY_NONE
	var/subcategory = LOADOUT_SUBCATEGORY_NONE
	var/slot
	var/description
	var/atom/path //item-to-spawn path // BLUEMOON EDIT - превращено в атом чтобы адекватнее работать с иконками
	var/cost = 1 //normally, each loadout costs a single point.
	var/geargroupID //defines the ID that the gear inherits from the config
	var/loadout_flags = LOADOUT_CAN_NAME_DESC
	var/list/loadout_initial_colors = list()
	var/handle_post_equip = FALSE

	//NEW DONATOR SYTSEM STUFF
	var/donoritem				//autoset on new if null
	var/donator_group_id		//New donator group ID system.
	//END

	var/list/restricted_roles

	//Old donator system/snowflake ckey whitelist, used for single ckeys/exceptions
	var/list/ckeywhitelist
	//END

	var/restricted_desc

	// BLUEMOON EDIT START - превью для вещей в лодауте
	// Автоматически гененерируемая base64 иконка для превью в лодауте
	var/base64icon
	// Возможный оверрайд иконки
	var/item_icon = null
	// Возможный оверрайд стейта иконки
	var/item_icon_state = null
	// BLUEMOON EDIT END

/datum/gear/New()
	if(isnull(donoritem))
		if(donator_group_id || ckeywhitelist)
			donoritem = TRUE
	// BLUEMOON EDIT START - превью для вещей в лодауте
	if(!description && path)
		description = initial(path.desc)
	// BLUEMOON FIX - Wrap icon generation in try-catch to prevent initialization failures from runtime errors
	try
		var/init_icon = item_icon ? item_icon : initial(path.icon)
		var/init_icon_state = item_icon_state ? item_icon_state : initial(path.icon_state)
		CHECK_TICK
		if(init_icon && init_icon_state)
			var/static/list/loadout_icon_cache = list()
			var/cache_key = "[init_icon]:[init_icon_state]"
			if(cache_key in loadout_icon_cache)
				base64icon = loadout_icon_cache[cache_key]
			else
				base64icon = icon2base64(icon(init_icon, init_icon_state, SOUTH, 1, FALSE))
				loadout_icon_cache[cache_key] = base64icon
	catch(var/exception/e)
		stack_trace("Loadout icon generation failed for [name] ([type]): [e]")
		base64icon = null  // Item will work without preview icon
	// BLUEMOON EDIT END


//a comprehensive donator check proc is intentionally not implemented due to the fact that we (((might))) have job-whitelists for donator items in the future and I like to stay on the safe side.

//ckey only check
/datum/gear/proc/donator_ckey_check(key)
	. = TRUE
	if(donator_group_id)
		. = IS_CKEY_DONATOR_GROUP(key, donator_group_id)
	if(LAZYLEN(ckeywhitelist))
		. = . && !!ckeywhitelist.Find(key)
