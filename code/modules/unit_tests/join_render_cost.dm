/mob/living/carbon/human/dummy/consistent/join_render_test
	var/body_updates = 0

/mob/living/carbon/human/dummy/consistent/join_render_test/update_body(update_genitals = FALSE, block_recursive_calls = FALSE)
	if(!HAS_TRAIT(src, TRAIT_HUMAN_NO_RENDER))
		body_updates++
	return ..()

/// Латеджойн одевает тело под TRAIT_HUMAN_NO_RENDER и собирает внешность один раз: картинка обязана совпасть с поштучной сборкой.
/datum/unit_test/latejoin_deferred_render_matches_direct

/datum/unit_test/latejoin_deferred_render_matches_direct/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	for(var/rank in list("Security Officer", "Medical Doctor"))
		var/datum/job/job = SSjob.GetJob(rank)
		TEST_ASSERT_NOTNULL(job, "нет профессии [rank]")
		prefs.pref_species = new /datum/species/lizard
		prefs.random_character(MALE)
		prefs.real_name = "Join Render [rank]"
		var/mob/living/carbon/human/dummy/consistent/join_render_test/direct = allocate(/mob/living/carbon/human/dummy/consistent/join_render_test)
		var/mob/living/carbon/human/dummy/consistent/join_render_test/deferred = allocate(/mob/living/carbon/human/dummy/consistent/join_render_test)
		direct.body_updates = 0
		deferred.body_updates = 0
		ADD_TRAIT(deferred, TRAIT_HUMAN_NO_RENDER, "join_render_test")
		for(var/mob/living/carbon/human/dummy/consistent/join_render_test/body as anything in list(direct, deferred))
			prefs.copy_to(body, initial_spawn = TRUE)
			job.equip(body, TRUE, FALSE, TRUE)
		TEST_ASSERT_EQUAL(deferred.body_updates, 0, "под отсрочкой тело пересобиралось")
		REMOVE_TRAIT(deferred, TRAIT_HUMAN_NO_RENDER, "join_render_test")
		TEST_ASSERT(deferred.body_updates < direct.body_updates, "отсрочка не сократила пересборки тела [rank]: [deferred.body_updates] против [direct.body_updates]")
		TEST_ASSERT(length(deferred.overlays), "после снятия отсрочки у тела нет слоёв")
		for(var/direction in GLOB.cardinals)
			var/icon/expected = getFlatIcon(direct, defdir = direction, no_anim = TRUE)
			var/icon/actual = getFlatIcon(deferred, defdir = direction, no_anim = TRUE)
			TEST_ASSERT_EQUAL(actual.Width(), expected.Width(), "изменилась ширина [rank], направление [direction]")
			TEST_ASSERT_EQUAL(actual.Height(), expected.Height(), "изменилась высота [rank], направление [direction]")
			for(var/pixel_x in 1 to expected.Width())
				for(var/pixel_y in 1 to expected.Height())
					TEST_ASSERT_EQUAL(actual.GetPixel(pixel_x, pixel_y), expected.GetPixel(pixel_x, pixel_y), "изменилась картинка [rank], направление [direction], пиксель [pixel_x],[pixel_y]")

/// Закрытое окно осмотра отдаёт экран со стопкой плоскостей в пул клиента, следующее окно берёт его чистым.
/datum/unit_test/examine_screen_pool_reuses_plane_group

/datum/unit_test/examine_screen_pool_reuses_plane_group/Run()
	var/mob/living/carbon/human/first_subject = allocate(/mob/living/carbon/human/dummy/consistent)
	var/mob/living/carbon/human/second_subject = allocate(/mob/living/carbon/human/dummy/consistent)
	second_subject.color = "#aa77cc"
	var/mob/viewer = allocate(/mob)
	var/datum/description_profile/first_profile = allocate(/datum/description_profile, first_subject)
	var/datum/description_profile/second_profile = allocate(/datum/description_profile, second_subject)
	var/datum/examine_screen_pool/pool = new
	allocated += pool

	var/atom/movable/screen/map_view/examine_panel_screen/screen = pool.take()
	first_profile.viewer_screens = list()
	first_profile.viewer_screens[viewer] = screen
	first_profile.update_preview(viewer)
	var/datum/plane_master_group/popup/group = screen.ensure_plane_group()
	var/map_name = screen.assigned_map
	screen.setDir(EAST)
	first_profile.current_bg_state = "engine"
	first_profile.update_preview(viewer)
	TEST_ASSERT(length(screen.overlays), "превью не собралось")

	first_profile.ui_close(viewer)
	TEST_ASSERT(!QDELETED(screen), "закрытое окно удалило экран вместо возврата в пул")
	TEST_ASSERT(!QDELETED(group), "закрытое окно удалило стопку плоскостей")
	TEST_ASSERT_NULL(LAZYACCESS(first_profile.viewer_screens, viewer), "закрытый экран остался в карточке")
	TEST_ASSERT_EQUAL(length(screen.overlays), 0, "в пуле остался прежний персонаж")
	TEST_ASSERT_EQUAL(screen.dir, SOUTH, "в пуле остался поворот прежнего окна")
	TEST_ASSERT_EQUAL(screen.icon_state, initial(screen.icon_state), "в пуле остался фон прежнего окна")

	var/atom/movable/screen/map_view/examine_panel_screen/reopened = pool.take()
	TEST_ASSERT_EQUAL(reopened, screen, "новое окно не взяло экран из пула")
	TEST_ASSERT_EQUAL(reopened.popup_plane_group, group, "новое окно собрало стопку плоскостей заново")
	TEST_ASSERT_EQUAL(reopened.assigned_map, map_name, "экран из пула сменил имя карты")
	second_profile.viewer_screens = list()
	second_profile.viewer_screens[viewer] = reopened
	second_profile.update_preview(viewer)
	var/mutable_appearance/shown = reopened.overlays[1]
	TEST_ASSERT_EQUAL(shown.color, second_subject.color, "экран из пула показал прежнего персонажа")

	var/atom/movable/screen/map_view/examine_panel_screen/parallel = pool.take()
	var/atom/movable/screen/map_view/examine_panel_screen/third = pool.take()
	TEST_ASSERT(parallel != reopened && third != reopened, "два открытых окна получили один экран")
	TEST_ASSERT(parallel.assigned_map != reopened.assigned_map && third.assigned_map != parallel.assigned_map, "открытые окна делят имя карты")
	release_examine_screen(viewer, parallel)
	release_examine_screen(viewer, third)
	second_profile.ui_close(viewer)
	TEST_ASSERT_EQUAL(length(pool.idle), 2, "пул вырос сверх предела")
	TEST_ASSERT(QDELETED(reopened), "экран сверх предела пула не удалён")

	var/atom/movable/screen/map_view/examine_panel_screen/in_use = pool.take()
	var/atom/movable/screen/map_view/examine_panel_screen/idle_screen = pool.idle[1]
	qdel(pool)
	TEST_ASSERT(QDELETED(idle_screen), "свободный экран пережил свой пул")
	TEST_ASSERT_NULL(in_use.home_pool, "открытый экран держит удалённый пул")
	release_examine_screen(viewer, in_use)
	TEST_ASSERT(QDELETED(in_use), "экран удалённого пула вернулся в пул")

