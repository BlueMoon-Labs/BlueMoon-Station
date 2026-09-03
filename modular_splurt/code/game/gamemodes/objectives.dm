/datum/objective/rescue_prisoner
	name = "rescue prisoner"

/datum/objective/rescue_prisoner/find_target(dupe_search_range, blacklist)
	// Микрочистка списка
	var/list/weakref_to_clean = list()
	for(var/datum/weakref/weak_target in GLOB.roundstart_prisoners)
		if(!weak_target.resolve())
			weakref_to_clean += weak_target

	GLOB.roundstart_prisoners -= weakref_to_clean

	if(!length(GLOB.roundstart_prisoners))
		qdel(src)
		return FALSE
	var/datum/weakref/weak_target = pick(GLOB.roundstart_prisoners)
	var/mob/living/rescue_target = weak_target.resolve()
	if(!rescue_target)
		qdel(src)
		return FALSE
	target = rescue_target.mind
	return target

/datum/objective/rescue_prisoner/check_completion()
	return considered_escaped(target)

/datum/objective/slaver
	name = "slave trading"
	explanation_text = "Earn 200,000 credits through slave trading."
