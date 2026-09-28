/datum/unit_test/heretic_ascension_gate
	var/original_shuttle_mode

/datum/unit_test/heretic_ascension_gate/Destroy()
	if(SSshuttle.emergency && original_shuttle_mode)
		SSshuttle.emergency.mode = original_shuttle_mode
	return ..()

/datum/unit_test/heretic_ascension_gate/proc/set_shuttle_mode(mode)
	SSshuttle.emergency.mode = mode

/datum/unit_test/heretic_ascension_gate/proc/make_final_fixture(list/out_bodies)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.ascension_notice_sent = TRUE
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.last_mind = allocate_mind()
		body.stat = DEAD
		out_bodies += body
	return heretic

/// Финальный обряд идёт только на станции и не начинается и не завершается после отлёта эвакуации; учебный еретик свободен от обоих запретов.
/datum/unit_test/heretic_ascension_gate/Run()
	TEST_ASSERT_NOTNULL(SSshuttle.emergency, "Есть эвакуационный шаттл.")
	original_shuttle_mode = SSshuttle.emergency.mode
	set_shuttle_mode(SHUTTLE_IDLE)
	var/list/bodies = list()
	var/datum/antagonist/heretic/heretic = make_final_fixture(bodies)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/blade_final)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/turf/ritual_turf = get_turf(rune)

	var/off_station = final_knowledge.ascension_block_reason(user, ritual_turf)
	TEST_ASSERT(findtext(off_station, "только на станции"), "Вне станции обряд отклонён: [off_station]")
	TEST_ASSERT(findtext(off_station, get_area_name(ritual_turf, TRUE)), "Отказ называет зону руны.")
	TEST_ASSERT(!rune.do_ritual(user, final_knowledge), "Руна вне станции не начинает вознесение.")
	TEST_ASSERT(COOLDOWN_FINISHED(final_knowledge, ascension_warning), "Отказ по месту не объявляет обряд станции.")
	for(var/mob/living/carbon/human/body as anything in bodies)
		TEST_ASSERT_NULL(GLOB.heretic_ritual_reservations[body], "Отказ по месту не резервирует тела.")

	var/datum/heretic_test_station_level/station_level = allocate(/datum/heretic_test_station_level, ritual_turf.z)
	TEST_ASSERT_NULL(final_knowledge.ascension_block_reason(user, ritual_turf), "На станции обряд разрешён.")
	for(var/mode in list(SHUTTLE_CALL, SHUTTLE_DOCKED))
		set_shuttle_mode(mode)
		TEST_ASSERT_NULL(final_knowledge.ascension_block_reason(user, ritual_turf), "Шаттл в режиме [mode] не мешает вознесению.")
	for(var/mode in list(SHUTTLE_ESCAPE, SHUTTLE_ENDGAME))
		set_shuttle_mode(mode)
		TEST_ASSERT(findtext(final_knowledge.ascension_block_reason(user, ritual_turf), "шаттл"), "Шаттл в режиме [mode] закрывает вознесение.")
	TEST_ASSERT(!rune.do_ritual(user, final_knowledge), "После отлёта шаттла обряд не начинается.")
	TEST_ASSERT(COOLDOWN_FINISHED(final_knowledge, ascension_warning), "Отказ после отлёта не объявляет обряд.")

	heretic.simulated = TRUE
	TEST_ASSERT_NULL(final_knowledge.ascension_block_reason(user, ritual_turf), "Учебное вознесение не зависит от шаттла.")
	qdel(station_level)
	TEST_ASSERT_NULL(final_knowledge.ascension_block_reason(user, ritual_turf), "Учебное вознесение идёт и на резервном уровне полигона.")
	heretic.simulated = FALSE
	allocate(/datum/heretic_test_station_level, ritual_turf.z)

	set_shuttle_mode(SHUTTLE_DOCKED)
	final_knowledge.ritual_time = 1 SECONDS
	addtimer(CALLBACK(src, PROC_REF(set_shuttle_mode), SHUTTLE_ESCAPE), 0.3 SECONDS)
	TEST_ASSERT(!rune.do_ritual(user, final_knowledge), "Отлёт шаттла во время обряда срывает вознесение.")
	TEST_ASSERT(findtext(rune.ritual_interrupt_reason, "шаттл"), "Срыв называет отлёт шаттла: [rune.ritual_interrupt_reason]")
	TEST_ASSERT(!heretic.ascended && !final_knowledge.finished, "Сорванный обряд не возносит.")
	for(var/mob/living/carbon/human/body as anything in bodies)
		TEST_ASSERT(!QDELETED(body), "Сорванный обряд сохраняет тела.")

/datum/unit_test/heretic_ritual_displacement
	var/turf/swap_result
	var/obj/effect/eldritch/watched_rune

/datum/unit_test/heretic_ritual_displacement/proc/bump_performer(mob/living/bumper, mob/living/user)
	bumper.MobBump(user)
	swap_result = get_turf(user)

/datum/unit_test/heretic_ritual_displacement/proc/step_performer(mob/living/user, turf/destination)
	user.forceMove(destination)
	SEND_SIGNAL(user, COMSIG_MOB_CLIENT_MOVE, null, get_dir(user, destination), destination, null, 0, 0)

