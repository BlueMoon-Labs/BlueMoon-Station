#define HERETIC_MANSUS_MINIMUM_TIME (30 SECONDS)
#define HERETIC_MANSUS_DURATION (45 SECONDS)
#define HERETIC_MANSUS_ROOM_SIZE 11
#define HERETIC_MANSUS_MEMORIES 3

GLOBAL_LIST_EMPTY(heretic_mansus_visits)

/// Комната принадлежит одному посещению: чужие жертвы никогда не встречаются внутри.
/area/heretic_mansus
	name = "Мансус: Дом памяти"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	area_flags = NOTELEPORT

/turf/open/indestructible/heretic_mansus
	name = "забытая дорога"
	desc = "Под камнями слышны шаги тех, кто ещё не родился."
	icon_state = "necro1"
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS
	baseturfs = /turf/open/indestructible/heretic_mansus
	color = "#707987"

/turf/closed/indestructible/heretic_mansus
	name = "стена Дома"
	desc = "Слишком много дверей. Ни одной ручки."
	icon = 'icons/turf/mining.dmi'
	icon_state = "rock"
	color = "#393549"
	baseturfs = /turf/closed/indestructible/heretic_mansus

/// Владеет таймерами, комнатой и сигналами; снятие роли еретика не бросает жертву внутри.
/datum/heretic_mansus_visit
	var/mob/living/carbon/human/victim
	var/datum/mind/soul
	var/datum/turf_reservation/reservation
	var/area/heretic_mansus/room
	var/turf/return_turf
	var/turf/fallback_turf
	var/turf/entry_turf
	var/obj/effect/heretic_mansus_gate/gate
	var/list/memories = list()
	var/list/scenery = list()
	var/list/timers = list()
	var/memories_found = 0
	var/earliest_exit = 0
	var/music_channel
	var/client/music_listener
	var/visit_duration = HERETIC_MANSUS_DURATION
	var/started = FALSE
	var/finished = FALSE
	var/finish_pending = FALSE

/datum/heretic_mansus_visit/Destroy()
	if(!finish(delete_visit = FALSE) && !finished)
		return QDEL_HINT_LETMELIVE
	return ..()

/// Подготовка может ждать mapping; до её завершения обряд не выдаёт награду.
/datum/heretic_mansus_visit/proc/prepare(mob/living/carbon/human/target, turf/destination, turf/origin)
	if(QDELETED(target) || target.stat == DEAD || QDELETED(target.mind) || !destination || started || reservation)
		return FALSE
	victim = target
	soul = target.mind
	return_turf = destination
	fallback_turf = origin
	var/datum/turf_reservation/new_reservation = SSmapping.RequestBlockReservation(HERETIC_MANSUS_ROOM_SIZE, HERETIC_MANSUS_ROOM_SIZE)
	if(QDELETED(src) || QDELETED(new_reservation) || QDELETED(victim) || QDELETED(soul))
		qdel(new_reservation)
		return FALSE
	reservation = new_reservation
	room = new
	var/left = reservation.bottom_left_coords[1]
	var/bottom = reservation.bottom_left_coords[2]
	var/level = reservation.bottom_left_coords[3]
	for(var/turf/reserved in reservation.reserved_turfs)
		room.contents += reserved
		if(reserved.x == left || reserved.x == left + HERETIC_MANSUS_ROOM_SIZE - 1 || reserved.y == bottom || reserved.y == bottom + HERETIC_MANSUS_ROOM_SIZE - 1)
			reserved.ChangeTurf(/turf/closed/indestructible/heretic_mansus)
		else
			reserved.ChangeTurf(/turf/open/indestructible/heretic_mansus)
	entry_turf = locate(left + 5, bottom + 2, level)
	gate = new(locate(left + 5, bottom + 8, level), src)
	scenery += gate
	var/list/positions = list(list(2, 3), list(8, 5), list(3, 8))
	var/list/words = list("Ваше имя. Никто здесь не вправе его отнять.", "Знакомый голос. Он ждёт вас по ту сторону стены.", "Собственное дыхание. Вы всё ещё живы.")
	for(var/index in 1 to HERETIC_MANSUS_MEMORIES)
		var/list/position = positions[index]
		var/obj/effect/heretic_mansus_memory/memory = new(locate(left + position[1], bottom + position[2], level), src, words[index])
		memories += memory
		scenery += memory
	return TRUE

