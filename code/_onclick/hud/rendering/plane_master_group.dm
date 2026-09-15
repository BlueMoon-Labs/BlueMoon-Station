/// Стопка plane master'ов одной карты: по набору мастеров на каждый этаж связки.
/datum/plane_master_group
	var/key
	var/datum/hud/our_hud
	/// "[plane]" -> мастер. Плоскости тут уже смещённые.
	var/list/atom/movable/screen/plane_master/plane_masters = list()
	var/active_offset = 0
	var/map = ""
	/// screen_loc реле: с CENTER BYOND смещает их неправильно.
	var/relay_loc = "1,1"
	/// Собирать ли картинку через плиты. Пустая BLEND_MULTIPLY-плоскость, отданная в плиту, красит её чёрным.
	var/use_render_plates = TRUE

	/// Самый глубокий построенный этаж.
	var/built_depth = -1

/datum/plane_master_group/New(key, map = "")
	. = ..()
	src.key = key
	src.map = map
	if(map)
		relay_loc = "[map]:[relay_loc]"
	build_plane_masters(0, initial_build_depth())

/datum/plane_master_group/proc/initial_build_depth()
	return SSmapping.max_plane_offset

/// Достроить этажи до depth и показать их владельцу, если стопка уже на экране.
/datum/plane_master_group/proc/ensure_depth(depth)
	depth = min(depth, SSmapping.max_plane_offset)
	if(depth <= built_depth)
		return
	var/list/before = plane_masters.Copy()
	build_plane_masters(built_depth + 1, depth)
	if(!our_hud)
		return
	for(var/plane_key in plane_masters)
		if(before[plane_key])
			continue
		var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
		plane.set_new_hud(our_hud)
		plane.show_to(our_hud.mymob)
	for(var/controller_key in our_hud.plane_master_controllers)
		var/atom/movable/plane_master_controller/controller = our_hud.plane_master_controllers[controller_key]
		controller.adopt_plane_masters()
	//Новые этажи родились с альфой по умолчанию, а владелец мог уже включить ночное зрение.
	our_hud.mymob?.sync_lighting_plane_alpha()

/datum/plane_master_group/Destroy()
	if(our_hud)
		hide_hud()
		our_hud.master_groups -= key
		our_hud = null
	QDEL_LIST_ASSOC_VAL(plane_masters)
	return ..()

/datum/plane_master_group/proc/attach_to(datum/hud/viewing_hud)
	if(viewing_hud.master_groups[key])
		stack_trace("Группа plane master'ов с ключом [key] уже есть на худе [viewing_hud.mymob]")
		return
	our_hud = viewing_hud
	our_hud.master_groups[key] = src
	//Без привязки к худу Destroy() мастера не снимает его с экрана клиента.
	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
		plane.set_new_hud(viewing_hud)
	show_hud()
	our_hud.eye_z_changed(force = TRUE)

/datum/plane_master_group/proc/refresh_hud()
	hide_hud()
	show_hud()
	our_hud?.eye_z_changed(force = TRUE)

/datum/plane_master_group/proc/hide_hud()
	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
		plane.hide_from(our_hud?.mymob)

/datum/plane_master_group/proc/show_hud()
	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
		plane.show_to(our_hud?.mymob)

/datum/plane_master_group/proc/get_plane(plane)
	return plane_masters["[plane]"]

/// Абстрактная плита без плоскости стала бы мастером на HUD_PLANE.
/datum/plane_master_group/proc/get_plane_types()
	return subtypesof(/atom/movable/screen/plane_master) - /atom/movable/screen/plane_master/rendering_plate

/datum/plane_master_group/proc/build_plane_masters(starting_offset, ending_offset)
	for(var/atom/movable/screen/plane_master/master_type as anything in get_plane_types())
		for(var/plane_offset in starting_offset to ending_offset)
			if(plane_offset != 0 && (initial(master_type.offsetting_flags) & BLOCKS_PLANE_OFFSETTING))
				continue
			var/atom/movable/screen/plane_master/instance = new master_type(null, our_hud, src, plane_offset)
			var/atom/movable/screen/plane_master/collision = plane_masters["[instance.plane]"]
			if(collision)
				stack_trace("Плоскость [instance.plane] заявлена дважды: [collision.type] и [instance.type]. Один из мастеров до клиента не доедет.")
				qdel(collision)
			plane_masters["[instance.plane]"] = instance
	built_depth = max(built_depth, ending_offset)

