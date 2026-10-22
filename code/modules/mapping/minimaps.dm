/datum/minimap
	var/name = "minimap"
	var/icon/overlay_icon
	// Готовый PNG NanoMap или иконка старой схемы.
	var/icon/map_icon
	var/icon/meta_icon

	var/list/color_area_names = list()

	var/minx
	var/maxx
	var/miny
	var/maxy

	var/z_level
	var/id = ""
	// Мировые координаты левого нижнего пикселя несрезанной иконки.
	var/origin_x
	var/origin_y
	var/source_icon
	var/icon/department_map_icon
	var/list/area_ui_data

// Готовые NanoMap можно дополнить полупрозрачной раскраской станционных полов.
/datum/minimap/New(z, x1 = 1, y1 = 1, x2 = world.maxx, y2 = world.maxy, name = "minimap", autocrop = TRUE, source_icon, area_colors = FALSE, list/source_tiles)
	if(!z)
		CRASH("ERROR: new minimap requested without z level") //CRASH to halt the operatio

	src.name = name
	z_level = z
	id = "[md5("[z_level]" + src.name + REF(src))]" //use it's own md5 as a special identifier
	origin_x = x1
	origin_y = y1
	// Исходная отрисовка NanoMap сохраняется; цвет добавляется отдельной маской.
	if(source_icon)
		src.source_icon = source_icon
		map_icon = icon(source_icon)
		minx = x1
		miny = y1
		maxx = x2
		maxy = y2
		add_map_features(x1, y1, x2, y2, source_tiles)
		var/icon/door_layer = build_door_layer(x1, y1, x2, y2, source_tiles)
		var/icon/plain_map = icon(map_icon)
		plain_map.Blend(door_layer, ICON_OVERLAY)
		if(area_colors)
			tint_station_floors(x1, y1, x2, y2)
		map_icon.Blend(door_layer, ICON_OVERLAY)
		department_map_icon = map_icon
		map_icon = plain_map
		SSassets.transport.register_asset("minimap-[id].png", map_icon)
		SSassets.transport.register_asset("minimap-[id]-departments.png", department_map_icon)
		return

	var/crop_x1 = x2
	var/crop_x2 = x1
	var/crop_y1 = y2
	var/crop_y2 = y1

	// Старая схема зон и построение метаданных оставлены для явного запроса.
	map_icon = new('html/blank.png')
	meta_icon = new('html/blank.png')
	map_icon.Scale(x2 - x1 + 1, y2 - y1 + 1)
	meta_icon.Scale(x2 - x1 + 1, y2 - y1 + 1)

	var/list/area_to_color = list()
	for(var/turf/T in block(locate(x1, y1, z_level), locate(x2, y2, z_level)))
		var/area/A = T.loc
		var/img_x = T.x - x1 + 1 // arrays start at 1
		var/img_y = T.y - y1 + 1
		if(!istype(A, /area/space) || istype(T, /turf/closed/wall))
			crop_x1 = min(crop_x1, T.x)
			crop_x2 = max(crop_x2, T.x)
			crop_y1 = min(crop_y1, T.y)
			crop_y2 = max(crop_y2, T.y)

		var/meta_color = area_to_color[A]
		if(!meta_color)
			var/meta_x = LAZYLEN(area_to_color) + 1
			var/meta_y = (((meta_x + 1) - ((meta_x + 1) % 255)) / 255)
			var/meta_z = (((meta_y + 1) - ((meta_y + 1) % 255)) / 255)
			meta_color = rgb(meta_x % 255, meta_y % 255, meta_z % 255) //This supports exactly 16,581,374 areas with no conflicts whatsoever before it just gives up
			area_to_color[A] = meta_color
			color_area_names[meta_color] = A.name
		meta_icon.DrawBox(meta_color, img_x, img_y)
		if(!area_colors)
			continue

		if(A.minimap_show_walls && istype(T, /turf/closed/wall))
			map_icon.DrawBox("#000000", img_x, img_y)

		else if(!istype(A, /area/space))
			var/color = (A.minimap_color2 ? (((img_x + img_y) % 2) ? A.minimap_color2 : A.minimap_color ) : A.minimap_color) || "#FF00FF"
			if(A.minimap_show_walls)
				var/overridden
				for(var/obj/structure/O in T)
					if(O.minimap_override_color)
						color = O.minimap_override_color
						overridden = TRUE
						break
					else if(O.density && O.anchored)
						color = BlendRGB(color, "#000000", 0.5)
						overridden = TRUE
						break

				// Структуры и машины обходятся отдельно, чтобы не перебирать все лежащие предметы.
				if(!overridden)
					for(var/obj/machinery/O in T)
						if(O.minimap_override_color)
							color = O.minimap_override_color
							break
						else if(O.density && O.anchored)
							color = BlendRGB(color, "#000000", 0.25)
							break

			map_icon.DrawBox(color, img_x, img_y)

	origin_x = x1
	origin_y = y1
	minx = crop_x1
	maxx = crop_x2
	miny = crop_y1
	maxy = crop_y2
	if(autocrop)
		finalize(minx, miny, maxx, maxy)

