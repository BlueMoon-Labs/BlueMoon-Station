/// Индуктор не видел энергомагазинов: у магазина нет get_cell(), зарядник же досоздаёт выстрелы.
/datum/unit_test/combat_inducer_recharges_laser_magazine/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/inducer/sci/combat/inducer = allocate(/obj/item/inducer/sci/combat)
	var/obj/item/ammo_box/magazine/recharge/vanguard/magazine = allocate(/obj/item/ammo_box/magazine/recharge/vanguard, get_step(user, EAST))
	QDEL_LIST(magazine.stored_ammo)
	user.put_in_active_hand(inducer)
	var/charge_before = inducer.cell.charge

	inducer.melee_attack_chain(user, magazine)

	TEST_ASSERT_EQUAL(magazine.stored_ammo.len, magazine.max_ammo, "боевой индуктор обязан зарядить энергомагазин до полного")
	TEST_ASSERT_EQUAL(round(charge_before - inducer.cell.charge, 1), magazine.max_ammo * magazine.charge_per_round, "заряд выстрелов берётся из батареи индуктора")

/datum/unit_test/combat_inducer_recharges_magazine_in_gun/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/inducer/sci/combat/inducer = allocate(/obj/item/inducer/sci/combat)
	var/obj/item/gun/ballistic/automatic/laser/vanguard/gun = allocate(/obj/item/gun/ballistic/automatic/laser/vanguard, get_step(user, EAST))
	QDEL_LIST(gun.magazine.stored_ammo)
	QDEL_NULL(gun.chambered)
	TEST_ASSERT(!gun.can_shoot(), "test premise: разряженная пушка не стреляет")
	user.put_in_active_hand(inducer)

	inducer.melee_attack_chain(user, gun)

	TEST_ASSERT(gun.can_shoot(), "заряженная индуктором пушка обязана стрелять")
	TEST_ASSERT_NOTNULL(gun.chambered, "после зарядки выстрел должен встать в патронник")

/// Зарядка оружия - особенность боевого индуктора, инженерный энергомагазины не берёт, как и энергопушки.
/datum/unit_test/engineer_inducer_refuses_laser_magazine/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/inducer/inducer = allocate(/obj/item/inducer)
	var/obj/item/ammo_box/magazine/recharge/vanguard/magazine = allocate(/obj/item/ammo_box/magazine/recharge/vanguard, get_step(user, EAST))
	QDEL_LIST(magazine.stored_ammo)
	user.put_in_active_hand(inducer)

	inducer.melee_attack_chain(user, magazine)

	TEST_ASSERT_EQUAL(magazine.stored_ammo.len, 0, "инженерный индуктор не заряжает оружие")
