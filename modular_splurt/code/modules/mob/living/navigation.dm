#define MAX_NAVIGATE_RANGE 125

/mob/living
	/// Cooldown of the navigate() verb.
	COOLDOWN_DECLARE(navigate_cooldown)
	/// Диалог выбора точки уже открыт. Ни картинок маршрута, ни кулдауна на этот
	/// момент ещё нет, так что без отдельного флага второе нажатие заводит вторую
	/// цепочку create_navigation() - и её RegisterSignal перебивает первую.
	var/navigate_choosing_destination = FALSE

/client
	/// Images of the path created by navigate().
	var/list/navigation_images = list()

/mob/living/verb/navigate()
	set name = "Navigate"
	set category = "IC"

	if(incapacitated())
		return
	if(navigate_choosing_destination)
		balloon_alert(src, "точка уже выбирается!")
		return
	if(length(client?.navigation_images))
		addtimer(CALLBACK(src, PROC_REF(cut_navigation)), world.tick_lag)
		balloon_alert(src, "маршрут убран")
		return
	if(!COOLDOWN_FINISHED(src, navigate_cooldown))
		balloon_alert(src, "навигация перезаряжается!")
		return
	addtimer(CALLBACK(src, PROC_REF(create_navigation)), world.tick_lag)

/mob/living/proc/create_navigation()
	//два нажатия в пределах одного world.tick_lag ставят два таймера разом: флаг
	//взводит первый из них, второй разворачиваем уже здесь
	if(navigate_choosing_destination)
		return
	var/list/destination_list = get_navigation_destinations()
	if(!length(destination_list))
		balloon_alert(src, "no navigation signals!")
		return

	navigate_choosing_destination = TRUE
	var/destination_id = tgui_input_list(src, "Select a location", "Navigate", sort_list(destination_list))
	navigate_choosing_destination = FALSE
	if(QDELETED(src))
		return
	var/navigate_target = destination_list[destination_id]

	if(isnull(navigate_target))
		return
	if(incapacitated())
		return
	COOLDOWN_START(src, navigate_cooldown, 15 SECONDS)

	var/vertical_dir = navigate_target == UP || navigate_target == DOWN ? navigate_target : navigation_vertical_dir(navigate_target)
	if(vertical_dir)
		COOLDOWN_START(src, navigate_cooldown, 5 SECONDS)
		var/new_target = find_nearest_stair_or_ladder(vertical_dir)
		if(!new_target)
			balloon_alert(src, vertical_dir == UP ? "нет лестницы наверх!" : "нет лестницы вниз!")
			return
		navigate_target = new_target

	if(!isatom(navigate_target))
		stack_trace("Navigate target ([navigate_target]) is not an atom, somehow.")
		return

	var/list/path = get_path_to(src, navigate_target, MAX_NAVIGATE_RANGE, mintargetdist = 1, id = get_idcard(), skip_first = FALSE)
	if(!length(path))
		balloon_alert(src, "no valid path with current access!")
		return
	//поиск пути тоже спит: картинки маршрута живут на клиенте, и рисовать их
	//разлогинившемуся уже некуда
	if(QDELETED(src) || !client)
		return
	//подчищаем остатки прошлого маршрута: после релога у моба новый клиент с пустым
	//navigation_images, а подписка на COMSIG_MOB_DEATH от прошлого раза ещё висит
	cut_navigation()
	path |= get_turf(navigate_target)
	for(var/i in 1 to length(path))
		var/turf/current_turf = path[i]
		var/image/path_image = image(icon = 'icons/obj/power_cond/cables.dmi', layer = SIGIL_LAYER, loc = current_turf)
		SET_PLANE_EXPLICIT(path_image, GAME_PLANE, current_turf)
		path_image.color = COLOR_CYAN
		path_image.alpha = 0
		var/dir_1 = 0
		var/dir_2 = 0
		if(i == 1)
			dir_2 = turn(angle2dir(Get_Angle(path[i+1], current_turf)), 180)
		else if(i == length(path))
			dir_2 = turn(angle2dir(Get_Angle(path[i-1], current_turf)), 180)
		else
			dir_1 = turn(angle2dir(Get_Angle(path[i+1], current_turf)), 180)
			dir_2 = turn(angle2dir(Get_Angle(path[i-1], current_turf)), 180)
			if(dir_1 > dir_2)
				dir_1 = dir_2
				dir_2 = turn(angle2dir(Get_Angle(path[i+1], current_turf)), 180)
		path_image.icon_state = "[dir_1]-[dir_2]"
		client.images += path_image
		client.navigation_images += path_image
		animate(path_image, 0.5 SECONDS, alpha = 150)
	addtimer(CALLBACK(src, PROC_REF(shine_navigation)), 0.5 SECONDS)
	RegisterSignal(src, COMSIG_MOB_DEATH, PROC_REF(cut_navigation))
	if(vertical_dir)
		RegisterSignal(src, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(cut_navigation))
	balloon_alert(src, vertical_dir ? "маршрут до лестницы" : "navigation path created")

