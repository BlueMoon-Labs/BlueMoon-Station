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
	var/list/destination_list = list()
	for(var/atom/destination in GLOB.navigate_destinations)
		if(!isatom(destination) || destination.z != z || get_dist(destination, src) > MAX_NAVIGATE_RANGE)
			continue
		var/destination_name = GLOB.navigate_destinations[destination]
		destination_list[destination_name] = destination

	if(!is_reserved_level(z)) //don't let us path to nearest staircase or ladder on shuttles in transit
		if(z > 1)
			destination_list["Nearest Way Down"] = DOWN
		if(z < world.maxz)
			destination_list["Nearest Way Up"] = UP

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

	if(navigate_target == UP || navigate_target == DOWN)
		var/new_target = find_nearest_stair_or_ladder(navigate_target)

		if(!new_target)
			balloon_alert(src, "can't find ladder or staircase going [navigate_target == UP ? "up" : "down"]!")
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
		var/image/path_image = image(icon = 'modular_splurt/icons/effects/navigation.dmi', layer = SIGIL_LAYER, loc = current_turf)
		path_image.plane = GAME_PLANE
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
	balloon_alert(src, "navigation path created")

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
	UnregisterSignal(src, COMSIG_MOB_DEATH)
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

	var/target
	for(var/obj/structure/ladder/lad in GLOB.ladders)
		if(lad.z != z)
			continue
		if(direction == UP && !lad.up)
			continue
		if(direction == DOWN && !lad.down)
			continue
		if(!target)
			target = lad
			continue
		if(get_dist_euclidian(lad, src) > get_dist_euclidian(target, src))
			continue
		target = lad

	for(var/obj/structure/stairs/stairs_bro in GLOB.stairs)
		if(direction == UP && stairs_bro.z != z) //if we're going up, we need to find stairs on our z level
			continue
		if(direction == DOWN && stairs_bro.z != z - 1) //if we're going down, we need to find stairs on the z level beneath us
			continue
		if(!target)
			target = stairs_bro.z == z ? stairs_bro : get_step_multiz(stairs_bro, UP) //if the stairs aren't on our z level, get the turf above them (on our zlevel) to path to instead
			continue
		if(get_dist_euclidian(stairs_bro, src) > get_dist_euclidian(target, src))
			continue
		target = stairs_bro.z == z ? stairs_bro : get_step_multiz(stairs_bro, UP)

	return target

#undef MAX_NAVIGATE_RANGE
