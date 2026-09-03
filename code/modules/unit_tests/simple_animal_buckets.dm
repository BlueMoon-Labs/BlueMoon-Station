/// Гигиена бакетов GLOB.simple_animals: удалённый моб не должен оставаться
/// ни в одном бакете и не должен туда возвращаться.
/// Регрессия по прод-логу: qdel-нутый слайм висел в GLOB.simple_animals
/// (warnfail + hard delete) - отложенный toggle_ai по удалённому мобу
/// (timestop, циклы мегафауны) заново кладёт труп в бакет, а прямое присвоение
/// AIStatus на живом мобе оставляет запись в старом бакете, которую Destroy()
/// по текущему статусу не находит.
/datum/unit_test/simple_animal_bucket_hygiene/Run()
	// 1) toggle_ai по qdel-нутому мобу не должен возвращать его в бакеты
	var/mob/living/simple_animal/mouse = allocate(/mob/living/simple_animal/mouse, run_loc_floor_bottom_left)
	qdel(mouse)
	for(var/bucket_index in 1 to length(GLOB.simple_animals))
		TEST_ASSERT(!(mouse in GLOB.simple_animals[bucket_index]), "Удалённый моб остался в бакете номер [bucket_index] после qdel")
	mouse.toggle_ai(AI_IDLE)
	for(var/bucket_index in 1 to length(GLOB.simple_animals))
		TEST_ASSERT(!(mouse in GLOB.simple_animals[bucket_index]), "toggle_ai по удалённому мобу воскресил запись в бакете номер [bucket_index]")

	// 2) прямое присвоение AIStatus (в обход toggle_ai) не должно приводить
	// к вечному стрэнду: Destroy() обязан вычистить моба из ВСЕХ бакетов
	var/mob/living/simple_animal/stranded = allocate(/mob/living/simple_animal/mouse, run_loc_floor_bottom_left)
	TEST_ASSERT(stranded in GLOB.simple_animals[stranded.AIStatus], "Свежий моб не попал в свой бакет simple_animals")
	stranded.AIStatus = (stranded.AIStatus == AI_OFF) ? AI_ON : AI_OFF
	qdel(stranded)
	for(var/bucket_index in 1 to length(GLOB.simple_animals))
		TEST_ASSERT(!(stranded in GLOB.simple_animals[bucket_index]), "Моб с рассинхроненным AIStatus остался в бакете номер [bucket_index] после qdel")
