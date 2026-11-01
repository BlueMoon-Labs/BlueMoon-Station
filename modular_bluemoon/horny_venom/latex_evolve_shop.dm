/datum/evolution_store
	var/name = "Evolution store"
	var/datum/antagonist/living_latex/living_latex

/datum/evolution_store/New(datum/antagonist/living_latex/latex)
	. = ..()
	living_latex = latex

/datum/evolution_store/Destroy()
	SStgui.close_uis(src)
	living_latex = null
	return ..()

/datum/evolution_store/ui_state(mob/user)
	return GLOB.always_state

/datum/evolution_store/ui_status(mob/user)
	return !QDELETED(living_latex) && user == living_latex.owner?.current ? UI_INTERACTIVE : UI_CLOSE

/datum/evolution_store/ui_interact(mob/user, datum/tgui/ui)
	if(ui_status(user) != UI_INTERACTIVE)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EvolveShop", name)
		ui.open()

/datum/evolution_store/ui_data(mob/user)
	var/list/abilities = list()
	for(var/path in living_latex.all_abilities)
		var/datum/action/cooldown/latexmob/template = path
		var/datum/action/cooldown/latexmob/owned = living_latex.get_ability_by_path(path)
		var/can_purchase = living_latex.stage >= initial(template.stage_required) && living_latex.evolve_points >= initial(template.points_need_to_purchase)
		if(owned)
			can_purchase = owned.stage < min(living_latex.stage, owned.finall_stage) && living_latex.evolve_points >= owned.points_need_to_upgrade
		var/ability_icon = owned ? owned.icon_icon : initial(template.icon_icon)
		var/ability_state = owned ? owned.button_icon_state : initial(template.button_icon_state)
		abilities += list(list(
			"name" = initial(template.name),
			"desc" = initial(template.desc),
			"icon" = icon2base64(icon(ability_icon, ability_state)),
			"stage_required" = initial(template.stage_required),
			"can_purchase" = can_purchase,
		))
	return list("abilities" = abilities, "current_stage" = living_latex.stage, "current_evolve_points" = living_latex.evolve_points)

/datum/evolution_store/ui_act(action, list/params)
	if(..() || ui_status(usr) != UI_INTERACTIVE)
		return FALSE
	switch(action)
		if("evolve")
			return living_latex.search_ability_name(params["abilityName"])
		if("evolve_to_stage")
			return living_latex.upgrade_stage(params["stage"])
	return FALSE

/datum/action/cooldown/latexmob/evolution_store
	name = "Evolution Store"
	button_icon_state = "shop"

/datum/action/cooldown/latexmob/evolution_store/Activate()
	if(!..())
		return FALSE
	my_living_latex.evolution_store.ui_interact(owner)
	return TRUE

/datum/inject_menu
	var/name = "Введение реагентов"
	var/datum/antagonist/living_latex/living_latex
	var/next_injection = 0

/datum/inject_menu/New(datum/antagonist/living_latex/latex)
	. = ..()
	living_latex = latex

/datum/inject_menu/Destroy()
	SStgui.close_uis(src)
	living_latex = null
	return ..()

/datum/inject_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/inject_menu/ui_status(mob/user)
	return !QDELETED(living_latex) && user == living_latex.owner?.current ? UI_INTERACTIVE : UI_CLOSE

/datum/inject_menu/proc/subject()
	return living_latex.host_organ?.owner || living_latex.owner?.current

/datum/inject_menu/ui_data(mob/user)
	var/list/reagents = list()
	for(var/path in living_latex.avaible_reagents)
		var/datum/reagent/reagent = path
		reagents += list(list("name" = initial(reagent.name)))
	var/mob/living/target = subject()
	return list("subject" = target?.name, "reagents" = reagents, "cooldown_remaining" = max(0, next_injection - world.time) / (1 SECONDS), "evolve_poins" = living_latex.evolve_points, "cost" = LATEX_INJECT_COST, "amount" = LATEX_INJECT_AMOUNT)

/datum/inject_menu/ui_interact(mob/user, datum/tgui/ui)
	if(ui_status(user) != UI_INTERACTIVE)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "InjectMenu", name)
		ui.open()

/datum/inject_menu/ui_act(action, list/params)
	if(..() || ui_status(usr) != UI_INTERACTIVE || action != "inject")
		return FALSE
	return inject(params["reagent_name"])

/datum/inject_menu/proc/inject(reagent_name)
	var/mob/living/target = subject()
	if(QDELETED(target) || !target.reagents || world.time < next_injection || living_latex.evolve_points < LATEX_INJECT_COST)
		return FALSE
	for(var/path in living_latex.avaible_reagents)
		var/datum/reagent/reagent = path
		if(initial(reagent.name) != reagent_name)
			continue
		if(!target.reagents.add_reagent(path, LATEX_INJECT_AMOUNT))
			return FALSE
		living_latex.evolve_points = max(0, living_latex.evolve_points - LATEX_INJECT_COST)
		next_injection = world.time + LATEX_INJECT_COOLDOWN
		return TRUE
	return FALSE
