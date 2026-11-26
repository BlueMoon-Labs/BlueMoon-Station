/proc/is_camera_chat_appearance(image/visual)
	return visual.icon in GLOB.speech_bubble_icons

/proc/camera_can_render_subject(atom/movable/subject, see_ghosts = FALSE)
	if(!subject.alpha || (subject.invisibility && !(see_ghosts && isobserver(subject))))
		return FALSE
	// Служебные объекты рисуются отдельно от спрайтов сцены.
	return !(istype(subject, /atom/movable/lighting_object) || (subject.appearance_flags & PLANE_MASTER) || (subject.render_target && copytext(subject.render_target, 1, 2) == "*"))

/datum/camera_frame_entry
	var/image/visual
	var/pixel_left
	var/pixel_bottom
	var/render_plane

/datum/camera_frame_entry/New(atom/subject, tile_left, tile_bottom, image/attached_visual)
	visual = attached_visual || subject.appearance
	pixel_left = tile_left + subject.pixel_x + subject.pixel_w
	pixel_bottom = tile_bottom + subject.pixel_y + subject.pixel_z
	if(ismovable(subject))
		var/atom/movable/movable_subject = subject
		pixel_left += movable_subject.step_x
		pixel_bottom += movable_subject.step_y
	if(attached_visual)
		pixel_left += attached_visual.pixel_x + attached_visual.pixel_w
		pixel_bottom += attached_visual.pixel_y + attached_visual.pixel_z
	var/plane = visual.plane
	render_plane = plane == FLOAT_PLANE ? 0 : PLANE_TO_TRUE(plane)

/datum/camera_frame_entry/proc/draw(icon/frame, list/flat_icon_cache, blend_mode, tile_light = FALSE)
	var/appearance_key = "\ref[visual]"
	var/list/rendered = flat_icon_cache[appearance_key]
	if(!rendered)
		rendered = list()
		if(tile_light)
			// Матрица света использует исходную альфу для четвёртого угла.
			// visual.alpha читает только её множитель и даёт 0, хотя маска после перекраски непрозрачна.
			var/icon/light_mask = icon(visual.icon, visual.icon_state || "", visual.dir, 1)
			var/list/light_color = visual.color
			if(islist(light_color))
				light_mask.MapColors(arglist(light_color))
			rendered["icon"] = light_mask
		else
			rendered["icon"] = getFlatIcon(visual, no_anim = TRUE, icon_offsets = rendered, apply_photo_transform = TRUE)
		flat_icon_cache[appearance_key] = rendered
	var/icon/flattened = rendered["icon"]
	if(flattened)
		frame.Blend(flattened, blend_mode, pixel_left - rendered["x"], pixel_bottom - rendered["y"])

/proc/cmp_camera_frame_entry(datum/camera_frame_entry/left, datum/camera_frame_entry/right)
	if(left.render_plane != right.render_plane)
		return left.render_plane - right.render_plane
	return left.visual.layer - right.visual.layer

/obj/item/camera/proc/camera_get_icon(list/turf/turfs, turf/center, psize_x = 96, psize_y = 96)
	. = render_camera_frame(turfs, center, psize_x, psize_y, !flash_enabled, see_ghosts)
	if(!QDELETED(src) && !silent)
		play_camera_shutter(loc, custom_sound)

/proc/play_camera_shutter(atom/source, sound/custom_sound)
	playsound(source, custom_sound || pick('sound/items/polaroid1.ogg', 'sound/items/polaroid2.ogg'), 75, TRUE, -3)

/atom/movable/screen/map_view/photo_viewfinder
	icon = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = APPEARANCE_UI | TILE_BOUND
	var/atom/movable/screen/background/frame_border
	var/list/frame_appearances = list()
	var/list/frame_buffer = list()

/atom/movable/screen/map_view/photo_viewfinder/Destroy()
	hide_from()
	QDEL_NULL(frame_border)
	frame_appearances = null
	frame_buffer = null
	return ..()

