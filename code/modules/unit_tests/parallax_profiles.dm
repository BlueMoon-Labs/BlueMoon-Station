/// Профиль, существующий только в тестовой сборке. Вес 0 - автоподбор его не выберет,
/// поэтому он не может протечь в обычную игру, но даёт тестам детерминированную сцену.
/datum/parallax_profile/space/unit_test
	id = "unit_test_scene"
	name = "Тестовая сцена"
	base_layers = list(
		/atom/movable/screen/parallax_layer/space/layer_1,
		/atom/movable/screen/parallax_layer/space/layer_2,
	)
	variant_sets = list(
		list(1, /atom/movable/screen/parallax_layer/space/random/space_gas),
	)
	static_objects = list(/atom/movable/screen/parallax_layer/space/planet)
	palette = list("#112233")
	weight = 0

/datum/parallax_profile/space/unit_test_alt
	id = "unit_test_scene_alt"
	name = "Тестовая сцена, вариант"
	base_layers = list(/atom/movable/screen/parallax_layer/space/layer_3)
	weight = 0

/// Каталог профилей должен быть внутренне согласован: уникальные id, живые типпасы
/// слоёв, реально существующие icon_state и подъёмная стоимость сцены.
/// Опечатка в icon_state даёт в игре невидимый слой и никак иначе не ловится.
/datum/unit_test/parallax_profile_catalog/Run()
	TEST_ASSERT(length(SSparallax.profiles_by_id) > 0, "Каталог профилей параллакса пуст")
	var/list/icon_state_cache = list()

	// Сверяем icon_state У ВСЕХ типов слоёв, а не только у тех, что кто-то уже
	// положил в профиль: часть импортированного арта пока лежит про запас, и
	// опечатку в нём иначе никто не заметит до дня, когда его подключат.
	// Тип без icon_state - абстрактная середина иерархии, её пропускаем.
	for(var/atom/movable/screen/parallax_layer/layer_type as anything in subtypesof(/atom/movable/screen/parallax_layer))
		var/layer_state = initial(layer_type.icon_state)
		if(!layer_state)
			continue
		var/layer_icon = initial(layer_type.icon)
		TEST_ASSERT_NOTNULL(layer_icon, "Слой [layer_type] объявляет стейт '[layer_state]' без иконки")
		var/list/states = icon_state_cache["[layer_icon]"]
		if(!states)
			states = icon_states(layer_icon)
			icon_state_cache["[layer_icon]"] = states
		TEST_ASSERT(layer_state in states, "Слой [layer_type]: в [layer_icon] нет стейта '[layer_state]'")
	for(var/profile_id in SSparallax.profiles_by_id)
		var/datum/parallax_profile/profile = SSparallax.profiles_by_id[profile_id]
		TEST_ASSERT_EQUAL(profile.id, profile_id, "Профиль [profile.type] лежит в каталоге не под своим id")
		TEST_ASSERT(profile.type != profile.abstract_type, "Абстрактный профиль [profile.type] попал в каталог")

		var/moving = profile.MaxMovingLayers()
		TEST_ASSERT(moving <= PARALLAX_MAX_MOVING_LAYERS, "Профиль '[profile_id]' держит [moving] движущихся слоёв при потолке [PARALLAX_MAX_MOVING_LAYERS]")

		// length() тут обязателен: в DM `list += null` кладёт в список ЭЛЕМЕНТ null,
		// а не ничего, и дальше он приезжает в проверку типа как пустой путь.
		var/list/all_paths = list()
		if(length(profile.base_layers))
			all_paths += profile.base_layers
		if(length(profile.static_objects))
			all_paths += profile.static_objects
		if(profile.skybox)
			all_paths += profile.skybox
		for(var/list/set_entry as anything in profile.variant_sets)
			TEST_ASSERT(isnum(set_entry[1]) && set_entry[1] > 0, "Профиль '[profile_id]': вариант с некорректным весом [set_entry[1]]")
			for(var/i in 2 to length(set_entry))
				all_paths += set_entry[i]

		if(profile.backdrop)
			all_paths += profile.backdrop
		TEST_ASSERT(length(all_paths) > 0, "Профиль '[profile_id]' не объявляет ни одного слоя")

		// Подложка обязательна: без непрозрачного низа план космоса остаётся белым,
		// потому что план параллакса накладывается на него УМНОЖЕНИЕМ. Профиль без
		// подложки допустим только вместе с непрозрачным скайбоксом.
		TEST_ASSERT(profile.backdrop || profile.skybox, "Профиль '[profile_id]' без подложки и без скайбокса - космос покажет белые дыры")

		// Дрейф сцены уходит в get_parallax_motion как 4-кортеж, и параллакс
		// падает, если он не 4-кортеж или если скорость отрицательная.
		TEST_ASSERT(profile.ambient_speed >= 0, "Профиль '[profile_id]': отрицательная скорость дрейфа [profile.ambient_speed]")

		for(var/atom/movable/screen/parallax_layer/layer_type as anything in all_paths)
			TEST_ASSERT(ispath(layer_type, /atom/movable/screen/parallax_layer), "Профиль '[profile_id]' ссылается на не-слой [layer_type]")
			var/layer_icon = initial(layer_type.icon)
			var/layer_state = initial(layer_type.icon_state)
			TEST_ASSERT_NOTNULL(layer_icon, "Слой [layer_type] профиля '[profile_id]' без иконки")
			var/list/states = icon_state_cache["[layer_icon]"]
			if(!states)
				states = icon_states(layer_icon)
				icon_state_cache["[layer_icon]"] = states
			TEST_ASSERT(layer_state in states, "Слой [layer_type] профиля '[profile_id]': в [layer_icon] нет стейта '[layer_state]'")
			var/mode = initial(layer_type.layer_mode)
			TEST_ASSERT(mode in list(PARALLAX_MODE_TILED, PARALLAX_MODE_SKYBOX, PARALLAX_MODE_STATIC, PARALLAX_MODE_OVERLAY), "Слой [layer_type]: неизвестный режим [mode]")
			var/intensity = initial(layer_type.parallax_intensity)
			TEST_ASSERT(intensity >= PARALLAX_LOW && intensity <= PARALLAX_INSANE, "Слой [layer_type]: parallax_intensity [intensity] вне диапазона")
			// Строковый цвет палитры затёр бы матрицу яркости и вернул слою непрозрачность.
			TEST_ASSERT(!(initial(layer_type.palette_tinted) && initial(layer_type.luminance_alpha)), "Слой [layer_type] одновременно palette_tinted и с матрицей яркости")

		if(profile.skybox)
			var/atom/movable/screen/parallax_layer/skybox_type = profile.skybox
			TEST_ASSERT_EQUAL(initial(skybox_type.layer_mode), PARALLAX_MODE_SKYBOX, "Профиль '[profile_id]': [skybox_type] назначен скайбоксом, но объявлен другим режимом")

		// Варианты обязаны ЗАМЕНЯТЬ друг друга, а не складываться: иначе стоимость
		// сцены зависела бы от броска, а потолок движущихся слоёв ничего не значил.
		// Постоянная часть профиля - всё, кроме вариантов; сцена не имеет права
		// оказаться больше неё плюс один самый крупный набор.
		var/fixed = length(profile.base_layers) + length(profile.static_objects) + (profile.skybox ? 1 : 0) + (profile.backdrop ? 1 : 0)
		var/biggest_variant = 0
		for(var/list/set_entry as anything in profile.variant_sets)
			biggest_variant = max(biggest_variant, length(set_entry) - 1)
		for(var/attempt in 1 to 8)
			var/list/scene = profile.Build()
			var/built = length(scene)
			QDEL_LIST(scene)
			TEST_ASSERT(built <= fixed + biggest_variant, "Профиль '[profile_id]' собрал [built] слоёв при потолке [fixed + biggest_variant] - варианты складываются вместо замены")
			TEST_ASSERT(built >= fixed, "Профиль '[profile_id]' собрал [built] слоёв, потеряв часть постоянных из [fixed]")

