/// Тип `/datum/atom_hud` три года был объявлен дважды: живая реализация в
/// `code/_rendering/atom_huds/atom_hud.dm` (списки `hudatoms`/`hudusers`) и мёртвая
/// z-скоупленная копия из апстрима в `code/datums/hud.dm`. У второй вырезали `New()`,
/// поэтому её z-списки навсегда оставались пустыми, `show_to()` падал на
/// индексировании пустого списка, а `hide_from()` молча выходил.
///
/// Очки нанокостюма зовут живой API combo HUD и с 2023 года не выдавали ни одного
/// дата-худа, рантаймя прямо в `equipped()`. Дубль снесён, очки переведены на живой API.
/// Тест держит контракт: очки на глазах дают худы, снятые - забирают.
/datum/unit_test/nanosuit_goggles_grants_data_huds

/datum/unit_test/nanosuit_goggles_grants_data_huds/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/clothing/glasses/nano_goggles/goggles = allocate(/obj/item/clothing/glasses/nano_goggles, run_loc_floor_bottom_left)

	TEST_ASSERT(length(goggles.hudlist), "У очков нанокостюма пустой hudlist - предпосылка теста сломана")

	// Снимок исходного членства: /mob/living/Initialize кладёт живых в часть дата-худов
	// сам, поэтому сравнивать надо дельту, а не абсолютное значение.
	// Ключ - сам худ-датум, а НЕ hud_type: типы худов это числовые дефайны, и `before[15]`
	// на пустом списке это позиционное индексирование, то есть index out of bounds
	var/list/before = list()
	for(var/hud_type in goggles.hudlist)
		var/datum/atom_hud/data_hud = GLOB.huds[hud_type]
		TEST_ASSERT_NOTNULL(data_hud, "Дата-худ [hud_type] не существует")
		before[data_hud] = data_hud.hudusers[wearer] || 0

	wearer.equip_to_slot_or_del(goggles, ITEM_SLOT_EYES)
	TEST_ASSERT_EQUAL(wearer.glasses, goggles, "Очки не надеты - предпосылка теста сломана")

	for(var/hud_type in goggles.hudlist)
		var/datum/atom_hud/data_hud = GLOB.huds[hud_type]
		TEST_ASSERT_EQUAL(data_hud.hudusers[wearer] || 0, before[data_hud] + 1, "Надетые очки не выдали носителю худ [hud_type]")

	// TRAIT_NODROP навешивается при надевании, поэтому снимаем принудительно
	wearer.dropItemToGround(goggles, TRUE)
	TEST_ASSERT_NULL(wearer.glasses, "Очки не снялись - предпосылка теста сломана")

	for(var/hud_type in goggles.hudlist)
		var/datum/atom_hud/data_hud = GLOB.huds[hud_type]
		TEST_ASSERT_EQUAL(data_hud.hudusers[wearer] || 0, before[data_hud], "Снятые очки не забрали у носителя худ [hud_type]")

/// `join_hud` даёт мобу две роли: носитель значка (`hudatoms`, через `add_to_hud`) и
/// зритель (`hudusers`, через `add_hud_to`) - причём вторую только при `self_visible`.
/// Девять из десяти антаг-худов это `hidden`, то есть в `hudusers` их носитель не попадает
/// никогда. `leave_all_antag_huds()` проверял только `hudusers`, поэтому такие значки при
/// переносе разума оставались висеть на прежнем теле до конца смены.
/datum/unit_test/antag_hud_leaves_hidden_huds

/datum/unit_test/antag_hud_leaves_hidden_huds/Run()
	var/mob/living/carbon/human/antagonist = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	antagonist.mind_initialize()
	TEST_ASSERT_NOTNULL(antagonist.mind, "У моба нет разума - предпосылка теста сломана")

	var/datum/atom_hud/antag/hidden_hud = GLOB.huds[ANTAG_HUD_TRAITOR]
	TEST_ASSERT_NOTNULL(hidden_hud, "Худ предателя не существует")
	TEST_ASSERT(!hidden_hud.self_visible, "Худ предателя перестал быть hidden - тест проверяет не тот случай")

	hidden_hud.join_hud(antagonist)
	TEST_ASSERT(antagonist in hidden_hud.hudatoms, "join_hud не сделал моба носителем значка")
	TEST_ASSERT(!hidden_hud.hudusers[antagonist], "hidden-худ не должен делать носителя зрителем - предпосылка теста сломана")

	antagonist.mind.leave_all_antag_huds()
	TEST_ASSERT(!(antagonist in hidden_hud.hudatoms), "leave_all_antag_huds не снял значок скрытого антаг-худа")
	TEST_ASSERT_NULL(antagonist.mind.antag_hud, "leave_all_antag_huds не обнулил ссылку на худ в разуме")
