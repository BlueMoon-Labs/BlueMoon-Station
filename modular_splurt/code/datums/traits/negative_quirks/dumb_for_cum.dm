/datum/quirk/dumb4cum
	name = "Спермоприёмник"
	desc = "По той или иной причине, вы помешаны на сперме. Её тепло, запах... вкус... делают счастливее."
	value = 0
	mob_trait = TRAIT_DUMB_CUM
	flavor_quirk = TRUE
	gain_text = span_notice("Неожиданно вам захотелось ощутить семя внутри себя!")
	lose_text = span_notice("Всё равно сперма была не такой уж и вкусной...")
	medical_record_text = "У пациента навязчивая одержимость семенными жидкостями."
	mood_quirk = TRUE
	var/timer
	var/timer_trigger
	var/reminder_timer
	var/reminder_trigger
	var/list/trigger_phrases = list(
										"У тебя урчит в животе, а на ум приходит сперма.",\
										"Уф-ф, сейчас бы не помешало раздобыть спермы...",\
										"Было бы неплохо сейчас потребить спермы!",\
										"Ты начинаешь тосковать по сперме..."
									  )
	var/list/uncrave_phrases = list("Ааахх~ сперма~ наконец-то!~",\
									"Это ощущение свежей спермы во мне... бесценно~",\
									"Ммм~, мне так не хватало этой восхитительной спермы~"
									)

/datum/quirk/dumb4cum/add()
	// Set timer
	timer_trigger = rand(9000, 18000)
	timer = addtimer(CALLBACK(src, PROC_REF(crave)), timer_trigger, TIMER_STOPPABLE)

/datum/quirk/dumb4cum/remove()
	// Remove status trait
	REMOVE_TRAIT(quirk_holder, TRAIT_DUMB_CUM_CRAVE, DUMB_CUM_TRAIT)

	// Remove penalty traits
	REMOVE_TRAIT(quirk_holder, TRAIT_ILLITERATE, DUMB_CUM_TRAIT)
	REMOVE_TRAIT(quirk_holder, TRAIT_DUMB, DUMB_CUM_TRAIT)

	// Remove mood event
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, QMOOD_DUMB_CUM)

	// Remove timer
	deltimer(timer)
	deltimer(reminder_timer)

/datum/quirk/dumb4cum/proc/crave()
	// Check if conscious
	if(quirk_holder.stat == CONSCIOUS)
		// Alert user in chat
		to_chat(quirk_holder, span_love("[pick(trigger_phrases)]"))

	reminder_trigger = rand(3000, 9000)
	reminder_timer = addtimer(CALLBACK(src, PROC_REF(reminder)), reminder_trigger, TIMER_STOPPABLE)

	// Add active status trait
	ADD_TRAIT(quirk_holder, TRAIT_DUMB_CUM_CRAVE, DUMB_CUM_TRAIT)

	// Add illiterate, dumb, and pacifist
	ADD_TRAIT(quirk_holder, TRAIT_ILLITERATE, DUMB_CUM_TRAIT)
	ADD_TRAIT(quirk_holder, TRAIT_DUMB, DUMB_CUM_TRAIT)

	// Add negative mood effect
	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_DUMB_CUM, /datum/mood_event/cum_craving)

/datum/quirk/dumb4cum/proc/reminder()
	to_chat(quirk_holder, span_love("[pick(trigger_phrases)]"))
	deltimer(reminder_timer)
	reminder_timer = null
	reminder_trigger = rand(3000, 9000)
	reminder_timer = addtimer(CALLBACK(src, PROC_REF(reminder)), reminder_trigger, TIMER_STOPPABLE)
	quirk_holder.overlay_fullscreen("dumb_cum_depression", /atom/movable/screen/fullscreen/scaled/depression, 2)
	quirk_holder.clear_fullscreen("dumb_cum_depression", 15 SECONDS)

/datum/quirk/dumb4cum/proc/uncrave(visible_effect = TRUE)
	// Remove active status trait
	REMOVE_TRAIT(quirk_holder, TRAIT_DUMB_CUM_CRAVE, DUMB_CUM_TRAIT)

	// Remove penalty traits
	REMOVE_TRAIT(quirk_holder, TRAIT_ILLITERATE, DUMB_CUM_TRAIT)
	REMOVE_TRAIT(quirk_holder, TRAIT_DUMB, DUMB_CUM_TRAIT)

	// Add positive mood event
	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_DUMB_CUM, /datum/mood_event/cum_stuffed)

	// Remove timer
	deltimer(timer)
	deltimer(reminder_timer)
	timer = null
	reminder_timer = null
	timer_trigger = rand(9000, 18000)
	// Add new timer
	timer = addtimer(CALLBACK(src, PROC_REF(crave)), timer_trigger, TIMER_STOPPABLE)

	if(visible_effect)
		quirk_holder.set_drugginess(2)
		to_chat(quirk_holder, span_love("[pick(uncrave_phrases)]"))

/datum/mood_event/cum_craving
	description = span_warning("МНЕ... НУЖНА... СПЕРМА...\n") // Я умер от испанского стыда, переводя ЕРП мудлеты. - прим. переводчика
	//mood_change = -20
	mood_change = -5 //STOP BEING SUICIDAL BECAUSE OF THE LACK OF CUM! - Gardelin0

/datum/mood_event/cum_stuffed
	description = span_lewd("Сперма ощущается так приятно внутри меня~\n")
	mood_change = 8
	timeout = 5 MINUTES
