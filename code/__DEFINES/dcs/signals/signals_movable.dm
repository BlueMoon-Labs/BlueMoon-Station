///from base of atom/experience_pressure_difference(): (pressure_difference, direction, pressure_resistance_prob_delta)
#define COMSIG_MOVABLE_PRE_PRESSURE_PUSH "atom_pre_pressure_push"
	///prevents pressure movement
	#define COMSIG_MOVABLE_BLOCKS_PRESSURE (1<<0)

#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
/// После первого CHECK_TICK в pathfind.search(), только для тестов: (/datum/pathfind/search).
#define COMSIG_TEST_PATHFIND_AFTER_FIRST_TICK "test_pathfind_after_first_tick"
#endif
