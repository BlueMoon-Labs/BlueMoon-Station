
/**
 * Один слой параллакса на экране клиента.
 *
 * Слои живут в трёх режимах (см. PARALLAX_MODE_* в __DEFINES/rendering/parallax.dm):
 * тайлящийся, скайбокс и статический объект. Режим выставляется на типе и
 * определяет и математику позиции, и то, участвует ли слой в анимации прокрутки.
 */
/atom/movable/screen/parallax_layer
	icon = 'icons/effects/parallax.dmi'
	blend_mode = BLEND_ADD
	plane = PLANE_SPACE_PARALLAX
	screen_loc = "CENTER:-224,CENTER:-224"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// TILE_BOUND обязателен, и его отсутствие обошлось дорого. Без него BYOND
	// считает границами объекта его КАРТИНКУ, а не тайл, и экранный объект шире
	// вьюпорта раздувает область отрисовки карты - экран уезжает мельче и в рамке.
	// Все четыре донора со скайбоксами 736 держат TILE_BOUND; у нас он потерялся
	// при перекрытии appearance_flags, пока все слои были ровно по вьюпорту.
	appearance_flags = PIXEL_SCALE | KEEP_TOGETHER | TILE_BOUND

	/// pixel x/y shift per real x/y
	var/speed = 1
	/// current cached offset x
	var/offset_x = 0
	/// current cached offset y
	var/offset_y = 0
	/// normal centered x
	var/center_x = 0
	/// normal centered y
	var/center_y = 0
	/// absolute - always determine shift x/y as a function of real x/y instead of allowing for relative scroll.
	var/absolute = FALSE
	/// parallax level required to see this
	var/parallax_intensity = PARALLAX_INSANE
	/// current view we're adapted to
	var/view_current
	/// dynamic self tile - tile to our view size. set this to false for static parallax layers.
	var/dynamic_self_tile = TRUE
	/// map id
	var/map_id
	/// queued animation timerid
	var/queued_animation

	/// Режим слоя, PARALLAX_MODE_*. Определяет [absolute] и [dynamic_self_tile] в Initialize.
	var/layer_mode = PARALLAX_MODE_TILED
	/// Сторона исходной картинки в пикселях. Для TILED это ещё и период заворота.
	var/tile_size = PARALLAX_DEFAULT_TILE_SIZE
	/// Половина периода - граница заворота. Кэш, чтобы не делить в горячем проке.
	var/tile_half = PARALLAX_DEFAULT_TILE_SIZE / 2
	/// Постоянный масштаб слоя. Скайбокс досчитывает свой поверх этого в SetView.
	var/base_scale = 1
	/// SKYBOX: минимальный запас картинки за краем вьюпорта, в пикселях. Он же
	/// максимальное смещение скайбокса - дальше край изображения вошёл бы в кадр.
	var/min_bleed = 48
	/// SKYBOX: фактический запас по осям, считается в SetView под текущий client.view.
	var/bleed_x = 0
	var/bleed_y = 0
	/// SKYBOX: масштаб, которым картинка подогнана под вьюпорт. Из него, а не из
	/// запаса, видно, действительно ли скайбокс перекрывает экран: при малом
	/// перекрытии запас упирается в min_bleed и перестаёт быть мерой покрытия.
	var/fitted_scale = 1
	/// Кэш префиксов screen_loc. Дефолты верны для тайла 480 без map_id, поэтому
	/// прок позиции не зависит от того, успел ли отработать Initialize.
	var/screen_loc_prefix = "CENTER:"
	var/screen_loc_mid = ",CENTER:"
	/// Пиксельный сдвиг, центрирующий картинку слоя на тайле CENTER.
	/// Для исторического тайла 480 это -224, то есть ровно прежний якорь CENTER-7.
	var/anchor_offset = -(PARALLAX_DEFAULT_TILE_SIZE - 32) / 2
	/// TRUE, если профиль имеет право красить этот слой цветом своей палитры.
	var/palette_tinted = FALSE
	/// STATIC/SKYBOX: разброс стартовой позиции при постройке профиля, в пикселях.
	var/spawn_jitter_min = 0
	var/spawn_jitter_max = 0
	/**
	 * Коэффициент "яркость -> прозрачность" (приём goonstation).
	 *
	 * Ненулевое значение подменяет [color] матрицей alpha = k*(R+G+B) + A + offset.
	 * Непрозрачная текстура серого шума превращается в маску плотности, а сила
	 * явления становится ОДНИМ числом вместо перерисовки картинки. Отрицательный k
	 * инвертирует маску: видимым остаётся тёмное, а не светлое (сажа, а не снег).
	 *
	 * Это единственный способ взять чужие полностью непрозрачные погодные слои,
	 * не засветив ими экран через BLEND_ADD.
	 */
	var/luminance_alpha = 0
	/// Свободный член матрицы яркости. -1 гасит полностью белый исходник в ноль.
	var/luminance_alpha_offset = -1
	/// Если больше нуля, слой проявляется за это время, когда его показывают клиенту.
	/// Событийным слоям нужен мягкий вход, а не рывок.
	var/fade_in_time = 0
	/// Проявление уже отыграно. Клон его не наследует: новая копия слоя - это новое
	/// появление на экране, а вот повторный Apply на том же экземпляре (событие
	/// сняло и вернуло слои) заново мигать не должен.
	var/faded_in = FALSE
	/**
	 * Период мерцания слоя в децисекундах. 0 - слой неподвижен по яркости.
	 *
	 * Мерцание идёт по alpha, а НЕ по transform, и в этом весь смысл: transform у
	 * слоя занят глайдом движения и прокруткой сцены, и анимация по нему их
	 * обрывает. Анимация альфы к ним не притрагивается, поэтому звёзды могут
	 * дышать, не отнимая плавности у шага игрока.
	 */
	var/twinkle_time = 0
	/// Нижняя граница мерцания. Верхняя - собственная alpha слоя.
	var/twinkle_min_alpha = 190
	/// Мерцание уже заведено. Как и [faded_in], клоном не наследуется.
	var/twinkling = FALSE
	/**
	 * Собственный дрейф слоя: децисекунды на проход своего тайла. 0 - слоя не несёт.
	 *
	 * Идёт по pixel_x/pixel_y - НЕ по transform и НЕ по screen_loc. Это принципиально:
	 * transform занят глайдом шага игрока и прокруткой шаттла, screen_loc считает
	 * горячий прок позиции. Пиксельное смещение не пересекается ни с тем, ни с
	 * другим, поэтому сцена может жить своей жизнью, ничего у них не отнимая.
	 *
	 * Смещение за цикл равно ровно периоду тайла, поэтому замощение переходит само
	 * в себя и шва в движении не видно.
	 */
	var/drift_time = 0
	/// Направление дрейфа, по часовой стрелке от севера.
	var/drift_angle = 0
	/// Дрейф уже заведён. Клоном не наследуется.
	var/drifting = FALSE
	/**
	 * Где слой уместен, битфилд PARALLAX_ENV_*. NONE - уместен везде.
	 *
	 * Профиль объявляет свои окружения сам, но внутри одной сцены слои живут по
	 * разным правилам: звёзды одинаково хороши и над станцией, и в гиперпространстве,
	 * а планета за окном летящего шаттла читается как летящая ВМЕСТЕ с ним. Поэтому
	 * гейт нужен и на слое, а не только на профиле.
	 *
	 * Сверяется при сборке шаблона z, а не в ShouldSee: окружение - свойство уровня,
	 * а не зрителя, и отсеянный слой не создаётся вовсе. Значит он не клонируется
	 * каждому клиенту и не считает позицию на каждый шаг игрока.
	 */
	var/environment_flags = NONE
	/// Идёт пролёт мимо: слой уезжает за край под движущейся областью. См. StartFlyby().
	/// Клоном не наследуется - новая копия начинает сцену заново.
	var/flying_by = FALSE
	/**
	 * STATIC: скорость пролёта мимо камеры, в долях скорости тайлящегося слоя.
	 *
	 * Отдельным полем, а НЕ через [speed]: у статики speed означает совсем другое -
	 * сколько пикселей объект сдвигается на один тайл шага игрока, и у планеты это
	 * выверенная единица. Взять её же за скорость пролёта значило бы гнать далёкий
	 * мир вровень с ближними звёздами: экран он проходил бы за четыре секунды.
	 *
	 * 0.15 - примерно вдевятеро медленнее слоя скорости 1, то есть около полуминуты
	 * на проход кадра при штатной скорости прокрутки шаттла.
	 */
	var/flyby_speed = 0.15

