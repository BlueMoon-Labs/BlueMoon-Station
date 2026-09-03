/**
 * Профили на скайбоксах.
 *
 * Шесть фонов Polaris - это шесть КАРТИНОК, а не шесть сцен: механика у них
 * одна, меняется только изображение. Поэтому они лежат вариантами одного
 * профиля, а не шестью почти одинаковыми объявлениями. Вариант выбирается один
 * раз на z, так что сектор у всех на уровне один и тот же и держится весь раунд.
 */
/datum/parallax_profile/space/deep
	id = "deep_space"
	name = "Дальний космос"
	base_layers = list(/atom/movable/screen/parallax_layer/skybox/stars)
	variant_sets = list(
		list(10, /atom/movable/screen/parallax_layer/skybox/space_0),
		list(10, /atom/movable/screen/parallax_layer/skybox/space_1),
		list(10, /atom/movable/screen/parallax_layer/skybox/space_2),
		list(10, /atom/movable/screen/parallax_layer/skybox/space_3),
		list(10, /atom/movable/screen/parallax_layer/skybox/space_4),
		list(10, /atom/movable/screen/parallax_layer/skybox/space_5),
		list(10, /atom/movable/screen/parallax_layer/skybox/space_6),
		list(10, /atom/movable/screen/parallax_layer/skybox/nebula),
	)
	min_quality = PARALLAX_LOW
	source = "Polaris / CEV-Eris"
	weight = 18

/// Секторные фоны Aurora. Отобраны по яркости кромки: взяты только те, чей край
/// сливается с чёрным космосом, иначе по периметру экрана видна рамка.
/datum/parallax_profile/space/aurora_sector
	id = "aurora_sector"
	name = "Секторный фон"
	base_layers = list(/atom/movable/screen/parallax_layer/skybox/stars)
	variant_sets = list(
		list(10, /atom/movable/screen/parallax_layer/skybox/sector/badlands),
		list(10, /atom/movable/screen/parallax_layer/skybox/sector/puddle_worlds),
		list(10, /atom/movable/screen/parallax_layer/skybox/sector/sparring_sea),
		list(10, /atom/movable/screen/parallax_layer/skybox/sector/crescent_expanse),
	)
	min_quality = PARALLAX_LOW
	source = "Aurora"
	weight = 14

/// Сектор под покраску: один обесцвеченный фрактал плюс палитра дают любой оттенок.
/datum/parallax_profile/space/tinted_sector
	id = "tinted_sector"
	name = "Окрашенный сектор"
	skybox = /atom/movable/screen/parallax_layer/skybox/dyable
	base_layers = list(/atom/movable/screen/parallax_layer/skybox/stars)
	palette = list("#4a2f6e", "#2f5c6e", "#6e4a2f", "#2f6e42", "#6e2f4a")
	min_quality = PARALLAX_LOW
	source = "Polaris"
	weight = 10

/**
 * Калибровочный профиль. В автоподбор не входит: ставится вручную, чтобы глазами
 * выверить центрирование, масштаб и запас скайбокса при нестандартном client.view.
 */
/datum/parallax_profile/space/diagnostic
	id = "diagnostic"
	name = "Калибровочная мишень"
	skybox = /atom/movable/screen/parallax_layer/skybox/diagnostic
	// Мишень обязана стоять неподвижно, иначе по ней нечего выверять.
	ambient_speed = 0
	min_quality = PARALLAX_LOW
	source = "Polaris"
	weight = 0
