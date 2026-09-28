#define DANCE_BOLERO_FINALE_STAGE (HERETIC_DANCE_BOLERO_STAGES + 1)
#define DANCE_BOLERO_PULSE_RANGE 3
#define DANCE_BOLERO_PULSE_BRUTE 10
#define DANCE_BOLERO_PULSE_STAMINA 15
#define DANCE_BOLERO_HOROVOD_LIMIT 4
#define DANCE_BOLERO_HOROVOD_TIME (6 SECONDS)
#define DANCE_FALSE_NOTE_COOLDOWN (15 SECONDS)

GLOBAL_LIST_EMPTY(heretic_dance_boleros)
GLOBAL_LIST_INIT(heretic_dance_bolero_phrases, list(
	list('modular_bluemoon/sound/heretic/dance/bolero_1_1.ogg', 'modular_bluemoon/sound/heretic/dance/bolero_1_2.ogg'),
	list('modular_bluemoon/sound/heretic/dance/bolero_2_1.ogg', 'modular_bluemoon/sound/heretic/dance/bolero_2_2.ogg'),
	list('modular_bluemoon/sound/heretic/dance/bolero_3_1.ogg', 'modular_bluemoon/sound/heretic/dance/bolero_3_2.ogg'),
	list('modular_bluemoon/sound/heretic/dance/bolero_4_1.ogg', 'modular_bluemoon/sound/heretic/dance/bolero_4_2.ogg'),
	list('modular_bluemoon/sound/heretic/dance/bolero_5_1.ogg', 'modular_bluemoon/sound/heretic/dance/bolero_5_2.ogg'),
	list('modular_bluemoon/sound/heretic/dance/bolero_6_1.ogg', 'modular_bluemoon/sound/heretic/dance/bolero_6_2.ogg'),
))
GLOBAL_LIST_INIT(heretic_dance_bolero_finale, list('modular_bluemoon/sound/heretic/dance/bolero_finale_1.ogg', 'modular_bluemoon/sound/heretic/dance/bolero_finale_2.ogg'))
GLOBAL_LIST_INIT(heretic_dance_voices, list('modular_bluemoon/sound/heretic/dance/voice_1.ogg', 'modular_bluemoon/sound/heretic/dance/voice_2.ogg', 'modular_bluemoon/sound/heretic/dance/voice_3.ogg', 'modular_bluemoon/sound/heretic/dance/voice_4.ogg'))

/datum/eldritch_knowledge/final_eldritch/dance_final
	name = "Болеро"
	summary = "Стойкость вознесения и Болеро: каждые 30 секунд вступает новый стиль, после пятого - Финал."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне станции; обряд длится 30 секунд.",
		"Малый барабан Болеро слышат все на уровне, с каждой ступенью громче.",
		"Каждые 30 секунд к вам навсегда добавляется пассивка следующего стиля: Вальс, Танго, Тарантелла, Канкан, Пляска смерти.",
		"Финал: каждая сильная доля бьёт врагов в 3 клетках на 10 ушибов и 15 выносливости и тянет до 4 из них в хоровод.",
		"Под вами ползёт паркет; Большой хоровод бесплатно тянет до 6 врагов в 4 клетках, перезарядка 45 секунд.",
		"Фальшивая нота - светошумовая, клаксон или воздушный горн в 7 клетках - сбрасывает ступень и глушит Болеро на 7 секунд.",
		"Нота сбивает Болеро не чаще раза в 15 секунд.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Оркестр начал с одного барабана. Когда вступили все инструменты, на станции не осталось никого, кто стоял бы на месте."
	route = PATH_DANCE
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_dance/great_horovod)
	var/datum/weakref/dance_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/dance_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dance/dance = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dance)
	if(!dance)
		return
	dance_knowledge_ref = WEAKREF(dance)
	dance.start_bolero()

/datum/eldritch_knowledge/final_eldritch/dance_final/on_body_lose(mob/living/user)
	var/datum/eldritch_knowledge/base_dance/dance = dance_knowledge_ref?.resolve()
	dance?.stop_bolero()
	return ..()

/datum/eldritch_knowledge/final_eldritch/dance_final/on_ascended_examine(datum/source, mob/examiner, list/examine_list)
	. = ..()
	var/datum/eldritch_knowledge/base_dance/dance = dance_knowledge_ref?.resolve()
	if(!dance?.bolero_on)
		return
	examine_list += span_warning("Вокруг гремит Болеро: ступень [dance.bolero_stage] из [DANCE_BOLERO_FINALE_STAGE]. Светошумовая, клаксон или воздушный горн рядом собьют музыку фальшивой нотой.")

