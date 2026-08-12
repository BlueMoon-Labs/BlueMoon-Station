/**
 * Слои космоса из чужих кодбаз, приведённые к нашему тайлу 480.
 *
 * Импортировано только то, что попиксельно НЕ совпало с нашим арт-паком:
 * layer1-3 у tgstation, Paradise и BeeStation побайтово наши, `asteroids` и
 * `icemoon` у Shiptest тоже. Полная выкладка - icons/effects/parallax/ATTRIBUTION.md.
 */
/atom/movable/screen/parallax_layer/donor
	icon = 'icons/effects/parallax/space.dmi'

// --- Shiptest: неоновая фиолетовая небула ---------------------------------
// Втрое ярче нашего layer1, поэтому это ЗАМЕНА звёздного набора, а не добавка.

/atom/movable/screen/parallax_layer/donor/shiptest_1
	icon_state = "shiptest_layer1"
	speed = 0.6
	layer = 1
	parallax_intensity = PARALLAX_LOW

/atom/movable/screen/parallax_layer/donor/shiptest_2
	icon_state = "shiptest_layer2"
	speed = 1
	layer = 2
	parallax_intensity = PARALLAX_MED

/atom/movable/screen/parallax_layer/donor/shiptest_3
	icon_state = "shiptest_layer3"
	speed = 1.4
	layer = 3
	parallax_intensity = PARALLAX_HIGH

// --- Shiptest: небо газового гиганта Layenia ------------------------------
// Четыре слоя работают только вместе: горизонт задаёт линию, три яруса облаков
// расходятся по скорости. По отдельности каждый бессмыслен.

/atom/movable/screen/parallax_layer/donor/layenia_horizon
	icon_state = "layeniahorizon"
	blend_mode = BLEND_OVERLAY
	speed = 0.3
	layer = 5
	parallax_intensity = PARALLAX_LOW

/atom/movable/screen/parallax_layer/donor/layenia_1
	icon_state = "layenia1"
	blend_mode = BLEND_OVERLAY
	speed = 0.6
	layer = 6
	parallax_intensity = PARALLAX_MED

/atom/movable/screen/parallax_layer/donor/layenia_2
	icon_state = "layenia2"
	blend_mode = BLEND_OVERLAY
	speed = 1
	layer = 7
	parallax_intensity = PARALLAX_HIGH

/atom/movable/screen/parallax_layer/donor/layenia_3
	icon_state = "layenia3"
	blend_mode = BLEND_OVERLAY
	speed = 1.4
	layer = 8
	parallax_intensity = PARALLAX_INSANE

/// Та же альфа-маска, что у нашего icemoon, но в тёплом песочном.
/// В самом Shiptest этот стейт - сирота, их параллакс его не подключает.
/atom/movable/screen/parallax_layer/donor/whitesands
	icon_state = "whitesands"
	blend_mode = BLEND_OVERLAY
	speed = 1.8
	layer = 3
	parallax_intensity = PARALLAX_HIGH

// --- TauCetiClassic: единственный донор без единого совпадения -------------
// Бирюзовое поле, полупрозрачная дымка (средняя альфа 17 - приём уникальный)
// и редкие звёзды. Лучшие швы во всей выборке.

/atom/movable/screen/parallax_layer/donor/tauceti_1
	icon_state = "tauceti_layer1"
	speed = 0.6
	layer = 1
	parallax_intensity = PARALLAX_LOW

/atom/movable/screen/parallax_layer/donor/tauceti_2
	icon_state = "tauceti_layer2"
	speed = 1
	layer = 2
	parallax_intensity = PARALLAX_MED

/// У TauCeti верхний слой идёт на 1.2, а не на 1.4 - так задумал их художник.
/atom/movable/screen/parallax_layer/donor/tauceti_3
	icon_state = "tauceti_layer3"
	speed = 1.2
	layer = 3
	parallax_intensity = PARALLAX_HIGH

// --- Paradise: планеты враждебных миров ------------------------------------

/// Окружение то же, что у нашей планеты, и по той же причине - см. space/planet.
/atom/movable/screen/parallax_layer/donor/planet
	blend_mode = BLEND_OVERLAY
	layer_mode = PARALLAX_MODE_STATIC
	center_x = -100
	center_y = -100
	speed = 1
	layer = 30
	base_scale = 2.5
	spawn_jitter_min = 100
	spawn_jitter_max = 130
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS | PARALLAX_ENV_CENTCOM

/atom/movable/screen/parallax_layer/donor/planet/lava
	icon_state = "planet_lava"

/atom/movable/screen/parallax_layer/donor/planet/plasma
	icon_state = "planet_plasma"

/atom/movable/screen/parallax_layer/donor/planet/chasm
	icon_state = "planet_chasm"

/// BeeStation: единственная анимированная планета в выборке, пять кадров по 1 с.
/// Пять кадров 480x480 - это 4.6 МБ RAM у клиента, что приемлемо; тридцать шесть
/// кадров goonstation были бы уже 65 МБ, поэтому те не взяты.
/atom/movable/screen/parallax_layer/donor/planet/animated
	icon_state = "planet_animated"
