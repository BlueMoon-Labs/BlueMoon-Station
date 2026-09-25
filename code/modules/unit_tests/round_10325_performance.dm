#define ROUND_SOUND_TEST_VOLUME 50
#define ROUND_SOUND_TEST_ENV_FULL 0
#define ROUND_SOUND_TEST_ENV_MUTED -10000
#define ROUND_SOUND_TEST_VACUUM_PRESSURE 0

/// Каталоги звуков переиспользуются и сохраняют различия вариантов.
/datum/unit_test/interaction_moan_catalogs/Run()
	var/list/male = build_interaction_moan_options(FALSE)
	var/list/female = build_interaction_moan_options(TRUE)
	TEST_ASSERT(male == build_interaction_moan_options(FALSE), "Повторная сборка мужского каталога")
	TEST_ASSERT(female == build_interaction_moan_options(TRUE), "Повторная сборка женского каталога")
	TEST_ASSERT(male != female, "Варианты каталога смешаны")
	var/list/male_keys = list()
	for(var/list/option as anything in male)
		male_keys += option["key"]
	var/list/female_keys = list()
	for(var/list/option as anything in female)
		female_keys += option["key"]
	for(var/sound_file in GLOB.lewd_moans_male)
		TEST_ASSERT("[sound_file]" in male_keys, "В мужском каталоге отсутствует звук")
	for(var/sound_file in GLOB.lewd_softmoans_female)
		TEST_ASSERT("[sound_file]" in female_keys, "В женском каталоге отсутствует тихий звук")
	for(var/sound_name in GLOB.lewd_other_animal_sounds)
		var/sound_file = GLOB.lewd_other_animal_sounds[sound_name]
		TEST_ASSERT(("[sound_file]" in male_keys) && ("[sound_file]" in female_keys), "Общий звук потерян")

/mob/living/round_sound_listener
	var/captured_pressure
	var/list/captured_echo
	var/captured_envwet
	var/captured_envdry
	var/turf/captured_virtual_hearer

/mob/living/round_sound_listener/playsound_local(turf/turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, sound/S, max_distance, falloff_distance, distance_multiplier, envwet, envdry, virtual_hearer, source_pressure, list/source_echo)
	captured_pressure = source_pressure
	captured_echo = source_echo
	captured_envwet = envwet
	captured_envdry = envdry
	captured_virtual_hearer = virtual_hearer

/// Рассылка передаёт слушателям одно давление источника и общий список эха.
/datum/unit_test/sound_broadcast_context
	var/list/listeners = list()

/datum/unit_test/sound_broadcast_context/Run()
	var/turf/source = run_loc_floor_bottom_left
	for(var/index in 1 to 3)
		var/mob/living/round_sound_listener/listener = allocate(/mob/living/round_sound_listener, source)
		listener.enable_client_mobs_in_contents()
		listeners += listener
	playsound(source, 'sound/machines/ping.ogg', ROUND_SOUND_TEST_VOLUME, FALSE)
	var/datum/gas_mixture/air = source.return_air()
	var/pressure = air.return_pressure()
	var/list/echo = sound_echo_for(ROUND_SOUND_TEST_ENV_FULL, ROUND_SOUND_TEST_ENV_MUTED)
	for(var/mob/living/round_sound_listener/listener as anything in listeners)
		TEST_ASSERT_EQUAL(listener.captured_pressure, pressure, "Давление источника не передано")
		TEST_ASSERT(listener.captured_echo == echo, "Список эха не переиспользован")
	playsound(source, 'sound/machines/ping.ogg', ROUND_SOUND_TEST_VOLUME, FALSE, pressure_affected = FALSE)
	for(var/mob/living/round_sound_listener/listener as anything in listeners)
		TEST_ASSERT_NULL(listener.captured_pressure, "Ненужный расчёт давления")
		TEST_ASSERT_NULL(listener.captured_echo, "Ненужный расчёт эха")

