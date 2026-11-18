/// Щиты брони (shielded hardsuit) должны поглощать удар моноструны.
/datum/unit_test/monowire_shield_block/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/space/hardsuit/shielded/suit = allocate(/obj/item/clothing/suit/space/hardsuit/shielded)
	TEST_ASSERT(victim.equip_to_slot_if_possible(suit, ITEM_SLOT_OCLOTHING), "Щит-костюм не надет")
	var/list/datum/component/shielded/shields = suit.GetComponents(/datum/component/shielded)
	TEST_ASSERT(length(shields), "У костюма нет компонента щита")
	var/datum/component/shielded/shield = shields[1]

	var/obj/item/melee/implantmonostring/wire = allocate(/obj/item/melee/implantmonostring)
	var/list/block_return = list()
	TEST_ASSERT(victim.mob_run_block(wire, wire.force, "the [wire.name]", ATTACK_TYPE_MELEE, wire.armour_penetration, attacker, BODY_ZONE_CHEST, block_return) & BLOCK_SUCCESS, "Щит не блокирует удар моноструны")
	TEST_ASSERT_EQUAL(shield.charges, shield.max_charges - 1, "Щит не потратил заряд на удар моноструны")

/// Полная цепочка обычного удара моноструной не должна проходить сквозь щит.
/datum/unit_test/monowire_shield_blocks_attack/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/space/hardsuit/shielded/suit = allocate(/obj/item/clothing/suit/space/hardsuit/shielded)
	TEST_ASSERT(victim.equip_to_slot_if_possible(suit, ITEM_SLOT_OCLOTHING), "Щит-костюм не надет")
	var/list/datum/component/shielded/shields = suit.GetComponents(/datum/component/shielded)
	var/datum/component/shielded/shield = shields[1]
	var/obj/item/melee/implantmonostring/wire = allocate(/obj/item/melee/implantmonostring)
	attacker.a_intent = INTENT_HARM

	wire.attack(victim, attacker)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Удар моноструны прошёл сквозь щит")
	TEST_ASSERT_EQUAL(shield.charges, shield.max_charges - 1, "Щит не потратил заряд на удар моноструны")

/// Гаррота моноструной не должна начинаться сквозь щит.
/datum/unit_test/monowire_shield_blocks_garrote/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/space/hardsuit/shielded/suit = allocate(/obj/item/clothing/suit/space/hardsuit/shielded)
	TEST_ASSERT(victim.equip_to_slot_if_possible(suit, ITEM_SLOT_OCLOTHING), "Щит-костюм не надет")
	var/list/datum/component/shielded/shields = suit.GetComponents(/datum/component/shielded)
	var/datum/component/shielded/shield = shields[1]
	var/obj/item/melee/implantmonostring/wire = allocate(/obj/item/melee/implantmonostring)
	attacker.a_intent = INTENT_GRAB
	victim.dir = attacker.dir

	wire.attack(victim, attacker)
	TEST_ASSERT_NULL(wire.strangling, "Гаррота началась сквозь щит")
	TEST_ASSERT_EQUAL(shield.charges, shield.max_charges - 1, "Щит не потратил заряд на попытку гарроты")

/// Разряд агентской моноструны не должен проходить сквозь щит.
/datum/unit_test/monowire_shield_blocks_shock/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/space/hardsuit/shielded/suit = allocate(/obj/item/clothing/suit/space/hardsuit/shielded)
	TEST_ASSERT(victim.equip_to_slot_if_possible(suit, ITEM_SLOT_OCLOTHING), "Щит-костюм не надет")
	var/obj/item/melee/implantmonostring/syndie/wire = allocate(/obj/item/melee/implantmonostring/syndie)
	attacker.a_intent = INTENT_HARM

	wire.attack(victim, attacker)
	TEST_ASSERT(!victim.IsParalyzed(), "Разряд агентской моноструны прошёл сквозь щит")
