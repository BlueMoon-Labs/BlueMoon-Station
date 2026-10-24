/datum/controller/subsystem/ticker/Initialize(timeofday)
	. = ..()
	OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(log_antag_opt_in_distribution), "старт"))
	OnRoundend(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(log_antag_round_summary)))

/// Сколько экипажа на каждом итоговом уровне согласия, сколько выбрали уровень сами и скольких поднял порог.
/proc/antag_opt_in_distribution_text()
	var/list/level_counts = list()
	var/crew = 0
	var/chosen = 0
	var/raised = 0
	for(var/datum/data/record/record as anything in GLOB.data_core.locked)
		var/datum/mind/crew_mind = record.fields["mindref"]
		if(!crew_mind)
			continue
		crew++
		var/effective = crew_mind.get_effective_antag_opt_in_level()
		var/selected = isnull(crew_mind.antag_opt_in_level) ? antag_opt_in_default_level() : crew_mind.antag_opt_in_level
		level_counts["[effective]"]++
		if(!isnull(crew_mind.antag_opt_in_level))
			chosen++
		if(effective > selected)
			raised++
	var/list/parts = list()
	for(var/level in ANTAG_OPT_IN_NOT_TARGET to ANTAG_OPT_IN_ROUND_REMOVE)
		parts += "\"[antag_opt_in_level_name(level)]\" [level_counts["[level]"] || 0]"
	return "экипаж [crew]; [jointext(parts, ", ")]; выбрали сами [chosen], подняты порогом [raised]"

/proc/log_antag_opt_in_distribution(stage)
	log_game("ANTAG OPT-IN ([stage]): [antag_opt_in_distribution_text()].")

/proc/log_antag_round_summary()
	log_antag_opt_in_distribution("конец")
	for(var/datum/antagonist/antag as anything in GLOB.antagonists)
		if(!antag.owner || !length(antag.objectives))
			continue
		var/list/objective_types = list()
		for(var/datum/objective/objective as anything in antag.objectives)
			objective_types += replacetext("[objective.type]", "/datum/objective/", "")
		var/style = antag.owner.get_antag_objective_style()
		log_game("ANTAG OBJECTIVES: [key_name(antag.owner)] ([antag.name], стиль \"[GLOB.antag_objective_styles[style]]\"): [jointext(objective_types, ", ")].")