/**
 * Крупный якорный объект обязан отсеиваться там, где ему не место.
 *
 * Планета за окном ЛЕТЯЩЕГО шаттла - это ровно тот баг, ради которого гейт и заведён:
 * статика не тайлится, прокручиваться не умеет и висит на экране неподвижно, пока
 * звёзды летят мимо. Гиперпространство местных ориентиров не имеет по определению.
 */
/datum/unit_test/parallax_static_environment_gate/Run()
	var/datum/parallax_profile/profile = SSparallax.profiles_by_id["space_classic"]
	TEST_ASSERT_NOTNULL(profile, "Классический профиль пропал из каталога")

	var/list/station_scene = profile.Build(null, null, PARALLAX_ENV_STATION)
	var/station_statics = 0
	for(var/atom/movable/screen/parallax_layer/layer as anything in station_scene)
		allocated += layer
		if(layer.layer_mode == PARALLAX_MODE_STATIC)
			station_statics++
	TEST_ASSERT(station_statics >= 1, "На станционном z из классической сцены пропала планета")

	var/list/transit_scene = profile.Build(null, null, PARALLAX_ENV_SHUTTLE)
	var/transit_layers = 0
	for(var/atom/movable/screen/parallax_layer/layer as anything in transit_scene)
		allocated += layer
		transit_layers++
		TEST_ASSERT(layer.layer_mode != PARALLAX_MODE_STATIC, "Слой [layer.type] остался в сцене летящего шаттла - планета будет висеть за окном неподвижно")
	TEST_ASSERT(transit_layers >= 1, "Гейт вырезал из сцены летящего шаттла вообще всё")

	// Сцена без окружения собирается целиком: у админского предпросмотра и вторичной
	// карты z нет, и молча терять там половину профиля гейт не имеет права.
	var/list/free_scene = profile.Build()
	var/free_statics = 0
	for(var/atom/movable/screen/parallax_layer/layer as anything in free_scene)
		allocated += layer
		if(layer.layer_mode == PARALLAX_MODE_STATIC)
			free_statics++
	TEST_ASSERT_EQUAL(free_statics, station_statics, "Сцена, собранная без окружения, потеряла статику")

	// Каждая планета в каталоге обязана нести гейт: без него профиль орбиты снова
	// выпадет транзитному уровню, и весь этот тест будет сторожить один тип из трёх.
	for(var/atom/movable/screen/parallax_layer/layer_type as anything in subtypesof(/atom/movable/screen/parallax_layer))
		if(initial(layer_type.layer_mode) != PARALLAX_MODE_STATIC)
			continue
		var/flags = initial(layer_type.environment_flags)
		TEST_ASSERT(flags, "Статический слой [layer_type] не объявляет окружения - он выпадет и летящему шаттлу")
		TEST_ASSERT(!(flags & PARALLAX_ENV_SHUTTLE), "Статический слой [layer_type] разрешён в гиперпространстве")
		// Проявление в Apply идёт с ANIMATION_END_NOW и заводится ПОСЛЕ прокрутки:
		// статике оно оборвало бы пролёт, швырнув объект сразу за край.
		TEST_ASSERT(!initial(layer_type.fade_in_time), "Статический слой [layer_type] объявляет проявление - оно оборвёт ему пролёт")

	// Явление, которое приходит в наш сектор, обязано сохранить планету: оно меняет
	// небо, но не переносит станцию. Проверка поимённая, потому что объявление сидит
	// на каждом профиле отдельно, и «уборка дублей» в общего родителя раздала бы мир
	// в небе планетарным погодам и астероидному поясу.
	for(var/in_sector_id in list("bluespace_storm", "graveyard", "micro_debris", "ion_blizzard"))
		var/datum/parallax_profile/in_sector = SSparallax.profiles_by_id[in_sector_id]
		TEST_ASSERT_NOTNULL(in_sector, "Профиль явления '[in_sector_id]' пропал из каталога")
		TEST_ASSERT(/atom/movable/screen/parallax_layer/space/planet in in_sector.static_objects, "Явление '[in_sector_id]' стирает планету со станционного неба")
	for(var/elsewhere_id in list("planet_snow", "planet_embers", "planet_dust", "asteroid_belt", "gas_giant"))
		var/datum/parallax_profile/elsewhere = SSparallax.profiles_by_id[elsewhere_id]
		TEST_ASSERT_NOTNULL(elsewhere, "Профиль '[elsewhere_id]' пропал из каталога")
		TEST_ASSERT(!length(elsewhere.static_objects), "Профиль '[elsewhere_id]' получил крупный объект в небо, хотя станцию не обслуживает")

	// Отсев не имеет права оставить от профиля одну подложку. Профиль, у которого весь
	// смысл в отсеиваемом слое, обязан и сам не объявлять это окружение - иначе
	// автоподбор выбирает между несколькими одинаковыми пустыми сценами.
	for(var/checked_id in SSparallax.profiles_by_id)
		var/datum/parallax_profile/checked = SSparallax.profiles_by_id[checked_id]
		for(var/environment in list(PARALLAX_ENV_STATION, PARALLAX_ENV_SPACE_RUINS, PARALLAX_ENV_PLANET, PARALLAX_ENV_SHUTTLE, PARALLAX_ENV_CENTCOM))
			if(!(checked.environment_flags & environment))
				continue
			var/list/scene = checked.Build(null, null, environment)
			var/meaningful = 0
			for(var/atom/movable/screen/parallax_layer/layer as anything in scene)
				if(layer.layer_mode != PARALLAX_MODE_OVERLAY)
					meaningful++
			QDEL_LIST(scene)
			TEST_ASSERT(meaningful >= 1, "Профиль '[checked_id]' в окружении [SSparallax.environment_name(environment)] собрался из одной подложки")

