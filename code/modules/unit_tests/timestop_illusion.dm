/// Копия для застывшего мира повторяет внешний вид и место атома, невидимые атомы пропускаются
/datum/unit_test/timestop_illusion_images/Run()
	var/obj/effect/timestop/field = allocate(/obj/effect/timestop, run_loc_floor_bottom_left, 1, 10 SECONDS, null, FALSE)
	field.timestop()
	var/datum/proximity_monitor/advanced/timestop/chronofield = field.chronofield
	TEST_ASSERT_NOTNULL(chronofield, "Sanity: таймстоп обязан построить хронополе")

	var/obj/item/crowbar/visible_item = allocate(/obj/item/crowbar, run_loc_floor_top_right)
	var/obj/item/crowbar/hidden_item = allocate(/obj/item/crowbar, run_loc_floor_top_right)
	hidden_item.invisibility = INVISIBILITY_MAXIMUM

	var/list/illusion = chronofield.build_illusion_images(list(visible_item, hidden_item))
	TEST_ASSERT_EQUAL(length(illusion), 1, "Невидимый атом не должен попадать в иллюзию")
	var/image/frozen_copy = illusion[1]
	TEST_ASSERT_EQUAL(frozen_copy.loc, visible_item.loc, "Копия должна стоять там же, где атом")
	TEST_ASSERT_EQUAL(frozen_copy.icon, visible_item.icon, "Копия должна брать иконку атома, а не плоский снимок")
	TEST_ASSERT_EQUAL(frozen_copy.icon_state, visible_item.icon_state, "Копия должна повторять icon_state атома")
	TEST_ASSERT_EQUAL(frozen_copy.layer, visible_item.layer, "Копия должна стоять на слое атома")
