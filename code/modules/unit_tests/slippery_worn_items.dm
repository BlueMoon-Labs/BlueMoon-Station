/// Скользкий предмет в кармане не роняет прохожих, надетый роняет только через лежащего носителя.
/datum/unit_test/slippery_worn_items/Run()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	var/saved_gravity = test_area.has_gravity
	test_area.has_gravity = STANDARD_GRAVITY

	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(allocate(/obj/item/clothing/under/color/grey), ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "test premise: без униформы нет карманов")
	var/obj/item/grown/bananapeel/specialpeel/peel = allocate(/obj/item/grown/bananapeel/specialpeel)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(peel, ITEM_SLOT_LPOCKET, disable_warning = TRUE), "test premise: кожура должна лечь в карман")
	wearer.set_resting(TRUE, TRUE)
	TEST_ASSERT_EQUAL(wearer.body_position, LYING_DOWN, "test premise: носитель должен лечь")
	var/mob/living/carbon/human/pocket_passer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	wearer.Crossed(pocket_passer)
	TEST_ASSERT_EQUAL(pocket_passer.body_position, STANDING_UP, "кожура в кармане не должна ронять прохожих")

	wearer.set_resting(FALSE, TRUE)
	TEST_ASSERT_EQUAL(wearer.body_position, STANDING_UP, "test premise: носитель должен встать")
	var/obj/item/clothing/head/hat = allocate(/obj/item/clothing/head/beanie)
	hat.AddComponent(/datum/component/slippery, 80)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD, disable_warning = TRUE), "test premise: шапка должна надеться")
	var/mob/living/carbon/human/standing_passer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	wearer.Crossed(standing_passer)
	TEST_ASSERT_EQUAL(standing_passer.body_position, STANDING_UP, "стоящий в скользкой шапке не должен ронять прохожих")

	wearer.set_resting(TRUE, TRUE)
	var/mob/living/carbon/human/lying_passer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	wearer.Crossed(lying_passer)
	TEST_ASSERT_EQUAL(lying_passer.body_position, LYING_DOWN, "лежащий в скользкой шапке должен ронять перешагнувших")

	test_area.has_gravity = saved_gravity
