/// Смертельный для носителя удар по аватару отключает его, но не удаляет тело посреди собственного apply_damage.
/datum/unit_test/bitrunning_avatar_lethal_hit_defers_delete

/datum/unit_test/bitrunning_avatar_lethal_hit_defers_delete/Run()
	var/obj/machinery/quantum_server/server = allocate(/obj/machinery/quantum_server)
	var/obj/machinery/netpod/pod = allocate(/obj/machinery/netpod, get_step(run_loc_floor_bottom_left, EAST))
	for(var/obj/machinery/machine as anything in list(server, pod))
		machine.machine_stat = NONE
		machine.set_is_operational(TRUE)

	var/mob/living/carbon/human/old_body = allocate(/mob/living/carbon/human)
	old_body.mind_initialize()
	var/mob/living/carbon/human/avatar = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	avatar.mind_initialize()
	avatar.AddComponent(/datum/component/avatar_connection, old_mind = old_body.mind, old_body = old_body, server = server, pod = pod, help_text = "", copy_body = FALSE)
	TEST_ASSERT_NOTNULL(avatar.GetComponent(/datum/component/avatar_connection), "Аватар должен подключиться")

	var/obj/item/bodypart/leg = avatar.get_bodypart(BODY_ZONE_L_LEG)
	avatar.apply_damage(old_body.health + old_body.maxHealth + 10, BRUTE, leg)

	TEST_ASSERT_NULL(avatar.GetComponent(/datum/component/avatar_connection), "Смертельный для носителя удар должен отключить аватара")
	TEST_ASSERT(!QDELETED(avatar), "Аватар не должен удаляться посреди собственного apply_damage")
	TEST_ASSERT_NOTNULL(avatar.dna, "У аватара до конца удара должна оставаться dna")

	for(var/i in 1 to 20)
		if(QDELETED(avatar))
			break
		sleep(world.tick_lag)
	TEST_ASSERT(QDELETED(avatar), "Отключённый аватар должен удалиться на следующем тике")
