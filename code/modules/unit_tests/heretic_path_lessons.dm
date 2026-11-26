/datum/unit_test/proc/path_lesson_grasp(mob/living/user, atom/target)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(target, user, TRUE)

/datum/unit_test/proc/path_lesson_blade_hit(mob/living/user, obj/item/melee/sickly_blade/blade, mob/living/target)
	blade.afterattack(target, user, TRUE, null)
	user.a_intent = INTENT_HARM
	blade.attack(target, user)

/datum/unit_test/proc/check_training_path_lesson(path_id, lesson_id, step_count)
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	TEST_ASSERT(!session.start_practice(lesson_id), "Без пути урока [lesson_id] нет.")
	TEST_ASSERT(session.prepare_path(path_id, 1), "Подготовлен путь [path_id].")
	session.arena.next_spawn_at = 0
	TEST_ASSERT(session.start_practice(lesson_id), "Урок [lesson_id] начинается.")
	var/datum/heretic_path_lesson/lesson = session.path_lesson
	TEST_ASSERT(istype(lesson, GLOB.heretic_path_lessons[lesson_id]), "Сеанс держит урок [lesson_id].")
	TEST_ASSERT(session.practice_available(lesson_id), "Упражнение урока доступно в списке сектора.")
	var/list/data = session.ui_data(session.current_body)
	var/list/button = data["path_lesson"]
	TEST_ASSERT_EQUAL(button?["id"], lesson_id, "Панель показывает кнопку урока.")
	var/list/practice = data["practice"]
	TEST_ASSERT_EQUAL(length(practice["steps"]), step_count, "Панель показывает шаги урока.")
	TEST_ASSERT(findtext(session.practice_hint, "Шаг 1 из [step_count]"), "Подсказка упражнения - первый шаг урока.")
	var/list/atom/movable/props = list()
	for(var/datum/weakref/prop_ref as anything in lesson.props)
		props += prop_ref.resolve()
	session.stop_practice()
	TEST_ASSERT(QDELETED(lesson), "Конец упражнения убирает урок.")
	for(var/atom/movable/prop as anything in props)
		TEST_ASSERT(QDELETED(prop), "Конец упражнения убирает [prop].")

/datum/unit_test/antag_training_glass_lesson/Run()
	check_training_path_lesson(PATH_GLASS, "glass", 5)

/datum/unit_test/antag_training_tide_lesson/Run()
	check_training_path_lesson(PATH_TIDE, "tide", 5)

/datum/unit_test/antag_training_wax_lesson/Run()
	check_training_path_lesson(PATH_WAX, "wax", 4)

/datum/unit_test/antag_training_blood_lesson/Run()
	check_training_path_lesson(PATH_BLOOD, "blood", 4)

/// После урока подготовка пути доводит его до девятой ступени: ступени, выданные уроком, не запирают следующие.
/datum/unit_test/proc/check_lesson_path_stage(path_id, lesson_id)
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	TEST_ASSERT(!session.prepare_path(1, 1) && !session.issue_kit(1) && !session.issue_equipment(1, session.current_body), "Нетекстовые id пути, набора и снаряжения отвергаются.")
	TEST_ASSERT(isnull(session.build_structure(1, session.current_body)) && isnull(session.arena.spawn_creature(1, 1)), "Нетекстовые id постройки и цели отвергаются.")
	TEST_ASSERT(session.prepare_path(path_id, 1), "Подготовлен путь [path_id].")
	session.arena.next_spawn_at = 0
	TEST_ASSERT(!session.start_practice(1), "Нетекстовый id упражнения отвергается.")
	TEST_ASSERT(session.start_practice(lesson_id), "Урок [lesson_id] начинается.")
	session.next_supply_at = 0
	TEST_ASSERT(session.prepare_path(path_id, 9), "Путь [path_id] готовится до девятой ступени.")
	var/datum/antagonist/heretic/heretic = IS_HERETIC(session.current_body)
	TEST_ASSERT_EQUAL(heretic?.path_stage, 9, "После урока [lesson_id] путь доходит до девятой ступени.")
	session.stop_practice()

