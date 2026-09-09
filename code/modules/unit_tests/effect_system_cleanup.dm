/// Химдым и пена держат химию в `chemholder` - голом `/obj`, у которого
/// `reagents.my_atom` смотрит обратно на него же. Это ссылочный цикл, а рефкаунт BYOND
/// циклы не разбирает никогда: разорвать его может только `Destroy()`, то есть `qdel`
/// самой системы. Вызывающий код `qdel` не звал ни в одном из ~48 мест создания -
/// систему заводили локальной переменной, дёргали `set_up()`/`start()` и бросали, -
/// поэтому каждый пуск дыма или пены оставлял в мире навсегда голый `/obj` плюс
/// `/datum/reagents` с содержимым. В переписи прода (раунды 10050/10052/10054, 100-130
/// игроков) число голых `/obj` росло на +122..+644 за каждый 25-минутный интервал и не
/// убыло ни разу.
///
/// Лечение - `autocleanup` у этих двух типов: система убирает себя сама, как только
/// отдала реагенты рождённому эффекту. Тесты ниже держат обе половины контракта:
/// одноразовые системы уходят вместе со своим носителем, а переиспользуемые (те, что
/// живут в переменной объекта и получают `start()` многократно) - остаются жить.
/datum/unit_test/effect_system_chem_smoke_self_cleanup

/datum/unit_test/effect_system_chem_smoke_self_cleanup/Run()
	var/obj/item/reagent_containers/glass/beaker/source = allocate(/obj/item/reagent_containers/glass/beaker)
	source.reagents.add_reagent(/datum/reagent/iron, 20)
	TEST_ASSERT(source.reagents.total_volume > 0, "Ёмкость не набрала реагентов - предпосылка теста сломана")

	var/datum/effect_system/smoke_spread/chem/smoke = new
	var/obj/holder = smoke.chemholder
	TEST_ASSERT_NOTNULL(holder, "Химдым не завёл chemholder - предпосылка теста сломана")
	TEST_ASSERT_NOTNULL(holder.reagents, "У chemholder нет ёмкости реагентов - предпосылка теста сломана")

	// radius 0: дым не расползается по соседним турфам, вся проверка остаётся на своём
	// тайле. silent: иначе set_up() шлёт message_admins на каждый прогон тестов.
	smoke.set_up(source.reagents, 0, run_loc_floor_bottom_left, silent = TRUE)
	TEST_ASSERT(holder.reagents.total_volume > 0, "Химия не доехала до chemholder - предпосылка теста сломана")

	smoke.start()

	// Ни одного сна до конца проверки: start() зовёт qdel синхронно, ждать нечего.
	var/obj/effect/particle_effect/smoke/chem/spawned = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(spawned, "start() не родил облако дыма")
	TEST_ASSERT(spawned.reagents.total_volume > 0, "Химия не доехала от chemholder до облака - передача сломана")

	TEST_ASSERT(QDELETED(smoke), "Система химдыма пережила start() - брошенный экземпляр утечёт")
	TEST_ASSERT(QDELETED(holder), "chemholder химдыма пережил start() - голый /obj остался в мире навсегда")
	TEST_ASSERT_NULL(smoke.chemholder, "Destroy() не отпустил chemholder")
	TEST_ASSERT_NULL(holder.reagents, "Цикл chemholder <-> reagents не разорван - ёмкость реагентов утечёт")

/datum/unit_test/effect_system_foam_self_cleanup

