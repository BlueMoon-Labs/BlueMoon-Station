/// Попап камеры: свет пустого этажа прозрачен и не зачерняет этажи под собой, свет каждого этажа получает фильтры зрителя.
/datum/unit_test/multiz_camera_popup_lighting

/datum/unit_test/multiz_camera_popup_lighting/Run()
	multiz_ai_floor_test_levels()
	TEST_ASSERT(SSmapping.max_plane_offset >= 1, "test premise: нет второго этажа связки")

	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.lighting_quality = LIGHTING_QUALITY_HIGH
	prefs.lighting_blur = LIGHTING_BLUR_MAX
	viewer.mock_client = new /datum/client_interface()
	viewer.mock_client.prefs = prefs

	var/obj/machinery/computer/security/console = allocate(/obj/machinery/computer/security)
	var/datum/plane_master_group/popup/group = new(PLANE_GROUP_POPUP_WINDOW(console), console.map_name)
	allocated += group
	for(var/plane_key in group.plane_masters)
		var/atom/movable/screen/plane_master/plane = group.plane_masters[plane_key]
		plane.refresh_backdrop(viewer)

	var/list/backdrops = LAZYCOPY(viewer.fullscreens)
	for(var/category in backdrops)
		viewer.clear_fullscreen(category, 0)
	viewer.mock_client = null

	var/list/problems = list()
	var/lighting_floors = 0
	for(var/plane_key in group.plane_masters)
		var/atom/movable/screen/plane_master/lighting/light = group.plane_masters[plane_key]
		if(!istype(light))
			continue
		lighting_floors++
		var/edge_sealed = FALSE
		for(var/filter_name in light.filter_data)
			var/list/params = light.filter_data[filter_name]
			if(params["type"] != "color")
				continue
			var/list/matrix = params["color"]
			if(color_matrix_alpha(matrix, 0) != 0)
				problems += "фильтр '[filter_name]' делает пустой свет этажа [light.offset] непрозрачным и зачерняет этажи под ним"
			if(color_matrix_alpha(matrix, 0.5) >= 1)
				edge_sealed = TRUE
		if(!light.filter_data?["lighting_blur"])
			problems += "свет этажа [light.offset] без размытия зрителя"
		else if(!edge_sealed)
			problems += "полупрозрачный край размытия света этажа [light.offset] остался полупрозрачным"
	if(lighting_floors != SSmapping.max_plane_offset + 1)
		problems += "свет построен на [lighting_floors] этажах из [SSmapping.max_plane_offset + 1]"
	if(length(backdrops))
		problems += "попап повесил на основную карту зрителя подложки света: [jointext(backdrops, ", ")]"
	TEST_ASSERT(!length(problems), jointext(problems, "; "))

/// Альфа на выходе матрицы для чёрного пикселя с альфой alpha.
/datum/unit_test/multiz_camera_popup_lighting/proc/color_matrix_alpha(list/matrix, alpha)
	var/result = alpha * matrix[16]
	if(length(matrix) >= 20)
		result += matrix[20]
	return result
