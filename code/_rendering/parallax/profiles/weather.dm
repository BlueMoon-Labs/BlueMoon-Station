/**
 * Профили космической погоды и планетарных явлений.
 *
 * Событийные профили держат weight = 0: они не должны выпадать раунду просто так,
 * их ставит событие через SSparallax.set_profile() под своим токеном.
 *
 * Явление, которое приходит В НАШ сектор, сохраняет за собой планету: оно меняет
 * небо, но не переносит станцию куда-то ещё, а лавовый мир за иллюминатором - это
 * метка сектора, по которой игрок понимает, где он. Планета лежит на слое 30, выше
 * всех ярусов Eris (0.5, 2 и 3), поэтому она видна сквозь явление.
 *
 * Планета объявляется каждым таким профилем отдельно, а не общим родителем: у него
 * же наследуются планетарные погоды и астероидный пояс, а им мир в небе не положен
 * ни по смыслу, ни по окружению. Не получают её и те два профиля, которые как раз и
 * означают "мы больше не здесь" - блюспейс-интерфаза и фотонный вихрь.
 */
/datum/parallax_profile/weather
	abstract_type = /datum/parallax_profile/weather
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS
	source = "CEV-Eris"
	ambient_speed = 1200

/// Блюспейс-шторм. Ярусы глубины вместо одной плоской картинки Eris.
/// Фоновый ярус не берётся: замер показал чистую черноту (см. layers/weather.dm).
/datum/parallax_profile/weather/bluespace_storm
	id = "bluespace_storm"
	name = "Блюспейс-шторм"
	ambient_speed = 400
	ambient_angle = 30
	base_layers = list(
		/atom/movable/screen/parallax_layer/eris/far/bluespace_storm,
		/atom/movable/screen/parallax_layer/eris/close/bluespace_storm,
	)
	min_quality = PARALLAX_LOW
	static_objects = list(/atom/movable/screen/parallax_layer/space/planet)
	weight = 0

/// Кладбище кораблей: крупные обломки станций на среднем ярусе.
/datum/parallax_profile/weather/graveyard
	id = "graveyard"
	name = "Кладбище кораблей"
	base_layers = list(
		/atom/movable/screen/parallax_layer/eris/background/graveyard,
		/atom/movable/screen/parallax_layer/eris/far/graveyard,
		/atom/movable/screen/parallax_layer/eris/close/graveyard,
	)
	min_quality = PARALLAX_LOW
	static_objects = list(/atom/movable/screen/parallax_layer/space/planet)
	// Событийный: явление, мимо которого пролетаешь, не должно быть фоном раунда.
	weight = 0

/// Поле мелких обломков. Дальний ярус - единственный бесшовный стейт Eris.
/datum/parallax_profile/weather/micro_debris
	id = "micro_debris"
	name = "Поле обломков"
	base_layers = list(
		/atom/movable/screen/parallax_layer/space/layer_1,
		/atom/movable/screen/parallax_layer/skybox/stars,
		/atom/movable/screen/parallax_layer/eris/far/micro_debris,
		/atom/movable/screen/parallax_layer/eris/close/micro_debris,
	)
	min_quality = PARALLAX_LOW
	static_objects = list(/atom/movable/screen/parallax_layer/space/planet)
	weight = 0

/// Ионная буря. Ближнего яруса у художника Eris нет, поэтому их только два.
/datum/parallax_profile/weather/ion_blizzard
	id = "ion_blizzard"
	name = "Ионная буря"
	ambient_speed = 500
	ambient_angle = 270
	base_layers = list(
		/atom/movable/screen/parallax_layer/eris/background/ion_blizzard,
		/atom/movable/screen/parallax_layer/eris/far/ion_blizzard,
	)
	min_quality = PARALLAX_LOW
	static_objects = list(/atom/movable/screen/parallax_layer/space/planet)
	weight = 0

/// Блюспейс-интерфаза: ровный фон без ярусов, для аномальных зон.
/datum/parallax_profile/weather/bluespace_interphase
	id = "bluespace_interphase"
	name = "Блюспейс-интерфаза"
	base_layers = list(/atom/movable/screen/parallax_layer/eris/background/bluespace_interphase)
	min_quality = PARALLAX_LOW
	weight = 0

/// Фотонный вихрь: чёрная дыра во весь фон, поверх неё редкие звёзды.
/datum/parallax_profile/weather/photon_vortex
	id = "photon_vortex"
	name = "Фотонный вихрь"
	skybox = /atom/movable/screen/parallax_layer/eris/photon_vortex
	base_layers = list(/atom/movable/screen/parallax_layer/skybox/stars)
	min_quality = PARALLAX_LOW
	weight = 0

// ---------------------------------------------------------------------------
// goonstation: погода через маску плотности
// ---------------------------------------------------------------------------

/datum/parallax_profile/weather/goon
	abstract_type = /datum/parallax_profile/weather/goon
	environment_flags = PARALLAX_ENV_PLANET
	source = "goonstation"
	// Погода обязана идти сама. Угол 0 - строго вниз по экрану.
	ambient_speed = 250
	ambient_angle = 0

/**
 * Планетарная погода идёт парами: спокойный фон мира и его же буря.
 *
 * Без этого хук погоды был бы бессмысленным на снежных и лавовых уровнях: там
 * метель и есть базовый вид, и включение метели поверх метели ничего не меняет.
 * Спокойный фон несёт только разреженный ярус, буря добавляет плотный.
 */
