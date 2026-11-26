/// Значок Сумрака показывает облик буквой и оттенком, заряды Шага, выжженные тени и окно Удара из тени - и после Шага, и до удара.
/datum/unit_test/heretic_dusk_hud_form/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light(user, 1)
	dusk_tick(dusk)
	var/atom/movable/screen/alert/heretic_resource/indicator = user.alerts["heretic_path_resource"]
	TEST_ASSERT_NOTNULL(indicator, "У Сумрака есть значок запаса.")
	TEST_ASSERT(findtext(indicator.maptext, ">Л</span>"), "Лик виден на значке буквой: [indicator.maptext]")
	var/face_tint = indicator.base_color
	TEST_ASSERT(face_tint && indicator.color == face_tint, "Значок Лика подкрашен: [indicator.color].")
	TEST_ASSERT(findtext(indicator.desc, "Облик: Лик") && findtext(indicator.desc, "Сумрак копится"), "Подсказка значка начинается с облика и копления: [indicator.desc]")
	TEST_ASSERT(!findtext(indicator.maptext, "Ш"), "Без Шага зарядов на значке нет.")
	dusk_learn(dusk, /datum/eldritch_knowledge/spell/dusk_step)
	TEST_ASSERT(findtext(indicator.maptext, "Ш[HERETIC_DUSK_STEP_CHARGES]"), "Заряды Шага видны на значке: [indicator.maptext]")
	TEST_ASSERT(findtext(indicator.maptext, "#17111d"), "Без окна удара фон значка обычный.")
	TEST_ASSERT(dusk.toggle_form(user), "Облик сменён: [dusk.dusk_failure]")
	TEST_ASSERT(findtext(indicator.maptext, ">К</span>"), "Крыло видно на значке буквой: [indicator.maptext]")
	TEST_ASSERT(indicator.base_color && indicator.base_color != face_tint, "Оттенок значка меняется с обликом.")
	TEST_ASSERT(findtext(indicator.desc, "Удар из тени готов") && !findtext(indicator.maptext, "#17111d"), "Окно удара после смены облика видно на значке.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/melee/sickly_blade/dusk/blade = allocate(/obj/item/melee/sickly_blade/dusk, get_turf(user))
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	blade.attack(crew, user)
	TEST_ASSERT(!findtext(indicator.desc, "Удар из тени готов") && findtext(indicator.maptext, "#17111d"), "Удар закрывает окно и на значке.")
	crew.apply_status_effect(/datum/status_effect/heretic_dusk_burnt, dusk)
	TEST_ASSERT(findtext(indicator.desc, "Выжженных теней: 1"), "Выжженная тень видна в подсказке: [indicator.desc]")
	crew.remove_status_effect(/datum/status_effect/heretic_dusk_burnt)
	TEST_ASSERT(!findtext(indicator.desc, "Выжженных теней"), "Сошедшая тень уходит из подсказки.")
	dusk_light_all(0)
	crew.adjustBruteLoss(-200)
	TEST_ASSERT(dusk.shadow_step(user, crew), "Шаг в тень: [dusk.dusk_failure]")
	TEST_ASSERT(findtext(indicator.desc, "Удар из тени готов") && findtext(indicator.maptext, "Ш[HERETIC_DUSK_STEP_CHARGES - 1]"), "После Шага значок показывает окно удара и потраченный заряд.")

/// Сумрак в родной стихии облика копится честно раз в 3 секунды, хотя свет проверяется раз в 2.
/datum/unit_test/heretic_dusk_gather_cadence/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	dusk_light(dusk.dusk_body, 1)
	dusk_tick(dusk)
	dusk.combat_resource = 0
	COOLDOWN_RESET(dusk, gather)
	var/start = world.time
	var/period = HERETIC_DUSK_GATHER_TIME * 4
	for(var/elapsed = 0; elapsed < period; elapsed += HERETIC_DUSK_LIGHT_CHECK)
		dusk.gather_tick(start + elapsed)
	TEST_ASSERT_EQUAL(dusk.combat_resource, period / HERETIC_DUSK_GATHER_TIME, "За [period / (1 SECONDS)] секунд в стихии облика копится единица на каждые [HERETIC_DUSK_GATHER_TIME / (1 SECONDS)] секунды.")

/// Своя клетка меняет свет на тень и обратно только за полосой вокруг порога: пятнистый свет не дёргает облик и цвет мира.
/datum/unit_test/heretic_dusk_light_hysteresis/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk()
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light(user, 1)
	dusk_tick(dusk)
	TEST_ASSERT(dusk.lit, "На свету клетка светлая.")
	dusk_light(user, HERETIC_DUSK_LIT_LUM - HERETIC_DUSK_LIT_HYSTERESIS / 2)
	dusk_tick(dusk)
	TEST_ASSERT(dusk.lit, "Чуть ниже порога свет ещё держится.")
	TEST_ASSERT_NOTNULL(locate(/datum/client_colour/heretic_dusk_face) in user.client_colours, "Мир Лика не мигает у порога.")
	dusk_light(user, HERETIC_DUSK_LIT_LUM - HERETIC_DUSK_LIT_HYSTERESIS * 2)
	dusk_tick(dusk)
	TEST_ASSERT(!dusk.lit, "Заметно ниже порога клетка в тени.")
	dusk_light(user, HERETIC_DUSK_LIT_LUM + HERETIC_DUSK_LIT_HYSTERESIS / 2)
	dusk_tick(dusk)
	TEST_ASSERT(!dusk.lit, "Чуть выше порога тень ещё держится.")
	dusk_light(user, HERETIC_DUSK_LIT_LUM + HERETIC_DUSK_LIT_HYSTERESIS * 2)
	dusk_tick(dusk)
	TEST_ASSERT(dusk.lit, "Заметно выше порога клетка снова светлая.")

/// Цвет мира обликов мягкий: красное узнаётся красным, но Лик белит тёплым, а Крыло холодит.
/datum/unit_test/heretic_dusk_world_tint/Run()
	var/datum/client_colour/heretic_dusk_face/face = new
	var/datum/client_colour/heretic_dusk_wing/wing = new
	for(var/datum/client_colour/tint as anything in list(face, wing))
		var/list/red = heretic_dusk_test_tint(tint.colour, list(1, 0, 0))
		TEST_ASSERT(red[1] - max(red[2], red[3]) > 0.4, "[tint.type]: красное остаётся красным: [jointext(red, ", ")].")
		var/list/grey = heretic_dusk_test_tint(tint.colour, list(0.5, 0.5, 0.5))
		TEST_ASSERT(max(grey) - min(grey) < 0.1, "[tint.type]: серое почти серое: [jointext(grey, ", ")].")
	var/list/yellow = heretic_dusk_test_tint(face.colour, list(1, 1, 0))
	TEST_ASSERT(max(yellow) - min(yellow) < 0.8, "Лик всё же выбеливает жёлтое: [jointext(yellow, ", ")].")
	var/list/white = heretic_dusk_test_tint(wing.colour, list(1, 1, 1))
	TEST_ASSERT(white[3] > white[1], "Белое под Крылом холодное: [jointext(white, ", ")].")
	qdel(face)
	qdel(wing)

/// Перевёрнутый нимб кладёт вокруг меченого тень на игровом плане, видную и под лампами; тень уходит вместе с меткой.
/datum/unit_test/heretic_dusk_mark_dim/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_learn(dusk, /datum/eldritch_knowledge/dusk_mark)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HARM
	fist.afterattack(victim, user, TRUE)
	var/datum/status_effect/eldritch/dusk/mark = victim.has_status_effect(/datum/status_effect/eldritch/dusk)
	TEST_ASSERT_NOTNULL(mark, "Хватка вешает перевёрнутый нимб.")
	TEST_ASSERT(heretic_dusk_test_dimmed(victim), "Вокруг меченого тускнеет свет.")
	qdel(mark)
	TEST_ASSERT(!heretic_dusk_test_dimmed(victim), "Без метки свет вокруг прежний.")

/proc/heretic_dusk_test_dimmed(mob/living/victim)
	var/list/overlays = list()
	SEND_SIGNAL(victim, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	for(var/mutable_appearance/look in overlays)
		if(look.blend_mode != BLEND_SUBTRACT && look.plane == FLOAT_PLANE && look.layer == BELOW_MOB_LAYER && look.icon == 'icons/effects/light_overlays/light_96.dmi')
			return TRUE
	return FALSE

/// Луч фонаря в лицо гасит тёмное зрение Крыла и издалека, если человек смотрит на Крыло, а Крыло - на него.
/datum/unit_test/heretic_dusk_torch_from_afar/Run()
	var/datum/eldritch_knowledge/base_dusk/dusk = allocate_dusk(0, 2)
	var/mob/living/carbon/human/user = dusk.dusk_body
	dusk_light_all(0)
	dusk.set_form(HERETIC_DUSK_FORM_WING, TRUE)
	user.setDir(EAST)
	var/mob/living/carbon/human/spotter = dusk_crew_facing(heretic_lead_test_spot(3, 2), NORTH)
	dusk_lit_torch(spotter)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Фонарь, направленный мимо, зрение не гасит.")
	spotter.setDir(WEST)
	user.setDir(NORTH)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Луч в бок Крылу зрение не гасит.")
	user.setDir(EAST)
	dusk_tick(dusk)
	TEST_ASSERT_EQUAL(dusk.night_sight, HERETIC_DUSK_SIGHT_WING, "Фонарь в руке спящего без игрока зрение не гасит.")
	spotter.mock_client = new /datum/client_interface()
	dusk_tick(dusk)
	spotter.mock_client = null
	TEST_ASSERT_NULL(dusk.night_sight, "Луч фонаря в лицо с трёх клеток гасит тёмное зрение Крыла.")
	TEST_ASSERT(abs(dusk.sight_snuffed_until - world.time - HERETIC_DUSK_SIGHT_SNUFF) < 1, "Зрение гаснет на [HERETIC_DUSK_SIGHT_SNUFF / (1 SECONDS)] секунд.")

/// Подсказки Сумрака сходятся с кодом: время Хватки из дефайна, секунды по-русски, Библия капеллана рвёт Хватку.
/datum/unit_test/heretic_dusk_comfort_texts/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_DUSK]
	TEST_ASSERT(findtext(jointext(path.first_steps, " "), "на [HERETIC_DUSK_GRIP_TIME / (1 SECONDS)] секунд"), "Первые шаги называют настоящее время Хватки.")
	TEST_ASSERT(findtext(jointext(path.weakness_points, " "), "Библия капеллана"), "Слабости называют Библию против Хватки.")
	TEST_ASSERT_EQUAL(heretic_dusk_seconds(6 SECONDS), "6 секунд", "Шесть секунд.")
	TEST_ASSERT_EQUAL(heretic_dusk_seconds(4 SECONDS), "4 секунды", "Четыре секунды.")
	TEST_ASSERT_EQUAL(heretic_dusk_seconds(1 SECONDS), "1 секунду", "Одна секунда.")
	TEST_ASSERT_EQUAL(heretic_dusk_seconds(0.8 SECONDS), "0,8 секунды", "Дробные секунды.")
	var/datum/eldritch_knowledge/spell/dusk_grip/grip = new
	TEST_ASSERT(findtext(jointext(grip.details, " "), "Библия капеллана"), "Знание Хватки называет Библию.")
	qdel(grip)
	var/atom/movable/screen/alert/status_effect/heretic_dusk_gripped/alert_type = /atom/movable/screen/alert/status_effect/heretic_dusk_gripped
	TEST_ASSERT(findtext(initial(alert_type.desc), "Библия капеллана"), "Значок прибитого называет Библию.")
