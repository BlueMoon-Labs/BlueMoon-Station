// Фото манифеста снимается лениво: вставка в манифест кладёт в запись только снапшот
// внешности, а кадр строится при первом обращении к фотографии и живёт в кэше записи.

/// Источник со счётчиком реальных съёмок: подменяется только генерация, логика кэша настоящая.
/datum/record_photo_source/unit_test_counted
	var/build_count = 0

/datum/record_photo_source/unit_test_counted/build_photo_icon()
	build_count++
	return ..()

/// Тот же источник со съёмкой, которая спит: окно, где кадр уже строится, но ещё не готов.
/datum/record_photo_source/unit_test_counted/slow

/datum/record_photo_source/unit_test_counted/slow/build_photo_icon()
	sleep(0.2 SECONDS)
	return ..()

/// Ленивый путь: до обращения фотографии нет, первое обращение снимает её ровно один раз.
/datum/unit_test/manifest_photo_lazy/Run()
	var/mob/living/carbon/human/crewmember = allocate(/mob/living/carbon/human)
	var/datum/data/record/general_record = new
	general_record.fields["name"] = "Test Subject"
	var/datum/record_photo_source/unit_test_counted/source = new(crewmember, null, null)
	general_record.photo_source = source

	TEST_ASSERT_NULL(general_record.fields["photo_front"], "запись не должна нести фото до первого обращения")
	TEST_ASSERT_EQUAL(source.build_count, 0, "снятие снапшота внешности не должно строить кадр")
	TEST_ASSERT_NULL(general_record.get_record_photo("photo_front", generate = FALSE), "заглядывание в кэш не должно отдавать фото до съёмки")
	TEST_ASSERT_EQUAL(source.build_count, 0, "заглядывание в кэш не должно снимать кадр - на этом стоит список записей охраны")

	var/obj/item/photo/photo_front = general_record.get_record_photo("photo_front")
	TEST_ASSERT(istype(photo_front), "первое обращение должно отдавать фото анфас")
	TEST_ASSERT_NOTNULL(photo_front.picture?.picture_image, "фото анфас должно содержать изображение")
	TEST_ASSERT_EQUAL(source.build_count, 1, "первое обращение должно снимать кадр ровно один раз")

	var/obj/item/photo/photo_side = general_record.get_record_photo("photo_side")
	TEST_ASSERT(istype(photo_side), "тот же кадр должен раскладываться и в профиль")
	TEST_ASSERT_NOTNULL(photo_side.picture?.picture_image, "фото в профиль должно содержать изображение")
	TEST_ASSERT_EQUAL(source.build_count, 1, "профиль берётся из того же кадра, а не снимается заново")

	TEST_ASSERT_EQUAL(general_record.get_record_photo("photo_front"), photo_front, "повторное обращение должно отдавать тот же объект фото")
	TEST_ASSERT_EQUAL(general_record.get_record_photo("photo_front", generate = FALSE), photo_front, "после съёмки заглядывание должно отдавать готовое фото")
	TEST_ASSERT_EQUAL(source.build_count, 1, "повторные обращения обязаны брать кэш")

	qdel(photo_front)
	qdel(photo_side)

/// Читатель, пришедший пока кадр снимается, дожидается кадра, а съёмка остаётся одной.
/datum/unit_test/manifest_photo_lazy_inflight
	var/datum/data/record/inflight_record
	var/obj/item/photo/inflight_result

/datum/unit_test/manifest_photo_lazy_inflight/proc/read_photo_async()
	inflight_result = inflight_record?.get_record_photo("photo_front")

/datum/unit_test/manifest_photo_lazy_inflight/Run()
	var/mob/living/carbon/human/crewmember = allocate(/mob/living/carbon/human)
	inflight_record = new
	inflight_record.fields["name"] = "Inflight Subject"
	var/datum/record_photo_source/unit_test_counted/slow/source = new(crewmember, null, null)
	inflight_record.photo_source = source

	INVOKE_ASYNC(src, PROC_REF(read_photo_async))
	var/enter_deadline = world.time + 5 SECONDS
	UNTIL(source.generating || world.time > enter_deadline)
	TEST_ASSERT(source.generating, "первый читатель должен был войти в съёмку")
	TEST_ASSERT_NULL(source.cached_icon, "кадра не должно быть, пока съёмка идёт")

	var/obj/item/photo/photo_front = inflight_record.get_record_photo("photo_front")
	TEST_ASSERT(istype(photo_front), "пришедший во время съёмки должен дождаться кадра, а не получить null")
	TEST_ASSERT_NOTNULL(photo_front.picture?.picture_image, "дождавшийся читатель должен получить настоящее фото")
	TEST_ASSERT_EQUAL(source.build_count, 1, "ожидание не должно превращаться во вторую съёмку")

	var/finish_deadline = world.time + 5 SECONDS
	UNTIL(inflight_result || world.time > finish_deadline)
	TEST_ASSERT_EQUAL(inflight_result, photo_front, "оба читателя должны получить одно и то же фото")
	TEST_ASSERT_EQUAL(source.build_count, 1, "к концу должна остаться ровно одна съёмка на двоих")

	qdel(photo_front)
	qdel(inflight_record.fields["photo_side"])
	inflight_record = null
	inflight_result = null

