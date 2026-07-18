// Фото манифеста генерируется отложенной очередью: manifest_inject() больше не строит
// второго персонажа (copy_to + экипировка джоба на манекене + два getFlatIcon) синхронно
// в тике латеджойна - каждый заход игрока стоил станции 200-400мс фриза, и половина
// этой цены была именно фотография для записи, которую никто не смотрит первые секунды.
// Записи создаются сразу с плейсхолдером, очередь доклеивает настоящие фото тиком позже.

/// Очередь фото: enqueue ставит работу, дренаж наполняет поля записей настоящими фото.
/datum/unit_test/manifest_photo_deferred/Run()
	var/mob/living/carbon/human/crewmember = allocate(/mob/living/carbon/human)
	var/datum/data/record/general_record = new
	var/datum/data/record/locked_record = new

	GLOB.data_core.enqueue_manifest_photo(crewmember, null, null, general_record, locked_record)
	TEST_ASSERT(length(GLOB.data_core.pending_photo_jobs), "enqueue_manifest_photo должен ставить работу в очередь")

	GLOB.data_core.process_manifest_photo_queue()
	TEST_ASSERT_EQUAL(length(GLOB.data_core.pending_photo_jobs), 0, "дренаж должен опустошать очередь фото")

	var/obj/item/photo/photo_front = general_record.fields["photo_front"]
	TEST_ASSERT(istype(photo_front), "после дренажа в general-записи должно лежать фото анфас")
	TEST_ASSERT_NOTNULL(photo_front.picture?.picture_image, "фото анфас должно содержать изображение")
	var/obj/item/photo/photo_side = general_record.fields["photo_side"]
	TEST_ASSERT(istype(photo_side), "после дренажа в general-записи должно лежать фото в профиль")
	TEST_ASSERT_NOTNULL(photo_side.picture?.picture_image, "фото в профиль должно содержать изображение")
	TEST_ASSERT_NOTNULL(locked_record.fields["image"], "locked-запись должна получить изображение для клонирования")

/// Удалённый до дренажа моб не должен ронять очередь: работа тихо пропускается.
/datum/unit_test/manifest_photo_deferred_deleted_mob/Run()
	var/mob/living/carbon/human/crewmember = new(run_loc_floor_bottom_left)
	var/datum/data/record/general_record = new
	var/datum/data/record/locked_record = new

	GLOB.data_core.enqueue_manifest_photo(crewmember, null, null, general_record, locked_record)
	qdel(crewmember)
	GLOB.data_core.process_manifest_photo_queue()

	TEST_ASSERT_EQUAL(length(GLOB.data_core.pending_photo_jobs), 0, "очередь должна опустошаться и при удалённом мобе")
	TEST_ASSERT_NULL(locked_record.fields["image"], "удалённый моб не должен получать фото задним числом")
