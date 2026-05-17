/atom/movable/screen/alert/status_effect/psychosis
	name = "Психоз"
	desc = "Реальность ускользает от вас. Что из этого настоящее, а что нет?"
	icon_state = "high"

// Сколько deciseconds снимается с длительности на тик при наличии реагента.
// На один тик psychosis (40 ds = 4 с) база и так списывает 40 ds - эти значения
// добавляются сверху.
#define PSYCHOSIS_HALOPERIDOL_DURATION_CUT  (12 SECONDS)
#define PSYCHOSIS_PSICODINE_DURATION_CUT    (2 SECONDS)
#define PSYCHOSIS_MANNITOL_DURATION_CUT     (4 SECONDS)
/// Шанс, что psicodine "съест" форс-эффект в этот тик.
#define PSYCHOSIS_PSICODINE_SUPPRESS_PROB   60

/datum/status_effect/psychosis
	id = "psychosis"
	duration = 5 MINUTES
	tick_interval = 40
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/psychosis
	/// Шанс на форс-эффект из GLOB.psychosis_hallucination_list на тик (в %).
	/// Не накачиваем mob.hallucination, чтобы базовый handle_hallucinations
	/// не дёргал тяжёлые death/oh_yeah/shock с knockdown'ами.
	var/forced_event_chance = 35
	/// Когда последний раз сообщали игроку, что лекарство работает (cooldown).
	var/next_treatment_message = 0
	examine_text = "<span class='warning'>SUBJECTPRONOUN бормочет себе под нос и затравленно озирается.</span>"

/datum/status_effect/psychosis/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration) && set_duration > 0)
		duration = set_duration
	return ..()

/datum/status_effect/psychosis/on_apply()
	if(!iscarbon(owner))
		return FALSE
	var/mob/living/carbon/C = owner
	// Профилактический эффект: если на момент применения уже есть антипсихотик
	// или анксиолитик, базовая длительность режется. Считаем до того, как
	// родитель прибавит world.time, потому что duration сейчас в "сыром" виде.
	// Бесконечную длительность (-1) не трогаем - её ставят админы/события.
	if(C.reagents && duration > 0)
		if(C.reagents.has_reagent(/datum/reagent/medicine/haloperidol))
			duration = max(10 SECONDS, duration * 0.5)
			to_chat(C, "<span class='notice'>Галоперидол в крови глушит наплыв.</span>")
		else if(C.reagents.has_reagent(/datum/reagent/medicine/psicodine))
			duration = max(20 SECONDS, duration * 0.7)
			to_chat(C, "<span class='notice'>Психодин гасит панику до того, как она успевает раскрутиться.</span>")
	to_chat(C, "<span class='userdanger'>Ваш разум начинает расползаться по швам.</span>")
	return ..()

/datum/status_effect/psychosis/on_remove()
	if(iscarbon(owner))
		var/mob/living/carbon/C = owner
		to_chat(C, "<span class='notice'>Туман в голове рассеивается. Реальность снова на своём месте.</span>")
	return ..()

/datum/status_effect/psychosis/tick()
	if(!iscarbon(owner) || owner.stat == DEAD)
		qdel(src)
		return
	var/mob/living/carbon/C = owner
	var/suppress_event = FALSE
	var/extra_cut = 0
	var/feels_relief = FALSE
	if(C.reagents)
		if(C.reagents.has_reagent(/datum/reagent/medicine/haloperidol))
			extra_cut += PSYCHOSIS_HALOPERIDOL_DURATION_CUT
			suppress_event = TRUE
			feels_relief = TRUE
		if(C.reagents.has_reagent(/datum/reagent/medicine/psicodine))
			extra_cut += PSYCHOSIS_PSICODINE_DURATION_CUT
			if(!suppress_event && prob(PSYCHOSIS_PSICODINE_SUPPRESS_PROB))
				suppress_event = TRUE
			feels_relief = TRUE
		if(C.reagents.has_reagent(/datum/reagent/medicine/mannitol))
			extra_cut += PSYCHOSIS_MANNITOL_DURATION_CUT
	if(extra_cut > 0 && duration != -1)
		duration = max(world.time, duration - extra_cut)
		if(feels_relief && world.time >= next_treatment_message)
			to_chat(C, "<span class='notice'>Тепло прокатывается по затылку, в голове чуть светлее.</span>")
			next_treatment_message = world.time + 25 SECONDS
	if(feels_relief)
		examine_text = "<span class='notice'>SUBJECTPRONOUN явно успокаивается - медикаменты работают.</span>"
	else
		examine_text = initial(examine_text)
	if(suppress_event)
		return
	if(prob(forced_event_chance))
		var/picked = pickweight(GLOB.psychosis_hallucination_list)
		if(picked)
			new picked(C, TRUE)

/mob/living/carbon/proc/apply_psychosis(duration = 5 MINUTES)
	return apply_status_effect(/datum/status_effect/psychosis, duration)

/mob/living/carbon/proc/remove_psychosis()
	return remove_status_effect(/datum/status_effect/psychosis)

#undef PSYCHOSIS_HALOPERIDOL_DURATION_CUT
#undef PSYCHOSIS_PSICODINE_DURATION_CUT
#undef PSYCHOSIS_MANNITOL_DURATION_CUT
#undef PSYCHOSIS_PSICODINE_SUPPRESS_PROB
