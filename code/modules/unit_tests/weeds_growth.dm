/obj/structure/alien/weeds/growth_test
	var/expansions = 0

/obj/structure/alien/weeds/growth_test/expand()
	expansions++
	return TRUE

/obj/structure/alien/weeds/node/growth_test
	weak = TRUE
	lon_range = 0

/// Ожидание роста сбрасывается при появлении weeds, перемещении и смене радиуса узла.
/datum/unit_test/weeds_growth_deadline/Run()
	var/turf/near = run_loc_floor_bottom_left
	var/turf/far = locate(near.x + 3, near.y, near.z)
	var/obj/structure/alien/weeds/node/growth_test/node = allocate(/obj/structure/alien/weeds/node/growth_test, near)
	node.node_range = 1
	node.last_expand = INFINITY
	var/obj/structure/alien/weeds/growth_test/weed = allocate(/obj/structure/alien/weeds/growth_test, near)
	weed.last_expand = world.time + 0.1 SECONDS
	node.process()
	TEST_ASSERT_EQUAL(node.next_growth_check, weed.last_expand, "Узел должен ждать ближайшего роста")
	node.process()
	TEST_ASSERT_EQUAL(weed.expansions, 0, "Ожидание не должно ускорять рост")
	sleep(0.1 SECONDS)
	node.process()
	TEST_ASSERT_EQUAL(weed.expansions, 1, "Наступивший срок роста пропущен")
	var/obj/structure/alien/weeds/growth_test/added = allocate(/obj/structure/alien/weeds/growth_test, near)
	added.last_expand = 0
	node.process()
	TEST_ASSERT_EQUAL(added.expansions, 1, "Новые weeds должны сбросить ожидание")
	var/obj/structure/alien/weeds/growth_test/moved = allocate(/obj/structure/alien/weeds/growth_test, far)
	moved.last_expand = 0
	node.process()
	TEST_ASSERT_EQUAL(moved.expansions, 0, "Weeds вне радиуса не должны расти")
	moved.forceMove(near)
	node.process()
	TEST_ASSERT_EQUAL(moved.expansions, 1, "Перемещение weeds должно сбросить ожидание")
	var/obj/structure/alien/weeds/growth_test/distant = allocate(/obj/structure/alien/weeds/growth_test, far)
	distant.last_expand = 0
	node.process()
	node.node_range = 3
	node.process()
	TEST_ASSERT_EQUAL(distant.expansions, 1, "Расширение радиуса должно сбросить ожидание")
	node.node_range = 1
	node.process()
	distant.last_expand = 0
	node.forceMove(far)
	node.process()
	TEST_ASSERT_EQUAL(distant.expansions, 2, "Перемещение узла должно сбросить ожидание")

/// Незавершённый обход переживает удаление weeds и согласуется с соседним узлом.
/datum/unit_test/weeds_growth_pending_sweep/Run()
	var/obj/structure/alien/weeds/node/growth_test/node = allocate(/obj/structure/alien/weeds/node/growth_test)
	var/obj/structure/alien/weeds/node/growth_test/other = allocate(/obj/structure/alien/weeds/node/growth_test, get_step(node, EAST))
	node.last_expand = INFINITY
	other.last_expand = INFINITY
	var/obj/structure/alien/weeds/growth_test/weed = allocate(/obj/structure/alien/weeds/growth_test)
	var/obj/structure/alien/weeds/growth_test/deleted = allocate(/obj/structure/alien/weeds/growth_test)
	weed.last_expand = 0
	node.growth_sweep_queue = list(weed, deleted)
	qdel(deleted)
	node.process()
	TEST_ASSERT_EQUAL(weed.expansions, 1, "Оставшаяся очередь должна продолжить рост")
	other.process()
	TEST_ASSERT_EQUAL(weed.expansions, 1, "Соседний узел не должен повторять рост до срока")
