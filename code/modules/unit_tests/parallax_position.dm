/// Tests for /atom/movable/screen/parallax_layer/proc/RelativePosition.
/// This runs per parallax layer on every player move (the single biggest non-atmos
/// self-CPU consumer in round profiles), so it must:
/// - keep the screen_loc math exact (including the 480px wrap and round-to-pixel),
/// - report via its return value whether a glide animation was started,
/// - NOT start a glide animation for sub-2px deltas (visually indistinguishable from
///   the instant screen_loc snap while the viewport itself glides a full tile).
/datum/unit_test/parallax_relative_position/Run()
	// Slow layer (0.6 px per tile): visual position changes only every other step,
	// and per-step deltas never exceed 1px so no glide animation should ever start.
	var/atom/movable/screen/parallax_layer/slow = new
	allocated += slow
	slow.speed = 0.6
	var/list/expected_x = list(-1, -1, -2, -2, -3)
	for(var/i in 1 to 5)
		var/animated = slow.RelativePosition(0, 0, 1, 0, 2)
		TEST_ASSERT(!animated, "Slow layer started a glide animation for a sub-pixel delta at step [i]")
		TEST_ASSERT_EQUAL(slow.screen_loc, "CENTER:[expected_x[i] - 224],CENTER:-224", "Slow layer screen_loc mismatch at step [i]")

	// Fast layer (2 px per tile): a 2px delta is the threshold where the glide animation
	// must still be started (and reported via the return value).
	var/atom/movable/screen/parallax_layer/fast = new
	allocated += fast
	fast.speed = 2
	var/animated_fast = fast.RelativePosition(0, 0, 1, 0, 2)
	TEST_ASSERT(animated_fast, "Fast layer did not report starting a glide animation for a 2px delta")
	TEST_ASSERT_EQUAL(fast.screen_loc, "CENTER:-226,CENTER:-224", "Fast layer screen_loc mismatch after first step")

	// anim_time = 0 must never animate regardless of delta
	var/animated_noanim = fast.RelativePosition(0, 0, 1, 0, 0)
	TEST_ASSERT(!animated_noanim, "Layer started a glide animation with anim_time = 0")
	TEST_ASSERT_EQUAL(fast.screen_loc, "CENTER:-228,CENTER:-224", "Fast layer screen_loc mismatch after no-anim step")

	// Mid-speed layer (1.4 px per tile) on diagonal moves: per-step visual delta
	// alternates between 1px (no animation) and 2px (animation).
	var/atom/movable/screen/parallax_layer/mid = new
	allocated += mid
	mid.speed = 1.4
	TEST_ASSERT(!mid.RelativePosition(0, 0, 1, 1, 2), "Mid layer animated a 1px diagonal delta")
	TEST_ASSERT_EQUAL(mid.screen_loc, "CENTER:-225,CENTER:-225", "Mid layer screen_loc mismatch at step 1")
	TEST_ASSERT(mid.RelativePosition(0, 0, 1, 1, 2), "Mid layer did not animate a 2px diagonal delta")
	TEST_ASSERT_EQUAL(mid.screen_loc, "CENTER:-227,CENTER:-227", "Mid layer screen_loc mismatch at step 2")

	// Wrap across the 240px boundary: position wraps by 480 and animation must be skipped
	var/atom/movable/screen/parallax_layer/wrapper = new
	allocated += wrapper
	wrapper.speed = 2
	wrapper.offset_x = 239
	var/animated_wrap = wrapper.RelativePosition(0, 0, -1, 0, 2)
	TEST_ASSERT(!animated_wrap, "Layer started a glide animation across a wrap")
	TEST_ASSERT_EQUAL(wrapper.screen_loc, "CENTER:-463,CENTER:-224", "Wrapped layer screen_loc mismatch")

	// Absolute layer delegates to ResetPosition and never glides
	var/atom/movable/screen/parallax_layer/abs_layer = new
	allocated += abs_layer
	abs_layer.speed = 1
	abs_layer.absolute = TRUE
	var/animated_abs = abs_layer.RelativePosition(10, 5, 1, 1, 2)
	TEST_ASSERT(!animated_abs, "Absolute layer reported a glide animation")
	TEST_ASSERT_EQUAL(abs_layer.screen_loc, "CENTER:-234,CENTER:-229", "Absolute layer screen_loc mismatch")

