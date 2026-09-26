/particles/heretic_ascension/test_short
	lifespan = 0.5 SECONDS
	fade = 0.2 SECONDS

/// Волна, выброс частиц, вспышка, контур и лучи убирают за собой всё, что создали.
/datum/unit_test/heretic_vfx_toolkit_cleanup/Run()
	var/turf/center = run_loc_floor_bottom_left
	var/list/lights_before = list()
	for(var/obj/effect/dummy/lighting_obj/light in center)
		lights_before += light
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = heretic_vfx_shockwave(center, "#81e7ee", 3, 0.3 SECONDS)
	TEST_ASSERT_NOTNULL(wave, "Волна создаётся.")
	var/obj/effect/temp_visual/heretic_vfx/warp/warp = locate() in center
	TEST_ASSERT_NOTNULL(warp, "Под волной искажается пространство.")
	TEST_ASSERT_EQUAL(warp.plane, GRAVITY_PULSE_PLANE, "Искажение рисуется на плоскости искажений.")
	TEST_ASSERT(wave.anchored && wave.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Волна не мешает кликам.")
	TEST_ASSERT(length(wave.overlays), "Волна светится в темноте.")
	TEST_ASSERT(length(wave.filters), "По кольцу волны бежит рябь.")
	var/obj/effect/temp_visual/heretic_vfx/burst/burst = heretic_vfx_burst(center, /particles/heretic_ascension/test_short, 0.1 SECONDS)
	TEST_ASSERT_NOTNULL(burst, "Выброс частиц создаётся.")
	TEST_ASSERT(istype(burst.particles, /particles/heretic_ascension/test_short), "Эмиттер несёт частицы нужного пути.")
	TEST_ASSERT(burst.anchored && burst.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Эмиттер не мешает кликам.")
	var/obj/effect/abstract/heretic_vfx_glow/glow = burst.glow
	TEST_ASSERT(glow in burst.vis_contents, "Эмиттер несёт светящуюся копию.")
	TEST_ASSERT_EQUAL(glow.render_source, burst.render_target, "Копия повторяет сам эмиттер.")
	TEST_ASSERT_EQUAL(glow.plane, EMISSIVE_PLANE, "Копия лежит на плоскости свечения.")
	TEST_ASSERT(glow.appearance_flags & RESET_ALPHA, "Прозрачность носителя копия уже несёт сама и не получает её второй раз.")
	TEST_ASSERT_NULL(heretic_vfx_burst(center, null, 1 SECONDS), "Без частиц пути выброса нет.")
	var/obj/item/pen/target = allocate(/obj/item/pen, center)
	TEST_ASSERT(heretic_vfx_pulse(target, "#ffffff", 2, 0.2 SECONDS), "Контур вспыхивает на живом атоме.")
	TEST_ASSERT_NOTNULL(target.get_filter(HERETIC_VFX_PULSE_FILTER), "Контур держится фильтром.")
	TEST_ASSERT(heretic_vfx_rays(target, "#ffffff", 0.3 SECONDS), "Лучи раскрываются на живом атоме.")
	TEST_ASSERT_NOTNULL(target.get_filter(HERETIC_VFX_RAYS_FILTER), "Лучи держатся фильтром.")
	heretic_vfx_flash(center, "#ffffff", 3, 1, 0.2 SECONDS)
	var/list/lights = list()
	for(var/obj/effect/dummy/lighting_obj/light in center)
		if(!(light in lights_before))
			lights += light
	TEST_ASSERT_EQUAL(length(lights), 2, "Вспышка - яркий пик и мягкий хвост.")
	TEST_ASSERT_EQUAL(heretic_vfx_quake(center, 3, 0.1), 0, "Без клиентов рядом трясти некого.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Волна исчезает после своего такта.")
	TEST_ASSERT(wait_for_qdeleted(warp), "Искажение исчезает вместе с волной.")
	TEST_ASSERT(wait_for_qdeleted(burst), "Эмиттер удаляется, когда долетает последняя частица.")
	TEST_ASSERT(QDELETED(glow), "Светящаяся копия уходит вместе с эмиттером.")
	for(var/obj/effect/dummy/lighting_obj/light as anything in lights)
		TEST_ASSERT(wait_for_qdeleted(light), "Свет вспышки гаснет.")
	TEST_ASSERT_NULL(target.get_filter(HERETIC_VFX_PULSE_FILTER), "Контур снимается после вспышки.")
	TEST_ASSERT_NULL(target.get_filter(HERETIC_VFX_RAYS_FILTER), "Лучи снимаются после вспышки.")

/// Эмиттер перестаёт порождать частицы по окончании выброса, а не живёт до конца полёта с полным потоком.
/datum/unit_test/heretic_vfx_burst_stops_emitting/Run()
	var/obj/effect/temp_visual/heretic_vfx/burst/burst = heretic_vfx_burst(run_loc_floor_bottom_left, /particles/heretic_ascension/test_short, 0.1 SECONDS)
	TEST_ASSERT(burst.particles.spawning > 0, "Выброс начинается с потока частиц.")
	var/list/budget = new_wait_budget(1 SECONDS, "остановка выброса")
	while(!QDELETED(burst) && burst.particles.spawning > 0)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(QDELETED(burst) || !burst.particles.spawning, "Через время выброса новые частицы не появляются.")
	qdel(burst)

/// У каждого пути свои частицы вознесения в пределах бюджета, и все их стейты нарисованы.
/datum/unit_test/heretic_vfx_path_particles/Run()
	var/list/seen = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(ispath(path.vfx_particles, /particles/heretic_ascension), "[path_id]: у пути есть частицы вознесения.")
		TEST_ASSERT(!(path.vfx_particles in seen), "[path_id]: частицы пути не повторяют чужие.")
		seen += path.vfx_particles
		var/particles/effect = new path.vfx_particles
		TEST_ASSERT(effect.count <= HERETIC_VFX_MAX_PARTICLES, "[path_id]: в одном эмиттере не больше [HERETIC_VFX_MAX_PARTICLES] частиц.")
		TEST_ASSERT(effect.spawning <= HERETIC_VFX_MAX_SPAWNING, "[path_id]: не больше [HERETIC_VFX_MAX_SPAWNING] частиц за тик.")
		var/list/states = icon_states(effect.icon)
		var/list/wanted = islist(effect.icon_state) ? effect.icon_state : list(effect.icon_state)
		for(var/state in wanted)
			TEST_ASSERT(state in states, "[path_id]: стейт [state] нарисован.")

/// Вознесение сопровождает кульминация: волна, искажение, частицы пути, вспышка и лучи, и всё гаснет само.
/datum/unit_test/heretic_ascension_climax/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	final_knowledge.ritual_time = 0
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.last_mind = allocate_mind()
		body.stat = DEAD
	TEST_ASSERT(rune.do_ritual(user, final_knowledge), "Обряд завершается вознесением.")
	var/turf/center = get_turf(user)
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_BLADE]
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in center
	var/obj/effect/temp_visual/heretic_vfx/warp/warp = locate() in center
	var/obj/effect/temp_visual/heretic_vfx/burst/burst = locate() in center
	TEST_ASSERT_NOTNULL(wave, "Вознесение расходится волной.")
	TEST_ASSERT_NOTNULL(warp, "Волна гнёт пространство.")
	TEST_ASSERT_NOTNULL(burst, "Вознесение взрывается частицами.")
	TEST_ASSERT(istype(burst.particles, path.vfx_particles), "Частицы принадлежат пути вознесённого.")
	TEST_ASSERT(locate(/obj/effect/dummy/lighting_obj) in center, "Вспышка освещает место вознесения.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_RAYS_FILTER), "За спиной вознесённого раскрываются лучи.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Волна гаснет сама.")
	TEST_ASSERT(wait_for_qdeleted(warp), "Искажение уходит вместе с волной.")
	TEST_ASSERT(wait_for_qdeleted(burst), "Эмиттер кульминации удаляется после полёта частиц.")
	var/list/budget = new_wait_budget(2 SECONDS, "снятие лучей")
	while(user.get_filter(HERETIC_VFX_RAYS_FILTER))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_NULL(user.get_filter(HERETIC_VFX_RAYS_FILTER), "Лучи гаснут и снимаются.")

/// Смерть рассыпает нимб частицами пути.
/datum/unit_test/heretic_ascension_aura_disperses/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/body = heretic.owner.current
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_MOON]
	var/datum/eldritch_knowledge/final_eldritch/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch)
	knowledge.route = PATH_MOON
	knowledge.finished = TRUE
	knowledge.on_body_gain(body)
	var/turf/last_turf = get_turf(body)
	var/list/before = list()
	for(var/obj/effect/temp_visual/heretic_vfx/burst/old_burst in last_turf)
		before += old_burst
	knowledge.on_body_lose(body)
	var/obj/effect/temp_visual/heretic_vfx/burst/dispersal
	for(var/obj/effect/temp_visual/heretic_vfx/burst/new_burst in last_turf)
		if(!(new_burst in before))
			dispersal = new_burst
	TEST_ASSERT_NOTNULL(dispersal, "Потерянный нимб рассыпается частицами.")
	TEST_ASSERT(istype(dispersal.particles, path.vfx_particles), "Нимб рассыпается частицами своего пути.")
	TEST_ASSERT(wait_for_qdeleted(dispersal, 3 SECONDS), "Частицы рассеиваются и эмиттер удаляется.")