/// Источник общий у general- и locked-записи: кадр снимается один раз на обе.
/datum/unit_test/manifest_photo_lazy_shared/Run()
	var/mob/living/carbon/human/crewmember = allocate(/mob/living/carbon/human)
	var/datum/record_photo_source/unit_test_counted/source = new(crewmember, null, null)
	var/datum/data/record/general_record = new
	var/datum/data/record/locked_record = new
	general_record.fields["name"] = "Shared Subject"
	general_record.photo_source = source
	locked_record.photo_source = source

	TEST_ASSERT_NULL(locked_record.fields["image"], "locked-запись не должна нести картинку до первого обращения")
	var/icon/locked_image = locked_record.get_record_image()
	TEST_ASSERT_NOTNULL(locked_image, "первое обращение к locked-записи должно снимать кадр")
	TEST_ASSERT_EQUAL(source.build_count, 1, "первое обращение к locked-записи должно снимать кадр один раз")

	var/obj/item/photo/photo_front = general_record.get_record_photo("photo_front")
	TEST_ASSERT(istype(photo_front), "general-запись должна получать фото из общего с locked источника")
	TEST_ASSERT_EQUAL(source.build_count, 1, "общий источник обязан сниматься один раз на обе записи")

	qdel(photo_front)
	qdel(general_record.fields["photo_side"])

/// Снимать нечего - запись отдаёт плейсхолдер, а не рантайм.
/datum/unit_test/manifest_photo_lazy_placeholder/Run()
	var/mob/living/carbon/human/crewmember = new(run_loc_floor_bottom_left)
	qdel(crewmember)
	var/datum/record_photo_source/unit_test_counted/source = new(crewmember, null, null)
	TEST_ASSERT_NULL(source.frozen_appearance, "с удалённого моба снапшот внешности сниматься не должен")

	var/datum/data/record/general_record = new
	general_record.fields["name"] = "Gone Subject"
	general_record.photo_source = source

	var/obj/item/photo/photo_front = general_record.get_record_photo("photo_front")
	TEST_ASSERT(istype(photo_front), "запись без исходника должна отдавать плейсхолдер")
	TEST_ASSERT_NOTNULL(photo_front.picture?.picture_image, "плейсхолдер тоже должен быть картинкой")
	TEST_ASSERT_EQUAL(source.build_count, 1, "неудачная съёмка тоже кэшируется")

	general_record.get_record_photo("photo_front")
	TEST_ASSERT_EQUAL(source.build_count, 1, "повторное обращение не должно пробовать снять кадр заново")

	var/datum/data/record/orphan_record = new
	TEST_ASSERT_NULL(orphan_record.get_record_photo("photo_front"), "запись без источника не должна ни снимать, ни ронять рантайм")
	TEST_ASSERT_NULL(orphan_record.get_record_image(), "то же самое для locked-стороны записи")

	qdel(photo_front)
	qdel(general_record.fields["photo_side"])

/// Зависший флаг съёмки снимает первый дождавшийся таймаута читатель.
/datum/unit_test/manifest_photo_lazy_stuck_flag_recovers/Run()
	var/mob/living/carbon/human/crewmember = allocate(/mob/living/carbon/human)
	var/datum/record_photo_source/unit_test_counted/source = new(crewmember, null, null)
	source.inflight_timeout = 2
	// Ровно то состояние, которое оставляет убитый посреди съёмки прок.
	source.generated = TRUE
	source.generating = TRUE

	var/started = world.time
	var/icon/first_answer = source.get_photo_icon()
	TEST_ASSERT(world.time - started >= source.inflight_timeout, "Sanity: первый читатель обязан отстоять таймаут ([world.time - started] против [source.inflight_timeout])")
	TEST_ASSERT_NULL(first_answer, "У зависшей съёмки кадра нет - читатель получает null, а не рантайм")
	TEST_ASSERT(!source.generating, "Дождавшийся таймаута читатель обязан снять зависший флаг")
	TEST_ASSERT(source.generated, "Снятие флага не должно перезапускать съёмку")

	started = world.time
	source.get_photo_icon()
	TEST_ASSERT(world.time - started < source.inflight_timeout, "Следующий читатель не должен ждать таймаут заново")
	TEST_ASSERT_EQUAL(source.build_count, 0, "Снятый флаг не должен приводить к повторной съёмке")

