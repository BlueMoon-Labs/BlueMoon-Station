/// Сборка манекена превью одним куском занимала 70-98% тика (прод 10645/10646, Timer -> run_preview_update), между этапами она обязана отдавать тик.
/datum/unit_test/preferences_preview_build_yields
	var/mob/living/carbon/human/dummy/doomed

/datum/unit_test/preferences_preview_build_yields/proc/delete_after_tick()
	sleep(world.tick_lag)
	qdel(doomed)

/datum/unit_test/preferences_preview_build_yields/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	prefs.pref_species = new /datum/species/human
	prefs.random_character(MALE)
	prefs.job_preferences = list("Security Officer" = JP_HIGH)

	var/started = world.time
	var/mutable_appearance/shown = prefs.build_preview_appearance()
	var/ticks_spent = round((world.time - started) / world.tick_lag)
	TEST_ASSERT_NOTNULL(shown, "превью не собралось")
	TEST_ASSERT(ticks_spent >= 3, "сборка превью прошла за [ticks_spent] тиков, без уступок между этапами")
	TEST_ASSERT(length(shown.overlays), "у превью нет слоёв")
	var/mob/living/carbon/human/dummy/pooled = GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_PREFERENCES]
	TEST_ASSERT_NOTNULL(pooled, "манекен превью не вернулся в пул")
	TEST_ASSERT(!pooled.in_use, "манекен превью остался занятым")

	doomed = pooled
	INVOKE_ASYNC(src, PROC_REF(delete_after_tick))
	var/mutable_appearance/orphaned = prefs.build_preview_appearance()
	TEST_ASSERT_NULL(orphaned, "превью собралось на удалённом посреди сборки манекене")
	doomed = null

	var/mutable_appearance/rebuilt = prefs.build_preview_appearance()
	TEST_ASSERT_NOTNULL(rebuilt, "после удаления манекена превью не собралось на новом")
	var/mob/living/carbon/human/dummy/replacement = GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_PREFERENCES]
	TEST_ASSERT(replacement && replacement != pooled && !replacement.in_use, "пул не получил свободный новый манекен")
