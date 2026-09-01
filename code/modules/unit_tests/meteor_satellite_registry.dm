/// Противометеоритный спутник должен лежать в GLOB.meteor_satellites ровно один раз и
/// покидать список при удалении. Родительский и дочерний Initialize оба добавляли его,
/// а Destroy снимал одну запись - дубль держал спутник до харддела.
/datum/unit_test/meteor_satellite_registry/Run()
	// Спутник заводится в нулевом пространстве: его Destroy взрывает свой loc, а взрыв
	// в резервации теста разлетелся бы по чужим объектам уже после конца проверки.
	var/obj/machinery/satellite/meteor_shield/satellite = allocate(/obj/machinery/satellite/meteor_shield)
	var/entries = 0
	for(var/obj/machinery/satellite/listed in GLOB.meteor_satellites)
		if(listed == satellite)
			entries++
	TEST_ASSERT_EQUAL(entries, 1, "спутник должен попадать в GLOB.meteor_satellites ровно один раз")

	qdel(satellite)
	TEST_ASSERT(!(satellite in GLOB.meteor_satellites), "удалённый спутник не должен оставаться в GLOB.meteor_satellites")
