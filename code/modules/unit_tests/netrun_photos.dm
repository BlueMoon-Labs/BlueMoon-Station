/// Build a real, separately reserved floor scene; no renderer or visibility stubs.
/datum/unit_test/netrun_photo_browser_export_single_frame/Run()
	var/icon/animated = icon('icons/effects/camera_image_base.dmi', "")
	var/icon/red = netrun_photo_color_icon("#ff0000")
	var/icon/blue = netrun_photo_color_icon("#0000ff")
	animated.Insert(red, "", SOUTH, 1)
	animated.Insert(blue, "", SOUTH, 2)
	var/datum/picture/picture = allocate(/datum/picture, "Export", null, animated)
	// Keep the browser-visible bytes for PNG dimension/pixel inspection outside BYOND.
	fdel("data/netrun-photo-export.base64")
	text2file(picture.get_base64(), "data/netrun-photo-export.base64")
	TEST_ASSERT_EQUAL(picture.get_base64(), icon2base64(icon(animated, dir = SOUTH, frame = 1)), "The export must select the first still frame")
	var/previous = picture.get_base64()
	picture.picture_image = blue
	TEST_ASSERT_NOTEQUAL(picture.get_base64(), previous, "Replacing the picture must invalidate the browser export cache")

/datum/unit_test/proc/netrun_photo_scene(side)
	var/datum/turf_reservation/scene = SSmapping.RequestBlockReservation(side + 2, side + 2, border_type_override = /turf/closed/wall)
	allocated += scene
	for(var/turf/T as anything in scene.reserved_turfs.Copy())
		if(T.x == scene.bottom_left_coords[1] || T.y == scene.bottom_left_coords[2] || T.x == scene.top_right_coords[1] || T.y == scene.top_right_coords[2])
			continue
		T.ChangeTurf(/turf/open/floor/plasteel)
	return scene

/datum/unit_test/proc/netrun_photo_color_icon(color)
	var/icon/tile = icon('icons/effects/effects.dmi', "nothing")
	tile.DrawBox(color, 1, 1, world.icon_size, world.icon_size)
	return tile

/// Read the actual PNG IHDR, independent of BYOND's per-frame icon.Width()/Height().
/// A multi-frame DMI reports 32x32 to those methods even when its PNG is a 5x5 sheet.
/datum/unit_test/proc/netrun_photo_png_dimensions(encoded)
	if(!istext(encoded) || length(encoded) < 32)
		return null
	var/alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	var/list/header = list()
	for(var/offset = 1; offset <= 29; offset += 4)
		var/list/quartet = list()
		for(var/index in 0 to 3)
			var/value = findtextEx(alphabet, copytext(encoded, offset + index, offset + index + 1)) - 1
			if(value < 0)
				return null
			quartet += value
		header += (quartet[1] << 2) | (quartet[2] >> 4)
		header += ((quartet[2] & 15) << 4) | (quartet[3] >> 2)
		header += ((quartet[3] & 3) << 6) | quartet[4]
	var/list/signature = list(137, 80, 78, 71, 13, 10, 26, 10)
	for(var/index in 1 to length(signature))
		if(header[index] != signature[index])
			return null
	if(header[13] != 73 || header[14] != 72 || header[15] != 68 || header[16] != 82)
		return null
	var/width = ((header[17] * 256 + header[18]) * 256 + header[19]) * 256 + header[20]
	var/height = ((header[21] * 256 + header[22]) * 256 + header[23]) * 256 + header[24]
	return list(width, height)

