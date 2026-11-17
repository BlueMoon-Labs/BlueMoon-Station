/datum/preferences/scar_counter
	var/character_saves = 0

/datum/preferences/scar_counter/save_character(bypass_cooldown = FALSE, silent = FALSE, export = FALSE, update_active_preset = TRUE)
	character_saves++
	return TRUE

/// Спавн с целыми постоянными шрамами персонажа не переписывает, а с битыми чистит набор и пишет один раз.
/datum/unit_test/preferences_persistent_scars_save_only_on_change

/datum/unit_test/preferences_persistent_scars_save_only_on_change/Run()
	var/datum/preferences/scar_counter/prefs = new
	prefs.persistent_scars = TRUE
	prefs.scars_index = 1
	var/scar = "[SCAR_CURRENT_VERSION]|[BODY_ZONE_CHEST]|тонкий шрам|грудь|[WOUND_SEVERITY_MODERATE];"
	prefs.scars_list["1"] = scar
	var/mob/living/carbon/human/whole_body = allocate(/mob/living/carbon/human)
	var/saves_before = prefs.character_saves
	var/changed_whole = prefs.apply_persistent_scars(whole_body)
	var/saves_whole = prefs.character_saves - saves_before
	var/whole_scars = LAZYLEN(whole_body.all_scars)

	prefs.scars_list["1"] = "битый шрам;[scar]"
	var/mob/living/carbon/human/torn_body = allocate(/mob/living/carbon/human)
	var/changed_torn = prefs.apply_persistent_scars(torn_body)
	var/saves_torn = prefs.character_saves - saves_before - saves_whole
	var/kept = prefs.scars_list["1"]
	qdel(prefs)

	TEST_ASSERT(!changed_whole, "целый набор шрамов сочтён изменённым")
	TEST_ASSERT_EQUAL(saves_whole, 0, "спавн с целыми шрамами переписал персонажа")
	TEST_ASSERT_EQUAL(whole_scars, 1, "шрам не нанесён на тело")
	TEST_ASSERT(changed_torn, "битый шрам не выкинут из набора")
	TEST_ASSERT_EQUAL(saves_torn, 1, "очищенный набор шрамов не записан один раз")
	TEST_ASSERT_EQUAL(kept, scar, "из набора выкинут целый шрам")
