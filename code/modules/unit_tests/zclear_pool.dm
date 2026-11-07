/// Пул свободных z-уровней засеян на старте раунда, и весь его космос инициализирован: с воздухом и иконкой.
/datum/unit_test/zclear_pool_levels_initialized/Run()
	TEST_ASSERT_EQUAL(LAZYLEN(SSzclear.free_levels), SSzclear.seeded_pool_levels, "пул свободных уровней засеян не полностью")
	for(var/datum/space_level/level as anything in SSzclear.free_levels)
		var/uninitialized = 0
		var/without_air = 0
		for(var/turf/open/space/T in block(locate(1, 1, level.z_value), locate(world.maxx, world.maxy, level.z_value)))
			if(!(T.flags_1 & INITIALIZED_1))
				uninitialized++
			else if(!T.air)
				without_air++
		TEST_ASSERT_EQUAL(uninitialized, 0, "на уровне пула [level.z_value] остался неинициализированный космос")
		TEST_ASSERT_EQUAL(without_air, 0, "на уровне пула [level.z_value] космос без воздуха")