/// Слой произвольного размера обязан заворачиваться по СВОЕМУ периоду, а не по 480.
/// Донорские ассеты идут в 672 (goonstation) и 736 (CEV-Eris) пикселей, и на
/// историческом периоде их картинка рвалась бы посреди экрана.
/datum/unit_test/parallax_layer_geometry/Run()
	// 672 пикселя: половина периода 336, центрирующий сдвиг -(672-32)/2 = -320.
	var/atom/movable/screen/parallax_layer/wide = new
	allocated += wide
	wide.tile_size = 672
	wide.speed = 1
	wide.ApplyLayerMode()
	TEST_ASSERT_EQUAL(wide.tile_half, 336, "Половина периода посчитана неверно для тайла 672")
	TEST_ASSERT_EQUAL(wide.anchor_offset, -320, "Якорь screen_loc неверен для тайла 672")

	wide.offset_x = 336
	wide.RelativePosition(0, 0, -1, 0, 0)
	TEST_ASSERT_EQUAL(wide.offset_x, -335, "Слой 672 не завернулся по своему периоду")
	TEST_ASSERT_EQUAL(wide.screen_loc, "CENTER:-655,CENTER:-320", "screen_loc после заворота не совпал")

	// 736 пикселей: половина периода 368, сдвиг -(736-32)/2 = -352. Ровно то же
	// число, что жёстко прописано у Polaris для их скайбокса того же размера.
	var/atom/movable/screen/parallax_layer/eris = new
	allocated += eris
	eris.tile_size = 736
	eris.speed = 1
	eris.ApplyLayerMode()
	TEST_ASSERT_EQUAL(eris.tile_half, 368, "Половина периода посчитана неверно для тайла 736")
	TEST_ASSERT_EQUAL(eris.anchor_offset, -352, "Якорь screen_loc неверен для тайла 736")

	// Чётный размер тайла больше не требует поправок: якорь всегда один тайл CENTER,
	// а центрирование целиком уходит в пиксельный суффикс.
	var/atom/movable/screen/parallax_layer/even_layer = new
	allocated += even_layer
	even_layer.tile_size = 64
	even_layer.speed = 1
	even_layer.ApplyLayerMode()
	TEST_ASSERT_EQUAL(even_layer.anchor_offset, -16, "Якорь screen_loc неверен для тайла 64")
	// Повторный вызов не должен ничего накапливать.
	even_layer.ApplyLayerMode()
	TEST_ASSERT_EQUAL(even_layer.anchor_offset, -16, "Повторный ApplyLayerMode сдвинул якорь")

	// Историческая геометрия 480 не сдвинулась НИ НА ПИКСЕЛЬ. Кодировка сменилась
	// с "CENTER-7:0" на "CENTER:-224", но это одна и та же точка: семь тайлов по
	// 32 пикселя - это ровно те же 224 пикселя западнее центра.
	var/atom/movable/screen/parallax_layer/legacy = new
	allocated += legacy
	legacy.ApplyLayerMode()
	TEST_ASSERT_EQUAL(legacy.screen_loc_prefix, "CENTER:", "Якорь исторического слоя 480 перестал быть тайлом CENTER")
	TEST_ASSERT_EQUAL(legacy.anchor_offset, -224, "Пиксельный якорь исторического слоя 480 не равен прежним семи тайлам")
	TEST_ASSERT_EQUAL(legacy.anchor_offset, -7 * world.icon_size, "Пиксельный якорь разошёлся с прежним тайловым CENTER-7")
	TEST_ASSERT_EQUAL(legacy.tile_half, 240, "Историческая граница заворота съехала")

