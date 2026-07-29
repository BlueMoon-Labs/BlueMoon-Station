// ===== Канал AI_TARGETS спатиал-грида + cell_tracker =====
//
// Проверяют членство живых мобов в новом канале (Initialize/смерть/оживление/
// перемещение/контейнер/qdel) и оконную математику /datum/cell_tracker.

///Живой моб при создании попадает в канал своей ячейки, и его видно поиском
/datum/unit_test/ai_targets_membership/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)

	var/datum/spatial_grid_cell/cell = SSspatial_grid.get_cell_of(subject)
	TEST_ASSERT_NOTNULL(cell, "Subject has no grid cell")
	TEST_ASSERT(subject in cell.ai_target_contents, "A live mob must be in its cell's ai_target_contents")

	var/list/found = SSspatial_grid.orthogonal_range_search(subject, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, 9)
	TEST_ASSERT(subject in found, "orthogonal_range_search must return the live mob on the AI_TARGETS channel")

///Смерть убирает из канала, оживление возвращает
/datum/unit_test/ai_targets_death_revive/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	var/datum/spatial_grid_cell/cell = SSspatial_grid.get_cell_of(subject)

	subject.death()
	TEST_ASSERT(!(subject in cell.ai_target_contents), "A dead mob must leave ai_target_contents")

	subject.revive(TRUE, TRUE)
	TEST_ASSERT_EQUAL(subject.stat, CONSCIOUS, "Sanity: revive must bring the mob back")
	TEST_ASSERT(subject in cell.ai_target_contents, "A revived mob must re-enter ai_target_contents")

///Перемещение через границу ячеек перекладывает запись
/datum/unit_test/ai_targets_move_updates_cell/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	var/datum/spatial_grid_cell/home_cell = SSspatial_grid.get_cell_of(subject)

	var/turf/far_turf = locate(1, 1, run_loc_floor_bottom_left.z)
	subject.forceMove(far_turf)
	var/datum/spatial_grid_cell/far_cell = SSspatial_grid.get_cell_of(subject)

	if(far_cell == home_cell) //резервация у самого угла карты - двигаем в другой угол
		far_turf = locate(world.maxx - 1, world.maxy - 1, run_loc_floor_bottom_left.z)
		subject.forceMove(far_turf)
		far_cell = SSspatial_grid.get_cell_of(subject)

	TEST_ASSERT(far_cell != home_cell, "Sanity: the far turf must be in a different grid cell")
	TEST_ASSERT(!(subject in home_cell.ai_target_contents), "The old cell must lose the moved mob")
	TEST_ASSERT(subject in far_cell.ai_target_contents, "The new cell must gain the moved mob")

	subject.forceMove(run_loc_floor_bottom_left)

///Моб в контейнере переезжает по ячейкам вместе с контейнером
/datum/unit_test/ai_targets_container_transfer/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	var/obj/structure/closet/box = allocate(/obj/structure/closet)

	subject.forceMove(box)
	var/datum/spatial_grid_cell/home_cell = SSspatial_grid.get_cell_of(subject)
	TEST_ASSERT(subject in home_cell.ai_target_contents, "A mob inside a closet must stay in the closet turf's cell")

	var/turf/far_turf = locate(1, 1, run_loc_floor_bottom_left.z)
	var/datum/spatial_grid_cell/far_cell = SSspatial_grid.get_cell_of(far_turf)
	if(far_cell == home_cell)
		far_turf = locate(world.maxx - 1, world.maxy - 1, run_loc_floor_bottom_left.z)
		far_cell = SSspatial_grid.get_cell_of(far_turf)
	TEST_ASSERT(far_cell != home_cell, "Sanity: need two distinct cells")

	box.forceMove(far_turf)
	TEST_ASSERT(!(subject in home_cell.ai_target_contents), "The old cell must lose the contained mob when the closet moves away")
	TEST_ASSERT(subject in far_cell.ai_target_contents, "The new cell must gain the contained mob with the closet")

	subject.forceMove(run_loc_floor_bottom_left)
	box.forceMove(run_loc_floor_bottom_left)

///qdel не оставляет висящих ссылок в ячейках
/datum/unit_test/ai_targets_qdel_no_hanging_refs/Run()
	var/mob/living/carbon/human/subject = new(run_loc_floor_bottom_left)
	var/datum/spatial_grid_cell/cell = SSspatial_grid.get_cell_of(subject)
	TEST_ASSERT(subject in cell.ai_target_contents, "Sanity: the mob must be registered before qdel")

	qdel(subject)
	var/list/hanging = SSspatial_grid.find_hanging_cell_refs_for_movable(subject, FALSE)
	TEST_ASSERT_EQUAL(length(hanging), 0, "A qdeleted mob must not linger in any grid cell ([length(hanging)] cells still hold it)")

///Destroy must remove the registered cell even if legacy code bypassed Moved().
/datum/unit_test/ai_targets_qdel_repairs_direct_loc_move/Run()
	var/mob/living/simple_animal/hostile/syndicate/ranged/smg/subject = new(run_loc_floor_bottom_left)
	var/datum/spatial_grid_cell/home_cell = SSspatial_grid.get_cell_of(subject)
	TEST_ASSERT(subject in home_cell.hearing_contents, "Sanity: exact leaked hostile must be registered for hearing")
	TEST_ASSERT(subject in home_cell.ai_target_contents, "Sanity: exact leaked hostile must be registered as an AI target")

	var/turf/far_turf = locate(world.maxx - 1, world.maxy - 1, run_loc_floor_bottom_left.z)
	TEST_ASSERT(SSspatial_grid.get_cell_of(far_turf) != home_cell, "Sanity: direct move needs a different cell")
	// Reproduce legacy/direct loc writes which change BYOND contents but skip Moved().
	subject.loc = far_turf
	qdel(subject)

	var/list/hanging = SSspatial_grid.find_hanging_cell_refs_for_movable(subject, FALSE)
	TEST_ASSERT_EQUAL(length(hanging), 0, "Destroy must clean the cell it registered, not only the current loc cell")

///Оконная математика cell_tracker: вход, гистерезис, выход
/datum/unit_test/ai_cell_tracker_window/Run()
	var/datum/cell_tracker/tracker = new(9, 9, 2)

	var/list/first_pass = tracker.recalculate_cells(run_loc_floor_bottom_left)
	TEST_ASSERT(length(first_pass[1]) > 0, "First recalculation must return new cells")
	TEST_ASSERT_EQUAL(length(first_pass[2]), 0, "First recalculation must have no old cells")
	TEST_ASSERT_EQUAL(length(tracker.member_cells), length(first_pass[1]), "member_cells must match the first window")

	var/list/second_pass = tracker.recalculate_cells(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(length(second_pass[1]), 0, "Same-center recalculation must add nothing")
	TEST_ASSERT_EQUAL(length(second_pass[2]), 0, "Same-center recalculation must drop nothing")

	var/turf/far_turf = locate(world.maxx - 1, world.maxy - 1, run_loc_floor_bottom_left.z)
	var/list/far_pass = tracker.recalculate_cells(far_turf)
	TEST_ASSERT(length(far_pass[1]) > 0, "A far recalculation must enter new cells")
	TEST_ASSERT(length(far_pass[2]) > 0, "A far recalculation must leave the old cells (outside the outer window)")

	qdel(tracker, TRUE)
