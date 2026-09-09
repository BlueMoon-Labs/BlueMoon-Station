/// Датум вида, лежащий в prefs, - это НЕ мусор-однодневка: prefs-датум ckey кладётся в
/// GLOB.preferences_datums (client_procs.dm:541) и из этого списка его никто не убирает до
/// перезапуска мира, так что живёт ровно столько же и его pref_species. Каждый лишний
/// экземпляр - живой мусор на весь раунд, а не churn, который соберёт рефкаунт.
///
/// Перепись датумов раунда 10060 (ноль игроков, ~40-50 отбитых попыток входа за интервал)
/// насчитала 15-21 /datum/species/human за 30-минутный интервал: инициализатор поля
/// pref_species (preferences.dm:192) и load_character() (preferences_savefile.dm) заводили по
/// экземпляру на одну и ту же попытку подключения, и второй сразу становился лишним.
///
/// Инвариант: совпадение типа - тот же экземпляр, несовпадение - новый.
/datum/unit_test/species_prefs_load_reuses_matching_datum
	/// Путь сейвфайла фикстуры: сносится в Destroy(), чтобы прогоны не копили мусор в data/.
	var/fixture_path

/datum/unit_test/species_prefs_load_reuses_matching_datum/Run()
	// Без записи в GLOB.species_list load_character вообще не трогает pref_species, и обе
	// проверки ниже прошли бы вхолостую. Тип сверяем точно: если ключ "human" займёт подтип
	// (подтип без своего id наследует чужой), фикстура сравнивала бы разные типы.
	TEST_ASSERT_EQUAL(GLOB.species_list[SPECIES_HUMAN], /datum/species/human, "Ключ human в GLOB.species_list обязан указывать на /datum/species/human")

	var/datum/preferences/prefs = new
	prefs.load_path("unittestspeciesprefs")
	fixture_path = prefs.path
	TEST_ASSERT_NOTNULL(fixture_path, "Фикстуре нужен путь сейвфайла")

	var/datum/species/default_species = prefs.pref_species
	TEST_ASSERT_NOTNULL(default_species, "Свежий /datum/preferences обязан иметь вид по умолчанию")
	TEST_ASSERT_EQUAL(default_species.type, /datum/species/human, "Вид по умолчанию в prefs - человек")

	TEST_ASSERT(istype(prefs.save_character(bypass_cooldown = TRUE, silent = TRUE), /savefile), "Сейв фикстуры должен пройти")
	TEST_ASSERT(istype(prefs.load_character(bypass_cooldown = TRUE), /savefile), "Загрузка фикстуры должна пройти")
	TEST_ASSERT(prefs.pref_species == default_species, "Загрузка того же вида не должна заводить второй датум вида")

	// Обратная сторона инварианта: чужой тип обязан быть вытеснен. Без этой проверки первая
	// выродилась бы в "load_character просто не трогает pref_species".
	var/datum/species/lizard/stale = new
	prefs.pref_species = stale
	TEST_ASSERT(istype(prefs.load_character(bypass_cooldown = TRUE), /savefile), "Повторная загрузка фикстуры должна пройти")
	TEST_ASSERT(prefs.pref_species != stale, "Сохранённый вид обязан вытеснить чужой экземпляр")
	TEST_ASSERT_EQUAL(prefs.pref_species.type, /datum/species/human, "После загрузки в prefs должен стоять сохранённый вид")

/datum/unit_test/species_prefs_load_reuses_matching_datum/Destroy()
	if(fixture_path)
		fdel(fixture_path)
		fixture_path = null
	return ..()
