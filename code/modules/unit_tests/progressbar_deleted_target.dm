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