/**
 * Станция обязана всегда получать одну и ту же сцену, а разнообразие - жить в
 * остальном космосе.
 *
 * Это требование игроков, а не вкусовщина: лавовый мир за иллюминатором помечает
 * сектор, в котором висит станция, и по нему ориентируются. Случайный профиль на
 * станционном z этот ориентир отнимает, а один и тот же профиль в полёте и на
 * руинах отнимает смысл у самой метки.
 */
/datum/unit_test/parallax_station_profile_is_fixed/Run()
	var/list/station_candidates = list()
	var/list/all_environments = list(PARALLAX_ENV_STATION, PARALLAX_ENV_SPACE_RUINS, PARALLAX_ENV_PLANET, PARALLAX_ENV_SHUTTLE, PARALLAX_ENV_CENTCOM)
	var/list/candidates_by_environment = list()
	for(var/environment in all_environments)
		candidates_by_environment["[environment]"] = list()

	for(var/profile_id in SSparallax.profiles_by_id)
		var/datum/parallax_profile/profile = SSparallax.profiles_by_id[profile_id]
		if(profile.weight <= 0)
			continue // ставится только явно - событием, погодой или админом
		for(var/environment in all_environments)
			if(profile.environment_flags & environment)
				candidates_by_environment["[environment]"] += profile_id
	station_candidates = candidates_by_environment["[PARALLAX_ENV_STATION]"]

	TEST_ASSERT_EQUAL(length(station_candidates), 1, "Станционному z доступно [length(station_candidates)] профилей ([station_candidates.Join(", ")]) - фон перестал быть постоянным ориентиром")
	TEST_ASSERT_EQUAL(station_candidates[1], "space_classic", "Станция получила профиль '[station_candidates[1]]' вместо классической сцены с Лавалендом")
	TEST_ASSERT_EQUAL(SSparallax.environment_for_z(0), PARALLAX_ENV_SPACE_RUINS, "z без известных трейтов ошибочно считается станцией и получает Лаваленд")

	var/datum/parallax_profile/fallback = SSparallax.resolve_profile(SSparallax.fallback_profile_id)
	TEST_ASSERT_NOTNULL(fallback, "Запасной профиль '[SSparallax.fallback_profile_id]' отсутствует в каталоге")
	TEST_ASSERT(!(fallback.environment_flags & PARALLAX_ENV_STATION), "Запасной профиль '[fallback.id]' станционный - неизвестный внешний z получит Лаваленд")

	// Тот же профиль в остальном космосе обесценил бы метку станции.
	for(var/environment in all_environments)
		if(environment == PARALLAX_ENV_STATION)
			continue
		var/list/candidates = candidates_by_environment["[environment]"]
		TEST_ASSERT(!("space_classic" in candidates), "Станционная сцена доступна окружению [SSparallax.environment_name(environment)] - Лаваленд перестанет помечать станцию")
		TEST_ASSERT(!("orbit_lava" in candidates), "Лавовый мир доступен автоподбору окружения [SSparallax.environment_name(environment)] вне станции")
		// Пустой пул дошёл бы до запасного профиля и скрыл бы ошибку конфигурации.
		TEST_ASSERT(length(candidates) > 0, "Окружению [SSparallax.environment_name(environment)] не досталось ни одного профиля - автоподбор свалится в запасной")

