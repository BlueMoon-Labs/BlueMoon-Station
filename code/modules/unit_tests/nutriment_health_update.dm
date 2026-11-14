/// Нутримент просит пересчёт моба только когда что-то зажило: у здорового сытого моба пересчёт здоровья, мобильности и стамины шёл каждый второй тик впустую.
/datum/unit_test/nutriment_health_update

/datum/unit_test/nutriment_health_update/Run()
	var/mob/living/carbon/human/eater = allocate(/mob/living/carbon/human)
	var/datum/reagent/consumable/nutriment/food = new
	food.brute_heal = 1
	for(var/i in 1 to 20)
		TEST_ASSERT(!food.on_mob_life(eater), "нутримент у здорового моба запросил пересчёт на итерации [i]")

	eater.take_bodypart_damage(10)
	var/damaged = eater.getBruteLoss()
	TEST_ASSERT(damaged > 0, "моб не получил урон для проверки лечения")
	var/requested = FALSE
	for(var/i in 1 to 40)
		if(food.on_mob_life(eater))
			requested = TRUE
	TEST_ASSERT(requested, "нутримент лечил, но ни разу не запросил пересчёт моба")
	TEST_ASSERT(eater.getBruteLoss() < damaged, "нутримент не лечил раненого моба")
	qdel(food)

	var/obj/item/bodypart/chest = eater.get_bodypart(BODY_ZONE_CHEST)
	chest.brute_dam = 0
	TEST_ASSERT(!eater.heal_bodypart_damage(5, 0, 0), "heal_bodypart_damage вернул TRUE без урона")
	eater.take_bodypart_damage(5)
	TEST_ASSERT(eater.heal_bodypart_damage(5, 0, 0), "heal_bodypart_damage не вернул TRUE после лечения")
