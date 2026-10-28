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

	var/real_latest = changelog_latest_entry_date()
	TEST_ASSERT(sanitize_changelog_date(real_latest), "в настоящем архиве должна находиться свежая дата, получено: [real_latest]")