/datum/eldritch_knowledge/base_dance
	var/bolero_on = FALSE
	var/bolero_stage = 0
	var/bolero_next_at = 0
	var/bolero_silent_until = 0
	var/list/bolero_passives = list()
	COOLDOWN_DECLARE(false_note_cooldown)

/datum/eldritch_knowledge/base_dance/proc/start_bolero()
	if(bolero_on)
		return
	bolero_on = TRUE
	bolero_stage = 0
	bolero_next_at = world.time + HERETIC_DANCE_BOLERO_STAGE_TIME
	GLOB.heretic_dance_boleros |= src
	to_chat(dance_body, span_eldritch("Болеро началось. Каждые [HERETIC_DANCE_BOLERO_STAGE_TIME / (1 SECONDS)] секунд вступает новый стиль; не дайте им сбить музыку фальшивой нотой."))

/datum/eldritch_knowledge/base_dance/proc/stop_bolero()
	if(!bolero_on)
		return
	bolero_on = FALSE
	bolero_stage = 0
	refresh_bolero_passives()
	GLOB.heretic_dance_boleros -= src
	update_passive()

/datum/eldritch_knowledge/base_dance/bolero_active()
	return bolero_on && world.time >= bolero_silent_until

/datum/eldritch_knowledge/base_dance/bolero_phrase()
	if(bolero_stage >= DANCE_BOLERO_FINALE_STAGE)
		return pick(GLOB.heretic_dance_bolero_finale)
	var/list/stage_phrases = GLOB.heretic_dance_bolero_phrases[clamp(bolero_stage + 1, 1, length(GLOB.heretic_dance_bolero_phrases))]
	return pick(stage_phrases)

/datum/eldritch_knowledge/base_dance/bolero_keeps_passive(id)
	if(!bolero_on)
		return FALSE
	var/index = GLOB.heretic_dance_styles.Find(id)
	return index && index <= bolero_stage

/// Пассивки стилей Болеро, кроме текущего: текущий включает и выключает set_passive.
/datum/eldritch_knowledge/base_dance/proc/refresh_bolero_passives()
	var/list/wanted = list()
	if(bolero_on && dance_body)
		for(var/id in GLOB.heretic_dance_styles)
			if(id != style_id && bolero_keeps_passive(id))
				wanted += id
	for(var/id in bolero_passives.Copy())
		if(id in wanted)
			continue
		var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[id]
		if(dance_body)
			style.passive_off(src, dance_body)
		bolero_passives -= id
	for(var/id in wanted)
		if(id in bolero_passives)
			continue
		var/datum/heretic_dance_style/style = GLOB.heretic_dance_styles[id]
		style.passive_on(src, dance_body)
		bolero_passives += id

/datum/eldritch_knowledge/base_dance/proc/bolero_beat(strong)
	if(!bolero_on || QDELETED(dance_body) || dance_body.stat == DEAD)
		return
	if(world.time < bolero_silent_until)
		return
	if(bolero_stage < DANCE_BOLERO_FINALE_STAGE && world.time >= bolero_next_at)
		set_bolero_stage(bolero_stage + 1)
	if(!strong)
		return
	broadcast_bolero()
	if(bolero_stage >= DANCE_BOLERO_FINALE_STAGE)
		finale_pulse()

/datum/eldritch_knowledge/base_dance/proc/set_bolero_stage(stage)
	bolero_stage = clamp(stage, 0, DANCE_BOLERO_FINALE_STAGE)
	bolero_next_at = world.time + HERETIC_DANCE_BOLERO_STAGE_TIME
	refresh_bolero_passives()
	update_passive()
	var/turf/place = get_turf(dance_body)
	if(place)
		new /obj/effect/temp_visual/heretic_dance/bolero(place)
	if(bolero_stage >= DANCE_BOLERO_FINALE_STAGE)
		dance_body.visible_message(span_danger("Болеро обрушивается всем оркестром: начинается Финал!"))
		return
	var/list/order = GLOB.heretic_dance_styles
	if(bolero_stage > 0)
		var/datum/heretic_dance_style/joined = order[order[bolero_stage]]
		to_chat(dance_body, span_eldritch("В Болеро вступает [lowertext(joined.name)]: его пассивка теперь с вами."))

/// Барабан Болеро слышен всему уровню, чем выше ступень, тем громче.
/datum/eldritch_knowledge/base_dance/proc/broadcast_bolero()
	var/turf/center = get_turf(dance_body)
	if(!center)
		return
	var/sound_file = bolero_phrase()
	var/volume = 8 + bolero_stage * 4
	for(var/mob/living/listener as anything in GLOB.player_list)
		if(!isliving(listener) || listener == dance_body || (listener in dancers) || listener.z != center.z || !listener.client)
			continue
		listener.playsound_local(get_turf(listener), sound_file, volume, FALSE)