/// Толчок в пределах руны не срывает обряд, обмен местами заблокирован, а уход от руны называет, сдвинули ли исполнителя или он ушёл сам.
/datum/unit_test/heretic_ritual_displacement/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/turf/center = get_step(run_loc_floor_bottom_left, NORTHEAST)
	user.forceMove(center)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, center)
	var/obj/item/pen/ingredient = allocate(/obj/item/pen, center)
	var/datum/eldritch_knowledge/recipe = allocate(/datum/eldritch_knowledge)
	recipe.required_atoms = list(/obj/item/pen)
	recipe.result_atoms = list(/obj/item/pen)
	recipe.ritual_time = 1 SECONDS
	heretic.researched_knowledge[recipe.type] = recipe
	var/turf/near = get_step(center, NORTH)
	var/turf/far = locate(center.x + 3, center.y, center.z)

	var/mob/living/carbon/human/bumper = allocate(/mob/living/carbon/human, get_step(center, EAST))
	bumper.a_intent = INTENT_HELP
	user.a_intent = INTENT_HELP
	addtimer(CALLBACK(src, PROC_REF(bump_performer), bumper, user), 0.3 SECONDS)
	TEST_ASSERT(rune.do_ritual(user, recipe), "Толчок медбота не срывает обряд.")
	TEST_ASSERT_EQUAL(swap_result, center, "С исполнителем нельзя поменяться местами.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOMOBSWAP), "После обряда защита от обмена снята.")
	qdel(bumper)

	ingredient = allocate(/obj/item/pen, center)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/atom/movable, forceMove), near), 0.3 SECONDS)
	TEST_ASSERT(rune.do_ritual(user, recipe), "Сдвиг на соседнюю с руной клетку не срывает обряд.")

	ingredient = allocate(/obj/item/pen, center)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/atom/movable, forceMove), far), 0.3 SECONDS)
	TEST_ASSERT(!rune.do_ritual(user, recipe), "Исполнителя утащили от руны.")
	TEST_ASSERT(findtext(rune.ritual_interrupt_reason, "оттащили"), "Причина - вынужденный сдвиг: [rune.ritual_interrupt_reason]")
	TEST_ASSERT(!QDELETED(ingredient) && !GLOB.heretic_ritual_reservations[ingredient], "Срыв сохраняет компонент.")

	user.forceMove(near)
	addtimer(CALLBACK(src, PROC_REF(step_performer), user, far), 0.3 SECONDS)
	TEST_ASSERT(!rune.do_ritual(user, recipe), "Исполнитель ушёл от руны.")
	TEST_ASSERT(findtext(rune.ritual_interrupt_reason, "отошли"), "Причина - уход по своей воле: [rune.ritual_interrupt_reason]")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOMOBSWAP), "Сорванный обряд тоже снимает защиту от обмена.")

/// Отказ из-за беспомощности называет, что именно случилось.
/datum/unit_test/heretic_ritual_incapacitated_reason/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.Paralyze(5 SECONDS)
	TEST_ASSERT(findtext(heretic_incapacitated_reason(user), "оглушили"), "Паралич назван оглушением.")
	user.SetParalyzed(0)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(findtext(heretic_incapacitated_reason(user), "связали"), "Наручники названы связыванием.")
	user.Unconscious(5 SECONDS)
	TEST_ASSERT(findtext(heretic_incapacitated_reason(user), "сознание"), "Потеря сознания названа первой.")

/// Цель с отрубленной головой и цель вне станции получают понятный отказ, а пришитая голова возвращает душу в тело.
/datum/unit_test/heretic_hunt_target_reasons/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	var/off_station = heretic.hunt_target_unavailable_reason(soul)
	TEST_ASSERT(findtext(off_station, "вне станции"), "Тело вне станции отклонено: [off_station]")
	TEST_ASSERT(findtext(off_station, get_area_name(run_loc_floor_top_right, TRUE)), "Отказ называет, где лежит тело.")
	allocate(/datum/heretic_test_station_level, run_loc_floor_top_right.z)
	TEST_ASSERT_NULL(heretic.hunt_target_unavailable_reason(soul), "На станции цель доступна.")
	var/obj/item/bodypart/head/head = victim.get_bodypart(BODY_ZONE_HEAD)
	head.drop_limb()
	TEST_ASSERT(istype(soul.current, /mob/living/brain), "Душа ушла в мозг отрубленной головы.")
	var/beheaded = heretic.hunt_target_unavailable_reason(soul)
	TEST_ASSERT(findtext(beheaded, "отрубленной голове"), "Отказ объясняет, что душа в голове: [beheaded]")
	head.attach_limb(victim)
	TEST_ASSERT_EQUAL(soul.current, victim, "Пришитая голова возвращает душу в тело.")
	TEST_ASSERT_NULL(heretic.hunt_target_unavailable_reason(soul), "Труп с пришитой головой снова принимается.")

