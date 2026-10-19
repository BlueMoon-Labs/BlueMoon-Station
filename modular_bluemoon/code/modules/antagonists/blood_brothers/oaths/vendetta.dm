/datum/blood_oath/vendetta
	name = "Месть"
	key = "vendetta"
	summary = "забрать ID-карту предателя, упечь его за решётку и расквитаться"
	weight = 10
	capstone_type = /datum/action/cooldown/blood_bond/capstone/mark
	kit_items = list(/obj/item/restraints/handcuffs/cable/zipties, /obj/item/restraints/handcuffs/cable/zipties, /obj/item/clothing/mask/balaclava, /obj/item/crowbar/red)

/datum/blood_oath/vendetta/Destroy()
	if(team)
		UnregisterSignal(team, COMSIG_BROTHER_TEAM_MEMBER_JOINED)
	return ..()

/datum/blood_oath/vendetta/get_weight(datum/team/brother_team/for_team)
	for(var/datum/mind/member as anything in for_team.members - for_team.departed_minds)
		if(member.get_antag_objective_style() != ANTAG_OBJECTIVE_STYLE_VIOLENT)
			return weight
	switch(GLOB.round_type)
		if(ROUNDTYPE_DYNAMIC_HARD)
			return round(weight * BROTHER_VENDETTA_VIOLENT_HARD_MULT)
		if(ROUNDTYPE_DYNAMIC_MEDIUM)
			return round(weight * BROTHER_VENDETTA_VIOLENT_MEDIUM_MULT)
	return weight

/datum/blood_oath/vendetta/prepare(datum/team/brother_team/for_team)
	if(team)
		UnregisterSignal(team, COMSIG_BROTHER_TEAM_MEMBER_JOINED)
	. = ..()
	var/violence = brother_team_violence_allowed(for_team)
	target_opt_in_level = violence ? ANTAG_OPT_IN_KILL : ANTAG_OPT_IN_TEMPORARY
	var/datum/mind/found = find_target(for_team)
	if(!found)
		return FALSE
	set_target(found)
	RegisterSignal(for_team, COMSIG_BROTHER_TEAM_MEMBER_JOINED, PROC_REF(on_member_joined))
	add_step(new /datum/blood_oath_step/vendetta_id)
	add_step(new /datum/blood_oath_step/vendetta_arrest)
	if(violence)
		add_step(new /datum/blood_oath_step/vendetta_kill)
	else
		add_step(new /datum/blood_oath_step/vendetta_hold)
	update_story()
	return TRUE

/// Охрана и капитан сами водят в бриг, заключённый уже там
/datum/blood_oath/vendetta/find_target(datum/team/brother_team/for_team)
	return brother_pick_target(for_team, target_opt_in_level, GLOB.security_positions + "Captain" + get_prisoner_role_titles(), src)

/// Сверхтяжёлого не удержать в техтоннелях
/datum/blood_oath/vendetta/target_allowed(datum/mind/candidate)
	if(target_opt_in_level == ANTAG_OPT_IN_KILL)
		return TRUE
	var/mob/living/body = candidate?.current
	return isliving(body) && body.mob_weight <= MOB_WEIGHT_HEAVY

/datum/blood_oath/vendetta/update_story()
	var/mob/living/target_body = target_mind.current
	story = "[target_mind.name] когда-то предал[target_body?.ru_a()] вас. Клянётесь: [target_body ? target_body.ru_who() : "предатель"] ответит."

/// Тихий новый брат переводит неисполненное убийство в удержание
/datum/blood_oath/vendetta/proc/on_member_joined(datum/source, datum/mind/joined)
	SIGNAL_HANDLER
	if(length(steps) < 3 || joined?.get_antag_objective_style() != ANTAG_OBJECTIVE_STYLE_QUIET)
		return
	var/datum/blood_oath_step/vendetta_kill/kill_step = steps[3]
	if(!istype(kill_step) || kill_step.sealed)
		return
	var/datum/blood_oath_step/vendetta_hold/hold_step = new
	hold_step.oath = src
	steps[3] = hold_step
	hold_step.describe()
	qdel(kill_step)
	target_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	log_game("Blood brothers [team.name] vendetta on [key_name(target_mind)] switched to a hold: [key_name(joined)] wants no killing.")
	if(team.oath != src)
		return
	hold_step.on_sworn()
	team.notify("[joined.name] клянётся без крови: [target_mind.name] больше не нужно убивать, только удержать.")
	team.refresh_brother_uis(static_data = TRUE)

/datum/blood_oath_step/vendetta_id
	name = "Забрать ID-карту"

/datum/blood_oath_step/vendetta_id/describe()
	name = "Забрать ID-карту: [oath.target_mind.name]"
	desc = "ID-карта на имя [oath.target_mind.name] у любого из братьев. Карта на прежнее имя цели тоже годится."

