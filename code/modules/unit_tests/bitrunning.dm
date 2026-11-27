/// Проверяет корректность настроек виртуальных доменов.
/datum/unit_test/bitrunner_vdom_settings

/datum/unit_test/bitrunner_vdom_settings/Run()
	var/obj/structure/closet/crate/secure/bitrunning/decrypted/cache = allocate(/obj/structure/closet/crate/secure/bitrunning/decrypted)

	for(var/path in subtypesof(/datum/lazy_template/virtual_domain))
		var/datum/lazy_template/virtual_domain/vdom = new path
		TEST_ASSERT_NOTNULL(vdom.key, "[path] should have a key")
		TEST_ASSERT_NOTNULL(vdom.map_name, "[path] should have a map name")

		if(!length(vdom.completion_loot))
			continue

		TEST_ASSERT_EQUAL(cache.spawn_loot(vdom.completion_loot), TRUE, "[path] didn't spawn loot. Completion loot should be an associative list")

/datum/unit_test/bitrunner_reward_certificate/proc/complete_domain()
	var/obj/machinery/quantum_server/server = allocate(/obj/machinery/quantum_server)
	var/obj/machinery/byteforge/forge = allocate(/obj/machinery/byteforge)
	var/obj/structure/closet/crate/secure/bitrunning/encrypted/cache = allocate(/obj/structure/closet/crate/secure/bitrunning/encrypted)
	server.generated_domain = new /datum/lazy_template/virtual_domain
	server.generated_domain.start_time = world.time

	server.generate_loot(cache, forge)
	server.generated_domain = null

	var/obj/structure/closet/crate/secure/bitrunning/decrypted/reward = locate() in server
	if(isnull(reward))
		return
	allocated += reward
	reward.forceMove(run_loc_floor_bottom_left)
	return reward

/// "undefined proc or verb /datum/weakref/forceMove()": сервер вешал на ящик награды weakref вместо сертификата.
/datum/unit_test/bitrunner_reward_certificate/Run()
	var/obj/structure/closet/crate/secure/bitrunning/decrypted/reward = complete_domain()
	TEST_ASSERT_NOTNULL(reward, "test premise: сервер обязан выдать ящик награды за доставленный груз")
	var/obj/item/paper/certificate = reward.manifest
	TEST_ASSERT(istype(certificate, /obj/item/paper), "на ящике награды обязан висеть сам сертификат")
	TEST_ASSERT_EQUAL(certificate.loc, reward, "сертификат лежит в ящике и уходит вместе с ним")

	var/mob/living/carbon/human/opener = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	TEST_ASSERT(reward.open(opener), "ящик награды обязан открываться с сертификатом")
	TEST_ASSERT_NULL(reward.manifest, "при открытии сертификат срывается")
	TEST_ASSERT_EQUAL(certificate.loc, run_loc_floor_bottom_left, "сорванный сертификат падает рядом с ящиком")

	reward = complete_domain()
	TEST_ASSERT_NOTNULL(reward, "test premise: второй домен тоже выдаёт ящик награды")
	certificate = reward.manifest
	reward.tear_manifest(opener)
	TEST_ASSERT_NULL(reward.manifest, "сертификат срывается и с закрытого ящика")
	TEST_ASSERT(opener.is_holding(certificate), "сорванный сертификат оказывается в руке")

/// "atom_entered overridden": клетки приёма груза держали сигнал сервера после домена, турфы резервации переиспользуются.
/datum/unit_test/bitrunner_goal_turf_released_with_domain/Run()
	var/obj/machinery/quantum_server/server = allocate(/obj/machinery/quantum_server)
	var/turf/exit = run_loc_floor_bottom_left
	var/turf/goal = get_step(exit, NORTH)

	for(var/attempt in 1 to 2)
		allocate(/obj/effect/landmark/bitrunning/hololadder_spawn, exit)
		allocate(/obj/effect/landmark/bitrunning/cache_goal_turf, goal)
		server.generated_domain = new /datum/lazy_template/virtual_domain
		TEST_ASSERT(server.load_map_items(), "test premise: домен из выхода и клетки приёма загружается")
		TEST_ASSERT(server.signal_procs?[goal]?[COMSIG_ATOM_ENTERED], "клетка приёма слушает доставку, пока домен загружен")

		server.scrub_vdom()
		TEST_ASSERT_NULL(server.signal_procs?[goal], "после домена клетка приёма больше не связана с сервером")
