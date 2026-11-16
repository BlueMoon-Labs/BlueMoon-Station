#define MIN_DEPRESS_TIMER 10 // минимальное время до начала приступа депрессии в минутах
#define MAX_DEPRESS_TIMER 30 // максимальное время до начала приступа депрессии в минутах

/datum/quirk/depression
	name = "Депрессия"
	desc = "У вас случаются острые приступы депрессии, что получается подавить только благодаря химии. \[Вместе с тем выключение венъетки настроения более не работает\]"
	mob_trait = TRAIT_DEPRESSION
	value = -1
	gain_text = "<span class='danger'>У вас начинается депрессия.</span>"
	medical_record_text = "У пациента наблюдаются серьёзные перепады настроения, вызывающие острые периоды депрессии."
	lose_text = "<span class='notice'>У вас больше нет депрессии.</span>" //if only it were that easy!
	mood_quirk = TRUE
	processing_quirk = TRUE
	var/in_depression = FALSE
	var/later_start = FALSE // не тригерим если мы умераем, спим или не двигаемся - начинаем депресуху при первой возможности
	COOLDOWN_DECLARE(advent_timer) // пик нейминга, таймер перед новым приступом депресии

/datum/quirk/depression/on_spawn()
	if(prob(5))
		later_start = TRUE
	COOLDOWN_START(src, advent_timer, rand(MIN_DEPRESS_TIMER, MAX_DEPRESS_TIMER) MINUTES)

/datum/quirk/depression/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(HAS_TRAIT(H, TRAIT_FEARLESS)) // трейт от Psicodine или Happiness
		if(in_depression && prob(5)) // примерно за минуту точно сработает
			to_chat(quirk_holder, span_notice("Возможно жизнь не так плоха."))
			COOLDOWN_START(src, advent_timer, rand(MIN_DEPRESS_TIMER, MAX_DEPRESS_TIMER) MINUTES)
			in_depression = FALSE
			SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "depression", /datum/mood_event/depression)
		if(later_start) // предотвращение депресухи заранее
			to_chat(quirk_holder, span_notice("Вы чувствуете, что мир вокруг стал чуть ярче."))
			later_start = FALSE
			COOLDOWN_START(src, advent_timer, rand(MIN_DEPRESS_TIMER, MAX_DEPRESS_TIMER) MINUTES)
		return

	if((COOLDOWN_FINISHED(src, advent_timer) && !in_depression) || later_start)
		if(H.insanelycomfy || quirk_holder.stat) // проснулись, потянулись, а после сразу-же ловим депресуху не выпив таблеток перед выходом из кровати
			later_start = TRUE
			return
		to_chat(quirk_holder, span_warning("Вы чувствуете, что краски жизни смыло в сторону."))
		in_depression = TRUE
		later_start = FALSE
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "depression", /datum/mood_event/depression)

#undef MIN_DEPRESS_TIMER
#undef MAX_DEPRESS_TIMER