/// Смена слота: запись прежнего слота не сбрасывает кэш имён, номер нового слота уже на диске, полная запись префов уходит таймером.
/datum/unit_test/character_switch_slot_defers_full_save
	var/datum/preferences/prefs
	var/datum/character_setup/setup

/datum/unit_test/character_switch_slot_defers_full_save/Destroy()
	QDEL_NULL(setup)
	if(prefs)
		if(prefs.pref_queue)
			deltimer(prefs.pref_queue)
			prefs.pref_queue = null
		if(prefs.path)
			fdel(prefs.path)
		QDEL_NULL(prefs)
	return ..()

/datum/unit_test/character_switch_slot_defers_full_save/Run()
	prefs = new
	prefs.load_path("unit_test_switch_slot_defer")
	if(fexists(prefs.path))
		fdel(prefs.path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.pref_species = new /datum/species/human
	prefs.random_character(MALE)
	prefs.default_slot = 2
	prefs.real_name = "Слот Два"
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE)
	prefs.load_character(1, bypass_cooldown = TRUE)
	prefs.real_name = "Слот Один"
	prefs.character_slot_name = "  Первый  "
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE)
	var/list/names = prefs.get_slot_names()
	TEST_ASSERT_EQUAL(names[1], "Слот Один", "не прочитано имя первого слота")
	TEST_ASSERT_EQUAL(names[2], "Слот Два", "не прочитано имя второго слота")

	prefs.real_name = "Слот Один Новый"
	prefs.character_slot_name = " Новый "
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE)
	TEST_ASSERT_NOTNULL(prefs.slot_names_cache, "запись слота сбросила кэш имён")
	var/list/cached_names = prefs.slot_names_cache.Copy()
	var/list/cached_custom = prefs.slot_custom_names_cache.Copy()
	prefs.slot_names_cache = null
	var/list/disk_names = prefs.get_slot_names()
	var/list/disk_custom = prefs.get_slot_custom_names()
	for(var/slot in 1 to prefs.max_save_slots)
		TEST_ASSERT_EQUAL(cached_names[slot], disk_names[slot], "кэш имени слота [slot] разошёлся с файлом")
		TEST_ASSERT_EQUAL(cached_custom[slot], disk_custom[slot], "кэш названия слота [slot] разошёлся с файлом")
	TEST_ASSERT_EQUAL(disk_names[1], "Слот Один Новый", "новое имя не записано")

	setup = new(prefs)
	prefs.character_setup_autosave = TRUE
	TEST_ASSERT_NULL(prefs.pref_queue, "до смены слота запись префов уже стояла в очереди")
	var/mob/user = allocate(/mob)
	var/datum/tgui/setup_ui = new(user, setup, "CharacterSetup")
	setup_ui.status = UI_INTERACTIVE
	setup.ui_act("switch_slot", list("slot" = 2), setup_ui)
	qdel(setup_ui)
	TEST_ASSERT_EQUAL(prefs.default_slot, 2, "слот не сменился")
	TEST_ASSERT_EQUAL(prefs.real_name, "Слот Два", "загружен не тот персонаж")
	TEST_ASSERT_NOTNULL(prefs.pref_queue, "полная запись префов не отложена")
	var/savefile/stored_file = new(prefs.path)
	stored_file.cd = "/"
	var/stored_slot
	stored_file["default_slot"] >> stored_slot
	stored_file = null
	TEST_ASSERT_EQUAL(stored_slot, 2, "номер слота не дошёл до файла")
