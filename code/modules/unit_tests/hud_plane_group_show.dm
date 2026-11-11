/// Новый худ строит стопку плоскостей, но показывает её только show_hud(): иначе вход в моба показывал её клиенту дважды.
/datum/unit_test/hud_plane_group_shown_by_show_hud/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(owner)
	owner.set_hud_used(hud)
	var/datum/plane_master_group/group = hud.master_groups[PLANE_GROUP_MAIN]
	TEST_ASSERT_NOTNULL(group, "У худа нет основной стопки")
	TEST_ASSERT(!group.shown, "Новый худ показал стопку до show_hud()")
	TEST_ASSERT(length(group.plane_masters), "Новый худ не построил плоскости")
	for(var/plane_key in group.plane_masters)
		var/atom/movable/screen/plane_master/plane = group.plane_masters[plane_key]
		TEST_ASSERT_EQUAL(plane.get_mob(), owner, "Мастер [plane.type] не привязан к худу: Destroy() не снимет его с экрана")

	hud.plane_masters_update()
	TEST_ASSERT(group.shown, "show_hud() не показал стопку")

	var/list/levels = multiz_ai_floor_test_levels()
	owner.abstract_move(locate(10, 10, levels[2]))
	TEST_ASSERT(group.built_depth >= GET_LOWEST_STACK_OFFSET(levels[2]), "Переход в связку не достроил этажи под глазом")
	for(var/plane_key in group.plane_masters)
		var/atom/movable/screen/plane_master/plane = group.plane_masters[plane_key]
		TEST_ASSERT_EQUAL(plane.get_mob(), owner, "Достроенный мастер [plane.type] #[plane.offset] не привязан к худу")
	owner.abstract_move(run_loc_floor_bottom_left)
