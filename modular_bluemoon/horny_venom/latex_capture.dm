/datum/latex_capture
	var/datum/antagonist/living_latex/latex
	var/mob/living/simple_animal/latexmob/actor
	var/mob/living/carbon/human/host
	var/datum/mind/host_mind
	var/datum/latex_coating/coating
	var/turf/safe_turf
	var/list/zones = list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_HEAD)
	var/round_id = 0
	var/round_start
	var/zone_start
	var/submitted = FALSE
	var/finished = FALSE

/datum/latex_capture/New(datum/antagonist/living_latex/latex, mob/living/simple_animal/latexmob/actor, mob/living/carbon/human/host)
	. = ..()
	src.latex = latex
	src.actor = actor
	src.host = host
	host_mind = host.mind
	safe_turf = get_turf(host)

/datum/latex_capture/proc/start()
	if(QDELETED(latex) || QDELETED(actor) || QDELETED(host) || latex.capture || host.latex_capture || host.latex_coating)
		return FALSE
	if(latex.owner?.current != actor || !actor.Adjacent(host) || !isturf(host.loc) || !isturf(actor.loc))
		return FALSE
	latex.capture = src
	host.latex_capture = src
	coating = new(host, latex)
	RegisterSignal(actor, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_LIVING_DEATH), PROC_REF(interrupted))
	RegisterSignal(host, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_LIVING_DEATH), PROC_REF(interrupted))
	RegisterSignal(host, COMSIG_LIVING_RESIST, PROC_REF(resist))
	ADD_TRAIT(actor, TRAIT_IMMOBILIZED, src)
	actor.forceMove(host)
	if(actor.loc != host)
		return FALSE
	to_chat(host, span_userdanger("Живой латекс цепляется за ваши ноги и ползёт вверх! Остановите указатель в светлой зоне, чтобы сбросить его."))
	to_chat(actor, span_notice("Вы цепляетесь за [host]. Повторное нажатие способности прервёт обволакивание."))
	START_PROCESSING(SSfastprocess, src)
	next_round()
	return TRUE

/datum/latex_capture/proc/valid()
	if(finished || QDELETED(latex) || QDELETED(actor) || QDELETED(host))
		return FALSE
	if(latex.owner?.current != actor || actor.loc != host || host.mind != host_mind)
		return FALSE
	if(actor.stat != CONSCIOUS || host.stat == DEAD || !players_present())
		return FALSE
	return isturf(host.loc)

/datum/latex_capture/proc/players_present()
	return actor.client && (!host_mind || host.client)

/datum/latex_capture/process()
	if(!valid())
		qdel(src)
		return
	safe_turf = get_turf(host)
	if(world.time >= round_start + LATEX_CAPTURE_ROUND)
		next_round()

/datum/latex_capture/proc/next_round()
	if(!valid())
		qdel(src)
		return
	round_id++
	while(round_id <= length(zones) && !host.get_bodypart(zones[round_id]))
		round_id++
	if(round_id > length(zones))
		complete()
		return
	coating.cover(zones[round_id])
	round_start = world.time
	zone_start = rand(LATEX_QTE_MARGIN * LATEX_QTE_STEPS, (1 - LATEX_QTE_MARGIN - LATEX_QTE_WIDTH) * LATEX_QTE_STEPS) / LATEX_QTE_STEPS
	submitted = FALSE
	if(host.client)
		ui_interact(host)

/datum/latex_capture/proc/pointer_position(at_time = world.time)
	var/phase = ((at_time - round_start) % LATEX_QTE_PERIOD) / LATEX_QTE_PERIOD
	return phase <= 0.5 ? phase * 2 : (1 - phase) * 2

/datum/latex_capture/proc/stop_pointer(mob/user, requested_round)
	if(user != host || !valid() || submitted || requested_round != round_id || world.time >= round_start + LATEX_CAPTURE_ROUND)
		return FALSE
	submitted = TRUE
	var/position = pointer_position()
	if(position < zone_start || position > zone_start + LATEX_QTE_WIDTH)
		to_chat(host, span_warning("Вы не успели ухватить скользкий край. Латекс продолжает ползти вверх."))
		return FALSE
	to_chat(host, span_notice("Вы подхватываете край латекса и сбрасываете его с себя!"))
	qdel(src)
	return TRUE

/datum/latex_capture/proc/interrupted()
	SIGNAL_HANDLER
	qdel(src)

/datum/latex_capture/proc/resist()
	SIGNAL_HANDLER
	if(valid())
		INVOKE_ASYNC(src, PROC_REF(ui_interact), host)

/datum/latex_capture/proc/complete()
	if(!valid())
		qdel(src)
		return
	finished = TRUE
	UnregisterSignal(actor, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_LIVING_DEATH))
	latex.capture = null
	host.latex_capture = null
	var/obj/item/organ/latexOrgan/organ = new
	if(!organ.attach(latex, actor, host, coating))
		qdel(organ)
	else
		coating = null
	qdel(src)

/datum/latex_capture/ui_state(mob/user)
	return GLOB.always_state

/datum/latex_capture/ui_status(mob/user)
	return user == host && valid() ? UI_INTERACTIVE : UI_CLOSE

/datum/latex_capture/ui_interact(mob/user, datum/tgui/ui)
	if(user != host || !valid())
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LatexQTE", "Сбросить латекс")
		ui.open()

/datum/latex_capture/ui_data(mob/user)
	return list(
		"round_id" = round_id,
		"zone" = zones[round_id],
		"zone_start" = zone_start,
		"zone_width" = LATEX_QTE_WIDTH,
		"elapsed" = DS2MS(world.time - round_start),
		"period" = DS2MS(LATEX_QTE_PERIOD),
		"remaining" = DS2MS(max(0, round_start + LATEX_CAPTURE_ROUND - world.time)),
		"submitted" = submitted,
	)

/datum/latex_capture/ui_act(action, list/params)
	if(..() || usr != host || !valid() || params["round_id"] != round_id)
		return FALSE
	switch(action)
		if("stop")
			stop_pointer(usr, params["round_id"])
			return TRUE
		if("yield")
			next_round()
			return TRUE
	return FALSE

/datum/latex_capture/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	SStgui.close_uis(src)
	if(latex?.capture == src)
		latex.capture = null
	if(host)
		UnregisterSignal(host, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_LIVING_DEATH, COMSIG_LIVING_RESIST))
		if(host.latex_capture == src)
			host.latex_capture = null
	if(actor)
		UnregisterSignal(actor, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_LIVING_DEATH))
		REMOVE_TRAIT(actor, TRAIT_IMMOBILIZED, src)
		if(!QDELETED(actor) && actor.loc == host)
			actor.forceMove(get_turf(host) || safe_turf)
	QDEL_NULL(coating)
	latex = null
	actor = null
	host = null
	host_mind = null
	safe_turf = null
	return ..()
