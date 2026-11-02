/// В цепочке тащения южный рисуется поверх северного, лежачий остаётся под стоящими, слой возвращается после отпускания.
/datum/unit_test/pull_layer_ordering

/datum/unit_test/pull_layer_ordering/Run()
	var/turf/bottom = run_loc_floor_bottom_left
	var/mob/living/carbon/human/alice = allocate(/mob/living/carbon/human, locate(bottom.x, bottom.y + 2, bottom.z))
	var/mob/living/carbon/human/bob = allocate(/mob/living/carbon/human, locate(bottom.x, bottom.y + 1, bottom.z))
	var/mob/living/carbon/human/charlie = allocate(/mob/living/carbon/human, bottom)
	alice.start_pulling(bob)
	bob.start_pulling(charlie)
	TEST_ASSERT(bob.layer > alice.layer, "второй в цепочке к северу не поверх первого")
	TEST_ASSERT(charlie.layer > bob.layer, "третий в цепочке к северу не поверх второго")

	alice.Move(get_step(alice, NORTH), NORTH)
	TEST_ASSERT_EQUAL(charlie.loc, locate(bottom.x, bottom.y + 1, bottom.z), "цепочка не пошла за первым")
	TEST_ASSERT(bob.layer > alice.layer, "после шага второй не поверх первого")
	TEST_ASSERT(charlie.layer > bob.layer, "после шага третий не поверх второго")

	bob.set_resting(TRUE, TRUE)
	TEST_ASSERT_EQUAL(bob.layer, LYING_MOB_LAYER, "лежачий в цепочке не опустился под стоящих")
	bob.set_resting(FALSE, TRUE)
	TEST_ASSERT(!bob.lying, "тащимый не встал")
	TEST_ASSERT(bob.layer > alice.layer, "вставший снова не поверх тянущего")

	alice.stop_pulling()
	TEST_ASSERT_EQUAL(bob.layer, MOB_LAYER, "отпущенный остался на сдвинутом слое")
	bob.stop_pulling()
	TEST_ASSERT_EQUAL(charlie.layer, MOB_LAYER, "отпущенный третий остался на сдвинутом слое")

	var/mob/living/carbon/human/dragger = allocate(/mob/living/carbon/human, locate(bottom.x + 2, bottom.y, bottom.z))
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, locate(bottom.x + 2, bottom.y + 1, bottom.z))
	dragger.start_pulling(body)
	TEST_ASSERT(body.layer < dragger.layer, "тащимый с севера не под тянущим")

	dragger.stop_pulling()
	var/mob/living/carbon/human/side = allocate(/mob/living/carbon/human, locate(bottom.x + 3, bottom.y, bottom.z))
	dragger.start_pulling(side)
	TEST_ASSERT(side.layer < dragger.layer, "тащимый сбоку не под тянущим")

	dragger.stop_pulling()
	body.set_resting(TRUE, TRUE)
	dragger.start_pulling(body)
	TEST_ASSERT_EQUAL(body.layer, LYING_MOB_LAYER, "лежачий тащимый поднялся над полом лежачих")
