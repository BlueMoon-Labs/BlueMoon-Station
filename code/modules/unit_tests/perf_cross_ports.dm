// ===== Порты оптимизаций из соседних кодбаз: гравитация, камеры, звук, диагностика =====

// --- Кэш гравитации по z (SSmapping.gravity_by_z_level, порт tg) ---
//
// has_gravity() зовётся на каждый шаг каждого моба: вместо обхода
// GLOB.gravity_generators и цепочки level_trait->get_level читается плоский
// кэш, а сигналы forced gravity шлются только при живом подписчике.

/datum/unit_test/gravity_z_cache/Run()
	TEST_ASSERT_EQUAL(length(SSmapping.gravity_by_z_level), length(SSmapping.z_list), "The gravity cache must cover every managed z-level")

	for(var/z in 1 to length(SSmapping.z_list))
		var/expected = 0
		for(var/obj/machinery/gravity_generator/main/generator as anything in GLOB.gravity_generators["[z]"])
			expected = max(generator.setting, expected)
		expected = expected || SSmapping.level_trait(z, ZTRAIT_GRAVITY) || 0
		TEST_ASSERT_EQUAL(SSmapping.gravity_by_z_level[z], expected, "The cached gravity for z [z] must match the generators/trait formula")

	// ленивый гейт сигналов: подписчик forced gravity обязан перекрывать кэш
	var/turf/T = run_loc_floor_bottom_left
	var/base_gravity = T.has_gravity(T)
	RegisterSignal(T, COMSIG_TURF_HAS_GRAVITY, PROC_REF(on_turf_gravity))
	TEST_ASSERT_EQUAL(T.has_gravity(T), 42, "A registered forced-gravity listener must override the z cache")
	UnregisterSignal(T, COMSIG_TURF_HAS_GRAVITY)
	TEST_ASSERT_EQUAL(T.has_gravity(T), base_gravity, "After unregistering, has_gravity must return the cached base value again")

/datum/unit_test/gravity_z_cache/proc/on_turf_gravity(datum/source, atom/asker, list/forced_gravity)
	SIGNAL_HANDLER
	forced_gravity += 42

// --- Кэш сетей камер (cameranet.get_cameras_by_network) ---
//
// Консоль/баг/SecurEye раньше пересобирали весь GLOB.cameranet.cameras на
// каждый ui_static_data и каждый клик переключения камеры.

/datum/unit_test/camera_network_cache/Run()
	var/obj/machinery/camera/cam = allocate(/obj/machinery/camera, run_loc_floor_bottom_left)
	// сборка камеры выставляет network/c_tag после Initialize и инвалидирует кэш - повторяем её порядок
	cam.c_tag = "unit-test-cam"
	cam.network = list("unit_test_net")
	GLOB.cameranet.invalidate_camera_cache()

	var/list/net_cameras = GLOB.cameranet.get_cameras_by_network("unit_test_net")
	TEST_ASSERT_NOTNULL(net_cameras, "A camera's network must appear in the cameranet cache")
	TEST_ASSERT_EQUAL(net_cameras["unit-test-cam"], cam, "The camera must be reachable by its c_tag through the network cache")
	TEST_ASSERT_NULL(GLOB.cameranet.get_cameras_by_network("unit_test_missing_net"), "An unknown network must return null")

	qdel(cam)
	var/list/after_delete = GLOB.cameranet.get_cameras_by_network("unit_test_net")
	TEST_ASSERT(!length(after_delete), "A destroyed camera must leave the network cache")

// --- Слушатели playsound из канала CLIENTS спатиал-грида ---
//
// playsound больше не обходит всех клиентов z-уровня: слушатели берутся из
// ячеек грида вокруг источника (см. sound.dm).

/datum/unit_test/playsound_grid_listeners/Run()
	TEST_ASSERT(SSspatial_grid.initialized, "test premise: SSspatial_grid must be initialized in CI")
	var/turf/center = run_loc_floor_bottom_left

	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human, get_step(center, EAST))
	fake_player.enable_client_mobs_in_contents() // канал CLIENTS обычно кормит Login

	var/list/listeners = get_hearers_in_view(5, center, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
	TEST_ASSERT(fake_player in listeners, "A registered client mob in view must be found through the CLIENTS channel")

	var/mob/living/carbon/human/npc = allocate(/mob/living/carbon/human, center)
	listeners = get_hearers_in_view(5, center, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
	TEST_ASSERT(!(npc in listeners), "A clientless mob must not be found through the CLIENTS channel")

	fake_player.clear_important_client_contents()
	listeners = get_hearers_in_view(5, center, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
	TEST_ASSERT(!(fake_player in listeners), "After clearing the channel the mob must not be found anymore")

// --- Кэш view(5) для compose_message (get_speech_visible_turfs) ---
//
// Все слушатели одного сообщения обрабатываются в одном тике подряд:
// первый вызов платит за view(), остальные читают кэш.

/datum/unit_test/speech_visible_turfs_cache/Run()
	var/turf/center = run_loc_floor_bottom_left
	var/list/first = get_speech_visible_turfs(center)
	TEST_ASSERT_NOTNULL(first, "get_speech_visible_turfs must return a list")
	TEST_ASSERT(first[center], "The source turf must see itself")

	var/list/second = get_speech_visible_turfs(center)
	TEST_ASSERT(first == second, "The same source turf in the same tick must return the cached list")

	var/turf/other = get_step(center, NORTH)
	var/list/third = get_speech_visible_turfs(other)
	TEST_ASSERT(third != first, "A different source turf must rebuild the cache")
	TEST_ASSERT(third[other], "The new source turf must see itself")

// --- Кольцо медленной работы SStick_spikes ---
//
// SStimer/SSverb_manager/client/Topic пишут сюда медленные вызовы, чтобы
// спайки "DM вне МК" перестали быть анонимными.

/datum/unit_test/tick_spikes_slow_work/Run()
	var/datum/controller/subsystem/tick_spikes/spikes = SStick_spikes
	TEST_ASSERT_NOTNULL(spikes, "test premise: SStick_spikes must exist")

	spikes.record_slow_work("тест", "юнит-тестовая запись", 42.5)
	var/found = FALSE
	for(var/line in spikes.collect_slow_work(world.time - 10))
		if(findtext(line, "юнит-тестовая запись") && findtext(line, "42.5"))
			found = TRUE
			break
	TEST_ASSERT(found, "record_slow_work must surface through collect_slow_work")

	var/datum/callback/global_callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(get_hear))
	TEST_ASSERT(findtext(spikes.callback_desc(global_callback), "GLOBAL_PROC"), "A global proc callback must be described as GLOBAL_PROC")
	var/datum/callback/datum_callback = CALLBACK(src, TYPE_PROC_REF(/datum/unit_test, Run))
	TEST_ASSERT(findtext(spikes.callback_desc(datum_callback), "[type]"), "A datum callback must be described with its object type")
