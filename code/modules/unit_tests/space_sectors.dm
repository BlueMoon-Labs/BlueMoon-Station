/// Секторы космоса: раскладка по сетке, вертикальные стопки, гейты и проходимость космоса по вертикали.

/// Тестовый набор секторов: компилируется только с UNIT_TESTS, на боевые карты попасть не может.
/datum/space_sector/unit_test
	abstract_type = /datum/space_sector/unit_test
	sector_set = "unit_test"

/datum/space_sector/unit_test/hub
	id = "unit_test_hub"
	name = "Тестовый узел"

/datum/space_sector/unit_test/north
	id = "unit_test_north"
	name = "Тестовый север"
	sector_y = 1

/datum/space_sector/unit_test/upper
	id = "unit_test_upper"
	name = "Тестовый верхний"
	sector_layer = 1

/datum/space_sector/unit_test/east
	id = "unit_test_east"
	name = "Тестовый восток"
	sector_x = 1
	//Запад по координатам - это узел, но объявленная связь уводит на север.
	link_west = "unit_test_north"

/obj/effect/sector_gate/unit_test_alpha
	gate_id = "unit_test_pair"

/obj/effect/sector_gate/unit_test_beta
	gate_id = "unit_test_pair"

/// Собирает тестовый набор на выдуманных z-номерах и возвращает готовую сетку.
/proc/unit_test_build_space_grid()
	SSmapping.build_space_sector_registry()
	var/datum/space_grid/grid = new
	var/fake_z = 101
	for(var/datum/space_sector/sector as anything in SSmapping.space_sector_sets["unit_test"])
		var/datum/space_level/level = new(fake_z++, sector.name, sector.build_traits())
		grid.place(level, sector.sector_x, sector.sector_y, sector.sector_layer, sector)
	grid.link_horizontal()
	grid.apply_explicit_links()
	return grid

/// Реестр секторов собирается из объявлений, валидируется и выдаёт свежие трейты каждому уровню.
/datum/unit_test/space_sector_declarations

/datum/unit_test/space_sector_declarations/Run()
	SSmapping.build_space_sector_registry()

	var/list/test_set = SSmapping.space_sector_sets["unit_test"]
	TEST_ASSERT_EQUAL(length(test_set), 4, "Тестовый набор должен собраться из четырёх секторов")

	for(var/id in SSmapping.space_sectors)
		var/datum/space_sector/sector = SSmapping.space_sectors[id]
		var/list/complaints = sector.validate()
		TEST_ASSERT(!length(complaints), "Сектор '[id]' не проходит валидацию: [complaints.Join("; ")]")
		TEST_ASSERT_EQUAL(sector.id, id, "Сектор '[id]' лежит в реестре не под своим id")

	var/datum/space_sector/hub = SSmapping.space_sectors["unit_test_hub"]
	var/list/hub_traits = hub.build_traits()
	TEST_ASSERT_EQUAL(hub_traits[ZTRAIT_LINKAGE], CROSSLINKED, "Сектор обязан быть частью сетки космоса")
	TEST_ASSERT(!hub_traits[ZTRAIT_SPACE_RUINS], "Нарисованный сектор не должен засеваться случайными руинами")

	var/list/second_call = hub.build_traits()
	TEST_ASSERT(hub_traits != second_call, "build_traits() обязан возвращать свежий список каждому уровню")

/// Сетка космоса связывает соседей по горизонтали и замечает одностороннюю явную связь.
/datum/unit_test/space_grid_layout

/datum/unit_test/space_grid_layout/Run()
	var/datum/space_grid/grid = unit_test_build_space_grid()

	var/datum/space_level/hub = grid.sector_levels["unit_test_hub"]
	var/datum/space_level/north = grid.sector_levels["unit_test_north"]
	var/datum/space_level/east = grid.sector_levels["unit_test_east"]
	var/datum/space_level/upper = grid.sector_levels["unit_test_upper"]
	TEST_ASSERT_NOTNULL(hub, "Узел не встал на сетку")
	TEST_ASSERT_NOTNULL(north, "Северный сектор не встал на сетку")
	TEST_ASSERT_NOTNULL(east, "Восточный сектор не встал на сетку")
	TEST_ASSERT_NOTNULL(upper, "Верхний сектор не встал на сетку")

	TEST_ASSERT_EQUAL(grid.level_at(0, 0, 0), hub, "Узел обязан стоять в объявленной клетке")
	TEST_ASSERT_EQUAL(grid.level_at(0, 1, 0), north, "Север обязан стоять в объявленной клетке")
	TEST_ASSERT_EQUAL(grid.level_at(0, 0, 1), upper, "Верхний этаж обязан стоять над узлом")

	TEST_ASSERT_EQUAL(hub.neigbours[TEXT_NORTH], north, "На север от узла должен лежать северный сектор")
	TEST_ASSERT_EQUAL(north.neigbours[TEXT_SOUTH], hub, "На юг от северного сектора должен лежать узел")
	TEST_ASSERT_EQUAL(hub.neigbours[TEXT_EAST], east, "На восток от узла должен лежать восточный сектор")

	TEST_ASSERT_EQUAL(east.neigbours[TEXT_WEST], north, "Явная связь обязана перебивать соседство по координатам")
	TEST_ASSERT_EQUAL(east.neigbours[TEXT_NORTH], null, "Клетка к северу от восточного сектора пуста, соседа быть не должно")

	var/list/pairs = grid.vertical_pairs()
	TEST_ASSERT_EQUAL(length(pairs), 1, "Стопка ровно одна: верхний этаж над узлом")
	var/list/pair = pairs[1]
	TEST_ASSERT_EQUAL(pair[1], hub, "Нижним в стопке обязан быть узел")
	TEST_ASSERT_EQUAL(pair[2], upper, "Верхним в стопке обязан быть верхний сектор")

	var/list/complaints = grid.validate()
	var/found_one_way = FALSE
	for(var/complaint in complaints)
		if(findtext(complaint, "односторонняя"))
			found_one_way = TRUE
	TEST_ASSERT(found_one_way, "Валидация обязана заметить одностороннюю связь восток -> север: [complaints.Join("; ")]")

