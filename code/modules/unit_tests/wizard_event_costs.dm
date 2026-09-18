/mob/living/simple_animal/petsplosion_probe
	AIStatus = AI_OFF

/datum/unit_test/petsplosion_stops_at_dupe_cap
	var/datum/round_event/wizard/petsplosion/event

/datum/unit_test/petsplosion_stops_at_dupe_cap/Destroy()
	event?.kill()
	event = null
	return ..()

/datum/unit_test/petsplosion_stops_at_dupe_cap/proc/station_pets()
	var/list/pets = list()
	for(var/mob/living/simple_animal/animal in GLOB.alive_mob_list)
		if(!ishostile(animal) && is_station_level(animal.z))
			pets += animal
	return pets

/// Волна Petsplosion не клонирует больше потолка.
/datum/unit_test/petsplosion_stops_at_dupe_cap/Run()
	var/turf/station_turf = get_safe_random_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "на станции нет свободного турфа")
	for(var/i in 1 to 3)
		allocate(/mob/living/simple_animal/petsplosion_probe, station_turf)

	var/list/pets_before = station_pets()
	event = new(FALSE)
	event.max_dupes = 1
	event.tick()
	var/list/spawned = station_pets() - pets_before
	allocated += spawned

	TEST_ASSERT_EQUAL(length(spawned), 1, "волна клонировала [length(spawned)] животных при потолке 1")

/// Race Swap не держит запомненных людей жёсткими ссылками.
/datum/unit_test/race_swap_does_not_hold_humans
	var/datum/round_event/wizard/race/event

/datum/unit_test/race_swap_does_not_hold_humans/Destroy()
	event?.kill()
	event = null
	return ..()

/datum/unit_test/race_swap_does_not_hold_humans/Run()
	var/mob/living/carbon/human/swapped = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human)
	event = new(FALSE)
	event.remember_original(swapped)

	qdel(swapped)
	qdel(control)

	TEST_ASSERT_EQUAL(refcount(swapped), refcount(control), "событие держит удалённого человека")

/// Race Swap возвращает запомненному человеку имя.
/datum/unit_test/race_swap_restores_name

/datum/unit_test/race_swap_restores_name/Run()
	var/mob/living/carbon/human/swapped = allocate(/mob/living/carbon/human)
	swapped.real_name = "Original Name"
	var/datum/round_event/wizard/race/event = new(FALSE)
	event.remember_original(swapped)
	swapped.real_name = "Swapped Name"

	event.end()
	event.kill()

	TEST_ASSERT_EQUAL(swapped.real_name, "Original Name", "имя не вернулось после Race Swap")
