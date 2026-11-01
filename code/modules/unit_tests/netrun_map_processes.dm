/// The overlay publishes role/faction values, not one moving actor copy per viewer.
/datum/unit_test/netrun_map_process_aggregates/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/viewer = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/bot/first = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "redshift_hacker")
	var/mob/camera/netrun_entity/bot/second = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "redshift_hacker")
	var/mob/camera/netrun_entity/bot/recycler = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RECYCLER)
	var/list/entry = scene.node_a.ui_entry(viewer.console)
	var/list/hackers
	var/list/cleaner
	for(var/list/process as anything in entry["processes"])
		if(process["bot_kind"] == "redshift_hacker")
			hackers = process
		if(process["bot_kind"] == NETRUN_BOT_RECYCLER)
			cleaner = process
	TEST_ASSERT_NOTNULL(hackers, "A visible bot role is included in the live overlay")
	TEST_ASSERT_EQUAL(hackers["count"], 2, "Identical role/faction processes aggregate into one marker")
	TEST_ASSERT_EQUAL(hackers["faction"], "redshift", "The summary preserves actual allegiance")
	TEST_ASSERT_EQUAL(hackers["faction_color"], SSnetrun.get_netrun_faction("redshift").color, "Tint comes from the faction definition")
	TEST_ASSERT_NOTNULL(cleaner, "A different role remains a distinct marker")
	TEST_ASSERT_EQUAL(cleaner["faction"], NETRUN_FACTION_STATION, "The maintenance profile has station affiliation")
	TEST_ASSERT_EQUAL(entry["bots"], 3, "Legacy total counters remain available for overflow and older clients")
	qdel(first)
	qdel(second)
	qdel(recycler)
	viewer.leave_node()
	entry = scene.node_a.ui_entry(viewer.console)
	TEST_ASSERT_NULL(entry["processes"], "Empty nodes do not retain departed actors or allocate empty summary arrays")

/// Crowded scenes keep a fixed amount of role data while repeated groups still count.
/datum/unit_test/netrun_map_process_summary_bound/Run()
	var/list/groups
	for(var/index in 1 to 40)
		groups = netrun_map_add_process(groups, "bot", "role-[index]", null, "faction-[index]", "#123456")
	TEST_ASSERT_EQUAL(length(groups), 6, "One node cannot create an unbounded marker payload")
	groups = netrun_map_add_process(groups, "bot", "role-1", null, "faction-1", "#123456")
	var/list/first = groups[groups[1]]
	TEST_ASSERT_EQUAL(first["count"], 2, "Existing groups remain accurate after the distinct-role cap is reached")