/// Занятая клетка сетки не отдаётся второму уровню, плавающий встаёт вплотную к занятой.
/datum/unit_test/space_grid_cell_conflict

/datum/unit_test/space_grid_cell_conflict/Run()
	var/datum/space_grid/grid = new
	var/datum/space_level/first = new(101, "первый", list(ZTRAIT_LINKAGE = CROSSLINKED))
	var/datum/space_level/second = new(102, "второй", list(ZTRAIT_LINKAGE = CROSSLINKED))

	TEST_ASSERT(grid.place(first, 0, 0, 0), "Первый уровень обязан встать в свободную клетку")
	TEST_ASSERT(!grid.place(second, 0, 0, 0), "Вторую карту в ту же точку пространства пускать нельзя")
	TEST_ASSERT_EQUAL(grid.level_at(0, 0, 0), first, "Занявший клетку обязан в ней остаться")
	TEST_ASSERT_NULL(grid.coords_of(second), "Не поместившийся уровень не должен считаться размещённым")
	TEST_ASSERT(length(grid.problems), "Конфликт клеток обязан попасть в отчёт")

	var/datum/space_level/floating = new(103, "плавающий", list(ZTRAIT_LINKAGE = CROSSLINKED))
	TEST_ASSERT(grid.place_floating(floating), "Свободная клетка рядом с занятой обязана найтись")
	var/list/spot = grid.coords_of(floating)
	TEST_ASSERT_NOTNULL(spot, "Плавающий уровень обязан оказаться на сетке")
	TEST_ASSERT_EQUAL(abs(spot[1]) + abs(spot[2]), 1, "Плавающий уровень обязан встать вплотную к занятой клетке")

/// Наборы трейтов шаблона раздаются каждому этажу и не делят один список.
/datum/unit_test/map_template_z_trait_sets

/datum/unit_test/map_template_z_trait_sets/Run()
	var/datum/map_template/probe = new

	var/list/shared = probe.build_z_trait_sets(list(ZTRAIT_AWAY = TRUE), 3)
	TEST_ASSERT_EQUAL(length(shared), 3, "Набор трейтов нужен каждому этажу шаблона")
	var/list/first_floor = shared[1]
	var/list/second_floor = shared[2]
	TEST_ASSERT(first_floor[ZTRAIT_AWAY], "Объявленный трейт обязан доехать до этажа")
	TEST_ASSERT(first_floor != second_floor, "У этажей обязаны быть разные списки трейтов")
	first_floor[ZTRAIT_UP] = 1
	TEST_ASSERT_NULL(second_floor[ZTRAIT_UP], "Связка одного этажа не должна протекать на соседний")

	var/list/per_floor = probe.build_z_trait_sets(list(list(ZTRAIT_MINING = TRUE), list(ZTRAIT_AWAY = TRUE)), 3)
	TEST_ASSERT_EQUAL(length(per_floor), 3, "Недостающие этажи обязаны получить набор трейтов")
	var/list/bottom = per_floor[1]
	var/list/top = per_floor[3]
	TEST_ASSERT(bottom[ZTRAIT_MINING], "Первый этаж обязан взять первый объявленный набор")
	TEST_ASSERT(top[ZTRAIT_AWAY], "Лишние этажи обязаны добираться последним объявленным набором")

	var/list/single_key = probe.build_z_trait_sets(list(ZTRAIT_VR = TRUE), 2)
	var/list/single_key_floor = single_key[1]
	TEST_ASSERT(islist(single_key_floor), "Этаж обязан получить список трейтов, а не ключ строкой")
	TEST_ASSERT(single_key_floor[ZTRAIT_VR], "Единственный объявленный трейт обязан доехать до этажа")

	var/list/defaults = probe.build_z_trait_sets(null, 2)
	var/list/default_floor = defaults[1]
	TEST_ASSERT(default_floor[ZTRAIT_AWAY], "Без объявленных трейтов этаж обязан получить дефолт away-миссии")

	qdel(probe)