/// Нарастание обряда проходит все такты, растёт к концу и рассеивается, не оставляя своих объектов.
/datum/unit_test/heretic_ascension_crescendo_stages/Run()
	var/turf/center = run_loc_floor_bottom_left
	var/mob/living/carbon/human/performer = allocate(/mob/living/carbon/human, center)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, center)
	var/obj/effect/heretic_ritual_crescendo/crescendo = new(center, PATH_TIDE, 0.6 SECONDS, rune, performer)
	TEST_ASSERT_EQUAL(crescendo.stage, 1, "Обряд начинается с первого такта.")
	TEST_ASSERT(length(crescendo.emitters), "Частицы пути стягиваются к руне.")
	var/obj/effect/abstract/heretic_vfx_emitter/emitter = crescendo.emitters[1]
	TEST_ASSERT(emitter in crescendo.vis_contents, "Эмиттеры несёт само нарастание.")
	var/first_rate = emitter.particles.spawning
	var/first_light = crescendo.light_range
	TEST_ASSERT(first_rate > 0, "Частицы тянутся к руне с первого такта.")
	TEST_ASSERT(first_light > 0, "Руна светится с первого такта.")
	TEST_ASSERT(crescendo.glow in crescendo.vis_contents, "Частицы нарастания видны в темноте.")
	TEST_ASSERT_EQUAL(crescendo.pulse?.loc, center, "Пульс руны лежит на полу, а не внутри светящейся копии.")
	TEST_ASSERT(!(crescendo.pulse in crescendo.vis_contents), "Светящаяся копия нарастания не захватывает руну.")
	TEST_ASSERT(length(crescendo.pulse.overlays), "Руна светится собственной маской на слое печатей.")
	TEST_ASSERT_EQUAL(crescendo.warp?.loc, center, "Над руной бьётся искажение.")
	var/list/budget = new_wait_budget(1 SECONDS, "последний такт обряда")
	while(crescendo.stage < length(crescendo.stage_at))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_EQUAL(crescendo.stage, length(crescendo.stage_at), "Обряд доходит до последнего такта.")
	TEST_ASSERT(emitter.particles.spawning > first_rate, "К концу обряда частиц тянется больше.")
	TEST_ASSERT(crescendo.light_range > first_light, "Свет руны растёт к концу обряда.")
	var/list/children = list(crescendo.pulse, crescendo.glow, crescendo.warp) + crescendo.emitters
	var/peak_power = crescendo.light_power
	crescendo.dissipate()
	TEST_ASSERT_EQUAL(emitter.particles.spawning, 0, "Рассеивание сразу останавливает поток частиц.")
	TEST_ASSERT_EQUAL(length(crescendo.stage_timers), 0, "Рассеивание снимает оставшиеся такты.")
	TEST_ASSERT(crescendo.light_range > 0, "Свет руны не обрывается разом.")
	var/list/dim_budget = new_wait_budget(1 SECONDS, "затухание света руны")
	while(!QDELETED(crescendo) && crescendo.light_power >= peak_power)
		if(!wait_budget_tick(dim_budget))
			break
	TEST_ASSERT(QDELETED(crescendo) || crescendo.light_power < peak_power, "Свет руны гаснет ступенями.")
	TEST_ASSERT(wait_for_qdeleted(crescendo, 3 SECONDS), "Нарастание удаляется после затухания.")
	for(var/datum/child as anything in children)
		TEST_ASSERT(QDELETED(child), "[child.type] уходит вместе с нарастанием.")

