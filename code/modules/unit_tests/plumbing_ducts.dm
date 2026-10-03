/// Слияние двух сетей труб оставляет трубы обеих в одной живой сети.
/datum/unit_test/ductnet_assimilate_keeps_ducts

/datum/unit_test/ductnet_assimilate_keeps_ducts/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/machinery/duct/first = allocate(/obj/machinery/duct, origin)
	var/obj/machinery/duct/second = allocate(/obj/machinery/duct, locate(origin.x + 2, origin.y, origin.z))
	first.create_duct()
	second.create_duct()

	var/datum/ductnet/survivor = first.duct
	var/datum/ductnet/absorbed = second.duct
	survivor.assimilate(absorbed)

	TEST_ASSERT(!QDELETED(survivor), "Поглощающая сеть не должна удаляться")
	TEST_ASSERT(QDELETED(absorbed), "Поглощённая сеть обязана удалиться")
	TEST_ASSERT_EQUAL(first.duct, survivor, "Своя труба обязана остаться в поглощающей сети")
	TEST_ASSERT_EQUAL(second.duct, survivor, "Чужая труба обязана перейти в поглощающую сеть")

/// Кольцо из четырёх труб собирается в одну сеть, а не пересоединяется бесконечно.
/datum/unit_test/duct_ring_forms_one_net

/datum/unit_test/duct_ring_forms_one_net/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/list/obj/machinery/duct/ring = list()
	for(var/list/offset in list(list(0, 2), list(1, 2), list(1, 3), list(0, 3)))
		ring += allocate(/obj/machinery/duct, locate(origin.x + offset[1], origin.y + offset[2], origin.z))

	var/datum/ductnet/net = ring[1].duct
	TEST_ASSERT_NOTNULL(net, "Труба кольца обязана быть в сети")
	for(var/obj/machinery/duct/piece as anything in ring)
		TEST_ASSERT_EQUAL(piece.duct, net, "Все трубы кольца обязаны быть в одной сети")
	TEST_ASSERT_EQUAL(length(net.ducts), length(ring), "В сети кольца ровно его трубы")
