//well-trained moved to neutral to stop the awkward situation of a dom snapping and the 30 trait powergamers fall to the floor.
/datum/quirk/well_trained
	name = "Дрессированный"
	desc = "Вы обожаете, когда над вами доминируют. Мысли о том, что есть кто-то сильнее, достаточно, чтобы завести вас."
	value = -1
	flavor_quirk = TRUE
	gain_text = span_notice("Вы хотите подчиниться кому-нибудь...")
	lose_text = span_notice("Вы больше не хотите подчиняться...")
	processing_quirk = TRUE
	/// BLUEMOON ADDED - optimization
	var/check_delay = 0
	var/notice_delay = 0
	var/mob/living/carbon/human/last_dom

/datum/quirk/well_trained/add()
	. = ..()
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/quirk/well_trained/remove()
	. = ..()
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

/datum/quirk/well_trained/proc/on_examine_holder(atom/source, mob/living/user, list/examine_list, anonymous = FALSE)
	SIGNAL_HANDLER

	if(!istype(user))
		return
	if(!user.has_quirk(/datum/quirk/dominant_aura))
		return
	examine_list += span_lewd("Вы чувствуете сильную ауру подчинения от [anonymous ? "него" : quirk_holder.ru_nego()].")

/datum/quirk/well_trained/on_process()
	. = ..()
	if(!quirk_holder)
		return
	// BLUEMOON EDIT START - оптимизация
	if(check_delay > world.time)
		return

	check_delay = world.time + 5 SECONDS
	// BLUEMOON EDIT END

	var/good_x = "хорошим питомцем"
	switch(quirk_holder.gender)
		if(MALE)
			good_x = "хорошим мальчиком"
		if(FEMALE)
			good_x = "хорошей девочкой"

	//Check for possible doms with the dominant_aura quirk, and for the closest one if there is
	. = FALSE
	var/list/mob/living/carbon/human/doms = range(DOMINANT_DETECT_RANGE, quirk_holder)
	var/closest_distance
	for(var/mob/living/carbon/human/dom in doms)
		if(dom != quirk_holder && dom.has_quirk(/datum/quirk/dominant_aura))
			if(!closest_distance || get_dist(quirk_holder, dom) <= closest_distance)
				. = dom
				closest_distance = get_dist(quirk_holder, dom)

	//Return if no dom is found
	if(!.)
		last_dom = null
		return

	// BLUEMOON EDIT START - теперь негативный мудлет убирается при появлении позитивного
	//Handle the mood
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(!isnull(mood.mood_events[QMOOD_WELL_TRAINED]))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_WELL_TRAINED, /datum/mood_event/dominant/good_boy)
	else
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_BAD_TRAINED, /datum/mood_event/dominant/need)
	// BLUEMOON EDIT END

	//Don't do anything if a previous dom was found
	if(last_dom)
		notice_delay = world.time + 15 SECONDS
		return

	last_dom = .

	if(notice_delay > world.time)
		return

	//Let them know they're near
	var/list/notices = list(
		"Вы ощущаете, как чьё-то присутствие делает вас более покорным...",
		"Мысли о том, чтобы вами командовали, заполняют ваш разум похотью...",
		"Вы хотите, чтобы вас назвали [good_x]...",
		"Чьё-то присутствие сильно возбуждает вас...",
		"Вы начинаете потеть и возбуждаться..."
	)

	to_chat(quirk_holder, span_lewd(pick(notices)))
	notice_delay = world.time + 15 SECONDS
