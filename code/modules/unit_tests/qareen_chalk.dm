/// Рисование руны завершается без ошибок progressbar и освобождает связанные списки.
/datum/unit_test/qareen_chalk_progress_target/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/qareen_chalk/chalk = allocate(/obj/item/qareen_chalk)
	var/turf/target = get_step(run_loc_floor_bottom_left, NORTH)
	user.put_in_hands(chalk)
	chalk.afterattack(target, user, TRUE)
	TEST_ASSERT(QDELETED(chalk), "После завершения рисования мел должен израсходоваться")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/qareen_rune) in target, "Руна должна появиться на выбранном полу")
	var/list/bars = user.progressbars[target]
	TEST_ASSERT_EQUAL(length(bars), 1, "После действия полоса должна доиграть затухание")
	var/datum/progressbar/bar = bars[1]
	TEST_ASSERT(wait_for_qdeleted(bar), "Полоса должна удалиться после затухания")
	TEST_ASSERT(!length(user.progressbars), "Завершённая полоса прогресса должна очистить список пользователя")
	TEST_ASSERT(!(target in user.do_afters), "Завершённое действие должно освободить цель")
	TEST_ASSERT(!(user in target.targeted_by), "Цель не должна удерживать пользователя после завершения")