/datum/eldritch_knowledge/base_dance/proc/finale_pulse()
	var/turf/center = get_turf(dance_body)
	if(!center)
		return
	new /obj/effect/temp_visual/heretic_dance/bolero(center)
	for(var/mob/living/carbon/victim in range(DANCE_BOLERO_PULSE_RANGE, dance_body))
		if(!heretic_edge_line_clear(dance_body, victim) || !heretic_can_affect(dance_body, victim, chargecost = 0, notify = FALSE))
			continue
		victim.adjustBruteLoss(DANCE_BOLERO_PULSE_BRUTE)
		victim.adjustStaminaLoss(DANCE_BOLERO_PULSE_STAMINA)
	start_horovod(dance_body, DANCE_BOLERO_HOROVOD_TIME, DANCE_BOLERO_HOROVOD_LIMIT, DANCE_BOLERO_PULSE_RANGE)

/datum/eldritch_knowledge/base_dance/proc/false_note(turf/origin)
	if(!bolero_on || !COOLDOWN_FINISHED(src, false_note_cooldown))
		return FALSE
	COOLDOWN_START(src, false_note_cooldown, DANCE_FALSE_NOTE_COOLDOWN)
	bolero_silent_until = world.time + HERETIC_DANCE_FALSE_NOTE_SILENCE
	set_bolero_stage(bolero_stage - 1)
	bolero_next_at = bolero_silent_until + HERETIC_DANCE_BOLERO_STAGE_TIME
	playsound(dance_body, 'modular_bluemoon/sound/heretic/dance/false_note.ogg', 80, FALSE)
	dance_body.visible_message(span_warning("Фальшивая нота врезается в Болеро, и оркестр сбивается!"), span_userdanger("Фальшивая нота! Болеро сбилось на ступень назад и молчит [HERETIC_DANCE_FALSE_NOTE_SILENCE / (1 SECONDS)] секунд."))
	log_game("[key_name(dance_body)]: Болеро сбито фальшивой нотой в [AREACOORD(origin)].")
	return TRUE

/// Громкий чужой звук рядом с вознёсшимся плясуном сбивает Болеро.
/proc/heretic_dance_false_note(turf/origin)
	if(!origin || !length(GLOB.heretic_dance_boleros))
		return
	for(var/datum/eldritch_knowledge/base_dance/dance as anything in GLOB.heretic_dance_boleros)
		var/turf/place = get_turf(dance.dance_body)
		if(place && place.z == origin.z && get_dist(place, origin) <= HERETIC_DANCE_FALSE_NOTE_RANGE)
			dance.false_note(origin)

/obj/effect/proc_holder/spell/self/heretic_dance/great_horovod
	name = "Большой хоровод"
	desc = "Бесплатно тянет до 6 врагов в 4 клетках в хоровод на 6 секунд. Лежачих, сидящих, пристёгнутых, схваченных, глухих и защищённых от магии хоровод не берёт. Перезарядка 45 секунд."
	summary = "Бесплатно тянет до 6 врагов в 4 клетках в хоровод на 6 секунд."
	action_icon_state = "dance_bolero"
	charge_max = 45 SECONDS

/obj/effect/proc_holder/spell/self/heretic_dance/great_horovod/can_cast(mob/user, skipcharge, silent)
	var/datum/eldritch_knowledge/base_dance/dance = dance_of(user)
	return ..() && heretic_check(user, dance?.bolero_on, silent, "Сначала завершите вознесение этого пути.")

/obj/effect/proc_holder/spell/self/heretic_dance/great_horovod/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dance/dance = dance_of(user)
	if(!dance?.start_horovod(user, 6 SECONDS, 6, 4))
		heretic_revert_cast(user, "Рядом нет никого, кого хоровод мог бы подхватить.")
		return
	playsound(user, HERETIC_DANCE_BELL_SOUND, 80, TRUE)

#undef DANCE_BOLERO_FINALE_STAGE
#undef DANCE_BOLERO_PULSE_RANGE
#undef DANCE_BOLERO_PULSE_BRUTE
#undef DANCE_BOLERO_PULSE_STAMINA
#undef DANCE_BOLERO_HOROVOD_LIMIT
#undef DANCE_BOLERO_HOROVOD_TIME
#undef DANCE_FALSE_NOTE_COOLDOWN
