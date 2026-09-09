/// Приоритет операторов в pre_attack() отправлял в снос мусоропроводные
/// конструкции, транзитные трубы, поды и метры даже при снятом DESTROY_MODE:
/// && связывает сильнее ||, а скобки стояли только вокруг проверки режима.
/// Здесь проверяются обе половины разъехавшегося условия: is_destroyable_target
/// отвечает только за тип, can_destroy_target - за тип вместе с режимом.
/datum/unit_test/rpd_destroy_mode_gate

/datum/unit_test/rpd_destroy_mode_gate/Run()
	var/obj/item/pipe_dispenser/dispenser = allocate(/obj/item/pipe_dispenser)
	var/obj/structure/disposalconstruct/construct = allocate(/obj/structure/disposalconstruct, run_loc_floor_bottom_left)
	var/obj/item/pipe_meter/meter = allocate(/obj/item/pipe_meter, run_loc_floor_bottom_left)
	var/obj/structure/c_transit_tube/tube = allocate(/obj/structure/c_transit_tube, run_loc_floor_bottom_left)
	var/obj/structure/c_transit_tube_pod/pod = allocate(/obj/structure/c_transit_tube_pod, run_loc_floor_bottom_left)
	// Фитинг без pipe_type роняет update() на initial() от нулевого пути,
	// поэтому тип трубы и направление передаются явно, как это делает RPD.
	var/obj/item/pipe/fitting = allocate(/obj/item/pipe, run_loc_floor_bottom_left, /obj/machinery/atmospherics/pipe/simple, SOUTH)

	// BUILD_MODE, значение 1<<0 - дефайны режимов локальны для RPD.dm (строки 11-14).
	dispenser.mode = 1
	TEST_ASSERT(!dispenser.can_destroy_target(construct), "мусоропроводная конструкция сносится при снятом DESTROY_MODE")
	TEST_ASSERT(!dispenser.can_destroy_target(meter), "метр сносится при снятом DESTROY_MODE")
	TEST_ASSERT(!dispenser.can_destroy_target(tube), "транзитная труба сносится при снятом DESTROY_MODE")
	TEST_ASSERT(!dispenser.can_destroy_target(pod), "транзитный под сносится при снятом DESTROY_MODE")
	TEST_ASSERT(!dispenser.can_destroy_target(fitting), "фитинг сносится при снятом DESTROY_MODE")

	// Тип от режима отделён: на этом разделении держится предупреждение
	// в pre_attack(), которое иначе пропустило бы клик в мили-цепочку.
	TEST_ASSERT(dispenser.is_destroyable_target(construct), "мусоропроводная конструкция выпала из списка сносимых типов")
	TEST_ASSERT(dispenser.is_destroyable_target(meter), "метр выпал из списка сносимых типов")
	TEST_ASSERT(dispenser.is_destroyable_target(tube), "транзитная труба выпала из списка сносимых типов")
	TEST_ASSERT(dispenser.is_destroyable_target(pod), "транзитный под выпал из списка сносимых типов")
	TEST_ASSERT(dispenser.is_destroyable_target(fitting), "фитинг выпал из списка сносимых типов")

	// DESTROY_MODE, значение 1<<2.
	dispenser.mode = 1 | 4
	TEST_ASSERT(dispenser.can_destroy_target(construct), "мусоропроводная конструкция не сносится при включённом DESTROY_MODE")
	TEST_ASSERT(dispenser.can_destroy_target(meter), "метр не сносится при включённом DESTROY_MODE")
	TEST_ASSERT(dispenser.can_destroy_target(tube), "транзитная труба не сносится при включённом DESTROY_MODE")
	TEST_ASSERT(dispenser.can_destroy_target(pod), "транзитный под не сносится при включённом DESTROY_MODE")
	TEST_ASSERT(dispenser.can_destroy_target(fitting), "фитинг не сносится при включённом DESTROY_MODE")

	// Список типов должен быть узким: посторонняя цель мимо сноса в любом режиме.
	TEST_ASSERT(!dispenser.is_destroyable_target(run_loc_floor_bottom_left), "посторонний тип попал в список сносимых")
	TEST_ASSERT(!dispenser.can_destroy_target(run_loc_floor_bottom_left), "снос берёт посторонний тип при включённом DESTROY_MODE")

	// Оба прока обязаны отдавать булево: is_type_in_typecache - макрос, и на
	// отсутствующем ключе списка возвращает null, а null в DM не равен FALSE.
	TEST_ASSERT_EQUAL(dispenser.is_destroyable_target(run_loc_floor_bottom_left), FALSE, "проверка типа вернула не булево на посторонней цели")
	TEST_ASSERT_EQUAL(dispenser.can_destroy_target(run_loc_floor_bottom_left), FALSE, "проверка сноса вернула не булево на посторонней цели")
	TEST_ASSERT_EQUAL(dispenser.can_destroy_target(construct), TRUE, "проверка сноса вернула не булево на сносимой цели")

/// Категория приходила из клиента без проверки. PLUMBING_CATEGORY ссылается
/// на first_plumbing, а его заполняет только закомментированный подтип
/// Plumberinator - recipe обнулялся и ui_data() падал на get_preview().
/datum/unit_test/rpd_category_validation

/datum/unit_test/rpd_category_validation/Run()
	var/obj/item/pipe_dispenser/dispenser = allocate(/obj/item/pipe_dispenser)
	var/datum/pipe_info/starting_recipe = dispenser.recipe

	// Значения категорий локальны для RPD.dm (строки 6-9):
	// ATMOS 0, DISPOSALS 1, TRANSIT 2, PLUMBING 3.
	TEST_ASSERT(dispenser.set_category(0), "категория атмоса должна приниматься")
	TEST_ASSERT(dispenser.set_category(1), "категория мусоропровода должна приниматься")
	TEST_ASSERT(dispenser.set_category(2), "категория транзитных труб должна приниматься")

	TEST_ASSERT(!dispenser.set_category(3), "PLUMBING не инициализирован и должен отвергаться")
	TEST_ASSERT(!dispenser.set_category(99), "неизвестная категория должна отвергаться")
	TEST_ASSERT(!dispenser.set_category(null), "пустая категория должна отвергаться")

	TEST_ASSERT_NOTNULL(dispenser.recipe, "отвергнутая категория не должна обнулять рецепт")
	TEST_ASSERT_NOTNULL(starting_recipe, "раздатчик обязан стартовать с рецептом")

	// Контракт возврата строго булев: ui_act проверяет результат напрямую, а
	// null в DM не равен ни TRUE, ни FALSE.
	TEST_ASSERT_EQUAL(dispenser.set_category(0), TRUE, "принятая категория вернула не булево")
	TEST_ASSERT_EQUAL(dispenser.set_category(3), FALSE, "категория PLUMBING вернула не булево")
	TEST_ASSERT_EQUAL(dispenser.set_category(99), FALSE, "неизвестная категория вернула не булево")
	TEST_ASSERT_EQUAL(dispenser.set_category(null), FALSE, "пустая категория вернула не булево")

	// Последняя принятая категория - атмос: отвергнутая не должна её подменять.
	TEST_ASSERT_EQUAL(dispenser.category, 0, "отвергнутая категория подменила текущую")
