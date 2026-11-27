/datum/unit_test/blackmesa_hecu_sleeper_damage/Run()
	var/list/breakable_types = list(
		/obj/effect/mob_spawn/human/black_mesa/hecu,
		/obj/effect/mob_spawn/human/black_mesa/hecu/breacher,
		/obj/effect/mob_spawn/human/black_mesa/hecu/medic,
		/obj/effect/mob_spawn/human/black_mesa/hecu/engineer,
		/obj/effect/mob_spawn/human/black_mesa/hecu/leader,
		/obj/effect/mob_spawn/human/black_mesa/hecu/machinegunner,
		/obj/effect/mob_spawn/human/black_mesa/hecu/sniper,
		/obj/effect/mob_spawn/human/black_mesa/hecu/blackops,
		/obj/effect/mob_spawn/human/black_mesa/hecu/blackops/assault,
	)
	for(var/spawner_type in breakable_types)
		var/obj/effect/mob_spawn/spawner = allocate(spawner_type, run_loc_floor_bottom_left)
		TEST_ASSERT(spawner.can_take_damage, "[spawner_type] должен принимать урон")
		TEST_ASSERT(spawner.obj_flags & CAN_BE_HIT, "[spawner_type] должен быть доступен для melee")
		var/integrity_before = spawner.obj_integrity
		spawner.take_damage(10, BRUTE, MELEE, FALSE)
		TEST_ASSERT(spawner.obj_integrity < integrity_before, "[spawner_type] должен терять прочность")

	var/obj/effect/mob_spawn/human/black_mesa/hecu/lost/deserter = allocate(/obj/effect/mob_spawn/human/black_mesa/hecu/lost, run_loc_floor_top_right)
	TEST_ASSERT(!deserter.can_take_damage, "HECU deserter должен оставаться неуязвимым")
	TEST_ASSERT(!(deserter.obj_flags & CAN_BE_HIT), "HECU deserter не должен быть melee-целью")
	var/deserter_integrity = deserter.obj_integrity
	deserter.take_damage(50, BRUTE, MELEE, FALSE)
	TEST_ASSERT_EQUAL(deserter.obj_integrity, deserter_integrity, "HECU deserter должен игнорировать урон")