/atom/movable/screen/map_view/photo_viewfinder/ensure_plane_group()
	if(!popup_plane_group)
		popup_plane_group = new /datum/plane_master_group/popup/on_demand/photo_viewfinder(PLANE_GROUP_POPUP_WINDOW(src), assigned_map)
	return popup_plane_group

/atom/movable/screen/map_view/photo_viewfinder/proc/show_frame(client/viewer, radius_x, radius_y)
	frame_border = new
	frame_border.assigned_map = assigned_map
	frame_border.del_on_map_removal = FALSE
	frame_border.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resize_frame(radius_x, radius_y)
	display_to_client(viewer)
	viewer.register_map_obj(frame_border)

/atom/movable/screen/map_view/photo_viewfinder/proc/resize_frame(radius_x, radius_y)
	frame_border?.fill_rect(1, 1, radius_x * 2 + 1, radius_y * 2 + 1)

/atom/movable/screen/map_view/photo_viewfinder/proc/clear_frame()
	if(!length(frame_appearances))
		return FALSE
	frame_appearances.Cut()
	overlays.Cut()
	return TRUE

/atom/movable/screen/map_view/photo_viewfinder/proc/update_frame(turf/center, mob/user, radius_x, radius_y, flash_enabled)
	var/list/turfs = camera_frame_turfs(center, user, radius_x, radius_y, flash_enabled)
	var/list/scene = frame_buffer
	for(var/turf/tile as anything in turfs)
		var/x = (tile.x - center.x + radius_x) * world.icon_size
		var/y = (tile.y - center.y + radius_y) * world.icon_size
		scene += tile.appearance
		scene += x
		scene += y
		if(tile.loc.icon_state)
			scene += tile.loc.appearance
			scene += x
			scene += y
		if(!flash_enabled && tile.lighting_object)
			scene += tile.lighting_object.appearance
			scene += x
			scene += y
		// vis_contents турфа показал бы и невидимое содержимое. Передаём только внешности, разрешённые для снимка.
		for(var/atom/movable/subject as anything in tile.contents)
			if(!camera_can_render_subject(subject) || is_camera_chat_appearance(subject))
				continue
			scene += subject.appearance
			scene += x + subject.step_x
			scene += y + subject.step_y

	var/offset = GET_TURF_PLANE_OFFSET(center)
	popup_plane_group.ensure_popup_depth(offset)
	var/atom/movable/screen/plane_master/overlay_light = popup_plane_group.get_plane(GET_NEW_PLANE(O_LIGHTING_VISUAL_PLANE, offset))
	var/overlay_alpha = flash_enabled ? 0 : 255
	if(overlay_light && overlay_light.alpha != overlay_alpha)
		overlay_light.alpha = overlay_alpha
	if(compare_list(scene, frame_appearances))
		scene.Cut()
		return FALSE
	frame_buffer = frame_appearances
	frame_buffer.Cut()
	frame_appearances = scene
	var/list/sprites = list()
	for(var/index = 1, index <= length(scene), index += 3)
		var/image/source_appearance = scene[index]
		// Передаём dir в конструктор image, чтобы слой не наследовал направление экрана.
		var/image/sprite = image(source_appearance, dir = source_appearance.dir)
		sprite.pixel_x += scene[index + 1]
		sprite.pixel_y += scene[index + 2]
		sprite.maptext = null
		sprites += sprite
	overlays = sprites
	return TRUE

/datum/plane_master_group/popup/on_demand/photo_viewfinder/get_plane_types()
	return list(
		/atom/movable/screen/plane_master/lighting,
		/atom/movable/screen/plane_master/o_light_visual,
		/atom/movable/screen/plane_master/emissive,
		/atom/movable/screen/plane_master/lamps,
		/atom/movable/screen/plane_master/lamps_selfglow,
		/atom/movable/screen/plane_master/lamps_glare,
		/atom/movable/screen/plane_master/chat_messages,
	)