/// Вызывается после повторной проверки души и компонентов обряда.
/datum/heretic_mansus_visit/proc/start()
	if(started || finished || QDELETED(victim) || victim.stat == DEAD || QDELETED(soul) || victim.mind != soul || !entry_turf || GLOB.heretic_mansus_visits[soul])
		return FALSE
	started = TRUE
	GLOB.heretic_mansus_visits[soul] = src
	heal_victim()
	victim.grab_ghost()
	ADD_TRAIT(victim, TRAIT_NOBREATH, REF(src))
	ADD_TRAIT(victim, TRAIT_NOFIRE, REF(src))
	// Не снимаем и не уничтожаем наручники: воспоминания доступны и при связанных руках.
	if(victim.buckled)
		victim.buckled.unbuckle_mob(victim, force = TRUE)
	victim.stop_pulling()
	victim.forceMove(entry_turf)
	RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(on_victim_moved))
	RegisterSignal(victim, COMSIG_LIVING_DEATH, PROC_REF(on_victim_death))
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(on_victim_deleted))
	RegisterSignals(soul, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING), PROC_REF(on_soul_changed))
	RegisterSignal(reservation, COMSIG_PARENT_QDELETING, PROC_REF(on_reservation_deleted))
	earliest_exit = world.time + HERETIC_MANSUS_MINIMUM_TIME
	timers += addtimer(CALLBACK(src, PROC_REF(open_gate)), HERETIC_MANSUS_MINIMUM_TIME, TIMER_STOPPABLE)
	timers += addtimer(CALLBACK(src, PROC_REF(finish)), visit_duration, TIMER_STOPPABLE)
	timers += addtimer(CALLBACK(src, PROC_REF(whisper), 1), 8 SECONDS, TIMER_STOPPABLE)
	timers += addtimer(CALLBACK(src, PROC_REF(whisper), 2), 19 SECONDS, TIMER_STOPPABLE)
	timers += addtimer(CALLBACK(src, PROC_REF(whisper), 3), 34 SECONDS, TIMER_STOPPABLE)
	music_channel = SSsounds.reserve_sound_channel(src)
	music_listener = victim.client
	if(music_channel && victim.client?.prefs.toggles & SOUND_AMBIENCE)
		SEND_SOUND(victim, sound('modular_bluemoon/sound/heretic/mansus_memory.ogg', channel = music_channel, volume = 45))
	to_chat(victim, span_userdanger("Вы приходите в себя в Доме, которого нет. Стены помнят вас. Найдите три светящихся воспоминания и коснитесь их — или наступите на них. Затем идите к вратам на севере."))
	to_chat(victim, span_notice("Держитесь за собственное имя. Даже если вы не найдёте выход, Дом отпустит вас меньше чем через минуту."))
	return TRUE

/datum/heretic_mansus_visit/proc/contains(atom/thing)
	return reservation && (get_turf(thing) in reservation.reserved_turfs)

/// Админское fully_heal() удаляет все наручники в инвентаре. Восстанавливаем тело без этого побочного эффекта.
/datum/heretic_mansus_visit/proc/heal_victim()
	victim.regenerate_limbs()
	victim.regenerate_organs()
	victim.revive(full_heal = TRUE)

/datum/heretic_mansus_visit/proc/collect_memory(obj/effect/heretic_mansus_memory/memory, mob/user)
	if(finished || !started || user != victim || !contains(user) || !(memory in memories) || memory.recalled || get_dist(user, memory) > 1 || user.stat != CONSCIOUS)
		return FALSE
	memory.recalled = TRUE
	memories_found++
	memory.alpha = 65
	to_chat(victim, span_notice("[memory.recollection] Воспоминания: [memories_found]/[HERETIC_MANSUS_MEMORIES]."))
	memory.balloon_alert(victim, "[memories_found]/[HERETIC_MANSUS_MEMORIES]: вспомнено")
	playsound(memory, 'sound/effects/ghost2.ogg', 30, TRUE)
	if(memories_found == HERETIC_MANSUS_MEMORIES)
		open_gate()
	return TRUE

/datum/heretic_mansus_visit/proc/open_gate()
	if(finished || QDELETED(gate))
		return
	if(world.time < earliest_exit || memories_found < HERETIC_MANSUS_MEMORIES)
		return
	gate.color = "#d9fff2"
	gate.desc = "С другой стороны слышна станция. Коснитесь врат или войдите в них."
	to_chat(victim, span_boldnotice("Северные врата открылись. Вспомните своё имя и возвращайтесь."))
	gate.balloon_alert(victim, "путь домой открыт")
	if(get_turf(victim) == get_turf(gate))
		try_exit(victim)

