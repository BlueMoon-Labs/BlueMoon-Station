/// Каждая голосовая строка HK-47 ведёт на свой файл в звуках дроидов, префиксов среди них нет.
/datum/unit_test/hk47_voice_lines

/datum/unit_test/hk47_voice_lines/Run()
	var/list/expected = list(
		"hk47_activate", "hk47_ready", "hk47_offer", "hk47_accept", "hk47_target_acquired",
		"hk47_combat_mode", "hk47_damage", "hk47_failing", "hk47_stealth", "hk47_full_gain",
		"hk47_rejoining", "hk47_meatbags", "hk47_charging", "hk47_purchased", "hk47_prospective",
		"hk47_unlock_begin", "hk47_unlock_success", "hk47_unlock_failed", "hk47_scan", "hk47_self_diagnostic",
		"hk47_recite_shields", "hk47_accuracy", "hk47_prejudice", "hk47_crude",
	)
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.mind_initialize()
	allocated += droid.mind
	var/datum/antagonist/hk47/antag = droid.mind.add_antag_datum(/datum/antagonist/hk47)
	TEST_ASSERT_NOTNULL(antag, "HK-47 gets the antag datum")
	TEST_ASSERT_EQUAL(length(antag.voice_lines), length(expected), "voice line count")
	for(var/key in expected)
		var/voice = antag.voice_lines[key]
		TEST_ASSERT(isfile(voice), "[key] has a sound")
		TEST_ASSERT_EQUAL("[voice]", "modular_bluemoon/sound/hk_droids/[key].ogg", "[key] plays its own file")

/// Щелчок префикса у всех моделей HK: свой звук на тип фразы, шёпот, жесты и повтор за кулдаун молчат.
/datum/unit_test/hk_prefix_bark

/datum/unit_test/hk_prefix_bark/Run()
	var/statement = 'modular_bluemoon/sound/hk_droids/hk47_prefix_statement.ogg'
	var/query = 'modular_bluemoon/sound/hk_droids/hk47_prefix_query.ogg'
	var/exclamation = 'modular_bluemoon/sound/hk_droids/hk47_prefix_exclamation.ogg'
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk50)
	var/datum/species/ipc/hk/species = droid.dna.species
	TEST_ASSERT_EQUAL(species.hk_prefix_bark_sound("[HK_PREFIX_STATEMENT] цель найдена"), statement, "statement clip")
	TEST_ASSERT_EQUAL(species.hk_prefix_bark_sound("[HK_PREFIX_QUERY] где хозяин?"), query, "query clip")
	TEST_ASSERT_EQUAL(species.hk_prefix_bark_sound("[HK_PREFIX_EXCLAMATION] огонь!"), exclamation, "exclamation clip")
	TEST_ASSERT_EQUAL(species.hk_prefix_bark_sound("[HK_PREFIX_ANALYSIS] цель уязвима"), 'modular_bluemoon/sound/hk_droids/hk47_prefix_analysis.ogg', "analysis clip")
	TEST_ASSERT_EQUAL(species.hk_speech_prefix("[HK_PREFIX_ANALYSIS] цель уязвима"), "[HK_PREFIX_ANALYSIS] цель уязвима", "a typed analysis prefix is kept")
	TEST_ASSERT_NULL(species.hk_prefix_bark_sound("цель найдена"), "no prefix, no clip")

	TEST_ASSERT_EQUAL(species.hk_prefix_bark(droid, "[HK_PREFIX_QUERY] где хозяин?", null, /datum/language/common), query, "first bark plays")
	TEST_ASSERT_NULL(species.hk_prefix_bark(droid, "[HK_PREFIX_EXCLAMATION] огонь!", null, /datum/language/common), "second bark within the cooldown is skipped")
	COOLDOWN_RESET(species, prefix_bark_cooldown)
	TEST_ASSERT_NULL(species.hk_prefix_bark(droid, "[HK_PREFIX_STATEMENT] тихо", MODE_WHISPER, /datum/language/common), "whisper mode is silent")
	TEST_ASSERT_NULL(species.hk_prefix_bark(droid, "[HK_PREFIX_STATEMENT] тихо", MODE_WHISPER_CRIT, /datum/language/common), "last breath is silent")
	TEST_ASSERT_NULL(species.hk_prefix_bark(droid, "[HK_PREFIX_STATEMENT] жест", null, /datum/language/signlanguage), "sign language is silent")

	for(var/model in list(/datum/species/ipc/hk/hk47, /datum/species/ipc/hk/hk50, /datum/species/ipc/hk/hk51))
		droid.set_species(model)
		species = droid.dna.species
		droid.whisper("Тихо", language = /datum/language/common, ignore_spam = TRUE)
		TEST_ASSERT_EQUAL(droid.last_words, "[HK_PREFIX_STATEMENT] Тихо", "[model] whisper gets a prefix")
		TEST_ASSERT(COOLDOWN_FINISHED(species, prefix_bark_cooldown), "[model] whisper doesn't bark")
		droid.say("Где хозяин?", language = /datum/language/common, ignore_spam = TRUE)
		TEST_ASSERT(!COOLDOWN_FINISHED(species, prefix_bark_cooldown), "[model] speech barks")

