// Tier/threshold defines объявлены в code/__BLUEMOONCODE/_DEFINES/psychosis.dm
// (включается до unit_tests).

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
	/// world.time когда статус-эффект встал. Используется для эскалации тиров.
	var/state_started = 0
	/// Текущая тема (одна из PSYCHOSIS_THEME_*) или null для немотивированного безумия.
	var/current_theme = null
	/// Последняя реплика owner'а (raw), кешируется для echo_self.
	var/last_said = ""
	/// Зарегистрирован ли HEAR-слушатель (для отложенной регистрации в MODERATE-тире).
	var/hear_listener_active = FALSE
	examine_text = "<span class='warning'>SUBJECTPRONOUN бормочет себе под нос и затравленно озирается.</span>"

/datum/status_effect/psychosis/on_creation(mob/living/new_owner, set_duration, set_theme)
	// -1 = бесконечная длительность (админы/события). Базовый on_creation
	// сам распознаёт -1 и не превращает его в world.time + duration.
	if(isnum(set_duration) && (set_duration > 0 || set_duration == -1))
		duration = set_duration
	if(set_theme)
		current_theme = set_theme
	return ..()

/datum/status_effect/psychosis/on_apply()
	if(!iscarbon(owner))
		return FALSE
	var/mob/living/carbon/C = owner
	state_started = world.time
	if(isnull(current_theme) && prob(50))
		current_theme = pick(GLOB.psychosis_themes)
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
	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(cache_last_said))
	return ..()

/datum/status_effect/psychosis/refresh(set_duration, set_theme)
	// Свежая доза - свежий отсчет: эскалация тиров стартует заново.
	// HEAR-listener подцепляется только на MODERATE-тире, поэтому при сбросе
	// state_started его тоже надо снять - иначе игрок продолжит ловить
	// mishearing/wrong_voice, пока тир-пул откатывается обратно до MILD.
	state_started = world.time
	unregister_passive_listeners()
	if(isnum(set_duration) && set_duration > 0)
		duration = world.time + set_duration
	else if(isnum(set_duration) && set_duration == -1)
		// Явный запрос на бесконечную длительность (админ/событие).
		duration = -1
	else
		// Базовый refresh() игнорирует -1 (бесконечная длительность от админов).
		if(duration != -1)
			duration = world.time + initial(duration)
	if(set_theme)
		current_theme = set_theme

/datum/status_effect/psychosis/on_remove()
	if(iscarbon(owner))
		var/mob/living/carbon/C = owner
		UnregisterSignal(C, COMSIG_MOB_SAY)
		unregister_passive_listeners()
		to_chat(C, "<span class='notice'>Туман в голове рассеивается. Реальность снова на своём месте.</span>")
	return ..()

/datum/status_effect/psychosis/tick()
	if(!iscarbon(owner) || owner.stat == DEAD)
		qdel(src)
		return
	var/mob/living/carbon/C = owner
	if(!hear_listener_active && (world.time - state_started >= PSYCHOSIS_MODERATE_THRESHOLD))
		register_passive_listeners()
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
		var/picked = pick_hallucination()
		if(picked)
			new picked(C, TRUE)

/// Выбирает тип галлюцинации с учётом текущего тира (по времени) и темы.
/datum/status_effect/psychosis/proc/pick_hallucination()
	if(!length(GLOB.psychosis_pool_by_tier))
		build_psychosis_tier_pools()
	var/elapsed = world.time - state_started
	var/list/pool = GLOB.psychosis_pool_by_tier[PSYCHOSIS_TIER_MILD].Copy()
	if(elapsed >= PSYCHOSIS_MODERATE_THRESHOLD)
		pool += GLOB.psychosis_pool_by_tier[PSYCHOSIS_TIER_MODERATE]
	if(elapsed >= PSYCHOSIS_SEVERE_THRESHOLD)
		pool += GLOB.psychosis_pool_by_tier[PSYCHOSIS_TIER_SEVERE]
	if(current_theme)
		for(var/type in pool)
			var/datum/hallucination/psychosis/proto = type
			var/list/type_themes = initial(proto.themes)
			if(type_themes && (current_theme in type_themes))
				pool[type] *= PSYCHOSIS_THEME_BIAS
