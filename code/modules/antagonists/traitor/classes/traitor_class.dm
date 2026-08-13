GLOBAL_LIST_EMPTY(traitor_classes)

/proc/bm_get_round_chaos()
	var/total = 0
	for(var/mob/player in GLOB.player_list)
		if(!player?.client?.prefs)
			continue
		var/level = player.client.prefs.preferred_chaos_level
		if(isnum(level))
			total += level
	return total

/proc/bm_traitor_violence_tier(pop = length(GLOB.joined_player_list))
	if(GLOB.round_type == ROUNDTYPE_DYNAMIC_LIGHT || GLOB.round_type == ROUNDTYPE_EXTENDED)
		return BM_TRAITOR_VIOLENCE_NONE

	var/tier = BM_TRAITOR_VIOLENCE_NONE
	if(pop >= 12)
		tier = BM_TRAITOR_VIOLENCE_SOFT
	if(pop >= 24)
		tier = BM_TRAITOR_VIOLENCE_FULL

	var/chaos = bm_get_round_chaos()
	var/hard_chaos_threshold = CONFIG_GET(number/chaos_for_a_hard_dynamic)
	var/medium_chaos_threshold = CONFIG_GET(number/chaos_for_a_medium_dynamic)

	switch(GLOB.round_type)
		if(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
			return tier
		if(ROUNDTYPE_DYNAMIC_MEDIUM)
			tier = min(tier, BM_TRAITOR_VIOLENCE_SOFT)
			if(chaos < medium_chaos_threshold)
				tier = BM_TRAITOR_VIOLENCE_NONE
			return tier

	if(chaos < medium_chaos_threshold)
		tier = min(tier, BM_TRAITOR_VIOLENCE_SOFT)
	if(chaos < hard_chaos_threshold / 2)
		tier = min(tier, BM_TRAITOR_VIOLENCE_NONE)
	return tier

/datum/traitor_class
	var/name = "Bad Coders Ltd."
	var/employer = "InteQ"
	var/weight = 0
	var/chaos = 0
	var/threat = 0
	var/TC = 20
	var/processing = FALSE
	/// Minimum players for this to randomly roll via get_random_traitor_kind().
	var/min_players = 0
	var/population_weight_penalty_threshold = 0
	var/population_weight_penalty_multiplier = 1
	var/list/uplink_filters
	/// Specific tgui theme for the player's antag info panel.
	var/tgui_theme = "inteq"

/datum/traitor_class/New()
	..()

	if(GLOB.round_type == ROUNDTYPE_DYNAMIC_LIGHT)
		if(istype(src, /datum/traitor_class/human/martyr) || istype(src, /datum/traitor_class/human/hijack))
			return

	if(src.type in GLOB.traitor_classes)
		qdel(src)
	else
		GLOB.traitor_classes += src.type
		GLOB.traitor_classes[src.type] = src

/datum/traitor_class/proc/forge_objectives(datum/antagonist/traitor/T)
	// Like the old forge_human_objectives. Makes all the objectives for this traitor class.

/datum/traitor_class/proc/forge_single_objective(datum/antagonist/traitor/T)
	// As forge_single_objective.

/datum/traitor_class/proc/on_removal(datum/antagonist/traitor/T)
	// What this does to the antag datum on removal. Called before proper removal, obviously.

/datum/traitor_class/proc/apply_innate_effects(mob/living/M)
	// What innate effects it should have. See: AI.

/datum/traitor_class/proc/remove_innate_effects(mob/living/M)
	// Cleaning up the innate effects.

/datum/traitor_class/proc/greet(datum/antagonist/traitor/T)
	// Message upon creation. Not necessary, but can be useful.

/datum/traitor_class/proc/finalize_traitor(datum/antagonist/traitor/T)
	// Finalization. Return TRUE if should play standard traitor sound/equip, return FALSE if both are special case
	return TRUE

/datum/traitor_class/proc/clean_up_traitor(datum/antagonist/traitor/T)
	// Any effects that need to be cleaned up if traitor class is being swapped.

/datum/traitor_class/proc/on_process(datum/antagonist/traitor/T)
	// only for processing traitor classes; runs once an SSprocessing tick

/datum/traitor_class/proc/get_selection_weight()
	. = LOGISTIC_FUNCTION(1.5 * weight, 0, chaos, 0) * 1000
	if(population_weight_penalty_threshold && length(GLOB.joined_player_list) >= population_weight_penalty_threshold)
		. *= population_weight_penalty_multiplier

/datum/traitor_class/human
	var/assassin_prob = 50

/datum/traitor_class/human/proc/get_effective_assassin_prob(datum/game_mode/dynamic/mode)
	if(GLOB.round_type == ROUNDTYPE_DYNAMIC_LIGHT)
		return 0
	var/tier = bm_traitor_violence_tier()
	switch(tier)
		if(BM_TRAITOR_VIOLENCE_NONE)
			return 0
		if(BM_TRAITOR_VIOLENCE_SOFT)
			return min(assassin_prob, 25)
	var/effective_prob = assassin_prob
	if(istype(mode))
		effective_prob = max(assassin_prob, mode.threat_level - 20)
	return max(0, effective_prob)

/datum/traitor_class/human/proc/try_forge_assassinate_objective(datum/antagonist/traitor/T, datum/game_mode/dynamic/mode)
	var/effective_prob = get_effective_assassin_prob(mode)
	if(!effective_prob || !prob(effective_prob))
		return FALSE
	var/tier = bm_traitor_violence_tier()
	if(tier == BM_TRAITOR_VIOLENCE_SOFT)
		var/datum/objective/assassinate/once/kill_objective = new
		kill_objective.owner = T.owner
		kill_objective.find_target()
		T.add_objective(kill_objective)
		return TRUE
	var/list/active_ais = active_ais()
	if(active_ais.len && prob(100 / max(1, GLOB.joined_player_list.len)))
		var/datum/objective/destroy/destroy_objective = new
		destroy_objective.owner = T.owner
		destroy_objective.find_target()
		T.add_objective(destroy_objective)
	else if(prob(max(0, effective_prob - 20)))
		var/datum/objective/assassinate/kill_objective = new
		kill_objective.owner = T.owner
		kill_objective.find_target()
		T.add_objective(kill_objective)
	else if(prob(20))
		var/datum/objective/assassinate/internal/kill_objective = new
		kill_objective.owner = T.owner
		kill_objective.find_target()
		T.add_objective(kill_objective)
	else
		var/datum/objective/assassinate/once/kill_objective = new
		kill_objective.owner = T.owner
		kill_objective.find_target()
		T.add_objective(kill_objective)
	return TRUE
