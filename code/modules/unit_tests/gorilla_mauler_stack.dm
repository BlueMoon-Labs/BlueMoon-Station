/// Синди-руки гориллы складываются с маулер-перчатками: бонусы к урону суммируются,
/// а TRAIT_MAULER превращает удар в 1.2x урона без стамины.
/datum/unit_test/gorilla_mauler_stack

/datum/unit_test/gorilla_mauler_stack/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.set_species(/datum/species/human)
	user.dna.features["body_size"] = 1
	user.dna.species.punchdamagelow = 10
	user.dna.species.punchdamagehigh = 10
	user.dna.species.punchwoundbonus = 0

	// Синди-руки гориллы добавляют +12 к урону кулаков.
	var/obj/item/organ/cyberimp/arm/gorilla/syndie/implant = allocate(/obj/item/organ/cyberimp/arm/gorilla/syndie)
	implant.Insert(user)
	TEST_ASSERT_EQUAL(user.dna.species.punchdamagelow, 22, "Синди-руки гориллы должны поднять нижнюю границу урона до 22")
	TEST_ASSERT_EQUAL(user.dna.species.punchdamagehigh, 22, "Синди-руки гориллы должны поднять верхнюю границу урона до 22")
	TEST_ASSERT_EQUAL(user.dna.species.punchwoundbonus, 12, "Синди-руки гориллы должны добавить бонус к ранам")

	// Маулер-перчатки добавляют ещё +16 и выдают TRAIT_MAULER.
	var/obj/item/clothing/gloves/fingerless/pugilist/mauler/gauntlets = allocate(/obj/item/clothing/gloves/fingerless/pugilist/mauler)
	TEST_ASSERT(user.equip_to_slot_or_del(gauntlets, ITEM_SLOT_GLOVES), "Маулер-перчатки должны надеться")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_MAULER), "Маулер-перчатки должны выдать TRAIT_MAULER")
	TEST_ASSERT_EQUAL(user.dna.species.punchdamagelow, 38, "Маулер-перчатки должны сложиться с руками гориллы (10 + 12 + 16)")
	TEST_ASSERT_EQUAL(user.dna.species.punchdamagehigh, 38, "Маулер-перчатки должны сложиться с руками гориллы (10 + 12 + 16)")
	TEST_ASSERT_EQUAL(user.dna.species.punchwoundbonus, 28, "Бонус к ранам тоже должен сложиться (12 + 16)")

	// Удар с TRAIT_MAULER наносит 1.2x урона и не трогает стамину цели.
	// Раны добавляют свой брут к результату, поэтому для проверки множителя их отключаем.
	user.dna.species.punchwoundbonus = 0
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	user.zone_selected = BODY_ZONE_CHEST
	var/stamina_before = target.getStaminaLoss()
	var/brute_before = target.getBruteLoss()
	user.dna.species.harm(user, target)
	var/brute_dealt = target.getBruteLoss() - brute_before
	var/stamina_dealt = target.getStaminaLoss() - stamina_before

	TEST_ASSERT(abs(brute_dealt - 45.6) < 0.05, "Удар должен нанести 1.2x от 38 урона за счёт TRAIT_MAULER (нанесено [brute_dealt])")
	TEST_ASSERT_EQUAL(stamina_dealt, 0, "Удар с TRAIT_MAULER не должен выбивать стамину")
