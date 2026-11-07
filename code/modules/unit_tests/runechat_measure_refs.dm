/datum/chatmessage/measure_probe
	var/measuring = FALSE

/datum/chatmessage/measure_probe/New()
	return

/datum/chatmessage/measure_probe/measure_height(complete_text)
	measuring = TRUE
	sleep(5 SECONDS)
	return 11

/// Пока сообщение ждёт замера от клиента, удалённый говорящий не держится и сообщение потом самоуничтожается.
/datum/unit_test/runechat_measure_refs/Run()
	var/mob/living/simple_animal/slime/speaker = new(run_loc_floor_bottom_left)
	var/datum/chatmessage/measure_probe/message = new
	message.generate_image("Blorble...", WEAKREF(speaker), world.icon_size, world.icon_size, 5 SECONDS)
	TEST_ASSERT(message.measuring, "замер текста не начался")
	qdel(speaker)
	sleep(3 SECONDS)
	TEST_ASSERT_EQUAL(refcount(speaker), 1, "ожидание замера держит удалённого говорящего")
	speaker = null
	sleep(3 SECONDS)
	TEST_ASSERT(QDELETED(message), "сообщение удалённого говорящего не удалилось после замера")