/// Скайбокс не тайлится, поэтому обязан перекрывать вьюпорт при любом client.view,
/// а его смещение - зажиматься запасом картинки, чтобы край не въехал в кадр.
/datum/unit_test/parallax_skybox_coverage/Run()
	var/atom/movable/screen/parallax_layer/sky = new
	allocated += sky
	sky.layer_mode = PARALLAX_MODE_SKYBOX
	sky.tile_size = 736
	sky.speed = 1
	sky.ApplyLayerMode()
	TEST_ASSERT(sky.absolute, "Скайбокс не переключился в абсолютный режим")
	TEST_ASSERT(!sky.dynamic_self_tile, "Скайбокс остался самотайлящимся")

	for(var/view_string in list("15x15", "19x19", "23x23", "31x31", "17x15"))
		sky.SetView(view_string, TRUE)
		var/list/view_size = getviewsize(view_string)
		var/view_px_x = view_size[1] * world.icon_size
		var/view_px_y = view_size[2] * world.icon_size
		TEST_ASSERT(sky.bleed_x >= sky.min_bleed, "При view [view_string] запас по x всего [sky.bleed_x] при минимуме [sky.min_bleed]")
		TEST_ASSERT(sky.bleed_y >= sky.min_bleed, "При view [view_string] запас по y всего [sky.bleed_y] при минимуме [sky.min_bleed]")
		// Главное: картинка ПОСЛЕ масштабирования обязана быть шире вьюпорта.
		// Сверять это по запасу нельзя - тот упирается в min_bleed и превращает
		// проверку в тавтологию вида "запас неотрицателен".
		var/covered = sky.tile_size * sky.fitted_scale
		TEST_ASSERT(covered >= view_px_x, "При view [view_string] скайбокс перекрывает [covered] пикселей при ширине вьюпорта [view_px_x]")
		TEST_ASSERT(covered >= view_px_y, "При view [view_string] скайбокс перекрывает [covered] пикселей при высоте вьюпорта [view_px_y]")
		// И перекрытия обязано хватать на ВЕСЬ ход смещения: bleed_* - это предел, до
		// которого слой уезжает, и картинка короче вьюпорта плюс двух запасов показала бы
		// край на упоре. Допуск на сотую пикселя - тот самый обратный счёт масштаба,
		// из-за которого covered выходит 1087.9999 вместо 1088.
		TEST_ASSERT(covered + 0.01 >= view_px_x + sky.bleed_x * 2, "При view [view_string] скайбокс перекрывает [covered] пикселей, а уезжает на [sky.bleed_x] при ширине вьюпорта [view_px_x] - край войдёт в кадр на упоре")
		TEST_ASSERT(covered + 0.01 >= view_px_y + sky.bleed_y * 2, "При view [view_string] скайбокс перекрывает [covered] пикселей, а уезжает на [sky.bleed_y] при высоте вьюпорта [view_px_y] - край войдёт в кадр на упоре")

	sky.SetView("15x15", TRUE)
	// Уезжать дальше запаса скайбокс не имеет права ни при каких координатах.
	sky.ResetPosition(10000, 10000)
	TEST_ASSERT_EQUAL(sky.offset_x, -sky.bleed_x, "Скайбокс не зажался запасом при большом x")
	TEST_ASSERT_EQUAL(sky.offset_y, -sky.bleed_y, "Скайбокс не зажался запасом при большом y")
	sky.ResetPosition(-10000, -10000)
	TEST_ASSERT_EQUAL(sky.offset_x, sky.bleed_x, "Скайбокс не зажался запасом при отрицательном x")
	sky.ResetPosition(0, 0)
	TEST_ASSERT_EQUAL(sky.offset_x, 0, "Скайбокс в начале координат смещён")

	// Статический объект - наоборот, имеет право уехать за край и не зажимается.
	var/atom/movable/screen/parallax_layer/rock = new
	allocated += rock
	rock.layer_mode = PARALLAX_MODE_STATIC
	rock.speed = 1
	rock.ApplyLayerMode()
	rock.ResetPosition(10000, 0)
	TEST_ASSERT_EQUAL(rock.offset_x, -10000, "Статический объект зажали как скайбокс")

