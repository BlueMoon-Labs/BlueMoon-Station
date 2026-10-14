/// Усиленный настил встаёт в baseturfs прямо над обычным: снятый пол открывает его, а под ним остаётся обычный настил.
/datum/unit_test/reinforced_plating_stacks_over_plating

/datum/unit_test/reinforced_plating_stacks_over_plating/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/old_type = test_turf.type
	var/list/old_baseturfs = islist(test_turf.baseturfs) ? test_turf.baseturfs.Copy() : test_turf.baseturfs

	test_turf = test_turf.ChangeTurf(/turf/open/floor/plasteel, list(/turf/open/space, /turf/open/floor/plating))
	test_turf.stack_ontop_of_baseturf(/turf/open/floor/plating, /turf/open/floor/plating/reinforced)
	test_turf = test_turf.ScrapeAway()
	var/revealed_type = test_turf.type
	var/denies_rcd = FALSE
	if(istype(test_turf, /turf/open/floor/plating/reinforced))
		var/obj/item/construction/rcd/rcd = allocate(/obj/item/construction/rcd)
		rcd.mode = RCD_DECONSTRUCT
		denies_rcd = !test_turf.rcd_vals(null, rcd)
	test_turf = test_turf.ScrapeAway()
	var/below_type = test_turf.type

	test_turf.ChangeTurf(old_type, old_baseturfs)

	TEST_ASSERT_EQUAL(revealed_type, /turf/open/floor/plating/reinforced, "Под снятым полом обязан быть усиленный настил")
	TEST_ASSERT(denies_rcd, "РЦД не должен разбирать усиленный настил")
	TEST_ASSERT_EQUAL(below_type, /turf/open/floor/plating, "Под усиленным настилом обязан остаться обычный настил")