/// Точки навигации со всей связки этажей по имени; у точек с других этажей в имени этаж.
/mob/living/proc/get_navigation_destinations()
	var/list/destination_list = list()
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return destination_list
	var/list/levels = SSmapping.get_connected_levels(our_turf)
	var/our_index = levels.Find(our_turf.z)
	for(var/turf/destination as anything in GLOB.navigate_destinations)
		var/destination_index = levels.Find(destination.z)
		if(!destination_index || max(abs(destination.x - our_turf.x), abs(destination.y - our_turf.y)) > MAX_NAVIGATE_RANGE)
			continue
		var/destination_name = GLOB.navigate_destinations[destination]
		if(destination_index != our_index)
			destination_name += destination_index > our_index ? " (выше)" : " (ниже)"
		destination_list[destination_name] = destination

	if(GET_TURF_BELOW(our_turf))
		destination_list["Nearest Way Down"] = DOWN
	if(GET_TURF_ABOVE(our_turf))
		destination_list["Nearest Way Up"] = UP
	return destination_list

/// UP или DOWN, если цель на другом этаже связки; NONE, если на нашем.
/mob/living/proc/navigation_vertical_dir(atom/target)
	var/turf/our_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!our_turf || !target_turf || our_turf.z == target_turf.z)
		return NONE
	var/list/levels = SSmapping.get_connected_levels(our_turf)
	return levels.Find(target_turf.z) > levels.Find(our_turf.z) ? UP : DOWN

/mob/living/proc/shine_navigation()
	if(!client)
		return
	for(var/i in 1 to length(client.navigation_images))
		if(!client || !length(client.navigation_images))
			return
		animate(client.navigation_images[i], time = 1 SECONDS, loop = -1, alpha = 200, color = "#bbffff", easing = BACK_EASING | EASE_OUT)
		animate(time = 2 SECONDS, loop = -1, alpha = 150, color = "#00ffff", easing = CUBIC_EASING | EASE_OUT)
		stoplag(0.1 SECONDS)

/mob/living/proc/cut_navigation()
	SIGNAL_HANDLER
	//подписку снимаем первой: у разлогиненного моба клиента нет, а падение на
	//client.navigation_images оставляло бы висеть обработчик COMSIG_MOB_DEATH
	UnregisterSignal(src, list(COMSIG_MOB_DEATH, COMSIG_MOVABLE_Z_CHANGED))
	if(!client)
		return
	for(var/image/navigation_path in client.navigation_images)
		client.images -= navigation_path
	client.navigation_images.Cut()

/**
 * Finds nearest ladder or staircase either up or down.
 *
 * Arguments:
 * * direction - UP or DOWN.
 */
/mob/living/proc/find_nearest_stair_or_ladder(direction)
	if(!direction)
		return
	if(direction != UP && direction != DOWN)
		return

	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return
	var/atom/target
	for(var/obj/structure/ladder/ladder as anything in GLOB.ladders)
		if(ladder.z != our_turf.z || !(direction == UP ? ladder.up : ladder.down))
			continue
		if(!target || get_dist_euclidian(ladder, src) < get_dist_euclidian(target, src))
			target = ladder

	for(var/obj/structure/stairs/stairs as anything in GLOB.stairs)
		var/turf/stairs_turf = get_turf(stairs)
		if(!stairs_turf)
			continue
		//вниз ведёт клетка над лестницей нижнего этажа
		var/atom/entrance = direction == UP ? stairs : GET_TURF_ABOVE(stairs_turf)
		if(entrance?.z != our_turf.z)
			continue
		if(!target || get_dist_euclidian(entrance, src) < get_dist_euclidian(target, src))
			target = entrance

	return target

#undef MAX_NAVIGATE_RANGE