/**
 * Сцена антагониста ложится ПОВЕРХ сцены уровня и не имеет права её подменять:
 * станция обязана сохранить свой ориентир, пока небо багровеет.
 */
/datum/unit_test/parallax_antag_scenes/Run()
	TEST_ASSERT(length(GLOB.antag_parallax_scenes) >= 7, "Сцен антагонистов всего [length(GLOB.antag_parallax_scenes)] - культ и четыре пути еретика не покрыты")
	for(var/scene_key in GLOB.antag_parallax_scenes)
		var/list/scene_layers = GLOB.antag_parallax_scenes[scene_key]
		TEST_ASSERT(length(scene_layers) > 0, "Сцена '[scene_key]' пуста")
		var/tints = 0
		for(var/atom/movable/screen/parallax_layer/layer_type as anything in scene_layers)
			TEST_ASSERT(ispath(layer_type, /atom/movable/screen/parallax_layer), "Сцена '[scene_key]' ссылается на не-слой [layer_type]")
			var/mode = initial(layer_type.layer_mode)
			// Скайбокс и статика перекрыли бы собой планету, ради сохранения которой
			// сцены и сделаны накладными.
			TEST_ASSERT(mode != PARALLAX_MODE_SKYBOX, "Сцена '[scene_key]': слой [layer_type] - скайбокс, он закроет собой станционный фон")
			TEST_ASSERT(mode != PARALLAX_MODE_STATIC, "Сцена '[scene_key]': слой [layer_type] - крупный объект, ему не место поверх чужой сцены")
			if(mode == PARALLAX_MODE_OVERLAY)
				tints++
		TEST_ASSERT_EQUAL(tints, 1, "Сцена '[scene_key]' несёт [tints] тонировок вместо одной")

	// Постановка и снятие идут через штатный стек модификаторов.
	var/test_z = 1
	SSparallax.add_layers(test_z, ANTAG_PARALLAX_TOKEN_CULT, GLOB.antag_parallax_scenes[ANTAG_SCENE_CULT_RISEN], PARALLAX_PRIORITY_ANTAG)
	var/datum/parallax_modifier/placed = SSparallax.find_modifier(test_z, ANTAG_PARALLAX_TOKEN_CULT)
	TEST_ASSERT_NOTNULL(placed, "Сцена культа не легла на z [test_z]")
	TEST_ASSERT_EQUAL(placed.priority, PARALLAX_PRIORITY_ANTAG, "Сцена культа легла с приоритетом [placed.priority]")
	TEST_ASSERT(placed.priority > PARALLAX_PRIORITY_EVENT + 1, "Сцена антагониста не перебивает пиковый слой космической погоды")
	TEST_ASSERT_NULL(placed.profile, "Сцена антагониста подменила профиль уровня вместо наложения слоёв")

	// Усиление ступени заменяет запись, а не складывается с ней.
	SSparallax.add_layers(test_z, ANTAG_PARALLAX_TOKEN_CULT, GLOB.antag_parallax_scenes[ANTAG_SCENE_CULT_ASCENDENT], PARALLAX_PRIORITY_ANTAG)
	var/tokens_on_z = 0
	for(var/datum/parallax_modifier/modifier as anything in SSparallax.modifiers_by_z["[test_z]"])
		if(modifier.token == ANTAG_PARALLAX_TOKEN_CULT)
			tokens_on_z++
	TEST_ASSERT_EQUAL(tokens_on_z, 1, "Вторая ступень культа завела [tokens_on_z] модификаторов вместо замены первой")

	TEST_ASSERT(SSparallax.remove_modifier(test_z, ANTAG_PARALLAX_TOKEN_CULT), "Сцена культа не снялась")
	TEST_ASSERT_NULL(SSparallax.find_modifier(test_z, ANTAG_PARALLAX_TOKEN_CULT), "После снятия модификатор культа остался в стеке")