/// Clone() обязан переносить ВСЕ параметры геометрии и режима: держатель клиента
/// работает только с клонами, и потерянная переменная означает битую сцену у игрока.
/datum/unit_test/parallax_layer_clone/Run()
	var/atom/movable/screen/parallax_layer/source = new
	allocated += source
	source.layer_mode = PARALLAX_MODE_SKYBOX
	source.tile_size = 672
	source.base_scale = 1.5
	source.min_bleed = 96
	source.speed = 0.35
	source.center_x = -12
	source.center_y = -34
	source.parallax_intensity = PARALLAX_MED
	source.palette_tinted = TRUE
	source.spawn_jitter_min = 5
	source.spawn_jitter_max = 9
	source.ApplyLayerMode()
	source.SetView("19x19", TRUE)
	source.offset_x = 7
	source.offset_y = -3

	var/atom/movable/screen/parallax_layer/copy = source.Clone()
	allocated += copy
	TEST_ASSERT_EQUAL(copy.layer_mode, source.layer_mode, "Clone потерял режим слоя")
	TEST_ASSERT_EQUAL(copy.tile_size, source.tile_size, "Clone потерял размер тайла")
	TEST_ASSERT_EQUAL(copy.tile_half, source.tile_half, "Clone потерял границу заворота")
	TEST_ASSERT_EQUAL(copy.base_scale, source.base_scale, "Clone потерял масштаб")
	TEST_ASSERT_EQUAL(copy.min_bleed, source.min_bleed, "Clone потерял минимальный запас скайбокса")
	TEST_ASSERT_EQUAL(copy.bleed_x, source.bleed_x, "Clone потерял посчитанный запас по x")
	TEST_ASSERT_EQUAL(copy.bleed_y, source.bleed_y, "Clone потерял посчитанный запас по y")
	TEST_ASSERT_EQUAL(copy.fitted_scale, source.fitted_scale, "Clone потерял масштаб подгонки скайбокса")
	TEST_ASSERT_EQUAL(copy.speed, source.speed, "Clone потерял скорость")
	TEST_ASSERT_EQUAL(copy.center_x, source.center_x, "Clone потерял центр по x")
	TEST_ASSERT_EQUAL(copy.center_y, source.center_y, "Clone потерял центр по y")
	TEST_ASSERT_EQUAL(copy.anchor_offset, source.anchor_offset, "Clone потерял пиксельный якорь")
	TEST_ASSERT_EQUAL(copy.offset_x, source.offset_x, "Clone потерял смещение по x")
	TEST_ASSERT_EQUAL(copy.offset_y, source.offset_y, "Clone потерял смещение по y")
	TEST_ASSERT_EQUAL(copy.absolute, source.absolute, "Clone потерял признак абсолютности")
	TEST_ASSERT_EQUAL(copy.dynamic_self_tile, source.dynamic_self_tile, "Clone потерял признак самотайлинга")
	TEST_ASSERT_EQUAL(copy.parallax_intensity, source.parallax_intensity, "Clone потерял требуемое качество")
	TEST_ASSERT_EQUAL(copy.palette_tinted, source.palette_tinted, "Clone потерял признак окрашиваемости")
	TEST_ASSERT_EQUAL(copy.view_current, source.view_current, "Clone потерял текущий view")
	TEST_ASSERT_EQUAL(copy.screen_loc_prefix, source.screen_loc_prefix, "Clone потерял кэш префикса screen_loc")
	TEST_ASSERT_EQUAL(copy.screen_loc_mid, source.screen_loc_mid, "Clone потерял кэш разделителя screen_loc")
	TEST_ASSERT_EQUAL(copy.spawn_jitter_min, source.spawn_jitter_min, "Clone потерял нижнюю границу разброса")
	TEST_ASSERT_EQUAL(copy.spawn_jitter_max, source.spawn_jitter_max, "Clone потерял верхнюю границу разброса")

	// Клон обязан считать позицию так же, как исходник.
	source.ResetPosition(42, 17)
	copy.ResetPosition(42, 17)
	TEST_ASSERT_EQUAL(copy.screen_loc, source.screen_loc, "Клон встал не туда, куда исходник")

/**
 * Полёт шаттла обязан оставить области ЧИСЛОВУЮ скорость прокрутки.
 *
 * Держатель параллакса берёт из области и признак движения, и скорость. Раньше
 * cleanup_runway звал afterShuttleMove без скорости, и в области оседал null -
 * полёт всё же читался только потому, что этот null доезжал до Animation(speed = 25)
 * и там подменялся ДЕФОЛТОМ АРГУМЕНТА: в DM явно переданный null включает
 * значение по умолчанию так же, как отсутствующий аргумент. Стоило прочитать
 * скорость до вызова - и транзит молча превращался в стоянку.
 */