/// An actual 24-frame scrubber appearance must never turn a scene into a sprite sheet.
/datum/unit_test/netrun_photo_animated_scene_exports_one_png_frame/Run()
	var/datum/turf_reservation/scene = netrun_photo_scene(3)
	var/turf/center = locate(scene.bottom_left_coords[1] + 2, scene.bottom_left_coords[2] + 2, scene.bottom_left_coords[3])
	var/list/turfs = list()
	for(var/dy = -1 to 1)
		for(var/dx = -1 to 1)
			var/turf/T = locate(center.x + dx, center.y + dy, center.z)
			T.icon = netrun_photo_color_icon(rgb(70 + (dx + 1) * 60, 70 + (dy + 1) * 60, 50))
			T.icon_state = ""
			T.color = null
			T.overlays.Cut()
			T.underlays.Cut()
			turfs += T
	var/obj/item/animated_atom = allocate(/obj/item, center)
	animated_atom.icon = 'icons/obj/atmospherics/components/unary_devices.dmi'
	animated_atom.icon_state = "scrub_on"
	animated_atom.dir = SOUTH
	animated_atom.pixel_x = 0
	animated_atom.pixel_y = 0
	var/icon/native_icon = icon(animated_atom.icon)
	var/icon/animated_icon = icon(animated_atom.icon, animated_atom.icon_state, SOUTH)
	TEST_ASSERT_NOTEQUAL(native_icon.GetPixel(12, 22, "scrub_on", SOUTH, 1), native_icon.GetPixel(12, 22, "scrub_on", SOUTH, 24), "The native fixture must contain genuinely different first and twenty-fourth frames")
	var/list/fixture_dimensions = netrun_photo_png_dimensions(icon2base64(animated_icon))
	TEST_ASSERT_NOTNULL(fixture_dimensions, "The native animation must export a valid PNG")
	TEST_ASSERT(fixture_dimensions[1] > world.icon_size && fixture_dimensions[2] > world.icon_size, "The fixture must exercise a real multi-frame sprite sheet")
	var/obj/item/camera/netrun_capture/capture = allocate(/obj/item/camera/netrun_capture, center)
	var/datum/turf_reservation/clones = SSmapping.RequestBlockReservation(3, 3)
	allocated += clones
	var/side = 3 * world.icon_size
	var/icon/rendered = capture.camera_get_icon(turfs, center, side, side, clones, 1, 1, 3, 3)
	TEST_ASSERT_NOTNULL(rendered, "The real clone renderer must return the animated scene")
	var/list/rendered_dimensions = netrun_photo_png_dimensions(icon2base64(rendered))
	TEST_ASSERT_NOTNULL(rendered_dimensions, "The rendered scene must export a valid PNG")
	TEST_ASSERT_EQUAL(rendered_dimensions[1], side, "The renderer must collapse animation before blending, rather than create multiple scene columns")
	TEST_ASSERT_EQUAL(rendered_dimensions[2], side, "The renderer must export one scene row rather than an animation sheet")
	TEST_ASSERT_EQUAL(rendered.GetPixel(world.icon_size + 12, world.icon_size + 22), native_icon.GetPixel(12, 22, "scrub_on", SOUTH, 1), "The single scene must contain the actual native appearance's first frame")
	// Exercise the production capture and picture export as well as the renderer itself.
	capture.captureimage(center, null, FALSE, 1, 1, turfs)
	TEST_ASSERT_NOTNULL(capture.result, "Native capture must create a photograph")
	var/encoded = capture.result.get_base64()
	var/export_path = "data/netrun-photo-animated-scene.base64"
	fdel(export_path)
	text2file(encoded, export_path)
	var/list/exported_dimensions = netrun_photo_png_dimensions(encoded)
	TEST_ASSERT_NOTNULL(exported_dimensions, "The browser-visible photograph must be a valid PNG")
	TEST_ASSERT_EQUAL(exported_dimensions[1], side, "The browser must receive the actual scene width, not the width of a sprite sheet")
	TEST_ASSERT_EQUAL(exported_dimensions[2], side, "The browser must receive the actual scene height, not the height of a sprite sheet")

/// Distinct real appearances must not share a recycled temporary appearance-ref cache slot.
/datum/unit_test/netrun_photo_distinct_scene_pixels/Run()
	var/datum/turf_reservation/scene = netrun_photo_scene(3)
	var/turf/center = locate(scene.bottom_left_coords[1] + 2, scene.bottom_left_coords[2] + 2, scene.bottom_left_coords[3])
	var/list/turfs = list()
	var/list/expected = list()
	var/index = 0
	for(var/dy = -1 to 1)
		for(var/dx = -1 to 1)
			index++
			var/turf/T = locate(center.x + dx, center.y + dy, center.z)
			var/icon/tile = netrun_photo_color_icon(rgb(20 + index * 20, 30 + (index % 3) * 55, 200 - index * 12))
			T.icon = tile
			T.icon_state = ""
			T.color = null
			T.overlays.Cut()
			T.underlays.Cut()
			turfs += T
			expected[T] = tile.GetPixel(16, 16)
			// Mix floors and solid objects: the original bug duplicated both kinds.
			if(index == 3 || index == 7)
				var/obj/item/marker = allocate(/obj/item, T)
				var/icon/marker_icon = netrun_photo_color_icon(index == 3 ? "#ff22cc" : "#22ddff")
				marker.icon = marker_icon
				marker.icon_state = ""
				marker.pixel_x = 0
				marker.pixel_y = 0
				expected[T] = marker_icon.GetPixel(16, 16)
	var/obj/item/camera/netrun_capture/capture = allocate(/obj/item/camera/netrun_capture, center)
	var/datum/turf_reservation/clones = SSmapping.RequestBlockReservation(3, 3)
	allocated += clones
	var/side = 3 * world.icon_size
	var/icon/cloned = capture.camera_get_icon(turfs, center, side, side, clones, 1, 1, 3, 3)
	var/icon/direct = capture.camera_get_icon(turfs, center, side, side, null, 1, 1, 3, 3)
	TEST_ASSERT_NOTNULL(cloned, "The real clone capture must produce an image")
	TEST_ASSERT_NOTNULL(direct, "The direct capture must produce an image")
	var/list/distinct = list()
	for(var/turf/T as anything in turfs)
		var/px = (T.x - center.x + 1) * world.icon_size + 16
		var/py = (T.y - center.y + 1) * world.icon_size + 16
		TEST_ASSERT_EQUAL(cloned.GetPixel(px, py), expected[T], "Clone capture duplicated another appearance at tile [T.x - center.x],[T.y - center.y]")
		TEST_ASSERT_EQUAL(direct.GetPixel(px, py), expected[T], "Direct capture duplicated another appearance at tile [T.x - center.x],[T.y - center.y]")
		distinct[cloned.GetPixel(px, py)] = TRUE
	TEST_ASSERT_EQUAL(length(distinct), 9, "Nine deliberately different scene tiles must remain nine different pixel samples")

