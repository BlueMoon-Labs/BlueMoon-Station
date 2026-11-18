/// Рисуется ли лак поверх кистей: при равном слое порядок решает overlays, и кисть, перерисованная позже, закрывала ногти.
/proc/nail_polish_drawn_above_hands(mob/living/carbon/human/painted)
	var/list/drawn = painted.overlays
	var/nails_index = 0
	var/list/hand_indexes = list()
	for(var/i in 1 to length(drawn))
		var/image/overlay = drawn[i]
		if(PLANE_TO_TRUE(overlay.plane) == EMISSIVE_PLANE)
			continue
		if(overlay.icon == 'modular_splurt/icons/mobs/nails.dmi')
			nails_index = i
		else if(overlay.layer == -HANDS_PART_LAYER)
			hand_indexes += i
	if(!nails_index || !length(hand_indexes))
		return FALSE
	var/image/nails = drawn[nails_index]
	for(var/hand_index in hand_indexes)
		var/image/hand = drawn[hand_index]
		if(nails.layer < hand.layer || (nails.layer == hand.layer && nails_index < hand_index))
			return FALSE
	return TRUE

/// Лак переживает переодевание и перерисовку тела и не прячется под кистями.
/datum/unit_test/nail_polish_survives_redraw

/datum/unit_test/nail_polish_survives_redraw/Run()
	var/mob/living/carbon/human/painted = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/nailpolish/red/polish = allocate(/obj/item/nailpolish/red)
	polish.attack(painted, painted)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "test premise: лак должен лечь на ногти")
	TEST_ASSERT(nail_polish_drawn_above_hands(painted), "лак должен быть виден сразу после нанесения")

	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	TEST_ASSERT(painted.equip_to_slot_if_possible(gloves, ITEM_SLOT_GLOVES, disable_warning = TRUE), "test premise: перчатки должны надеться")
	TEST_ASSERT(painted.dropItemToGround(gloves), "test premise: перчатки должны сняться")
	TEST_ASSERT(painted.equip_to_slot_if_possible(allocate(/obj/item/clothing/under/color/grey), ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "test premise: униформа должна надеться")
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "переодевание не должно снимать лак")
	TEST_ASSERT_EQUAL(painted.nail_color, "red", "переодевание не должно менять цвет лака")

	painted.icon_render_key = null
	painted.update_body_parts()
	TEST_ASSERT(nail_polish_drawn_above_hands(painted), "перерисованные кисти не должны закрывать лак")

	painted.regenerate_icons()
	TEST_ASSERT(nail_polish_drawn_above_hands(painted), "полная перерисовка не должна прятать лак под кистями")

/// Душ, пена и чистящие средства лак не трогают; мыло по руке и ацетон снимают.
/datum/unit_test/nail_polish_removal

/datum/unit_test/nail_polish_removal/Run()
	var/mob/living/carbon/human/painted = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(painted.equip_to_slot_if_possible(allocate(/obj/item/clothing/under/color/grey), ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "test premise: униформа должна надеться")
	var/obj/item/nailpolish/blue/polish = allocate(/obj/item/nailpolish/blue)
	polish.attack(painted, painted)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "test premise: лак должен лечь на ногти")

	var/obj/machinery/shower/shower = allocate(/obj/machinery/shower, run_loc_floor_bottom_left)
	shower.wash_mob(painted)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "душ не должен смывать лак")

	var/datum/reagents/cleaner = new(100)
	cleaner.add_reagent(/datum/reagent/space_cleaner, 30)
	cleaner.reaction(painted, TOUCH)
	cleaner.reaction(painted, VAPOR)
	qdel(cleaner)
	SEND_SIGNAL(painted, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_STRONG)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "чистящая пена не должна смывать лак")

	var/obj/item/nailpolish/red/other_polish = allocate(/obj/item/nailpolish/red)
	other_polish.attack(painted, painted)
	TEST_ASSERT_EQUAL(painted.nail_color, "blue", "поверх старого лака новый не наносится")

	var/obj/item/soap/soap = allocate(/obj/item/soap)
	painted.zone_selected = BODY_ZONE_CHEST
	soap.clean_human(painted, painted)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "мыло по груди не должно снимать лак")

	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	TEST_ASSERT(painted.equip_to_slot_if_possible(gloves, ITEM_SLOT_GLOVES, disable_warning = TRUE), "test premise: перчатки должны надеться")
	painted.zone_selected = BODY_ZONE_L_ARM
	TEST_ASSERT(!soap.clean_human(painted, painted), "через перчатки ногти не отмыть")
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "мыло через перчатки не должно снимать лак")
	TEST_ASSERT(painted.dropItemToGround(gloves), "test premise: перчатки должны сняться")

	TEST_ASSERT(soap.clean_human(painted, painted), "мыло по руке под рукавом должно отмыть ногти")
	TEST_ASSERT_NULL(painted.nail_style, "мыло по руке должно снимать лак")

	polish.attack(painted, painted)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "test premise: после мыла лак наносится заново")
	var/datum/reagents/remover = new(100)
	remover.add_reagent(/datum/reagent/acetone, NAIL_POLISH_ACETONE_VOLUME)
	remover.reaction(painted, TOUCH)
	qdel(remover)
	TEST_ASSERT_NULL(painted.nail_style, "плеснутый на руки ацетон должен растворить лак")