/// Съёмок одновременно не больше лимита: читатели, пришедшие пачкой, стоят в очереди.
/datum/unit_test/manifest_photo_lazy_inflight_cap
	var/list/datum/data/record/records = list()
	var/finished_readers = 0
	var/peak_in_flight = 0

/datum/unit_test/manifest_photo_lazy_inflight_cap/proc/read_record_async(datum/data/record/target)
	target.get_record_photo("photo_front")
	finished_readers++

/datum/unit_test/manifest_photo_lazy_inflight_cap/Run()
	var/mob/living/carbon/human/crewmember = allocate(/mob/living/carbon/human)
	var/readers = 3
	TEST_ASSERT_EQUAL(GLOB.record_photos_in_flight, 0, "Sanity: до теста съёмок в полёте нет")
	for(var/i in 1 to readers)
		var/datum/data/record/target = new
		target.fields["name"] = "Cap Subject [i]"
		target.photo_source = new /datum/record_photo_source/unit_test_counted/slow(crewmember, null, null)
		records += target
		INVOKE_ASYNC(src, PROC_REF(read_record_async), target)

	var/deadline = world.time + 10 SECONDS
	while(finished_readers < readers && world.time < deadline)
		peak_in_flight = max(peak_in_flight, GLOB.record_photos_in_flight)
		sleep(1)

	TEST_ASSERT_EQUAL(finished_readers, readers, "Все читатели обязаны дождаться своих кадров")
	TEST_ASSERT(peak_in_flight > 0, "Sanity: съёмка вообще шла")
	TEST_ASSERT(peak_in_flight < readers, "Лимит одновременных съёмок не сработал: пик [peak_in_flight] при [readers] читателях")
	TEST_ASSERT_EQUAL(GLOB.record_photos_in_flight, 0, "Счётчик съёмок в полёте обязан вернуться к нулю")
	for(var/datum/data/record/target as anything in records)
		var/datum/record_photo_source/unit_test_counted/source = target.photo_source
		TEST_ASSERT_EQUAL(source.build_count, 1, "Каждая запись обязана сняться ровно один раз")
		TEST_ASSERT(istype(target.fields["photo_front"], /obj/item/photo), "Каждая запись обязана получить фото")
		qdel(target.fields["photo_front"])
		qdel(target.fields["photo_side"])
	records.Cut()

/// Снапшот внешности догоняет дообутого моба и отпускается после съёмки.
/datum/unit_test/manifest_photo_lazy_snapshot_refresh/Run()
	var/mob/living/carbon/human/crewmember = allocate(/mob/living/carbon/human)
	var/datum/record_photo_source/unit_test_counted/source = new(crewmember, null, null)
	TEST_ASSERT_NOTNULL(source.frozen_appearance, "Sanity: со стоящего видимого моба снапшот снимается")
	var/before = source.frozen_appearance

	crewmember.add_atom_colour("#ff0000", FIXED_COLOUR_PRIORITY)
	TEST_ASSERT(source.snapshot_appearance(crewmember), "Пересъёмка до первого обращения обязана проходить")
	TEST_ASSERT_NOTEQUAL(source.frozen_appearance, before, "Пересъёмка обязана заменить снапшот на актуальную внешность")

	var/datum/data/record/general_record = new
	general_record.fields["name"] = crewmember.real_name
	general_record.photo_source = source
	var/datum/data/record/saved_index = GLOB.data_core.general_by_name[crewmember.real_name]
	GLOB.data_core.general_by_name[crewmember.real_name] = general_record
	crewmember.remove_atom_colour(FIXED_COLOUR_PRIORITY)
	var/refreshed = GLOB.data_core.refresh_manifest_photo_source(crewmember)
	if(saved_index)
		GLOB.data_core.general_by_name[crewmember.real_name] = saved_index
	else
		GLOB.data_core.general_by_name -= crewmember.real_name
	TEST_ASSERT(refreshed, "refresh_manifest_photo_source обязан находить запись по имени и делать пересъёмку")
	TEST_ASSERT_EQUAL(source.frozen_appearance, crewmember.appearance, "После refresh снапшот обязан совпадать с внешностью моба")

	var/obj/item/photo/photo_front = general_record.get_record_photo("photo_front")
	TEST_ASSERT(istype(photo_front), "Sanity: съёмка после пересъёмки работает")
	TEST_ASSERT_NULL(source.frozen_appearance, "После съёмки снапшот внешности обязан отпускаться: кадр в кэше, а снапшот прижимал бы дерево аппирансов весь раунд")
	TEST_ASSERT(!source.snapshot_appearance(crewmember), "После съёмки пересъёмка снапшота не имеет смысла и обязана отказывать")

	qdel(photo_front)
	qdel(general_record.fields["photo_side"])
