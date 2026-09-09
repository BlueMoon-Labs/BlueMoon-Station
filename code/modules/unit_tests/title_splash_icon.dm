/**
 * Сплеш-экран заводится поштучно на каждого клиента: на старте раунда всем сразу, в
 * SStitle.Shutdown() ещё раз всем. Присваивание датума /icon в atom.icon каждый раз
 * заставляет BYOND расплющивать изменяемый битмап заставки в ресурс, поэтому сплеш берёт
 * готовую .rsc-ссылку. Откат на сам /icon обязан работать: заставку правят через VV.
 */

/// В обычном раунде ссылка на .rsc собрана инициализацией, и сплеш обязан брать ЕЁ.
/datum/unit_test/title_splash_prefers_rsc_source/Run()
	TEST_ASSERT_NOTNULL(SStitle.icon_source, "Инициализация обязана оставить .rsc-ссылку на заставку")
	TEST_ASSERT_EQUAL(title_splash_icon(FALSE), SStitle.icon_source, "Сплеш обязан брать .rsc-ссылку, а не датум /icon")

/// VV подменил заставку, ссылку пересобрать не успели - сплеш обязан показать хоть что-то,
/// а не уйти пустым.
/datum/unit_test/title_splash_falls_back_to_icon/Run()
	var/restore_source = SStitle.icon_source
	SStitle.icon_source = null

	var/fallback = title_splash_icon(FALSE)

	SStitle.icon_source = restore_source

	TEST_ASSERT_EQUAL(fallback, SStitle.icon, "Без .rsc-ссылки сплеш обязан откатиться на сам /icon")

/// Прошлой заставки может не быть вовсе (первый раунд после рестарта хоста): сплеш
/// сервер-хопа тогда обязан получить null и удалить себя, а не показать текущую заставку.
/datum/unit_test/title_splash_previous_is_separate/Run()
	var/restore_icon = SStitle.previous_icon
	var/restore_source = SStitle.previous_icon_source
	SStitle.previous_icon = null
	SStitle.previous_icon_source = null

	var/previous = title_splash_icon(TRUE)

	SStitle.previous_icon = restore_icon
	SStitle.previous_icon_source = restore_source

	TEST_ASSERT_NULL(previous, "Без прошлой заставки сплеш сервер-хопа не должен подставлять текущую")

/// Сеттер - единственная точка записи: правка через VV обязана двигать ОБА поля разом,
/// иначе турф покажет новую заставку, а сплеш - старую.
/datum/unit_test/title_set_icon_keeps_source_in_sync/Run()
	var/icon/restore_icon = SStitle.icon
	var/restore_source = SStitle.icon_source

	SStitle.set_title_icon(null)
	var/cleared_source = SStitle.icon_source
	var/cleared_icon = SStitle.icon

	SStitle.icon = restore_icon
	SStitle.icon_source = restore_source

	TEST_ASSERT_NULL(cleared_icon, "Сеттер обязан записать переданную иконку")
	TEST_ASSERT_NULL(cleared_source, "Снятая заставка обязана снять и .rsc-ссылку, иначе сплеш покажет прежнюю")
