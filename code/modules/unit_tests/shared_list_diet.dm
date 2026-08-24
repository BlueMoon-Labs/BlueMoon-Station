/**
 * Списки, которые обязаны быть ОБЩИМИ, а не личными.
 *
 * BYOND платит за каждый непустой список инстанса: сотня байт заголовка плюс элементы.
 * На типах с многотысячной популяцией (объекты освещения, минеральные турфы) личный
 * список там, где хватило бы общего, стоит десятки мегабайт адресного пространства -
 * а его у тридцатидвухбитного DreamDaemon всего четыре гигабайта, и раунд стартует,
 * заняв больше половины.
 *
 * Ошибки этого класса тихие: код работает, просто мир весит на сотню мегабайт больше.
 * Поэтому каждая правка закреплена здесь проверкой на ТОЖДЕСТВО ССЫЛКИ, а не на
 * содержимое: список с правильным содержимым, но свой у каждого инстанса, - это ровно
 * то, что чинилось.
 */

/// Объект освещения не должен заводить atom_colours.
///
/// Типовой дефолт color проходит через /atom/Initialize -> `if(color) add_atom_colour()`,
/// а тот заводит каждому инстансу личный список на четыре слота с личной копией
/// двадцатиэлементной цветовой матрицы внутри. Читать его у объекта освещения некому:
/// update() пишет color напрямую. При четверти миллиона объектов на мир - 80 МиБ впустую.
/datum/unit_test/lighting_object_skips_atom_colours
	requires_full_map = FALSE

/datum/unit_test/lighting_object_skips_atom_colours/Run()
	var/atom/movable/lighting_object/probe_path = /atom/movable/lighting_object
	TEST_ASSERT_NULL(initial(probe_path.color), "у /atom/movable/lighting_object снова типовой дефолт color - он форсит личный atom_colours на каждом инстансе, ставить матрицу надо в New() после ..()")

	var/atom/movable/lighting_object/live = run_loc_floor_bottom_left.lighting_object
	TEST_ASSERT_NOTNULL(live, "на тестовом турфе нет объекта освещения - проверять нечего")
	TEST_ASSERT_NULL(live.atom_colours, "живой объект освещения завёл atom_colours на [length(live.atom_colours)] слотов")
	TEST_ASSERT_NOTNULL(live.color, "объект освещения остался без цветовой матрицы")

/// Минеральные турфы делят один canSmoothWith на весь тип.
///
/// Штатный дедуп через typelist() сюда не достаёт: /turf/Initialize объявлен
/// SHOULD_CALL_PARENT(FALSE) и до строки `canSmoothWith = typelist(...)` в /atom/Initialize
/// не доходит вовсе. Значит список обязан быть типовым дефолтом, иначе каждый из ~70 тысяч
/// минеральных турфов карты получит личную копию.
/datum/unit_test/mineral_smoothing_list_is_shared
	requires_full_map = FALSE

/datum/unit_test/mineral_smoothing_list_is_shared/Run()
	// Проверяем на живых турфах, а не через initial(): initial() на списочной переменной
	// отдаёт ПУСТОЙ список, а не содержимое типового дефолта - проверено этим же тестом,
	// который на initial() падал с "усох до 0 элементов" при заведомо заполненном дефолте.
	var/turf/first = run_loc_floor_bottom_left.ChangeTurf(/turf/closed/mineral)
	var/turf/second = run_loc_floor_top_right.ChangeTurf(/turf/closed/mineral)

	TEST_ASSERT_NOTNULL(first.canSmoothWith, "минеральный турф остался без canSmoothWith")
	TEST_ASSERT(length(first.canSmoothWith) >= 2, "canSmoothWith минерала усох до [length(first.canSmoothWith)] элементов")
	// Тождество ссылки - и есть предмет проверки: список с правильным содержимым, но свой
	// у каждого из ~70 тысяч минеральных турфов карты, это ровно то, что чинилось.
	TEST_ASSERT(first.canSmoothWith == second.canSmoothWith, "два минеральных турфа держат РАЗНЫЕ списки canSmoothWith - список снова собирается на каждом инстансе")
	TEST_ASSERT(first.canSmoothWith == GLOB.mineral_smooth_targets, "минеральный турф взял не общий список, а свой")

	// Подтипы со своим набором целей обязаны брать ВТОРУЮ глобалку, а не унаследовать
	// минеральную от родителя: они сглаживаются со всем закрытым, а не только с породой.
	var/turf/snowy = first.ChangeTurf(/turf/closed/mineral/snowmountain)
	TEST_ASSERT(snowy.canSmoothWith == GLOB.closed_turf_smooth_targets, "снежная гора взяла минеральный набор целей сглаживания вместо набора закрытых турфов")

/// Синдикатский винтеркоут делит один список разрешённых предметов на весь тип.
///
/// Прежнее `allowed += GLOB.security_wintercoat_allowed` строило каждому экземпляру
/// собственный список на полторы тысячи путей.
/datum/unit_test/syndicate_wintercoat_allowed_is_shared
	requires_full_map = FALSE

