/// Регрессии по прод-раундам 9823/9824 (2026-07-29): hard delete'ы из qdel.log
/// и рантаймы, которые ломали цепочку Destroy.
///
/// Числа в комментариях к тестам - реальные замеры из логов раунда:
/// строка "## GC: ... не собрался (warnfail, ~120с, внешних ссылок: N)".

/datum/unit_test/harddel_9824_base
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/harddel_9824_base/Run()
	return

/// Устройство самоактуализации складывало траумы старого мозга в список, менял вид
/// (copy_to -> regenerate_organs), а старый мозг в Destroy делает QDEL_LIST(traumas).
/// Дальше этот же список qdel-нутых траум клался в НОВЫЙ мозг: owner у них null,
/// поэтому handle_brain_damage вызывал on_life на мёртвом датуме каждые 2 секунды
/// (раунд 9824: 104 рантайма "Cannot read null.status_traits" с 08:34:09 до конца
/// раунда), а brain.traumas оставался единственным держателем - hard delete
/// /datum/brain_trauma/mild/phobia (2 шт.) и /datum/brain_trauma/severe/pacifism.
/datum/unit_test/self_actualization_keeps_traumas_alive
	parent_type = /datum/unit_test/harddel_9824_base

/// Снятые с мозга траумы обязаны пережить удаление этого мозга.
/datum/unit_test/self_actualization_keeps_traumas_alive/proc/detach_survives_brain_deletion()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	patient.gain_trauma(/datum/brain_trauma/severe/pacifism, TRAUMA_RESILIENCE_LOBOTOMY)

	var/obj/machinery/self_actualization_device/device = allocate(/obj/machinery/self_actualization_device, run_loc_floor_bottom_left)
	var/list/detached = device.detach_traumas(patient)
	TEST_ASSERT_EQUAL(length(detached), 1, "detach_traumas не снял единственную трауму")

	var/obj/item/organ/brain/old_brain = patient.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT(!length(old_brain.traumas), "Траума осталась на старом мозге и уйдёт в QDEL_LIST")

	var/datum/brain_trauma/saved = detached[1]
	qdel(old_brain)
	TEST_ASSERT(!QDELETED(saved), "Снятая траума всё равно погибла вместе со старым мозгом")
	TEST_ASSERT_NULL(saved.owner, "У снятой траумы обязан быть пустой owner до возврата")
	return saved

/// Возврат обязан выдать траумe живого владельца, иначе on_life рантаймит вечно.
/datum/unit_test/self_actualization_keeps_traumas_alive/proc/restore_reattaches_owner(datum/brain_trauma/saved)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/machinery/self_actualization_device/device = allocate(/obj/machinery/self_actualization_device, run_loc_floor_bottom_left)

	device.restore_traumas(patient, list(saved))
	TEST_ASSERT(!QDELETED(saved), "restore_traumas удалил трауму, которой не было дубля")
	TEST_ASSERT_EQUAL(saved.owner, patient, "restore_traumas не вернул трауме владельца")

	var/obj/item/organ/brain/new_brain = patient.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT(saved in new_brain.traumas, "Траума не попала в список нового мозга")
	TEST_ASSERT_EQUAL(saved.brain, new_brain, "У траумы не проставлен новый мозг")

	// on_life на живом владельце обязан пройти без "Cannot read null.status_traits"
	patient.handle_brain_damage()

/// Дубль того же типа (квирк завёл трауму заново) возвращать нельзя.
/datum/unit_test/self_actualization_keeps_traumas_alive/proc/restore_drops_duplicates()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/machinery/self_actualization_device/device = allocate(/obj/machinery/self_actualization_device, run_loc_floor_bottom_left)
	patient.gain_trauma(/datum/brain_trauma/severe/pacifism, TRAUMA_RESILIENCE_LOBOTOMY)

	var/datum/brain_trauma/severe/pacifism/stale = new
	stale.resilience = TRAUMA_RESILIENCE_LOBOTOMY
	var/list/record = target_record(stale, "дубль траумы из устройства самоактуализации")
	device.restore_traumas(patient, list(stale))

	var/obj/item/organ/brain/brain = patient.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT_EQUAL(length(brain.traumas), 1, "restore_traumas продублировал трауму того же типа")
	return record

/datum/unit_test/self_actualization_keeps_traumas_alive/Run()
	begin_isolated_gc()
	var/datum/brain_trauma/saved = detach_survives_brain_deletion()
	restore_reattaches_owner(saved)

	var/list/duplicate = restore_drops_duplicates()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(duplicate)

/// cure_trauma_type ждёт ТИП; квирки фобии и немоты отдавали ему экземпляр, поэтому
/// istype(BT, экземпляр) всегда был FALSE - траума переживала снятие квирка, а поле
/// квирка оставалось её единственным держателем.
/datum/unit_test/trauma_quirk_removal_releases_trauma
	parent_type = /datum/unit_test/harddel_9824_base

