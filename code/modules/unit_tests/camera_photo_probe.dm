// Regression test for the camera "no background" bug: a photo taken in a shaded
// (dynamic-lit, non-fully-bright) area must still render the floor/scene, not a
// solid black tile. Root cause was camera_get_icon cloning the turf's
// lighting_object (which lives in turf.contents) — its dark color matrix painted
// every floor tile black. See camera_image_capturing.dm.

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
	var/datum/turf_reservation/clone_area = SSmapping.RequestBlockReservation(3, 3)
	var/psize = 3 * world.icon_size
	var/icon/result = cam.camera_get_icon(turfs, center, psize, psize, clone_area, 1, 1, 3, 3)

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

	qdel(clone_area)
	for(var/atom/movable/lighting_object/lo as anything in created_los)
		if(!QDELETED(lo))
			qdel(lo, force = TRUE)

	TEST_ASSERT_EQUAL(black_tiles, 0, "Shaded camera photo lost [black_tiles]/9 background floor tiles to black (lighting_object cloned into the photo)")
