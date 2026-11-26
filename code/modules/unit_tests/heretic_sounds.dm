/// У клинка каждого пути свой набор ударов из нескольких файлов (подвиды оружия пути делят его набор); наборы путей не делят файлы, tg-удар не звучит.
/datum/unit_test/heretic_blade_hit_sounds/Run()
	var/list/owner_of_file = list()
	var/list/owner_of_key = list()
	var/list/route_of_key = list()
	var/common_key = initial(/obj/item/melee/sickly_blade::hitsound)
	for(var/blade_type in subtypesof(/obj/item/melee/sickly_blade))
		var/obj/item/melee/sickly_blade/blade = blade_type
		if(initial(blade.route) == PATH_SIDE)
			continue
		var/key = initial(blade.hitsound)
		TEST_ASSERT(istext(key), "Удар [blade_type] выбирается из набора, а не одним файлом: [key].")
		TEST_ASSERT_NOTEQUAL(key, common_key, "Удар [blade_type] звучит своим набором, а не общим.")
		if(route_of_key[key] == initial(blade.route))
			continue
		TEST_ASSERT(!owner_of_key[key], "Клинки [blade_type] и [owner_of_key[key]] звучат одним набором [key].")
		owner_of_key[key] = blade_type
		route_of_key[key] = initial(blade.route)
		var/datum/sound_effect/effect = GLOB.sfx_datum_by_key[key]
		TEST_ASSERT_NOTNULL(effect, "Набор [key] клинка [blade_type] зарегистрирован.")
		TEST_ASSERT(length(effect.file_paths) >= 2, "У удара [blade_type] несколько вариантов.")
		for(var/sound_file in effect.file_paths)
			TEST_ASSERT(isfile(sound_file), "Вариант удара [sound_file] - файл.")
			TEST_ASSERT(!owner_of_file["[sound_file]"], "Файл [sound_file] звучит у [blade_type] и [owner_of_file["[sound_file]"]].")
			owner_of_file["[sound_file]"] = blade_type
	TEST_ASSERT(length(owner_of_key) >= 16, "Свой набор есть у клинка каждого пути: [length(owner_of_key)].")
	var/list/forbidden = list("[file('sound/weapons/bladeslice.ogg')]")
	for(var/key in list(common_key, initial(/obj/item/melee/rune_knife::hitsound)))
		TEST_ASSERT_EQUAL(key, common_key, "Клинок без пути и нож для рун звучат общим набором.")
		var/datum/sound_effect/effect = GLOB.sfx_datum_by_key[key]
		TEST_ASSERT_NOTNULL(effect, "Общий набор ударов зарегистрирован.")
		for(var/sound_file in effect.file_paths)
			TEST_ASSERT(isfile(sound_file), "Общий удар [sound_file] - файл.")
			TEST_ASSERT(!("[sound_file]" in forbidden), "Общий удар не tg-разрез.")
			TEST_ASSERT(!owner_of_file["[sound_file]"], "Общий удар [sound_file] не повторяет удар пути [owner_of_file["[sound_file]"]].")

/// Удар клинком в живую цель звучит набором пути, и каждый вариант набора можно услышать.
/datum/unit_test/heretic_blade_hit_sound_plays/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(get_turf(user))
	var/obj/item/melee/sickly_blade/ash/blade = allocate(/obj/item/melee/sickly_blade/ash)
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	blade.melee_attack_chain(user, victim)
	TEST_ASSERT(blade.hitsound in ear.heard, "Удар пепельным клинком звучит набором Пепла.")
	var/datum/sound_effect/effect = GLOB.sfx_datum_by_key[blade.hitsound]
	var/list/picked = list()
	for(var/i in 1 to 60)
		picked["[get_sfx(blade.hitsound)]"] = TRUE
	TEST_ASSERT_EQUAL(length(picked), length(effect.file_paths), "Случайный выбор доходит до каждого варианта удара.")

