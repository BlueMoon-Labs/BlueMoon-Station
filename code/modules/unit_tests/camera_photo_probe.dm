// Камера должна рисовать пол и в затенённом помещении. Служебная маска освещения
// из turf.contents прежде перекрывала фон чёрным цветом.

/datum/unit_test/camera_photo_reset_transform/Run()
	var/icon/base = icon('icons/effects/camera_image_base.dmi', "")
	base.DrawBox("#ff0000", 3, 4, 3, 4)
	var/icon/detail = icon('icons/effects/camera_image_base.dmi', "")
	detail.DrawBox("#00ff00", 5, 6, 5, 6)
	var/image/subject = image(icon = base)
	var/matrix/pose = matrix()
	pose.Translate(8, 0)
	subject.transform = pose
	var/image/overlay = image(icon = detail)
	for(var/grouping in list(0, KEEP_TOGETHER, KEEP_TOGETHER | KEEP_APART))
		subject.appearance_flags = grouping & KEEP_TOGETHER
		overlay.appearance_flags = RESET_TRANSFORM | (grouping & KEEP_APART)
		subject.overlays = list(overlay)
		var/list/offsets = list()
		var/icon/result = getFlatIcon(subject, no_anim = TRUE, icon_offsets = offsets, photo_transform = GLOBAL_PROC_REF(transform_camera_icon))
		var/detail_x = grouping == KEEP_TOGETHER ? 13 : 5
		TEST_ASSERT_EQUAL(result.GetPixel(11 + offsets["x"], 4 + offsets["y"]), "#ff0000", "Основа не получила матрицу объекта")
		TEST_ASSERT_EQUAL(result.GetPixel(detail_x + offsets["x"], 6 + offsets["y"]), "#00ff00", "Оверлей получил неверную матрицу при флагах [grouping]")

/// Returns TRUE if the pixel at (px,py) is present and not pure/near-black.
/datum/unit_test/proc/camera_pixel_is_lit(icon/ico, px, py)
	if(!ico)
		return FALSE
	var/col = ico.GetPixel(px, py)
	if(isnull(col))
		return FALSE
	var/list/rgb = ReadRGB(col)
	return (rgb[1] + rgb[2] + rgb[3]) > 12 // > ~#040404, i.e. not the dark-lighting fill

/datum/unit_test/camera_photo_shaded_background/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/bl = run_loc_floor_bottom_left
	var/turf/center = locate(bl.x + 1, bl.y + 1, bl.z)
	TEST_ASSERT_NOTNULL(center, "no center turf for camera test")

	// Build a 3x3 of floor turfs, each driven to a dark lighting state — exactly
	// the condition under which the bug manifested ("slightly shaded breaks").
	var/list/turfs = list()
	var/list/created_los = list()
	for(var/dx = -1 to 1)
		for(var/dy = -1 to 1)
			var/turf/T = locate(center.x + dx, center.y + dy, center.z)
			if(!isturf(T))
				continue
			if(!isfloorturf(T))
				T = T.ChangeTurf(/turf/open/floor/plasteel)
			if(!T.lighting_object)
				new /atom/movable/lighting_object(T)
				created_los += T.lighting_object
			T.lighting_object.color = LIGHTING_DARK_MATRIX
			T.lighting_object.update(animate_time = 0, use_animate = FALSE)
			turfs += T

	var/obj/item/camera/cam = allocate(/obj/item/camera, center)
	var/psize = 3 * world.icon_size
	var/icon/result = cam.camera_get_icon(turfs, center, psize, psize)

	TEST_ASSERT_NOTNULL(result, "camera_get_icon returned null")

	// Sample the 9 tile centers. Every background floor tile must be lit (not black).
	var/black_tiles = 0
	var/list/report = list()
	for(var/ty = 0 to 2)
		for(var/tx = 0 to 2)
			var/px = tx * world.icon_size + round(world.icon_size / 2)
			var/py = ty * world.icon_size + round(world.icon_size / 2)
			var/lit = camera_pixel_is_lit(result, px, py)
			if(!lit)
				black_tiles++
			report += "[tx],[ty]=[isnull(result.GetPixel(px, py)) ? "EMPTY" : result.GetPixel(px, py)]"

	log_test("camera_photo_shaded_background: tiles=[report.Join(" | ")]")

	// В одном кадре без вспышки освещённый пол должен сохраниться, а соседний остаться тёмным.
	var/list/previous_light = list()
	for(var/turf/tile as anything in turfs)
		var/atom/movable/lighting_object/light = tile.lighting_object
		previous_light[light] = light.color
		light.color = tile == center ? LIGHTING_BASE_MATRIX : LIGHTING_DARK_MATRIX
	cam.flash_enabled = FALSE
	var/icon/unflashed = cam.camera_get_icon(turfs, center, psize, psize)
	for(var/atom/movable/lighting_object/light as anything in previous_light)
		if(!QDELETED(light))
			light.color = previous_light[light]

	for(var/atom/movable/lighting_object/lo as anything in created_los)
		if(!QDELETED(lo))
			qdel(lo, force = TRUE)

	TEST_ASSERT_EQUAL(black_tiles, 0, "Shaded camera photo lost [black_tiles]/9 background floor tiles to black (lighting_object cloned into the photo)")
	var/sample_offset = round(world.icon_size / 2)
	var/center_pixel = world.icon_size + sample_offset
	TEST_ASSERT_NOTNULL(unflashed, "No-flash camera render returned null")
	TEST_ASSERT(camera_pixel_is_lit(unflashed, center_pixel, center_pixel), "No-flash photo lost the lit center tile")
	TEST_ASSERT(!camera_pixel_is_lit(unflashed, sample_offset, sample_offset), "No-flash photo ignored the dark neighbor")