/proc/render_camera_frame(list/turf/turfs, turf/center, psize_x, psize_y, use_scene_lighting, see_ghosts)
	var/list/entries = list()
	var/list/tile_lights
	var/list/overlay_lights
	var/overlay_light_plane = use_scene_lighting ? MUTATE_PLANE(O_LIGHTING_VISUAL_PLANE, center) : null
	var/x_origin = round((psize_x - world.icon_size) / 2) + 1
	var/y_origin = round((psize_y - world.icon_size) / 2) + 1
	// Снимаем внешность и координаты до первого CHECK_TICK, чтобы кадр не менялся при сборке.
	for(var/turf/tile as anything in turfs)
		var/tile_left = (tile.x - center.x) * world.icon_size + x_origin
		var/tile_bottom = (tile.y - center.y) * world.icon_size + y_origin
		entries += new /datum/camera_frame_entry(tile, tile_left, tile_bottom)
		if(isclosedturf(tile))
			// Подложки диагональных стен рисуются на плоскости пола или космоса.
			for(var/image/ground as anything in tile.underlays)
				var/ground_plane = PLANE_TO_TRUE(ground.plane)
				if(ground.plane != tile.plane && (ground_plane == FLOOR_PLANE || ground_plane == PLANE_SPACE))
					entries += new /datum/camera_frame_entry(tile, tile_left, tile_bottom, ground)
		if(tile.loc.icon_state)
			entries += new /datum/camera_frame_entry(tile.loc, tile_left, tile_bottom)
		if(use_scene_lighting && tile.lighting_object)
			LAZYADD(tile_lights, new /datum/camera_frame_entry(tile.lighting_object, tile_left, tile_bottom))
		for(var/atom/movable/subject as anything in tile.contents)
			if(!camera_can_render_subject(subject, see_ghosts))
				continue
			entries += new /datum/camera_frame_entry(subject, tile_left, tile_bottom)
			if(use_scene_lighting)
				for(var/image/light_overlay as anything in subject.underlays)
					if(light_overlay.plane == overlay_light_plane && light_overlay.alpha)
						LAZYADD(overlay_lights, new /datum/camera_frame_entry(subject, tile_left, tile_bottom, light_overlay))

	var/icon/result = icon('icons/effects/camera_image_base.dmi', "")
	result.Scale(psize_x, psize_y)
	result.DrawBox("#000000", 1, 1, psize_x, psize_y)
	sortTim(entries, GLOBAL_PROC_REF(cmp_camera_frame_entry))

	// Одинаковые внешности используют общий растр и смещение в пределах кадра.
	var/list/flat_icon_cache = list()
	var/icon/lighting_map
	if(tile_lights || overlay_lights)
		// Белый сохраняет яркость тайлов без маски. Цветные маски освещают уже собранную сцену.
		lighting_map = icon('icons/effects/camera_image_base.dmi', "")
		lighting_map.Scale(psize_x, psize_y)
		lighting_map.DrawBox(COLOR_WHITE, 1, 1, psize_x, psize_y)
		for(var/datum/camera_frame_entry/light as anything in tile_lights)
			light.draw(lighting_map, flat_icon_cache, ICON_OVERLAY, tile_light = TRUE)
			CHECK_TICK
		for(var/datum/camera_frame_entry/light as anything in overlay_lights)
			light.draw(lighting_map, flat_icon_cache, ICON_OVERLAY)
			CHECK_TICK

	for(var/datum/camera_frame_entry/entry as anything in entries)
		if(lighting_map && entry.render_plane > LIGHTING_PLANE)
			result.Blend(lighting_map, ICON_MULTIPLY)
			lighting_map = null
		entry.draw(result, flat_icon_cache, blendMode2iconMode(entry.visual.blend_mode))
		CHECK_TICK
	if(lighting_map)
		result.Blend(lighting_map, ICON_MULTIPLY)

	return result

#define CAMERA_RASTER_SIDE_LIMIT 2048

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
	if(!b && !d && new_width <= CAMERA_RASTER_SIDE_LIMIT && new_height <= CAMERA_RASTER_SIDE_LIMIT)
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
	new_width = min(new_width, CAMERA_RASTER_SIDE_LIMIT)
	new_height = min(new_height, CAMERA_RASTER_SIDE_LIMIT)
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

#undef CAMERA_RASTER_SIDE_LIMIT
