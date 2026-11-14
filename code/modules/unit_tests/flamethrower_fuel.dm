/// Зажжённый огнемёт в руках каждый тик поджигал пол под владельцем: тайловый огонь,
/// догорев, сносит покрытие.
/datum/unit_test/flamethrower_lit_spares_holder_floor/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/flamethrower/full/tank/flamer = allocate(/obj/item/flamethrower/full/tank)
	user.put_in_active_hand(flamer)
	flamer.attack_self(user)
	TEST_ASSERT(flamer.lit, "test premise: огнемёт должен зажечься")

	var/turf/open/floor = get_turf(user)
	for(var/i in 1 to 3)
		flamer.process()
	TEST_ASSERT_NULL(floor.turf_fire, "горелка в руках не должна поджигать пол под владельцем")

/datum/unit_test/flamethrower_full_tank_fires/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/flamethrower/full/tank/flamer = allocate(/obj/item/flamethrower/full/tank)
	user.put_in_active_hand(flamer)
	flamer.attack_self(user)

	var/turf/open/first = get_step(user, EAST)
	var/turf/open/target = get_step(first, EAST)
	flamer.ranged_attack_chain(user, target)
	TEST_ASSERT_NOTNULL(first.turf_fire, "полный баллон обязан дать огонь по линии выстрела")

/// Огнемёт стрелял с выработанным баллоном: огонь на тайле не зависел от газа, а доля
/// с тайла убывает по экспоненте и баллон в ноль не уходит.
/datum/unit_test/flamethrower_drained_tank_does_not_fire/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/flamethrower/full/tank/flamer = allocate(/obj/item/flamethrower/full/tank)
	flamer.ptank.air_contents.clear()
	flamer.ptank.air_contents.set_moles(GAS_PLASMA, 0.1)
	flamer.ptank.air_contents.set_temperature(T20C)
	user.put_in_active_hand(flamer)
	flamer.attack_self(user)
	TEST_ASSERT(flamer.lit, "test premise: огнемёт зажигается и с пустым баллоном")

	var/turf/open/first = get_step(user, EAST)
	var/turf/open/target = get_step(first, EAST)
	flamer.ranged_attack_chain(user, target)
	TEST_ASSERT_NULL(first.turf_fire, "выработанный баллон не должен давать огня")
	TEST_ASSERT_NULL(target.turf_fire, "выработанный баллон не должен давать огня")
	TEST_ASSERT(abs(flamer.ptank.air_contents.get_moles(GAS_PLASMA) - 0.1) < 0.001, "выстрел без топлива не должен тянуть газ из баллона")
