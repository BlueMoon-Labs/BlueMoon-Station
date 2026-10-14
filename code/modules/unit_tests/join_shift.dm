/// Вход в смену из наблюдателя идёт через проверки респавна: запрет режима его закрывает.
/datum/unit_test/join_shift_respects_respawn_rules
	var/datum/game_mode/saved_mode
	var/saved_respawns_enabled
	var/saved_roundstart_delay
	var/list/saved_chaos_modes

/datum/unit_test/join_shift_respects_respawn_rules/Destroy()
	SSticker.mode = saved_mode
	CONFIG_SET(flag/respawns_enabled, saved_respawns_enabled)
	CONFIG_SET(number/respawn_minimum_delay_roundstart, saved_roundstart_delay)
	var/datum/config_entry/keyed_list/respawn_chaos_gamemodes/chaos_entry = CONFIG_GET_ENTRY(keyed_list/respawn_chaos_gamemodes)
	chaos_entry.config_entry_value = saved_chaos_modes
	return ..()

/datum/unit_test/join_shift_respects_respawn_rules/Run()
	saved_mode = SSticker.mode
	saved_respawns_enabled = CONFIG_GET(flag/respawns_enabled)
	saved_roundstart_delay = CONFIG_GET(number/respawn_minimum_delay_roundstart)
	var/datum/config_entry/keyed_list/respawn_chaos_gamemodes/chaos_entry = CONFIG_GET_ENTRY(keyed_list/respawn_chaos_gamemodes)
	saved_chaos_modes = chaos_entry.config_entry_value

	CONFIG_SET(flag/respawns_enabled, TRUE)
	CONFIG_SET(number/respawn_minimum_delay_roundstart, 0)
	var/datum/game_mode/dynamic/mode = allocate(/datum/game_mode/dynamic)
	SSticker.mode = mode
	chaos_entry.config_entry_value = list()
	var/datum/preferences/prefs = new
	allocated += prefs
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer)
	TEST_ASSERT_NULL(respawn_block_reason(ghost, prefs), "Без запретов респавн открыт")

	var/list/banned_modes = list()
	banned_modes[lowertext(mode.config_tag)] = TRUE
	chaos_entry.config_entry_value = banned_modes
	TEST_ASSERT_NOTNULL(respawn_block_reason(ghost, prefs), "Запрет режима обязан закрывать респавн")
	TEST_ASSERT(!ghost.try_join_shift(), "Вход в смену при запрете режима не должен проходить")
	TEST_ASSERT(!QDELETED(ghost), "Наблюдатель не должен уходить в лобби при запрете режима")

	chaos_entry.config_entry_value = list()
	CONFIG_SET(flag/respawns_enabled, FALSE)
	TEST_ASSERT_NOTNULL(respawn_block_reason(ghost, prefs), "Выключенный респавн закрывает и вход в смену")

/// Настройка приглашений переживает полную запись и чтение префов, отсутствующий ключ читается как "включено".
/datum/unit_test/shift_invites_pref_round_trip
	var/datum/preferences/prefs

/datum/unit_test/shift_invites_pref_round_trip/Destroy()
	if(prefs?.path)
		fdel(prefs.path)
	QDEL_NULL(prefs)
	return ..()

/datum/unit_test/shift_invites_pref_round_trip/Run()
	prefs = new
	prefs.load_path("unit_test_shift_invites")
	if(fexists(prefs.path))
		fdel(prefs.path)
	prefs.shift_invites = FALSE
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	sleep(1)

	var/datum/preferences/reloaded = new
	allocated += reloaded
	reloaded.load_path("unit_test_shift_invites")
	TEST_ASSERT(reloaded.load_preferences(bypass_cooldown = TRUE), "Префы не прочитались")
	TEST_ASSERT(!reloaded.shift_invites, "Выключенные приглашения должны пережить перезаход")

	var/savefile/written = new /savefile(prefs.path)
	written.cd = "/"
	written.dir -= "shift_invites"
	written = null
	sleep(1)
	TEST_ASSERT(reloaded.load_preferences(bypass_cooldown = TRUE), "Префы без ключа не прочитались")
	TEST_ASSERT(reloaded.shift_invites, "Старый сейв без ключа должен получать приглашения")
