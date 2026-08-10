/**
 * Непрозрачная подложка сцены.
 *
 * Растянута по всему вьюпорту и никуда не двигается, поэтому не стоит ни
 * пикселя работы на шаг игрока. Её единственная задача - гарантировать, что
 * плану космоса есть на что умножаться: без неё прозрачные участки сцены
 * остаются БЕЛЫМИ (см. [/datum/parallax_profile/var/backdrop]).
 *
 * Спрайт - обычный белый квадрат 32x32, покрашенный в чёрный и растянутый
 * своим screen_loc: отдельного ассета под сплошную заливку заводить незачем.
 */
/atom/movable/screen/parallax_layer/backdrop
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	color = "#000000"
	blend_mode = BLEND_OVERLAY
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	layer_mode = PARALLAX_MODE_OVERLAY
	layer = 0
	parallax_intensity = PARALLAX_LOW

/**
 * Базовые слои космоса BlueMoon.
 *
 * Три звёздных слоя разной скорости - историческая основа сцены. Отдельный тип
 * заводится под отдельное ИЗОБРАЖЕНИЕ; цвет, позиция и выбор варианта задаются
 * данными профиля, а не новым подтипом.
 */
/atom/movable/screen/parallax_layer/space
	icon = 'icons/effects/parallax.dmi'

/atom/movable/screen/parallax_layer/space/layer_1
	icon_state = "layer1"
	speed = 0.6
	layer = 1
	parallax_intensity = PARALLAX_LOW

/// Мерцает: период у среднего и верхнего слоя разный, поэтому пульсации не
/// складываются в общее "экран потемнел", а читаются как живые звёзды.
/atom/movable/screen/parallax_layer/space/layer_2
	icon_state = "layer2"
	speed = 1
	layer = 2
	parallax_intensity = PARALLAX_MED
	twinkle_time = 7 SECONDS
	twinkle_min_alpha = 175

/atom/movable/screen/parallax_layer/space/layer_3
	icon_state = "layer3"
	speed = 1.4
	layer = 3
	parallax_intensity = PARALLAX_HIGH
	twinkle_time = 4.5 SECONDS
	twinkle_min_alpha = 160

/// Ближний быстрый слой - разреженная взвесь поверх звёзд.
/atom/movable/screen/parallax_layer/space/random
	blend_mode = BLEND_OVERLAY
	speed = 2
	layer = 3
	parallax_intensity = PARALLAX_INSANE

/atom/movable/screen/parallax_layer/space/random/space_gas
	icon_state = "space_gas"
	palette_tinted = TRUE

/atom/movable/screen/parallax_layer/space/random/asteroids
	icon_state = "asteroids"

/// Ледяная равнина под станцией. Долго лежал в DMI неподключённым.
/atom/movable/screen/parallax_layer/space/icemoon
	icon_state = "icemoon"
	blend_mode = BLEND_OVERLAY
	speed = 1.8
	layer = 3
	parallax_intensity = PARALLAX_HIGH

/**
 * Планета на орбите. Не тайлится: под движущейся областью уезжает за край пролётом,
 * а не прокручивается циклом.
 *
 * Окружение сужено намеренно. Гиперпространство местных ориентиров не имеет по
 * определению, и планета за окном летящего шаттла читается как летящая ВМЕСТЕ с ним;
 * на планетарном уровне мир в небе - и вовсе тот, на котором игрок стоит. Остаются
 * станция, космические руины и ЦК - места, откуда на планету действительно смотрят.
 */
/atom/movable/screen/parallax_layer/space/planet
	icon_state = "planet"
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
