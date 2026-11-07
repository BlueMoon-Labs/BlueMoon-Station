/datum/blood_oath/initiation
	name = "Посвящение"
	key = "initiation"
	summary = "принять третьего, испытать его делом и уйти втроём"
	weight = 5
	capstone_type = /datum/blood_bond_passive/circle
	kit_items = list(BROTHER_KIT_BREAKIN)
	var/gift_type
	var/gift_name
	var/datum/objective_item/gift_info

/datum/blood_oath/initiation/Destroy()
	gift_info = null
	return ..()

/datum/blood_oath/initiation/available(datum/team/brother_team/for_team)
	if(!..() || for_team.third_oath_used || length(for_team.members - for_team.departed_minds) >= BROTHER_TEAM_MAX_SIZE)
		return FALSE
	for(var/datum/data/record/record as anything in GLOB.data_core.locked)
		var/datum/mind/candidate = record.fields["mindref"]
		var/mob/living/body = candidate?.current
		if(isliving(body) && body.stat != DEAD && GET_CLIENT(body) && for_team.recruit_role_ok(candidate) == TRUE)
			return TRUE
	return FALSE

/datum/blood_oath/initiation/prepare(datum/team/brother_team/for_team)
	. = ..()
	if(!third_possible(for_team))
		return FALSE
	gift_info = brother_steal_pick(for_team)
	if(!gift_info)
		return FALSE
	gift_type = gift_info.targetitem
	gift_name = brother_item_name(gift_info)
	add_step(new /datum/blood_oath_step/initiation_third)
	add_step(new /datum/blood_oath_step/initiation_gift)
	add_step(new /datum/blood_oath_step/initiation_circle)
	story = "Вдвоём вам не выстоять. Клянётесь найти третьего, проверить его делом и уйти со станции втроём."
	return TRUE

/datum/blood_oath/initiation/revalidate()
	return ..() && third_possible(team)

/// Третий уже среди живых братьев или его ещё можно позвать
/datum/blood_oath/initiation/proc/third_possible(datum/team/brother_team/for_team)
	if(length(for_team.living_brothers()) >= BROTHER_TEAM_MAX_SIZE)
		return TRUE
	return !for_team.third_oath_used || for_team.replacement_available

/// Последний принятый брат, если он жив и в строю
/datum/blood_oath/initiation/proc/newest_brother()
	if(length(team?.members) <= BROTHER_TEAM_START_SIZE)
		return null
	var/datum/mind/newest = team.members[length(team.members)]
	return team.is_active_brother(newest) ? newest : null

/datum/blood_oath/initiation/finale_extra_complete()
	var/datum/objective/blood_oath_escape/escape_objective = locate() in team?.objectives
	if(!escape_objective)
		return FALSE
	var/escaped_count = 0
	for(var/datum/mind/member as anything in team.members - team.departed_minds - team.severed_minds)
		var/mob/living/body = member.current
		if(QDELETED(body) || body.stat == DEAD)
			continue
		if(!escape_objective.considered_escaped(member))
			return FALSE
		if(iscarbon(body))
			var/mob/living/carbon/carbon_body = body
			if(carbon_body.handcuffed)
				return FALSE
		escaped_count++
	return escaped_count >= BROTHER_TEAM_MAX_SIZE

/datum/blood_oath/initiation/finale_extra_text()
	return "все трое ушли вместе"

/datum/blood_oath_step/initiation_third
	name = "Принять третьего"
	desc = "Позовите третьего кнопкой «Принять в братство». Скрепить можно, когда вас трое и все живы."

/datum/blood_oath_step/initiation_third/can_seal(mob/living/sealer)
	var/living_count = length(oath.team.living_brothers())
	if(living_count >= BROTHER_TEAM_MAX_SIZE)
		return TRUE
	return "живых братьев [living_count] из [BROTHER_TEAM_MAX_SIZE]"

/datum/blood_oath_step/initiation_third/condition_text(mob/living/viewer, sealable)
	return "братьев: [length(oath.team.living_brothers())] из [BROTHER_TEAM_MAX_SIZE]"

/datum/blood_oath_step/initiation_gift
	name = "Испытание"

/datum/blood_oath_step/initiation_gift/describe()
	var/datum/blood_oath/initiation/initiation = oath
	name = "Испытание: добыть [initiation.gift_name]"
	desc = "Третий брат, тот, кто принял клятву последним, добывает [initiation.gift_name] и держит при себе."

/datum/blood_oath_step/initiation_gift/can_seal(mob/living/sealer)
	var/datum/blood_oath/initiation/initiation = oath
	var/datum/mind/newest = initiation.newest_brother()
	if(!newest)
		return "третьего брата нет"
	if(brother_holder_has(newest.current, initiation.gift_info))
		return TRUE
	return "[newest.name] ещё не добыл[newest.current?.ru_a()] [initiation.gift_name]"

/datum/blood_oath_step/initiation_gift/condition_text(mob/living/viewer, sealable)
	return "на третьем: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/initiation_circle
	name = "Круг крови"

/datum/blood_oath_step/initiation_circle/describe()
	desc = "Все трое братьев живы и стоят не дальше [BROTHER_INITIATION_RANGE] клеток от того, кто скрепляет."

/datum/blood_oath_step/initiation_circle/can_seal(mob/living/sealer)
	var/list/mob/living/brothers = oath.team.living_brothers()
	if(length(brothers) < BROTHER_TEAM_MAX_SIZE)
		return "живых братьев меньше трёх"
	for(var/mob/living/brother_body as anything in brothers)
		if(!brother_within(sealer, brother_body, BROTHER_INITIATION_RANGE))
			return "не все братья рядом"
	return TRUE

/datum/blood_oath_step/initiation_circle/condition_text(mob/living/viewer, sealable)
	return "все рядом: [sealable_now(viewer, sealable) ? "да" : "нет"]"
