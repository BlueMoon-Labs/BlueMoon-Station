/**
 * # Профиль параллакса
 *
 * Декларативное описание одной визуальной сцены за бортом: какие слои её
 * составляют, какая у неё палитра, где она уместна и откуда взяты ассеты.
 *
 * Профиль - синглтон. Экземпляров у него нет: каталог строится один раз в
 * SSparallax по подтипам, а разрешённый под конкретный z набор объектов живёт
 * в /datum/parallax, который делится всеми клиентами этого z.
 *
 * Отдельным DM-типом стоит заводить отдельное ИЗОБРАЖЕНИЕ. Цветовые вариации,
 * позиция планеты и выбор дополнительного слоя выражаются данными профиля.
 */
/datum/parallax_profile
	/// Стабильный идентификатор. Уникален по каталогу, переживает переименования типов,
	/// на него ссылаются конфиг карты, z-трейт и админский инструмент.
	var/id
	/// Человекочитаемое имя для админских списков.
	var/name = "Безымянный профиль"
	/// Слои, которые есть в профиле всегда. Список типпасов.
	var/list/base_layers
	/**
	 * Взаимоисключающие наборы дополнительных слоёв. Ровно один набор на z-уровень.
	 * Формат: список списков, где первый элемент - вес, остальные - типпасы слоёв.
	 * Пустой набор (только вес) означает "без дополнительного слоя".
	 *
	 *   variant_sets = list(
	 *       list(35, /atom/movable/screen/parallax_layer/space/asteroids),
	 *       list(30),
	 *   )
	 */
	var/list/variant_sets
	/**
	 * Непрозрачная подложка под всей сценой.
	 *
	 * Не украшение, а обязательный слой. План параллакса накладывается на план
	 * космоса УМНОЖЕНИЕМ, а плану космоса держатель ставит матрицу "альфа ->
	 * белый". Поэтому там, где у сцены нет непрозрачных пикселей, умножать нечего
	 * и космос остаётся БЕЛЫМ. Историческим слоям это сходило с рук: layer1
	 * непрозрачен целиком. Донорский арт почти весь с альфой, и без подложки
	 * профиль показывает белые дыры.
	 *
	 * null ставится только тогда, когда непрозрачность гарантирует сам профиль.
	 */
	var/backdrop = /atom/movable/screen/parallax_layer/backdrop
	/// Крупный нетайлящийся фон под всем остальным. Один типпас или null.
	var/skybox
	/**
	 * Собственный дрейф сцены: децисекунды на проход своего тайла слоем скорости 1.
	 * 0 - сцена стоит на месте и оживает только от шага игрока.
	 *
	 * Раздаётся тайлящимся слоям при постройке и делится на скорость слоя: ближний
	 * слой обязан проходить экран быстрее дальнего, иначе параллакс выворачивается.
	 */
	var/ambient_speed = 0
	/// Угол дрейфа, по часовой стрелке от севера.
	var/ambient_angle = 0
	/// Крупные статические объекты - планеты, кольца, обломки. Список типпасов.
	var/list/static_objects
	/// Цвета, которыми красятся слои с palette_tinted. Один цвет на z-уровень.
	var/list/palette
	/// Уровень качества, начиная с которого профиль выглядит как задумано.
	/// Справочное поле: фильтрация идёт по parallax_intensity каждого слоя,
	/// потому что шаблон общий на z, а настройка качества - у каждого клиента своя.
	var/min_quality = PARALLAX_LOW
	/// Трейты z-уровня, на которых профиль уместен. Пусто - подходит всем.
	var/list/z_traits
	/// Где профиль разрешён, битфилд PARALLAX_ENV_*.
	var/environment_flags = PARALLAX_ENV_STATION
	/// Вес в автоподборе. 0 - профиль ставится только явно.
	var/weight = 0
	/// Откуда взяты ассеты. Полная выкладка - в icons/effects/parallax/ATTRIBUTION.md.
	var/source = "BlueMoon Station"
	/// Абстрактный корень ветки - такие типы в каталог не попадают.
	var/abstract_type = /datum/parallax_profile

/**
 * Собирает набор объектов слоёв для одного z-уровня.
 *
 * Вся случайность профиля разрешается здесь и ровно один раз: результат
 * кладётся в шаблон /datum/parallax, общий для всех клиентов этого z. Поэтому
 * сцена одинакова у всех на z, стабильна весь раунд и независима между z.
 *
 * @param extra_layers - типпасы, добавленные модификаторами поверх профиля.
 * @param tint - цвет, которым модификатор перекрашивает слои с palette_tinted.
 * @param environment - окружение z, PARALLAX_ENV_*. Слои, которым оно не подходит,
 *   в сцену не попадают. NONE - собрать профиль целиком (админский предпросмотр,
 *   вторичные карты, тесты - там z либо нет, либо он не решает).
 */
