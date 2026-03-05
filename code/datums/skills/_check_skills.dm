// yeah yeah verbs suck whatever I suck at this fix this someone please - kevinz000

/mob/verb/check_skills()
	set name = "Check Skills"
	set category = "IC"
	set desc = "Check your skills (if you have any..)"

	if(!mind)
		to_chat(usr, "<span class='warning'>How do you check the skills of [(usr == src)? "yourself when you are" : "something"] without a mind?</span>")
		return
	if(!mind.skill_holder)
		to_chat(usr, "<span class='warning'>How do you check the skills of [(usr == src)? "yourself when you are" : "something"] without the capability for skills? (PROBABLY A BUG, PRESS F1.)</span>")
		return

	mind.skill_holder.ui_interact(src)

/datum/skill_holder/ui_state(mob/user)
	return GLOB.always_state

/datum/skill_holder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SkillPanel", "[owner.name]'s Skills")
		ui.set_autoupdate(FALSE)
		ui.open()
	else if(need_static_data_update)
		update_static_data(user)
		need_static_data_update = FALSE

/datum/skill_holder/ui_static_data(mob/user)
	. = list()
	.["skills"] = list()

	// Добавляем обычные навыки
	for(var/path in GLOB.skill_datums)
		var/datum/skill/S = GLOB.skill_datums[path]
		var/list/dat = S.get_skill_data(src)
		if(islist(dat["modifiers"]))
			dat["modifiers"] = jointext(dat["modifiers"], ", ")
		dat["percent_base"] = (dat["value_base"] / dat["max_value"])
		dat["percent_mod"] = (dat["value_mod"] / dat["max_value"])
		.["skills"] += list(dat)

	// Добавляем Research skill если у персонажа есть TRAIT
	if(owner?.current && HAS_TRAIT(owner.current, TRAIT_KNOWS_RESEARCH))
		var/list/research_data = get_research_skill_data()
		.["skills"] += list(research_data)

/datum/skill_holder/proc/get_research_skill_data()
	var/list/data = list()
	data["name"] = "Research"
	data["desc"] = "Your ability to conduct experimental research and craft advanced technology using shapes"
	data["path"] = "/datum/skill/research"

	var/exp_value = owner?.research_exp || 0

	data["value_base"] = exp_value
	data["value_mod"] = exp_value

	var/current_level = round(exp_value / 20)
	data["max_value"] = 100
	data["level_based"] = TRUE
	data["lvl_base_num"] = current_level
	data["lvl_mod_num"] = current_level

	switch(current_level)
		if(0)
			data["lvl_base"] = "Novice"
		if(1)
			data["lvl_base"] = "Apprentice"
		if(2)
			data["lvl_base"] = "Researcher"
		if(3)
			data["lvl_base"] = "Advanced Researcher"
		if(4)
			data["lvl_base"] = "Expert Researcher"
		else
			data["lvl_base"] = "Master Researcher"

	data["lvl_mod"] = data["lvl_base"]

	if(current_level >= 5)
		data["xp_next_lvl_base"] = "MAXED"
	else
		var/xp_in_level = exp_value - (current_level * 20)
		data["xp_next_lvl_base"] = "\[[xp_in_level]/20\]"

	data["xp_next_lvl_mod"] = data["xp_next_lvl_base"]

	if(current_level < 3)
		data["base_readout"] = "Basic items only. Level 3 unlocks advanced item chance."
	else if(current_level < 5)
		data["base_readout"] = "50% chance for advanced items. Level 5 unlocks guaranteed advanced items."
	else
		data["base_readout"] = "Always creates advanced versions!"

	data["mod_readout"] = data["base_readout"]
	data["percent_base"] = (exp_value / 100.0)
	data["percent_mod"] = data["percent_base"]
	data["modifiers"] = "None"

	return data

/datum/skill_holder/ui_data(mob/user)
	. = list()
	.["playername"] = owner.name
	.["see_skill_mods"] = see_skill_mods
	.["admin"] = check_rights(R_DEBUG, FALSE)

/datum/skill_holder/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle_mods")
			see_skill_mods = !see_skill_mods
			return TRUE
		if ("adj_exp")
			if(!check_rights(R_DEBUG))
				return
			var/skill = text2path(params["skill"])
			var/number = input("Please insert the amount of experience/progress you'd like to add/subtract:") as num|null
			if (number)
				owner.set_skill_value(skill, owner.get_skill_value(skill, FALSE) + number)
			return TRUE
		if ("set_exp")
			if(!check_rights(R_DEBUG))
				return
			var/skill = text2path(params["skill"])
			var/number = input("Please insert the number you want to set the player's exp/progress to:") as num|null
			if (!isnull(number))
				owner.set_skill_value(skill, number)
			return TRUE
		if ("set_lvl")
			if(!check_rights(R_DEBUG))
				return
			var/datum/skill/level/S = GLOB.skill_datums[text2path(params["skill"])]
			var/number = input("Please insert a whole number between 0[S.associative ? " ([S.unskilled_tier])" : ""] and [S.max_levels][S.associative ? " ([S.levels[S.max_levels]])" : ""] corresponding to the level you'd like to set the player to.") as num|null
			if (number >= 0 && number <= S.max_levels)
				owner.set_skill_value(S.type, S.get_skill_level_value(number))
			return TRUE
