/// Стартовый навес атмоса (5.8 тыс. активных турфов и 13 тыс. атмос-машин на проде) ждал всё лобби и разгребался ровно на спавне экипажа. В лобби SSair обязан работать.
/datum/unit_test/atmos_settles_in_lobby/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/source = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/turf/open/neighbor = locate(source.x + 1, source.y, source.z)
	TEST_ASSERT(istype(source) && source.air && istype(neighbor) && neighbor.air, "в зоне теста нет пары открытых турфов")
	var/neighbor_moles = neighbor.air.total_moles()
	source.air.adjust_moles(GAS_O2, 200)
	SSair.add_to_active(source)

	var/old_runlevel = Master.current_runlevel
	Master.SetRunLevel(RUNLEVEL_LOBBY)
	var/fired_before = SSair.times_fired
	var/deadline = world.time + 5 SECONDS
	while(world.time < deadline && (SSair.times_fired < fired_before + 2 || neighbor.air.total_moles() <= neighbor_moles))
		sleep(world.tick_lag)
	var/fired_in_lobby = SSair.times_fired - fired_before
	var/neighbor_gain = neighbor.air.total_moles() - neighbor_moles
	Master.SetRunLevel(1 << (old_runlevel - 1))

	TEST_ASSERT(fired_in_lobby >= 2, "SSair не работал в лобби: проходов [fired_in_lobby] за 5 с")
	TEST_ASSERT(neighbor_gain > 0, "градиент не начал оседать в лобби: сосед получил [neighbor_gain] моль")
