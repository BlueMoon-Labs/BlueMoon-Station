// ===== Труп не бегает =====
//
// Регрессия с прода: замороженного таймстопом моба добивали, поле спадало, и
// unfreeze_mob звал легаси toggle_ai(initial(AIStatus)) - тот форсил
// set_ai_status(AI_STATUS_ON) в обход проверки stat в get_expected_ai_status().
// stat у трупа больше не меняется, так что планировщик гонял мёртвого моба до
// конца раунда: он бегал, бил и не умирал повторно (updatehealth() зовёт death()
// только из живого stat), а на шифтклике честно писал "не подаёт признаков жизни".

///Труп нельзя поднять форсом легаси-статуса, но воскрешение обязано вернуть AI
/datum/unit_test/dead_pawn_ai_never_forced_on/Run()
	var/mob/living/simple_animal/hostile/carp/fish = allocate(/mob/living/simple_animal/hostile/carp)
	var/datum/ai_controller/controller = fish.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: карп должен подниматься с контроллером")

	fish.adjustHealth(fish.maxHealth * 2)
	TEST_ASSERT_EQUAL(fish.stat, DEAD, "Sanity: урон больше maxHealth обязан убить карпа")
	TEST_ASSERT(!controller.able_to_run, "Смерть обязана снимать able_to_run")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "Sanity: труп должен уходить в OFF по смене stat")

	fish.toggle_ai(AI_ON)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "Легаси toggle_ai(AI_ON) не должен поднимать труп в бакет активных контроллеров")
	TEST_ASSERT(!controller.able_to_run, "Легаси toggle_ai(AI_ON) не должен возвращать able_to_run трупу")

	fish.revive(full_heal = TRUE)
	TEST_ASSERT_EQUAL(fish.stat, CONSCIOUS, "Sanity: полное лечение обязано вернуть карпа в сознание")
	TEST_ASSERT(controller.able_to_run, "После воскрешения контроллер обязан снова быть работоспособен")

///Снятие таймстопа не должно оживлять AI моба, убитого внутри поля
/datum/unit_test/timestop_does_not_revive_dead_ai/Run()
	var/mob/living/simple_animal/hostile/asteroid/goliath/goliath = allocate(/mob/living/simple_animal/hostile/asteroid/goliath)
	var/datum/ai_controller/controller = goliath.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: голиаф должен подниматься с контроллером")

	//run_loc_floor_bottom_left - центр резервации, радиус 1 укладывается в неё целиком.
	//start = FALSE и ручной вызов: штатный путь строит поле через INVOKE_ASYNC, и
	//рассчитывать на то, что оно доедет до следующей строки, нельзя - тест так флачил
	var/obj/effect/timestop/field = allocate(/obj/effect/timestop, run_loc_floor_bottom_left, 1, 10 SECONDS, null, FALSE)
	field.timestop()
	TEST_ASSERT_NOTNULL(field.chronofield, "Sanity: таймстоп обязан построить хронополе")
	TEST_ASSERT(HAS_TRAIT(goliath, TRAIT_AI_PAUSED), "Заморозка обязана ставить пауну паузу AI")

	//обычный сценарий каста: замороженного моба добивают, пока он не может ответить
	goliath.adjustHealth(goliath.maxHealth * 2)
	TEST_ASSERT_EQUAL(goliath.stat, DEAD, "Sanity: урон больше maxHealth обязан убить голиафа внутри поля")

	qdel(field)
	TEST_ASSERT(!HAS_TRAIT(goliath, TRAIT_AI_PAUSED), "Снятие таймстопа обязано снимать паузу AI")
	TEST_ASSERT(!controller.able_to_run, "Труп после таймстопа не должен быть able_to_run")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "Труп после таймстопа не должен возвращаться в бакет активных контроллеров")
	TEST_ASSERT_NULL(goliath.move_packet?.existing_loops[SSai_movement], "У трупа не должно остаться мув-лупа AI")
