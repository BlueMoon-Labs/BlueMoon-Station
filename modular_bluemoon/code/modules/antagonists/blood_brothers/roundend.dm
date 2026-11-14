GLOBAL_LIST_INIT(brother_seal_ordinals, list("Первая", "Вторая", "Третья", "Четвёртая", "Пятая"))

/datum/team/brother_team/roundend_report()
	var/list/parts = list("<span class='header'>Кровные братья [name]</span>")
	parts += roundend_thread()
	for(var/datum/mind/member as anything in members)
		parts += "[printplayer(member)][roundend_departure_mark(member)]"
	for(var/datum/mind/severed as anything in severed_minds)
		var/kind = severed_kinds[severed]
		parts += "<span class='redtext'>Клятва [severed.name] разорвана[kind == BROTHER_SEVER_RITE ? " обрядом" : ""][kind == BROTHER_SEVER_SURGERY ? " операцией" : ""].</span>"
	for(var/datum/blood_oath/fulfilled as anything in fulfilled_oaths)
		var/fulfilled_extra = fulfilled.finale_extra_text()
		var/extra_verdict = ""
		if(fulfilled_extra)
			extra_verdict = ", к концу смены [fulfilled_extra]: [fulfilled.finale_extra_complete() ? "<span class='greentext'>да</span>" : "<span class='redtext'>нет</span>"]"
		parts += "<b>Клятва «[fulfilled.name]»</b>: <span class='greentext'>все печати скреплены</span>[extra_verdict]"
	if(oath)
		parts += "<b>[length(fulfilled_oaths) ? "Следующая клятва" : "Клятва"] «[oath.name]»</b>"
		for(var/step_index in 1 to length(oath.steps))
			var/datum/blood_oath_step/oath_step = oath.steps[step_index]
			var/ordinal = step_index <= length(GLOB.brother_seal_ordinals) ? GLOB.brother_seal_ordinals[step_index] : "[step_index]-я"
			var/verdict = oath_step.sealed ? "<span class='greentext'>скреплено ([oath_step.sealed_by])</span>" : "<span class='redtext'>не скреплено</span>"
			parts += "[ordinal] печать, «[oath_step.name]»: [verdict]"
	else
		parts += "<span class='redtext'>Клятва так и не была дана.</span>"
	if(vow)
		parts += "Обет «[vow.name]»: [vow.broken ? "<span class='redtext'>нарушен: [vow.broken_reason]</span>" : "<span class='greentext'>держится</span>"]"
	var/datum/objective/blood_oath/oath_objective = locate() in objectives
	var/datum/objective/blood_oath_escape/escape_objective = locate() in objectives
	var/escaped = escape_objective?.check_completion()
	parts += "К концу смены всем живым братьям - до ЦК, без наручников: [escaped ? "<span class='greentext'>ушли</span>" : "<span class='redtext'>не ушли</span>"]"
	var/extra = oath?.finale_extra_text()
	if(extra)
		parts += "К концу смены [extra]: [oath.finale_extra_complete() ? "<span class='greentext'>да</span>" : "<span class='redtext'>нет</span>"]"
	if(abandoned)
		parts += "<span class='redtext'><b>Клятва оборвана: братьев не осталось.</b></span>"
	else if(oath_objective?.check_completion() && escaped)
		parts += "<span class='greentext'><b>Клятва исполнена[vow?.holds() ? " безупречно" : ""].</b></span>"
	else
		parts += "<span class='redtext'><b>Клятва не исполнена.</b></span>"
	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/// Имена братьев через нить: к ушедшему, мёртвому и разорвавшему клятву она порвана
/datum/team/brother_team/proc/roundend_thread()
	var/list/line = list()
	var/datum/mind/previous
	for(var/datum/mind/member as anything in members | severed_minds)
		if(previous)
			var/torn = roundend_thread_torn(previous) || roundend_thread_torn(member)
			line += "<span class='redtext'>[torn ? BROTHER_ROUNDEND_TORN : BROTHER_ROUNDEND_THREAD]</span>"
		line += "<b>[member.name]</b>"
		previous = member
	return line.Join(" ")

/datum/team/brother_team/proc/roundend_thread_torn(datum/mind/member)
	if((member in severed_minds) || (member in departed_minds))
		return TRUE
	var/mob/living/body = member.current
	return QDELETED(body) || body.stat == DEAD

/datum/team/brother_team/proc/roundend_departure_mark(datum/mind/member)
	if(!(member in departed_minds) || (member in severed_minds))
		return ""
	var/female = departed_genders[member] == FEMALE
	var/went = female ? "ушла" : "ушёл"
	switch(departed_reasons[member])
		if(BROTHER_DEPARTURE_CRYO)
			return ", <span class='redtext'>[went] в крио</span>"
		if(BROTHER_DEPARTURE_GHOST)
			return ", <span class='redtext'>[went] в призраки</span>"
		if(BROTHER_DEPARTURE_SSD)
			return ", <span class='redtext'>[female ? "уснула и не вернулась" : "уснул и не вернулся"]</span>"
		if(BROTHER_DEPARTURE_DELETED)
			return ", <span class='redtext'>тело пропало</span>"
	return ""