/datum/unit_test/effect_system_foam_self_cleanup/Run()
	var/obj/item/reagent_containers/glass/beaker/source = allocate(/obj/item/reagent_containers/glass/beaker)
	source.reagents.add_reagent(/datum/reagent/iron, 20)
	TEST_ASSERT(source.reagents.total_volume > 0, "Ёмкость не набрала реагентов - предпосылка теста сломана")

	var/datum/effect_system/foam_spread/foam = new
	var/obj/holder = foam.chemholder
	TEST_ASSERT_NOTNULL(holder, "Пена не завела chemholder - предпосылка теста сломана")
	TEST_ASSERT_NOTNULL(holder.reagents, "У chemholder нет ёмкости реагентов - предпосылка теста сломана")

	// amt 2 даёт amount = round(sqrt(1), 1) = 1: минимальный разлив, при котором start()
	// не делит объём на ноль.
	foam.set_up(2, run_loc_floor_bottom_left, source.reagents)
	TEST_ASSERT(holder.reagents.total_volume > 0, "Химия не доехала до chemholder - предпосылка теста сломана")

	foam.start()

	var/obj/effect/particle_effect/foam/spawned = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(spawned, "start() не родил пену")
	TEST_ASSERT(spawned.reagents.total_volume > 0, "Химия не доехала от chemholder до пены - передача сломана")

	TEST_ASSERT(QDELETED(foam), "Система пены пережила start() - брошенный экземпляр утечёт")
	TEST_ASSERT(QDELETED(holder), "chemholder пены пережил start() - голый /obj остался в мире навсегда")
	TEST_ASSERT_NULL(foam.chemholder, "Destroy() не отпустил chemholder")
	TEST_ASSERT_NULL(holder.reagents, "Цикл chemholder <-> reagents не разорван - ёмкость реагентов утечёт")

/// Обратная половина контракта. Бесхимийные системы дыма живут в переменных объектов
/// (`/obj/vehicle/sealed/mecha.smoke_system`, дымовая граната, танцпол дьявола) и получают
/// `start()` многократно за жизнь владельца. Самоуборка не должна расползтись на них:
/// удалённая под владельцем система - это рантайм на следующем пуске.
/datum/unit_test/effect_system_reusable_smoke_survives_start

/datum/unit_test/effect_system_reusable_smoke_survives_start/Run()
	var/datum/effect_system/smoke_spread/smoke = new
	TEST_ASSERT(!smoke.autocleanup, "Бесхимийный дым включил самоуборку - переиспользуемые системы сломаются")

	// radius 0 - дым рождается, но не расползается: проверяем жизнь системы, а не спред.
	smoke.set_up(0, run_loc_floor_bottom_left)
	smoke.start()
	TEST_ASSERT(!QDELETED(smoke), "Переиспользуемая система дыма удалилась после первого start()")

	smoke.start()
	TEST_ASSERT(!QDELETED(smoke), "Переиспользуемая система дыма удалилась после повторного start()")

	qdel(smoke)

/// `autocleanup` у базового класса снимала систему только через `decrement_total_effect()`,
/// то есть только если хотя бы один эффект успел родиться. `do_sparks()` от источника вне
/// турфа (location == null) не рождает ни одного: счётчик остаётся нулём, таймер на
/// уменьшение никто не заводит, и система, обещавшая убрать себя, висит до конца раунда.
/datum/unit_test/effect_system_autocleanup_without_effects

/datum/unit_test/effect_system_autocleanup_without_effects/Run()
	var/datum/effect_system/spark_spread/homeless = new
	homeless.autocleanup = TRUE
	homeless.set_up(3, FALSE, run_loc_floor_bottom_left)
	// Источник вне турфа воспроизводим прямой записью поля, а не set_up(..., null):
	// так проверка не зависит от того, что вернёт get_turf() от null.
	homeless.location = null

	homeless.start()
	TEST_ASSERT_EQUAL(homeless.total_effects, 0, "Без турфа не должно родиться ни одного эффекта")
	TEST_ASSERT(QDELETED(homeless), "Система с autocleanup осталась жить, не создав ни одного эффекта")

	// Рабочий путь трогать нельзя: пока эффекты живы, система нужна им для уменьшения
	// счётчика, и уборка обязана дождаться decrement_total_effect().
	var/datum/effect_system/spark_spread/sparks = new
	sparks.autocleanup = TRUE
	sparks.set_up(1, FALSE, run_loc_floor_bottom_left)

	sparks.start()
	// INVOKE_ASYNC это spawn(-1): колбек крутится синхронно до своего первого сна, а
	// total_effects++ в generate_effect() стоит до sleep(5) - значит счётчик уже финальный.
	TEST_ASSERT_EQUAL(sparks.total_effects, 1, "Эффект не родился - предпосылка теста сломана")
	TEST_ASSERT(!QDELETED(sparks), "Система с живым эффектом убралась раньше времени")
