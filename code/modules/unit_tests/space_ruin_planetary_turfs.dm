/// Планетарный турф в космической руине вечно тянет комнату к воздуху планеты и держит её активной в SSair.
/datum/unit_test/space_ruin_planetary_turfs

/datum/unit_test/space_ruin_planetary_turfs/Run()
	// Initialize сам снимает planetary_atmos вне Reebe
	var/static/list/fixed_at_init = typecacheof(/turf/open/floor/clockwork/reebe)
	// по типам, а не по SSmapping.space_ruins_templates: там ключ - имя, и шаблоны с одинаковым именем схлопываются
	var/list/mappaths = list()
	for(var/datum/map_template/ruin/space/ruin_type as anything in subtypesof(/datum/map_template/ruin/space))
		var/suffix = initial(ruin_type.suffix)
		if(suffix)
			mappaths["[initial(ruin_type.prefix)][suffix]"] = TRUE
	var/checked = 0
	for(var/mappath in mappaths)
		var/text = file2text(mappath)
		TEST_ASSERT(length(text), "[mappath]: карта руины не читается")
		checked++
		// у глобального regex позиция поиска переходит в следующий файл
		var/regex/turf_path = regex(@"^(/turf/[^,{)\s]+)", "gm")
		var/list/reported = list()
		while(turf_path.Find(text))
			var/path_text = turf_path.group[1]
			if(reported[path_text])
				continue
			var/turf/open/turf_type = text2path(path_text)
			if(!ispath(turf_type, /turf/open) || !initial(turf_type.planetary_atmos) || fixed_at_init[turf_type])
				continue
			reported[path_text] = TRUE
			TEST_FAIL("[mappath]: планетарный [path_text] - нужен непланетарный вариант")
	TEST_ASSERT(checked, "Ни одной карты космических руин")
