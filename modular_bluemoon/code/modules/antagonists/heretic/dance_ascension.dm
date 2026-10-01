#define DANCE_BOLERO_FINALE_STAGE (HERETIC_DANCE_BOLERO_STAGES + 1)
#define DANCE_BOLERO_PULSE_RANGE 3
#define DANCE_BOLERO_PULSE_BRUTE 10
#define DANCE_BOLERO_PULSE_STAMINA 15
#define DANCE_BOLERO_HOROVOD_LIMIT 4
#define DANCE_BOLERO_HOROVOD_TIME (6 SECONDS)
#define DANCE_FALSE_NOTE_COOLDOWN (15 SECONDS)
#define DANCE_FINALE_WARNING (8 SECONDS)
#define DANCE_GHOST_LIMIT 6

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
		"Малый барабан Болеро слышат все на уровне, всё громче. Пока оно играет, любой стиль идёт в его темпе: 0,7 с, 3 в такте.",
		"Каждые 30 секунд к вам навсегда добавляется пассивка следующего стиля: Вальс, Танго, Тарантелла, Канкан, Пляска смерти.",
		"Финал: каждая сильная доля бьёт врагов в 3 клетках на 10 ушибов и 15 выносливости и тянет до 4 из них в хоровод.",
		"Ступени зовут призрачные пары и бал за иллюминаторы; перед каждым ударом Финала пары стягиваются, а рампа вспыхивает.",
		"Под вами ползёт паркет; Большой хоровод бесплатно тянет до 6 врагов в 4 клетках, перезарядка 45 секунд.",
		"Фальшивая нота (светошумовая, клаксон, горн в 7 клетках) сбивает ступень и глушит Болеро на 7 с, не чаще раза в 15 с.",
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

/// Небо над местом вознесения меняется со ступенью Болеро: бал, оркестр, Финал.
/datum/eldritch_knowledge/final_eldritch/dance_final/proc/show_bolero_scene(stage)
	if(!finished)
		return
	var/sky_tier = 0
	if(stage > HERETIC_DANCE_BOLERO_STAGES)
		sky_tier = 3
	else if(stage >= 3)
		sky_tier = 2
	else if(stage >= 1)
		sky_tier = 1
	GLOB.heretic_sky.tier(src, sky_tier)
	if(sky_tier == 3)
		GLOB.heretic_sky.event(src)

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
	var/list/obj/effect/abstract/heretic_dance_ghost/bolero_ghosts = list()
	var/finale_warned = FALSE
	/// Оркестр сбит фальшивой нотой и молчит; вступит снова, когда кончится тишина.
	var/bolero_broken = FALSE
	/// Фраза такта Болеро выбирается один раз и звучит у всех: у танцоров и у всего уровня.
	var/bolero_bar_phrase
	var/bolero_bar_beat = -1
	COOLDOWN_DECLARE(false_note_cooldown)

/datum/eldritch_knowledge/base_dance/proc/start_bolero()
	if(bolero_on)
		return
	bolero_on = TRUE
	bolero_stage = 0
	bolero_next_at = world.time + HERETIC_DANCE_BOLERO_STAGE_TIME
	GLOB.heretic_dance_boleros |= src
	apply_tempo()
	if(dance_body)
		restart_clock()
	to_chat(dance_body, span_eldritch("Болеро началось. Каждые [HERETIC_DANCE_BOLERO_STAGE_TIME / (1 SECONDS)] секунд вступает новый стиль; не дайте им сбить музыку фальшивой нотой."))

/datum/eldritch_knowledge/base_dance/proc/stop_bolero()
	if(!bolero_on)
		return
	bolero_on = FALSE
	bolero_stage = 0
	finale_warned = FALSE
	bolero_broken = FALSE
	update_ghosts()
	refresh_bolero_passives()
	GLOB.heretic_dance_boleros -= src
	update_passive()
	apply_tempo()
	if(dance_body)
		restart_clock()

/datum/eldritch_knowledge/base_dance/proc/bolero_active()
	return bolero_on && world.time >= bolero_silent_until

/datum/eldritch_knowledge/base_dance/proc/bolero_phrase()
	if(bolero_bar_beat == beat_total && bolero_bar_phrase)
		return bolero_bar_phrase
	bolero_bar_beat = beat_total
	if(bolero_stage >= DANCE_BOLERO_FINALE_STAGE)
		bolero_bar_phrase = pick(GLOB.heretic_dance_bolero_finale)
	else
		var/list/stage_phrases = GLOB.heretic_dance_bolero_phrases[clamp(bolero_stage + 1, 1, length(GLOB.heretic_dance_bolero_phrases))]
		bolero_bar_phrase = pick(stage_phrases)
	return bolero_bar_phrase

