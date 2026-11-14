/// Отказ в посадке не оставляет моба «садящимся»: иначе бросок-захват заблокирован до следующей удачной посадки.
/datum/unit_test/refused_buckle_clears_buckling

/datum/unit_test/refused_buckle_clears_buckling/Run()
	var/obj/structure/chair/chair = allocate(/obj/structure/chair)
	var/mob/living/carbon/human/heavy = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human)
	heavy.mob_weight = MOB_WEIGHT_HEAVY_SUPER

	TEST_ASSERT(!chair.user_buckle_mob(heavy, helper), "Сверхтяжёлого посадили посторонние руки")
	TEST_ASSERT_NULL(heavy.buckling, "После отказа в посадке моб так и остался садящимся")

/// Поднятое забрало HECU выключает ПНВ, опущенное - включает обратно.
/datum/unit_test/hecu_visor_toggles_night_vision

/datum/unit_test/hecu_visor_toggles_night_vision/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	wearer.mock_client = new /datum/client_interface
	var/obj/item/clothing/head/helmet/nvg/hecu/helmet = allocate(/obj/item/clothing/head/helmet/nvg/hecu)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(helmet, ITEM_SLOT_HEAD), "Шлем HECU надет")
	var/dark_down = wearer.see_in_dark
	var/alpha_down = wearer.lighting_alpha
	TEST_ASSERT(alpha_down < LIGHTING_PLANE_ALPHA_VISIBLE, "С опущенным забралом ПНВ не работает")

	helmet.cooldown = -INFINITY
	helmet.attack_self(wearer)
	TEST_ASSERT(helmet.up, "Забрало не поднялось")
	TEST_ASSERT_EQUAL(wearer.lighting_alpha, LIGHTING_PLANE_ALPHA_VISIBLE, "С поднятым забралом ПНВ продолжает работать")

	helmet.cooldown = -INFINITY
	helmet.attack_self(wearer)
	TEST_ASSERT(!helmet.up, "Забрало не опустилось")
	TEST_ASSERT_EQUAL(wearer.see_in_dark, dark_down, "После опускания забрала дальность ночного зрения не вернулась")
	TEST_ASSERT_EQUAL(wearer.lighting_alpha, alpha_down, "После опускания забрала ПНВ не вернулось")
	wearer.mock_client = null
