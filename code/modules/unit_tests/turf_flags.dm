/**
 * Типовые дефолты битовой укладки turf_flags.
 *
 * Одиннадцать булевых переменных турфа (intact, tiled_dirt, bullet_sizzle и прочие) свёрнуты
 * в одно поле ради адресного пространства: каждый слот на 1.2 млн турфов стоил 6.4 МБ.
 * Плата за это - типовые дефолты перестали складываться сами: подтип обязан писать ПОЛНОЕ
 * значение, а не один флаг. Ошибка в композите тихая: пол просто перестаёт быть целым или
 * начинает копить грязь там, где не должен, и ловится только в раунде.
 *
 * Поэтому здесь проверяются опорные точки дерева турфов, а не поведение процедур.
 */
/datum/unit_test/turf_flag_defaults
	requires_full_map = FALSE

/// Сверяет типовой дефолт turf_flags. Путь принимается типизированной переменной:
/// initial() умеет читать поле по пути только через неё, а не по литералу.
/datum/unit_test/turf_flag_defaults/proc/check_flags(turf/checked_path, expected, description)
	var/actual = initial(checked_path.turf_flags)
	if(actual == expected)
		return
	TEST_FAIL("[checked_path]: turf_flags = [actual], ожидалось [expected] ([description])")

/datum/unit_test/turf_flag_defaults/Run()
	// База: пол цел, свет динамический, грязь не копится, плиточной декали нет.
	check_flags(/turf, TURF_FLAGS_DEFAULT, "дефолт всего дерева")
	check_flags(/turf/closed/wall, TURF_FLAGS_DEFAULT, "стена ничего не меняет")

	// Пол: копит грязь и носит плиточную декаль.
	check_flags(/turf/open/floor, TURF_FLAGS_FLOOR, "базовый пол")
	check_flags(/turf/open/floor/plasteel, TURF_FLAGS_FLOOR, "плистил наследует пол без правок")

	// Провода поверх: плитинг, стекло и опенспейс не целы.
	check_flags(/turf/open/floor/plating, TURF_FLAGS_FLOOR & ~TURF_INTACT, "плитинг не цел")
	check_flags(/turf/open/floor/glass, TURF_FLAGS_FLOOR & ~TURF_INTACT, "стеклянный пол не цел")
	check_flags(/turf/open/openspace, TURF_FLAGS_DEFAULT & ~TURF_INTACT, "опенспейс не цел")

	// Космос: не цел, свет не динамический, грязи нет.
	check_flags(/turf/open/space, NONE, "космос пуст по всем флагам")
	check_flags(/turf/open/space/transparent, NONE, "прозрачный космос наследует пустой набор")

	// Голодек копирует только помеченные турфы.
	check_flags(/turf/open/floor/holofloor, TURF_FLAGS_HOLOFLOOR, "голопол копируется")
	check_flags(/turf/open/floor/engine, (TURF_FLAGS_FLOOR | TURF_HOLODECK_COMPATIBLE) & ~TURF_TILED_DIRT, "армированный пол копируется")

	// Шипящая гильза.
	check_flags(/turf/open/water, TURF_FLAGS_DEFAULT | TURF_BULLET_SIZZLE, "вода шипит")
	check_flags(/turf/closed/wall/ice, TURF_FLAGS_DEFAULT | TURF_BULLET_SIZZLE, "ледяная стена шипит")
	check_flags(/turf/open/floor/plating/ice, (TURF_FLAGS_FLOOR & ~TURF_INTACT) | TURF_BULLET_SIZZLE, "ледяной плитинг шипит и не цел")

	// Неразрушимые: плиточная декаль есть, грязь не копится.
	check_flags(/turf/open/indestructible, TURF_FLAGS_DEFAULT | TURF_TILED_DIRT, "неразрушимый носит декаль")
	check_flags(/turf/open/indestructible/necropolis, TURF_FLAGS_DEFAULT, "некрополь без декали")

	// Обычный пол в голодек уезжать не должен.
	var/turf/open/floor/plasteel/plasteel_path = /turf/open/floor/plasteel
	TEST_ASSERT(!(initial(plasteel_path.turf_flags) & TURF_HOLODECK_COMPATIBLE), "обычный плистил не должен уезжать в голодек")

	// Опорные точки ловят потерянный бит там, где его правили руками, но не ловят чужой бит,
	// приписанный композиту по опечатке: в дереве семь сотен подтипов, и перечислять их
	// поимённо бессмысленно. Два инварианта проверяются сразу по всему дереву.
	var/known_flags = TURF_INTACT | TURF_BULLET_SIZZLE | TURF_HOLODECK_COMPATIBLE | TURF_OVERFLOOR_PLACED
	known_flags |= TURF_CHANGING | TURF_REQUIRES_ACTIVATION | TURF_DYNAMIC_LIGHTING | TURF_DIRT_BUILDUP_ALLOWED | TURF_TILED_DIRT
	for(var/turf/checked_path as anything in typesof(/turf))
		// Первый: в дефолте типа нет битов, которых нет в дефайнах. Композит пишется руками
		// от родительского значения, и лишний разряд тут ничем себя не проявит до раунда.
		var/stray = initial(checked_path.turf_flags) & ~known_flags
		if(stray)
			TEST_FAIL("[checked_path]: в turf_flags биты вне дефайнов ([stray]), композит собран с опечаткой")

		// Второй: производное состояние света не живёт в дефолте типа. Оно снимается копиром
		// голодека по имени переменной, и типовой дефолт означал бы турф, который родился с
		// уже разложенными углами или с чужим непрозрачным атомом на себе.
		if(initial(checked_path.lighting_flags) != NONE)
			TEST_FAIL("[checked_path]: lighting_flags = [initial(checked_path.lighting_flags)] типовым дефолтом, а это производное состояние света")
