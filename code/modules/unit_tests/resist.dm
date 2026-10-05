/// Test that stop, drop, and roll lowers fire stacks
/datum/unit_test/stop_drop_and_roll/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	TEST_ASSERT_EQUAL(human.fire_stacks, 0, "Human does not have 0 fire stacks pre-ignition")

	human.adjust_fire_stacks(5)
	human.IgniteMob()

	TEST_ASSERT_EQUAL(human.fire_stacks, 5, "Human does not have 5 fire stacks pre-resist")

	// Stop, drop, and roll has a sleep call. This would delay the test, and is not necessary.
	CallAsync(human, /mob/living/verb/resist)

	// resist() is a verb: on an overloaded tick it queues into SSverb_manager
	// instead of executing inline, so drain the queue before asserting.
	SSverb_manager.run_verb_queue()

	TEST_ASSERT(human.fire_stacks < 5, "Human did not lower fire stacks after resisting")

/// Test that you can resist out of a container
/datum/unit_test/container_resist/Run()
	var/obj/structure/closet/closet = allocate(/obj/structure/closet)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, closet)
	TEST_ASSERT(!closet.opened && human.loc == closet, "Персонаж начинает проверку внутри закрытого шкафа.")

	human.resist()

	// resist() is a verb: on an overloaded tick it queues into SSverb_manager
	// instead of executing inline, so drain the queue before asserting.
	SSverb_manager.run_verb_queue()

	TEST_ASSERT(closet.opened && human.loc == get_turf(closet), "Сопротивление открывает шкаф и выпускает персонажа на его клетку.")