/mob/living/carbon/human/hk_voice_probe
	var/list/heard_locally = list()

/mob/living/carbon/human/hk_voice_probe/Destroy()
	heard_locally.Cut()
	return ..()

/mob/living/carbon/human/hk_voice_probe/playsound_local(turf/turf_source, soundin, vol as num, vary, frequency, falloff_exponent = SOUND_FALLOFF_EXPONENT, channel = 0, pressure_affected = TRUE, sound/S, max_distance, falloff_distance = SOUND_DEFAULT_FALLOFF_DISTANCE, distance_multiplier = SOUND_DEFAULT_DISTANCE_MULTIPLIER, envwet = -10000, envdry = 0, virtual_hearer, source_pressure, list/source_echo)
	heard_locally += soundin
	return ..()

/datum/antagonist/hk47/voice_probe
	silent = TRUE
	var/played = 0
	var/last_private

/datum/antagonist/hk47/voice_probe/play_voice(mob/living/droid, voice, private)
	. = ..()
	if(.)
		played++
		last_private = private

/// Служебные строки HK-47 слышит только он сам, остальные звучат вслух, а в маскировке вслух звучит только приветствие протокольного дроида; любая строка занимает вокабулятор, и барк префикса её не перебивает.
/datum/unit_test/hk47_voice_privacy

/datum/unit_test/hk47_voice_privacy/Run()
	var/mob/living/carbon/human/hk_voice_probe/droid = allocate(/mob/living/carbon/human/hk_voice_probe)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.mind_initialize()
	allocated += droid.mind
	var/datum/antagonist/hk47/voice_probe/antag = new
	droid.mind.add_antag_datum(antag)
	var/list/private_lines = list("hk47_offer", "hk47_accept", "hk47_stealth", "hk47_charging", "hk47_full_gain", "hk47_scan", "hk47_self_diagnostic", "hk47_recite_shields", "hk47_accuracy")
	for(var/key in antag.voice_lines)
		droid.heard_locally.Cut()
		var/played_before = antag.played
		var/service_line = (key in private_lines)
		TEST_ASSERT(antag.hk_voice(key, forced = TRUE), "[key] plays")
		TEST_ASSERT_EQUAL(antag.played, played_before + 1, "[key] goes through the voice proc")
		TEST_ASSERT_EQUAL(antag.last_private, service_line, "[key] is [service_line ? "a service line for HK-47 only" : "said out loud"]")
		TEST_ASSERT_EQUAL(length(droid.heard_locally), service_line ? 1 : 0, "[key] [service_line ? "reaches HK-47's own ear" : "is not played into HK-47's own ear"]")

	ADD_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)
	for(var/key in list("hk47_combat_mode", "hk47_damage", "hk47_failing", "hk47_meatbags"))
		antag.hk_voice(key, forced = TRUE)
		TEST_ASSERT(antag.last_private, "[key] does not give away a disguised HK-47")
	var/datum/component/hk47_voice_cues/cues = droid.GetComponent(/datum/component/hk47_voice_cues)
	cues.last_combat_time = null
	COOLDOWN_RESET(antag, voice_cooldown)
	antag.last_voice = null
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	droid.set_last_attacker(attacker)
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_combat_mode", "an attack on a disguised HK-47 still switches it to combat mode")
	TEST_ASSERT(antag.last_private, "but only HK-47 hears it")
	antag.hk_voice("hk47_prospective", forced = TRUE)
	TEST_ASSERT(!antag.last_private, "the protocol droid greeting is the disguise itself and stays out loud")
	REMOVE_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)

	var/datum/species/ipc/hk/chassis = droid.dna.species
	TEST_ASSERT(chassis.voice_busy_until > world.time, "a voice line keeps the vocabulator busy")
	COOLDOWN_RESET(chassis, prefix_bark_cooldown)
	TEST_ASSERT_NULL(chassis.hk_prefix_bark(droid, "[HK_PREFIX_STATEMENT] цель", null, /datum/language/common), "no prefix bark over a voice line")
	chassis.voice_busy_until = 0
	TEST_ASSERT_NOTNULL(chassis.hk_prefix_bark(droid, "[HK_PREFIX_STATEMENT] цель", null, /datum/language/common), "the bark returns after the line")

	droid.set_species(/datum/species/ipc/hk/hk51)
	chassis = droid.dna.species
	TEST_ASSERT(hk_voice_line(droid, 'sound/machines/ping.ogg'), "the shared voice proc plays for any HK chassis")
	var/busy = chassis.voice_busy_until - world.time
	var/expected_busy = hk_voice_line_length('sound/machines/ping.ogg')
	TEST_ASSERT(abs(busy - expected_busy) < 0.1, "the vocabulator is busy for the clip length, expected [expected_busy], got [busy]")
	TEST_ASSERT(busy > 0 && busy <= HK_VOICE_LINE_FALLBACK_LENGTH, "a clip keeps the vocabulator busy no longer than the fallback, got [busy]")
	droid.moveToNullspace()
	TEST_ASSERT(!hk_voice_line(droid, 'sound/machines/ping.ogg'), "nothing plays in nullspace")

