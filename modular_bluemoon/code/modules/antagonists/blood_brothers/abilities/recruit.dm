/datum/action/cooldown/blood_bond/recruit
	name = "Принять в братство"
	desc = "Позвать в братство третьего. Можно один раз за раунд и ещё раз, если кто-то из братьев ушёл насовсем. Человек сам решает, принять ли кровную клятву, отказ ему ничем не грозит."
	bond_how = "Встать вплотную к человеку, нажать кнопку и стоять рядом, пока режется ладонь. Позвать нельзя майндшилд, охрану и глав, других антагонистов и того, кто недавно отказался."
	button_icon_state = "recruit"
	beam_state = "recruit_bind"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/blood_bond/recruit/Activate(atom/target)
	var/datum/team/brother_team/team = brother.team
	var/team_verdict = team.recruit_team_refusal(owner.mind)
	if(team_verdict != TRUE)
		owner.balloon_alert(owner, team_verdict)
		return FALSE
	var/list/candidates = list()
	var/list/neighbours = list()
	var/last_reason
	for(var/mob/living/carbon/human/neighbour in orange(1, owner))
		neighbours += neighbour
		var/verdict = team.can_recruit(owner.mind, neighbour)
		if(verdict == TRUE)
			candidates += neighbour
		else
			last_reason = verdict
	if(!length(candidates))
		owner.balloon_alert(owner, length(neighbours) == 1 ? last_reason : "рядом некого позвать")
		return FALSE
	var/mob/living/carbon/human/chosen = candidates[1]
	if(length(candidates) > 1)
		chosen = tgui_input_list(owner, "Кому предложить кровную клятву?", "Принять в братство", candidates)
		if(!chosen || QDELETED(src) || !IsAvailable())
			return FALSE
	owner.visible_message(span_warning("[owner] надрезает ладонь и протягивает руку [chosen]."), span_notice("Вы надрезаете ладонь и протягиваете руку [chosen]."))
	if(!bond_do_after(chosen, BROTHER_RECRUIT_TIME) || QDELETED(src))
		return FALSE
	var/verdict = team.can_recruit(owner.mind, chosen)
	if(verdict != TRUE)
		owner.balloon_alert(owner, verdict)
		return FALSE
	StartCooldown(bond_cooldown())
	INVOKE_ASYNC(src, PROC_REF(ask_candidate), chosen)
	return TRUE

/datum/action/cooldown/blood_bond/recruit/proc/ask_candidate(mob/living/carbon/human/candidate)
	if(brother?.team?.training)
		answer_offer(candidate, "Принять")
		return
	var/answer = tgui_alert(candidate, "[owner] предлагает вам кровную клятву. Это роль антагониста: у братьев общие цели и способности, действуют правила малого антагониста. Отказ ничем не грозит.", "Кровная клятва", list("Принять", "Отказаться"), timeout = BROTHER_RECRUIT_ANSWER_TIME)
	answer_offer(candidate, answer)

/// Ответ кандидата на предложение; TRUE, если он стал братом
/datum/action/cooldown/blood_bond/recruit/proc/answer_offer(mob/living/carbon/human/candidate, answer)
	if(QDELETED(src) || !brother?.team || QDELETED(candidate) || !candidate.mind)
		return FALSE
	var/datum/team/brother_team/team = brother.team
	var/mob/living/recruiter = brother.owner.current
	if(answer != "Принять")
		team.recruit_refusals[candidate.mind] = world.time
		to_chat(recruiter, span_warning("[candidate] не принимает клятву."))
		log_game("[key_name(candidate)] refused the blood oath of [key_name(recruiter)] ([team.name]).")
		return FALSE
	var/verdict = team.can_recruit(brother.owner, candidate)
	if(verdict != TRUE)
		to_chat(recruiter, span_warning("Клятва с [candidate] не состоялась: [verdict]."))
		to_chat(candidate, span_warning("Клятва не состоялась."))
		return FALSE
	return team.recruit(candidate.mind)
