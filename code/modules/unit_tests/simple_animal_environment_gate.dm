// ===== Гейт обработки среды в PhysicalLife =====
//
// Иммунный к среде симпл (нет газовых требований, температурные границы
// разомкнуты) не должен платить return_air()+handle_environment() каждый
// тик Life. Уязвимый - обязан обрабатывать среду как раньше.

///Полностью безразличен к атмосфере и температуре
/mob/living/simple_animal/unit_test_env_immune
	name = "env immune subject"
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY

///Обычный дышащий симпл с дефолтными требованиями
/mob/living/simple_animal/unit_test_env_sensitive
	name = "env sensitive subject"

/datum/unit_test/simple_animal_environment_gate/Run()
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	register_fake_player(fake_player, run_loc_floor_bottom_left)

	var/mob/living/simple_animal/immune = allocate(/mob/living/simple_animal/unit_test_env_immune, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/sensitive = allocate(/mob/living/simple_animal/unit_test_env_sensitive, get_step(run_loc_floor_bottom_left, EAST))

	TEST_ASSERT(immune.environment_processing_immune, "A mob with no atmos requirements and unbounded temperature must be environment-immune")
	TEST_ASSERT(!sensitive.environment_processing_immune, "A default simple animal must keep processing its environment")

	//иммунный: температура тела не дрейфует к комнатной - среда не читается вовсе
	immune.bodytemperature = 500
	immune.PhysicalLife(2, 1)
	TEST_ASSERT_EQUAL(immune.bodytemperature, 500, "An environment-immune mob must skip body temperature drift")

	//уязвимый: обычный дрейф к температуре среды сохранился
	sensitive.bodytemperature = 500
	sensitive.PhysicalLife(2, 1)
	TEST_ASSERT(sensitive.bodytemperature < 500, "A sensitive mob must keep drifting toward the area temperature")

	//рантайм-смена требований через refresh перещитывает флаг
	immune.maxbodytemp = 400
	immune.refresh_atmos_pathing_sensitivity()
	TEST_ASSERT(!immune.environment_processing_immune, "Tightening the temperature bounds must re-enable environment processing")
