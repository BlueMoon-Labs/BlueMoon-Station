/// Врождённый такл вокса не сильнее обычных перчаток-хватателей: без монстр-такла с агрессивным захватом.
/datum/unit_test/vox_tackle_not_above_gripper_gloves/Run()
	var/mob/living/carbon/human/vox = allocate(/mob/living/carbon/human)
	vox.set_species(/datum/species/mammal/vox)
	var/datum/component/tackler/tackle = vox.GetComponent(/datum/component/tackler)
	TEST_ASSERT_NOTNULL(tackle, "Вокс потерял врождённый такл")

	var/obj/item/clothing/gloves/tackler/gloves = /obj/item/clothing/gloves/tackler
	TEST_ASSERT(tackle.skill_mod <= initial(gloves.skill_mod), "Такл вокса точнее перчаток-хватателей: [tackle.skill_mod] > [initial(gloves.skill_mod)]")
	TEST_ASSERT(tackle.range <= initial(gloves.tackle_range), "Такл вокса дальше перчаток-хватателей: [tackle.range] > [initial(gloves.tackle_range)]")
	TEST_ASSERT(tackle.stamina_cost >= initial(gloves.tackle_stam_cost), "Такл вокса дешевле перчаток-хватателей: [tackle.stamina_cost] < [initial(gloves.tackle_stam_cost)]")

	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	target.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(target), ITEM_SLOT_ICLOTHING)
	var/best_roll = -INFINITY
	for(var/i in 1 to 100)
		best_roll = max(best_roll, tackle.rollTackle(target))
	TEST_ASSERT(best_roll < 5, "Вокс без снаряжения выбрасывает монстр-такл (бросок [best_roll]): мгновенный агрессивный захват")

/// Удар вокса валит не чаще человеческого: роняет только удар с максимальным уроном.
/datum/unit_test/vox_punch_knockdown_threshold/Run()
	var/mob/living/carbon/human/vox = allocate(/mob/living/carbon/human)
	vox.set_species(/datum/species/mammal/vox)
	var/datum/species/species = vox.dna.species
	TEST_ASSERT(species.punchstunthreshold >= species.punchdamagehigh, "Почти любой удар вокса валит: порог [species.punchstunthreshold] при уроне [species.punchdamagelow]-[species.punchdamagehigh]")