/// Сорванный обряд вознесения гасит нарастание и не оставляет его объектов на полу.
/datum/unit_test/heretic_ascension_crescendo_abort/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/big/crescendo_abort_fixture/rune = allocate(/obj/effect/eldritch/big/crescendo_abort_fixture, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	final_knowledge.ritual_time = 2 SECONDS
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	var/list/bodies = list()
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.last_mind = allocate_mind()
		body.stat = DEAD
		bodies += body
	rune.escapee = bodies[1]
	rune.escape_to = run_loc_floor_top_right
	TEST_ASSERT(!rune.do_ritual(user, final_knowledge), "Унесённое тело срывает обряд.")
	TEST_ASSERT(!final_knowledge.finished, "Сорванный обряд не возносит.")
	var/obj/effect/heretic_ritual_crescendo/crescendo = rune.observed_crescendo
	TEST_ASSERT_NOTNULL(crescendo, "Во время обряда на руне было нарастание.")
	TEST_ASSERT_NULL(rune.ascension_crescendo, "Руна не держит сорванное нарастание.")
	TEST_ASSERT(crescendo.dissipating, "Срыв сразу гасит нарастание.")
	TEST_ASSERT(crescendo.light_range > 0, "Свет сорванного обряда затухает, а не обрывается.")
	var/list/children = list(crescendo.pulse, crescendo.glow, crescendo.warp) + crescendo.emitters
	TEST_ASSERT(wait_for_qdeleted(crescendo, 3 SECONDS), "Нарастание удаляется после затухания.")
	for(var/datum/child as anything in children)
		TEST_ASSERT(QDELETED(child), "[child.type] уходит вместе с нарастанием.")
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_ritual_crescendo) in run_loc_floor_bottom_left, "На руне не остаётся нарастания.")
	TEST_ASSERT_NULL(locate(/obj/effect/abstract/heretic_crescendo_warp) in run_loc_floor_bottom_left, "Над руной не остаётся искажения.")