/// Связка этажей шаблона взаимна, объявленная маппером вертикаль не перетирается.
/datum/unit_test/map_template_stack_linking

/datum/unit_test/map_template_stack_linking/Run()
	var/datum/map_template/probe = new

	var/datum/space_level/lower = new(101, "низ", list())
	var/datum/space_level/upper = new(102, "верх", list())
	probe.link_template_stack(list(lower, upper))
	TEST_ASSERT_EQUAL(lower.traits[ZTRAIT_UP], 1, "Нижний этаж обязан смотреть вверх на соседний z")
	TEST_ASSERT_EQUAL(upper.traits[ZTRAIT_DOWN], -1, "Связка обязана быть взаимной, иначе её отбросит build_z_stacks()")

	var/datum/space_level/declared_lower = new(103, "низ с объявленной связкой", list(ZTRAIT_UP = 3))
	var/datum/space_level/declared_upper = new(104, "верх с объявленной связкой", list())
	probe.link_template_stack(list(declared_lower, declared_upper))
	TEST_ASSERT_EQUAL(declared_lower.traits[ZTRAIT_UP], 3, "Объявленная связка обязана остаться нетронутой")
	TEST_ASSERT_NULL(declared_upper.traits[ZTRAIT_DOWN], "Не трогаем пару целиком, если связка объявлена вручную")

	qdel(probe)

/// Космос пропускает по вертикали в обе стороны, кроме прикрученного; пол только впускает сверху.
/datum/unit_test/space_turf_vertical_passage

/datum/unit_test/space_turf_vertical_passage/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/spot = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT_NOTNULL(spot, "Не нашлось турфа под тест в резервации")
	var/original_type = spot.type

	var/turf/open/space/vacuum = spot.ChangeTurf(/turf/open/space)
	TEST_ASSERT(isspaceturf(vacuum), "Турф не превратился в космос")
	var/obj/item/stack/sheet/metal/probe = allocate(/obj/item/stack/sheet/metal, vacuum)

	TEST_ASSERT(vacuum.zPassOut(probe, DOWN, null), "Космос обязан выпускать вниз")
	TEST_ASSERT(vacuum.zPassIn(probe, DOWN, null), "Космос обязан впускать сверху")
	TEST_ASSERT(vacuum.zPassOut(probe, UP, null), "Космос обязан выпускать вверх")
	TEST_ASSERT(vacuum.zPassIn(probe, UP, null), "Космос обязан впускать снизу")
	TEST_ASSERT(!vacuum.zPassIn(probe, NORTH, null), "По горизонтали проходимость решает не zPass")

	var/obj/structure/table/anchored_thing = allocate(/obj/structure/table, vacuum)
	TEST_ASSERT(!vacuum.zPassOut(anchored_thing, DOWN, null), "Прикрученное к месту не должно уезжать вниз")

	var/turf/open/restored = vacuum.ChangeTurf(original_type)
	TEST_ASSERT(!restored.zPassOut(probe, DOWN, null), "Обычный пол вниз выпускать не должен")
	TEST_ASSERT(restored.zPassIn(probe, DOWN, null), "Обычный пол обязан впускать падающего сверху")

/// Парные гейты находят друг друга, переносят груз по направлению и помечают прибывшего.
/datum/unit_test/sector_gate_pairing

/datum/unit_test/sector_gate_pairing/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/alpha_turf = origin
	var/turf/beta_turf = locate(origin.x + 2, origin.y, origin.z)
	var/turf/staging = locate(origin.x, origin.y + 1, origin.z)
	TEST_ASSERT_NOTNULL(beta_turf, "Не нашлось турфа под второй гейт")
	TEST_ASSERT_NOTNULL(staging, "Не нашлось турфа под подготовку груза")

	var/obj/effect/sector_gate/alpha = allocate(/obj/effect/sector_gate/unit_test_alpha, alpha_turf)
	var/obj/effect/sector_gate/beta = allocate(/obj/effect/sector_gate/unit_test_beta, beta_turf)
	TEST_ASSERT_EQUAL(alpha.pair, beta, "Гейты с одинаковым id обязаны найти друг друга")
	TEST_ASSERT_EQUAL(beta.pair, alpha, "Пара обязана быть взаимной")

	//Груз готовится в стороне: на самом гейте он уехал бы прямо при создании.
	var/obj/item/stack/sheet/metal/probe = allocate(/obj/item/stack/sheet/metal, staging)
	probe.setDir(WEST)
	probe.forceMove(alpha_turf)

	var/turf/expected = locate(origin.x + 1, origin.y, origin.z)
	TEST_ASSERT_EQUAL(get_turf(probe), expected, "Зашедший в гейт обязан выйти за парным по направлению движения")
	TEST_ASSERT_EQUAL(probe.dir, WEST, "Направление движения обязано пережить переход")

	beta.mark_arrival(probe)
	TEST_ASSERT(beta.recently_arrived(probe), "Прибывший обязан помечаться, иначе пара перекидывает его туда-сюда")