/proc/nail_polish_overlay_drawn(mob/living/carbon/human/painted)
	for(var/image/overlay as anything in painted.overlays)
		if(overlay.icon == 'modular_splurt/icons/mobs/nails.dmi' && PLANE_TO_TRUE(overlay.plane) != EMISSIVE_PLANE)
			return TRUE
	return FALSE

/// Вещи в карманах не закрывают ни ногти, ни другие части тела.
/datum/unit_test/nail_polish_pocket_items_do_not_cover

/datum/unit_test/nail_polish_pocket_items_do_not_cover/Run()
	var/mob/living/carbon/human/painted = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(painted.equip_to_slot_if_possible(allocate(/obj/item/clothing/under/color/grey), ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "test premise: униформа должна надеться")
	TEST_ASSERT(painted.equip_to_slot_if_possible(allocate(/obj/item/clothing/gloves/color/black), ITEM_SLOT_LPOCKET, disable_warning = TRUE), "test premise: перчатки должны лечь в карман")
	TEST_ASSERT(painted.equip_to_slot_if_possible(allocate(/obj/item/clothing/mask/surgical), ITEM_SLOT_RPOCKET, disable_warning = TRUE), "test premise: маска должна лечь в карман")

	var/obj/item/nailpolish/red/polish = allocate(/obj/item/nailpolish/red)
	polish.attack(painted, painted)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "перчатки в кармане не должны мешать красить ногти")

	var/obj/item/soap/soap = allocate(/obj/item/soap)
	painted.zone_selected = BODY_ZONE_R_ARM
	TEST_ASSERT(soap.clean_human(painted, painted), "перчатки в кармане не должны мешать оттирать лак")
	TEST_ASSERT_NULL(painted.nail_style, "мыло должно снять лак, когда перчатки лежат в кармане")

	polish.attack(painted, painted)
	var/datum/reagents/remover = new(100)
	remover.add_reagent(/datum/reagent/acetone, NAIL_POLISH_ACETONE_VOLUME)
	remover.reaction(painted, TOUCH)
	qdel(remover)
	TEST_ASSERT_NULL(painted.nail_style, "ацетон должен снять лак, когда перчатки лежат в кармане")

	painted.zone_selected = BODY_ZONE_HEAD
	TEST_ASSERT(soap.clean_human(painted, painted), "маска в кармане не должна закрывать голову от мыла")

/// Перчатки, надетые посреди мытья руки, закрывают ногти: лак остаётся.
/datum/unit_test/nail_polish_gloves_on_mid_scrub

/datum/unit_test/nail_polish_gloves_on_mid_scrub/Run()
	var/mob/living/carbon/human/painted = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/nailpolish/red/polish = allocate(/obj/item/nailpolish/red)
	polish.attack(painted, painted)
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "test premise: лак должен лечь на ногти")
	var/obj/item/bodypart/arm = painted.get_bodypart(BODY_ZONE_L_ARM)
	arm.writtentext = "метка"

	var/obj/item/soap/soap = allocate(/obj/item/soap)
	painted.zone_selected = BODY_ZONE_L_ARM
	INVOKE_ASYNC(soap, TYPE_PROC_REF(/obj/item/soap, clean_human), painted, painted)
	TEST_ASSERT(LAZYLEN(painted.do_afters), "test premise: мытьё руки должно начаться")
	TEST_ASSERT(painted.equip_to_slot_if_possible(allocate(/obj/item/clothing/gloves/color/black), ITEM_SLOT_GLOVES, disable_warning = TRUE), "test premise: перчатки должны надеться")
	var/deadline = world.time + NAIL_POLISH_SCRUB_TIME * 3
	UNTIL(!LAZYLEN(painted.do_afters) || world.time > deadline)
	TEST_ASSERT_EQUAL(arm.writtentext, "", "test premise: мытьё руки должно завершиться")
	TEST_ASSERT_EQUAL(painted.nail_style, "nails", "мыло не должно оттирать лак сквозь надетые по ходу перчатки")

/// Без рук ногтей нет: лак не наносится и не рисуется.
/datum/unit_test/nail_polish_needs_arms

/datum/unit_test/nail_polish_needs_arms/Run()
	var/mob/living/carbon/human/armless = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	for(var/zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		var/obj/item/bodypart/arm = armless.get_bodypart(zone)
		arm.drop_limb()
		qdel(arm)
	var/obj/item/nailpolish/red/polish = allocate(/obj/item/nailpolish/red)
	polish.attack(armless, armless)
	TEST_ASSERT_NULL(armless.nail_style, "без рук лак не должен наноситься")

	var/mob/living/carbon/human/painted = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	polish.attack(painted, painted)
	TEST_ASSERT(nail_polish_overlay_drawn(painted), "test premise: лак должен быть виден")
	var/obj/item/bodypart/left_arm = painted.get_bodypart(BODY_ZONE_L_ARM)
	left_arm.drop_limb()
	qdel(left_arm)
	TEST_ASSERT(nail_polish_overlay_drawn(painted), "с одной рукой лак должен остаться виден")
	var/obj/item/bodypart/right_arm = painted.get_bodypart(BODY_ZONE_R_ARM)
	right_arm.drop_limb()
	qdel(right_arm)
	TEST_ASSERT(!nail_polish_overlay_drawn(painted), "без обеих рук лак не должен рисоваться")
