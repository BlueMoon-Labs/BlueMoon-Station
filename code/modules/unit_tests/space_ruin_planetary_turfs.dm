/// Планетарный турф в космической руине вечно тянет комнату к воздуху планеты и держит её активной в SSair.
/datum/unit_test/space_ruin_planetary_turfs

/datum/unit_test/space_ruin_planetary_turfs/Run()
	// Initialize сам снимает planetary_atmos вне Reebe
	var/static/list/fixed_at_init = typecacheof(/turf/open/floor/clockwork/reebe)
	var/checked = 0
	for(var/name in SSmapping.space_ruins_templates)
		var/datum/map_template/ruin/space/template = SSmapping.space_ruins_templates[name]
		var/text = file2text(template.mappath)
		if(!length(text))
			continue
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
			TEST_FAIL("[template.mappath]: планетарный [path_text] - нужен непланетарный вариант")
	TEST_ASSERT(checked, "Ни одна карта космических руин не прочиталась")
