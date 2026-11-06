#define STOMP_GRAVITY "gravity"
#define STOMP_ANTIGRAV "antigrav"
#define STOMP_FLYING "flying"
#define STOMP_NO_GRAVITY_TURF "no_gravity_turf"

/// Сверхтяжёлый великан давит только под гравитацией: антиграв, полёт и тайл без гравитации давку снимают
/datum/unit_test/heavy_stomp_weightless

/datum/unit_test/heavy_stomp_weightless/Run()
	for(var/target_lying in list(TRUE, FALSE))
		var/how = target_lying ? "по лежащему" : "в стоящего"
		TEST_ASSERT(stomp_brute(STOMP_GRAVITY, target_lying) > 0, "Сверхтяж под гравитацией, шагая [how], не нанёс урона")
		TEST_ASSERT_EQUAL(stomp_brute(STOMP_ANTIGRAV, target_lying), 0, "Сверхтяж с антигравом, шагая [how], нанёс урон")
		TEST_ASSERT_EQUAL(stomp_brute(STOMP_FLYING, target_lying), 0, "Летящий сверхтяж, шагая [how], нанёс урон")
		TEST_ASSERT_EQUAL(stomp_brute(STOMP_NO_GRAVITY_TURF, target_lying), 0, "Сверхтяж на тайле без гравитации, шагая [how], нанёс урон")

/datum/unit_test/heavy_stomp_weightless/proc/stomp_brute(setup, target_lying)
	var/turf/start = run_loc_floor_bottom_left
	var/turf/victim_turf = get_step(start, EAST)
	var/mob/living/carbon/human/heavy = allocate(/mob/living/carbon/human, start)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_turf)
	heavy.mob_weight = MOB_WEIGHT_HEAVY_SUPER
	heavy.update_size(2)
	heavy.a_intent = INTENT_HARM
	if(target_lying)
		victim.Knockdown(10 SECONDS)
	TEST_ASSERT(abs(get_size(heavy) - 2) < 0.01, "Рост великана не стал 200%")
	TEST_ASSERT_EQUAL(!!victim.lying, !!target_lying, "Цель не в нужной позе")

	// в резервации тестов своей гравитации нет
	var/victim_gravity = setup == STOMP_NO_GRAVITY_TURF ? 0 : STANDARD_GRAVITY
	start.AddElement(/datum/element/forced_gravity, STANDARD_GRAVITY)
	victim_turf.AddElement(/datum/element/forced_gravity, victim_gravity)
	heavy.refresh_gravity()
	switch(setup)
		if(STOMP_ANTIGRAV)
			heavy.AddElement(/datum/element/forced_gravity, 0)
		if(STOMP_FLYING)
			heavy.setMovetype(heavy.movement_type | FLYING)
	var/grounded = heavy.has_gravity(victim_turf) && !(heavy.movement_type & FLOATING)

	heavy.Move(victim_turf, EAST)
	. = victim.getBruteLoss()

	start.RemoveElement(/datum/element/forced_gravity, STANDARD_GRAVITY)
	victim_turf.RemoveElement(/datum/element/forced_gravity, victim_gravity)
	qdel(heavy)
	qdel(victim)
	if(setup == STOMP_GRAVITY)
		TEST_ASSERT(grounded, "Контрольный случай идёт не под гравитацией")

#undef STOMP_GRAVITY
#undef STOMP_ANTIGRAV
#undef STOMP_FLYING
#undef STOMP_NO_GRAVITY_TURF