/datum/unit_test/shuttle_transit_parallax/Run()
	var/area/flying = new /area
	allocated += flying
	// Ровно то, что кладёт /area/onShuttleMove, забирая параметры у транзитной области.
	flying.parallax_moving = TRUE
	flying.parallax_move_speed = PARALLAX_SHUTTLE_SCROLL_SPEED
	flying.parallax_move_angle = 0

	// Ровно то, что зовёт cleanup_runway при уходе в транзит.
	flying.afterShuttleMove(EAST)
	TEST_ASSERT(flying.parallax_moving, "Уход в транзит снял с области признак движения")
	TEST_ASSERT(isnum(flying.parallax_move_speed), "После ухода в транзит скорость прокрутки нечисловая: [isnull(flying.parallax_move_speed) ? "null" : flying.parallax_move_speed]")
	TEST_ASSERT(flying.parallax_move_speed > 0, "После ухода в транзит скорость прокрутки [flying.parallax_move_speed] - сцена стоит на месте")
	TEST_ASSERT_EQUAL(flying.parallax_move_angle, dir2angle(EAST), "Угол прокрутки не совпал с направлением полёта")

	// Своя скорость шаттла обязана доезжать до области, а не подменяться дефолтом.
	flying.afterShuttleMove(EAST, 40)
	TEST_ASSERT_EQUAL(flying.parallax_move_speed, 40, "Область не приняла собственную скорость шаттла")

	// Посадка: та же область обязана перестать считаться летящей.
	flying.afterShuttleMove(0)
	TEST_ASSERT(!flying.parallax_moving, "После посадки область осталась летящей")

/**
 * Статика под движущейся областью обязана уезжать за край, сохраняя свой масштаб.
 *
 * Масштаб и смещение живут в ОДНОЙ матрице, поэтому анимация, построенная от matrix(),
 * первым же кадром схлопывает планету с её 2.5x до единицы. Уходить слой обязан
 * навстречу движению и дальше края экрана - иначе объект просто дёрнется и замрёт
 * в кадре, что хуже неподвижности.
 */
/datum/unit_test/parallax_static_flyby/Run()
	var/atom/movable/screen/parallax_layer/world_layer = new
	allocated += world_layer
	world_layer.layer_mode = PARALLAX_MODE_STATIC
	world_layer.base_scale = 2.5
	world_layer.speed = 1
	world_layer.ApplyLayerMode()
	world_layer.SetView("15x15", TRUE)

	var/matrix/at_rest = world_layer.BaseTransform()
	TEST_ASSERT_EQUAL(at_rest.a, 2.5, "Матрица покоя потеряла масштаб слоя")
	TEST_ASSERT_EQUAL(at_rest.c, 0, "Матрица покоя несёт смещение по x")
	TEST_ASSERT_EQUAL(at_rest.f, 0, "Матрица покоя несёт смещение по y")

	// Слой обязан уйти дальше, чем половина картинки плюс половина вьюпорта: иначе
	// его край останется в кадре.
	var/distance = world_layer.FlybyDistance()
	var/list/real_view = getviewsize("15x15")
	var/minimum = (world_layer.tile_size * world_layer.base_scale + max(real_view[1], real_view[2]) * world.icon_size) * 0.5
	TEST_ASSERT(distance >= minimum, "Пролёт уводит слой на [distance] при необходимых [minimum] - край останется в кадре")

	// Полёт на север: сцена уходит НАВСТРЕЧУ движению, то есть вниз по экрану.
	var/matrix/north_target = world_layer.FlybyTarget(0)
	TEST_ASSERT_EQUAL(north_target.a, 2.5, "Пролёт схлопнул масштаб статики")
	TEST_ASSERT_EQUAL(north_target.c, 0, "Пролёт на север увёл слой вбок")
	TEST_ASSERT_EQUAL(north_target.f, -distance, "Пролёт на север не увёл слой вниз по экрану")

	// Полёт на восток: слой уходит влево.
	var/matrix/east_target = world_layer.FlybyTarget(dir2angle(EAST))
	TEST_ASSERT_EQUAL(east_target.c, -distance, "Пролёт на восток не увёл слой влево")

	// Далёкий мир не имеет права идти вровень с ближними звёздами. Тайлящийся слой
	// скорости 1 проходит свой тайл за скорость сцены; пролёт обязан быть заметно
	// медленнее, иначе планета пересекает кадр за считанные секунды.
	var/duration = world_layer.FlybyDuration(PARALLAX_SHUTTLE_SCROLL_SPEED)
	TEST_ASSERT(duration >= 15 SECONDS, "Пролёт занимает [duration * 0.1]с - далёкий мир обгоняет ближние звёзды")
	TEST_ASSERT(duration <= 120 SECONDS, "Пролёт занимает [duration * 0.1]с - объект не успеет уйти за кадр за весь рейс")

	TEST_ASSERT(world_layer.StartFlyby(PARALLAX_SHUTTLE_SCROLL_SPEED, 0), "Статика не ушла в пролёт под движущейся областью")
	TEST_ASSERT(world_layer.flying_by, "Пролёт не отметился на слое")
	// Повторный запуск обязан быть пустой операцией: UpdateMotion зовётся на каждой
	// смене области, и перезапуск дёргал бы планету к началу пути на каждом шаге.
	TEST_ASSERT(!world_layer.StartFlyby(PARALLAX_SHUTTLE_SCROLL_SPEED, 0), "Пролёт перезапустился поверх самого себя")
	TEST_ASSERT(world_layer.StopFlyby(), "Слой не вышел из пролёта")
	TEST_ASSERT(!world_layer.flying_by, "После остановки слой всё ещё считается пролетающим")

	// Тайлящийся слой прокручивается своим циклом, пролёт ему не положен.
	var/atom/movable/screen/parallax_layer/stars = new
	allocated += stars
	stars.speed = 1
	stars.ApplyLayerMode()
	TEST_ASSERT(!stars.StartFlyby(PARALLAX_SHUTTLE_SCROLL_SPEED, 0), "Тайлящийся слой ушёл в пролёт вместо прокрутки")