// NanoMap не видит итоговые камни генератора и отфильтровывает обычные оконные объекты.
/datum/minimap/proc/add_map_features(x1, y1, x2, y2, list/source_tiles)
	var/tile_width = map_icon.Width() / (x2 - x1 + 1)
	var/tile_height = map_icon.Height() / (y2 - y1 + 1)
	var/list/turf_icons = list()
	for(var/turf/map_tile in block(locate(x1, y1, z_level), locate(x2, y2, z_level)))
		var/list/features = list()
		var/list/source_model = source_tiles?["[map_tile.x],[map_tile.y]"]
		var/list/source_types = source_model?[1]
		// Общий прок выбирает отдельный спрайт любого типа турфа; результат кэшируется на этаж.
		for(var/source_type in source_types)
			if(!ispath(source_type, /turf))
				continue
			var/icon/turf_icon
			if(!(source_type in turf_icons))
				turf_icon = map_tile.get_minimap_icon(source_type)
				if(turf_icon)
					turf_icon.Scale(tile_width, tile_height)
				turf_icons[source_type] = turf_icon || FALSE
			turf_icon = turf_icons[source_type]
			if(turf_icon)
				map_icon.Blend(turf_icon, ICON_OVERLAY, (map_tile.x - x1) * tile_width + 1, (map_tile.y - y1) * tile_height + 1)
		// Объекты декалей удаляются при инициализации, поэтому читаем их вид из DMM.
		var/list/source_attributes = source_model?[2]
		for(var/index in 1 to length(source_types))
			var/obj/effect/turf_decal/decal_type = source_types[index]
			if(!ispath(decal_type, /obj/effect/turf_decal))
				continue
			var/list/attributes = source_attributes[index]
			var/image/decal_image = image(attributes["icon"] || initial(decal_type.icon), icon_state = attributes["icon_state"] || initial(decal_type.icon_state), dir = attributes["dir"] || initial(decal_type.dir))
			decal_image.color = ("color" in attributes) ? attributes["color"] : initial(decal_type.color)
			decal_image.alpha = ("alpha" in attributes) ? attributes["alpha"] : initial(decal_type.alpha)
			var/icon/decal_icon = getFlatIcon(decal_image, no_anim = TRUE)
			// Некоторые служебные декали не имеют готового состояния в DMI.
			if(!decal_icon)
				continue
			decal_icon.Scale(decal_icon.Width() * tile_width / world.icon_size, decal_icon.Height() * tile_height / world.icon_size)
			var/offset_x = ("pixel_x" in attributes) ? attributes["pixel_x"] : initial(decal_type.pixel_x)
			var/offset_y = ("pixel_y" in attributes) ? attributes["pixel_y"] : initial(decal_type.pixel_y)
			map_icon.Blend(decal_icon, ICON_OVERLAY, (map_tile.x - x1) * tile_width + 1 + offset_x * tile_width / world.icon_size, (map_tile.y - y1) * tile_height + 1 + offset_y * tile_height / world.icon_size)
		for(var/obj/structure/lattice/lattice in map_tile)
			if(!source_tiles || (lattice.type in source_types))
				features += lattice
		for(var/obj/structure/window/window in map_tile)
			if(window.fulltile)
				features += window
		for(var/atom/feature as anything in features)
			var/icon/feature_icon = feature.get_minimap_icon()
			feature_icon.Scale(tile_width, tile_height)
			map_icon.Blend(feature_icon, ICON_OVERLAY, (map_tile.x - x1) * tile_width + 1, (map_tile.y - y1) * tile_height + 1)
		CHECK_TICK