/// Наборы событий еретика зарегистрированы, у частых событий несколько вариантов; изучение и улучшение в кодексе звучат по-разному.
/datum/unit_test/heretic_event_sound_sets/Run()
	var/list/keys = list(HERETIC_CODEX_LEARN_SFX, HERETIC_CODEX_UPGRADE_SFX, HERETIC_HEART_SUMMON_SFX, HERETIC_HEART_HIDE_SFX, HERETIC_EMERGENCE_HIT_SFX, HERETIC_CRUCIBLE_BUBBLE_SFX, HERETIC_TRAP_GRASP_SFX, HERETIC_SIPHON_SFX, HERETIC_VOID_BLINK_OUT_SFX, HERETIC_VOID_BLINK_IN_SFX, HERETIC_ASH_PRINT_FLARE_SFX)
	var/list/owner_of_file = list()
	for(var/key in keys)
		var/datum/sound_effect/effect = GLOB.sfx_datum_by_key[key]
		TEST_ASSERT_NOTNULL(effect, "Набор [key] зарегистрирован.")
		TEST_ASSERT(length(effect.file_paths) >= 2, "У [key] несколько вариантов.")
		for(var/sound_file in effect.file_paths)
			TEST_ASSERT(isfile(sound_file), "[sound_file] из [key] - файл.")
			TEST_ASSERT(findtext("[sound_file]", "modular_bluemoon/") == 1, "[key] звучит своим звуком, а не [sound_file].")
			TEST_ASSERT(!owner_of_file["[sound_file]"], "[sound_file] звучит и в [key], и в [owner_of_file["[sound_file]"]].")
			owner_of_file["[sound_file]"] = key
	var/obj/effect/proc_holder/spell/self/heretic_summon/heart/heart = /obj/effect/proc_holder/spell/self/heretic_summon/heart
	TEST_ASSERT_EQUAL(initial(heart.summon_sound), HERETIC_HEART_SUMMON_SFX, "Живое сердце появляется своим звуком.")
	TEST_ASSERT_EQUAL(initial(heart.hide_sound), HERETIC_HEART_HIDE_SFX, "Живое сердце прячется своим звуком.")
	for(var/spell_type in list(/obj/effect/proc_holder/spell/targeted/shapeshift/eldritch, /obj/effect/proc_holder/spell/targeted/genetic/mute))
		var/obj/effect/proc_holder/spell/spell = spell_type
		TEST_ASSERT(isfile(initial(spell.sound)), "[spell_type] звучит файлом.")
		TEST_ASSERT(findtext("[initial(spell.sound)]", "modular_bluemoon/") == 1, "[spell_type] звучит своим звуком.")

/mob/living/carbon/human/heretic_codex_reader
	var/list/heard = list()

/mob/living/carbon/human/heretic_codex_reader/playsound_local(turf/turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, sound/S, max_distance, falloff_distance, distance_multiplier, envwet, envdry, virtual_hearer, source_pressure, list/source_echo, list/excluded_listeners)
	heard += "[soundin]"

/// Изучение знания в кодексе звучит набором изучения, улучшение пассивки - набором улучшения.
/datum/unit_test/heretic_codex_research_sound/Run()
	var/mob/living/carbon/human/heretic_codex_reader/reader = allocate(/mob/living/carbon/human/heretic_codex_reader, run_loc_floor_bottom_left)
	var/datum/mind/mind = allocate_mind()
	mind.current = reader
	reader.mind = mind
	var/datum/antagonist/heretic/heretic = allocate(/datum/antagonist/heretic)
	heretic.owner = mind
	heretic.silent = TRUE
	mind.antag_datums = list(heretic)
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(reader.put_in_hands(book), "Кодекс в руке.")
	var/datum/tgui/heretic_book_test/ui = allocate(/datum/tgui/heretic_book_test, reader, book, "ForbiddenLore", "Кодекс Рубцов")
	ui.status = UI_INTERACTIVE
	TEST_ASSERT(book.ui_act("research", list("id" = "[/datum/eldritch_knowledge/base_ash]"), ui), "Путь Пепла изучается из кодекса.")
	TEST_ASSERT(HERETIC_CODEX_LEARN_SFX in reader.heard, "Изучение звучит набором изучения: [json_encode(reader.heard)].")
	TEST_ASSERT(!(HERETIC_CODEX_UPGRADE_SFX in reader.heard), "Изучение не звучит как улучшение.")
	reader.heard.Cut()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ASH]
	var/passive_type
	for(var/knowledge_type in path.knowledge)
		var/datum/eldritch_knowledge/prototype = allocate(knowledge_type)
		if(length(prototype.passive_values))
			passive_type = knowledge_type
			break
	TEST_ASSERT_NOTNULL(passive_type, "У Пепла есть улучшаемая пассивка.")
	heretic.path_stage = 8
	heretic.side_knowledge_points = 2
	heretic.gain_knowledge(passive_type)
	TEST_ASSERT(book.ui_act("upgrade_passive", list("id" = "[passive_type]", "level" = 1), ui), "Пассивка улучшается из кодекса.")
	TEST_ASSERT(HERETIC_CODEX_UPGRADE_SFX in reader.heard, "Улучшение звучит набором улучшения: [json_encode(reader.heard)].")
	TEST_ASSERT(!(HERETIC_CODEX_LEARN_SFX in reader.heard), "Улучшение не звучит как изучение.")
