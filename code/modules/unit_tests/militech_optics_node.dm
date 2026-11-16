/// Militech optical suite — боевой имплант: живёт в боевой ноде и печатается только со взломанного протолата.
/datum/unit_test/militech_optics_node

/datum/unit_test/militech_optics_node/Run()
	var/datum/techweb_node/adv_node = SSresearch.techweb_nodes["adv_cyber_implants"]
	TEST_ASSERT_NOTNULL(adv_node, "Нода adv_cyber_implants должна существовать")
	TEST_ASSERT(!("ci-militech-optics" in adv_node.design_ids), "Militech optics не должен быть в медицинской ноде adv_cyber_implants")
	TEST_ASSERT("ci-kiroshi-optics" in adv_node.design_ids, "Гражданская оптика Kiroshi должна остаться в adv_cyber_implants")

	var/datum/techweb_node/combat_node = SSresearch.techweb_nodes["combat_cyber_implants"]
	TEST_ASSERT_NOTNULL(combat_node, "Нода combat_cyber_implants должна существовать")
	TEST_ASSERT("ci-militech-optics" in combat_node.design_ids, "Militech optics должен быть в боевой ноде combat_cyber_implants")

	var/datum/design/militech = SSresearch.techweb_designs["ci-militech-optics"]
	TEST_ASSERT_NOTNULL(militech, "Дизайн ci-militech-optics должен существовать")
	TEST_ASSERT(militech.hacked_only, "Militech optics должен печататься только со взломанного протолата")
