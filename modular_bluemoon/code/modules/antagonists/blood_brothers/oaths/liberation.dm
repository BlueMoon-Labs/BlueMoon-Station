/datum/blood_oath/liberation
	name = "Вызволение"
	key = "liberation"
	summary = "добыть ключ от брига, вывести узника и укрыть его"
	weight = 6
	capstone_type = /datum/action/cooldown/blood_bond/capstone/unshackle
	kit_items = list(BROTHER_KIT_BREAKIN, /obj/item/clothing/mask/balaclava)
	target_opt_in_level = ANTAG_OPT_IN_TEMPORARY

/datum/blood_oath/liberation/available(datum/team/brother_team/for_team)
	if(!..())
		return FALSE
	return length(prisoner_candidates(for_team)) > 0

/datum/blood_oath/liberation/prepare(datum/team/brother_team/for_team)
	. = ..()
	var/datum/mind/found = find_target(for_team)
	if(!found)
		return FALSE
	set_target(found)
	add_step(new /datum/blood_oath_step/liberation_key)
	add_step(new /datum/blood_oath_step/liberation_out)
	add_step(new /datum/blood_oath_step/liberation_free)
	update_story()
	return TRUE

/datum/blood_oath/liberation/find_target(datum/team/brother_team/for_team)
	var/list/datum/mind/candidates = prisoner_candidates(for_team)
	return length(candidates) ? pick(candidates) : null

/datum/blood_oath/liberation/update_story()
	var/mob/living/prisoner = target_mind.current
	story = "[target_mind.name] сел[prisoner?.ru_a()] за решётку вместо вас и никого не выдал[prisoner?.ru_a()]. Клянётесь: [prisoner ? prisoner.ru_who() : "узник"] выйдет на свободу."

/// Заключённый узнаёт, что снаружи за него поклялись, но не кто
/datum/blood_oath/liberation/target_sworn()
	var/mob/living/prisoner = target_mind?.current
	if(team.training || !prisoner || !GET_CLIENT(prisoner))
		return
	to_chat(prisoner, span_notice("Снаружи кто-то поклялся вытащить вас отсюда."))
	target_mind.store_memory("Снаружи кто-то поклялся вытащить вас отсюда.")
	log_game("Blood brothers [team.name] swore to free [key_name(target_mind)], the prisoner was told anonymously.")

/// Живые заключённые экипажа с игроком, согласные на помощь в побеге
/datum/blood_oath/liberation/proc/prisoner_candidates(datum/team/brother_team/for_team)
	. = list()
	if(for_team.training)
		if(brother_target_valid(for_team, for_team.training_target, ANTAG_OPT_IN_TEMPORARY))
			. += for_team.training_target
		return
	var/list/prisoner_titles = get_prisoner_role_titles()
	for(var/datum/data/record/record as anything in GLOB.data_core.locked)
		var/datum/mind/candidate = record.fields["mindref"]
		if(!(candidate?.assigned_role in prisoner_titles) || !brother_target_valid(for_team, candidate, ANTAG_OPT_IN_TEMPORARY))
			continue
		var/mob/living/body = candidate.current
		if(GET_CLIENT(body))
			. |= candidate

/datum/blood_oath/liberation/finale_extra_complete()
	var/turf/prisoner_turf = get_turf(target_mind?.current)
	if(!prisoner_turf || !brother_prisoner_free(target_mind))
		return FALSE
	if(istype(prisoner_turf, /turf/open/floor/plasteel/shuttle/red) || istype(prisoner_turf, /turf/open/floor/mineral/plastitanium/red/brig))
		return FALSE
	return prisoner_turf.onCentCom() || is_station_level(prisoner_turf.z)

/datum/blood_oath/liberation/finale_extra_text()
	var/mob/living/prisoner = target_mind?.current
	return "[target_mind?.name] жив[prisoner?.ru_a()] и на свободе"

/// Жив, без наручников и не под стражей
/proc/brother_prisoner_free(datum/mind/prisoner_mind)
	var/mob/living/carbon/prisoner = prisoner_mind?.current
	if(!iscarbon(prisoner) || QDELETED(prisoner) || !get_turf(prisoner) || prisoner.stat == DEAD || prisoner.handcuffed)
		return FALSE
	return !brother_area_is(prisoner, GLOB.brother_brig_areas)

/datum/blood_oath_step/liberation_key
	name = "Ключ от брига"
	desc = "ID-карта с доступом в бриг у любого из братьев."

/datum/blood_oath_step/liberation_key/can_seal(mob/living/sealer)
	for(var/obj/item/card/id/card as anything in brother_team_items(oath.team, /obj/item/card/id))
		if(ACCESS_BRIG in card.access)
			return TRUE
	return "на брате нет ID-карты с доступом в бриг"

/datum/blood_oath_step/liberation_key/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/liberation_out
	name = "Вывести"

/datum/blood_oath_step/liberation_out/describe()
	name = "Вывести: [oath.target_mind.name]"
	desc = "[oath.target_mind.name] вне брига и пермы, без наручников, не дальше [BROTHER_LIBERATION_RANGE] клеток от того, кто скрепляет."

/datum/blood_oath_step/liberation_out/can_seal(mob/living/sealer)
	if(!brother_prisoner_free(oath.target_mind))
		return "[oath.target_mind?.name] ещё не на свободе"
	if(!brother_within(sealer, oath.target_mind.current, BROTHER_LIBERATION_RANGE))
		return "[oath.target_mind.name] слишком далеко"
	return TRUE

/datum/blood_oath_step/liberation_out/condition_text(mob/living/viewer, sealable)
	return "на свободе рядом: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/liberation_free
	name = "Укрыть"
	var/free_time = 0

/datum/blood_oath_step/liberation_free/describe()
	var/mob/living/prisoner = oath.target_mind.current
	name = "Укрыть: [oath.target_mind.name]"
	desc = "[oath.target_mind.name] жив[prisoner?.ru_a()] и на свободе [DisplayTimeText(BROTHER_LIBERATION_FREE_TIME)] подряд: не в бриге, не в перме, без наручников. Поймают - отсчёт начнётся заново."

/datum/blood_oath_step/liberation_free/on_team_tick()
	if(oath.current_step() != src)
		return
	if(brother_prisoner_free(oath.target_mind))
		free_time += BROTHER_SENSE_INTERVAL
	else
		free_time = 0

/datum/blood_oath_step/liberation_free/can_seal(mob/living/sealer)
	if(free_time >= BROTHER_LIBERATION_FREE_TIME)
		return TRUE
	return condition_text(sealer)

/datum/blood_oath_step/liberation_free/condition_text(mob/living/viewer, sealable)
	return "на свободе [brother_time_text(free_time)] из [brother_time_text(BROTHER_LIBERATION_FREE_TIME)]"