// Двери идут отдельным слоем поверх раскраски и сохраняют исходные цвета.
/datum/minimap/proc/build_door_layer(x1, y1, x2, y2, list/source_tiles)
	var/icon/doors = new('html/blank.png')
	doors.Scale(map_icon.Width(), map_icon.Height())
	var/tile_width = map_icon.Width() / (x2 - x1 + 1)
	var/tile_height = map_icon.Height() / (y2 - y1 + 1)
	for(var/turf/map_tile in block(locate(x1, y1, z_level), locate(x2, y2, z_level)))
		var/list/source_model = source_tiles?["[map_tile.x],[map_tile.y]"]
		var/list/source_types = source_model?[1]
		// Фаерлоки лежат под окнами, решётками и всеми остальными дверями.
		var/list/foreground = list()
		for(var/obj/machinery/door/firedoor/firelock in map_tile)
			foreground += firelock
		if(length(foreground))
			for(var/obj/structure/lattice/lattice in map_tile)
				foreground += lattice
			for(var/obj/structure/window/window in map_tile)
				if(window.fulltile)
					foreground += window
		for(var/obj/door in map_tile)
			if(!istype(door, /obj/machinery/door) && !istype(door, /obj/structure/mineral_door))
				continue
			if(!istype(door, /obj/machinery/door/firedoor))
				foreground += door
		for(var/obj/door as anything in foreground)
			if(source_tiles && !(door.type in source_types) && !istype(door, /obj/structure/window))
				continue
			if(door.invisibility || !door.alpha)
				continue
			var/icon/door_icon = door.get_minimap_icon()
			door_icon.Scale(door_icon.Width() * tile_width / world.icon_size, door_icon.Height() * tile_height / world.icon_size)
			doors.Blend(door_icon, ICON_OVERLAY, (map_tile.x - x1) * tile_width + 1, (map_tile.y - y1) * tile_height + 1)
		CHECK_TICK
	return doors

// Маска строится в координатах тайлов и масштабируется без изменения геометрии NanoMap.
/datum/minimap/proc/tint_station_floors(x1, y1, x2, y2)
	var/icon/floor_colors = new('html/blank.png')
	floor_colors.Scale(x2 - x1 + 1, y2 - y1 + 1)
	var/list/natural_floors = typecacheof(list(/turf/open/floor/plating/asteroid, /turf/open/floor/grass, /turf/open/floor/fakespace, /turf/open/floor/fakepit))
	for(var/turf/open/floor/floor_tile in block(locate(x1, y1, z_level), locate(x2, y2, z_level)))
		if(is_type_in_typecache(floor_tile, natural_floors))
			continue
		var/area/floor_area = get_area(floor_tile)
		if(floor_area.outdoors || istype(floor_area, /area/space) || !floor_area.minimap_color)
			continue
		// Двери и окна на стороне тайла не исключают пол из цветовой маски.
		var/occupied = FALSE
		for(var/obj/obstacle in floor_tile)
			if(istype(obstacle, /obj/machinery/door) || istype(obstacle, /obj/structure/mineral_door))
				continue
			if(istype(obstacle, /obj/structure/window))
				var/obj/structure/window/window = obstacle
				if(!window.fulltile)
					continue
			for(var/direction in GLOB.cardinals)
				if(!CANATMOSPASS(obstacle, get_step(floor_tile, direction)))
					occupied = TRUE
					break
			if(occupied)
				break
		if(occupied)
			continue
		floor_colors.DrawBox(floor_area.minimap_color, floor_tile.x - x1 + 1, floor_tile.y - y1 + 1)
		CHECK_TICK
	floor_colors.Scale(map_icon.Width(), map_icon.Height())
	floor_colors.ChangeOpacity(0.5)
	map_icon.Blend(floor_colors, ICON_OVERLAY)

