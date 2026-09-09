/obj/effect/anomaly/ectoplasm
	desc = "Похоже, души проклятых снова пытаются прорваться в мир живых. Как неприятно."
	icon_state = "ectoplasm"
	aSignal = /obj/item/assembly/signaler/anomaly/ectoplasm
	lifespan = ANOMALY_COUNTDOWN_TIMER + 2 SECONDS //Действует чуть дольше, потому что аномалия может сбежать.
	immobile = TRUE //не даёт аномалии разгуливать, чтобы призраки могли двигать её с достаточной точностью

	///Блокирует пересчёт количества призраков аномалией. Используется, если админ хочет задать аномалии определённый размер или интенсивность.
	var/override_ghosts = FALSE
	///Численная сила аномалии. Рассчитывается в anomalyEffect. Также используется для определения категории эффектов детонации.
	var/effect_power = 0
	///Текущее количество призраков, кружащихся вокруг аномалии.
	var/ghosts_orbiting = 0

/obj/effect/anomaly/ectoplasm/Initialize(mapload, new_lifespan)
	. = ..()

	AddComponent(/datum/component/deadchat_control/cardinal_movement, _deadchat_mode = ANARCHY_MODE, _inputs = list(), _input_cooldown = 7 SECONDS)

/obj/effect/anomaly/ectoplasm/examine(mob/user)
	. = ..()

	if(isobserver(user))
		. += span_info("Если вы будете кружить вокруг этой аномалии, её эффекты станут больше и мощнее.")

/obj/effect/anomaly/ectoplasm/examine_more(mob/user)
	. = ..()

	switch(effect_power)
		if(0 to 25)
			. += span_notice("Пространство вокруг аномалии слабо резонирует. Похоже, сейчас она не очень сильна.")
		if(26 to 49)
			. += span_notice("Пространство вокруг аномалии вибрирует, издавая звук, похожий на жуткий стон. Кому-то стоило бы что-то с этим сделать.")
		if(50 to 100)
			. += span_alert("Аномалия тяжело пульсирует и вот-вот разорвётся неземной энергией. Вряд ли это сулит что-то хорошее.")

/obj/effect/anomaly/ectoplasm/anomalyEffect(seconds_per_tick)
	. = ..()

	if(override_ghosts)
		return

	ghosts_orbiting = 0
	for(var/mob/dead/observer/orbiter in orbiters?.orbiters)
		ghosts_orbiting++

	if(ghosts_orbiting)
		var/total_dead = length(GLOB.dead_mob_list) + length(GLOB.current_observers_list)
		effect_power = total_dead ? clamp((ghosts_orbiting / total_dead) * 100 * 2, 0, 100) : 0
	else
		effect_power = 0

	intensity_update()

/obj/effect/anomaly/ectoplasm/detonate()
	. = ..()

	if(effect_power < 10) //При участии ниже 10% мы делаем лишь небольшой визуальный *хлопок*.
		new /obj/effect/temp_visual/revenant/cracks(get_turf(src))
		return

	if(effect_power >= 10) //Выполняет нечто вроде заклинания осквернения ревенанта.
		var/effect_range = ghosts_orbiting + 3
		var/effect_area = range(effect_range, src)

		for(var/impacted_thing in effect_area)
			if(isfloorturf(impacted_thing))
				if(prob(5))
					new /obj/effect/decal/cleanable/blood(get_turf(impacted_thing))
				else if(prob(10))
					new /obj/effect/decal/cleanable/greenglow/ecto(get_turf(impacted_thing))
				else if(prob(10))
					new /obj/effect/decal/cleanable/dirt/dust(get_turf(impacted_thing))

				if(!isplatingturf(impacted_thing))
					var/turf/open/floor/floor_to_break = impacted_thing
					if((floor_to_break.turf_flags & TURF_OVERFLOOR_PLACED) && floor_to_break.floor_tile && prob(20))
						new floor_to_break.floor_tile(floor_to_break)
						floor_to_break.make_plating(TRUE)
						floor_to_break.broken = TRUE
						floor_to_break.burnt = TRUE

			if(ishuman(impacted_thing))
				var/mob/living/carbon/human/mob_to_infect = impacted_thing
				mob_to_infect.ForceContractDisease(new /datum/disease/revblight(), FALSE, TRUE)
				new /obj/effect/temp_visual/revenant(get_turf(mob_to_infect))
				to_chat(mob_to_infect, span_revenminor("Какофония призрачных стонов на мгновение затопляет ваши уши. Шум стихает, но далёкий шёпот продолжает звучать эхом глубоко в вашей голове..."))

			if(istype(impacted_thing, /obj/structure/window))
				var/obj/structure/window/window_to_damage = impacted_thing
				window_to_damage.take_damage(rand(60, 90))
				if(window_to_damage?.fulltile)
					new /obj/effect/temp_visual/revenant/cracks(get_turf(window_to_damage))

	if(effect_power >= 35)
		var/effect_range = ghosts_orbiting + 3
		haunt_outburst(epicenter = get_turf(src), range = effect_range, haunt_chance = 45, duration = 2 MINUTES)

	if(effect_power >= 50) //Вызывает рой призраков!
		var/list/candidate_list = list()
		for(var/mob/dead/observer/orbiter in orbiters?.orbiters)
			candidate_list += orbiter

		new /obj/structure/ghost_portal(get_turf(src), candidate_list)

		priority_announce("Призрачная аномалия достигла своей критической массы. Обнаружен эктоплазматический выброс.", "ВНИМАНИЕ: АНОМАЛИЯ")