/// Каждый путь вознесения еретика обязан объявить свою сцену, иначе три из четырёх
/// вознесений молча не меняют ничего, и заметить это можно только в игре.
/datum/unit_test/parallax_heretic_ascension_scenes/Run()
	var/checked = 0
	for(var/datum/eldritch_knowledge/final_eldritch/final_type as anything in subtypesof(/datum/eldritch_knowledge/final_eldritch))
		var/scene_key = initial(final_type.parallax_scene)
		checked++
		TEST_ASSERT_NOTNULL(scene_key, "Вознесение [final_type] не объявляет сцену параллакса")
		TEST_ASSERT(length(GLOB.antag_parallax_scenes[scene_key]) > 0, "Вознесение [final_type] ссылается на несуществующую сцену '[scene_key]'")
	TEST_ASSERT_EQUAL(checked, 4, "Путей вознесения нашлось [checked] вместо четырёх - тест смотрит не туда")

/// Выбор профиля обязан быть единым на z, стабильным весь раунд и независимым между z.
/datum/unit_test/parallax_profile_selection/Run()
	var/datum/parallax_profile/first_call = SSparallax.get_base_profile(1)
	TEST_ASSERT_NOTNULL(first_call, "Для z 1 не выбрался ни один профиль")
	var/datum/parallax_profile/second_call = SSparallax.get_base_profile(1)
	TEST_ASSERT_EQUAL(first_call, second_call, "Повторный запрос профиля z 1 дал другой профиль - выбор не стабилен")

	// Независимость: закрепление профиля за одним z не должно трогать соседний.
	var/datum/parallax_profile/before_z2 = SSparallax.get_base_profile(2)
	SSparallax.set_base_profile(1, "unit_test_scene")
	TEST_ASSERT_EQUAL(SSparallax.get_base_profile(1), SSparallax.profiles_by_id["unit_test_scene"], "set_base_profile не закрепил профиль за z 1")
	TEST_ASSERT_EQUAL(SSparallax.get_base_profile(2), before_z2, "Смена профиля на z 1 утащила за собой z 2")

	// Возврат исходного состояния, чтобы не влиять на соседние тесты.
	SSparallax.base_profile_by_z["1"] = first_call
	SSparallax.invalidate_z(1)