/// Голос HK-47 в бою: «режим боя» на первом выстреле после затишья, строка о повреждениях ниже половины прочности один раз, «системы отказывают» в крите без строки о повреждениях следом и без повтора при отключении, запуск после ремонта.
/datum/unit_test/hk47_combat_voice

/datum/unit_test/hk47_combat_voice/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.mind_initialize()
	allocated += droid.mind
	var/datum/antagonist/hk47/antag = droid.mind.add_antag_datum(/datum/antagonist/hk47)
	var/datum/component/hk47_voice_cues/cues = droid.GetComponent(/datum/component/hk47_voice_cues)
	TEST_ASSERT_NOTNULL(cues, "HK-47 gets the combat voice")

	COOLDOWN_RESET(antag, voice_cooldown)
	SEND_SIGNAL(droid, COMSIG_LIVING_GUN_PROCESS_FIRE, run_loc_floor_top_right, null, null)
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_combat_mode", "the first shot after a calm switches to combat mode")
	COOLDOWN_RESET(antag, voice_cooldown)
	TEST_ASSERT(!cues.note_combat(), "no repeat in the middle of a fight")
	cues.last_combat_time = world.time - HK47_COMBAT_CALM_TIME
	TEST_ASSERT(cues.note_combat(), "a new fight after the calm")

	COOLDOWN_RESET(antag, voice_cooldown)
	TEST_ASSERT(hurt_until(droid, droid.maxHealth * 0.8), "light damage dealt, health [droid.health]")
	TEST_ASSERT(!cues.check_damage_line(), "light damage is silent")
	TEST_ASSERT(hurt_until(droid, droid.maxHealth * HK47_DAMAGE_LINE_HEALTH - 5), "heavy damage dealt, health [droid.health]")
	TEST_ASSERT(droid.stat == CONSCIOUS, "still standing after heavy damage")
	TEST_ASSERT(cues.check_damage_line(), "below [HK47_DAMAGE_LINE_HEALTH * 100]% the damage line plays")
	COOLDOWN_RESET(antag, voice_cooldown)
	TEST_ASSERT(!cues.check_damage_line(), "the damage line plays once per drop")
	droid.fully_heal()
	cues.check_damage_line()

	COOLDOWN_RESET(antag, voice_cooldown)
	TEST_ASSERT(hurt_until(droid, droid.crit_threshold - 5), "crit damage dealt, health [droid.health]")
	TEST_ASSERT(droid.InCritical(), "the droid is in crit")
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_failing", "crit says the systems are failing")
	COOLDOWN_RESET(antag, voice_cooldown)
	TEST_ASSERT(!cues.check_damage_line(), "in crit the damage line does not follow the failing line")
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_failing", "the failing line stays the last one")
	antag.last_voice = null
	droid.death()
	TEST_ASSERT_NULL(antag.last_voice, "death right after crit does not repeat the line")
	droid.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_activate", "repaired HK-47 boots up out loud")
	antag.last_voice = null
	droid.death()
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_failing", "a sudden shutdown still says the systems are failing")

/datum/unit_test/hk47_combat_voice/proc/hurt_until(mob/living/carbon/human/droid, health_target)
	for(var/attempt in 1 to 60)
		if(droid.health <= health_target)
			return TRUE
		droid.apply_damage(5, BRUTE, null, 0, TRUE, TRUE)
	return droid.health <= health_target
