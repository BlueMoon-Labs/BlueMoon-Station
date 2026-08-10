/**
 * Корень ветки профилей космоса. Сам в каталог не попадает.
 *
 * Станции здесь НЕТ намеренно: её фон закреплён за одним профилем (см. classic).
 * Разнообразие живёт в остальном космосе - на руинах, в ЦК и в гиперпространстве.
 */
/datum/parallax_profile/space
	abstract_type = /datum/parallax_profile/space
	environment_flags = PARALLAX_ENV_SPACE_RUINS | PARALLAX_ENV_SHUTTLE | PARALLAX_ENV_CENTCOM
	// Станция дрейфует. Очень медленно: верхний слой проходит тайл минуты за три,
	// и это ровно та фоновая жизнь, которой сцене не хватало, когда она замирала
	// намертво, стоило игроку остановиться.
	ambient_speed = 2000
	ambient_angle = 15

/**
 * Историческая сцена BlueMoon: три звёздных слоя, Лаваленд с ледяной луной и один
 * необязательный ближний слой.
 *
 * Единственный профиль станционного окружения, и это не лень, а требование игроков:
 * лавовый мир за иллюминатором помечает сектор, в котором висит станция, и по нему
 * ориентируются. Случайная сцена каждый раунд этот ориентир отнимает, поэтому всё
 * разнообразие профилей уехало в остальной космос и в полёт, а станция получила
 * постоянный вид. Разброс внутри профиля (астероиды, газовая взвесь или ничего)
 * остался: сцена не идентична попиксельно, а планета на месте всегда.
 */
/datum/parallax_profile/space/classic
	id = "space_classic"
	name = "Космос"
	environment_flags = PARALLAX_ENV_STATION
	base_layers = list(
		/atom/movable/screen/parallax_layer/space/layer_1,
		/atom/movable/screen/parallax_layer/space/layer_2,
		/atom/movable/screen/parallax_layer/space/layer_3,
	)
	variant_sets = list(
		list(35, /atom/movable/screen/parallax_layer/space/random/asteroids),
		list(35, /atom/movable/screen/parallax_layer/space/random/space_gas),
		list(30),
	)
	static_objects = list(/atom/movable/screen/parallax_layer/space/planet)
	palette = list(COLOR_TEAL, COLOR_GREEN, COLOR_YELLOW, COLOR_CYAN, COLOR_ORANGE, COLOR_PURPLE)
	min_quality = PARALLAX_LOW
	// Половина всего веса автоподбора на станционном z. Разнообразие - смысл
	// профилей, но "обычный космос" обязан оставаться обычным.
	weight = 140

/// Та же звёздная основа, но над ледяной луной вместо газовой взвеси.
/datum/parallax_profile/space/icemoon
	id = "space_icemoon"
	name = "Орбита ледяной луны"
	base_layers = list(
		/atom/movable/screen/parallax_layer/space/layer_1,
		/atom/movable/screen/parallax_layer/space/layer_2,
		/atom/movable/screen/parallax_layer/space/layer_3,
	)
	variant_sets = list(
		list(1, /atom/movable/screen/parallax_layer/space/icemoon),
	)
	min_quality = PARALLAX_LOW
	weight = 12
