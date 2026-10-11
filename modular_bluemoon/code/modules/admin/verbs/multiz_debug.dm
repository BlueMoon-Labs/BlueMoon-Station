/// Отладочные кнопки мульти-Z: то, что юнит-тесты поймать не могут. Дампы пишутся в data/ файлом.

#define MULTIZ_DUMP_DIR "data/multiz_debug"

/client/proc/multiz_debug_panel()
	set category = "Debug.7) Testing"
	set name = "Multi-Z: панель"
	if(!check_rights(R_DEBUG))
		return

	var/static/list/actions = list(
		"Дамп плоскостей и мастеров",
		"Проверить проводку рендера",
		"Связка z-уровней подо мной",
		"Разбор объектов вокруг (почему чёрное)",
		"Аудит плоскостей всего этажа глаза",
		"Собрать стенд под ногами",
		"Прыгнуть на этаж выше",
		"Прыгнуть на этаж ниже",
	)
	var/choice = input(usr, "Что делаем?", "Multi-Z") as null|anything in actions
	switch(choice)
		if("Дамп плоскостей и мастеров")
			multiz_dump_planes()
		if("Проверить проводку рендера")
			multiz_audit_graph()
		if("Связка z-уровней подо мной")
			multiz_dump_stack()
		if("Разбор объектов вокруг (почему чёрное)")
			multiz_dump_atoms()
		if("Аудит плоскостей всего этажа глаза")
			multiz_audit_level_planes()
		if("Собрать стенд под ногами")
			multiz_build_testbed()
		if("Прыгнуть на этаж выше")
			multiz_step(UP)
		if("Прыгнуть на этаж ниже")
			multiz_step(DOWN)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Multi-Z Debug Panel")

/// Дамп плейн-мастеров: тип, номер плоскости, render_target, фильтры и коллизии номеров.
/client/proc/multiz_dump_planes()
	var/datum/hud/our_hud = mob?.hud_used
	if(!our_hud)
		to_chat(src, span_warning("Нет худа - смотреть нечего."))
		return

	var/list/lines = list()
	lines += "=== Plane masters, [key_name(src)], [time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")] ==="
	lines += "max_plane_offset: [SSmapping.max_plane_offset] (0 = плоскостной куб выключен)"
	lines += "мастеров в списке худа: [length(our_hud.plane_masters)]"
	lines += ""

	var/list/claims = list()
	for(var/atom/movable/screen/plane_master/master_type as anything in subtypesof(/atom/movable/screen/plane_master))
		var/plane_key = "[initial(master_type.plane)]"
		LAZYADD(claims[plane_key], "[master_type]")

	lines += "--- типы мастеров по номеру плоскости ---"
	for(var/plane_key in claims)
		var/list/claimants = claims[plane_key]
		var/marker = length(claimants) > 1 ? "COLLISION" : "ok"
		lines += "[plane_key]\t[marker]\t[claimants.Join(", ")]"

	lines += ""
	lines += "этаж глаза: [our_hud.current_plane_offset]"
	var/turf/our_turf = get_turf(mob)
	lines += "глубина своей связки: [our_turf ? GET_LOWEST_STACK_OFFSET(our_turf.z) : "нет турфа"]"

	if(our_turf)
		var/expected = GET_NEW_PLANE(initial(our_turf.plane), GET_Z_PLANE_OFFSET(our_turf.z))
		lines += "турф под ногами: [our_turf.type] z=[our_turf.z] plane=[our_turf.plane] (ожидается [expected])[our_turf.plane == expected ? "" : "  <-- РАСХОЖДЕНИЕ"]"
		lines += "мы сами: plane=[mob.plane] (ожидается [GET_NEW_PLANE(initial(mob.plane), GET_Z_PLANE_OFFSET(our_turf.z))])"
		var/list/plane_census = list()
		for(var/atom/movable/thing as anything in our_turf.contents)
			plane_census["[thing.plane]"] += 1
		var/list/census_out = list()
		for(var/plane_key in plane_census)
			census_out += "[plane_key]:[plane_census[plane_key]]"
		lines += "плоскости содержимого турфа: [length(census_out) ? census_out.Join(" ") : "пусто"]"
	lines += ""
	lines += "--- живые мастера на клиенте ---"
	lines += "плоскость\tэтаж\tскрыт\tтип\tblend\talpha\trender_target\tсдаёт в\tфильтры"
	for(var/plane_key in our_hud.plane_masters)
		var/atom/movable/screen/plane_master/master = our_hud.plane_masters[plane_key]
		if(!master)
			lines += "[plane_key]\t(пусто)"
			continue
		var/filter_names = master.filter_data ? jointext(master.filter_data, ",") : "-"
		var/list/relay_targets = list()
		for(var/atom/movable/screen/render_plane_relay/relay as anything in master.relays)
			relay_targets += "[relay.plane]"
		lines += "[plane_key]\t[master.offset]\t[master.force_hidden ? "ДА" : "нет"]\t[master.type]\tblend=[master.blend_mode]\talpha=[master.alpha]\trt=[master.render_target || "РИСУЕТСЯ САМ"]\t[length(relay_targets) ? relay_targets.Join(",") : "-"]\t[length(master.filters)] ([filter_names])"

	var/path = multiz_write_dump("planes", lines)
	to_chat(src, span_notice("Дамп плоскостей: [path]. Строки со словом COLLISION - это два мастера на одном номере."))

