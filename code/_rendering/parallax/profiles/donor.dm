/**
 * Профили, собранные из донорского арта под наш тайл 480.
 * Источники и лицензии - icons/effects/parallax/ATTRIBUTION.md.
 */

/// Неоновая фиолетовая небула Shiptest. Это ЗАМЕНА звёздного набора: их layer1
/// втрое ярче нашего, и поверх классики он бы просто засветил экран.
/datum/parallax_profile/space/shiptest_neon
	id = "shiptest_neon"
	name = "Неоновая небула"
	base_layers = list(
		/atom/movable/screen/parallax_layer/donor/shiptest_1,
		/atom/movable/screen/parallax_layer/donor/shiptest_2,
		/atom/movable/screen/parallax_layer/donor/shiptest_3,
	)
	variant_sets = list(
		list(50, /atom/movable/screen/parallax_layer/space/random/space_gas),
		list(50),
	)
	palette = list(COLOR_PURPLE, COLOR_CYAN, COLOR_TEAL)
	source = "Shiptest"
	weight = 8

/// Бирюзовое поле TauCeti: единственный донор, где ни один стейт не совпал с нашим.
/// Средний слой у них - полупрозрачная дымка (альфа 17), это и даёт глубину.
/datum/parallax_profile/space/tauceti
	id = "tauceti_deep"
	name = "Глубокий космос Tau Ceti"
	base_layers = list(
		/atom/movable/screen/parallax_layer/donor/tauceti_1,
		/atom/movable/screen/parallax_layer/donor/tauceti_2,
		/atom/movable/screen/parallax_layer/donor/tauceti_3,
	)
	variant_sets = list(
		list(30, /atom/movable/screen/parallax_layer/space/random/asteroids),
		list(70),
	)
	source = "TauCetiClassic"
	weight = 10

/// Песчаная луна вместо ледяной: та же альфа-маска, что у icemoon, в тёплом тоне.
/datum/parallax_profile/space/whitesands
	id = "space_whitesands"
	name = "Орбита песчаной луны"
	base_layers = list(
		/atom/movable/screen/parallax_layer/space/layer_1,
		/atom/movable/screen/parallax_layer/space/layer_2,
		/atom/movable/screen/parallax_layer/space/layer_3,
	)
	variant_sets = list(
		list(1, /atom/movable/screen/parallax_layer/donor/whitesands),
	)
	source = "Shiptest"
	weight = 10

// ---------------------------------------------------------------------------
// Орбиты враждебных миров
// ---------------------------------------------------------------------------

/**
 * Общая часть орбитальных профилей: звёздный фон плюс один крупный мир.
 *
 * Гиперпространство исключено на уровне профиля, а не только слоя. Мир - это всё,
 * чем орбитальный профиль отличается от классического космоса, и там, где слой с
 * ним отсеивается окружением, автоподбор выбирал бы между пятью одинаковыми
 * звёздными полями.
 */
/datum/parallax_profile/space/orbit
	abstract_type = /datum/parallax_profile/space/orbit
	environment_flags = PARALLAX_ENV_SPACE_RUINS | PARALLAX_ENV_CENTCOM
	base_layers = list(
		/atom/movable/screen/parallax_layer/space/layer_1,
		/atom/movable/screen/parallax_layer/space/layer_2,
		/atom/movable/screen/parallax_layer/space/layer_3,
	)
	source = "Paradise"

/datum/parallax_profile/space/orbit/lava
	id = "orbit_lava"
	name = "Орбита лавового мира"
	static_objects = list(/atom/movable/screen/parallax_layer/donor/planet/lava)
	// Лаваленд служит ориентиром только станционного сектора. Профиль оставлен
	// для явного админского выбора, но вне станции случайно больше не выпадает.
	weight = 0

/datum/parallax_profile/space/orbit/plasma
	id = "orbit_plasma"
	name = "Орбита плазменного мира"
	static_objects = list(/atom/movable/screen/parallax_layer/donor/planet/plasma)
	weight = 5

/datum/parallax_profile/space/orbit/chasm
	id = "orbit_chasm"
	name = "Орбита мёртвого мира"
	static_objects = list(/atom/movable/screen/parallax_layer/donor/planet/chasm)
	weight = 5

/datum/parallax_profile/space/orbit/animated
	id = "orbit_animated"
	name = "Орбита живого мира"
	static_objects = list(/atom/movable/screen/parallax_layer/donor/planet/animated)
	source = "BeeStation"
	weight = 5

/**
 * Процедурная планета: диск собирается из обесцвеченных масок и красится в
 * рантайме, поэтому две станции никогда не висят над одинаковым миром.
 */
/datum/parallax_profile/space/orbit/generated
	id = "orbit_generated"
	name = "Орбита неизвестного мира"
	static_objects = list(/atom/movable/screen/parallax_layer/planet_generated)
	source = "Aurora + Polaris"
	weight = 14

/**
 * Досовременный фон SS13. Один составной профиль, а не пятнадцать фонов:
 * мигалки лежат оверлеями на базовом стейте.
 *
 * Автоподбором не выбирается - это осознанная стилизация, а не случайность.
 *
 * Дрейфа нет намеренно: у этого фона своя жизнь - четырёхкадровые мигалки с
 * рассинхронизированными периодами, ради них он и берётся.
 */
/datum/parallax_profile/space/legacy
	id = "legacy_tg"
	name = "Классика (до параллакса)"
	base_layers = list(/atom/movable/screen/parallax_layer/legacy)
	ambient_speed = 0
	min_quality = PARALLAX_LOW
	source = "tgstation"
	weight = 0
