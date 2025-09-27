/datum/orbit_menu
	var/mob/dead/observer/owner
	var/auto_observe = FALSE
	var/compact_mode = TRUE // BLUEMOON ADD - компактный режим без ненужной информации

/datum/orbit_menu/New(mob/dead/observer/new_owner)
	if(!istype(new_owner))
		qdel(src)
	owner = new_owner

/datum/orbit_menu/ui_state(mob/user)
	return GLOB.observer_state

/datum/orbit_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "Orbit")
		ui.open()

/datum/orbit_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if (..())
		return

	switch(action)
		if ("orbit")
			var/ref = params["ref"]
			var/atom/movable/poi = (locate(ref) in GLOB.mob_list) || (locate(ref) in GLOB.poi_list)
			if (poi == null)
				. = TRUE
				return
			owner.ManualFollow(poi)
			owner.reset_perspective(null)
			if (auto_observe)
				owner.do_observe(poi)
			. = TRUE
		if ("refresh")
			update_static_data(owner, ui)
			. = TRUE
		if ("toggle_observe")
			auto_observe = !auto_observe
			if (auto_observe && owner.orbit_target)
				owner.do_observe(owner.orbit_target)
			else
				owner.reset_perspective(null)
		// BLUEMOON ADD START - компактный режим без ненужной информации
		if ("toggle_compact_mode")
			compact_mode = !compact_mode
			update_static_data(owner, ui)
			. = TRUE
		// BLUEMOON ADD END

/datum/orbit_menu/ui_data(mob/user)
	var/list/data = list()
	data["auto_observe"] = auto_observe
	data["compact_mode"] = compact_mode // BLUEMOON ADD - компактный режим без ненужной информации
	return data

// BLUEMOON EDIT START - правки орбита. В основном, изменение отображения гостролей
/datum/orbit_menu/ui_static_data(mob/user)
	var/list/data = list()
	var/list/alive = list()
	var/list/antagonists = list()
	var/list/dead = list()
	var/list/dead_players = list()
	var/list/ghosts = list()
	var/list/misc = list()
	var/list/npcs = list()
	var/list/ghost_roles = list()

	var/list/pois = getpois(mobs_only = compact_mode, skip_mindless = !compact_mode, specify_dead_role = FALSE)
	for (var/name in pois)
		var/list/serialized = list()
		serialized["name"] = name

		var/poi = pois[name]

		serialized["ref"] = REF(poi)

		var/mob/M = poi
		if (istype(M))
			if (isobserver(M))
				ghosts += list(serialized)
			else if (M.mind == null && M.stat == DEAD && !compact_mode)
				dead += list(serialized)
			else if (M.mind && M.stat == DEAD)
				dead_players += list(serialized)
			else if (M.mind == null)
				if(!compact_mode)
					npcs += list(serialized)
			else
				var/number_of_orbiters = M.orbiters?.orbiters?.len
				if (number_of_orbiters)
					serialized["orbiters"] = number_of_orbiters

				var/datum/mind/mind = M.mind
				var/was_special = FALSE

				for (var/_A in mind.antag_datums)
					var/datum/antagonist/A = _A
					var/mob/dead/observer/O = user
					if(istype(A, /datum/antagonist/ghost_role))
						was_special = TRUE
						serialized["role"] = A.name
						ghost_roles += list(serialized)
						break // Я не верю, что гострольки могут быть антагами. Не хочу верить...
					else if (A?.show_to_ghosts || !O?.can_reenter_corpse)
						was_special = TRUE
						serialized["antag"] = A.name
						antagonists += list(serialized)
						break

				var/assignment = "no_id"

				if(ishuman(M)) // Владос уверяет, что это уменьшит лишние такты процессору
					var/obj/item/card/id/card = M.get_idcard()
					if(card)
						assignment = "[ckey(card.get_job_name())]"

				else if(issilicon(M) || isdrone(M)) // Для отображения иконок силиконов в orbit
					if(iscyborg(M))
						assignment = "cyborg"
					else if(isdrone(M))
						assignment = "drone"
					else if(ispAI(M))
						assignment = "pai"
					else if(isAI(M))
						assignment = "ai"

				else if(isalien(M))
					assignment = "alien"

				else if(ishostile(M))
					if(isterrorspider(M))
						assignment = "terrorspider"
					else if(isswarmer(M))
						assignment = "swarmer"

				serialized["assignment"] = assignment

				if (!was_special)
					alive += list(serialized)
		else if(!compact_mode)
			misc += list(serialized)

	data["alive"] = alive
	data["antagonists"] = antagonists
	data["dead"] = dead
	data["dead_players"] = dead_players
	data["ghosts"] = ghosts
	data["misc"] = misc
	data["npcs"] = npcs
	data["ghost_roles"] = ghost_roles

	return data
// BLUEMOON EDIT END

/datum/orbit_menu/ui_assets()
	. = ..() || list()
	. += get_asset_datum(/datum/asset/simple/orbit)
	. += get_asset_datum(/datum/asset/spritesheet/jobs)