/// Шаблон z обязан пересобираться при смене профиля, даже если DM-тип не изменился.
/datum/unit_test/parallax_template_invalidation/Run()
	var/datum/parallax_profile/original = SSparallax.get_base_profile(1)

	SSparallax.set_base_profile(1, "unit_test_scene")
	var/datum/parallax/first_template = SSparallax.get_parallax_template(1)
	TEST_ASSERT_NOTNULL(first_template, "Шаблон z 1 не собрался")
	TEST_ASSERT_EQUAL(first_template.profile_id, "unit_test_scene", "Шаблон собран не из закреплённого профиля")

	// Повторный запрос без изменений обязан вернуть тот же объект - иначе каждый
	// Reset клиента заново создавал бы все экранные объекты уровня.
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(1), first_template, "Шаблон пересобрался без причины")

	// Смена на профиль ТОГО ЖЕ DM-типа: раньше кэш сравнивал типы и не заметил бы подмены.
	SSparallax.set_base_profile(1, "unit_test_scene_alt")
	var/datum/parallax/second_template = SSparallax.get_parallax_template(1)
	TEST_ASSERT_NOTEQUAL(second_template, first_template, "Шаблон не пересобрался после смены профиля")
	TEST_ASSERT_EQUAL(second_template.profile_id, "unit_test_scene_alt", "Пересобранный шаблон помнит старый профиль")

	// Инвалидация одного z не имеет права трогать соседний: сцены независимы,
	// и переключение обязано доходить только до своего уровня.
	var/datum/parallax/z2_template = SSparallax.get_parallax_template(2)
	TEST_ASSERT_NOTNULL(z2_template, "Шаблон z 2 не собрался")
	SSparallax.invalidate_z(1)
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(2), z2_template, "Инвалидация z 1 пересобрала шаблон z 2")

	SSparallax.base_profile_by_z["1"] = original
	SSparallax.invalidate_z(1)

/// Модификаторы складываются по приоритету и снимаются по токену в ЛЮБОМ порядке,
/// не восстанавливая чужое устаревшее состояние.
/datum/unit_test/parallax_modifier_stack/Run()
	var/datum/parallax_profile/original = SSparallax.get_base_profile(1)
	SSparallax.set_base_profile(1, "unit_test_scene")

	SSparallax.set_profile(1, "unit_test_scene_alt", "event_low", 0)
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(1).profile_id, "unit_test_scene_alt", "Модификатор не подменил профиль")

	SSparallax.set_profile(1, "unit_test_scene", "event_high", 10)
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(1).profile_id, "unit_test_scene", "Старший приоритет не перебил младший")

	// Снятие младшего первым: старший обязан остаться в силе.
	TEST_ASSERT(SSparallax.remove_modifier(1, "event_low"), "Модификатор event_low не снялся")
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(1).profile_id, "unit_test_scene", "Снятие младшего модификатора сбросило старший")

	TEST_ASSERT(SSparallax.remove_modifier(1, "event_high"), "Модификатор event_high не снялся")
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(1).profile_id, "unit_test_scene", "Стек не опустел до базового профиля")

	// Обратный порядок снятия.
	SSparallax.set_profile(1, "unit_test_scene_alt", "event_low", 0)
	SSparallax.set_profile(1, "unit_test_scene", "event_high", 10)
	TEST_ASSERT(SSparallax.remove_modifier(1, "event_high"), "Модификатор event_high не снялся при обратном порядке")
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(1).profile_id, "unit_test_scene_alt", "После снятия старшего не вернулся младший")
	TEST_ASSERT(SSparallax.remove_modifier(1, "event_low"), "Модификатор event_low не снялся при обратном порядке")

	TEST_ASSERT(!length(SSparallax.modifiers_by_z["1"]), "Стек модификаторов z 1 не опустел")
	TEST_ASSERT(!SSparallax.remove_modifier(1, "never_added"), "Снятие несуществующего токена отчиталось успехом")

	SSparallax.base_profile_by_z["1"] = original
	SSparallax.invalidate_z(1)

/// Временные слои добавляются поверх сцены и уходят вместе со своим токеном,
/// не оставляя за собой ни объектов, ни записей в стеке.
/datum/unit_test/parallax_temporary_layers/Run()
	var/datum/parallax_profile/original = SSparallax.get_base_profile(1)
	SSparallax.set_base_profile(1, "unit_test_scene")
	var/baseline = length(SSparallax.get_parallax_template(1).objects)

	SSparallax.add_layers(1, "weather", list(/atom/movable/screen/parallax_layer/space/random/asteroids))
	TEST_ASSERT_EQUAL(length(SSparallax.get_parallax_template(1).objects), baseline + 1, "Временный слой не добавился в сцену")

	SSparallax.set_tint(1, "tint", "#ff0000")
	var/datum/parallax/tinted = SSparallax.get_parallax_template(1)
	var/found_tinted = FALSE
	for(var/atom/movable/screen/parallax_layer/layer as anything in tinted.objects)
		if(layer.palette_tinted)
			found_tinted = TRUE
			TEST_ASSERT_EQUAL(layer.color, "#ff0000", "Слой с palette_tinted не перекрасился модификатором")
	TEST_ASSERT(found_tinted, "В тестовой сцене не оказалось ни одного слоя с palette_tinted")

	SSparallax.remove_modifier(1, "tint")
	SSparallax.remove_modifier(1, "weather")
	TEST_ASSERT_EQUAL(length(SSparallax.get_parallax_template(1).objects), baseline, "После снятия токенов сцена не вернулась к исходной")

	SSparallax.base_profile_by_z["1"] = original
	SSparallax.invalidate_z(1)

