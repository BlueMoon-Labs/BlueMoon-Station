// Регрессы по багрепортам на МОД от 17.07.2026. Тесты названы по симптому,
// который видел игрок, а не по внутреннему механизму.

// "Перетаскивание сумки на мод не работает - вещи выпадают на пол"
//
// Хранилище МОД получает компонентом, а типом остаётся обычным /obj/item.
// get_dumping_location() у /obj отдаёт турф, и вся сумка уезжала на пол вместо
// отсеков костюма: правом на "меня можно наполнить" владел только тип
// /obj/item/storage, хотя storage_contents_dump_act() рядом уже давно
// диспатчится по наличию компонента.
/datum/unit_test/mod_storage_accepts_dumped_container/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/mod/module/storage/module = allocate(/obj/item/mod/module/storage)
	mod.install(module)

	TEST_ASSERT_NOTNULL(mod.GetComponent(/datum/component/storage), \
		"test premise: installing the storage module must give the MOD a storage component")
	TEST_ASSERT_EQUAL(mod.get_dumping_location(), mod, \
		"A MOD with a storage module must swallow a dumped container itself instead of spilling it on the floor")

	// обратная сторона: костюм без модуля обязан остаться "неналивным"
	var/obj/item/mod/control/bare = allocate(/obj/item/mod/control)
	TEST_ASSERT_EQUAL(bare.get_dumping_location(), get_turf(bare), \
		"A MOD without a storage module must keep dumping onto the floor")

// "Вытащил модуль хранилища - вещи остались в моде, но без доступа к ним"
//
// on_uninstall() убивал компонент, ничего не выгрузив: предметы так и лежали
// в contents костюма, а UI к ним больше не открывался.
/datum/unit_test/mod_storage_module_releases_contents/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/mod/module/storage/module = allocate(/obj/item/mod/module/storage)
	mod.install(module)

	var/datum/component/storage/storage = mod.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(storage, "test premise: installing the storage module must give the MOD a storage component")

	var/obj/item/stored = allocate(/obj/item/screwdriver)
	TEST_ASSERT(storage.handle_item_insertion(stored, TRUE), "test premise: the item must fit into the MOD storage")
	TEST_ASSERT_EQUAL(stored.loc, mod, "test premise: an inserted item must actually live inside the MOD")

	mod.uninstall(module)

	TEST_ASSERT_NOTEQUAL(stored.loc, mod, \
		"Pulling the storage module must not strand items inside the MOD with no way to reach them")
	TEST_ASSERT_NULL(mod.GetComponent(/datum/component/storage), \
		"Pulling the storage module must take the storage component with it")

// "Рампартка на надетых частях ломает изоляцию МОДа - поддувает и замерзаешь"
//
// Набор брони присваивал (не сливал) восемь защитных переменных с прототипа
// жилета. Запечатывание костюма восстанавливает только clothing_flags через
// visor_flags, поэтому min_cold_protection_temperature и body_parts_covered
// оставались жилетными навсегда.
/datum/unit_test/armor_kit_refuses_mod_parts/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/clothing/mod_part/suit/chestplate = mod.mod_parts[MOD_PART_CHEST]
	TEST_ASSERT_NOTNULL(chestplate, "test premise: a MOD must build itself a chestplate")

	var/covered_before = chestplate.body_parts_covered
	var/flags_before = chestplate.clothing_flags
	var/cold_before = chestplate.min_cold_protection_temperature

	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/armorkit/durathread/vest/kit = allocate(/obj/item/armorkit/durathread/vest)
	kit.afterattack(chestplate, user, TRUE)

	TEST_ASSERT(!chestplate.reinforced, "An armor kit must not reinforce a MOD part")
	TEST_ASSERT_EQUAL(chestplate.body_parts_covered, covered_before, \
		"An armor kit must not shrink the coverage of a MOD part")
	TEST_ASSERT_EQUAL(chestplate.clothing_flags, flags_before, \
		"An armor kit must not strip the clothing flags of a MOD part")
	TEST_ASSERT_EQUAL(chestplate.min_cold_protection_temperature, cold_before, \
		"An armor kit must not strip the cold protection of a MOD part - sealing only restores clothing_flags")
	TEST_ASSERT(!QDELETED(kit), "An armor kit rejected by a MOD part must not be consumed")

