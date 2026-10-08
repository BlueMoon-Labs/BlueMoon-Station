/datum/objective/rescue_prisoner
	name = "rescue prisoner"

/datum/objective/rescue_prisoner/find_target(dupe_search_range, blacklist)
	// Микрочистка списка
	var/list/weakref_to_clean = list()
	var/list/datum/mind/possible_targets = list()
	for(var/datum/weakref/weak_target in GLOB.roundstart_prisoners)
		var/mob/living/rescue_target = weak_target.resolve()
		if(!rescue_target)
			weakref_to_clean += weak_target
		else if(rescue_target.mind && opt_in_valid(rescue_target.mind))
			possible_targets += rescue_target.mind

	GLOB.roundstart_prisoners -= weakref_to_clean
	target = safepick(possible_targets)
	update_explanation_text()
	return target

/datum/objective/rescue_prisoner/update_explanation_text()
	if(target)
		explanation_text = "Помогите заключённому [target.name] сбежать на шаттле или в спасательной капсуле живым(-ой)."
	else
		explanation_text = "Свободная Задача"

/datum/objective/rescue_prisoner/check_completion()
	return considered_escaped(target)

/datum/objective/slaver
	name = "slave trading"
	explanation_text = "Earn 200,000 credits through slave trading."
