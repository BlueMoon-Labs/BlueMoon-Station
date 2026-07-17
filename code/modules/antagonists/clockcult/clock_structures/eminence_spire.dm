//Used to nominate oneself or ghosts for the role of Eminence.
/obj/structure/destructible/clockwork/eminence_spire
	name = "eminence spire"
	desc = "Огромная машина, сделанная из прочного сплава, с тремя маленькими обелисками и огромной плитой в центре."
	clockwork_desc = "Этот шпиль используется для того, чтобы стать Епископ, который функционирует как невидимый лидер культа. Активируйте его, чтобы выдвинуть свою кандидатуру или предложить \
	выбрать Епископа из доступных призраков. Как только Епископ выбран, его обычно нельзя изменить."
	icon_state = "tinkerers_daemon"
	break_message = "<span class='warning'>Шпиль издает оглушительный скрежет и разваливается на куски!</span>"
	max_integrity = 400
	var/mob/eminence_nominee
	var/selection_timer //Timer ID; this is canceled if the vote is canceled
	var/kingmaking

/obj/structure/destructible/clockwork/eminence_spire/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(!is_servant_of_ratvar(user))
		to_chat(user, "<span class='notice'>Вы можете сказать, насколько силен [src]; вы знаете, что к нему лучше не прикасаться.</span>")
		return
	if(kingmaking)
		return

	var/datum/antagonist/clockcult/C = user.mind.has_antag_datum(/datum/antagonist/clockcult)
	if(!C || !C.clock_team)
		return
	if(C.clock_team.eminence)
		to_chat(user, "<span class='warning'>Епископ уже назначен!</span>")
		return
	if(eminence_nominee) //This could be one large proc, but is split into three for ease of reading
		if(eminence_nominee == user)
			cancelation(user)
		else
			objection(user)
	else
		nomination(user)

/obj/structure/destructible/clockwork/eminence_spire/attack_drone(mob/living/simple_animal/drone/user)
	if(!is_servant_of_ratvar(user))
		..()
	else
		to_chat(user, "<span class='warning'>Вы чувствуете, как всезнающий взгляд превращается в озадаченную гримасу. Возможно, вам стоит просто заняться строительством.</span>")
		return

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/structure/destructible/clockwork/eminence_spire/attack_ghost(mob/user)
	if(!IsAdminGhost(user))
		return

	var/datum/mind/rando = locate() in get_antag_minds(/datum/antagonist/clockcult) //if theres no cultists new team without eminence will be created anyway.
	if(rando)
		var/datum/antagonist/clockcult/random_cultist = rando.has_antag_datum(/datum/antagonist/clockcult)
		if(random_cultist && random_cultist.clock_team && random_cultist.clock_team.eminence)
			to_chat(user, "<span class='warning'>Епископ уже назначен - слишком поздно!</span>")
			return
	if(!GLOB.servants_active)
		to_chat(user, "<span class='warning'>Сначала Ковчег должен быть активен!</span>")
		return
	if(alert(user, "Стать Епископом, используя возможности админа?", "Становление Епископом", "Да", "Нет") != "Да")
		return
	message_admins("<span class='danger'>Admin [key_name_admin(user)] directly became the Eminence of the cult!</span>")
	log_admin("Admin [key_name(user)] made themselves the Eminence.")
	var/mob/camera/eminence/eminence = new(get_turf(src))
	user.transfer_ckey(eminence, FALSE)
	hierophant_message("<span class='bold large_brass'>Ратвар напрямую назначил Епископа!</span>")
	for(var/mob/M in servants_and_ghosts())
		M.playsound_local(M, 'sound/machines/clockcult/eminence_selected.ogg', 50, FALSE)

/obj/structure/destructible/clockwork/eminence_spire/proc/nomination(mob/living/nominee) //A user is nominating themselves or ghosts to become Eminence
	var/nomination_choice = alert(nominee, "Кого бы вы хотели выдвинуть?", "Выдвижение на Епископа", "Выдвинуть себя на место Епископа", "Выдвинуть призрака на место Епископа", "Отмена")
	if(!is_servant_of_ratvar(nominee) || !nominee.canUseTopic(src) || eminence_nominee)
		return
	switch(nomination_choice)
		if("Отмена")
			return
		if("Выдвинуть себя на место Епископа")
			eminence_nominee = nominee
			hierophant_message("<span class='brass'><b>[nominee] предлагает себя как Епископа!</b> Вы можете возразить, нажав на шпиль возвышения. В противном случае голосование будет завершено через 30 секунд.</span>")
		if("Выдвинуть призрака на место Епископа")
			eminence_nominee = "призраков"
			hierophant_message("<span class='brass'><b>[nominee] предлагает выбрать Епископа среди призраков!</b> Вы можете возразить, нажав на шпиль возвышения. В противном случае голосование будет завершено через 30 секунд.</span>")
	for(var/mob/M in servants_and_ghosts())
		M.playsound_local(M, 'sound/machines/clockcult/ocularwarden-target.ogg', 50, FALSE)
	selection_timer = addtimer(CALLBACK(src, PROC_REF(kingmaker)), 300, TIMER_STOPPABLE)