/**
 * Атом в нульспейсе не находится в границах никакого шаттла.
 *
 * Прок перебирается по ВСЕМ докам разом, поэтому один моб, удалённый прямо в
 * Entered транзитного турфа, давал по рантайму на каждый док станции - полторы
 * сотни за раунд на каждом уровне, где шли события гиперпространства.
 */
/datum/unit_test/shuttle_bounds_nullspace/Run()
	// Док НЕ уходит в allocated: /obj/docking_port/Destroy без force возвращает
	// QDEL_HINT_LETMELIVE, и обычная уборка теста оставила бы его жить на карте.
	var/obj/docking_port/dock = new(run_loc_floor_bottom_left)
	var/obj/effect/orphan = new(run_loc_floor_bottom_left)
	allocated += orphan
	orphan.moveToNullspace()

	TEST_ASSERT_NULL(get_turf(orphan), "Подопытный атом остался на турфе - тест ничего не проверяет")
	var/in_dock = dock.is_in_shuttle_bounds(orphan)
	var/in_any_shuttle = SSshuttle.is_in_shuttle_bounds(orphan)
	qdel(dock, TRUE)

	TEST_ASSERT(!in_dock, "Атом в нульспейсе посчитали внутри границ дока")
	TEST_ASSERT(!in_any_shuttle, "SSshuttle посчитал атом в нульспейсе внутри шаттла")

/// Матрица "яркость -> прозрачность" (приём goonstation) обязана давать ровно ту
/// свёртку, ради которой берётся: непрозрачный серый шум становится маской плотности.
/datum/unit_test/parallax_luminance_matrix/Run()
	var/atom/movable/screen/parallax_layer/dust = new
	allocated += dust
	dust.luminance_alpha = 0.4
	dust.ApplyLayerMode()
	var/list/matrix_values = dust.color
	TEST_ASSERT(islist(matrix_values), "Матрица яркости не выставилась в color")
	TEST_ASSERT_EQUAL(length(matrix_values), 20, "Цветовая матрица не 4x5")
	// Вклад каждого канала цвета в выходную альфу - это и есть коэффициент.
	TEST_ASSERT_EQUAL(matrix_values[4], 0.4, "Красный канал не даёт вклада в альфу")
	TEST_ASSERT_EQUAL(matrix_values[8], 0.4, "Зелёный канал не даёт вклада в альфу")
	TEST_ASSERT_EQUAL(matrix_values[12], 0.4, "Синий канал не даёт вклада в альфу")
	TEST_ASSERT_EQUAL(matrix_values[16], 1, "Исходная альфа не пропускается насквозь")
	TEST_ASSERT_EQUAL(matrix_values[20], -1, "Свободный член матрицы не выставлен")
	// Цвет остаётся нетронутым: матрица меняет только прозрачность.
	TEST_ASSERT_EQUAL(matrix_values[1], 1, "Матрица изменила красный канал")
	TEST_ASSERT_EQUAL(matrix_values[6], 1, "Матрица изменила зелёный канал")
	TEST_ASSERT_EQUAL(matrix_values[11], 1, "Матрица изменила синий канал")

	// Отрицательный коэффициент инвертирует маску - видимым остаётся тёмное.
	dust.ApplyLuminanceMatrix(-0.4)
	matrix_values = dust.color
	TEST_ASSERT_EQUAL(matrix_values[4], -0.4, "Инверсия маски не применилась")