/datum/actionspeed_modifier/heretic_crescendo_test
	variable = TRUE

/// Нарастание, печать обряда и объявление станции рассчитаны на настоящую длину обряда с учётом скорости действий исполнителя.
/datum/unit_test/heretic_ascension_crescendo_actionspeed/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/big/crescendo_abort_fixture/rune = allocate(/obj/effect/eldritch/big/crescendo_abort_fixture, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	final_knowledge.ritual_time = 2 SECONDS
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.last_mind = allocate_mind()
		body.stat = DEAD
	user.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/heretic_crescendo_test, multiplicative_slowdown = -0.5)
	var/expected = final_knowledge.ritual_time * user.cached_multiplicative_actions_slowdown
	TEST_ASSERT(expected < final_knowledge.ritual_time, "Модификатор ускоряет действия исполнителя.")
	var/datum/news/feed_channel/announcements
	for(var/datum/news/feed_channel/channel in GLOB.news_network.network_channels)
		if(channel.channel_name == "Станционные Объявления")
			announcements = channel
	TEST_ASSERT_NOTNULL(announcements, "Объявления станции доходят до новостей.")
	var/seen_messages = length(announcements.messages)
	TEST_ASSERT(rune.do_ritual(user, final_knowledge), "Ускоренный обряд завершается.")
	var/datum/news/feed_message/warning
	for(var/index in seen_messages + 1 to length(announcements.messages))
		var/datum/news/feed_message/message = announcements.messages[index]
		if(findtext(message.body, "До разрыва завесы"))
			warning = message
	TEST_ASSERT_NOTNULL(warning, "Станцию предупреждают о начале обряда.")
	TEST_ASSERT(findtext(warning.body, "До разрыва завесы — [DisplayTimeText(expected)]."), "Станции называют настоящую длину обряда: [warning.body]")
	var/obj/effect/heretic_ritual_crescendo/crescendo = rune.observed_crescendo
	TEST_ASSERT_NOTNULL(crescendo, "Во время обряда на руне было нарастание.")
	TEST_ASSERT_EQUAL(crescendo.ritual_duration, expected, "Такты нарастания рассчитаны на настоящую длину обряда.")
	TEST_ASSERT_EQUAL(rune.observed_visual_lifetime, expected + 1 SECONDS, "Печать обряда живёт столько же, сколько обряд.")
	user.remove_actionspeed_modifier(/datum/actionspeed_modifier/heretic_crescendo_test)