/datum/eldritch_knowledge/base_dance/proc/bolero_keeps_passive(id)
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
	if(bolero_broken)
		orchestra_return()
	if(bolero_stage < DANCE_BOLERO_FINALE_STAGE && world.time >= bolero_next_at)
		set_bolero_stage(bolero_stage + 1)
	var/finale_near = bolero_stage == HERETIC_DANCE_BOLERO_STAGES && bolero_next_at - world.time <= DANCE_FINALE_WARNING
	if(finale_near && !finale_warned)
		finale_warned = TRUE
		dance_body.visible_message(span_userdanger("Оркестр набирает дыхание: скоро Финал! Рампа вокруг [dance_body] очерчивает, куда ударит музыка."), span_eldritch("Финал через [round((bolero_next_at - world.time) / (1 SECONDS))] секунд: рампа показывает всем зону удара."))
	if(!strong)
		if(bolero_stage >= DANCE_BOLERO_FINALE_STAGE && (beat_index + 1) % meter == 0)
			finale_inhale()
		return
	broadcast_bolero()
	heretic_dance_hop(dance_body, TRUE)
	if(finale_near)
		mark_finale_zone(TRUE)
	if(bolero_stage >= DANCE_BOLERO_FINALE_STAGE)
		mark_finale_zone(FALSE)
		finale_pulse()

/datum/eldritch_knowledge/base_dance/proc/set_bolero_stage(stage)
	bolero_stage = clamp(stage, 0, DANCE_BOLERO_FINALE_STAGE)
	bolero_next_at = world.time + HERETIC_DANCE_BOLERO_STAGE_TIME
	if(bolero_stage < HERETIC_DANCE_BOLERO_STAGES)
		finale_warned = FALSE
	refresh_bolero_passives()
	update_passive()
	update_ghosts()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(dance_body)
	var/datum/eldritch_knowledge/final_eldritch/dance_final/final = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/dance_final)
	final?.show_bolero_scene(bolero_stage)
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
	var/channel = dance_channel()
	for(var/mob/listener as anything in GLOB.player_list)
		if(listener == dance_body || (listener in dancers) || listener.z != center.z || !listener.client)
			continue
		listener.playsound_local(get_turf(listener), sound_file, heretic_dance_music_volume(listener, volume), FALSE, channel = channel)

/// Рампа по краю зоны Финала: лампы светят внутрь, туда, куда ударит музыка.
/datum/eldritch_knowledge/base_dance/proc/mark_finale_zone(faint)
	var/turf/center = get_turf(dance_body)
	if(!center)
		return
	for(var/turf/open/edge in RANGE_TURFS(DANCE_BOLERO_PULSE_RANGE, center))
		var/dx = edge.x - center.x
		var/dy = edge.y - center.y
		if(max(abs(dx), abs(dy)) != DANCE_BOLERO_PULSE_RANGE || isgroundlessturf(edge))
			continue
		if(dy == DANCE_BOLERO_PULSE_RANGE)
			new /obj/effect/temp_visual/heretic_dance_finale_edge(edge, NORTH, faint)
		if(dy == -DANCE_BOLERO_PULSE_RANGE)
			new /obj/effect/temp_visual/heretic_dance_finale_edge(edge, SOUTH, faint)
		if(dx == DANCE_BOLERO_PULSE_RANGE)
			new /obj/effect/temp_visual/heretic_dance_finale_edge(edge, EAST, faint)
		if(dx == -DANCE_BOLERO_PULSE_RANGE)
			new /obj/effect/temp_visual/heretic_dance_finale_edge(edge, WEST, faint)

