/// Архив ченджлога: список месяцев, свежая дата для меток «новое», белый список get_month.
/datum/unit_test/changelog_archive

/datum/unit_test/changelog_archive/Run()
	var/dir = "data/unit_test_changelog/"
	fdel(dir)
	rustg_file_write("2026-09-30:\n  Someone:\n  - rscadd: old\n", "[dir]2026-09.yml")
	rustg_file_write("2026-10-01:\n  A:\n  - rscadd: first\n2026-10-15:\n  B:\n  - bugfix: '2026-10-31: не дата'\n2026-10-07:\n  C:\n  - tweak: middle\n", "[dir]2026-10.yml")
	rustg_file_write("not a month", "[dir]notes.txt")

	var/list/months = changelog_archive_months(dir)
	TEST_ASSERT_EQUAL(months.Join(","), "2026-10,2026-09", "месяцы должны идти свежими первыми и без посторонних файлов")
	TEST_ASSERT_EQUAL(changelog_latest_entry_date(dir), "2026-10-15", "свежая дата берётся по ключам дней, а не по тексту записей и не по порядку в файле")

	var/datum/changelog/changelog = new(dir)
	TEST_ASSERT_NULL(changelog.get_month_asset("../../config/admins"), "get_month не должен отдавать файл вне архива")
	TEST_ASSERT_NULL(changelog.get_month_asset("2026-11"), "get_month не должен заводить ассет под несуществующий месяц")
	TEST_ASSERT(!("2026-11" in changelog.changelog_items), "отказ не должен оседать в кэше ассетов")
	TEST_ASSERT_NOTNULL(changelog.get_month_asset("2026-09"), "месяц из архива должен отдаваться")
	var/list/static_data = changelog.ui_static_data(null)
	TEST_ASSERT_EQUAL(static_data["last_seen"], "", "без игрока last_seen пустой")
	qdel(changelog)
	fdel(dir)

	TEST_ASSERT_EQUAL(changelog_latest_entry_date("data/unit_test_changelog_missing/"), "", "пустой архив даёт пустую дату")

	TEST_ASSERT_EQUAL(sanitize_changelog_date("2026-10-28"), "2026-10-28", "корректная дата проходит")
	TEST_ASSERT_EQUAL(sanitize_changelog_date("d41d8cd98f00b204e9800998ecf8427e"), "", "старый хэш не должен считаться датой")
	TEST_ASSERT_EQUAL(sanitize_changelog_date(0), "", "число не дата")

	// Тело PR с GitHub приходит с CRLF.
	var/crlf = "[ascii2text(13)]\n"
	var/body = "## Описание[crlf]текст[crlf]## Changelog[crlf][crlf]:cl: Someone[crlf]add: Новая механика[crlf]fix: fixed a few things[crlf]messzone без двоеточия[crlf]balance:   Баланс с пробелами  [crlf]/:cl:[crlf]хвост: не из блока[crlf]"
	var/list/changes = changelog_parse_cl(body)
	TEST_ASSERT_EQUAL(length(changes), 2, "из :cl: берутся строки тег: текст без заглушек шаблона и без текста вне блока")
	TEST_ASSERT_EQUAL(changes[1]["type"], "add", "тег отдаётся как есть, алиасы разбирает окно")
	TEST_ASSERT_EQUAL(changes[1]["text"], "Новая механика", "кириллица в тексте записи читается")
	TEST_ASSERT_EQUAL(changes[2]["text"], "Баланс с пробелами", "пробелы по краям текста срезаются")
	TEST_ASSERT_EQUAL(length(changelog_parse_cl("без блока")), 0, "без :cl: записей нет")
	TEST_ASSERT_EQUAL(length(changelog_parse_cl(null)), 0, "пустое тело PR не ломает разбор")

	var/datum/tgs_revision_information/test_merge/open_tm = new
	open_tm.number = 4265
	open_tm.title = "Открытый PR"
	open_tm.author = "DuLL-FoX"
	open_tm.body = body
	var/datum/tgs_revision_information/test_merge/secret_tm = new
	secret_tm.number = 4266
	secret_tm.title = "\[s\] Секретный PR"
	secret_tm.author = "Someone"
	var/list/visible = changelog_testmerge_entries(list(open_tm, secret_tm))
	TEST_ASSERT_EQUAL(length(visible), 1, "секретный тест-мердж скрыт от игрока")
	TEST_ASSERT_EQUAL(visible[1]["number"], 4265, "открытый тест-мердж виден")
	TEST_ASSERT_EQUAL(length(visible[1]["changes"]), 2, "у тест-мерджа есть записи его :cl:")
	TEST_ASSERT_EQUAL(length(changelog_testmerge_entries(list(open_tm, secret_tm), TRUE)), 2, "админ видит и секретный")
	TEST_ASSERT_EQUAL(length(changelog_testmerge_entries(null)), 0, "без TGS тест-мерджей нет")

	var/real_latest = changelog_latest_entry_date()
	TEST_ASSERT(sanitize_changelog_date(real_latest), "в настоящем архиве должна находиться свежая дата, получено: [real_latest]")