/// Сверяет проводку рендера на живом худе, пожившем раунд.
/client/proc/multiz_audit_graph()
	var/datum/hud/our_hud = mob?.hud_used
	if(!our_hud)
		to_chat(src, span_warning("Нет худа - проверять нечего."))
		return

	var/list/problems = our_hud.audit_render_graph()
	if(!length(problems))
		to_chat(src, span_notice("Проводка рендера сходится: [length(our_hud.master_groups)] стопок, обрывов нет."))
		return

	var/list/lines = list()
	lines += "=== Обрывы в проводке рендера, [key_name(src)], [time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")] ==="
	lines += "этаж глаза [our_hud.current_plane_offset], max_plane_offset [SSmapping.max_plane_offset]"
	lines += ""
	lines += problems

	var/path = multiz_write_dump("graph", lines)
	to_chat(src, span_warning("Обрывов: [length(problems)]. Дамп: [path]"))

/// Раскладка вертикальных связок: что с чем стыкуется и какое у уровня смещение.
/client/proc/multiz_dump_stack()
	var/turf/our_turf = get_turf(mob)
	if(!our_turf)
		to_chat(src, span_warning("Не понимаю, где вы стоите."))
		return

	var/list/lines = list()
	lines += "=== Z-связки, [time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")] ==="
	lines += "мы на z=[our_turf.z] ([SSmapping.level_trait(our_turf.z, ZTRAIT_STATION) ? "станция" : "не станция"])"
	lines += "max_plane_offset: [SSmapping.max_plane_offset]"
	lines += ""
	for(var/z in 1 to length(SSmapping.z_list))
		var/datum/space_level/level = SSmapping.z_list[z]
		var/list/stack = SSmapping.z_level_to_stack[z]
		var/transparent = level.traits[ZTRAIT_TRANSPARENT_SPACE] ? (SSmapping.z_level_below[z] ? "да" : "заказан, но снизу пусто") : "-"
		lines += "z=[z]\t[level.name]\tвверх=[level.traits[ZTRAIT_UP] || "-"]\tвниз=[level.traits[ZTRAIT_DOWN] || "-"]\tсмещение=[SSmapping.z_level_to_plane_offset[z]]\tпрозрачный космос=[transparent]\tсвязка=[stack ? stack.Join(",") : "-"]"

	var/path = multiz_write_dump("zstack", lines)
	to_chat(src, span_notice("Связки z-уровней: [path]"))
	to_chat(src, span_notice("Ваша связка снизу вверх: [SSmapping.get_connected_levels(our_turf.z).Join(" -> ")]"))

