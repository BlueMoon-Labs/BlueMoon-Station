/datum/spawners_menu
	var/mob/dead/observer/owner

/datum/spawners_menu/New(mob/dead/observer/new_owner)
	if(!istype(new_owner))
		qdel(src)
	owner = new_owner

/datum/spawners_menu/ui_state(mob/user)
	return GLOB.observer_state

/datum/spawners_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SpawnersMenu")
		ui.open()

/datum/spawners_menu/ui_data(mob/user)
	if(QDELETED(GLOB.antag_training_spawner))
		GLOB.antag_training_spawner = new /obj/effect/mob_spawn/antag_training(null)
	var/datum/antag_training_arena/shared = GLOB.antag_training_arenas["shared"]
	var/list/data = list()
	data["spawners"] = list()
	for(var/spawner in GLOB.mob_spawners)
		var/list/spawner_objs = GLOB.mob_spawners[spawner]
		// del() контейнера удаляет лежащий в нём спавнер без Destroy(), и в списке остаётся null.
		if(spawner_objs)
			listclearnulls(spawner_objs)
		if(!length(spawner_objs))
			GLOB.mob_spawners -= spawner
			continue
		var/list/this = list()
		this["name"] = spawner
		this["short_desc"] = ""
		this["flavor_text"] = ""
		this["important_warning"] = ""
		this["category"] = ""
		this["refs"] = list()
		this["can_jump"] = FALSE
		var/amount_left = 0
		for(var/obj/spawner_obj in spawner_objs)
			if(QDELETED(spawner_obj))
				continue
			amount_left++
			if(get_turf(spawner_obj) || (istype(spawner_obj, /obj/effect/mob_spawn/antag_training) && shared?.ready))
				this["can_jump"] = TRUE
			this["refs"] += "[REF(spawner_obj)]"
			if(!this["desc"])
				if(istype(spawner_obj, /obj/effect/mob_spawn))
					var/obj/effect/mob_spawn/MS = spawner_obj
					this["short_desc"] = strip_html_tags(MS.short_desc)
					this["flavor_text"] = strip_html_tags(MS.flavour_text)
					this["important_info"] = strip_html_tags(MS.important_info)
					this["category"] = MS.category
					this["can_load_appearance"] = MS.can_load_appearance
				else
					var/obj/O = spawner_obj
					this["desc"] = strip_html_tags(O.desc)
		if(!amount_left)
			continue
		this["amount_left"] = amount_left
		data["spawners"] += list(this)

	return data

/datum/spawners_menu/ui_act(action, params)
	if(..())
		return

	var/group_name = params["name"]
	if(!group_name || !(group_name in GLOB.mob_spawners))
		return
	var/list/spawnerlist = list()
	for(var/obj/effect/mob_spawn/candidate in GLOB.mob_spawners[group_name])
		if(!QDELETED(candidate))
			spawnerlist += candidate
	if(!length(spawnerlist))
		return
	var/obj/effect/mob_spawn/MS = pick(spawnerlist)
	if(!(MS in GLOB.poi_list))
		return
	switch(action)
		if("jump")
			var/turf/destination = get_turf(MS)
			if(istype(MS, /obj/effect/mob_spawn/antag_training))
				var/datum/antag_training_arena/shared = GLOB.antag_training_arenas["shared"]
				destination = shared?.ready ? shared.entry_turf : null
			if(destination)
				owner.forceMove(destination)
				. = TRUE
		if("spawn")
			if(MS)
				MS.attack_ghost(owner)
				. = TRUE