/obj/structure/destructible/clockwork/eminence_spire/proc/objection(mob/living/wright)
	if(alert(wright, "Возражаете против выбора [eminence_nominee] в качестве Епископа?", "Возражение!", "Возражаю", "Отмена") == "Отмена" || !is_servant_of_ratvar(wright) || !wright.canUseTopic(src) || !eminence_nominee)
		return
	hierophant_message("<span class='brass'><b>[wright] возражает против выдвижения кандидатуры [eminence_nominee]!</b> Шпиль Епископа был сброшен.</span>")
	for(var/mob/M in servants_and_ghosts())
		M.playsound_local(M, 'sound/machines/clockcult/integration_cog_install.ogg', 50, FALSE)
	eminence_nominee = null
	deltimer(selection_timer)

/obj/structure/destructible/clockwork/eminence_spire/proc/cancelation(mob/living/cold_feet)
	if(alert(cold_feet, "Отменить свою номинацию?", "Отмена номинации", "Отозвать кандидатуру", "Отмена") == "Отмена" || !is_servant_of_ratvar(cold_feet) || !cold_feet.canUseTopic(src) || !eminence_nominee)
		return
	hierophant_message("<span class='brass'><b>[eminence_nominee] отозвал свою кандидатуру!</b> Шпиль Епископа был сброшен.</span>")
	for(var/mob/M in servants_and_ghosts())
		M.playsound_local(M, 'sound/machines/clockcult/integration_cog_install.ogg', 50, FALSE)
	eminence_nominee = null
	deltimer(selection_timer)

/obj/structure/destructible/clockwork/eminence_spire/proc/kingmaker()
	if(!eminence_nominee)
		return
	if(ismob(eminence_nominee))
		if(!eminence_nominee.client || !eminence_nominee.mind)
			hierophant_message("<span class='brass'><b>[eminence_nominee] каким-то образом потерял разум!</b> Шпиль Епископа был сброшен.</span>")
			for(var/mob/M in servants_and_ghosts())
				M.playsound_local(M, 'sound/machines/clockcult/integration_cog_install.ogg', 50, FALSE)
			eminence_nominee = null
			return
		playsound(eminence_nominee, 'sound/machines/clockcult/ark_damage.ogg', 50, FALSE)
		eminence_nominee.visible_message("<span class='warning'>Вспышка раскаленного добела света устремляется в [eminence_nominee], мгновенно превращая [eminence_nominee.ru_ego()] в пар!</span>", \
		"<span class='userdanger'>allthelightintheuniverseflowing.into.YOU</span>")
		for(var/obj/item/I in eminence_nominee)
			eminence_nominee.dropItemToGround(I)
		var/mob/camera/eminence/eminence = new(get_turf(src))
		eminence_nominee.mind.transfer_to(eminence)
		eminence_nominee.dust()
		hierophant_message("<span class='bold large_brass'>[eminence_nominee] возвысился как Епископ!</span>")
	else if(eminence_nominee == "призраков")
		kingmaking = TRUE
		hierophant_message("<span class='brass'><b>Шпиль Епископа сейчас выбирает призрака на роль возвышения...</b></span>")
		var/list/candidates = pollGhostCandidates("Хотели бы вы сыграть за Епископа слуг?", ROLE_SERVANT_OF_RATVAR, null, ROLE_SERVANT_OF_RATVAR, poll_time = 100)
		kingmaking = FALSE
		if(!LAZYLEN(candidates))
			for(var/mob/M in servants_and_ghosts())
				M.playsound_local(M, 'sound/machines/clockcult/integration_cog_install.ogg', 50, FALSE)
			hierophant_message("<span class='brass'><b>Ни один призрак не принял это предложение! Шпиль Епископа был восстановлен.</span>")
			eminence_nominee = null
			return
		visible_message("<span class='warning'>Взрыв раскаленных добела световых спиралей волнами вырывается из [src]!</span>")
		playsound(src, 'sound/machines/clockcult/ark_damage.ogg', 50, FALSE)
		var/mob/camera/eminence/eminence = new(get_turf(src))
		eminence_nominee = pick(candidates)
		eminence_nominee.transfer_ckey(eminence)
		hierophant_message("<span class='bold large_brass'>Призрак возвысился как Епископа!</span>")
	for(var/mob/M in servants_and_ghosts())
		M.playsound_local(M, 'sound/machines/clockcult/eminence_selected.ogg', 50, FALSE)
	eminence_nominee = null