/datum/heretic_mansus_visit/proc/try_exit(mob/user)
	if(finished || user != victim || !contains(user) || get_dist(user, gate) > 1)
		return FALSE
	if(memories_found < HERETIC_MANSUS_MEMORIES)
		gate.balloon_alert(victim, "вспомните себя: [memories_found]/[HERETIC_MANSUS_MEMORIES]")
		return FALSE
	if(world.time < earliest_exit)
		gate.balloon_alert(victim, "Дом ещё не отпускает")
		return FALSE
	finish()
	return TRUE

/// Видения принадлежат комнате; они не наносят урон и не остаются после возвращения.
/datum/heretic_mansus_visit/proc/whisper(stage)
	if(finished || QDELETED(victim) || !contains(victim))
		return
	var/list/words = list("Кто-то за вашей спиной произносит ваше имя вашим же голосом.", "На мгновение в стене проступает лицо. Оно открывает рот одновременно с вами.", "Дом делает вдох. Врата дрожат; совсем скоро вас вытолкнет наружу.")
	to_chat(victim, span_warning(words[stage]))
	playsound(victim, 'sound/hallucinations/behind_you1.ogg', 30, FALSE)
	var/turf/shadow_turf = get_step(get_turf(victim), turn(victim.dir, 180))
	if(contains(shadow_turf) && !shadow_turf.density)
		var/obj/effect/heretic_mansus_echo/echo = new(shadow_turf)
		echo.appearance = victim.appearance
		echo.name = initial(echo.name)
		echo.color = "#1b1327"
		echo.alpha = 150
		echo.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		scenery += echo
		animate(echo, alpha = 0, time = 4 SECONDS)

/datum/heretic_mansus_visit/proc/on_victim_moved()
	SIGNAL_HANDLER
	if(!finished && !finish_pending && !contains(victim))
		finish_pending = TRUE
		timers += addtimer(CALLBACK(src, PROC_REF(finish), TRUE), 0, TIMER_STOPPABLE)

/datum/heretic_mansus_visit/proc/on_victim_death()
	SIGNAL_HANDLER
	// Этот сигнал предшествует set_stat(DEAD); сперва даём death() закончить работу.
	timers += addtimer(CALLBACK(src, PROC_REF(finish)), 1, TIMER_STOPPABLE)

/datum/heretic_mansus_visit/proc/on_victim_deleted()
	SIGNAL_HANDLER
	finish()

/datum/heretic_mansus_visit/proc/on_soul_changed(datum/source, mob/new_body)
	SIGNAL_HANDLER
	// При удалении разума второй аргумент сигнала — force, а не новое тело.
	if(music_channel && ismob(new_body))
		new_body.stop_sound_channel(music_channel)
	// Возвращаем оставшееся тело; новый носитель разума не перемещается и не лечится.
	finish()

/datum/heretic_mansus_visit/proc/on_reservation_deleted()
	SIGNAL_HANDLER
	finish()

/datum/heretic_mansus_visit/proc/find_return_turf()
	if(return_turf && is_station_level(return_turf.z) && is_safe_turf(return_turf))
		return return_turf
	if(return_turf && is_station_level(return_turf.z))
		for(var/turf/nearby in range(7, return_turf))
			if(is_safe_turf(nearby))
				return nearby
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(length(station_levels))
		var/turf/safe = find_safe_turf(zlevels = station_levels, extended_safety_checks = TRUE, dense_atoms = FALSE)
		if(safe)
			return safe
	if(fallback_turf && is_safe_turf(fallback_turf))
		return fallback_turf
	// При уничтожении станции всё равно покидаем резервную комнату.
	return return_turf || fallback_turf || get_turf(GET_ERROR_ROOM)

