// Тесты держателей ссылок на /obj/item/mail. Профиль спайков раунда 2026-07-11:
// 44 харддела /obj/item/mail по ~460мс за 7 минут (полный ref-скан мира на каждый del()).
// Каждый тест ассертит конкретного держателя напрямую, без прогона очередей SSgarbage
// (счётчики сбора при нулевых таймаутах флачат, см. тесты gc_rewrite).

/// Ищет активный таймер SStimer, чей коллбек держит target.
/// Длинные таймеры живут в second_queue, короткие - в кольцевых цепочках bucket_list.
/proc/find_timer_holding(datum/target)
	for(var/datum/timedevent/timer as anything in SStimer.second_queue)
		if(timer.callBack?.object == target)
			return timer
	for(var/datum/timedevent/bucket_head in SStimer.bucket_list)
		var/datum/timedevent/node = bucket_head
		do
			if(node.callBack?.object == target)
				return node
			node = node.next
		while(node && node != bucket_head)
	return null

/// Вскрытие конверта взводит 7-минутный таймер самоликвидации. GC-конвейер до харддела
/// (softcheck + warnfail + harddel) короче 7 минут, поэтому конверт, удалённый раньше
/// своего таймера (кнопка ликвидации, мусорка), гарантированно хардделился: коллбек
/// таймера держал жёсткую ссылку. Destroy обязан снимать таймер.
/datum/unit_test/mail_open_timer_released_on_destroy/Run()
	var/mob/living/carbon/human/opener = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/mail/envelope = allocate(/obj/item/mail, run_loc_floor_bottom_left)

	envelope.open(opener)
	TEST_ASSERT(envelope.opened, "Envelope did not open")
	TEST_ASSERT_NOTNULL(find_timer_holding(envelope), "Premise broken: opening mail must arm the self-destruct timer")

	allocated -= envelope
	qdel(envelope)
	TEST_ASSERT_NULL(find_timer_holding(envelope), "Self-destruct timer still holds a hard reference to the destroyed envelope")

/// drop_all_mails обязан вычищать список mails: после Alt+Click/поломки автомат
/// иначе вечно держит ссылки на все выброшенные письма - каждое из них при
/// последующем удалении (истечение срока, ликвидация) уходит в харддел.
/datum/unit_test/mailmat_drop_all_releases_refs/Run()
	var/obj/machinery/mailmat/dispenser = allocate(/obj/machinery/mailmat, run_loc_floor_bottom_left)
	var/obj/item/mail/envelope = allocate(/obj/item/mail, dispenser)
	dispenser.mails += envelope

	dispenser.drop_all_mails()

	TEST_ASSERT_EQUAL(envelope.loc, get_turf(dispenser), "Envelope was not dropped to the dispenser's turf")
	TEST_ASSERT(!(envelope in dispenser.mails), "Dispenser still holds a reference to the dropped envelope in its mails list")

/// delete_obsolete_mails удалял записи внутри for-in по тому же списку: удаление
/// сдвигает следующий элемент под итератор, и тот пропускается. Все просроченные
/// письма обязаны вычищаться за один проход.
/datum/unit_test/mail_obsolete_sweep_clears_all_expired/Run()
	var/obj/item/mail/first = allocate(/obj/item/mail, run_loc_floor_bottom_left)
	var/obj/item/mail/second = allocate(/obj/item/mail, run_loc_floor_bottom_left)

	var/list/saved_sealed = SSmail.sealed_mails
	SSmail.sealed_mails = list()
	SSmail.register_mail(first)
	SSmail.register_mail(second)
	SSmail.sealed_mails[first] = world.time - 1
	SSmail.sealed_mails[second] = world.time - 1

	SSmail.delete_obsolete_mails()
	var/leftovers = length(SSmail.sealed_mails)
	SSmail.sealed_mails = saved_sealed

	TEST_ASSERT_EQUAL(leftovers, 0, "Expired mail survived a delete_obsolete_mails sweep (in-place removal skips the next list entry)")
