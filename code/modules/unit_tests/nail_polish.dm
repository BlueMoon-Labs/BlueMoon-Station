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
