/datum/objective/blood_oath
	name = "blood oath"
	explanation_text = "Исполнить кровную клятву."

/datum/objective/blood_oath/update_explanation_text()
	var/datum/team/brother_team/brother_team = team
	var/datum/blood_oath/oath = brother_team?.oath
	if(!oath)
		explanation_text = initial(explanation_text)
		return
	var/list/fulfilled_names = list()
	for(var/datum/blood_oath/fulfilled as anything in brother_team.fulfilled_oaths)
		fulfilled_names += "«[fulfilled.name]»"
	var/list/step_names = list()
	for(var/datum/blood_oath_step/oath_step as anything in oath.steps)
		step_names += oath_step.name
	var/extra = oath.finale_extra_text()
	explanation_text = "[length(fulfilled_names) ? "Исполнено: [fulfilled_names.Join(", ")]. " : ""]Клятва «[oath.name]»: [step_names.Join("; ")][extra ? "; к концу смены: [extra]" : ""]."

/// Хватает одной исполненной клятвы: следующие - по желанию
/datum/objective/blood_oath/check_completion()
	var/datum/team/brother_team/brother_team = team
	if(!brother_team)
		return FALSE
	for(var/datum/blood_oath/fulfilled as anything in brother_team.fulfilled_oaths)
		if(fulfilled.finale_extra_complete())
			return TRUE
	var/datum/blood_oath/oath = brother_team.oath
	if(!oath || !length(oath.steps) || oath.current_step())
		return FALSE
	return oath.finale_extra_complete() ? TRUE : FALSE

/datum/objective/blood_oath_escape
	name = "leave together"
	explanation_text = "Уйти вместе: все живые братья покидают станцию свободными."

/// Мёртвые и ушедшие братья финал не блокируют, но хоть один живой должен уйти
/datum/objective/blood_oath_escape/check_completion()
	var/datum/team/brother_team/brother_team = team
	if(!brother_team)
		return FALSE
	var/escaped = FALSE
	for(var/datum/mind/member as anything in brother_team.members - brother_team.severed_minds - brother_team.departed_minds)
		var/mob/living/body = member.current
		if(QDELETED(body) || body.stat == DEAD)
			continue
		if(!considered_escaped(member))
			return FALSE
		if(iscarbon(body))
			var/mob/living/carbon/carbon_body = body
			if(carbon_body.handcuffed)
				return FALSE
		escaped = TRUE
	return escaped