/// Плоскости атомов и их оверлеев вокруг: колонка "вердикт" отвечает, почему объект чёрный.
/client/proc/multiz_dump_atoms(radius = 1)
	var/turf/center = get_turf(mob)
	var/datum/hud/our_hud = mob?.hud_used
	if(!center || !our_hud)
		to_chat(src, span_warning("Нет турфа или худа - разбирать нечего."))
		return

	var/list/lines = list()
	lines += "=== Объекты вокруг, [key_name(src)], [time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")] ==="
	lines += "радиус [radius], этаж глаза [our_hud.current_plane_offset], max_plane_offset [SSmapping.max_plane_offset]"
	lines += ""

	for(var/turf/spot as anything in RANGE_TURFS(radius, center))
		var/offset = GET_Z_PLANE_OFFSET(spot.z)
		lines += "--- ([spot.x],[spot.y],[spot.z]) смещение=[offset] свет=[round(spot.get_lumcount(), 0.01)] ---"
		lines += multiz_describe_atom(our_hud, spot, offset)
		for(var/atom/movable/thing as anything in spot.contents)
			lines += multiz_describe_atom(our_hud, thing, offset)

	var/path = multiz_write_dump("atoms", lines)
	to_chat(src, span_notice("Разбор объектов: [path]. Ищите строки со словом ПЛОХО."))

/// Весь z-уровень глаза: какие типы сидят на чужом этаже и сколько их.
/client/proc/multiz_audit_level_planes()
	var/turf/center = get_turf(mob?.client?.eye || mob)
	if(!center)
		to_chat(src, span_warning("Нет турфа под глазом - проверять нечего."))
		return
	var/list/samples = list()
	var/list/by_type = audit_z_level_planes(center.z, samples)
	if(!length(by_type))
		to_chat(src, span_notice("z=[center.z]: все атомы на своём этаже."))
		return

	var/list/lines = list()
	lines += "=== Атомы на чужом этаже, z=[center.z], смещение [GET_Z_PLANE_OFFSET(center.z)], [key_name(src)], [time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")] ==="
	lines += ""
	for(var/type_key in by_type)
		lines += "[type_key]\t[by_type[type_key]]"
	lines += ""
	lines += "Примеры:"
	lines += samples

	var/path = multiz_write_dump("level_planes", lines)
	to_chat(src, span_warning("Типов на чужом этаже: [length(by_type)]. Дамп: [path]"))

/// Одна строка про атом плюс по строке на каждый его оверлей и подложку.
/client/proc/multiz_describe_atom(datum/hud/our_hud, atom/thing, offset)
	var/list/out = list()
	var/expected = GET_NEW_PLANE(PLANE_TO_TRUE(thing.plane), offset)
	out += "[thing.type]\tplane=[thing.plane]\tждём=[expected]\t[thing.plane == expected ? "ok" : "ПЛОХО: атом на чужом этаже"]"
	for(var/mutable_appearance/look as anything in thing.overlays)
		out += "\tоверлей\tplane=[look.plane]\t[multiz_plane_verdict(our_hud, look.plane)]"
	for(var/mutable_appearance/look as anything in thing.underlays)
		out += "\tподложка\tplane=[look.plane]\t[multiz_plane_verdict(our_hud, look.plane)]"
	return out

/// Есть ли у плоскости живой мастер. Без мастера содержимое рисуется как есть.
/client/proc/multiz_plane_verdict(datum/hud/our_hud, plane_number)
	if(plane_number == FLOAT_PLANE)
		return "ok (наследует носителя)"
	var/atom/movable/screen/plane_master/master = our_hud.plane_masters["[plane_number]"]
	if(!master)
		return "ПЛОХО: мастера на эту плоскость нет вообще"
	if(master.force_hidden)
		return "скрыт: реле сняты, содержимое до плиты не доходит"
	return "ok ([master.type])"

