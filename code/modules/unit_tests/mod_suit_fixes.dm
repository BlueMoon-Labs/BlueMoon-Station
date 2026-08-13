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
	var/obj/item/clothing/suit/mod/chestplate = mod.chestplate
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

// Обычная одежда обязана и дальше укрепляться - фикс не должен убить сам механизм.
/datum/unit_test/armor_kit_still_reinforces_clothing/Run()
	var/obj/item/clothing/suit/hooded/wintercoat/coat = allocate(/obj/item/clothing/suit/hooded/wintercoat)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/armorkit/durathread/vest/kit = allocate(/obj/item/armorkit/durathread/vest)

	kit.afterattack(coat, user, TRUE)

	TEST_ASSERT(coat.reinforced, "An armor kit must still reinforce ordinary outer clothing")
