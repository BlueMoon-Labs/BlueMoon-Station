/datum/camera_frame_entry
	var/image/visual
	var/pixel_left
	var/pixel_bottom
	var/render_plane

/datum/camera_frame_entry/New(atom/subject, tile_left, tile_bottom)
	visual = subject.appearance
	pixel_left = tile_left + subject.pixel_x + subject.pixel_w
	pixel_bottom = tile_bottom + subject.pixel_y + subject.pixel_z
	if(ismovable(subject))
		var/atom/movable/movable_subject = subject
		pixel_left += movable_subject.step_x
		pixel_bottom += movable_subject.step_y
	var/plane = visual.plane
	render_plane = plane == FLOAT_PLANE ? 0 : PLANE_TO_TRUE(plane)

/proc/cmp_camera_frame_entry(datum/camera_frame_entry/left, datum/camera_frame_entry/right)
	if(left.render_plane != right.render_plane)
		return left.render_plane - right.render_plane
	return left.visual.layer - right.visual.layer

/obj/item/camera/proc/camera_get_icon(list/turf/turfs, turf/center, psize_x = 96, psize_y = 96)
	var/list/entries = list()
	var/x_origin = round((psize_x - world.icon_size) / 2) + 1
	var/y_origin = round((psize_y - world.icon_size) / 2) + 1
	// Снимаем внешность и координаты до первого CHECK_TICK, чтобы кадр не менялся при сборке.
	for(var/turf/tile as anything in turfs)
		var/tile_left = (tile.x - center.x) * world.icon_size + x_origin
		var/tile_bottom = (tile.y - center.y) * world.icon_size + y_origin
		entries += new /datum/camera_frame_entry(tile, tile_left, tile_bottom)
		if(tile.loc.icon_state)
			entries += new /datum/camera_frame_entry(tile.loc, tile_left, tile_bottom)
		for(var/atom/movable/subject as anything in tile.contents)
			if(!subject.alpha || (subject.invisibility && !(see_ghosts && isobserver(subject))))
				continue
			// Служебные маски и объекты освещения нельзя накладывать на кадр как обычные спрайты.
			if(istype(subject, /atom/movable/lighting_object) || (subject.appearance_flags & PLANE_MASTER) || (subject.render_target && copytext(subject.render_target, 1, 2) == "*"))
				continue
			entries += new /datum/camera_frame_entry(subject, tile_left, tile_bottom)

	var/icon/result = icon('icons/effects/camera_image_base.dmi', "")
	result.Scale(psize_x, psize_y)
	result.DrawBox("#000000", 1, 1, psize_x, psize_y)
	sortTim(entries, GLOBAL_PROC_REF(cmp_camera_frame_entry))

	// У одинаковых внешностей общие растр и смещение, даже если спрайты стоят на разных тайлах.
	var/list/flat_icon_cache = list()
	for(var/datum/camera_frame_entry/entry as anything in entries)
		var/image/visual = entry.visual
		var/appearance_key = "\ref[visual]"
		var/list/rendered = flat_icon_cache[appearance_key]
		if(!rendered)
			rendered = list()
			rendered["icon"] = getFlatIcon(visual, no_anim = TRUE, icon_offsets = rendered, apply_photo_transform = TRUE)
			flat_icon_cache[appearance_key] = rendered
		var/icon/flattened = rendered["icon"]
		if(flattened)
			result.Blend(flattened, blendMode2iconMode(visual.blend_mode), entry.pixel_left - rendered["x"], entry.pixel_bottom - rendered["y"])
		CHECK_TICK

	if(!QDELETED(src) && !silent)
		playsound(loc, custom_sound || pick('sound/items/polaroid1.ogg', 'sound/items/polaroid2.ogg'), 75, TRUE, -3)
	return result

/proc/transform_camera_icon(icon/source, matrix/pose, list/offsets, pivot_x, pivot_y)
	var/source_x = -offsets["x"] - pivot_x
	var/source_y = -offsets["y"] - pivot_y
	var/width = source.Width()
	var/height = source.Height()
	var/a = pose.a
	var/b = pose.b
	var/d = pose.d
	var/e = pose.e
	var/determinant = a * e - b * d
	if(!determinant)
		return null

	var/translate_x = pivot_x + pose.c + a * source_x + b * source_y
	var/translate_y = pivot_y + pose.f + d * source_x + e * source_y
	var/x_from_width = a * width
	var/x_from_height = b * height
	var/y_from_width = d * width
	var/y_from_height = e * height
	var/x_min = translate_x + min(0, x_from_width) + min(0, x_from_height)
	var/y_min = translate_y + min(0, y_from_width) + min(0, y_from_height)
	var/new_width = round(abs(x_from_width) + abs(x_from_height) + 0.5)
	var/new_height = round(abs(y_from_width) + abs(y_from_height) + 0.5)
	if(!new_width || !new_height)
		return null
	var/left = round(x_min + 0.5)
	var/bottom = round(y_min + 0.5)
	offsets["x"] = -left
	offsets["y"] = -bottom

	// Перенос и масштабирование без поворота обрабатываем средствами /icon.
	if(!b && !d && new_width <= 2048 && new_height <= 2048)
		if(a == 1 && e == 1)
			return source
		var/icon/scaled = icon(source)
		scaled.Scale(new_width, new_height)
		if(a < 0)
			scaled.Flip(EAST)
		if(e < 0)
			scaled.Flip(NORTH)
		return scaled

	// Ограничиваем растр для экстремальных матриц. Обратное преобразование сохраняет
	// исходные цвета и избегает дыр между пикселями при повороте или сдвиге.
	new_width = min(new_width, 2048)
	new_height = min(new_height, 2048)
	var/icon/result = icon('icons/effects/camera_image_base.dmi', "")
	result.Scale(new_width, new_height)
	for(var/y in 1 to new_height)
		var/delta_y = bottom + y - 0.5 - translate_y
		var/run_start = 1
		var/run_color
		for(var/x in 1 to new_width)
			var/delta_x = left + x - 0.5 - translate_x
			var/sample_x = round((e * delta_x - b * delta_y) / determinant) + 1
			var/sample_y = round((a * delta_y - d * delta_x) / determinant) + 1
			var/sample_color
			if(sample_x >= 1 && sample_x <= width && sample_y >= 1 && sample_y <= height)
				sample_color = source.GetPixel(sample_x, sample_y)
			if(sample_color != run_color)
				if(run_color)
					result.DrawBox(run_color, run_start, y, x - 1, y)
				run_start = x
				run_color = sample_color
		if(run_color)
			result.DrawBox(run_color, run_start, y, new_width, y)
		CHECK_TICK
	return result