/// The configured camera range determines real pixels, file capacity and the printed photo.
/datum/unit_test/netrun_photo_full_range_file_and_print/Run()
	var/datum/turf_reservation/scene = netrun_photo_scene(19)
	var/turf/center = locate(scene.bottom_left_coords[1] + 10, scene.bottom_left_coords[2] + 10, scene.bottom_left_coords[3])
	var/obj/machinery/camera/camera = allocate(/obj/machinery/camera, center)
	camera.set_machine_stat(0)
	camera.status = TRUE
	camera.view_range = 7
	camera.mark_visibility_dirty()
	var/turf/far_turf = locate(center.x + 6, center.y, center.z)
	var/obj/item/marker = allocate(/obj/item, far_turf)
	var/icon/marker_icon = netrun_photo_color_icon("#ff22cc")
	marker.icon = marker_icon
	marker.icon_state = ""
	marker.pixel_x = 0
	marker.pixel_y = 0
	var/obj/item/host = allocate(/obj/item, center)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/component/netrun_node/node = camera.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "The security camera must be a real network node")
	TEST_ASSERT(far_turf in camera.get_visible_turfs(), "The distant marker must be in the camera's actual view")
	var/datum/netrun_command/command = SSnetrun.get_command("cam_photo")
	console.inventory.local_store.capacity = 3
	command.execute(node, console)
	TEST_ASSERT_EQUAL(length(console.inventory.local_store.files), 0, "A full-range frame must not bypass its calculated memory requirement")
	TEST_ASSERT(!camera.netrun_photographing && camera.netrun_next_photo == 0, "Insufficient memory must fail before exposing a frame or starting cooldown")
	console.inventory.local_store.capacity = 4
	command.execute(node, console)
	var/datum/netrun_file/file = console.selected_local_file(NETRUN_FILE_PHOTO)
	TEST_ASSERT_NOTNULL(file, "Capturing a working camera must produce a selected photo file")
	TEST_ASSERT_NOTNULL(file.picture, "The photo file must own a real picture datum")
	TEST_ASSERT_EQUAL(file.picture.psize_x, 15 * world.icon_size, "Radius seven means fifteen turfs, not seven or three")
	TEST_ASSERT_EQUAL(file.picture.psize_y, 15 * world.icon_size, "The full configured vertical range must be retained")
	TEST_ASSERT_EQUAL(file.picture.picture_image.Width(), file.picture.psize_x, "Stored pixel width must match the declared full-size frame")
	TEST_ASSERT_EQUAL(file.picture.picture_image.Height(), file.picture.psize_y, "Stored pixel height must match the declared full-size frame")
	TEST_ASSERT_EQUAL(file.size, 4, "A 225-turf frame must account for four 64-turf memory cells")
	var/px = (7 + 6) * world.icon_size + 16
	var/py = 7 * world.icon_size + 16
	TEST_ASSERT_EQUAL(file.picture.picture_image.GetPixel(px, py), marker_icon.GetPixel(16, 16), "A visible object six turfs away must appear in the saved image")

	var/obj/item/modular_computer/laptop/computer = allocate(/obj/item/modular_computer/laptop, center)
	computer.enabled = TRUE
	var/obj/item/computer_hardware/printer/printer = allocate(/obj/item/computer_hardware/printer, center)
	computer.install_component(printer)
	TEST_ASSERT_EQUAL(printer.holder, computer, "The printer must be installed through the real hardware system")
	var/paper_before = printer.stored_paper
	var/datum/component/netrun_node/computer_node = computer.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_command/print_command = SSnetrun.get_command("pc_print")
	print_command.execute(computer_node, console)
	TEST_ASSERT_EQUAL(printer.stored_paper, paper_before - 1, "Printing the selected photograph must consume real paper")
	var/obj/item/photo/printed = locate(/obj/item/photo) in center
	TEST_ASSERT_NOTNULL(printed, "The hardware printer must produce an actual photo item")
	TEST_ASSERT_NOTEQUAL(printed.picture, file.picture, "A printed photo must have independent picture ownership")
	TEST_ASSERT_EQUAL(printed.picture.picture_image.GetPixel(px, py), marker_icon.GetPixel(16, 16), "Printing must preserve the distant marker's real pixels")
	console.delete_local_file(file)
	TEST_ASSERT(!QDELETED(printed.picture), "Deleting the saved file must not invalidate the physical photograph")
	TEST_ASSERT_EQUAL(printed.picture.picture_image.Width(), 15 * world.icon_size, "The printed full-size photograph must survive removal of its source file")