/datum/unit_test/trauma_quirk_removal_releases_trauma/Run()
	begin_isolated_gc()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	patient.add_quirk(/datum/quirk/phobia)

	//саму трауму заводит post_add, а его /datum/quirk/New вешает отложенным
	//таймером и только при spawn_effects - в тесте зовём напрямую
	var/datum/quirk/phobia/quirk = locate() in patient.roundstart_quirks
	TEST_ASSERT_NOTNULL(quirk, "Квирк фобии не выдался мобу")
	quirk.post_add()

	var/obj/item/organ/brain/brain = patient.getorganslot(ORGAN_SLOT_BRAIN)
	var/datum/brain_trauma/mild/phobia/granted = brain.has_trauma_type(/datum/brain_trauma/mild/phobia)
	TEST_ASSERT_NOTNULL(granted, "Квирк фобии не выдал трауму")

	var/list/record = target_record(granted, "траума квирка фобии")
	patient.remove_quirk(/datum/quirk/phobia)
	TEST_ASSERT_NULL(brain.has_trauma_type(/datum/brain_trauma/mild/phobia), "Снятие квирка не вылечило фобию")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// Кровяная клякса на окне: /obj/effect/decal/Initialize отвечает INITIALIZE_HINT_QDEL
/// на турфе без пола (NeverShouldHaveComeHere), то есть new() возвращает уже удалённый
/// атом. Прежний код звал ему forceMove (рантайм "doMove qdel-нутого ... в the
/// reinforced window") и клал в vis_contents окна - мёртвая декаль висела там до конца
/// раунда. Раунд 9824: /obj/effect/decal/cleanable/blood/splatter/over_window,
/// 1 внешняя ссылка, единственный warnfail с уликой "в vis_contents у
/// /obj/structure/window/reinforced/fulltile (1 держателей)".
/datum/unit_test/window_hitsplatter_skips_merged_decal
	parent_type = /datum/unit_test/harddel_9824_base

/datum/unit_test/window_hitsplatter_skips_merged_decal/Run()
	begin_isolated_gc()
	var/turf/window_turf = run_loc_floor_bottom_left
	//окно у края пола: кровь летит с безопорного турфа, декаль на нём не живёт
	var/turf/source_turf = get_step(window_turf, EAST)
	var/source_original_type = source_turf.type
	source_turf = source_turf.ChangeTurf(/turf/open/space/basic)
	TEST_ASSERT(isgroundlessturf(source_turf), "Не удалось подготовить турф без пола")

	var/obj/structure/window/reinforced/fulltile/window = allocate(/obj/structure/window/reinforced/fulltile, window_turf)

	var/obj/effect/decal/cleanable/blood/hitsplatter/splatter = new(window_turf)
	splatter.blood_DNA = list("A+" = "A+")
	splatter.prev_loc = source_turf

	var/before = length(window.vis_contents)
	splatter.land_on_window(window)

	TEST_ASSERT_EQUAL(length(window.vis_contents), before, "Мертворождённая декаль всё равно попала в vis_contents окна")
	for(var/atom/movable/shown as anything in window.vis_contents)
		TEST_ASSERT(!QDELETED(shown), "В vis_contents окна лежит удалённый атом")

	source_turf.ChangeTurf(source_original_type)

/// /datum/component/swarming/Destroy правил swarm_members прямо во время обхода
/// этого же списка: индекс сдвигался и каждый второй сосед оставался со ссылкой
/// на удалённый компонент. Легион-бруды (swarming = TRUE) стакаются пачками, так
/// что стая из трёх и больше - штатный случай, а не край.
/datum/unit_test/swarming_teardown_releases_every_member
	parent_type = /datum/unit_test/harddel_9824_base

/datum/unit_test/swarming_teardown_releases_every_member/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/leaver = allocate(/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion, floor)
	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/first = allocate(/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion, floor)
	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/second = allocate(/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion, floor)

	var/datum/component/swarming/leaving_swarm = leaver.GetComponent(/datum/component/swarming)
	var/datum/component/swarming/first_swarm = first.GetComponent(/datum/component/swarming)
	var/datum/component/swarming/second_swarm = second.GetComponent(/datum/component/swarming)
	TEST_ASSERT_NOTNULL(leaving_swarm, "У легион-бруда нет swarming-компонента")

	leaving_swarm.join_swarm(leaver, first)
	leaving_swarm.join_swarm(leaver, second)
	TEST_ASSERT_EQUAL(length(leaving_swarm.swarm_members), 2, "Стая не собралась из двух соседей")

	qdel(leaving_swarm)
	TEST_ASSERT(!(leaving_swarm in first_swarm.swarm_members), "Первый сосед удержал ссылку на распавшийся компонент")
	TEST_ASSERT(!(leaving_swarm in second_swarm.swarm_members), "Второй сосед удержал ссылку на распавшийся компонент")

