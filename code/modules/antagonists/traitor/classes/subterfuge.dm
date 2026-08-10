/datum/traitor_class/human/subterfuge
	name = "InteQ Overative"
	employer = "InteQ"
	weight = 25
	chaos = -5
	var/assassin_prob = 25

/datum/traitor_class/human/subterfuge/forge_single_objective(datum/antagonist/traitor/T)
	var/datum/game_mode/dynamic/mode
	if(istype(SSticker.mode,/datum/game_mode/dynamic))
		mode = SSticker.mode
		assassin_prob = max(0,mode.threat_level-20)
	if(GLOB.round_type == ROUNDTYPE_DYNAMIC_LIGHT)
		assassin_prob = 0
	if(prob(assassin_prob))
		if(prob(25))
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
	else
		var/list/weights = list()
		var/datum/objective/sabotage/sabotage_objective = new
		sabotage_objective.owner = T.owner
		if(sabotage_objective.find_target())
			weights["sabo"] = length(subtypesof(/datum/objective_item/steal))
		var/datum/objective/steal/steal_objective = new
		steal_objective.owner = T.owner
		if(steal_objective.find_target())
			weights["steal"] = length(subtypesof(/datum/objective_item/steal))
		var/datum/objective/protect/protect_objective = new
		protect_objective.owner = T.owner
		if(protect_objective.find_target())
			weights["protect"] = length(subtypesof(/datum/objective_item/steal))
		var/datum/objective/breakout/breakout_objective = null
		if(has_manifest_prisoner())
			breakout_objective = new
			breakout_objective.owner = T.owner
			if(!breakout_objective.find_target())
				qdel(breakout_objective)
				breakout_objective = null
			else
				weights["breakout"] = length(subtypesof(/datum/objective_item/steal))
		weights["download"] = !(locate(/datum/objective/download) in T.objectives || (T.owner.assigned_role in list("Research Director", "Scientist", "Roboticist")))
		switch(pickweight(weights))
			if("sabo")
				T.add_objective(sabotage_objective)
				qdel(steal_objective)
				qdel(protect_objective)
				if(breakout_objective)
					qdel(breakout_objective)
				return TRUE
			if("steal")
				T.add_objective(steal_objective)
				qdel(sabotage_objective)
				qdel(protect_objective)
				if(breakout_objective)
					qdel(breakout_objective)
				return TRUE
			if("protect")
				T.add_objective(protect_objective)
				qdel(sabotage_objective)
				qdel(steal_objective)
				if(breakout_objective)
					qdel(breakout_objective)
				return TRUE
			if("breakout")
				T.add_objective(breakout_objective)
				qdel(sabotage_objective)
				qdel(steal_objective)
				qdel(protect_objective)
				return TRUE
			if("download")
				qdel(sabotage_objective)
				qdel(steal_objective)
				qdel(protect_objective)
				if(breakout_objective)
					qdel(breakout_objective)
				var/datum/objective/download/download_objective = new
				download_objective.owner = T.owner
				download_objective.gen_amount_goal()
				T.add_objective(download_objective)
				return TRUE
		return FALSE
