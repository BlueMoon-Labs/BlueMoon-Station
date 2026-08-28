/// Иконка-заглушка для оверлея: любая существующая пара (файл, стейт), лишь бы icon() её взял.
#define MUTANT_OVERLAY_TEST_ICON 'icons/effects/effects.dmi'
/// Стейт из неё же. Тот самый, на котором стоит icon_alloc_placeholder, - он точно есть.
#define MUTANT_OVERLAY_TEST_STATE "nothing"
/// Слой заведомо НЕ из OVERLAY_GENITAL_LIST: ветка слоя к предмету теста отношения не имеет.
#define MUTANT_OVERLAY_TEST_LAYER "tail"
/// Сколько раз зовём прок после первого раза, чтобы промах было видно по росту кэша.
#define MUTANT_OVERLAY_TEST_REPEATS 5

/**
 * Кэш оверлеев мутантных частей хранит ИКОНКУ, а не оверлей, и на попадании её отдаёт.
 *
 * ЗАЧЕМ ТЕСТ. use_effect_by_params() клал в GLOB.mutant_overlays_cache готовый
 * /mutable_appearance, а читал его в переменную типа /icon и подставлял в `icon = ...`
 * нового оверлея. Попадание поэтому не просто не экономило работу - оно записывало в поле
 * icon датум оверлея вместо иконки, и клиент рисовал на этом месте что придётся. Ровно так
 * на проде 28.08.2026 и выглядели "случайные спрайты на людях", пропавшие шляпы и чужие
 * текстуры крови.
 *
 * Промах при этом стоил дорого и был почти всегда: icon() на каждый вызов - это НОВАЯ
 * рантайм-иконка, а она уезжает отдельным ресурсом каждому видящему клиенту и живёт у него
 * до конца сессии. Поэтому тест держит инвариант с четырёх сторон: в кэш ложится иконка,
 * причём СНИМОК fcopy_rsc, а не живая рантайм-иконка; повторные вызовы с теми же
 * аргументами кэш не растят; и оверлей на попадании берёт ровно ту иконку, что в кэше лежит.
 */
/datum/unit_test/mutant_overlay_icon_cache/Run()
	// Кэш глобальный и переживает тест, поэтому подменяем его целиком и возвращаем на место:
	// иначе записи теста уехали бы к живым носителям, а чужие записи посчитались бы здесь.
	var/list/saved_cache = GLOB.mutant_overlays_cache
	GLOB.mutant_overlays_cache = list()

	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/datum/overlay_effect/effect = new /datum/overlay_effect/mod_effect
	var/mutable_appearance/accessory = mutable_appearance(MUTANT_OVERLAY_TEST_ICON, MUTANT_OVERLAY_TEST_STATE)
	var/list/overlay_params = list(MUTANT_OVERLAY_TEST_LAYER, effect.color, effect)
	var/cache_key = carrier.generate_accessory_cache_key(accessory, effect)

	var/mutable_appearance/first_overlay = carrier.use_effect_by_params(accessory, overlay_params)
	var/entries_after_first = length(GLOB.mutant_overlays_cache)
	var/cached_entry = GLOB.mutant_overlays_cache[cache_key]

	var/mutable_appearance/last_overlay
	for(var/repeat in 1 to MUTANT_OVERLAY_TEST_REPEATS)
		last_overlay = carrier.use_effect_by_params(accessory, overlay_params)
	var/entries_after_repeats = length(GLOB.mutant_overlays_cache)

	// Снимаем всё, что проверяем, ДО возврата глобалки: после восстановления записи теста
	// в кэше уже нет, и ассерты читали бы чужое состояние.
	var/cached_is_icon = isicon(cached_entry)
	var/cached_is_appearance = istype(cached_entry, /mutable_appearance)
	var/first_icon = first_overlay?.icon
	var/last_icon = last_overlay?.icon

	// Контрольная рантайм-иконка. Живая /icon стрингифицируется в "/icon" - одинаково для
	// любой динамической иконки (на этом свойстве построен разбор ключей в strippable.dm),
	// а снимок fcopy_rsc - это уже ресурс, и текст у него другой. Пара нужна целиком:
	// без контрольного ассерта проверка снимка ниже была бы непроверяемой сама по себе.
	var/icon/control_runtime_icon = icon(MUTANT_OVERLAY_TEST_ICON, MUTANT_OVERLAY_TEST_STATE)
	var/control_text = "[control_runtime_icon]"
	var/cached_text = "[cached_entry]"

	qdel(effect)
	GLOB.mutant_overlays_cache = saved_cache

	TEST_ASSERT_EQUAL(entries_after_first, 1, "первый вызов обязан положить в кэш ровно одну запись, а положил [entries_after_first]")
	TEST_ASSERT(cached_is_icon, "в кэше лежит не иконка - именно из-за этого клиент рисовал на месте мутантной части чужой спрайт")
	TEST_ASSERT(!cached_is_appearance, "в кэш снова кладётся /mutable_appearance вместо иконки")
	TEST_ASSERT_EQUAL(control_text, "/icon", "контрольная рантайм-иконка перестала стрингифицироваться в \"/icon\" - ассерт про снимок ниже потерял смысл, чинить надо оба")
	TEST_ASSERT_NOTEQUAL(cached_text, control_text, "в кэше лежит живая рантайм-иконка, а не снимок fcopy_rsc: такую иконку следующий вызов может поправить на месте, и она рассылается клиентам заново")
	TEST_ASSERT_EQUAL(entries_after_repeats, 1, "[MUTANT_OVERLAY_TEST_REPEATS] повторов с теми же аргументами обязаны быть попаданиями, а кэш вырос до [entries_after_repeats] записей")
	TEST_ASSERT_EQUAL(first_icon, cached_entry, "оверлей первого вызова взял не ту иконку, что легла в кэш")
	TEST_ASSERT_EQUAL(last_icon, cached_entry, "оверлей на попадании обязан брать иконку из кэша, а не строить свою")

#undef MUTANT_OVERLAY_TEST_ICON
#undef MUTANT_OVERLAY_TEST_STATE
#undef MUTANT_OVERLAY_TEST_LAYER
#undef MUTANT_OVERLAY_TEST_REPEATS