/**
 * Адресный цвет слоя обязан пережить пересборку сцены.
 *
 * Явление тянет подсветку только на смене интенсивности, а на плато пика она стоит на
 * единице. Любой чужой модификатор, легший на z в это время, выбрасывает шаблон, и без
 * запоминания цвета явление доигрывало бы пик вообще без подсветки - до самого ухода.
 */
/datum/unit_test/parallax_layer_color_survives_rebuild/Run()
	var/datum/parallax_profile/original = SSparallax.get_base_profile(1)
	SSparallax.set_base_profile(1, "unit_test_scene")

	var/layer_type = /atom/movable/screen/parallax_layer/tint/phenomenon
	SSparallax.add_layers(1, "phenomenon", list(layer_type))
	// Сцена должна существовать до покраски: add_layers её инвалидировал, а красить
	// нечего, пока шаблон не собран заново.
	SSparallax.get_parallax_template(1)
	var/painted = SSparallax.animate_layer_type(1, layer_type, "#3399ff")

	// Ровно то, что делает посреди явления любой чужой источник параллакса.
	SSparallax.invalidate_z(1)
	var/rebuilt_color
	for(var/atom/movable/screen/parallax_layer/layer as anything in SSparallax.get_parallax_template(1).objects)
		if(layer.type == layer_type)
			rebuilt_color = layer.color

	SSparallax.remove_modifier(1, "phenomenon")
	SSparallax.base_profile_by_z["1"] = original
	SSparallax.invalidate_z(1)

	TEST_ASSERT(painted, "animate_layer_type не нашёл слой явления в собранной сцене")
	TEST_ASSERT_EQUAL(rebuilt_color, "#3399ff", "Цвет слоя явления не пережил пересборку сцены - стало '[rebuilt_color]'")

/// Настройка качества обязана отсекать слои по parallax_intensity, а выключенный
/// параллакс и lag switch - не рисовать ничего.
/datum/unit_test/parallax_quality_filter/Run()
	var/datum/parallax_profile/profile = SSparallax.profiles_by_id["space_classic"]
	TEST_ASSERT_NOTNULL(profile, "Классический профиль пропал из каталога")
	var/list/scene = profile.Build()
	for(var/atom/movable/screen/parallax_layer/layer as anything in scene)
		allocated += layer

	var/list/visible_at = list()
	for(var/quality in list(PARALLAX_DISABLE, PARALLAX_LOW, PARALLAX_MED, PARALLAX_HIGH, PARALLAX_INSANE))
		var/count = 0
		for(var/atom/movable/screen/parallax_layer/layer as anything in scene)
			if(layer.parallax_intensity <= quality)
				count++
		visible_at["[quality]"] = count

	TEST_ASSERT_EQUAL(visible_at["[PARALLAX_DISABLE]"], 0, "При выключенном параллаксе остались видимые слои")
	TEST_ASSERT(visible_at["[PARALLAX_LOW]"] >= 1, "На минимальном качестве не видно ни одного слоя")
	for(var/i in list(PARALLAX_MED, PARALLAX_HIGH, PARALLAX_INSANE))
		TEST_ASSERT(visible_at["[i]"] >= visible_at["[i - 1]"], "Качество [i] показывает меньше слоёв, чем [i - 1]")
	TEST_ASSERT(visible_at["[PARALLAX_INSANE]"] > visible_at["[PARALLAX_LOW]"], "Максимальное качество не добавляет ни одного слоя к минимальному")

