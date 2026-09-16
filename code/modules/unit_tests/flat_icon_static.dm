/// Статическая сборка совпадает с первым кадром анимации для направлений и вложенных слоёв.
/datum/unit_test/flat_icon_static_frames/Run()
	var/icon/animated = new
	var/direction_index = 0
	for(var/direction in GLOB.cardinals)
		direction_index++
		for(var/frame_index in 1 to 3)
			var/icon/frame = icon('icons/effects/effects.dmi', "nothing")
			frame.DrawBox(rgb(direction_index * 40, frame_index * 60, 100), 1, 1, 32, 32)
			animated.Insert(frame, "test", direction, frame_index, FALSE)
	TEST_ASSERT_NOTEQUAL(animated.GetPixel(1, 1, "test", SOUTH, 1), animated.GetPixel(1, 1, "test", SOUTH, 2), "Исходная иконка должна иметь разные кадры")
	TEST_ASSERT_NOTEQUAL(animated.GetPixel(1, 1, "test", SOUTH, 1), animated.GetPixel(1, 1, "test", NORTH, 1), "Исходная иконка должна иметь разные направления")

	for(var/direction in GLOB.cardinals)
		var/image/subject = image(animated, icon_state = "test", dir = direction)
		compare_first_frame(subject, "без слоёв, [dir2text(direction)]")
		var/icon/full_animation = getFlatIcon(subject)
		TEST_ASSERT_EQUAL(full_animation.GetPixel(1, 1, "", SOUTH, 2), animated.GetPixel(1, 1, "test", direction, 2), "Анимированная сборка потеряла второй кадр")

		var/image/underlay = image(animated, icon_state = "test", layer = -2)
		underlay.pixel_x = -3
		underlay.pixel_y = -2
		subject.underlays += underlay
		var/image/overlay = image(animated, icon_state = "test", layer = -1)
		overlay.pixel_x = 4
		overlay.pixel_y = 3
		overlay.alpha = 140
		overlay.color = "#ccaaff"
		var/image/nested = image(animated, icon_state = "test", dir = WEST, layer = -1)
		nested.pixel_y = 2
		nested.alpha = 90
		overlay.overlays += nested
		subject.overlays += overlay
		compare_first_frame(subject, "вложенные слои, [dir2text(direction)]")
		subject.color = "#ddbb99"
		subject.alpha = 190
		compare_first_frame(subject, "цвет и прозрачность, [dir2text(direction)]")
		subject.color = list(0.8, 0.1, 0, 0, 0.7, 0.1, 0.1, 0, 0.9, 0.1, 0, 0)
		var/image/reset_overlay = image(animated, icon_state = "test", layer = -1)
		reset_overlay.appearance_flags |= RESET_COLOR
		reset_overlay.color = "#aabbcc"
		reset_overlay.pixel_x = 2
		reset_overlay.alpha = 150
		subject.overlays += reset_overlay
		compare_first_frame(subject, "матрица цвета и RESET_COLOR, [dir2text(direction)]")

/datum/unit_test/flat_icon_static_frames/proc/compare_first_frame(image/subject, context)
	var/icon/full_animation = getFlatIcon(subject)
	var/icon/expected = icon(full_animation, "", SOUTH, 1, FALSE)
	var/icon/actual = getFlatIcon(subject, no_anim = TRUE)
	TEST_ASSERT_EQUAL(actual.Width(), expected.Width(), "Ширина отличается: [context]")
	TEST_ASSERT_EQUAL(actual.Height(), expected.Height(), "Высота отличается: [context]")
	for(var/pixel_x in 1 to expected.Width())
		for(var/pixel_y in 1 to expected.Height())
			TEST_ASSERT_EQUAL(actual.GetPixel(pixel_x, pixel_y), expected.GetPixel(pixel_x, pixel_y), "Пиксель [pixel_x],[pixel_y] отличается: [context]")