/// Новые эффекты создаются без аргументов и удаляются без ошибок; общий create_and_destroy в сборке закомментирован.
/datum/unit_test/heretic_vfx_types_create_and_destroy/Run()
	var/list/types = typesof(/obj/effect/temp_visual/heretic_vfx) + typesof(/obj/effect/heretic_ritual_crescendo)
	types += list(/obj/effect/abstract/heretic_vfx_glow, /obj/effect/abstract/heretic_rune_pulse, /obj/effect/abstract/heretic_vfx_emitter, /obj/effect/abstract/heretic_vfx_converge_arm, /obj/effect/abstract/heretic_crescendo_warp, /obj/effect/eldritch/big/crescendo_abort_fixture, /atom/movable/screen/fullscreen/scaled/heretic_omen_surge)
	for(var/thing_type in types)
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")

/obj/effect/eldritch/big/crescendo_abort_fixture
	var/obj/effect/heretic_ritual_crescendo/observed_crescendo
	var/observed_visual_lifetime
	var/atom/movable/escapee
	var/turf/escape_to

/obj/effect/eldritch/big/crescendo_abort_fixture/ritual_valid(mob/living/user, datum/eldritch_knowledge/ritual)
	if(ascension_crescendo && !observed_crescendo)
		observed_crescendo = ascension_crescendo
		observed_visual_lifetime = ritual_visual?.duration
	if(escapee && observed_crescendo)
		var/atom/movable/moving = escapee
		escapee = null
		moving.forceMove(escape_to)
	return ..()

/obj/effect/eldritch/big/crescendo_abort_fixture/Destroy()
	escapee = null
	observed_crescendo = null
	return ..()

/// Знамение начинается всплеском чернил пути по краям экрана и убирает его вместе с дымкой.
/datum/unit_test/heretic_ascension_omen_surge/Run()
	var/mob/living/carbon/human/witness = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/status_effect/heretic_ascension_omen/omen = witness.apply_status_effect(/datum/status_effect/heretic_ascension_omen, PATH_TIDE)
	TEST_ASSERT_NOTNULL(omen, "Знамение выдаётся живому свидетелю.")
	var/surge_key = omen.surge_key
	var/atom/movable/screen/fullscreen/surge = witness.fullscreens[surge_key]
	TEST_ASSERT_NOTNULL(surge, "Знамение открывается всплеском по краям экрана.")
	TEST_ASSERT(islist(surge.color), "Всплеск перекрашен в чернила пути.")
	TEST_ASSERT(witness.fullscreens[omen.fullscreen_key], "После всплеска остаётся дымка.")
	omen.duration = world.time - 1
	omen.process()
	TEST_ASSERT(QDELETED(omen), "Знамение само удаляется по истечении срока.")
	TEST_ASSERT_NULL(witness.fullscreens[surge_key], "Истёкшее знамение убирает и всплеск.")