/atom/movable/screen/parallax_layer/Initialize(mapload)
	. = ..()
	ApplyLayerMode()

/// Приводит производные переменные в соответствие с [layer_mode] и [tile_size].
/// Зовётся из Initialize и после ручной смены геометрии слоя профилем.
/atom/movable/screen/parallax_layer/proc/ApplyLayerMode()
	tile_half = tile_size * 0.5
	switch(layer_mode)
		if(PARALLAX_MODE_TILED)
			absolute = FALSE
			dynamic_self_tile = TRUE
		if(PARALLAX_MODE_SKYBOX)
			absolute = TRUE
			dynamic_self_tile = FALSE
		if(PARALLAX_MODE_STATIC)
			absolute = TRUE
			dynamic_self_tile = FALSE
		if(PARALLAX_MODE_OVERLAY)
			absolute = TRUE
			dynamic_self_tile = FALSE
	UpdateScreenLocCache()
	transform = BaseTransform()
	if(luminance_alpha)
		ApplyLuminanceMatrix(luminance_alpha)

/**
 * Матрица слоя в покое - только его масштаб, без смещений.
 *
 * Всё, что двигает слой через transform (прокрутка сцены, пролёт статики), обязано
 * строиться отсюда, а не от matrix(). Иначе первый же кадр анимации схлопывает
 * планету с её 2.5x до единицы: масштаб живёт в той же матрице, что и смещение.
 *
 * У скайбокса масштаб считает FitSkybox под текущий вьюпорт, но до первого SetView
 * там лежит единица - поэтому берётся больший из двух.
 */
