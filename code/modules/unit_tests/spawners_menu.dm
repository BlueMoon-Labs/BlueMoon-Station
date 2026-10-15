#define SPAWNERS_MENU_TEST_GROUP "unit test spawner group"
#define SPAWNERS_MENU_TEST_NULLS 4

/obj/effect/mob_spawn/human/unit_test_spawners_menu
	job_description = SPAWNERS_MENU_TEST_GROUP
	roundstart = FALSE
	instant = FALSE
	death = FALSE
	uses = -1
	mob_name = "spawners menu probe"

/// Меню спавнеров собирает данные и показывает живой спавнер, когда в группе есть null.
/datum/unit_test/spawners_menu_skips_null_entries

/datum/unit_test/spawners_menu_skips_null_entries/Run()
	var/obj/effect/mob_spawn/human/unit_test_spawners_menu/alive = allocate(/obj/effect/mob_spawn/human/unit_test_spawners_menu, run_loc_floor_top_right)
	var/list/group_spawners = GLOB.mob_spawners[SPAWNERS_MENU_TEST_GROUP]
	for(var/index in 1 to SPAWNERS_MENU_TEST_NULLS)
		group_spawners += null
	TEST_ASSERT_EQUAL(length(GLOB.mob_spawners[SPAWNERS_MENU_TEST_GROUP]), SPAWNERS_MENU_TEST_NULLS + 1, "test premise: the group must hold the live spawner and the null entries")

	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/spawners_menu/menu = new(ghost)
	var/list/data = menu.ui_data(ghost)
	qdel(menu)

	var/list/group
	for(var/list/entry as anything in data["spawners"])
		if(entry["name"] == SPAWNERS_MENU_TEST_GROUP)
			group = entry
	TEST_ASSERT_NOTNULL(group, "the group with a live spawner must stay in the menu")
	TEST_ASSERT_EQUAL(group["amount_left"], 1, "only the live spawner counts")
	TEST_ASSERT_EQUAL(length(group["refs"]), 1, "null entries must not reach the menu")
	TEST_ASSERT_EQUAL(length(GLOB.mob_spawners[SPAWNERS_MENU_TEST_GROUP]), 1, "null entries are pruned from the group")
	TEST_ASSERT(alive in GLOB.mob_spawners[SPAWNERS_MENU_TEST_GROUP], "the live spawner stays registered")

#undef SPAWNERS_MENU_TEST_GROUP
#undef SPAWNERS_MENU_TEST_NULLS