/**
 * Управляет обновлением спрайта аномалии в зависимости от количества кружащихся вокруг неё призраков.
 *
 *
 * Проверка, определяющая, какой спрайт аномалия должна отображать в данный момент.
 * При участии 50% и более используется «тяжёлый» спрайт. В противном случае возвращается обычный спрайт аномалии.
 */

/obj/effect/anomaly/ectoplasm/proc/intensity_update()
	if(effect_power >= 50) //Если мы достигли порога эффекта высшего уровня, меняем спрайт в предвкушении жути.
		icon_state = "ectoplasm_heavy"
		update_icon_state()
	else
		icon_state = "ectoplasm"
		update_icon_state()



// Призрачный портал. Используется, чтобы доставить призраков-орбитеров аномалии на поле боя. Самоуничтожается вместе со всеми порождёнными призраками через две минуты.
// Может быть уничтожен раньше с тем же эффектом.

/obj/structure/ghost_portal
	name = "Жуткий портал"
	desc = "Портал между нашим измерением и неизвестно чем. Из него доносится совершенно нечеловеческий вой."
	icon = 'icons/obj/objects.dmi'
	icon_state = "anom"
	anchored = TRUE
	var/static/list/spooky_noises = list(
		'sound/hallucinations/growl1.ogg',
		'sound/hallucinations/growl2.ogg',
		'sound/hallucinations/growl3.ogg',
		'sound/hallucinations/veryfar_noise.ogg',
		'sound/hallucinations/wail.ogg'
	)
	var/list/ghosts_spawned = list()

/obj/structure/ghost_portal/Initialize(mapload, candidate_list)
	. = ..()

	START_PROCESSING(SSobj, src)
	INVOKE_ASYNC(src, PROC_REF(make_ghost_swarm), candidate_list)
	playsound(src, pick(spooky_noises), 100, TRUE)
	QDEL_IN(src, 2 MINUTES)

/obj/structure/ghost_portal/process(seconds_per_tick)
	. = ..()

	if(prob(5))
		playsound(src, pick(spooky_noises), 100)

/obj/structure/ghost_portal/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	playsound(loc, 'sound/effects/empulse.ogg', 75, TRUE)
	if(prob(40))
		playsound(src, pick(spooky_noises), 50)

/obj/structure/ghost_portal/Destroy()
	. = ..()

	STOP_PROCESSING(SSobj, src)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(cleanup_ghosts), ghosts_spawned)
	ghosts_spawned = null

/**
 * Устраивает опрос для наблюдателей, призывая согласившихся в качестве большой группы призрачных мобов
 *
 * Устраивает опрос с просьбой об участии для всех наблюдателей. Призывает группу призрачных мобов basicmob с клавиатурами согласившихся кандидатов.
 * Призраки удаляются через две минуты после появления и существуют, чтобы крушить всё, пока оно не сломается.
 */

/obj/structure/ghost_portal/proc/make_ghost_swarm(list/candidate_list = list())
	if(!length(candidate_list)) //Если список кандидатов не передан, мы опрашиваем всех мёртвых, значит эти порталы можно также призывать напрямую.
		candidate_list += GLOB.current_observers_list
		candidate_list += GLOB.dead_mob_list

	var/list/candidates = pollCandidates("Хотите присоединиться к жуткому рою призраков? (Предупреждение: вернуться в своё тело вы уже не сможете!)", ROLE_SENTIENCE, null, 0, 10 SECONDS, group = candidate_list)
	for(var/mob/dead/observer/candidate_ghost as anything in candidates)
		var/mob/living/simple_animal/hostile/ghost/swarm/new_ghost = new(get_turf(src))
		ghosts_spawned += new_ghost
		new_ghost.ghostize(FALSE)
		new_ghost.key = candidate_ghost.key
		var/policy = get_policy(ROLE_ANOMALY_GHOST)
		if(policy)
			to_chat(new_ghost, policy)
		else
			to_chat(new_ghost, span_revenboldnotice("Вы — заблудшая душа, возвращённая в мир живых. Ваше время в этом мире ограничено, и скоро вас утащат обратно в пустоту!"))
		new_ghost.log_message("эктоплазменная аномалия вернула его в мир живых в виде призрака.", LOG_GAME)

/**
 * Благодарит и удаляет призраков, порождённых структурой призрачного портала.
 *
 * Обрабатывает зачистку всех призрачных мобов, призванных призрачным порталом. Проходится по списку,
 * вызывает qdel для его содержимого, выводит короткое сообщение и оставляет после себя немного слизи.
 * Хранится как глобальная процедура, поскольку вызывается сразу после самоуничтожения портала.
 *
 * * delete_list - Список сущностей, которые должны быть удалены этой процедурой.
 */

/proc/cleanup_ghosts(list/delete_list)
	for(var/mob/living/mob_to_delete as anything in delete_list)
		mob_to_delete.visible_message(span_alert("[mob_to_delete] завывает, когда его утягивает обратно в пустоту!"), span_alert("Вы издаёте последний вой, когда вас засасывает обратно в царство мёртвых. И тут же — вы снова в уютных объятиях загробного мира."), span_hear("Вы слышите призрачный вой."))
		playsound(mob_to_delete, pick(delete_list), 50)
		new /obj/effect/temp_visual/revenant/cracks(get_turf(mob_to_delete))
		new /obj/effect/decal/cleanable/greenglow/ecto(get_turf(mob_to_delete))
		mob_to_delete.ghostize(FALSE) //Чтобы не выводить предупреждение об удалении моба с клавиатурой внутри.
		qdel(mob_to_delete)
