/// REF() и \ref[] - индексы в таблицах BYOND, и они переиспользуются после сборки мусора.
/// Кэш иконок, ключёванный такой ссылкой, поэтому отдаёт картинку чужого объекта: ровно так
/// на проде выглядели "спрайты несуществующей одежды" в панели осмотренного турфа.
/// Тесты держат инвариант: запись кэша обязана доказывать, кому она принадлежит.

/// Запись statpanel_sent_icons под переиспользованным REF не должна считаться отправленной.
/datum/unit_test/statpanel_icon_ref_reuse

/datum/unit_test/statpanel_icon_ref_reuse/Run()
	var/obj/item/original = allocate(/obj/item/reagent_containers/glass/beaker)
	var/obj/item/impostor = allocate(/obj/item/reagent_containers/glass/beaker)
	var/original_ref = REF(original)

	var/list/sent_icons = list()
	var/list/entry = new /list(2)
	entry[1] = "asset/url/original.png"
	entry[2] = WEAKREF(original)
	sent_icons[original_ref] = entry

	TEST_ASSERT(statpanel_icon_already_sent(sent_icons, original_ref, original), \
		"Иконка, отправленная для этого самого атома, обязана засчитываться как отправленная")

	// Тот же ключ, другой атом - именно это и происходит, когда BYOND отдаёт освободившийся
	// слот REF следующему объекту. Раньше проверка была на непустоту значения и проходила.
	TEST_ASSERT(!statpanel_icon_already_sent(sent_icons, original_ref, impostor), \
		"Чужой атом под тем же REF не должен получать иконку предыдущего владельца")

	// Записи из старого формата (просто строка с URL) доверия не заслуживают.
	var/list/legacy_icons = list()
	legacy_icons[original_ref] = "asset/url/legacy.png"
	TEST_ASSERT(!statpanel_icon_already_sent(legacy_icons, original_ref, original), \
		"Запись без владельца не должна засчитываться за отправленную иконку")

	TEST_ASSERT(!statpanel_icon_already_sent(sent_icons, "[REF(impostor)]", impostor), \
		"Отсутствующий ключ не должен засчитываться за отправленную иконку")

	qdel(original)
	TEST_ASSERT(!statpanel_icon_already_sent(sent_icons, original_ref, original), \
		"Удалённый владелец обязан обнулять попадание: его слот вот-вот достанется другому")

/// icon2base64html кэширует только файловые иконки: у рантайм-иконки ссылка нестабильна.
/datum/unit_test/bicon_cache_skips_runtime_icons

/datum/unit_test/bicon_cache_skips_runtime_icons/Run()
	var/obj/item/subject = allocate(/obj/item/reagent_containers/glass/beaker)

	var/file_key = "[subject.icon]:[subject.icon_state]"
	GLOB.bicon_cache -= file_key

	var/file_html = icon2base64html(subject)
	TEST_ASSERT_NOTNULL(file_html, "Файловая иконка обязана отдавать html")
	TEST_ASSERT_NOTNULL(GLOB.bicon_cache[file_key], \
		"Файловая иконка стабильно ключуется своим dmi-путём и обязана кэшироваться")

	// Рантайм-иконка: стрингифицируется в "/icon" для любой динамической, а REF() на неё
	// достаётся следующей иконке после сборки мусора. Такой ключ кэшировать нельзя.
	var/icon/runtime_icon = icon(subject.icon, subject.icon_state)
	TEST_ASSERT_EQUAL("[runtime_icon]", "/icon", \
		"Контрольная рантайм-иконка обязана стрингифицироваться в \"/icon\"")
	subject.icon = runtime_icon

	var/runtime_html = icon2base64html(subject)
	TEST_ASSERT_NOTNULL(runtime_html, "Рантайм-иконка обязана отдавать html и без кэша")

	// Инвариант ключа, а не размера кэша: BYOND может подменить присвоенную рантайм-иконку
	// ресурсом в rsc, и тогда запись законна. Незаконна ровно одна форма ключа - REF, потому
	// что его слот достаётся следующей иконке после сборки мусора.
	for(var/cache_key in GLOB.bicon_cache)
		TEST_ASSERT(findtextEx(cache_key, "\[0x") != 1, \
			"Ключ кэша иконок не должен строиться из REF: [cache_key]")