/datum/parallax_profile/proc/Build(list/extra_layers, tint, environment = NONE)
	. = list()
	var/chosen_tint = tint || (length(palette) ? pick(palette) : null)

	if(backdrop)
		. += InstantiateLayerOrNothing(backdrop, null, environment)

	if(skybox)
		. += InstantiateLayerOrNothing(skybox, chosen_tint, environment)

	for(var/layer_path in base_layers)
		. += InstantiateLayerOrNothing(layer_path, chosen_tint, environment)

	var/list/variant = PickVariant()
	for(var/layer_path in variant)
		. += InstantiateLayerOrNothing(layer_path, chosen_tint, environment)

	for(var/layer_path in extra_layers)
		. += InstantiateLayerOrNothing(layer_path, chosen_tint, environment)

	for(var/layer_path in static_objects)
		. += InstantiateLayerOrNothing(layer_path, chosen_tint, environment)

/**
 * Обёртка для сложения в список сцены.
 *
 * В DM `list += null` кладёт в список ЭЛЕМЕНТ null, а не ничего, и отброшенный
 * слой доехал бы до GetObjects() как дырка. Поэтому негодный путь возвращается
 * ПУСТЫМ СПИСКОМ: его сложение действительно ничего не добавляет.
 */
/datum/parallax_profile/proc/InstantiateLayerOrNothing(layer_path, tint, environment = NONE)
	var/atom/movable/screen/parallax_layer/new_layer = InstantiateLayer(layer_path, tint, environment)
	return new_layer ? list(new_layer) : list()

/// Взвешенно выбирает один набор из [variant_sets]. Возвращает список типпасов.
/datum/parallax_profile/proc/PickVariant()
	if(!length(variant_sets))
		return list()
	var/total = 0
	for(var/list/set_entry as anything in variant_sets)
		total += set_entry[1]
	if(total <= 0)
		return list()
	var/roll = rand() * total
	for(var/list/set_entry as anything in variant_sets)
		roll -= set_entry[1]
		if(roll > 0)
			continue
		if(length(set_entry) < 2)
			return list()
		return set_entry.Copy(2)
	return list()

/// Создаёт один слой и применяет к нему данные профиля. null при негодном пути
/// и при слое, которому не подходит окружение уровня.
/datum/parallax_profile/proc/InstantiateLayer(layer_path, tint, environment = NONE)
	// Профили сверяет юнит-тест каталога, но слои приходят ещё и от модификаторов,
	// то есть от произвольного вызывающего. Мусор в сцене уронил бы GetObjects()
	// на каждом Reset клиента, а не в момент ошибки.
	if(!ispath(layer_path, /atom/movable/screen/parallax_layer))
		stack_trace("Профиль '[id]': '[layer_path]' не является слоем параллакса, пропущен")
		return null
	// Отсев по initial(), ДО создания объекта: слой, которому не место на этом
	// уровне, не должен ни существовать, ни клонироваться клиентам.
	var/atom/movable/screen/parallax_layer/layer_type = layer_path
	var/layer_environments = initial(layer_type.environment_flags)
	if(environment && layer_environments && !(layer_environments & environment))
		return null
	var/atom/movable/screen/parallax_layer/new_layer = new layer_path
	// Идемпотентно и дёшево, зато снимает зависимость от того, успел ли отработать
	// Initialize: во время инициализации мира SSatoms откладывает его на потом.
	new_layer.ApplyLayerMode()
	if(ambient_speed > 0 && new_layer.layer_mode == PARALLAX_MODE_TILED && !new_layer.drift_time)
		new_layer.drift_time = ambient_speed / max(new_layer.speed, 0.05)
		new_layer.drift_angle = ambient_angle
	if(new_layer.spawn_jitter_max)
		new_layer.pixel_x = rand(new_layer.spawn_jitter_min, new_layer.spawn_jitter_max)
		new_layer.pixel_y = rand(new_layer.spawn_jitter_min, new_layer.spawn_jitter_max)
	// color у такого слоя занят матрицей яркости, строковый цвет её затрёт и
	// вернёт непрозрачность. Красить его можно только другой матрицей.
	if(tint && new_layer.palette_tinted && !new_layer.luminance_alpha)
		new_layer.add_atom_colour(tint, ADMIN_COLOUR_PRIORITY)
	return new_layer

/// Число тайлящихся слоёв в худшем случае - по нему юнит-тест сверяет потолок стоимости.
/datum/parallax_profile/proc/MaxMovingLayers()
	. = 0
	for(var/atom/movable/screen/parallax_layer/layer_type as anything in base_layers)
		if(initial(layer_type.layer_mode) == PARALLAX_MODE_TILED)
			.++
	var/worst_variant = 0
	for(var/list/set_entry as anything in variant_sets)
		var/count = 0
		for(var/i in 2 to length(set_entry))
			var/atom/movable/screen/parallax_layer/layer_type = set_entry[i]
			if(initial(layer_type.layer_mode) == PARALLAX_MODE_TILED)
				count++
		worst_variant = max(worst_variant, count)
	. += worst_variant
