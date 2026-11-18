#define MINIMAP_TEST_TILE 16

/datum/unit_test/minimap_feature_cache
	abstract_type = /datum/unit_test/minimap_feature_cache
	/// "x,y" -> модель DMM, как её отдаёт read_source_features().
	var/list/source_tiles = list()
	/// Имя входит в имя ассета миникарты, а REF удалённой карты переиспользуется.
	var/static/built_count = 0

/datum/unit_test/minimap_feature_cache/proc/add_source(turf/tile, atom_type, list/attributes = list())
	var/list/model = source_tiles["[tile.x],[tile.y]"]
	if(!model)
		model = list(list(/turf/open/floor/plasteel), list(list()))
		source_tiles["[tile.x],[tile.y]"] = model
	model[1] += atom_type
	model[2] += list(attributes)

/datum/unit_test/minimap_feature_cache/proc/build_minimap(width, height, minimap_type = /datum/minimap)
	var/turf/corner = run_loc_floor_bottom_left
	var/icon/source = icon('html/blank.png')
	source.Scale(width * MINIMAP_TEST_TILE, height * MINIMAP_TEST_TILE)
	return new minimap_type(corner.z, corner.x, corner.y, corner.x + width - 1, corner.y + height - 1, "minimap cache test [++built_count]", FALSE, source, FALSE, source_tiles)

/// Одинаковые декали, окна и двери подряд на миникарте не собираются в иконку заново на каждой клетке.
/datum/unit_test/minimap_feature_cache/built_once

/datum/unit_test/minimap_feature_cache/built_once/Run()
	var/turf/corner = run_loc_floor_bottom_left
	for(var/turf/tile in block(corner, run_loc_floor_top_right))
		add_source(tile, /obj/effect/turf_decal/tile/blue, list("dir" = NORTH))
	// Через клетку от стен и друг от друга: сглаживание не делает их разными.
	for(var/offset in list(1, 3))
		smooth_icon(allocate(/obj/structure/window/fulltile, locate(corner.x + offset, corner.y + 1, corner.z)))
		var/turf/door_tile = locate(corner.x + offset, corner.y + 3, corner.z)
		allocate(/obj/machinery/door/airlock, door_tile)
		add_source(door_tile, /obj/machinery/door/airlock)

	var/icons_before = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS]
	var/datum/minimap/narrow = build_minimap(2, 5)
	var/narrow_icons = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS] - icons_before
	icons_before = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS]
	var/datum/minimap/wide = build_minimap(5, 5)
	var/wide_icons = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS] - icons_before
	qdel(narrow)
	qdel(wide)

	TEST_ASSERT(narrow_icons > 0, "миникарта не собрала ни одной иконки, тест ничего не проверяет")
	// Узкая карта: 10 декалей, окно и дверь; широкая: 25 декалей, 2 окна и 2 двери того же вида.
	TEST_ASSERT(wide_icons - narrow_icons <= 1, "сборок иконок на 5x5 [wide_icons] против [narrow_icons] на 2x5: одинаковые объекты собираются заново на каждой клетке")

/datum/minimap/uncached

/datum/minimap/uncached/scaled_flat_icon(source, key, list/feature_icons, tile_width, tile_height, whole_tile)
	return ..(source, key, list(), tile_width, tile_height, whole_tile)

/// Кэш иконок не меняет ни одного пикселя миникарты: разные декали, сглаженные окна и двери не путаются между собой.
/datum/unit_test/minimap_feature_cache/same_pixels