/// Все частицы вознесения, включая частные выбросы путей, в бюджете и с нарисованными стейтами.
/datum/unit_test/heretic_vfx_particle_states/Run()
	for(var/particles_type in subtypesof(/particles/heretic_ascension) - /particles/heretic_ascension/test_short)
		var/particles/effect = new particles_type
		TEST_ASSERT(effect.count <= HERETIC_VFX_MAX_PARTICLES, "[particles_type]: не больше [HERETIC_VFX_MAX_PARTICLES] частиц.")
		TEST_ASSERT(effect.spawning <= HERETIC_VFX_MAX_SPAWNING, "[particles_type]: не больше [HERETIC_VFX_MAX_SPAWNING] частиц за тик.")
		var/list/states = icon_states(effect.icon)
		var/list/wanted = islist(effect.icon_state) ? effect.icon_state : list(effect.icon_state)
		for(var/state in wanted)
			TEST_ASSERT(state in states, "[particles_type]: стейт [state] нарисован.")

/// Нить тянется между клетками и сходится в свой срок, призрак повторяет облик и светится, сходящиеся частицы долетают точно в центр.
/datum/unit_test/heretic_vfx_thread_ghost_converge/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/finish = locate(start.x + 3, start.y + 4, start.z)
	TEST_ASSERT_NULL(heretic_vfx_thread(start, start, "#d8b674"), "Нить в свою же клетку не рисуется.")
	var/obj/effect/temp_visual/heretic_vfx/thread/thread = heretic_vfx_thread(start, finish, "#d8b674", 3 SECONDS)
	TEST_ASSERT_NOTNULL(thread, "Нить создаётся.")
	TEST_ASSERT_EQUAL(thread.length, 5 * world.icon_size, "Нить тянется на всё расстояние между клетками.")
	TEST_ASSERT_EQUAL(round(thread.angle), round(Get_Angle(start, finish)), "Нить смотрит на цель.")
	TEST_ASSERT(thread.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Нить не мешает кликам.")
	TEST_ASSERT(length(thread.overlays), "Нить светится в темноте.")
	thread.grow(0.2 SECONDS)
	TEST_ASSERT(!thread.settled, "Прорастающая нить ещё держится.")
	thread.snap(0.2 SECONDS)
	TEST_ASSERT(thread.settled, "Вспышка завершает нить.")
	TEST_ASSERT(wait_for_qdeleted(thread, 1 SECONDS), "Вспыхнувшая нить гаснет в свой срок, а не в запасной.")
	var/mob/living/carbon/human/model = allocate(/mob/living/carbon/human, start)
	var/list/tint = heretic_vfx_ink_tint("#9be8cf")
	TEST_ASSERT_EQUAL(length(tint), 20, "Тон призрака - полная цветовая матрица.")
	var/obj/effect/temp_visual/heretic_vfx/ghost/ghost = heretic_vfx_ghost(model, finish, tint, 0.3 SECONDS, TRUE)
	TEST_ASSERT_NOTNULL(ghost, "Призрак создаётся.")
	TEST_ASSERT_EQUAL(ghost.loc, finish, "Призрак стоит там, где его просили.")
	TEST_ASSERT_EQUAL(ghost.icon, model.icon, "Призрак повторяет облик.")
	TEST_ASSERT(ghost.mouse_opacity == MOUSE_OPACITY_TRANSPARENT && !ghost.density, "Призрак не мешает кликам и проходу.")
	TEST_ASSERT(ghost.glow in ghost.vis_contents, "Призрак светится в темноте.")
	TEST_ASSERT_NULL(heretic_vfx_ghost(null, finish), "Без образца призрака нет.")
	model.alpha = 128
	var/obj/effect/temp_visual/heretic_vfx/ghost/pale = heretic_vfx_ghost(model, finish, null, 0.3 SECONDS)
	TEST_ASSERT_EQUAL(pale.model_share(200), 100, "Полупрозрачный образец оставляет призрак бледнее.")
	model.alpha = 255
	model.invisibility = INVISIBILITY_MAXIMUM
	TEST_ASSERT_NULL(heretic_vfx_ghost(model, finish), "Невидимый образец не оставляет призрака.")
	model.invisibility = 0
	var/obj/effect/temp_visual/heretic_vfx/converge/converge = heretic_vfx_converge(start, /particles/heretic_ascension/spirit, 64, 0.5 SECONDS, 0.2 SECONDS, 4, 1)
	TEST_ASSERT_NOTNULL(converge, "Сходящиеся частицы создаются.")
	TEST_ASSERT_EQUAL(length(converge.arms), 4, "Частицы идут по четырём рукавам.")
	for(var/obj/effect/abstract/heretic_vfx_converge_arm/arm as anything in converge.arms)
		TEST_ASSERT(arm in converge.vis_contents, "Рукав висит на выбросе.")
		var/particles/flow = arm.particles
		var/list/speed = flow.velocity
		var/list/pull = flow.gravity
		var/travel = flow.lifespan
		TEST_ASSERT(abs(speed[1]) + abs(speed[2]) > 0, "Закрутка даёт частицам боковой разгон.")
		TEST_ASSERT(abs(arm.start_x + speed[1] * travel + pull[1] * travel * travel / 2) < 0.01, "По горизонтали частица долетает в центр.")
		TEST_ASSERT(abs(arm.start_y + speed[2] * travel + pull[2] * travel * travel / 2) < 0.01, "По вертикали частица долетает в центр.")
	var/obj/effect/temp_visual/heretic_vfx/burst/plain = heretic_vfx_burst(start, /particles/heretic_ascension/test_short, 0.1 SECONDS, FALSE)
	TEST_ASSERT_NULL(plain.glow, "Выброс без свечения не заводит светящуюся копию.")
	var/list/arms = converge.arms.Copy()
	TEST_ASSERT(wait_for_qdeleted(ghost), "Призрак гаснет.")
	TEST_ASSERT(wait_for_qdeleted(pale), "Бледный призрак тоже гаснет.")
	TEST_ASSERT(wait_for_qdeleted(converge), "Сходящиеся частицы исчезают, долетев.")
	for(var/obj/effect/abstract/heretic_vfx_converge_arm/arm as anything in arms)
		TEST_ASSERT(QDELETED(arm), "Рукава уходят вместе с выбросом.")
	TEST_ASSERT(wait_for_qdeleted(plain), "Выброс без свечения тоже удаляется.")

/// Длинный поток частиц помещается в холст целиком и не обрезается на полпути, короткий остаётся в обычном холсте.
/datum/unit_test/heretic_vfx_stream_canvas/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/far = locate(start.x + 10, start.y + 3, start.z)
	var/obj/effect/temp_visual/heretic_vfx/burst/stream = heretic_vfx_stream(start, far, /particles/heretic_ascension/test_short, 0.1 SECONDS)
	TEST_ASSERT_NOTNULL(stream, "Поток на десять клеток создаётся.")
	var/particles/flow = stream.particles
	TEST_ASSERT(flow.width >= 2 * 10 * world.icon_size, "Холст покрывает десять клеток пути в обе стороны, ширина [flow.width].")
	TEST_ASSERT(flow.height >= 2 * 3 * world.icon_size, "Холст покрывает путь по вертикали, высота [flow.height].")
	var/particles/plain = new /particles/heretic_ascension/test_short
	var/obj/effect/temp_visual/heretic_vfx/burst/short = heretic_vfx_stream(start, get_step(start, EAST), /particles/heretic_ascension/test_short, 0.1 SECONDS)
	TEST_ASSERT_EQUAL(short.particles.width, plain.width, "Короткому потоку хватает обычного холста.")
	TEST_ASSERT(wait_for_qdeleted(stream) && wait_for_qdeleted(short), "Потоки иссякают.")
