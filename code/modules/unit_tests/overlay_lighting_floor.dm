/// Маска оверлейного света лежит на плоскости своего этажа и переезжает вместе с источником, в том числе в руках.
/datum/unit_test/overlay_light_mask_follows_floor

/datum/unit_test/overlay_light_mask_follows_floor/Run()
	var/turf/lower_turf = multiz_test_lower_turf()
	if(!lower_turf)
		var/datum/space_level/lower = SSmapping.add_new_zlevel("Тест оверлейного света: нижний этаж", list())
		var/datum/space_level/upper = SSmapping.add_new_zlevel("Тест оверлейного света: верхний этаж", list())
		var/datum/map_template/stack = new
		stack.link_template_stack(list(lower, upper))
		qdel(stack)
		lower_turf = locate(TRANSITIONEDGE + 2, TRANSITIONEDGE + 2, lower.z_value)
	TEST_ASSERT_NOTNULL(lower_turf, "Для проверки нужен нижний этаж связки")
	TEST_ASSERT_NOTEQUAL(GET_Z_PLANE_OFFSET(lower_turf.z), GET_Z_PLANE_OFFSET(run_loc_floor_bottom_left.z), "Этажи проверки обязаны различаться смещением")

	var/obj/item/flashlight/lamp/lamp = allocate(/obj/item/flashlight/lamp, run_loc_floor_bottom_left)
	var/datum/component/overlay_lighting/lamp_light = lamp.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT_NOTNULL(lamp_light, "У лампы нет оверлейного света")

	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/flashlight/held = allocate(/obj/item/flashlight)
	holder.put_in_hands(held)
	held.on = TRUE
	held.update_brightness()
	var/datum/component/overlay_lighting/held_light = held.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT_NOTNULL(held_light, "У фонаря нет оверлейного света")
	TEST_ASSERT_NOTNULL(held_light.cone, "У фонаря нет конуса")

	for(var/turf/destination as anything in list(lower_turf, run_loc_floor_bottom_left))
		var/floor_offset = GET_Z_PLANE_OFFSET(destination.z)
		lamp.forceMove(destination)
		holder.forceMove(destination)
		check_mask_floor(lamp_light.visible_mask, floor_offset, "маска лампы")
		check_mask_floor(held_light.visible_mask, floor_offset, "маска фонаря в руках")
		check_mask_floor(held_light.cone, floor_offset, "конус фонаря в руках")
		check_masks_shown(lamp, floor_offset, 1)
		check_masks_shown(holder, floor_offset, 2)

/datum/unit_test/overlay_light_mask_follows_floor/proc/check_mask_floor(image/mask, floor_offset, what)
	TEST_ASSERT_EQUAL(PLANE_TO_TRUE(mask.plane), O_LIGHTING_VISUAL_PLANE, "[what] не на плоскости оверлейного света")
	TEST_ASSERT_EQUAL(PLANE_TO_OFFSET(mask.plane), floor_offset, "[what] лежит на плоскости этажа [PLANE_TO_OFFSET(mask.plane)], а источник на этаже [floor_offset]")

/// На держателе ровно wanted масок света, и все на плоскости этажа floor_offset.
/datum/unit_test/overlay_light_mask_follows_floor/proc/check_masks_shown(atom/movable/holder, floor_offset, wanted)
	var/shown = 0
	for(var/mutable_appearance/underlay as anything in holder.underlays)
		if(PLANE_TO_TRUE(underlay.plane) != O_LIGHTING_VISUAL_PLANE)
			continue
		TEST_ASSERT_EQUAL(PLANE_TO_OFFSET(underlay.plane), floor_offset, "На [holder] висит маска света с этажа [PLANE_TO_OFFSET(underlay.plane)]")
		shown++
	TEST_ASSERT_EQUAL(shown, wanted, "На [holder] показано [shown] масок света вместо [wanted]")

/// Маски этажа высветляют освещение своего этажа: в плитах через реле, без плит через фильтр с таргетом своего этажа.
/datum/unit_test/overlay_light_plane_per_floor/Run()
	for(var/group_type in list(/datum/plane_master_group/main, /datum/plane_master_group/popup))
		var/datum/plane_master_group/group = allocate(group_type, "unit-test-overlay-light")
		if(group.built_depth < 1)
			group.build_plane_masters(group.built_depth + 1, 1)
		for(var/floor_offset in 0 to 1)
			var/atom/movable/screen/plane_master/o_light = group.plane_masters["[GET_NEW_PLANE(O_LIGHTING_VISUAL_PLANE, floor_offset)]"]
			var/atom/movable/screen/plane_master/lighting = group.plane_masters["[GET_NEW_PLANE(LIGHTING_PLANE, floor_offset)]"]
			TEST_ASSERT_NOTNULL(o_light, "У этажа [floor_offset] нет плоскости оверлейного света")
			TEST_ASSERT_NOTNULL(lighting, "У этажа [floor_offset] нет плоскости освещения")
			var/list/cut = lighting.filter_data?["object_lighting"]
			if(!group.use_render_plates)
				TEST_ASSERT(!length(o_light.relays), "Без плит оверлейный свет рисуется сам")
				TEST_ASSERT_EQUAL(cut?["render_source"], o_light.render_target, "Освещение этажа [floor_offset] режется чужим оверлейным светом")
				continue
			TEST_ASSERT_NULL(cut, "В плитах освещение этажа [floor_offset] не должно резаться фильтром")
			var/atom/movable/screen/render_plane_relay/brighten
			var/atom/movable/screen/render_plane_relay/tint
			for(var/atom/movable/screen/render_plane_relay/relay as anything in o_light.relays)
				TEST_ASSERT_EQUAL(relay.plane, lighting.plane, "Оверлейный свет этажа [floor_offset] сдаётся не в освещение своего этажа")
				TEST_ASSERT_EQUAL(relay.render_source, o_light.render_target, "Реле оверлейного света читает чужую картинку")
				if(relay.blend_mode == BLEND_OVERLAY)
					brighten = relay
				else if(relay.blend_mode == BLEND_MULTIPLY)
					tint = relay
			TEST_ASSERT_NOTNULL(brighten, "У оверлейного света этажа [floor_offset] нет реле высветления")
			TEST_ASSERT_NOTNULL(tint, "У оверлейного света этажа [floor_offset] нет реле цвета")
			TEST_ASSERT(brighten.layer < tint.layer, "Высветление обязано лечь раньше умножения на цвет")