/// Видимость и масштаб этажей под положение глаза: выше глаза не рисуется, ниже сжимается.
/datum/plane_master_group/proc/build_planes_offset(new_offset, use_scale = TRUE)
	if(!SSmapping.max_plane_offset)
		return

	var/mob/our_mob = our_hud?.mymob
	if(!our_mob?.client?.prefs?.multiz_parallax)
		use_scale = FALSE
	var/depth_limit = our_mob?.client?.prefs?.multiz_performance
	if(isnull(depth_limit))
		depth_limit = MULTIZ_PERFORMANCE_DISABLE

	//Глубина связки глаза, не тела: камера ИИ может стоять в другой стопке.
	var/own_depth = our_hud ? our_hud.current_stack_depth : SSmapping.max_plane_offset
	apply_viewer_offset(new_offset, own_depth, depth_limit, use_scale ? MULTIZ_SCALE_PER_LEVEL : 1)

/datum/plane_master_group/proc/apply_viewer_offset(new_offset, own_depth, depth_limit, scale_by)
	active_offset = new_offset

	var/wanted_depth = own_depth
	if(depth_limit != MULTIZ_PERFORMANCE_DISABLE)
		wanted_depth = min(wanted_depth, new_offset + depth_limit)
	ensure_depth(wanted_depth)

	var/mob/our_mob = our_hud?.mymob
	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
		//До решения о скрытии: плита по этажу глаза выбирает, рисоваться или уехать наверх.
		plane.sync_to_viewer(new_offset)
		if(plane.offsetting_flags & BLOCKS_PLANE_OFFSETTING)
			continue

		var/visual_offset = plane.offset - new_offset

		//Прячем, а не гасим альфой: пустая BLEND_MULTIPLY-плоскость всё равно красит плиту.
		var/hidden = visual_offset < 0 || plane.offset > own_depth || (depth_limit != MULTIZ_PERFORMANCE_DISABLE && visual_offset > depth_limit)
		if(plane.mirrors_to_all_floors && !plane.offset)
			hidden = FALSE
		plane.set_hidden(hidden, our_mob)

		if(!plane.multiz_scaled || hidden)
			continue

		plane.multiz_scale = (visual_offset > 0 && scale_by != 1) ? (scale_by ** visual_offset) : 1
		//Без кэша: transform пишут и эффекты (Rotatium), а масштаб обязан пережить их.
		plane.transform = plane.compose_transform(matrix())

/// Основная стопка: этажи ниже глаза достраиваются по мере надобности.
/datum/plane_master_group/main

/datum/plane_master_group/main/initial_build_depth()
	return 0

/// Стопка вторичной карты: без худа, мастера регистрируются в клиенте напрямую, без масштаба.
/datum/plane_master_group/popup
	use_render_plates = FALSE
	var/list/client/registered_clients = list()

/datum/plane_master_group/popup/New(key, map = "")
	. = ..()
	RegisterSignal(SSmapping, COMSIG_PLANE_OFFSET_INCREASE, PROC_REF(on_plane_increase))

/datum/plane_master_group/popup/Destroy()
	for(var/client/target as anything in registered_clients.Copy())
		unregister_from_client(target)
	registered_clients = null
	return ..()

/datum/plane_master_group/popup/proc/on_plane_increase(datum/source, old_max_offset, new_max_offset)
	SIGNAL_HANDLER
	var/list/before = plane_masters.Copy()
	build_plane_masters(old_max_offset + 1, new_max_offset)
	for(var/client/target as anything in registered_clients)
		if(!target)
			continue
		for(var/plane_key in plane_masters)
			if(before[plane_key])
				continue
			var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
			target.register_map_obj(plane)
			for(var/atom/movable/screen/render_plane_relay/relay as anything in plane.relays)
				target.register_map_obj(relay)
	listclearnulls(registered_clients)

/datum/plane_master_group/popup/get_plane_types()
	return ..() - typesof(/atom/movable/screen/plane_master/rendering_plate)

/datum/plane_master_group/popup/build_planes_offset(new_offset, use_scale = TRUE)
	return

/// Отдать всю стопку клиенту вторичной карты. Релеи обязательны: без них плита
/// пустая, и карта будет чёрной.
/datum/plane_master_group/popup/proc/register_to_client(client/target)
	if(!target)
		return
	registered_clients |= target
	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
		target.register_map_obj(plane)
		for(var/atom/movable/screen/render_plane_relay/relay as anything in plane.relays)
			target.register_map_obj(relay)

/datum/plane_master_group/popup/proc/unregister_from_client(client/target)
	if(!target)
		return
	registered_clients -= target
	for(var/plane_key in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[plane_key]
		target.screen -= plane
		target.screen -= plane.relays