/// Logs the cost of the per-move hot path (speed-1 layer, 1px deltas with glide enabled).
/// No assertions on timing, output is for before/after comparison in test logs.
/datum/unit_test/parallax_relative_position_bench
	priority = TEST_LONGER

/datum/unit_test/parallax_relative_position_bench/Run()
	var/atom/movable/screen/parallax_layer/layer = new
	allocated += layer
	layer.speed = 1
	// Контроль: тот же цикл, но период заворота взят литералами, как было до
	// обобщения геометрии. Разница между строками - цена того, что слой теперь
	// умеет тайлиться не только по 480.
	//
	// Замеры чередуются и повторяются: один прогон каждого варианта подряд даёт
	// второму тёплый кеш, и разница ушла бы в шум порядка запуска.
	var/atom/movable/screen/parallax_layer/control = new
	allocated += control
	control.speed = 1
	var/iterations = 50000
	var/general_total = 0
	var/legacy_total = 0
	var/rounds = 3
	for(var/pass in 1 to rounds)
		var/start = REALTIMEOFDAY
		for(var/i in 1 to iterations)
			layer.RelativePosition(0, 0, (i % 2) ? 1 : -1, 0, 2)
		general_total += REALTIMEOFDAY - start
		start = REALTIMEOFDAY
		for(var/i in 1 to iterations)
			control.LegacyRelativePosition(0, 0, (i % 2) ? 1 : -1, 0, 2)
		legacy_total += REALTIMEOFDAY - start
	var/general_ms = general_total * 100 / rounds
	var/legacy_ms = legacy_total * 100 / rounds
	log_world("PERF: parallax RelativePosition x[iterations] (speed 1, 1px glide deltas), среднее из [rounds]: [general_ms]ms")
	log_world("PERF: parallax RelativePosition x[iterations] КОНТРОЛЬ на литералах 480/240, среднее из [rounds]: [legacy_ms]ms (обобщение стоит [legacy_ms ? round((general_ms - legacy_ms) / legacy_ms * 100, 0.1) : 0]%)")

/// Сравнение стоимости профилей. Без утверждений на время - цифры в лог, чтобы
/// сверять "до и после" и ловить профиль, который вдруг стал дороже классики.
/// Меряется ровно то, за что платит сервер: шаг игрока (RelativePosition по всем
/// слоям сцены), постройка сцены и её клонирование при смене z.
/datum/unit_test/parallax_profile_bench
	priority = TEST_LONGER

/datum/unit_test/parallax_profile_bench/Run()
	var/list/measured = list("space_classic", "deep_space", "gas_giant", "planet_snow", "orbit_generated")
	var/steps = 20000

	for(var/profile_id in measured)
		var/datum/parallax_profile/profile = SSparallax.profiles_by_id[profile_id]
		if(!profile)
			log_world("PERF: parallax profile '[profile_id]' отсутствует в каталоге, пропущен")
			continue

		// Постройка сцены: цена появления z-уровня.
		var/build_start = REALTIMEOFDAY
		var/datum/parallax/scene = new(profile)
		var/build_ms = (REALTIMEOFDAY - build_start) * 100

		// Клонирование: цена каждого Reset клиента, то есть смены z и телепорта.
		var/clone_start = REALTIMEOFDAY
		var/list/clones = scene.GetObjects()
		var/clone_ms = (REALTIMEOFDAY - clone_start) * 100

		var/moving = 0
		for(var/atom/movable/screen/parallax_layer/layer as anything in clones)
			if(layer.layer_mode == PARALLAX_MODE_TILED)
				moving++

		// Шаг игрока по всей сцене - именно это идёт на каждое движение каждого игрока.
		var/move_start = REALTIMEOFDAY
		for(var/i in 1 to steps)
			var/rel = (i % 2) ? 1 : -1
			for(var/atom/movable/screen/parallax_layer/layer as anything in clones)
				layer.RelativePosition(i % 200, i % 200, rel, 0, 2)
		var/move_ms = (REALTIMEOFDAY - move_start) * 100

		log_world("PERF: parallax profile '[profile_id]': слоёв [length(clones)] (движущихся [moving]), постройка [build_ms]ms, клон [clone_ms]ms, [steps] шагов [move_ms]ms")

		QDEL_LIST(clones)
		qdel(scene)
