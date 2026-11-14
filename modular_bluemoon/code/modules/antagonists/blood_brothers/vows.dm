GLOBAL_LIST_INIT(blood_vow_types, list(
	/datum/blood_vow/bloodless,
	/datum/blood_vow/shoulder,
	/datum/blood_vow/shadow,
))

/datum/blood_vow
	var/name
	var/key
	var/desc
	var/broken = FALSE
	var/broken_reason
	var/datum/team/brother_team/team

/datum/blood_vow/Destroy()
	team = null
	return ..()

/datum/blood_vow/proc/attach(datum/team/brother_team/for_team)
	team = for_team

/datum/blood_vow/proc/on_team_tick()
	return

/datum/blood_vow/proc/holds()
	return !broken

/// Зовётся и из обработчиков сигналов: не спит
/datum/blood_vow/proc/break_vow(reason)
	if(broken || !team)
		return FALSE
	broken = TRUE
	broken_reason = reason
	team.cooldown_multiplier = 1
	team.notify("Обет «[name]» нарушен: [reason].")
	log_game("Blood brothers [team.name] broke vow [key]: [reason].")
	team.refresh_brother_uis()
	return TRUE

/datum/blood_vow/bloodless
	name = "Без крови"
	key = "bloodless"
	/// WEAKREF жертвы -> list(world.time удара, разум ударившего брата)
	var/list/recent_hits = list()
	var/list/datum/mind/watched_minds = list()
	var/list/mob/living/watched_bodies = list()

/datum/blood_vow/bloodless/New()
	. = ..()
	desc = "Никто из братьев не убивает разумных в ближнем бою: смерть того, кого брат бил в последние [BROTHER_VOW_BLOODLESS_WINDOW / (1 SECONDS)] секунд, ломает обет. Цель клятвы не в счёт. Выстрелы тоже: пуля не помнит стрелка."

/datum/blood_vow/bloodless/attach(datum/team/brother_team/for_team)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death))
	RegisterSignal(team, COMSIG_BROTHER_TEAM_MEMBER_JOINED, PROC_REF(on_member_joined))
	for(var/datum/mind/member as anything in team.members)
		watch_member(member)

/datum/blood_vow/bloodless/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	if(team)
		UnregisterSignal(team, COMSIG_BROTHER_TEAM_MEMBER_JOINED)
	for(var/datum/mind/member as anything in watched_minds)
		UnregisterSignal(member, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING))
	for(var/mob/living/body as anything in watched_bodies)
		UnregisterSignal(body, list(COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_PARENT_QDELETING))
	watched_minds.Cut()
	watched_bodies.Cut()
	recent_hits.Cut()
	return ..()

/datum/blood_vow/bloodless/proc/on_member_joined(datum/source, datum/mind/joined)
	SIGNAL_HANDLER
	watch_member(joined)

/datum/blood_vow/bloodless/proc/watch_member(datum/mind/member)
	if(!member || (member in watched_minds))
		return
	watched_minds += member
	RegisterSignal(member, COMSIG_MIND_TRANSFER, PROC_REF(on_mind_transfer))
	RegisterSignal(member, COMSIG_PARENT_QDELETING, PROC_REF(on_mind_deleted))
	watch_body(member.current)

/datum/blood_vow/bloodless/proc/on_mind_deleted(datum/mind/deleted)
	SIGNAL_HANDLER
	watched_minds -= deleted
	UnregisterSignal(deleted, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING))
	for(var/datum/weakref/hit_ref as anything in recent_hits)
		var/list/hit = recent_hits[hit_ref]
		if(hit[2] == deleted)
			recent_hits -= hit_ref

/datum/blood_vow/bloodless/proc/watch_body(mob/living/body)
	if(!isliving(body) || QDELETED(body) || (body in watched_bodies))
		return
	watched_bodies += body
	RegisterSignal(body, COMSIG_LIVING_SET_AS_ATTACKER, PROC_REF(on_brother_hit))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(unwatch_body))

