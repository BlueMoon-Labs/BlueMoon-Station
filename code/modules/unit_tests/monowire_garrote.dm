/// Моноструна душит только на интенте захвата и наносит окси-урон, пока захват держится.
/datum/unit_test/monowire_garrote

/datum/unit_test/monowire_garrote/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, start)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(start, EAST))
	var/obj/item/melee/implantmonostring/wire = allocate(/obj/item/melee/implantmonostring)
	user.put_in_active_hand(wire)

	// В боевом интенте струна просто режет и не хватает цель.
	user.a_intent = INTENT_HARM
	wire.attack(victim, user)
	TEST_ASSERT_NULL(user.pulling, "В боевом интенте моноструна не должна хватать цель")

	// Гаррота работает только в упор: с двух тайлов струна достаёт (reach), но не хватает.
	victim.forceMove(get_step(get_step(start, EAST), EAST))
	user.a_intent = INTENT_GRAB
	wire.attack(victim, user)
	TEST_ASSERT_NULL(user.pulling, "Моноструна не должна хватать цель с дистанции")
	victim.forceMove(get_step(start, EAST))

	// На интенте захвата струна обвивает шею и ставит удушающий захват.
	user.a_intent = INTENT_GRAB
	wire.attack(victim, user)
	TEST_ASSERT_EQUAL(user.pulling, victim, "На интенте захвата цель взята")
	TEST_ASSERT_EQUAL(user.grab_state, GRAB_KILL, "Гаррота ставит удушающий захват")
	TEST_ASSERT_EQUAL(victim.pulledby, user, "Цель удерживается гарротой")

	// Обычный GRAB_KILL в life() даёт слишком мало урона, поэтому душение идёт через process().
	var/oxyloss_before = victim.getOxyLoss()
	wire.process()
	TEST_ASSERT(victim.getOxyLoss() > oxyloss_before, "Удушение должно наносить окси-урон")

	// Разрыв захвата прекращает удушение.
	user.stop_pulling()
	wire.process()
	TEST_ASSERT_NULL(wire.strangling, "После разрыва захвата удушение прекращается")
	TEST_ASSERT_NULL(wire.strangler, "После разрыва захвата удушающий сбрасывается")

/// Все варианты моноструны бьют раз в 1 секунду; урон базовой 13, агентской 15.
/datum/unit_test/monowire_attack_speed/Run()
	var/expected = 1 SECONDS
	var/expected_damage = list(
		/obj/item/melee/implantmonostring = 13,
		/obj/item/melee/implantmonostring/corpo = 13,
		/obj/item/melee/implantmonostring/syndie = 15,
	)
	for(var/wire_type in expected_damage)
		var/obj/item/melee/implantmonostring/wire = allocate(wire_type)
		TEST_ASSERT_EQUAL(wire.attack_speed, expected, "[wire_type] должен иметь задержку атаки 1 секунда")
		TEST_ASSERT_EQUAL(wire.force, expected_damage[wire_type], "[wire_type] должен иметь урон [expected_damage[wire_type]]")