#ifdef PSYCHOSIS_DEBUG_LOG
	var/elapsed_s = (world.time - state_started) / 10
	var/picked_for_log = pickweight(pool)
	psy_log("pick owner=[owner] elapsed=[elapsed_s]s theme=[current_theme || "none"] pool_size=[length(pool)] picked=[picked_for_log]")
	return picked_for_log
#else
	return pickweight(pool)
#endif

/mob/living/carbon/proc/apply_psychosis(duration = 5 MINUTES, theme = null)
	// Базовый apply_status_effect() при STATUS_EFFECT_REFRESH вызывает refresh()
	// без аргументов, поэтому новые duration/theme от повторной волны теряются.
	// Перехватываем здесь и обновляем активный эффект напрямую.
	var/datum/status_effect/psychosis/existing = has_status_effect(/datum/status_effect/psychosis)
	if(existing)
		existing.refresh(duration, theme)
		return existing
	return apply_status_effect(/datum/status_effect/psychosis, duration, theme)

/mob/living/carbon/proc/remove_psychosis()
	return remove_status_effect(/datum/status_effect/psychosis)

/// Накапливает последнюю реплику owner'а для echo_self.
/datum/status_effect/psychosis/proc/cache_last_said(datum/source, list/speech_args)
	SIGNAL_HANDLER
	if(!speech_args || !length(speech_args))
		return
	// SPEECH_MESSAGE = 1 (см. code/__DEFINES/dcs/signals.dm).
	var/msg = speech_args[SPEECH_MESSAGE]
	if(istext(msg) && length(msg) > 0)
		last_said = msg

/// Подключает слушатель речи окружающих. Безопасно вызывать повторно.
/datum/status_effect/psychosis/proc/register_passive_listeners()
	if(hear_listener_active || !iscarbon(owner))
		return
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(on_hear_distort))
	hear_listener_active = TRUE

/datum/status_effect/psychosis/proc/unregister_passive_listeners()
	if(!hear_listener_active || !iscarbon(owner))
		return
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	hear_listener_active = FALSE

/// Перехватывает входящую речь и с малым шансом подменяет фрагмент или имя спикера.
/// Оба эффекта независимы и могут сработать на одном сообщении.
/datum/status_effect/psychosis/proc/on_hear_distort(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	if(!hearing_args || !length(hearing_args))
		return
	var/atom/movable/speaker = hearing_args[HEARING_SPEAKER]
	if(speaker == owner || isnull(speaker))
		return

	// Mishearing: 6% подмена фрагмента речи через словарь.
	// HEARING_MESSAGE тут трогать бессмысленно - /mob/living/Hear() сразу
	// после сигнала пересобирает финальный текст через compose_message()
	// из HEARING_RAW_MESSAGE и HEARING_SPEAKER, перетирая нашу правку.
	if(prob(6))
		var/raw = hearing_args[HEARING_RAW_MESSAGE]
		if(raw)
			var/distorted = distort_message(raw)
			if(distorted != raw)
				hearing_args[HEARING_RAW_MESSAGE] = distorted

	// Wrong voice: 2% подмена голоса на покойника. Имя спикера в шапке мы
	// поменять без подмены атома не можем (compose_message берёт его из
	// speaker.GetVoice()), поэтому встраиваем покойничью атрибуцию прямо
	// в тело сообщения через raw_message - это переживёт пересборку.
	if(prob(2))
		var/list/dead_pool = list()
		for(var/mob/living/carbon/human/dead_mob in GLOB.dead_mob_list)
			if(dead_mob.real_name && length(dead_mob.real_name))
				dead_pool += dead_mob.real_name
		if(length(dead_pool))
			var/dead_name = pick(dead_pool)
			var/raw = hearing_args[HEARING_RAW_MESSAGE]
			if(istext(raw) && length(raw))
				hearing_args[HEARING_RAW_MESSAGE] = "<i>(голосом [dead_name], покойного)</i> [raw]"

#undef PSYCHOSIS_HALOPERIDOL_DURATION_CUT
#undef PSYCHOSIS_PSICODINE_DURATION_CUT
#undef PSYCHOSIS_MANNITOL_DURATION_CUT
#undef PSYCHOSIS_PSICODINE_SUPPRESS_PROB