/// По призрачной паре на каждую вступившую ступень: они кружат вокруг вознёсшегося.
/datum/eldritch_knowledge/base_dance/proc/update_ghosts()
	var/wanted = bolero_on && !QDELETED(dance_body) ? min(bolero_stage, DANCE_GHOST_LIMIT) : 0
	while(length(bolero_ghosts) > wanted)
		var/obj/effect/abstract/heretic_dance_ghost/ghost = bolero_ghosts[length(bolero_ghosts)]
		bolero_ghosts.len--
		dance_body?.vis_contents -= ghost
		qdel(ghost)
	while(length(bolero_ghosts) < wanted)
		var/obj/effect/abstract/heretic_dance_ghost/ghost = new(null, length(bolero_ghosts), DANCE_GHOST_LIMIT)
		bolero_ghosts += ghost
		dance_body.vis_contents += ghost

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
		shake_camera(victim, 2, 1)
	for(var/obj/effect/abstract/heretic_dance_ghost/ghost as anything in bolero_ghosts)
		animate(ghost, transform = matrix() * 1.6, alpha = 230, time = 1.5, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
		animate(transform = matrix(), alpha = initial(ghost.alpha), time = 5, easing = SINE_EASING)
	start_horovod(dance_body, DANCE_BOLERO_HOROVOD_TIME, DANCE_BOLERO_HOROVOD_LIMIT, DANCE_BOLERO_PULSE_RANGE)

/// Последняя доля перед ударом Финала: оркестр набирает воздух, пары стягиваются к вознёсшемуся, рампа вспыхивает.
/datum/eldritch_knowledge/base_dance/proc/finale_inhale()
	mark_finale_zone(TRUE)
	playsound(dance_body, 'modular_bluemoon/sound/heretic/dance/finale_inhale.ogg', 55, FALSE, DANCE_BOLERO_PULSE_RANGE + 4)
	for(var/obj/effect/abstract/heretic_dance_ghost/ghost as anything in bolero_ghosts)
		animate(ghost, transform = matrix() * 0.55, time = beat_ds, easing = SINE_EASING | EASE_IN, flags = ANIMATION_PARALLEL)

/// Фальшивая нота разгоняет призрачные пары, будто оркестр сбился и бал рассыпался.
/datum/eldritch_knowledge/base_dance/proc/scatter_ghosts()
	for(var/obj/effect/abstract/heretic_dance_ghost/ghost as anything in bolero_ghosts)
		var/matrix/stumble = matrix()
		stumble.Turn(pick(-25, 25))
		animate(ghost, transform = stumble, alpha = 0, time = 4, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)

/datum/eldritch_knowledge/base_dance/proc/orchestra_return()
	bolero_broken = FALSE
	var/turf/place = get_turf(dance_body)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_dance/orchestra_return(place)
	playsound(place, 'modular_bluemoon/sound/heretic/dance/orchestra_return.ogg', 70, FALSE, DANCE_BOLERO_PULSE_RANGE + 7)
	for(var/obj/effect/abstract/heretic_dance_ghost/ghost as anything in bolero_ghosts)
		animate(ghost, transform = matrix(), alpha = initial(ghost.alpha), time = 6, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	dance_body.visible_message(span_warning("Оркестр собирается и снова вступает вокруг [dance_body]."), span_eldritch("Оркестр снова с вами: Болеро продолжается."))

/datum/eldritch_knowledge/base_dance/proc/false_note(turf/origin)
	if(!bolero_on || !COOLDOWN_FINISHED(src, false_note_cooldown))
		return FALSE
	COOLDOWN_START(src, false_note_cooldown, DANCE_FALSE_NOTE_COOLDOWN)
	bolero_silent_until = world.time + HERETIC_DANCE_FALSE_NOTE_SILENCE
	set_bolero_stage(bolero_stage - 1)
	bolero_next_at = bolero_silent_until + HERETIC_DANCE_BOLERO_STAGE_TIME
	bolero_broken = TRUE
	scatter_ghosts()
	var/turf/place = get_turf(dance_body)
	if(place)
		new /obj/effect/temp_visual/heretic_dance/false_note(place)
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
#undef DANCE_FINALE_WARNING
#undef DANCE_GHOST_LIMIT

/obj/effect/temp_visual/heretic_dance_finale_edge
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_finale_edge"
	duration = 2.1 SECONDS
	randomdir = FALSE
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/heretic_dance_finale_edge/Initialize(mapload, edge_dir, faint)
	dir = edge_dir
	if(faint)
		alpha = 120
	return ..()

/// Призрачная пара в vis_contents вознёсшегося: обходит его по эллипсу, чётные против часовой.
/obj/effect/abstract/heretic_dance_ghost
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_ghost_couple"
	alpha = 170
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
	vis_flags = VIS_INHERIT_PLANE

/obj/effect/abstract/heretic_dance_ghost/Initialize(mapload, index, total)
	. = ..()
	var/steps = 12
	var/direction = ISODD(index) ? -1 : 1
	var/start = index / max(total, 1) * steps
	for(var/step_index in 0 to steps)
		var/angle = direction * (start + step_index) / steps * 360
		var/x = round(sin(angle) * 26)
		var/y = round(cos(angle) * 9) + 4
		if(step_index == 0)
			pixel_x = x
			pixel_y = y
			animate(src, pixel_x = x, pixel_y = y, time = 0, loop = -1)
			continue
		animate(pixel_x = x, pixel_y = y, time = 3.5)
