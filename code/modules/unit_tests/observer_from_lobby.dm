/// Худ, собранный до входа клиента, - тот же худ госта, и вход его не пересобирает.
/datum/unit_test/observer_prebuilt_hud
	priority = TEST_LONGER

/datum/unit_test/observer_prebuilt_hud/Run()
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(ghost.hud_used, "у госта без клиента уже есть худ")
	ghost.prebuild_hud()
	var/datum/hud/ghost/hud = ghost.hud_used
	TEST_ASSERT(istype(hud), "заранее собран не худ госта, а [hud?.type]")
	TEST_ASSERT(length(hud.plane_masters), "у заранее собранного худа нет плоскостей")
	var/has_orbit = FALSE
	for(var/atom/movable/screen/ghost/orbit/button in hud.static_inventory)
		has_orbit = TRUE
	TEST_ASSERT(has_orbit, "у заранее собранного худа нет кнопок госта")
	ghost.prebuild_hud()
	ghost.create_mob_hud()
	TEST_ASSERT(ghost.hud_used == hud, "повторная сборка заменила готовый худ")
	qdel(ghost)
	TEST_ASSERT(QDELETED(hud), "худ пережил госта")

/// Игрок ушёл, пока гост строился: ни госта, ни моба лобби не остаётся.
/datum/unit_test/observer_from_lobby_abort_cleans_up
	priority = TEST_LONGER

/datum/unit_test/observer_from_lobby_abort_cleans_up/Run()
	var/list/ghosts_before = list()
	for(var/mob/dead/observer/ghost in GLOB.mob_list)
		ghosts_before += ghost
	var/mob/dead/new_player/player = allocate(/mob/dead/new_player)
	TEST_ASSERT(!player.become_observer(), "переход без клиента засчитался")
	TEST_ASSERT(QDELETED(player), "моб лобби без клиента остался висеть")
	for(var/mob/dead/observer/ghost in GLOB.mob_list)
		TEST_ASSERT((ghost in ghosts_before) || QDELETED(ghost), "после прерванного перехода остался гост [ghost]")
