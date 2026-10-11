/// Предмет в объёмном хранилище наследует плоскость держателя, а при извлечении возвращает свою.
/datum/unit_test/volumetric_storage_item_plane

/datum/unit_test/volumetric_storage_item_plane/Run()
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	var/obj/item/screwdriver/tool = allocate(/obj/item/screwdriver)
	var/world_plane = tool.plane
	var/datum/component/storage/storage = bag.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(storage, "У рюкзака нет компонента хранилища")
	TEST_ASSERT(storage.volumetric_ui(), "Рюкзак должен показываться в объёмном режиме")
	TEST_ASSERT(storage.handle_item_insertion(tool, TRUE), "Отвёртка не влезла в рюкзак")

	var/atom/movable/screen/storage/volumetric_box/center/box = new(null, null, storage, tool)
	box.set_pixel_size(VOLUMETRIC_STORAGE_BOX_ICON_SIZE * 2, null)
	TEST_ASSERT_NOTNULL(box.holder, "Коробка не создала держатель предмета")
	TEST_ASSERT(tool in box.holder.vis_contents, "Предмет не попал в vis_contents держателя")
	TEST_ASSERT(tool.vis_flags & VIS_INHERIT_PLANE, "Предмет в держателе обязан наследовать его плоскость")
	TEST_ASSERT_EQUAL(tool.plane, world_plane, "Показ в хранилище не должен трогать плоскость предмета")

	box.makeItemActive()
	TEST_ASSERT_EQUAL(tool.plane, world_plane, "Подсветка предмета не должна трогать его плоскость")
	TEST_ASSERT_EQUAL(box.holder.plane, VOLUMETRIC_STORAGE_ACTIVE_ITEM_PLANE, "Подсветка должна поднимать держатель")
	box.makeItemInactive()
	TEST_ASSERT_EQUAL(box.holder.plane, VOLUMETRIC_STORAGE_ITEM_PLANE, "Снятие подсветки должно опускать держатель")

	box.set_item(null)
	TEST_ASSERT(!(tool in box.holder.vis_contents), "Предмет остался в vis_contents после сброса коробки")
	TEST_ASSERT(!(tool.vis_flags & VIS_INHERIT_PLANE), "Флаг наследования остался после сброса коробки")
	qdel(box)

	box = new(null, null, storage, tool)
	box.set_pixel_size(VOLUMETRIC_STORAGE_BOX_ICON_SIZE * 2, null)
	TEST_ASSERT(tool.vis_flags & VIS_INHERIT_PLANE, "Повторный показ не выставил флаг наследования")
	qdel(box)
	TEST_ASSERT(!(tool.vis_flags & VIS_INHERIT_PLANE), "Флаг наследования остался после удаления коробки")

	storage.remove_from_storage(tool, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(tool.loc, run_loc_floor_bottom_left, "Предмет не вернулся на турф")
	TEST_ASSERT_EQUAL(tool.plane, world_plane, "После извлечения плоскость предмета должна быть плоскостью его этажа")
	TEST_ASSERT(!(tool.vis_flags & VIS_INHERIT_PLANE), "Флаг наследования остался после извлечения")

/// База /obj/effect не наследует плоскость контейнера; подтипы, которые живут в чужих vis_contents из nullspace, наследуют явно.
/datum/unit_test/effect_vis_flags

/datum/unit_test/effect_vis_flags/Run()
	var/obj/effect/base_type = /obj/effect
	TEST_ASSERT(!(initial(base_type.vis_flags) & VIS_INHERIT_PLANE), "/obj/effect не должен наследовать плоскость: содержимое дыры в полу схлопывается на этаж зрителя")
	var/obj/effect/abstract/z_holder/holder_type = /obj/effect/abstract/z_holder
	TEST_ASSERT(!(initial(holder_type.vis_flags) & VIS_INHERIT_PLANE), "Держатель показанного снизу турфа не должен наследовать плоскость")

	var/list/inheriting_types = list(/obj/effect/countdown, /obj/effect/overlay/emote_popup)
	for(var/obj/effect/effect_type as anything in inheriting_types)
		TEST_ASSERT(initial(effect_type.vis_flags) & VIS_INHERIT_PLANE, "[effect_type] рисуется из nullspace в vis_contents носителя и обязан наследовать его плоскость")