/atom/movable/screen/parallax_layer/proc/BaseTransform()
	RETURN_TYPE(/matrix)
	var/scale = (layer_mode == PARALLAX_MODE_SKYBOX) ? max(fitted_scale, base_scale) : base_scale
	var/matrix/base = matrix()
	if(scale != 1)
		base.Scale(scale, scale)
	return base

/**
 * Заводит бесконечный дрейф слоя. См. [drift_time].
 *
 * Смещение за цикл - ровно период тайла, поэтому в конце цикла картинка
 * совпадает сама с собой и мгновенный возврат в ноль незаметен.
 */
/atom/movable/screen/parallax_layer/proc/StartDrift()
	if(drift_time <= 0 || layer_mode != PARALLAX_MODE_TILED)
		return
	drifting = TRUE
	var/base_x = pixel_x
	var/base_y = pixel_y
	var/shift_x = -sin(drift_angle) * tile_size
	var/shift_y = -cos(drift_angle) * tile_size
	animate(src, pixel_x = base_x + shift_x, pixel_y = base_y + shift_y, time = drift_time, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(pixel_x = base_x, pixel_y = base_y, time = 0)

/**
 * Расстояние, на котором статический объект гарантированно вне кадра.
 *
 * Половина картинки плюс половина вьюпорта плюс тайл запаса. Считать по одной только
 * картинке нельзя: слой без собственного масштаба уже 480, а вьюпорт бывает шире.
 */
/atom/movable/screen/parallax_layer/proc/FlybyDistance()
	var/list/real_view = getviewsize(view_current || world.view)
	var/view_px = max(real_view[1], real_view[2]) * world.icon_size
	return (tile_size * base_scale + view_px) * 0.5 + world.icon_size

/**
 * Запускает пролёт статики мимо камеры.
 *
 * Крупный якорный объект под движущейся областью - это ровно та картинка, из-за
 * которой полёт перестаёт читаться как полёт: звёзды летят, а планета висит на
 * месте, будто она летит вместе с шаттлом. Поэтому статика уезжает против
 * направления движения и за кадром остаётся: она осталась позади, ей незачем
 * возвращаться, и зацикливать здесь нечего.
 *
 * Тайлящиеся слои прокручиваются в Animation() своим циклом, скайбокс не двигается
 * вовсе - его смещение упирается в bleed, за которым в кадр входит край картинки.
 *
 * Длительность берётся от скорости СЦЕНЫ, а не от длительности рейса: короткий
 * грузовой рейс покажет часть пролёта, эвакуация - весь, и оба будут идти с одной
 * скоростью. Делит её [flyby_speed], а не [speed] - у статики speed про другое,
 * см. его описание.
 *
 * Анимация идёт с ANIMATION_END_NOW, как и прокрутка тайлящихся слоёв, поэтому
 * статике нельзя давать fade_in_time: Apply() заводит проявление ПОСЛЕ прокрутки
 * и тем же флагом оборвал бы пролёт, швырнув объект сразу за край.
 */
/atom/movable/screen/parallax_layer/proc/StartFlyby(scene_speed, angle = 0)
	if(layer_mode != PARALLAX_MODE_STATIC || flying_by || scene_speed <= 0)
		return FALSE
	flying_by = TRUE
	animate(src, transform = FlybyTarget(angle), time = FlybyDuration(scene_speed), easing = LINEAR_EASING, flags = ANIMATION_END_NOW)
	return TRUE

/// Сколько децисекунд занимает полный пролёт при данной скорости прокрутки сцены.
/atom/movable/screen/parallax_layer/proc/FlybyDuration(scene_speed)
	return max(1, round(scene_speed * (FlybyDistance() / tile_size) / max(flyby_speed, 0.01), 1))

/// Матрица конца пролёта: масштаб слоя плюс уход на FlybyDistance() против движения.
/// Отдельным проком, чтобы её мог сверить тест, не дожидаясь конца анимации.
/atom/movable/screen/parallax_layer/proc/FlybyTarget(angle = 0)
	RETURN_TYPE(/matrix)
	var/matrix/target = BaseTransform()
	// Знак тот же, что у прокрутки тайлящихся слоёв: сцена уходит НАВСТРЕЧУ движению.
	var/distance = FlybyDistance()
	target.Translate(-sin(angle) * distance, -cos(angle) * distance)
	return target

/// Возвращает статику из пролёта на своё место. time = 0 - мгновенно.
/atom/movable/screen/parallax_layer/proc/StopFlyby(time = 0)
	if(!flying_by)
		return FALSE
	flying_by = FALSE
	if(time > 0)
		animate(src, transform = BaseTransform(), time = time, easing = QUAD_EASING | EASE_OUT, flags = ANIMATION_END_NOW)
	else
		animate(src, transform = BaseTransform(), time = 0, flags = ANIMATION_END_NOW)
	return TRUE

/// Ставит слою матрицу "яркость -> прозрачность". См. [luminance_alpha].
/atom/movable/screen/parallax_layer/proc/ApplyLuminanceMatrix(strength)
	luminance_alpha = strength
	color = list(
		1, 0, 0, strength,
		0, 1, 0, strength,
		0, 0, 1, strength,
		0, 0, 0, 1,
		0, 0, 0, luminance_alpha_offset
	)

/**
 * Пересобирает кэш строки screen_loc под текущие [tile_size] и [map_id].
 *
 * Тайловая часть якоря ВСЕГДА ровно CENTER, а центрирование картинки уходит в
 * пиксельный суффикс. Так делают все четыре донора со скайбоксами шире экрана,
 * и на то есть причина: тайловое смещение вида CENTER-11 указывает на тайл вне
 * сетки вьюпорта, а этого BYOND не любит.
 *
 * Позиционно это ТО ЖЕ САМОЕ, что было раньше: "CENTER-7" ставит левый нижний
 * угол картинки на 7*32 = 224 пикселя западнее CENTER, и "CENTER:-224" ставит
 * его туда же. Историческая геометрия 480 не сдвинулась ни на пиксель.
 */
/atom/movable/screen/parallax_layer/proc/UpdateScreenLocCache()
	anchor_offset = -(tile_size - world.icon_size) * 0.5
	screen_loc_prefix = "[map_id ? "[map_id]:" : ""]CENTER:"
	screen_loc_mid = ",CENTER:"

/atom/movable/screen/parallax_layer/proc/SetMapID(new_map_id)
	if(map_id == new_map_id)
		return
	map_id = new_map_id
	// У растянутых слоёв screen_loc записан на типе целиком ("WEST,SOUTH to
	// EAST,NORTH") и кэшем префиксов не собирается: id карты вешается на него
	// целиком. От типового значения, а не от текущего - иначе повторный вызов
	// приклеил бы второй префикс.
	if(layer_mode == PARALLAX_MODE_OVERLAY)
		screen_loc = "[map_id ? "[map_id]:" : ""][initial(screen_loc)]"
		return
	UpdateScreenLocCache()

/atom/movable/screen/parallax_layer/proc/ResetPosition(x, y)
	// Тонировка растянута по вьюпорту своим screen_loc: тронуть его - значит
	// стянуть фильтр в одну точку.
	if(layer_mode == PARALLAX_MODE_OVERLAY)
		return
	// remember that our offsets/directiosn are relative to the player's viewport
	// this means we need to scroll reverse to them.
	offset_x = -(center_x + speed * x)
	offset_y = -(center_y + speed * y)
	switch(layer_mode)
		if(PARALLAX_MODE_TILED)
			if(offset_x > tile_half)
				offset_x -= tile_size
			if(offset_x < -tile_half)
				offset_x += tile_size
			if(offset_y > tile_half)
				offset_y -= tile_size
			if(offset_y < -tile_half)
				offset_y += tile_size
		if(PARALLAX_MODE_SKYBOX)
			// Скайбокс не тайлится: вместо заворота зажимаем смещение в запас
			// картинки за краем вьюпорта, иначе в кадр въедет её край.
			offset_x = clamp(offset_x, -bleed_x, bleed_x)
			offset_y = clamp(offset_y, -bleed_y, bleed_y)
	screen_loc = "[screen_loc_prefix][round(offset_x,1) + anchor_offset][screen_loc_mid][round(offset_y,1) + anchor_offset]"

/// Scrolls the layer relative to an eye movement. Runs per layer on EVERY player move -
/// this is the hottest parallax proc on the server, keep it lean.
/// Returns TRUE if a glide animation was started, FALSE otherwise.
/atom/movable/screen/parallax_layer/proc/RelativePosition(x, y, rel_x, rel_y, anim_time = 0)
	if(absolute)
		ResetPosition(x, y)
		return FALSE
	var/old_visual_x = round(offset_x, 1)
	var/old_visual_y = round(offset_y, 1)
	offset_x -= rel_x * speed
	offset_y -= rel_y * speed
	var/wrapped = FALSE
	var/period = tile_size
	var/half = tile_half
	if(offset_x > half)
		offset_x -= period
		wrapped = TRUE
	if(offset_x < -half)
		offset_x += period
		wrapped = TRUE
	if(offset_y > half)
		offset_y -= period
		wrapped = TRUE
	if(offset_y < -half)
		offset_y += period
		wrapped = TRUE
	var/new_visual_x = round(offset_x, 1)
	var/new_visual_y = round(offset_y, 1)
	if(new_visual_x == old_visual_x && new_visual_y == old_visual_y)
		return FALSE // the screen_loc string would be byte-identical, nothing to update
	screen_loc = "[screen_loc_prefix][new_visual_x + anchor_offset][screen_loc_mid][new_visual_y + anchor_offset]"
	if(anim_time <= 0 || wrapped)
		return FALSE
	var/dx = old_visual_x - new_visual_x
	var/dy = old_visual_y - new_visual_y
	if(abs(dx) <= 1 && abs(dy) <= 1)
		// A 1px glide is indistinguishable from the instant screen_loc snap while the
		// viewport itself glides a full tile - skip the matrix alloc + animate(), which
		// used to be ~75-80% of this proc's cost.
		return FALSE
	transform = matrix(1, 0, dx, 0, 1, dy)
	animate(src, transform = matrix(), time = anim_time, flags = ANIMATION_END_NOW)
	return TRUE

#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
/**
 * Копия RelativePosition с историческими литералами 480/240 вместо переменных
 * геометрии. Существует ТОЛЬКО в тестовой сборке и только затем, чтобы бенчмарк
 * мог сравнить обобщённую версию с прежней в одном и том же процессе.
 * В игровой код не входит и вызываться из него не должна.
 */
/atom/movable/screen/parallax_layer/proc/LegacyRelativePosition(x, y, rel_x, rel_y, anim_time = 0)
	if(absolute)
		ResetPosition(x, y)
		return FALSE
	var/old_visual_x = round(offset_x, 1)
	var/old_visual_y = round(offset_y, 1)
	offset_x -= rel_x * speed
	offset_y -= rel_y * speed
	var/wrapped = FALSE
	if(offset_x > 240)
		offset_x -= 480
		wrapped = TRUE
	if(offset_x < -240)
		offset_x += 480
		wrapped = TRUE
	if(offset_y > 240)
		offset_y -= 480
		wrapped = TRUE
	if(offset_y < -240)
		offset_y += 480
		wrapped = TRUE
	var/new_visual_x = round(offset_x, 1)
	var/new_visual_y = round(offset_y, 1)
	if(new_visual_x == old_visual_x && new_visual_y == old_visual_y)
		return FALSE
	screen_loc = "[map_id && "[map_id]:"]CENTER-7:[new_visual_x],CENTER-7:[new_visual_y]"
	if(anim_time <= 0 || wrapped)
		return FALSE
	var/dx = old_visual_x - new_visual_x
	var/dy = old_visual_y - new_visual_y
	if(abs(dx) <= 1 && abs(dy) <= 1)
		return FALSE
	transform = matrix(1, 0, dx, 0, 1, dy)
	animate(src, transform = matrix(), time = anim_time, flags = ANIMATION_END_NOW)
	return TRUE
#endif

/atom/movable/screen/parallax_layer/proc/SetView(client_view = world.view, force_update = FALSE)
	if(view_current == client_view && !force_update)
		return
	view_current = client_view
	var/list/real_view = getviewsize(client_view)
	if(layer_mode == PARALLAX_MODE_SKYBOX)
		FitSkybox(real_view)
		return
	if(!dynamic_self_tile)
		return
	var/tiles_per_side = tile_size / world.icon_size
	var/count_x = CEILING((real_view[1] / 2) / tiles_per_side, 1) + 1
	var/count_y = CEILING((real_view[2] / 2) / tiles_per_side, 1) + 1
	var/list/natural_overlays = GetOverlays()
	var/list/new_overlays = natural_overlays.Copy()
	for(var/x in -count_x to count_x)
		for(var/y in -count_y to count_y)
			if(!x && !y)
				continue
			var/mutable_appearance/clone = new
			// appearance clone
			clone.icon = icon
			clone.icon_state = icon_state
			clone.overlays = natural_overlays
			// do NOT inherit our overlays! parallax layers should never have overlays,
			// because if it inherited us it'll result in exponentially increasing overlays
			// due to cut_overlays() above over there being a queue operation and not instant!
			// shift to position
			clone.transform = matrix(1, 0, x * tile_size, 0, 1, y * tile_size)
			new_overlays += clone
	overlays = new_overlays

/**
 * Подгоняет скайбокс под текущий вьюпорт.
 *
 * Картинка масштабируется так, чтобы перекрыть вьюпорт с запасом min_bleed по
 * каждой стороне, а фактический запас запоминается как предел смещения слоя.
 * Так край изображения не показывается ни при каком client.view, и при этом
 * скайбокс всё же немного плывёт вместе с игроком.
 */
/atom/movable/screen/parallax_layer/proc/FitSkybox(list/real_view)
	var/view_px_x = real_view[1] * world.icon_size
	var/view_px_y = real_view[2] * world.icon_size
	var/needed_x = view_px_x + min_bleed * 2
	var/needed_y = view_px_y + min_bleed * 2
	var/scale = max(base_scale, needed_x / tile_size, needed_y / tile_size)
	fitted_scale = scale
	var/covered = tile_size * scale
	// Нижняя граница здесь не косметика: covered считается через деление и обратное
	// умножение, и на 32-битных числах BYOND возвращает 1087.9999 вместо 1088.
	// Без max запас оказался бы на сотую пикселя меньше запрошенного.
	bleed_x = max(min_bleed, (covered - view_px_x) * 0.5)
	bleed_y = max(min_bleed, (covered - view_px_y) * 0.5)
	var/matrix/scale_matrix = matrix()
	scale_matrix.Scale(scale, scale)
	transform = scale_matrix

/atom/movable/screen/parallax_layer/proc/ShouldSee(client/C, atom/location)
	return TRUE

/**
 * Return "natural" overlays, as we're goin to do some fuckery to overlays above.
 */
/atom/movable/screen/parallax_layer/proc/GetOverlays()
	return list()

/atom/movable/screen/parallax_layer/proc/Clone()
	var/atom/movable/screen/parallax_layer/layer = new type
	layer.speed = speed
	layer.offset_x = offset_x
	layer.offset_y = offset_y
	layer.center_x = center_x
	layer.center_y = center_y
	layer.absolute = absolute
	layer.parallax_intensity = parallax_intensity
	layer.view_current = view_current
	layer.layer_mode = layer_mode
	layer.tile_size = tile_size
	layer.tile_half = tile_half
	layer.base_scale = base_scale
	layer.min_bleed = min_bleed
	layer.bleed_x = bleed_x
	layer.bleed_y = bleed_y
	layer.fitted_scale = fitted_scale
	layer.dynamic_self_tile = dynamic_self_tile
	layer.palette_tinted = palette_tinted
	layer.luminance_alpha = luminance_alpha
	layer.luminance_alpha_offset = luminance_alpha_offset
	layer.fade_in_time = fade_in_time
	layer.twinkle_time = twinkle_time
	layer.twinkle_min_alpha = twinkle_min_alpha
	layer.drift_time = drift_time
	layer.drift_angle = drift_angle
	layer.spawn_jitter_min = spawn_jitter_min
	layer.spawn_jitter_max = spawn_jitter_max
	layer.environment_flags = environment_flags
	layer.flyby_speed = flyby_speed
	layer.anchor_offset = anchor_offset
	layer.screen_loc_prefix = screen_loc_prefix
	layer.screen_loc_mid = screen_loc_mid
	layer.appearance = appearance
	return layer

/atom/movable/screen/parallax_layer/proc/default_x()
	return center_x

/atom/movable/screen/parallax_layer/proc/default_y()
	return center_y

/atom/movable/screen/parallax_layer/proc/QueueLoop(delay, speed, matrix/translate_matrix, matrix/target_matrix)
	if(queued_animation)
		CancelAnimation()
	queued_animation = addtimer(CALLBACK(src, PROC_REF(_loop), speed, translate_matrix, target_matrix), delay, TIMER_STOPPABLE)

/atom/movable/screen/parallax_layer/proc/_loop(speed, matrix/translate_matrix = matrix(1, 0, 0, 0, 1, 480), matrix/target_matrix = matrix())
	transform = translate_matrix
	animate(src, transform = target_matrix, time = speed, loop = -1)
	animate(transform = translate_matrix, time = 0)
	queued_animation = null

/atom/movable/screen/parallax_layer/proc/CancelAnimation()
	if(queued_animation)
		deltimer(queued_animation)
		queued_animation = null
