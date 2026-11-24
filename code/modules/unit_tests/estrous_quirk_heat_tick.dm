/// Тик эстрального цикла поднимает стадию и пишет сообщение без рантайма в span_love().
/datum/unit_test/estrous_quirk_heat_tick

/datum/unit_test/estrous_quirk_heat_tick/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	holder.add_quirk(/datum/quirk/estrous_active)
	var/datum/quirk/estrous_active/quirk = locate() in holder.roundstart_quirks
	TEST_ASSERT_NOTNULL(quirk, "Квирк должен добавиться")

	quirk.last_heat_reset = world.time - (10 MINUTES + 1)
	holder.last_climax = quirk.last_heat_reset
	quirk.on_heat_tick()
	TEST_ASSERT_EQUAL(quirk.current_stage, 1, "За 10 минут стадия должна вырасти до первой")
	TEST_ASSERT_NOTNULL(quirk.heat_timer, "После тика должен встать следующий")