/datum/unit_test/antag_training_glass_lesson_stage/Run()
	check_lesson_path_stage(PATH_GLASS, "glass")

/datum/unit_test/antag_training_tide_lesson_stage/Run()
	check_lesson_path_stage(PATH_TIDE, "tide")

/datum/unit_test/antag_training_wax_lesson_stage/Run()
	check_lesson_path_stage(PATH_WAX, "wax")

/datum/unit_test/antag_training_blood_lesson_stage/Run()
	check_lesson_path_stage(PATH_BLOOD, "blood")

/datum/unit_test/antag_training_sand_lesson_stage/Run()
	check_lesson_path_stage(PATH_SAND, "sand")

/datum/unit_test/antag_training_spirit_lesson_stage/Run()
	check_lesson_path_stage(PATH_SPIRIT, "spirit")

/datum/unit_test/antag_training_dance_lesson_stage/Run()
	check_lesson_path_stage(PATH_DANCE, "dance")

/// Числа боевых советов полигона совпадают с дефайнами механик.
/datum/unit_test/heretic_combat_practice_numbers/Run()
	var/shake = HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)
	var/list/fragments = list(
		PATH_RUST = list("держат до [HERETIC_RUST_ROOTS_DURATION / (1 SECONDS)] секунд"),
		PATH_FLESH = list("ползун в [HERETIC_FLESH_LATCH_REACH] клетках вцепляется в неё и держит до [HERETIC_FLESH_LATCH_DURATION / (1 SECONDS)] секунд", "за [HERETIC_FLESH_SHED_COST] биомассу уводит вас в самого дальнего слугу в [HERETIC_FLESH_SHED_RANGE] клетках"),
		PATH_BLADE = list("замрёт до [HERETIC_BLADE_THROAT_DURATION / (1 SECONDS)] секунд"),
		PATH_COSMIC = list("через [HERETIC_COSMIC_LEASH_TIME / (1 SECONDS)] секунды привязь", "через [HERETIC_COSMIC_ROAD_CHANNEL / (1 SECONDS)] секунды на месте", "в [HERETIC_COSMIC_ORBIT_RANGE] клетках от своей звезды: [HERETIC_COSMIC_ORBIT_DURATION / (1 SECONDS)] секунд"),
		PATH_LOCK = list("мишень в [HERETIC_LOCK_SHACKLES_RANGE] клетках: через полсекунды она [HERETIC_LOCK_SHACKLES_OTHER / (1 SECONDS)] секунды", "проводит [HERETIC_LOCK_SHACKLES_DURATION / (1 SECONDS)] секунд"),
		PATH_BLOOD = list("[HERETIC_BLOOD_TETHER_COST] долга уходят на путы: [HERETIC_BLOOD_TETHER_DURATION / (1 SECONDS)] секунды"),
		PATH_ECHO = list("[HERETIC_ECHO_LULLABY_DROWSE / (1 SECONDS)] секунды она идёт на [HERETIC_ECHO_LULLABY_SLOWDOWN * 100]% медленнее", "Тишину на [HERETIC_ECHO_HUSH_DURATION / (1 SECONDS)] секунды", "вырывает за [HERETIC_ECHO_HUSH_GRAB_COST] резонанса"),
		PATH_WAX = list("[HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд держите куклу", "дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток"),
		PATH_SPIRIT = list("замрёт до [HERETIC_SPIRIT_HOLD_DURATION / (1 SECONDS)] секунд", "Бесплотность на [HERETIC_SPIRIT_INCORPOREAL_DURATION / (1 SECONDS)] секунды"),
	)
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/text = path.combat_practice
		if(findtext(text, "растолкает"))
			TEST_ASSERT(findtext(text, "за [shake] секунды"), "Совет пути [path_id]: растолкать за [shake] секунды.")
		for(var/fragment in fragments[path_id])
			TEST_ASSERT(findtext(text, fragment), "Совет пути [path_id] расходится с дефайном: нет «[fragment]».")
