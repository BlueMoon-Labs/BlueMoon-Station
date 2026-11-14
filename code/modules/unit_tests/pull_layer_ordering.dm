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

/// Средний в цепочке меняет слой без шага (его взяли или отпустили): следующий пересчитывается от него.
/datum/unit_test/pull_layer_middle_change

/datum/unit_test/pull_layer_middle_change/Run()
	var/turf/bottom = run_loc_floor_bottom_left
	// Следующий к северу от среднего, тянущий берёт среднего с юга: средний уходит вниз
	var/mob/living/carbon/human/a = allocate(/mob/living/carbon/human, bottom)
	var/mob/living/carbon/human/b = allocate(/mob/living/carbon/human, locate(bottom.x, bottom.y + 1, bottom.z))
	var/mob/living/carbon/human/c = allocate(/mob/living/carbon/human, locate(bottom.x, bottom.y + 2, bottom.z))
	b.start_pulling(c)
	TEST_ASSERT_EQUAL(c.layer, MOB_LAYER - PULL_LAYER_STEP, "северный тащимый не под тянущим")
	a.start_pulling(b)
	TEST_ASSERT_EQUAL(b.layer, MOB_LAYER - PULL_LAYER_STEP, "средний не ушёл под южного тянущего")
	TEST_ASSERT_EQUAL(c.layer, b.layer - PULL_LAYER_STEP, "следующий не пересчитан от нового слоя среднего")
	a.stop_pulling()
	TEST_ASSERT_EQUAL(b.layer, MOB_LAYER, "средний не вернул слой")
	TEST_ASSERT_EQUAL(c.layer, MOB_LAYER - PULL_LAYER_STEP, "следующий не пересчитан после сброса среднего")
	b.stop_pulling()

	// Следующий к югу от среднего, тянущий берёт среднего с севера: средний уходит вверх
	var/mob/living/carbon/human/d = allocate(/mob/living/carbon/human, locate(bottom.x + 2, bottom.y + 2, bottom.z))
	var/mob/living/carbon/human/e = allocate(/mob/living/carbon/human, locate(bottom.x + 2, bottom.y + 1, bottom.z))
	var/mob/living/carbon/human/f = allocate(/mob/living/carbon/human, locate(bottom.x + 2, bottom.y, bottom.z))
	e.start_pulling(f)
	TEST_ASSERT_EQUAL(f.layer, MOB_LAYER + PULL_LAYER_STEP, "южный тащимый не поверх тянущего")
	d.start_pulling(e)
	TEST_ASSERT_EQUAL(e.layer, MOB_LAYER + PULL_LAYER_STEP, "средний не поднялся над северным тянущим")
	TEST_ASSERT_EQUAL(f.layer, e.layer + PULL_LAYER_STEP, "следующий не пересчитан от нового слоя среднего")
	d.stop_pulling()
	TEST_ASSERT_EQUAL(e.layer, MOB_LAYER, "средний не вернул слой")
	TEST_ASSERT_EQUAL(f.layer, MOB_LAYER + PULL_LAYER_STEP, "следующий не пересчитан после сброса среднего")