/// AV-перенаправление сохраняет давление источника, но меняет параметры эха.
/datum/unit_test/sound_redirect_context/Run()
	var/mob/body = allocate(/mob, run_loc_floor_bottom_left)
	var/mob/living/round_sound_listener/listener = allocate(/mob/living/round_sound_listener)
	body.audiovisual_redirect = listener
	body.playsound_local(run_loc_floor_bottom_left, 'sound/machines/ping.ogg', ROUND_SOUND_TEST_VOLUME, FALSE, source_pressure = ROUND_SOUND_TEST_VACUUM_PRESSURE, source_echo = sound_echo_for(ROUND_SOUND_TEST_ENV_FULL, ROUND_SOUND_TEST_ENV_MUTED))
	TEST_ASSERT_EQUAL(listener.captured_pressure, ROUND_SOUND_TEST_VACUUM_PRESSURE, "Нулевое давление потеряно при перенаправлении")
	TEST_ASSERT_NULL(listener.captured_echo, "Перенаправление получило исходный список эха")
	TEST_ASSERT_EQUAL(listener.captured_envwet, ROUND_SOUND_TEST_ENV_FULL, "Параметр envwet не изменён")
	TEST_ASSERT_EQUAL(listener.captured_envdry, ROUND_SOUND_TEST_ENV_MUTED, "Параметр envdry не изменён")
	TEST_ASSERT_EQUAL(listener.captured_virtual_hearer, run_loc_floor_bottom_left, "Позиция виртуального слушателя потеряна")
	body.audiovisual_redirect = null

/datum/unit_test/sound_broadcast_context/Destroy()
	for(var/mob/living/listener as anything in listeners)
		listener.clear_important_client_contents()
	listeners = null
	return ..()

/datum/atom_hud/round_removal_probe
	var/list/removed_images
	var/removal_calls = 0

/datum/atom_hud/round_removal_probe/should_show_to(mob/viewer, atom/movable/target)
	return FALSE

/datum/atom_hud/round_removal_probe/viewer_has_images(mob/viewer)
	return TRUE

/datum/atom_hud/round_removal_probe/remove_hud_images(mob/viewer, list/images_to_remove)
	removed_images = images_to_remove.Copy()
	removal_calls++

/// Полное снятие HUD удаляет весь набор одной операцией, даже после смены видимости.
/datum/unit_test/atom_hud_full_removal_batch/Run()
	var/datum/atom_hud/round_removal_probe/hud = allocate(/datum/atom_hud/round_removal_probe)
	hud.hud_icons = list(HEALTH_HUD)
	var/mob/viewer = allocate(/mob)
	hud.hudusers[viewer] = 2
	var/list/expected = list()
	for(var/index in 1 to 3)
		var/obj/effect/target = allocate(/obj/effect)
		var/image/marker = image('icons/mob/hud.dmi')
		target.hud_list = list(HEALTH_HUD = marker)
		hud.hudatoms += target
		expected += marker
	hud.remove_hud_from(viewer)
	TEST_ASSERT_EQUAL(hud.removal_calls, 0, "Снятие одного из двух источников убрало HUD")
	hud.remove_hud_from(viewer)
	TEST_ASSERT_EQUAL(hud.removal_calls, 1, "Снятие HUD не объединено в одну операцию")
	TEST_ASSERT_EQUAL(length(hud.removed_images), length(expected), "Удалены не все изображения")
	for(var/image/marker as anything in expected)
		TEST_ASSERT(marker in hud.removed_images, "Потеряно изображение скрытого атома")

/// Отложенная проба отвергает несуществующую ссылку и несовпадающую метку удаления.
/datum/unit_test/gc_deferred_client_probe_identity/Run()
	var/datum/target = allocate(/datum)
	qdel(target)
	var/ref_id = text_ref(target)
	TEST_ASSERT(!SSgarbage.probe_warnfail_clients(ref_id, target.type, target.gc_destroyed + 1), "Принята чужая метка удаления")
	TEST_ASSERT(!SSgarbage.probe_warnfail_clients(ref_id, /obj, target.gc_destroyed), "Принят чужой тип")
	TEST_ASSERT(SSgarbage.probe_warnfail_clients(ref_id, target.type, target.gc_destroyed), "Отклонена исходная цель")
	var/missing_ref_id = "\[0x0]"
	TEST_ASSERT_NULL(locate(missing_ref_id), "Тестовая ссылка разрешается в объект")
	TEST_ASSERT(!SSgarbage.probe_warnfail_clients(missing_ref_id, /datum, target.gc_destroyed), "Принята несуществующая ссылка")

#undef ROUND_SOUND_TEST_VOLUME
#undef ROUND_SOUND_TEST_ENV_FULL
#undef ROUND_SOUND_TEST_ENV_MUTED
#undef ROUND_SOUND_TEST_VACUUM_PRESSURE
