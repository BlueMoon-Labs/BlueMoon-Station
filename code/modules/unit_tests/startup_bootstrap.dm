/// The CI world must reach tests through a deterministic Dynamic round without
/// waiting for either crash-map or game-mode votes.
/datum/unit_test/startup_bootstrap
	priority = TEST_PRE

/datum/unit_test/startup_bootstrap/Run()
	TEST_ASSERT(SSticker.HasRoundStarted(), "unit tests started before ticker reached PLAYING")
	TEST_ASSERT(SSticker.setup_done, "unit tests started before ticker PostSetup completed")
	TEST_ASSERT(istype(SSticker.mode, /datum/game_mode/dynamic), "unit test bootstrap selected [SSticker.mode?.type] instead of Dynamic")
	TEST_ASSERT(SSticker.modevoted, "unit test bootstrap did not mark mode selection complete")
	TEST_ASSERT(isnull(SSvote.mode), "unit test bootstrap left an active [SSvote.mode] vote")
	// PostSetup is real work and can exceed 30 seconds on a full CI map. This
	// ceiling still catches the old five-minute unattended vote path.
	TEST_ASSERT(world.time - SSticker.round_start_time <= 90 SECONDS, "unit tests waited more than 90 seconds after roundstart")
	// Панель спавна должна быть готова к первому клику админа, а не собираться
	// на 3-5 секунд прямо в раунде. Ассеты обязаны существовать после SSassets.
	TEST_ASSERT_NOTNULL(GLOB.asset_datums[/datum/asset/spritesheet/spawnpanel], "Spawn Panel spritesheet was not built during startup")
	TEST_ASSERT_NOTNULL(GLOB.asset_datums[/datum/asset/json/spawnpanel], "Spawn Panel JSON was not built during startup")
	// А порядок сборки ассетов обязан оставаться таким, чтобы карта иконок была
	// заполнена до генерации JSON - иначе в панели пропадут все превьюшки.
	TEST_ASSERT(length(GLOB.spawnpanel_icon_map) > 0, "Spawn Panel icon map is empty after startup")
	var/datum/asset/json/spawnpanel/atom_data = GLOB.asset_datums[/datum/asset/json/spawnpanel]
	var/list/generated = atom_data.generate()
	var/list/generated_atoms = generated["atoms"]
	var/with_sprite = 0
	for(var/type_key in generated_atoms)
		var/list/entry = generated_atoms[type_key]
		if(entry["iconid"])
			with_sprite++
	TEST_ASSERT(with_sprite > 1000, "Spawn Panel JSON has only [with_sprite] entries with a sprite id out of [length(generated_atoms)]")