/// Стенд 5x5 под ногами со всеми случаями, которые надо посмотреть глазами.
/client/proc/multiz_build_testbed()
	var/turf/origin = get_turf(mob)
	if(!origin)
		return
	if(alert(usr, "Перестроить 5x5 турфов вокруг вас? Всё, что там стоит, будет снесено.", "Multi-Z стенд", "Строить", "Отмена") != "Строить")
		return

	var/turf/below = GET_TURF_BELOW(origin)
	if(!below)
		to_chat(src, span_warning("Снизу нет уровня: дыры схлопнутся обратно в пол. Для честной проверки нужна карта со связкой (multiz_debug или icemoonstation)."))

	var/list/built = list()
	for(var/turf/pad as anything in RANGE_TURFS(2, origin))
		pad.ChangeTurf(/turf/open/floor/plasteel, flags = CHANGETURF_INHERIT_AIR)
		for(var/atom/movable/junk as anything in pad.contents.Copy())
			if(junk == mob || ismob(junk))
				continue
			qdel(junk)
		built += pad

	var/turf/row_start = locate(origin.x - 2, origin.y + 2, origin.z)
	if(row_start)
		var/turf/hole = locate(row_start.x, row_start.y, row_start.z)
		hole?.ChangeTurf(/turf/open/openspace, flags = CHANGETURF_INHERIT_AIR)

		var/turf/latticed = locate(row_start.x + 1, row_start.y, row_start.z)
		if(latticed)
			latticed.ChangeTurf(/turf/open/openspace, flags = CHANGETURF_INHERIT_AIR)
			new /obj/structure/lattice(latticed)

		var/turf/catwalked = locate(row_start.x + 2, row_start.y, row_start.z)
		if(catwalked)
			catwalked.ChangeTurf(/turf/open/openspace, flags = CHANGETURF_INHERIT_AIR)
			new /obj/structure/lattice/catwalk(catwalked)

		var/turf/glassed = locate(row_start.x + 3, row_start.y, row_start.z)
		glassed?.ChangeTurf(/turf/open/floor/glass, flags = CHANGETURF_INHERIT_AIR)

	var/turf/stair_spot = locate(origin.x - 2, origin.y - 2, origin.z)
	if(stair_spot)
		new /obj/structure/stairs/north(stair_spot)

	var/turf/ladder_spot = locate(origin.x + 2, origin.y - 2, origin.z)
	if(ladder_spot)
		new /obj/structure/ladder(ladder_spot)
		var/turf/ladder_below = GET_TURF_BELOW(ladder_spot)
		if(ladder_below)
			ladder_below.ChangeTurf(/turf/open/floor/plasteel, flags = CHANGETURF_INHERIT_AIR)
			new /obj/structure/ladder(ladder_below)

	var/turf/drop_spot = locate(origin.x - 2, origin.y + 1, origin.z)
	if(drop_spot)
		new /obj/item/stack/sheet/metal(drop_spot, 10)
	var/turf/spawn_over_hole = locate(origin.x - 2, origin.y + 2, origin.z)
	if(spawn_over_hole)
		new /obj/item/stack/sheet/metal(spawn_over_hole, 5)

	message_admins("[key_name_admin(src)] собрал стенд мульти-Z на [ADMIN_VERBOSEJMP(origin)].")
	to_chat(src, span_notice("Стенд собран: [length(built)] турфов. Верхний ряд слева направо - дыра, решётка, катуок, стекло, пол."))
	to_chat(src, span_notice("Стак железа над дырой должен был упасть сам, ещё один лежит рядом с краем - столкните его."))

/// Шаг по вертикали через штатный API, а не телепортом; проверки полёта сняты сознательно.
/client/proc/multiz_step(direction)
	if(!mob)
		return
	if(mob.zMove(direction, null, ZMOVE_IGNORE_OBSTACLES|ZMOVE_FEEDBACK|ZMOVE_CHECK_PULLS|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED))
		to_chat(src, span_notice("Переместились [direction == UP ? "вверх" : "вниз"], теперь z=[mob.z]."))
		return
	to_chat(src, span_warning("Не вышло. Обычно это значит, что в той стороне нет уровня."))

/// Пишет дамп файлом и возвращает путь.
/client/proc/multiz_write_dump(name, list/lines)
	var/path = "[MULTIZ_DUMP_DIR]/[name]_[time2text(world.realtime, "YYYY-MM-DD_hh-mm-ss")].txt"
	var/text = lines.Join("\n")
	rustg_file_write(text, path)
	return path

#undef MULTIZ_DUMP_DIR