/// Провал подношения после канала передаёт причину руне для сообщения и лога.
/datum/unit_test/heretic_hunt_refusal_reason/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/offering = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	offering.finish_failure_reason = null
	TEST_ASSERT(!offering.on_finished_recipe(user, list(), run_loc_floor_bottom_left), "Без цели подношение не принято.")
	TEST_ASSERT(findtext(offering.finish_failure_reason, "Подношение не принято."), "Причина заполнена: [offering.finish_failure_reason]")
	TEST_ASSERT(findtext(offering.finish_failure_reason, "Цель охоты не назначена"), "Причина называет, чего не хватает.")

/// Пустой опрос призраков закрывает призыв слуги на паузу, и тексты призывов называют её длину.
/datum/unit_test/heretic_servant_poll_cooldown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/cooldown_text = "[HERETIC_SERVANT_POLL_COOLDOWN / (1 SECONDS)] секунд"
	var/datum/eldritch_knowledge/summon/raw_prophet/ghost_poll_probe/summon = allocate(/datum/eldritch_knowledge/summon/raw_prophet/ghost_poll_probe)
	heretic.researched_knowledge[summon.type] = summon
	TEST_ASSERT_NULL(summon.recipe_block_reason(user), "До опроса призыв открыт.")
	TEST_ASSERT(!summon.on_finished_recipe(user, list(), run_loc_floor_top_right), "Без отклика призыв не удаётся.")
	TEST_ASSERT(findtext(summon.finish_failure_reason, "Позвать снова можно через"), "Отказ говорит, когда звать снова: [summon.finish_failure_reason]")
	TEST_ASSERT(findtext(summon.recipe_block_reason(user), "Позвать снова можно через"), "Повторный призыв закрыт на паузу.")
	TEST_ASSERT(!summon.recipe_snowflake_check(list(), run_loc_floor_top_right, list(), user), "Руна не начинает призыв во время паузы.")
	COOLDOWN_RESET(summon, servant_poll_cooldown)
	TEST_ASSERT(summon.recipe_snowflake_check(list(), run_loc_floor_top_right, list(), user), "После паузы призыв снова доступен.")
	heretic.researched_knowledge -= summon.type

	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	path.combat_resource = 2
	var/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe/grasp = allocate(/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, get_step(user, EAST))
	corpse.death()
	TEST_ASSERT(grasp.on_mansus_grasp(corpse, user, TRUE), "Хватка зовёт духов в пустое тело.")
	TEST_ASSERT(grasp.servant_poll_wait_reason(), "Пустой зов гуля включает паузу.")
	grasp.last_poll_duration = null
	TEST_ASSERT(!grasp.on_mansus_grasp(corpse, user, TRUE), "Во время паузы хватка не зовёт духов.")
	TEST_ASSERT_NULL(grasp.last_poll_duration, "Второй опрос не запущен.")

	var/datum/eldritch_knowledge/summon/summon_type = /datum/eldritch_knowledge/summon
	var/datum/eldritch_knowledge/summon/summon_base = allocate(summon_type)
	TEST_ASSERT(findtext(summon_base.ritual_hint, cooldown_text), "Подсказка призыва называет паузу.")
	TEST_ASSERT(findtext(heretic_codex_text(/datum/eldritch_knowledge/flesh_ghoul), cooldown_text), "Безмолвный мертвец называет паузу.")
	TEST_ASSERT(findtext(heretic_codex_text(/datum/eldritch_knowledge/flesh_grasp), cooldown_text), "Хватка Плоти называет паузу.")

/// Сообщение о двойнике на посту объясняет Алиби, а вне станции предупреждает, что пост не засчитается.
/datum/unit_test/heretic_moon_post_placement_text/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/moon = get_heretic_moon(user)
	var/turf/place = get_step(run_loc_floor_bottom_left, EAST)
	TEST_ASSERT(findtext(moon.post_placement_text(place), "не засчитается"), "Вне станции пост не идёт в дело.")
	allocate(/datum/heretic_test_station_level, place.z)
	var/station_text = moon.post_placement_text(place)
	TEST_ASSERT(findtext(station_text, "Алиби") && findtext(station_text, "уходите"), "На станции сообщение объясняет тактику: [station_text]")
	TEST_ASSERT(findtext(jointext(moon.details.Copy(1, 5), " "), "Алиби"), "Смысл двойника виден в первых четырёх строках кодекса.")

/// Кодекс говорит, что подношение и вознесение идут только на станции и что голову цели рубить нельзя.
/datum/unit_test/heretic_station_only_codex/Run()
	var/datum/eldritch_knowledge/spell/basic/offering = allocate(/datum/eldritch_knowledge/spell/basic)
	TEST_ASSERT(findtext(offering.desc, "только на станции"), "Подношение названо станционным.")
	TEST_ASSERT(findtext(offering.ritual_hint, "Не отрубайте цели голову"), "Подсказка предупреждает о голове.")
	var/datum/eldritch_knowledge/final_eldritch/finale = allocate(/datum/eldritch_knowledge/final_eldritch)
	TEST_ASSERT(findtext(finale.ritual_hint, "только на станции"), "Подсказка вознесения называет станцию.")
	TEST_ASSERT(findtext(finale.ritual_hint, "шаттл"), "Подсказка вознесения называет запрет после отлёта шаттла.")