/// Единый идемпотентный выход для таймера, врат, смерти, удаления и смены тела.
/datum/heretic_mansus_visit/proc/finish(preserve_location = FALSE, delete_visit = TRUE)
	if(finished)
		return FALSE
	finish_pending = FALSE
	var/turf/destination = (started || reservation) ? find_return_turf() : null
	if((started || reservation) && !destination)
		finish_pending = TRUE
		timers += addtimer(CALLBACK(src, PROC_REF(finish), preserve_location), 5 SECONDS, TIMER_STOPPABLE)
		return FALSE
	finished = TRUE
	for(var/timer in timers)
		deltimer(timer)
	timers.Cut()
	if(victim)
		UnregisterSignal(victim, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		REMOVE_TRAIT(victim, TRAIT_NOBREATH, REF(src))
		REMOVE_TRAIT(victim, TRAIT_NOFIRE, REF(src))
	if(music_channel)
		if(music_listener)
			SEND_SOUND(music_listener, sound(null, channel = music_channel))
		SSsounds.free_sound_channel(music_channel)
		music_channel = null
	music_listener = null
	if(soul)
		UnregisterSignal(soul, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING))
		if(GLOB.heretic_mansus_visits[soul] == src)
			GLOB.heretic_mansus_visits -= soul
	if(reservation)
		UnregisterSignal(reservation, COMSIG_PARENT_QDELETING)
	if(started && !QDELETED(soul))
		record_mansus_memory()
	if(started && !QDELETED(victim))
		if(!preserve_location)
			heal_victim()
			victim.forceMove(destination)
		victim.AddComponent(/datum/component/heretic_mansus_trace)
		to_chat(victim, span_boldnotice("Стены Дома смыкаются за спиной. Вы помните свой путь среди чужих стен. На коже остался бледный след незнакомой двери."))
	// Возвращаем также брошенные вещи, контейнеры и посторонних: Release() уничтожает содержимое.
	QDEL_LIST(scenery)
	if(reservation)
		for(var/turf/reserved in reservation.reserved_turfs)
			for(var/atom/movable/thing in reserved.contents.Copy())
				if(!QDELETED(thing) && !istype(thing, /atom/movable/lighting_object))
					thing.forceMove(destination)
		if(!QDELETED(reservation))
			qdel(reservation)
	reservation = null
	QDEL_NULL(room)
	memories.Cut()
	gate = null
	victim = null
	soul = null
	if(delete_visit)
		qdel(src)
	return TRUE

/// Амнезия относится к похищению; прежние записи и знания персонажа остаются на месте.
/datum/heretic_mansus_visit/proc/record_mansus_memory()
	var/recollection = "Вы помните Дом, три воспоминания и дорогу назад. Само похищение распалось на белые пятна: лицо, голос и имя того, кто отправил вас в Мансус, не вспоминаются. По воспоминаниям о похищении вы не можете опознать этого человека. Всё, что вы знали и видели до похищения, вы помните по-прежнему."
	soul.store_memory(recollection)
	if(soul.current)
		to_chat(soul.current, span_boldnotice(recollection))

/obj/effect/heretic_mansus_memory
	name = "воспоминание о мире наяву"
	desc = "Знакомое чувство, которому здесь не место. Коснитесь его или наступите на него."
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	icon_state = "mansus_memory_idle"
	color = "#f4d7a0"
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	var/datum/heretic_mansus_visit/visit
	var/recollection
	var/recalled = FALSE

/obj/effect/heretic_mansus_memory/Initialize(mapload, datum/heretic_mansus_visit/new_visit, words)
	. = ..()
	visit = new_visit
	recollection = words
	color = color_matrix_multiply(color_matrix_saturation(0), color_hex2color_matrix("#f4d7a0"))

/obj/effect/heretic_mansus_memory/Destroy()
	visit = null
	return ..()

/obj/effect/heretic_mansus_memory/attack_hand(mob/user)
	visit?.collect_memory(src, user)

/obj/effect/heretic_mansus_memory/Crossed(atom/movable/crosser)
	. = ..()
	if(ismob(crosser))
		visit?.collect_memory(src, crosser)

/obj/effect/heretic_mansus_gate
	name = "дверь в мир наяву"
	desc = "Закрытые врата. Три воспоминания помогут вам вернуться к себе."
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	icon_state = "ring_leader_effect"
	color = "#797485"
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	var/datum/heretic_mansus_visit/visit

/obj/effect/heretic_mansus_gate/Initialize(mapload, datum/heretic_mansus_visit/new_visit)
	. = ..()
	visit = new_visit
	transform = matrix() * 1.6

/obj/effect/heretic_mansus_gate/Destroy()
	visit = null
	return ..()

/obj/effect/heretic_mansus_gate/attack_hand(mob/user)
	visit?.try_exit(user)

/obj/effect/heretic_mansus_gate/Crossed(atom/movable/crosser)
	. = ..()
	if(ismob(crosser))
		visit?.try_exit(crosser)

/obj/effect/heretic_mansus_echo
	name = "кто-то почти знакомый"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Косметический след остаётся на этом теле до конца раунда, не меняя органы или память.
/datum/component/heretic_mansus_trace
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/heretic_mansus_trace/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_mansus_trace/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("На коже проступает бледный контур двери. Стоит отвести взгляд — и кажется, что она приоткрылась.")

#undef HERETIC_MANSUS_MINIMUM_TIME
#undef HERETIC_MANSUS_DURATION
#undef HERETIC_MANSUS_ROOM_SIZE
#undef HERETIC_MANSUS_MEMORIES
