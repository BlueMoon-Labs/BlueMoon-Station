/// У каждого пути своя тема и своя кульминация вознесения; кульминация не общий tg Repulse и не реакция неба.
/datum/unit_test/heretic_fin_ascension_path_sounds/Run()
	var/list/themes = list()
	var/list/climaxes = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(isfile(path.ascension_sound), "Путь [path_id] без темы вознесения.")
		TEST_ASSERT(isfile(path.ascension_climax_sound), "Путь [path_id] без кульминации вознесения.")
		var/theme = "[path.ascension_sound]"
		var/climax = "[path.ascension_climax_sound]"
		TEST_ASSERT(!themes[theme], "Тема [theme] звучит у путей [path_id] и [themes[theme]].")
		TEST_ASSERT(!climaxes[climax], "Кульминация [climax] звучит у путей [path_id] и [climaxes[climax]].")
		TEST_ASSERT_NOTEQUAL(climax, theme, "Кульминация пути [path_id] не повторяет его тему.")
		TEST_ASSERT_NOTEQUAL(climax, "sound/magic/Repulse.ogg", "Кульминация пути [path_id] - не tg Repulse.")
		TEST_ASSERT_NOTEQUAL(climax, "[path.sky_event_sound]", "Кульминация пути [path_id] не повторяет реакцию неба.")
		themes[theme] = path_id
		climaxes[climax] = path_id
	TEST_ASSERT_EQUAL(length(climaxes), length(GLOB.heretic_paths), "Кульминаций столько же, сколько путей.")

/// Такты обряда и знамение у свидетелей звучат своими звуками, а не tg-заклинаниями.
/datum/unit_test/heretic_fin_ascension_rite_sounds/Run()
	var/mob/living/carbon/human/performer = allocate(/mob/living/carbon/human)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big)
	var/obj/effect/heretic_ritual_crescendo/crescendo = allocate(/obj/effect/heretic_ritual_crescendo, run_loc_floor_bottom_left, PATH_TIDE, 30 SECONDS, rune, performer)
	TEST_ASSERT(!QDELETED(crescendo), "Обряд создаётся.")
	var/list/heard = list()
	for(var/stage in 2 to length(crescendo.stage_at))
		var/sound_file = crescendo.stage_sound[stage]
		TEST_ASSERT(isfile(sound_file), "Такт [stage] обряда звучит.")
		TEST_ASSERT(findtext("[sound_file]", "modular_bluemoon/") == 1, "Такт [stage] обряда звучит своим звуком, а не [sound_file].")
		TEST_ASSERT(!heard["[sound_file]"], "Такты обряда звучат разными звуками.")
		heard["[sound_file]"] = TRUE
	var/omen_sound = /datum/status_effect/heretic_ascension_omen::omen_sound
	TEST_ASSERT(isfile(omen_sound), "Знамение у свидетелей звучит.")
	TEST_ASSERT(findtext("[omen_sound]", "modular_bluemoon/") == 1, "Знамение звучит своим звуком, а не [omen_sound].")