// Обрезает старую карту и метаданные по общей рамке; готовые NanoMap сохраняют координаты DMM.
/datum/minimap/proc/finalize(crop_x1, crop_y1, crop_x2, crop_y2)
	if(source_icon)
		return
	map_icon.Crop(crop_x1 - origin_x + 1, crop_y1 - origin_y + 1, crop_x2 - origin_x + 1, crop_y2 - origin_y + 1)
	meta_icon.Crop(crop_x1 - origin_x + 1, crop_y1 - origin_y + 1, crop_x2 - origin_x + 1, crop_y2 - origin_y + 1)
	minx = crop_x1
	maxx = crop_x2
	miny = crop_y1
	maxy = crop_y2
	overlay_icon = new(map_icon)
	overlay_icon.Scale(16, 16)
	//we're done baking, now we ship it.
	if (!SSassets.cache["minimap-[id].png"])
		SSassets.transport.register_asset("minimap-[id].png", map_icon)
	if (!SSassets.cache["minimap-[id]-meta.png"])
		SSassets.transport.register_asset("minimap-[id]-meta.png", meta_icon)

// Метаданные зон нужны только OOC-миникарте и старой отправке через send().
/datum/minimap/proc/ensure_area_metadata()
	if(meta_icon)
		return
	var/datum/minimap/metadata = new(z_level, minx, miny, maxx, maxy, autocrop = FALSE)
	meta_icon = metadata.meta_icon
	color_area_names = metadata.color_area_names
	SSassets.transport.register_asset("minimap-[id]-meta.png", meta_icon)
	qdel(metadata)

/datum/minimap/proc/get_area_ui_data()
	if(!area_ui_data)
		ensure_area_metadata()
		// Встроенное изображение позволяет читать пиксели при любом транспорте ассетов.
		area_ui_data = list(
			"image" = "data:image/png;base64,[icon2base64(meta_icon)]",
			"names" = color_area_names,
		)
	return area_ui_data

/datum/minimap/proc/send(mob/user)
	if(!id)
		CRASH("ERROR: send called, but the minimap id is null/missing. ID: [id]")
	ensure_area_metadata()
	SSassets.transport.send_assets(user, list("minimap-[id].png" = map_icon, "minimap-[id]-meta.png" = meta_icon))

/datum/minimap_group
	var/list/minimaps = list()
	var/static/next_id = 0
	var/id
	var/name

/datum/minimap_group/New(list/maps, name)
	id = ++next_id
	src.name = name
	if(maps)
		minimaps = maps

/datum/minimap_group/proc/show(mob/user)
	if(!length(minimaps))
		to_chat(user, span_boldwarning("Карта станции недоступна."))
		return
	ui_interact(user)

/datum/minimap_group/ui_state(mob/user)
	return GLOB.always_state

/datum/minimap_group/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		var/list/map_assets = list()
		for(var/datum/minimap/floor_map as anything in minimaps)
			map_assets += "minimap-[floor_map.id].png"
			if(floor_map.department_map_icon)
				map_assets += "minimap-[floor_map.id]-departments.png"
		SSassets.transport.send_assets(user, map_assets)
		ui = new(user, src, "StationMinimap", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/minimap_group/ui_static_data(mob/user)
	var/list/maps = list()
	for(var/datum/minimap/floor_map as anything in minimaps)
		var/list/stack = SSmapping.get_connected_levels(floor_map.z_level)
		var/list/floor_data = floor_map.get_ui_data(stack.Find(floor_map.z_level))
		floor_data["areas"] = floor_map.get_area_ui_data()
		maps += list(floor_data)
	var/turf/user_turf = get_turf(user)
	return list("maps" = maps, "z" = user_turf?.z)

// Оба интерфейса используют одинаковые изображения и координаты карты.
/datum/minimap/proc/get_ui_data(floor_number)
	return list(
		"z" = z_level,
		"floor" = floor_number,
		"image" = SSassets.transport.get_asset_url("minimap-[id].png"),
		"department_image" = SSassets.transport.get_asset_url(department_map_icon ? "minimap-[id]-departments.png" : "minimap-[id].png"),
		"min_x" = minx,
		"min_y" = miny,
		"max_x" = maxx,
		"max_y" = maxy,
	)