/datum/blood_oath_step/vendetta_id/can_seal(mob/living/sealer)
	for(var/obj/item/card/id/card as anything in brother_team_items(oath.team, /obj/item/card/id))
		if(oath.target_known_name(card.registered_name))
			return TRUE
	return "на брате нет ID-карты на имя [oath.target_mind?.name]"

/datum/blood_oath_step/vendetta_id/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/vendetta_arrest
	name = "За решёткой"

/datum/blood_oath_step/vendetta_arrest/describe()
	name = "За решёткой: [oath.target_mind.name]"
	desc = "Пусть [oath.target_mind.name] окажется в бриге, в перме, в ГУЛАГе или на пересылке туда: подставьте, сдайте охране, приведите сами."

/datum/blood_oath_step/vendetta_arrest/can_seal(mob/living/sealer)
	var/mob/living/target_body = oath.target_mind?.current
	if(!QDELETED(target_body) && brother_area_is(target_body, GLOB.brother_brig_areas))
		return TRUE
	return "[oath.target_mind?.name] не в бриге"

/datum/blood_oath_step/vendetta_arrest/condition_text(mob/living/viewer, sealable)
	return "в бриге: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/vendetta_kill
	name = "Кровь за предательство"
	var/died_once = FALSE
	var/mob/living/watched

/datum/blood_oath_step/vendetta_kill/Destroy()
	watch(null)
	return ..()

/datum/blood_oath_step/vendetta_kill/describe()
	var/mob/living/target_body = oath.target_mind.current
	desc = "[oath.target_mind.name] долж[target_body.ru_a() ? "на" : "ен"] умереть хотя бы раз после клятвы. Убийство разовое: тело не уничтожать, из раунда не выводить."

/datum/blood_oath_step/vendetta_kill/keeps_target()
	return died_once

/datum/blood_oath_step/vendetta_kill/on_sworn()
	watch(oath.target_mind?.current)

/datum/blood_oath_step/vendetta_kill/on_team_tick()
	var/mob/living/target_body = oath.target_mind?.current
	if(target_body != watched && isliving(target_body))
		watch(target_body)

/datum/blood_oath_step/vendetta_kill/proc/watch(mob/living/target_body)
	if(watched)
		UnregisterSignal(watched, list(COMSIG_MOB_STATCHANGE, COMSIG_PARENT_QDELETING))
	watched = target_body
	if(watched)
		RegisterSignal(watched, COMSIG_MOB_STATCHANGE, PROC_REF(on_target_stat))
		RegisterSignal(watched, COMSIG_PARENT_QDELETING, PROC_REF(on_target_deleted))

/datum/blood_oath_step/vendetta_kill/proc/on_target_stat(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat == DEAD)
		died_once = TRUE

/datum/blood_oath_step/vendetta_kill/proc/on_target_deleted(datum/source)
	SIGNAL_HANDLER
	watch(null)

/datum/blood_oath_step/vendetta_kill/can_seal(mob/living/sealer)
	if(died_once)
		return TRUE
	var/mob/living/target_body = oath.target_mind?.current
	return "[oath.target_mind?.name] ещё не умирал[target_body?.ru_a()] после клятвы"

/datum/blood_oath_step/vendetta_kill/condition_text(mob/living/viewer, sealable)
	return "умирал после клятвы: [died_once ? "да" : "нет"]"

/datum/blood_oath_step/vendetta_hold
	name = "Удержать"
	var/held_time = 0

/datum/blood_oath_step/vendetta_hold/describe()
	name = "Удержать: [oath.target_mind.name]"
	desc = "Держите [oath.target_mind.name] в наручниках или связанным в техтоннелях, не дальше [BROTHER_VENDETTA_HOLD_RANGE] клеток от брата, всего [DisplayTimeText(BROTHER_VENDETTA_HOLD_TIME)]. Без убийства."

/datum/blood_oath_step/vendetta_hold/on_team_tick()
	if(oath.current_step() != src)
		return
	var/mob/living/carbon/target_body = oath.target_mind?.current
	if(!iscarbon(target_body) || QDELETED(target_body) || target_body.stat == DEAD || !target_body.handcuffed)
		return
	if(!brother_area_is(target_body, list(/area/maintenance)))
		return
	for(var/mob/living/brother_body as anything in oath.team.living_brothers())
		if(brother_within(brother_body, target_body, BROTHER_VENDETTA_HOLD_RANGE))
			held_time += BROTHER_SENSE_INTERVAL
			return

/datum/blood_oath_step/vendetta_hold/can_seal(mob/living/sealer)
	if(held_time >= BROTHER_VENDETTA_HOLD_TIME)
		return TRUE
	return condition_text(sealer)

/datum/blood_oath_step/vendetta_hold/condition_text(mob/living/viewer, sealable)
	return "удержано [brother_time_text(held_time)] из [brother_time_text(BROTHER_VENDETTA_HOLD_TIME)]"