/datum/blood_vow/bloodless/proc/unwatch_body(mob/living/body)
	SIGNAL_HANDLER
	if(!(body in watched_bodies))
		return
	watched_bodies -= body
	UnregisterSignal(body, list(COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_PARENT_QDELETING))

/datum/blood_vow/bloodless/proc/on_mind_transfer(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	unwatch_body(old_character)
	watch_body(new_character)

/datum/blood_vow/bloodless/proc/on_brother_hit(mob/living/attacker, mob/living/victim)
	SIGNAL_HANDLER
	for(var/datum/weakref/hit_ref as anything in recent_hits)
		var/list/old_hit = recent_hits[hit_ref]
		if(world.time - old_hit[1] > BROTHER_VOW_BLOODLESS_WINDOW)
			recent_hits -= hit_ref
	if(isliving(victim) && attacker.mind)
		recent_hits[WEAKREF(victim)] = list(world.time, attacker.mind)

/datum/blood_vow/bloodless/proc/on_mob_death(datum/source, mob/living/dead, gibbed)
	SIGNAL_HANDLER
	if(broken || !dead?.mind || (dead.mind in team.members) || team.oath?.is_target(dead.mind))
		return
	var/list/hit = recent_hits[WEAKREF(dead)]
	if(!hit || world.time - hit[1] > BROTHER_VOW_BLOODLESS_WINDOW)
		return
	var/datum/mind/killer = hit[2]
	if(!(killer in team.members) || (killer in team.departed_minds) || (killer in team.severed_minds))
		return
	break_vow("[killer.name] пролил[killer.current?.ru_a()] кровь")

/datum/blood_vow/shoulder
	name = "Плечом к плечу"
	key = "shoulder"

/datum/blood_vow/shoulder/New()
	. = ..()
	desc = "Каждый шаг скрепляется, когда рядом стоит другой брат, до [BROTHER_VOW_SHOULDER_RANGE] клеток."

/datum/blood_vow/shoulder/attach(datum/team/brother_team/for_team)
	. = ..()
	RegisterSignal(team, COMSIG_BROTHER_TEAM_STEP_SEALED, PROC_REF(on_step_sealed))

/datum/blood_vow/shoulder/Destroy()
	if(team)
		UnregisterSignal(team, COMSIG_BROTHER_TEAM_STEP_SEALED)
	return ..()

/datum/blood_vow/shoulder/proc/on_step_sealed(datum/source, datum/blood_oath_step/sealed_step, datum/mind/sealer)
	SIGNAL_HANDLER
	var/mob/living/sealer_body = sealer?.current
	for(var/mob/living/brother_body as anything in team.living_brothers())
		if(brother_body != sealer_body && brother_within(brother_body, sealer_body, BROTHER_VOW_SHOULDER_RANGE))
			return
	break_vow("шаг скреплён в одиночку")

/datum/blood_vow/shadow
	name = "Тень"
	key = "shadow"
	/// mind -> world.time, с которого брат в наручниках
	var/list/cuffed_since = list()

/datum/blood_vow/shadow/New()
	. = ..()
	desc = "Ни один брат не проводит в наручниках больше [BROTHER_VOW_SHADOW_LIMIT / (1 SECONDS)] секунд подряд."

/datum/blood_vow/shadow/Destroy()
	cuffed_since.Cut()
	return ..()

/datum/blood_vow/shadow/on_team_tick()
	if(broken)
		return
	for(var/datum/mind/member as anything in team.members - team.departed_minds)
		var/mob/living/carbon/body = member.current
		if(!iscarbon(body) || !body.handcuffed)
			cuffed_since -= member
			continue
		if(!cuffed_since[member])
			cuffed_since[member] = world.time
		else if(world.time - cuffed_since[member] > BROTHER_VOW_SHADOW_LIMIT)
			break_vow("[member.name] провёл[body.ru_a()] в наручниках больше [BROTHER_VOW_SHADOW_LIMIT / (1 SECONDS)] секунд")
			return