/datum/unit_test/minimap_feature_cache/same_pixels/Run()
	var/turf/corner = run_loc_floor_bottom_left
	// Декали только в крайних рядах, чтобы окна и двери в середине рисовались на пустом фоне.
	var/list/dirs = list(NORTH, SOUTH, EAST, WEST)
	var/index = 0
	for(var/turf/tile in block(corner, run_loc_floor_top_right))
		if(tile.y != corner.y && tile.y != run_loc_floor_top_right.y)
			continue
		index++
		add_source(tile, /obj/effect/turf_decal/tile/blue, list("dir" = dirs[index % 4 + 1], "color" = index % 4 >= 2 ? "#ff0000" : "#52B4E9"))
		if(index % 2)
			add_source(tile, /obj/effect/turf_decal/stripes/yellow/line, list("dir" = index % 4 == 1 ? NORTH : EAST, "alpha" = index % 4 == 1 ? 255 : 120))

	var/list/windows = list()
	for(var/offset in list(0, 1, 2))
		windows += allocate(/obj/structure/window/fulltile, locate(corner.x + offset, corner.y + 1, corner.z))
	windows += allocate(/obj/structure/window/reinforced/fulltile, locate(corner.x + 4, corner.y + 1, corner.z))
	var/turf/firelock_tile = locate(corner.x + 1, corner.y + 1, corner.z)
	allocate(/obj/machinery/door/firedoor, firelock_tile)
	add_source(firelock_tile, /obj/machinery/door/firedoor)
	for(var/offset in list(0, 1, 3))
		var/turf/lattice_tile = locate(corner.x + offset, corner.y + 2, corner.z)
		windows += allocate(/obj/structure/lattice, lattice_tile)
		add_source(lattice_tile, /obj/structure/lattice)
	for(var/atom/smoothed as anything in windows)
		smooth_icon(smoothed)

	var/list/door_types = list(/obj/machinery/door/airlock, /obj/machinery/door/airlock, /obj/machinery/door/airlock/glass, /obj/machinery/door/airlock, /obj/machinery/door/firedoor)
	for(var/offset in 0 to 4)
		var/turf/door_tile = locate(corner.x + offset, corner.y + 3, corner.z)
		var/obj/machinery/door/door = allocate(door_types[offset + 1], door_tile)
		add_source(door_tile, door.type)
		if(offset == 1)
			door.name = "Bridge"
		if(offset == 3)
			var/obj/machinery/door/airlock/bolted = door
			bolted.bolt()

	var/icons_before = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS]
	var/datum/minimap/cached = build_minimap(5, 5)
	var/cached_icons = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS] - icons_before
	icons_before = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS]
	var/datum/minimap/reference = build_minimap(5, 5, /datum/minimap/uncached)
	var/reference_icons = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS] - icons_before
	var/icon/cached_icon = cached.map_icon
	var/icon/reference_icon = reference.map_icon
	qdel(cached)
	qdel(reference)

	TEST_ASSERT(cached_icons < reference_icons, "кэш ни разу не сработал ([cached_icons] сборок против [reference_icons]), сравнение ничего не проверяет")
	var/list/drawn_tiles = list("window" = list(0, 1), "lattice" = list(3, 2), "airlock" = list(0, 3), "glass airlock" = list(2, 3), "firelock" = list(4, 3))
	for(var/feature in drawn_tiles)
		var/list/offset = drawn_tiles[feature]
		var/drawn = FALSE
		for(var/pixel_y in offset[2] * MINIMAP_TEST_TILE + 1 to (offset[2] + 1) * MINIMAP_TEST_TILE)
			for(var/pixel_x in offset[1] * MINIMAP_TEST_TILE + 1 to (offset[1] + 1) * MINIMAP_TEST_TILE)
				if(reference_icon.GetPixel(pixel_x, pixel_y))
					drawn = TRUE
					break
			if(drawn)
				break
		TEST_ASSERT(drawn, "[feature] не нарисован на миникарте, сравнение его не проверяет")
	TEST_ASSERT_EQUAL(cached_icon.Width(), reference_icon.Width(), "миникарта с кэшем другой ширины")
	TEST_ASSERT_EQUAL(cached_icon.Height(), reference_icon.Height(), "миникарта с кэшем другой высоты")
	var/mismatches = 0
	var/first_mismatch
	for(var/pixel_y in 1 to reference_icon.Height())
		for(var/pixel_x in 1 to reference_icon.Width())
			if(cached_icon.GetPixel(pixel_x, pixel_y) == reference_icon.GetPixel(pixel_x, pixel_y))
				continue
			if(!mismatches++)
				first_mismatch ="[pixel_x],[pixel_y] (клетка [round((pixel_x - 1) / MINIMAP_TEST_TILE)],[round((pixel_y - 1) / MINIMAP_TEST_TILE)])"
	TEST_ASSERT_EQUAL(mismatches, 0, "миникарта с кэшем расходится со сборкой без кэша, первый пиксель [first_mismatch]")

#undef MINIMAP_TEST_TILE