/// Capture uses the source camera's normal/XRay visibility instead of a temporary item's view.
/datum/unit_test/netrun_photo_camera_visibility/Run()
	var/datum/turf_reservation/scene = netrun_photo_scene(7)
	var/turf/center = locate(scene.bottom_left_coords[1] + 4, scene.bottom_left_coords[2] + 4, scene.bottom_left_coords[3])
	for(var/dy = -3 to 3)
		var/turf/occluder = locate(center.x + 1, center.y + dy, center.z)
		occluder.ChangeTurf(/turf/closed/wall)
	var/obj/machinery/camera/camera = allocate(/obj/machinery/camera, center)
	camera.set_machine_stat(0)
	camera.status = TRUE
	camera.view_range = 2
	camera.mark_visibility_dirty()
	var/turf/behind_wall = locate(center.x + 2, center.y, center.z)
	var/obj/item/marker = allocate(/obj/item, behind_wall)
	var/icon/marker_icon = netrun_photo_color_icon("#ff22cc")
	marker.icon = marker_icon
	marker.icon_state = ""
	marker.pixel_x = 0
	marker.pixel_y = 0
	TEST_ASSERT(!(behind_wall in camera.get_visible_turfs()), "An ordinary camera must not see through the separating wall")
	var/obj/item/camera/netrun_capture/normal = allocate(/obj/item/camera/netrun_capture, center)
	normal.captureimage(camera, null, FALSE, camera.netrun_photo_radius(), camera.netrun_photo_radius(), camera.get_visible_turfs().Copy())
	TEST_ASSERT_NOTNULL(normal.result, "Normal camera capture must produce a real picture")
	TEST_ASSERT_EQUAL(normal.result.picture_image.Width(), 5 * world.icon_size, "A deliberately reduced radius two must produce a five-turf frame")
	var/px = 4 * world.icon_size + 16
	var/py = 2 * world.icon_size + 16
	TEST_ASSERT_NOTEQUAL(normal.result.picture_image.GetPixel(px, py), marker_icon.GetPixel(16, 16), "An occluded marker must not leak into the normal camera snapshot")
	camera.upgradeXRay()
	TEST_ASSERT(behind_wall in camera.get_visible_turfs(), "The real XRay upgrade must expose the previously hidden tile")
	var/obj/item/camera/netrun_capture/xray = allocate(/obj/item/camera/netrun_capture, center)
	xray.captureimage(camera, null, FALSE, camera.netrun_photo_radius(), camera.netrun_photo_radius(), camera.get_visible_turfs().Copy())
	TEST_ASSERT_NOTNULL(xray.result, "XRay camera capture must produce a real picture")
	TEST_ASSERT_EQUAL(xray.result.picture_image.GetPixel(px, py), marker_icon.GetPixel(16, 16), "An XRay camera must preserve its own visible pixels beyond the wall")
	camera.view_range = 100
	TEST_ASSERT_EQUAL(camera.netrun_photo_radius(), 10, "Oversized camera ranges must respect the rendering work cap")
	TEST_ASSERT_EQUAL(camera.netrun_photo_storage_size(), 7, "The capped frame must still be charged for its actual area")