/datum/unit_test/syndicate_wintercoat_allowed_is_shared/Run()
	var/obj/item/clothing/suit/hooded/wintercoat/syndicate/first = allocate(/obj/item/clothing/suit/hooded/wintercoat/syndicate)
	var/obj/item/clothing/suit/hooded/wintercoat/syndicate/second = allocate(/obj/item/clothing/suit/hooded/wintercoat/syndicate)

	TEST_ASSERT_NOTNULL(first.allowed, "синдикатский винтеркоут остался без списка разрешённых предметов")
	TEST_ASSERT(first.allowed == second.allowed, "два синдикатских винтеркоута держат РАЗНЫЕ списки allowed - список снова строится на каждом экземпляре")
	TEST_ASSERT(first.allowed != GLOB.security_wintercoat_allowed, "синдикатский винтеркоут пишет прямо в глобальный список - его правка утечёт на все остальные коуты")

	// Склейка обязана сохранить обе половины: и базовые предметы винтеркоута, и оружейные.
	TEST_ASSERT(first.allowed[/obj/item/toy], "потерян базовый разрешённый предмет винтеркоута (/obj/item/toy)")
	TEST_ASSERT(first.allowed[/obj/item/gun/ballistic], "потерян разрешённый предмет из security_wintercoat_allowed (/obj/item/gun/ballistic)")

/// Шаблоны шаттлов не держат разобранную карту после замера размеров.
///
/// preload_size() просит кэш ради discover_offset() и обязан отпустить его сразу после.
/// Ветка отпускания проверяла cached_map вместо force_cache и потому была недостижима -
/// все сто с лишним шаблонов таскали свой parsed_map до конца раунда.
/datum/unit_test/shuttle_templates_release_parsed_map
	requires_full_map = FALSE

/datum/unit_test/shuttle_templates_release_parsed_map/Run()
	var/checked = 0
	var/list/leaked = list()
	for(var/shuttle_id in SSmapping.shuttle_templates)
		var/datum/map_template/shuttle/template = SSmapping.shuttle_templates[shuttle_id]
		if(!istype(template) || template.keep_cached_map)
			continue
		checked++
		if(template.cached_map)
			leaked += shuttle_id

	TEST_ASSERT(checked > 0, "ни одного шаблона шаттла не проверено - список SSmapping.shuttle_templates пуст")
	TEST_ASSERT(!length(leaked), "[length(leaked)] из [checked] шаблонов шаттлов держат parsed_map после preload_size: [leaked.Join(", ")]")

/// Диспенсер не строит книгу рецептов на инициализации машины.
///
/// Книга - это 747 рецептов со вложенными списками на каждый уникальный набор реагентов.
/// Строить её обязан ensure_recipes_asset() при первом открытии интерфейса, как и написано
/// в его комментарии; сборка в Initialize сводила эту ленивость на нет.
/datum/unit_test/chem_dispenser_recipes_stay_lazy
	requires_full_map = FALSE

/datum/unit_test/chem_dispenser_recipes_stay_lazy/Run()
	var/obj/machinery/chem_dispenser/dispenser = allocate(/obj/machinery/chem_dispenser)
	TEST_ASSERT_NULL(dispenser.cached_dispenser_game_recipes, "диспенсер построил книгу рецептов прямо в Initialize - она снова эагерная")

	dispenser.ensure_recipes_asset()
	TEST_ASSERT_NOTNULL(dispenser.cached_dispenser_game_recipes, "ensure_recipes_asset() не построил книгу рецептов")
	TEST_ASSERT(length(dispenser.cached_dispenser_game_recipes) > 0, "книга рецептов построена пустой")

/// Жидкость снимается с турфа только форсированным qdel.
///
/// /obj/effect/abstract/liquid_turf/Destroy() держит всю уборку под if(force) и без него
/// возвращает QDEL_HINT_LETMELIVE, то есть простой qdel() не удаляет НИЧЕГО и не снимает
/// турф с очередей SSliquids. Турф, оставшийся в evaporation_queue без жидкости, ронял
/// рантайм прямо в fire() и заклинивал подсистему на весь раунд.
/datum/unit_test/liquid_removal_clears_subsystem_queues
	requires_full_map = FALSE

/datum/unit_test/liquid_removal_clears_subsystem_queues/Run()
	var/turf/wet = run_loc_floor_bottom_left
	wet.add_liquid(/datum/reagent/water, 50, TRUE)
	TEST_ASSERT_NOTNULL(wet.liquids, "на турфе не завелась жидкость - проверять нечего")

	// Ставим турф в очередь испарения руками: именно это делает break_group() на живом мире.
	SSliquids.evaporation_queue[wet] = TRUE

	qdel(wet.liquids, TRUE)
	TEST_ASSERT_NULL(wet.liquids, "форсированный qdel не снял жидкость с турфа")
	TEST_ASSERT(!SSliquids.evaporation_queue[wet], "турф остался в evaporation_queue без жидкости - следующий проход SSliquids уронит рантайм и заклинит подсистему")
	TEST_ASSERT(!SSliquids.processing_fire[wet], "турф остался в processing_fire без жидкости")