/// Дрейф сцены обязан достаться только тайлящимся слоям и быть обратно
/// пропорциональным их скорости: ближний слой проходит экран быстрее дальнего.
/datum/unit_test/parallax_ambient_drift/Run()
	var/datum/parallax_profile/drifting = SSparallax.profiles_by_id["planet_snow_storm"]
	TEST_ASSERT_NOTNULL(drifting, "Профиль метели пропал из каталога")
	TEST_ASSERT(drifting.ambient_speed > 0, "У метели нет собственного дрейфа - сцена будет стоять на месте")

	var/list/scene = drifting.Build()
	for(var/atom/movable/screen/parallax_layer/layer as anything in scene)
		allocated += layer

	var/fastest_drift = INFINITY
	var/slowest_drift = 0
	var/tiled_seen = 0
	for(var/atom/movable/screen/parallax_layer/layer as anything in scene)
		if(layer.layer_mode != PARALLAX_MODE_TILED)
			TEST_ASSERT_EQUAL(layer.drift_time, 0, "Слой [layer.type] в режиме [layer.layer_mode] получил дрейф, хотя дрейфуют только тайлящиеся")
			continue
		tiled_seen++
		TEST_ASSERT(layer.drift_time > 0, "Тайлящийся слой [layer.type] остался без дрейфа")
		TEST_ASSERT_EQUAL(layer.drift_time, drifting.ambient_speed / layer.speed, "Слой [layer.type]: дрейф не обратно пропорционален скорости")
		TEST_ASSERT_EQUAL(layer.drift_angle, drifting.ambient_angle, "Слой [layer.type]: угол дрейфа не от профиля")
		fastest_drift = min(fastest_drift, layer.drift_time)
		slowest_drift = max(slowest_drift, layer.drift_time)

	TEST_ASSERT(tiled_seen >= 2, "В сцене метели меньше двух тайлящихся слоёв - глубину дрейфа не на чем показать")
	TEST_ASSERT(fastest_drift < slowest_drift, "Все слои дрейфуют с одной скоростью - параллакса в движении не будет")

	// У профиля без дрейфа слои обязаны остаться неподвижными.
	var/datum/parallax_profile/still = SSparallax.profiles_by_id["diagnostic"]
	TEST_ASSERT_NOTNULL(still, "Калибровочный профиль пропал из каталога")
	TEST_ASSERT_EQUAL(still.ambient_speed, 0, "Калибровочная мишень поехала - по ней нечего будет выверять")
	var/list/still_scene = still.Build()
	for(var/atom/movable/screen/parallax_layer/layer as anything in still_scene)
		allocated += layer
		TEST_ASSERT_EQUAL(layer.drift_time, 0, "Слой [layer.type] неподвижного профиля получил дрейф")

/// Постройка сцены не должна оставлять за собой висящих таймеров.
/// Таймер тут заводит только анимация прокрутки, и она обязана сниматься.
/datum/unit_test/parallax_scene_teardown/Run()
	var/datum/parallax_profile/profile = SSparallax.profiles_by_id["space_classic"]
	var/datum/parallax/scene = new(profile)
	TEST_ASSERT(length(scene.objects) > 0, "Сцена собралась пустой")

	var/atom/movable/screen/parallax_layer/probe = scene.objects[1]
	probe.QueueLoop(10, 10, matrix(), matrix())
	TEST_ASSERT_NOTNULL(probe.queued_animation, "QueueLoop не завёл таймер")
	probe.CancelAnimation()
	TEST_ASSERT_NULL(probe.queued_animation, "CancelAnimation не снял таймер")

	qdel(scene)
	TEST_ASSERT(QDELETED(probe), "Слой пережил удаление своей сцены")

/// У каждого события космической погоды профиль обязан существовать в каталоге, а
/// токен - быть уникальным. Опечатка в id даёт событие, которое молча ничего не
/// делает: объявление выходит, картинка не меняется.
/datum/unit_test/parallax_event_profiles/Run()
	var/list/seen_tokens = list()
	var/checked = 0
	for(var/datum/round_event_control/space_weather/control as anything in subtypesof(/datum/round_event_control/space_weather))
		var/datum/round_event/space_weather/event_type = initial(control.typepath)
		if(!event_type)
			continue
		var/event_profile = initial(event_type.profile_id)
		var/event_token = initial(event_type.token)
		if(!event_profile && !event_token)
			continue // абстрактная середина ветки
		checked++
		TEST_ASSERT_NOTNULL(event_profile, "Событие [event_type] без профиля параллакса")
		TEST_ASSERT_NOTNULL(event_token, "Событие [event_type] без токена модификатора")
		TEST_ASSERT_NOTNULL(SSparallax.profiles_by_id[event_profile], "Событие [event_type] ссылается на несуществующий профиль '[event_profile]'")
		TEST_ASSERT(!seen_tokens[event_token], "Токен '[event_token]' занят и событием [event_type], и [seen_tokens[event_token]] - они будут снимать модификаторы друг друга")
		seen_tokens[event_token] = event_type
	TEST_ASSERT(checked >= 3, "Событий космической погоды нашлось всего [checked] - тест ничего не проверяет")

	// То же для погоды: профиль бури обязан существовать.
	var/weather_checked = 0
	for(var/datum/weather/weather_type as anything in subtypesof(/datum/weather))
		var/weather_profile = initial(weather_type.parallax_profile)
		if(!weather_profile)
			continue
		weather_checked++
		TEST_ASSERT_NOTNULL(SSparallax.profiles_by_id[weather_profile], "Погода [weather_type] ссылается на несуществующий профиль '[weather_profile]'")
	TEST_ASSERT(weather_checked >= 3, "Погод с профилем параллакса нашлось всего [weather_checked]")

