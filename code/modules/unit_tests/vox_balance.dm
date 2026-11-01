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

	target.drunkenness = 100
	best_roll = -INFINITY
	for(var/i in 1 to 100)
		best_roll = max(best_roll, tackle.rollTackle(target))
	TEST_ASSERT(best_roll < 5, "Вокс выбрасывает монстр-такл по пьяной цели (бросок [best_roll]): мгновенный агрессивный захват")

/// Удар вокса валит не чаще человеческого: роняет только удар с максимальным уроном.
/datum/unit_test/vox_punch_knockdown_threshold/Run()
	var/mob/living/carbon/human/vox = allocate(/mob/living/carbon/human)
	vox.set_species(/datum/species/mammal/vox)
	var/datum/species/species = vox.dna.species
	TEST_ASSERT(species.punchstunthreshold == species.punchdamagehigh, "Валит не только максимальный удар вокса: порог [species.punchstunthreshold] при уроне [species.punchdamagelow]-[species.punchdamagehigh]")

/// Перчатки воксу не надеть, поэтому ток бьёт его слабее человека, но оглушает так же.
/datum/unit_test/vox_shock_resistance/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/vox = allocate(/mob/living/carbon/human)
	vox.set_species(/datum/species/mammal/vox)
	human.electrocute_act(20, "тестовый провод")
	vox.electrocute_act(20, "тестовый провод")
	TEST_ASSERT(vox.getFireLoss() < human.getFireLoss(), "Ток бьёт вокса не слабее человека: [vox.getFireLoss()] против [human.getFireLoss()]")
	TEST_ASSERT(vox.getFireLoss() > 0, "Вокс стал неуязвим к току")
	TEST_ASSERT(vox.IsStun(), "Ток перестал оглушать вокса")

	vox.set_species(/datum/species/human)
	TEST_ASSERT(vox.physiology.siemens_coeff == 1, "Сопротивление току осталось после смены расы: [vox.physiology.siemens_coeff]")

	var/mob/living/carbon/human/species/mammal/vox/spawned = allocate(/mob/living/carbon/human/species/mammal/vox)
	TEST_ASSERT(spawned.physiology.siemens_coeff < 1, "Готовый вокс со спавна без сопротивления току")

/// Вокс из настроек персонажа под ударом шлюза под напряжением: путь, которым раса достаётся игроку.
/datum/unit_test/vox_shock_resistance_from_preferences/Run()
	var/datum/preferences/prefs = new
	prefs.pref_species = new /datum/species/mammal/vox
	var/mob/living/carbon/human/vox = allocate(/mob/living/carbon/human)
	prefs.copy_to(vox, roundstart_checks = FALSE)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/stock_parts/cell/cell = allocate(/obj/item/stock_parts/cell/bluespace)
	cell.charge = 500000
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock)
	electrocute_mob(human, cell, door)
	cell.charge = 500000
	electrocute_mob(vox, cell, door)
	// Урон от батареи 50 +-5: у вокса не больше 33, у человека не меньше 45
	TEST_ASSERT(vox.getFireLoss() < human.getFireLoss(), "Шлюз бьёт вокса из настроек не слабее человека: [vox.getFireLoss()] против [human.getFireLoss()]")
