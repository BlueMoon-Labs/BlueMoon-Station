/// Сверка проводки графа рендера: у каждого render_source есть производитель,
/// имена render_target не дублируются, реле целится в существующего мастера,
/// картинка каждого мастера доезжает до экранной плиты.

/// Сколько шагов по реле считаем заведомо ненормальным. Живая цепочка - три.
#define RENDER_GRAPH_MAX_HOPS 16

/// Проверяет одну стопку мастеров. Пустой список жалоб - всё сошлось.
/datum/plane_master_group/proc/audit_render_graph(viewer_offset)
	if(isnull(viewer_offset))
		viewer_offset = active_offset
	var/list/problems = list()
	var/list/produced_by = list()

	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/master = plane_masters[plane_key]
		if(!master)
			problems += "по ключу [plane_key] в стопке пусто"
			continue
		if("[master.plane]" != plane_key)
			problems += "[master.type] #[master.offset] лежит под ключом [plane_key], а его плоскость [master.plane] - искать его будут не там"
		if(!master.render_target)
			continue
		var/existing = produced_by[master.render_target]
		if(existing)
			problems += "картинку '[master.render_target]' производят двое: [existing] и [master.type] #[master.offset]"
			continue
		produced_by[master.render_target] = "[master.type] #[master.offset]"

	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/master = plane_masters[plane_key]
		if(!master)
			continue

		//Имя картинки несёт суффикс этажа: промах тут значит "фильтр смотрит на соседний этаж".
		for(var/filter_name in master.filter_data)
			var/list/params = master.filter_data[filter_name]
			var/wanted = params?["render_source"]
			if(!wanted || produced_by[wanted])
				continue
			problems += "фильтр '[filter_name]' у [master.type] #[master.offset] ищет картинку '[wanted]' - её никто не производит"

		for(var/atom/movable/screen/render_plane_relay/relay as anything in master.relays)
			if(relay.render_source && !produced_by[relay.render_source])
				problems += "релей [master.type] #[master.offset] ищет картинку '[relay.render_source]' - её никто не производит"
			if(!plane_masters["[relay.plane]"])
				problems += "релей [master.type] #[master.offset] кладёт картинку на плоскость [relay.plane], мастера на неё в стопке нет"

		//Этажи выше глаза содержимого не несут: их цепочка законно упирается в мастер-плиту без реле.
		if(master.offset < viewer_offset)
			continue
		if(master.force_hidden)
			continue
		if(!length(master.relays))
			//Маска со звёздочным таргетом не рисуется; остальное ниже экранной плиты закрыто картинкой мира.
			var/is_mask = master.render_target && copytext(master.render_target, 1, 2) == "*"
			if(!is_mask && PLANE_TO_TRUE(master.plane) < RENDER_PLANE_SCREEN)
				problems += "[master.type] #[master.offset] рисуется напрямую под экранной плитой: содержимое плоскости [master.plane] закрыто картинкой мира"
			continue
		if(!relay_reaches_screen(master))
			problems += "картинка [master.type] #[master.offset] никуда не доезжает: цепочка релеев не приводит к экранной плите"

	return problems

/// Обход помечает пройденные плоскости: кольцо в проводке иначе повесило бы проверку намертво.
/datum/plane_master_group/proc/relay_reaches_screen(atom/movable/screen/plane_master/start)
	var/list/seen = list()
	var/list/frontier = list(start)
	var/hops = 0
	while(length(frontier))
		if(++hops > RENDER_GRAPH_MAX_HOPS * length(plane_masters))
			return FALSE
		var/atom/movable/screen/plane_master/current = frontier[length(frontier)]
		frontier.len--
		if(seen["[current.plane]"])
			continue
		seen["[current.plane]"] = TRUE
		if(current.plane == RENDER_PLANE_SCREEN)
			return TRUE
		for(var/atom/movable/screen/render_plane_relay/relay as anything in current.relays)
			var/atom/movable/screen/plane_master/next_master = plane_masters["[relay.plane]"]
			if(next_master)
				frontier += next_master
	return FALSE

/// То же по всем стопкам худа сразу. Ключ стопки приписан к каждой жалобе.
/datum/hud/proc/audit_render_graph()
	var/list/problems = list()
	for(var/group_key in master_groups)
		var/datum/plane_master_group/group = master_groups[group_key]
		var/list/complaints = group.audit_render_graph()
		for(var/complaint in complaints)
			problems += "[group_key]: [complaint]"
	return problems

#undef RENDER_GRAPH_MAX_HOPS

/// Атомы z-уровня (и их оверлеи), чья плоскость лежит не на этаже уровня: ловит записи в plane в обход SET_PLANE_*.
/// Возвращает "тип" -> число ("тип overlay" для оверлеев), до max_samples примеров на тип кладёт в samples.
/proc/audit_z_level_planes(z, list/samples, max_samples = 5)
	var/list/by_type = list()
	var/offset = GET_Z_PLANE_OFFSET(z)
	for(var/turf/spot as anything in Z_TURFS(z))
		note_plane_mismatch(spot, offset, by_type, samples, max_samples)
		for(var/atom/movable/thing as anything in spot.contents)
			note_plane_mismatch(thing, offset, by_type, samples, max_samples)
		CHECK_TICK
	return by_type

/// Плоскость, на которой plane должен лежать на этаже offset. null для плоскостей без мастера (их смещать некуда, FLOAT_PLANE в том числе).
/proc/plane_expected_on_floor(plane, offset)
	if(isnull(SSmapping.plane_to_offset?["[plane]"]))
		return null
	return GET_NEW_PLANE(PLANE_TO_TRUE(plane), offset)

/proc/note_plane_mismatch(atom/thing, offset, list/by_type, list/samples, max_samples)
	var/expected = plane_expected_on_floor(thing.plane, offset)
	if(!isnull(expected) && thing.plane != expected)
		by_type["[thing.type]"] += 1
		if(samples && by_type["[thing.type]"] <= max_samples)
			samples += "[thing.type] в ([thing.x],[thing.y],[thing.z]): plane=[thing.plane], ждём [expected], area=[get_area(thing)], loc=[thing.loc?.type]"
	//Элемент overlays - appearance, а не mutable_appearance; plane через такую переменную читается.
	for(var/mutable_appearance/overlay as anything in thing.overlays)
		expected = plane_expected_on_floor(overlay.plane, offset)
		if(isnull(expected) || overlay.plane == expected)
			continue
		by_type["[thing.type] overlay"] += 1
		if(samples && by_type["[thing.type] overlay"] <= max_samples)
			samples += "оверлей [overlay.icon_state || overlay.icon] на [thing.type] в ([thing.x],[thing.y],[thing.z]): plane=[overlay.plane], ждём [expected], area=[get_area(thing)]"
