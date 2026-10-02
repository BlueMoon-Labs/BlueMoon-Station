/// Полоса прогресса на удалённую цель гасится без рантайма в Destroy() и не пишет себя пользователю
/datum/unit_test/progressbar_deleted_target
	allowed_runtime_patterns = list("progressbar created with a missing or deleted target")

/datum/unit_test/progressbar_deleted_target/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/crowbar/target = allocate(/obj/item/crowbar)
	qdel(target)

	var/datum/progressbar/bar = new(user, 10, target)
	TEST_ASSERT(QDELETED(bar), "Полоса на удалённую цель должна сразу уничтожаться")
	TEST_ASSERT_NULL(bar.user, "Полоса на удалённую цель не должна запоминать пользователя")
	TEST_ASSERT(!length(user.progressbars), "Полоса на удалённую цель не должна попадать в список пользователя")

/// Полоса без цели встаёт над пользователем, как в do_after без target
/datum/unit_test/progressbar_no_target

/datum/unit_test/progressbar_no_target/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)

	var/datum/progressbar/bar = new(user, 10, null)
	TEST_ASSERT(!QDELETED(bar), "Полоса без цели не должна уничтожаться")
	TEST_ASSERT_EQUAL(bar.bar_loc, user, "Полоса без цели должна висеть над пользователем")
	qdel(bar)
	TEST_ASSERT(!length(user.progressbars), "Удалённая полоса должна уйти из списка пользователя")
