/// Мудлет опьянения держится, пока органик пьян: раньше лишняя ветка снимала его каждый тик сразу после постановки.
/datum/unit_test/drunk_mood_event

/datum/unit_test/drunk_mood_event/Run()
	var/mob/living/carbon/human/drinker = allocate(/mob/living/carbon/human)
	var/datum/component/mood/mood = drinker.GetComponent(/datum/component/mood)
	TEST_ASSERT_NOTNULL(mood, "у человека нет компонента настроения")
	drinker.drunkenness = 30
	drinker.handle_status_effects()
	TEST_ASSERT_NOTNULL(mood.mood_events["drunk"], "мудлет опьянения снят в том же тике, где поставлен")
	drinker.drunkenness = 1
	drinker.handle_status_effects()
	TEST_ASSERT_NULL(mood.mood_events["drunk"], "мудлет опьянения остался у трезвого")