/// Экраны объёмного хранилища переиспользуются через пул компонента storage.
/// _recycle_ui_objects сбрасывал предмет у коробки, но не у вложенного holder'а,
/// поэтому уехавшая в пул коробка держала последний показанный предмет до конца
/// раунда. Ровно этот класс и виден в раундах 9823/9824: осколки (14), прутья (6),
/// кабель (6), швы, конденсаторы, платы, еда - каждый с одной внешней ссылкой
/// и без единой улики (loc пуст, таймеров нет, из vis_contents Destroy вычистил).
/datum/unit_test/storage_pool_releases_recycled_item
	parent_type = /datum/unit_test/harddel_9824_base

/datum/unit_test/storage_pool_releases_recycled_item/Run()
	begin_isolated_gc()
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, run_loc_floor_bottom_left)
	var/datum/component/storage/storage = bag.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(storage, "У рюкзака нет компонента хранилища")

	var/obj/item/stack/rods/stored = new(bag)
	var/atom/movable/screen/storage/volumetric_box/center/box = storage._acquire_volumetric_box(null, stored)
	box.set_pixel_size(64, null)
	TEST_ASSERT_NOTNULL(box.holder, "set_pixel_size не завёл holder для предмета")
	TEST_ASSERT_EQUAL(box.holder.our_item, stored, "holder не получил предмет")

	storage._recycle_ui_objects(list(box))
	TEST_ASSERT_NULL(box.our_item, "Коробка уехала в пул с предметом")
	TEST_ASSERT_NULL(box.holder.our_item, "holder уехал в пул с предметом")

	// Второй контур защиты: даже если экран не переработали, удаление предмета
	// обязано само отпустить ссылку. Тип берём отличный от прутьев - второй стек
	// того же типа схлопнулся бы с первым прямо в конструкторе.
	var/obj/item/shard/second = new(bag)
	box.set_item(second)
	box.holder.set_item(second)
	TEST_ASSERT_EQUAL(box.our_item, second, "Коробка не приняла живой предмет")
	var/list/record = target_record(second, "предмет, удалённый прямо в открытом хранилище")
	qdel(second)
	TEST_ASSERT_NULL(box.our_item, "Коробка удержала удалённый предмет")
	TEST_ASSERT_NULL(box.holder.our_item, "holder удержал удалённый предмет")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// ДИАГНОСТИКА + регрессия: легион-бруд - топ-1 по времени hard delete в раундах
/// 9823/9824 (82 харддела, 17.7 секунды, 768 qdel'ов). У 73 из 91 warnfail ровно
/// одна внешняя ссылка и ни одной улики: не в loc, без живых таймеров, без
/// неснятых подписок, не в vis_contents, не бакнут.
/// scan_holders пишет полный скан держателей в data/logs/<раунд>/harddels.log.
/datum/unit_test/legion_brood_death_releases_mob
	parent_type = /datum/unit_test/harddel_9824_base

/// Бруд, рождённый хайвлордом штатным OpenFire, и убитый в бою.
/datum/unit_test/legion_brood_death_releases_mob/proc/killed_in_combat()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/asteroid/hivelord/legion/host = allocate(/mob/living/simple_animal/hostile/asteroid/hivelord/legion, floor)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(floor, EAST))

	host.GiveTarget(prey)
	host.ranged_cooldown = 0
	host.OpenFire(prey)

	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/brood = locate(/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion) in floor
	TEST_ASSERT_NOTNULL(brood, "Хайвлорд-легион не породил бруда через OpenFire")

	brood.GiveTarget(prey)
	brood.AttackingTarget()
	var/list/record = target_record(brood, "легион-бруд, убитый в бою")
	brood.death()
	return record

/// Бруд, вселившийся в тело: infest() зовёт qdel(src) изнутри Life.
/datum/unit_test/legion_brood_death_releases_mob/proc/killed_by_infesting()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, floor)
	victim.death()

	var/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/advanced/brood = allocate(/mob/living/simple_animal/hostile/asteroid/hivelordbrood/legion/advanced, floor)
	var/list/record = target_record(brood, "легион-бруд, ушедший в infest")
	brood.infest(victim)

	//вселившийся легион уносит тело внутрь себя; разбираем его тут же, пока
	//жертва жива, иначе разбор теста удалит тело первым
	//именно тот легион, что забрал жертву: на турфе уже стоит хайвлорд из
	//соседнего сценария, и locate() по типу нашёл бы не того
	var/mob/living/simple_animal/hostile/asteroid/hivelord/legion/host = victim.loc
	TEST_ASSERT(istype(host), "infest не поднял легиона на месте жертвы")
	qdel(host)
	TEST_ASSERT_EQUAL(victim.loc, floor, "Разбор легиона не вернул тело на турф")
	return record

/datum/unit_test/legion_brood_death_releases_mob/Run()
	begin_isolated_gc()
	var/list/combat = killed_in_combat()
	var/list/infested = killed_by_infesting()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(combat)
	assert_soft_collected(infested)