/// Снежный мир в спокойную погоду. Гейт по трейтам, чтобы снег не пошёл над лавой.
/datum/parallax_profile/weather/goon/snow
	id = "planet_snow"
	name = "Снежная позёмка"
	ambient_speed = 400
	ambient_angle = 20
	base_layers = list(/atom/movable/screen/parallax_layer/goon/snow_sparse)
	z_traits = list(ZTRAIT_ICE_RUINS, ZTRAIT_ICE_RUINS_UNDERGROUND, ZTRAIT_SNOWSTORM, ZTRAIT_ICESTORM)
	min_quality = PARALLAX_LOW
	weight = 60

/// Его же буря. Ставится самой погодой, автоподбором не выпадает.
/datum/parallax_profile/weather/goon/snow/storm
	id = "planet_snow_storm"
	name = "Метель"
	ambient_speed = 200
	base_layers = list(
		/atom/movable/screen/parallax_layer/goon/snow_sparse,
		/atom/movable/screen/parallax_layer/goon/snow_dense,
	)
	z_traits = null
	weight = 0

/// Пепел и угли. Исходник почти чёрный (яркость 34 из 255), поэтому коэффициент
/// маски плотности здесь втрое больше снежного.
/// Угли поднимаются, а не падают - отсюда угол 180.
/datum/parallax_profile/weather/goon/embers
	id = "planet_embers"
	name = "Пепел"
	ambient_speed = 600
	ambient_angle = 180
	base_layers = list(/atom/movable/screen/parallax_layer/goon/embers_sparse)
	z_traits = list(ZTRAIT_LAVA_RUINS, ZTRAIT_LAVA_JUNGLE_RUINS, ZTRAIT_ASHSTORM)
	min_quality = PARALLAX_LOW
	weight = 60

/// Пепельная буря. Ставится самой погодой.
/datum/parallax_profile/weather/goon/embers/storm
	id = "planet_embers_storm"
	name = "Пепельная буря"
	ambient_speed = 350
	base_layers = list(
		/atom/movable/screen/parallax_layer/goon/embers_sparse,
		/atom/movable/screen/parallax_layer/goon/embers_dense,
	)
	z_traits = null
	weight = 0

/// Пыльная буря. Без гейта по трейтам - запасной вариант для любой планеты.
/// Пыль несёт вбок, а не сверху вниз.
/datum/parallax_profile/weather/goon/dust
	id = "planet_dust"
	name = "Пыльная буря"
	ambient_speed = 500
	ambient_angle = 75
	base_layers = list(/atom/movable/screen/parallax_layer/goon/dust_sparse)
	min_quality = PARALLAX_LOW
	weight = 25

/// Пыльная буря. Резерв для планетарных погод, которым нечего показать своего.
/datum/parallax_profile/weather/goon/dust/storm
	id = "planet_dust_storm"
	name = "Пыльная буря"
	ambient_speed = 220
	base_layers = list(
		/atom/movable/screen/parallax_layer/goon/dust_sparse,
		/atom/movable/screen/parallax_layer/goon/dust_dense,
	)
	weight = 0

/// Выброс: событийный профиль планетарных уровней, ставится только вручную.
/datum/parallax_profile/weather/goon/blowout
	id = "planet_blowout"
	name = "Выброс"
	ambient_speed = 150
	base_layers = list(
		/atom/movable/screen/parallax_layer/goon/blowout_clouds,
		/atom/movable/screen/parallax_layer/goon/meteors,
	)
	min_quality = PARALLAX_LOW
	weight = 0

/// Пустота: чернота и два яруса разреженных облаков.
/datum/parallax_profile/weather/goon/void
	id = "void"
	name = "Пустота"
	ambient_speed = 1500
	ambient_angle = 45
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS | PARALLAX_ENV_PLANET
	base_layers = list(
		/atom/movable/screen/parallax_layer/goon/void,
		/atom/movable/screen/parallax_layer/goon/void_clouds_1,
		/atom/movable/screen/parallax_layer/goon/void_clouds_2,
	)
	min_quality = PARALLAX_LOW
	weight = 0

/// Астероидный пояс из трёх плотностей.
/// Станции не достаётся: её фон закреплён за space_classic, см. profiles/space.dm.
/datum/parallax_profile/weather/goon/asteroid_belt
	id = "asteroid_belt"
	name = "Астероидный пояс"
	environment_flags = PARALLAX_ENV_SPACE_RUINS
	base_layers = list(
		/atom/movable/screen/parallax_layer/space/layer_1,
		/atom/movable/screen/parallax_layer/skybox/stars,
		/atom/movable/screen/parallax_layer/goon/asteroids_far,
		/atom/movable/screen/parallax_layer/goon/asteroids_near,
	)
	min_quality = PARALLAX_LOW
	weight = 8

// ---------------------------------------------------------------------------
// Небо газового гиганта
// ---------------------------------------------------------------------------

/**
 * Layenia: четыре слоя Shiptest работают только вместе. Горизонт задаёт линию,
 * три яруса облаков расходятся по скорости; по отдельности каждый бессмыслен.
 */
/// Только планетарные уровни: это яркое небо (средняя яркость кадра 187 из 255),
/// и над руиной в открытом космосе оно читалось бы как засвет, а не как небо.
/datum/parallax_profile/weather/layenia
	id = "gas_giant"
	name = "Небо газового гиганта"
	// Облака гиганта идут поперёк неба.
	ambient_speed = 600
	ambient_angle = 90
	environment_flags = PARALLAX_ENV_PLANET
	base_layers = list(
		/atom/movable/screen/parallax_layer/donor/layenia_horizon,
		/atom/movable/screen/parallax_layer/donor/layenia_1,
		/atom/movable/screen/parallax_layer/donor/layenia_2,
		/atom/movable/screen/parallax_layer/donor/layenia_3,
	)
	min_quality = PARALLAX_LOW
	source = "Shiptest"
	weight = 10
