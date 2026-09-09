/// Нагрузка диспенсера не имеет права возить книгу рецептов. Раньше книга ездила
/// внутри сообщения tgui: 560 КБ - 1.17 МБ за раз, и url_encode(json_encode())
/// просил у 32-битного DreamDaemon непрерывный кусок в разы больше - на таких
/// аллокациях процесс умирал (раунды 9941/9948). Теперь книга уезжает JSON-ассетом,
/// а в нагрузке остаются имя файла и счётчик по категориям.
/datum/unit_test/chem_dispenser_payload_size
	requires_full_map = FALSE

/// Статика без книги - это список реагентов и мелочь; порог с запасом, но заведомо
/// ниже веса самой книги, чтобы её возврат в нагрузку не прошёл незамеченным.
#define DISPENSER_PAYLOAD_LIMIT (100 * 1024)

/datum/unit_test/chem_dispenser_payload_size/Run()
	var/obj/machinery/chem_dispenser/dispenser = allocate(/obj/machinery/chem_dispenser)
	var/list/static_data = dispenser.ui_static_data(null)

	var/encoded = json_encode(static_data)
	log_test("DISPENSER PAYLOAD: [num2text(length(encoded), 12)] Б json")
	TEST_ASSERT(length(encoded) < DISPENSER_PAYLOAD_LIMIT, "статика диспенсера весит [num2text(length(encoded), 12)] Б при пороге [num2text(DISPENSER_PAYLOAD_LIMIT, 12)] Б - книга рецептов вернулась в нагрузку?")
	TEST_ASSERT_NULL(static_data["gameRecipes"], "книга рецептов уехала в нагрузку tgui, а должна ехать JSON-ассетом")

	// Вместо книги в нагрузке - имя файла ассета, а сам файл зарегистрирован в транспорте.
	var/asset_file_name = static_data["gameRecipesAsset"]
	TEST_ASSERT(istext(asset_file_name) && length(asset_file_name), "в статике нет имени файла книги рецептов")
	TEST_ASSERT_NOTNULL(dispenser.cached_dispenser_recipes_asset, "ассет книги рецептов не создался")
	TEST_ASSERT_EQUAL(asset_file_name, "[dispenser.cached_dispenser_recipes_asset.name].json", "имя файла в статике не совпало с именем ассета")
	TEST_ASSERT_NOTNULL(SSassets.cache[asset_file_name], "файл книги рецептов не зарегистрирован в транспорте ассетов")

	// Книга непустая, и счётчик на ярлыке вкладки сходится с ней по числу рецептов.
	TEST_ASSERT(length(dispenser.cached_dispenser_game_recipes), "кэш рецептов пуст - ассет собран ни из чего")
	var/counted = 0
	for(var/category in static_data["gameRecipeCounts"])
		counted += static_data["gameRecipeCounts"][category]
	TEST_ASSERT_EQUAL(counted, length(dispenser.cached_dispenser_game_recipes), "счётчик по категориям не сходится с числом рецептов в книге")

	// Второй диспенсер с тем же набором реагентов делит готовый файл, а не кодирует свой.
	var/obj/machinery/chem_dispenser/second = allocate(/obj/machinery/chem_dispenser)
	TEST_ASSERT_EQUAL(second.ensure_recipes_asset(), dispenser.cached_dispenser_recipes_asset, "диспенсеры с одним набором реагентов не делят ассет книги")

#undef DISPENSER_PAYLOAD_LIMIT
