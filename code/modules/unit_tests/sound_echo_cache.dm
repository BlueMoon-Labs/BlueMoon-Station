/**
 * Кэш списка эха: один список на пару (envdry, envwet), а не по списку на слушателя.
 *
 * Список S.echo строился заново внутри playsound_local(), то есть на КАЖДОГО слушателя
 * каждого позиционного звука, хотя оба меняющихся слота приходят аргументами вызова и у
 * всех слушателей одного playsound() одинаковые. Переписи этих списков не видно: список
 * не датум, /datum/New() на нём не срабатывает, в глобальных списках его нет - поэтому
 * контракт держится тестом, а не строкой лога.
 *
 * Проверяется ровно то, на чём стоит безопасность общего списка: содержимое по паре,
 * тождество возвращаемого списка и предел роста кэша. Если кто-нибудь вернёт мутацию
 * S.echo[3]/S.echo[4] (закомментированный tg-блок реверба), первый же ассерт содержимого
 * поплывёт у всех звуков разом, а не в одном месте.
 */
/datum/unit_test/sound_echo_cache
	requires_full_map = FALSE
	/// Снимок кэша до теста: тест заведомо заполняет его мусором сверх предела, и оставлять
	/// этот мусор следующим тестам (и живому раунду в CI-мире) нельзя.
	var/list/saved_cache

/datum/unit_test/sound_echo_cache/Run()
	saved_cache = GLOB.sound_echo_cache
	GLOB.sound_echo_cache = list()

	// Дефолтная пара из сигнатуры playsound_local(): envwet = -10000, envdry = 0.
	var/list/first = sound_echo_for(0, -10000)
	TEST_ASSERT_EQUAL(length(first), 18, "список эха обязан быть из восемнадцати слотов - BYOND читает его позиционно")
	TEST_ASSERT_EQUAL(first[1], 0, "первый слот обязан нести envdry")
	TEST_ASSERT_EQUAL(first[3], -10000, "третий слот обязан нести envwet")
	TEST_ASSERT_EQUAL(first[14], 1, "четырнадцатый слот - константа реверба, а не аргумент")
	TEST_ASSERT_EQUAL(first[15], 1, "пятнадцатый слот - константа реверба, а не аргумент")
	TEST_ASSERT_EQUAL(first[16], 1, "шестнадцатый слот - константа реверба, а не аргумент")

	// Ради чего всё и делалось: второй вызов с той же парой обязан отдать ТОТ ЖЕ список,
	// а не равный ему. Равенство здесь ничего не доказало бы - аллокация уже случилась.
	var/list/again = sound_echo_for(0, -10000)
	TEST_ASSERT(first == again, "повторный вызов с той же парой построил новый список - кэш не работает")

	// Пара, которую подставляет audiovisual_redirect (envwet = max(0, envwet), envdry = -10000).
	var/list/redirected = sound_echo_for(-10000, 0)
	TEST_ASSERT(redirected != first, "разные пары обязаны давать разные списки")
	TEST_ASSERT_EQUAL(redirected[1], -10000, "первый слот обязан нести envdry вызова")
	TEST_ASSERT_EQUAL(redirected[3], 0, "третий слот обязан нести envwet вызова")
	TEST_ASSERT(sound_echo_for(-10000, 0) == redirected, "вторая пара не закэширована")

	// Пары различаются ПОРЯДКОМ аргументов, а не множеством значений: ключ обязан их
	// различать, иначе звук с ручным ревербом получил бы чужое эхо.
	TEST_ASSERT(sound_echo_for(0, -10000) != sound_echo_for(-10000, 0), "ключ кэша не различает порядок аргументов")

	// Предел роста. Две пары уже лежат, добиваем заведомо больше остатка квоты.
	var/list/overflow_first
	for(var/i in 1 to SOUND_ECHO_CACHE_MAX + 8)
		var/list/built = sound_echo_for(i, -i)
		TEST_ASSERT_EQUAL(built[1], i, "список сверх предела обязан нести свои значения, а не чужие")
		TEST_ASSERT_EQUAL(built[3], -i, "список сверх предела обязан нести свои значения, а не чужие")
		if(i == SOUND_ECHO_CACHE_MAX + 8)
			overflow_first = built
	TEST_ASSERT_EQUAL(length(GLOB.sound_echo_cache), SOUND_ECHO_CACHE_MAX, "кэш обязан остановиться ровно на пределе")
	// Последняя пара под предел не попала, значит повторный вызов обязан дать НОВЫЙ список -
	// это и есть доказательство, что кэш перестал расти, а не начал отдавать чужое.
	TEST_ASSERT(sound_echo_for(SOUND_ECHO_CACHE_MAX + 8, -(SOUND_ECHO_CACHE_MAX + 8)) != overflow_first, "кэш продолжил расти за пределом")

/datum/unit_test/sound_echo_cache/Destroy()
	// Уборка в Destroy(), а не в хвосте Run(): провалившийся TEST_ASSERT выходит из Run()
	// немедленно и оставил бы кэш забитым мусором до конца прогона.
	if(saved_cache)
		GLOB.sound_echo_cache = saved_cache
		saved_cache = null
	return ..()
