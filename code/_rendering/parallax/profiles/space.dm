/// Корень ветки профилей космоса. Сам в каталог не попадает.
/datum/parallax_profile/space
	abstract_type = /datum/parallax_profile/space
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS | PARALLAX_ENV_SHUTTLE | PARALLAX_ENV_CENTCOM
	// Станция дрейфует. Очень медленно: верхний слой проходит тайл минуты за три,
	// и это ровно та фоновая жизнь, которой сцене не хватало, когда она замирала
	// намертво, стоило игроку остановиться.
	ambient_speed = 2000
	ambient_angle = 15

/**
 * Историческая сцена BlueMoon: три звёздных слоя, планета и один необязательный
 * ближний слой. Держит подавляющий вес автоподбора - именно так станция
 * выглядела до перехода на профили, и именно так она должна выглядеть чаще всего.
 */
/datum/parallax_profile/space/classic
	id = "space_classic"
	name = "Космос"
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

/// Та же сцена, но станция висит над ледяной луной вместо газовой взвеси.
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
