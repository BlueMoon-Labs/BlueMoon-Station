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
	TEST_ASSERT(isnull(GLOB.asset_datums[/datum/asset/spritesheet/spawnpanel]), "Spawn Panel spritesheet was built eagerly during startup")
	TEST_ASSERT(isnull(GLOB.asset_datums[/datum/asset/json/spawnpanel]), "Spawn Panel JSON was built eagerly during startup")
