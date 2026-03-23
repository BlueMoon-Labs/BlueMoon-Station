//Ставлю тут дефайны феромонов
#define TRAIT_UR_PHEROMONES "ur_pheromones"

/datum/quirk/ur_pheromones
	name = "Твои феромоны"
	desc = "Вы источаете феромоны, что странно влияют на чувствительных к ним существам. Они испытывают к вам возбуждение и желание принять вашу ласку и любовь."
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы источаете страный и нейтральный запах.</span>"
	lose_text = "<span class='notice'>Странный и нейтральный запах пропадает.</span>"

/datum/quirk/ur_pheromones/add()
	. = ..()
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/quirk/ur_pheromones/remove()
	. = ..()
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)
	UnregisterSignal(quirk_holder, COMSIG_MOB_EMOTE)

/datum/quirk/ur_pheromones/proc/on_examine_holder(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(!ishuman(user))
		return
	var/mob/living/carbon/human/sub = user
	if(!sub.has_quirk(/datum/quirk/sensitive_to_pheramones) || (sub == quirk_holder))
		return

	examine_list += span_lewd("\nВы испытываете сильное возбуждение при взгляде на [quirk_holder.ru_na()] и краснеете!")
	if(!TIMER_COOLDOWN_CHECK(user, COOLDOWN_PHEROMON_AURA))
		to_chat(quirk_holder, span_notice("[user] смотрит на вас и сильно краснеет, издавая тихий стон..."))
		TIMER_COOLDOWN_START(user, COOLDOWN_PHEROMON_AURA, 10 SECONDS)
		sub.emote ("moan")
		sub.emote("blush")

// Ставлю дефайны феромонов

#define TRAIT_SENSITIVE_TO_PHERAMONES "sensitive_to_pheramones"

/datum/quirk/sensitive_to_pheramones
	name = "Чувствительный к феромонам"
	desc = "Вы ощущаете феромоны самцов или самок, что хотят размножения. Эти феромоны опутывают ваш разум желанием спаривания."
	value = 0
	gain_text = span_notice("Вы чувствуете феромоны окружающих...")
	lose_text = span_notice("Вы больше не чувствуете феромны вокруг себя...")
	processing_quirk = TRUE
	flavor_quirk = TRUE
	var/notice_delay = 0
	var/mob/living/carbon/human/last_feromon

/datum/quirk/sensitive_to_pheramones/add()
	. = ..()
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/quirk/sensitive_to_pheramones/remove()
	. = ..()
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

/datum/quirk/sensitive_to_pheramones/proc/on_examine_holder(atom/source, mob/living/user, list/examine_list)
	SIGNAL_HANDLER

	if(!istype(user))
		return
	if(!user.has_quirk(/datum/quirk/ur_pheromones))
		return
	examine_list += span_lewd("Вы чувствуете сладкий непонятный запах от [quirk_holder.ru_nego()], ваш разум заполняет желание секса.")


	//Check for possible doms with the dominant_aura quirk, and for the closest one if there is
	var/mob/living/carbon/human/closest_phero
	var/list/mob/living/carbon/human/pheros = range(PHEROMONS_DETECT_RANGE, quirk_holder)
	var/closest_distance
	for(var/mob/living/carbon/human/phero in pheros)
		if(phero != quirk_holder && phero.has_quirk(/datum/quirk/ur_pheromones))
			if(!closest_distance || get_dist(quirk_holder, phero) <= closest_distance)
				closest_phero = phero
				closest_distance = get_dist(quirk_holder, phero)

	//Return if no dom is found
	if(!closest_phero)
		last_feromon = null
		return

	//Handle the mood
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(istype(mood.mood_events[QMOOD_SENS_PHEROMONS], /datum/mood_event/pheromon/i_feel))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_SENS_PHEROMONS, /datum/mood_event/pheromon/i_feel)
	else
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_SENS_PHEROMONS, /datum/mood_event/pheromon/i_need)

	//Don't do anything if a previous dom was found
	if(last_feromon)
		notice_delay = world.time + 15 SECONDS
		return

	last_feromon = closest_phero

	if(notice_delay > world.time)
		return

	//Let them know they're near
	var/list/notices = list(
		"Вы ощущаете, как чьё-то присутствие делает вас возбужденным...",
		"Мысли о том, чтобы вы занялись сексом, заполняют ваш разум похотью...",
		"Чьё-то присутствие сильно возбуждает вас...",
		"Вы начинаете потеть и возбуждаться..."
	)

	to_chat(quirk_holder, span_lewd(pick(notices)))
	notice_delay = world.time + 15 SECONDS
