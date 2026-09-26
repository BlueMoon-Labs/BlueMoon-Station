/datum/evolution_store
	var/name = "Evolution store"
	var/data
	var/datum/antagonist/living_latex/living_latex

/datum/evolution_store/New(my_living_latex)
	. = ..()
	living_latex = my_living_latex

/datum/evolution_store/Destroy()
	living_latex = null
	. = ..()

/datum/evolution_store/ui_state(mob/user)
	return GLOB.always_state

/datum/evolution_store/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EvolveShop", name)
		ui.open()

/datum/evolution_store/ui_data(mob/user)
	var/list/data = list()

	var/list/abilities = list()

	for(var/datum/action/cooldown/latexmob/ability in living_latex.only_for_ui_abilities_list)
		var/stage_required = initial(ability.stage_required)
		var/ability_icon = icon(ability.icon_icon, ability.button_icon_state)
		var/ability_icon_64 = icon2base64(ability_icon)
		var/list/AL = list()
		AL["name"] = initial(ability.name)
		AL["desc"] = initial(ability.desc)
		AL["icon"] = initial(ability_icon_64)
		AL["stage_required"] = initial(stage_required)
		AL["can_purchase"] = (living_latex.stage >= ability.stage_required)

		abilities += list(AL)

		data["abilities"] = abilities
		data["current_stage"] = living_latex.stage
		data["current_evolve_points"] = living_latex.evolve_points

	return data

/datum/evolution_store/ui_act(action, params)
	if(..())
		return

	if(action == "evolve")
		var/ability_name = params["abilityName"]
		living_latex.search_ability_name(ability_name)

	if(action == "evolve_to_stage")
		var/target_stage = params["stage"]
		if(living_latex.stage < target_stage)
			living_latex.upgrade_stage(target_stage)

/datum/action/cooldown/latexmob/evolution_store
	name = "Evolution Store"
	icon_icon = 'modular_bluemoon/horny_venom/icons/latex_abilities.dmi'
	button_icon = 'modular_bluemoon/horny_venom/icons/latex_abilities.dmi'
	background_icon_state = "background"
	button_icon_state = "shop"
	var/datum/evolution_store/evolution

/datum/action/cooldown/latexmob/evolution_store/New()
	. = ..()
	var/datum/antagonist/living_latex/living_latex = locate(/datum/antagonist/living_latex) in usr.mind.antag_datums
	evolution = living_latex.evolution_store
	if(!evolution)
		CRASH("evolution_store action created with non store")

/datum/action/cooldown/latexmob/evolution_store/Activate()
	evolution.ui_interact(usr)
