/// Недовозвращённый видит осколок того Дома, из которого его вытолкнуло.
/datum/unit_test/heretic_fin_mansus_unreturned_theme/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_GLASS)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	visit.finish(exit_reason = "timeout")
	var/atom/movable/screen/alert/status_effect/heretic_mansus_unreturned/alert = victim.alerts["heretic_mansus_unreturned"]
	TEST_ASSERT_NOTNULL(alert, "Таймаут выдаёт алерт недовозвращённой памяти.")
	TEST_ASSERT_EQUAL(alert.icon_state, "glass_memory", "Алерт показывает осколок Стекла, а не Пепла.")
	TEST_ASSERT("glass_memory" in icon_states(alert.icon), "Осколок Стекла есть в листе алерта.")

/// Демоны еретика гибнут видимым распадом своего пути и с русской строкой гибели.
/datum/unit_test/heretic_fin_mansus_demon_remains/Run()
	var/list/demon_states = icon_states('modular_bluemoon/icons/mob/heretic_demons.dmi')
	var/list/seen_states = list()
	var/regex/cyrillic = regex(@"[а-яё]")
	for(var/demon_type in list(/mob/living/simple_animal/hostile/eldritch/raw_prophet, /mob/living/simple_animal/hostile/eldritch/stalker, /mob/living/simple_animal/hostile/eldritch/ash_spirit, /mob/living/simple_animal/hostile/eldritch/rust_spirit))
		var/mob/living/simple_animal/hostile/eldritch/demon = allocate(demon_type, run_loc_floor_bottom_left)
		var/state = demon.remains_state
		TEST_ASSERT(state in demon_states, "Распад [demon_type] нарисован.")
		TEST_ASSERT(!(state in seen_states), "У [demon_type] свой распад.")
		seen_states += state
		TEST_ASSERT(cyrillic.Find(demon.deathmessage), "Гибель [demon_type] описана по-русски.")
		demon.death()
		TEST_ASSERT(QDELETED(demon), "[demon_type] исчезает после гибели.")
		var/obj/effect/temp_visual/heretic_demon_remains/remains = locate() in run_loc_floor_bottom_left
		TEST_ASSERT_NOTNULL(remains, "[demon_type] оставляет распад на месте гибели.")
		TEST_ASSERT_EQUAL(remains.icon_state, state, "Распад [demon_type] играет свой стейт.")
		qdel(remains)

/// Каждое кольцо червя Плоти оставляет распад, а не исчезает вместе с головой.
/datum/unit_test/heretic_fin_mansus_armsy_remains/Run()
	var/mob/living/simple_animal/hostile/eldritch/armsy/head = allocate(/mob/living/simple_animal/hostile/eldritch/armsy, run_loc_floor_bottom_left)
	var/segments = head.get_length()
	TEST_ASSERT("armsy_dead" in icon_states(head.icon), "Распад кольца червя нарисован.")
	head.death()
	TEST_ASSERT(QDELETED(head), "Голова червя исчезает после гибели.")
	var/remains = 0
	for(var/obj/effect/temp_visual/heretic_demon_remains/piece in run_loc_floor_bottom_left)
		TEST_ASSERT_EQUAL(piece.icon_state, "armsy_dead", "Кольцо распадается своим стейтом.")
		remains++
		qdel(piece)
	TEST_ASSERT_EQUAL(remains, segments, "Распадается каждое кольцо червя.")

/// Удары демонов звучат материалом пути, а не общим кулаком.
/datum/unit_test/heretic_fin_mansus_demon_sounds/Run()
	for(var/demon_type in list(/mob/living/simple_animal/hostile/eldritch/raw_prophet, /mob/living/simple_animal/hostile/eldritch/stalker, /mob/living/simple_animal/hostile/eldritch/ash_spirit, /mob/living/simple_animal/hostile/eldritch/rust_spirit, /mob/living/simple_animal/hostile/eldritch/armsy))
		var/mob/living/simple_animal/hostile/eldritch/demon_path = demon_type
		var/sound_key = initial(demon_path.attack_sound)
		TEST_ASSERT(istext(sound_key) && GLOB.sfx_datum_by_key[sound_key], "У [demon_type] набор ударов своего пути.")
	TEST_ASSERT_NOTEQUAL(/mob/living/simple_animal/hostile/eldritch/armsy::attack_sound, /mob/living/simple_animal/hostile/eldritch/stalker::attack_sound, "Укус червя отличается от удара сталкера.")

/// У каждого сигнала живого сердца свой звук: указание, новая цель, цель повержена, цель погибла.
/datum/unit_test/heretic_fin_mansus_heart_signals/Run()
	var/list/seen = list()
	for(var/signal in list("track", "claim", "downed", "dead"))
		var/heart_sound = GLOB.heretic_heart_sounds[signal]
		TEST_ASSERT(isfile(heart_sound), "Сигнал сердца [signal] включён в ресурсы.")
		TEST_ASSERT(!(heart_sound in seen), "Сигнал сердца [signal] не повторяет другой.")
		seen += heart_sound