// Регресс по раунду 10137: части МОДа составляли 44 харддела из 127 за смену -
// половину всего бюджета заморозки от SSgarbage (15.0 с из 29.6 с).
//
// mod_parts это alist с числовыми ключами MOD_PART_*, а вычитание из alist идёт
// ПО КЛЮЧУ. Destroy() костюма передавал в `mod_parts -= ...` саму часть, то есть
// значение, и не удалял ничего: alist продолжал держать уже qdel-нутую часть, та
// проваливала окно GC и уходила в харддел. Батарея в лог хардделов не попадала
// только потому, что её чистил QDEL_NULL(MOD_CELL) - этот макрос разворачивается
// в mod_parts[MOD_PART_CELL] и работает как lvalue.
/datum/unit_test/mod_destroy_releases_its_parts/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/list/parts = mod.get_mod_parts(include_cell = FALSE)
	TEST_ASSERT(length(parts), "test premise: a MOD must build itself some parts")

	qdel(mod)

	for(var/obj/item/clothing/mod_part/part as anything in parts)
		TEST_ASSERT(QDELETED(part), \
			"Destroying a MOD must actually destroy [part.type], not just detach it")
		TEST_ASSERT(!mod.is_mod_part(part), \
			"A destroyed MOD must not keep holding [part.type] in mod_parts - that reference is what sent every part to hard delete")

// Пин на семантику alist: именно она сломала Destroy выше. Если однажды alist
// начнёт вычитать по значению, этот тест упадёт и правку можно будет упростить.
/datum/unit_test/mod_parts_are_keyed_not_valued/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/clothing/mod_part/head/helmet = mod.mod_parts[MOD_PART_HEAD]
	TEST_ASSERT_NOTNULL(helmet, "test premise: a MOD must build itself a helmet")

	mod.mod_parts -= helmet
	TEST_ASSERT(mod.is_mod_part(helmet), \
		"Subtracting a part by value must stay a no-op on an alist - if this changed, revisit /obj/item/mod/control/Destroy")

	TEST_ASSERT(mod.clear_mod_part(helmet), "clear_mod_part must report that it found the part")
	TEST_ASSERT(!mod.is_mod_part(helmet), "clear_mod_part must actually drop the part out of mod_parts")
	TEST_ASSERT(!mod.clear_mod_part(helmet), "clear_mod_part must report a miss the second time round")
	// Отцепленный шлем костюм при своём qdel уже не увидит - убираем сами, иначе тест
	// оставляет в нулевом пространстве шлем с mod на удалённый костюм (ровно тот
	// харддел, ради которого он написан).
	qdel(helmet)

// Перебор alist отдаёт КЛЮЧИ, поэтому `for(var/obj/item/part in mod_parts)` молча
// не исполнялся ни разу: фильтр по типу отбрасывал числа. На этом стояли проверка
// "выдвиньте элементы МОДа", сокрытие частей при обыске и пружинная ловушка.
/datum/unit_test/mod_part_iteration_yields_parts/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)

	var/naive_hits = 0
	for(var/obj/item/part in mod.mod_parts)
		naive_hits++
	TEST_ASSERT_EQUAL(naive_hits, 0, \
		"test premise: iterating the alist directly must keep yielding keys, not parts")

	var/list/parts = mod.get_mod_parts(include_cell = FALSE)
	TEST_ASSERT(length(parts), "get_mod_parts must return the actual parts")
	for(var/part in parts)
		TEST_ASSERT(istype(part, /obj/item/clothing/mod_part), \
			"get_mod_parts must return parts, got [part]")

// Обычная одежда обязана и дальше укрепляться - фикс не должен убить сам механизм.
/datum/unit_test/armor_kit_still_reinforces_clothing/Run()
	var/obj/item/clothing/suit/hooded/wintercoat/coat = allocate(/obj/item/clothing/suit/hooded/wintercoat)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/armorkit/durathread/vest/kit = allocate(/obj/item/armorkit/durathread/vest)

	kit.afterattack(coat, user, TRUE)

	TEST_ASSERT(coat.reinforced, "An armor kit must still reinforce ordinary outer clothing")
