/// Cybersun Sandevistan продаётся в синди-, интекью- и агентском аплинках за 10 ТК.
/datum/unit_test/sandevistan_uplink

/datum/unit_test/sandevistan_uplink/Run()
	var/datum/uplink_item/implants/sandevistan_military/entry = new
	TEST_ASSERT_NOTNULL(entry.item, "У записи Cybersun Sandevistan должен быть предмет")
	TEST_ASSERT_EQUAL(entry.cost, 10, "Cybersun Sandevistan должен стоить 10 ТК")
	TEST_ASSERT(entry.purchasable_from & UPLINK_SYNDICATE, "Cybersun Sandevistan должен продаваться в синди-аплинке")
	TEST_ASSERT(entry.purchasable_from & UPLINK_NUKE_OPS, "Cybersun Sandevistan должен продаваться в аплинке InteQ")
	TEST_ASSERT(entry.purchasable_from & UPLINK_TRAITORS, "Cybersun Sandevistan должен продаваться в агентском аплинке")
	qdel(entry)

/// Активный сандевистан с шансом уклоняет от любого проджектайла; неактивный или отсутствующий — нет.
/datum/unit_test/sandevistan_projectile_dodge

/datum/unit_test/sandevistan_projectile_dodge/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/projectile/projectile = allocate(/obj/item/projectile/bullet)

	// Без импланта уклонения нет.
	TEST_ASSERT(!user.try_sandevistan_dodge(projectile), "Без сандевистана уклонения быть не должно")

	var/obj/item/organ/cyberimp/brain/sandevistan/implant = allocate(/obj/item/organ/cyberimp/brain/sandevistan)
	implant.Insert(user)
	TEST_ASSERT_EQUAL(implant.projectile_dodge_chance, 45, "Шанс уклонения сандевистана должен быть 45%")

	// Неактивный имплант не уклоняет, даже при 100% шансе.
	implant.active = FALSE
	implant.projectile_dodge_chance = 100
	TEST_ASSERT(!user.try_sandevistan_dodge(projectile), "Неактивный сандевистан не должен уклоняться")

	// Активный имплант с 100% шансом всегда уклоняется и пропускает проджектайл сквозь куклу.
	implant.active = TRUE
	TEST_ASSERT(user.try_sandevistan_dodge(projectile), "Активный сандевистан со 100% шансом должен уклоняться")
	TEST_ASSERT_EQUAL(user.bullet_act(projectile, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Уклонение должно пропускать проджектайл сквозь куклу")

	// Активный имплант с 0% шансом никогда не уклоняется.
	implant.projectile_dodge_chance = 0
	TEST_ASSERT(!user.try_sandevistan_dodge(projectile), "Сандевистан с 0% шансом не должен уклоняться")
