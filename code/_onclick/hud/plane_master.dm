/*

	† † † † † † † † † † † † † † † † † † † † † † † † † † † † † †

	Отче наш, сущий на небесах!

	Да святится имя Твое;

	Да приидет Царствие Твое;

	да будет воля Твоя и на земле, как на небе;

	Хлеб наш насущный дай нам на сей день;

	И прости нам долги наши, как и мы прощаем должникам нашим;

	И не введи нас в искушение, но избавь нас от лукавого.

	Ибо Твое есть Царство и сила и слава вовеки. Аминь.

													Мф. 6:9-13.

	† † † † † † † † † † † † † † † † † † † † † † † † † † † † † †

*/

/atom/movable/screen/plane_master
	screen_loc = "CENTER"
	icon_state = "blank"
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_OVERLAY
	var/show_alpha = 255
	var/hide_alpha = 0

	var/datum/plane_master_group/home
	/// Этаж стопки: 0 - этаж глаза, дальше вниз.
	var/offset = 0
	/// Номер плоскости без смещения; смещённый лежит в plane.
	var/real_plane
	var/offsetting_flags = NONE
	var/multiz_scaled = TRUE
	/// Масштаб своего этажа. Эффекты, которым нужен transform, композируют его через compose_transform().
	var/multiz_scale = 1
	/// Раздаём картинку плоскостям остальных этажей; сам источник прятать нельзя.
	var/mirrors_to_all_floors = FALSE
	/// Пять фильтров плюс четыре бесконечные анимации на экземпляр, поэтому только этаж глаза.
	var/wants_world_distortion = FALSE
	var/world_distortion_applied = FALSE
	var/singularity_animated = FALSE
	/// Декоративные фильтры: их держит только этаж глаза, остальные этажи платят за них GPU даже скрытыми.
	var/list/eye_floor_filters
	/// Декоративные фильтры чужого этажа с параметрами, ждут прихода глаза.
	var/list/stashed_floor_filters
	var/is_eye_floor = TRUE
	/// Пересборку фильтров копим до конца пересчёта этажа: искажения и декор меняются на одной плоскости разом.
	var/filter_updates_deferred = FALSE
	var/filters_dirty = FALSE
	var/wants_vision_cone = FALSE

	/// В какие плоскости сдаём картинку. Пусто - рисуемся сами.
	var/list/render_relay_planes = list()
	var/list/atom/movable/screen/render_plane_relay/relays = list()
	var/force_hidden = FALSE

/// Стопку мастеров заводят и до того, как SSatoms дошёл до своей очереди: SecurEye создаётся в SSnetworks.
INITIALIZE_IMMEDIATE(/atom/movable/screen/plane_master)

/atom/movable/screen/plane_master/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	src.offset = offset
	real_plane = plane
	show_alpha = alpha
	if(home)
		src.home = home
		if(!home.use_render_plates)
			render_relay_planes = list()
		if(home.map)
			//Вторичная карта: мастер и его реле адресуются в свою подкарту интерфейса.
			screen_loc = "[home.map]:[screen_loc]"
			assigned_map = home.map
			del_on_map_removal = FALSE
	update_offset()
	generate_render_relays()
	//Искажения ставим только этажу глаза, дальше их двигает sync_to_viewer().
	if(wants_vision_cone)
		add_filter("vision_cone", 100, list(type = "alpha", render_source = OFFSET_RENDER_TARGET(FIELD_OF_VISION_RENDER_TARGET, offset), flags = MASK_INVERSE))
	if(wants_world_distortion && !offset)
		world_distortion_applied = TRUE
		apply_world_distortion()

/// Уводит мастера на плоскости своего этажа. Render target получает суффикс этажа, иначе фильтры читают чужую картинку.
/atom/movable/screen/plane_master/proc/update_offset()
	name = "[initial(name)] #[offset]"
	SET_PLANE_W_SCALAR(src, real_plane, offset)
	for(var/i in 1 to length(render_relay_planes))
		render_relay_planes[i] = GET_NEW_PLANE(render_relay_planes[i], offset)
	if(initial(render_target))
		render_target = OFFSET_RENDER_TARGET(initial(render_target), offset)

/// Альфа ставится мастеру, даже когда он сдаёт картинку в плиту: нулевая альфа у плиты с BLEND_MULTIPLY значит "не действует".
/atom/movable/screen/plane_master/proc/set_alpha(new_alpha)
	show_alpha = new_alpha
	alpha = new_alpha

/// Глаз переехал на другой этаж стопки: база двигает искажения мира на этаж глаза.
/atom/movable/screen/plane_master/proc/sync_to_viewer(viewer_offset)
	SHOULD_CALL_PARENT(TRUE)
	if(!wants_world_distortion)
		return
	var/should_distort = (offset == viewer_offset)
	if(should_distort == world_distortion_applied)
		return
	world_distortion_applied = should_distort
	if(should_distort)
		apply_world_distortion()
		return
	clear_world_distortion()

/// Матрица эффекта поверх сжатия этажа: голый transform стёр бы масштаб нижних этажей.
/atom/movable/screen/plane_master/proc/compose_transform(matrix/effect)
	var/matrix/result = matrix(effect)
	if(multiz_scale != 1)
		result.Scale(multiz_scale)
	return result

/atom/movable/screen/plane_master/proc/Show(override)
	alpha = override || show_alpha

/atom/movable/screen/plane_master/proc/Hide(override)
	alpha = override || hide_alpha

//Why do plane masters need a backdrop sometimes? Read https://secure.byond.com/forum/?post=2141928
//Trust me, you need one. Period. If you don't think you do, you're doing something extremely wrong.
/atom/movable/screen/plane_master/proc/backdrop(mob/mymob)

/// backdrop() переставляет фильтры по одному, а каждая правка пересобирает весь список: собираем один раз в конце.
/atom/movable/screen/plane_master/proc/refresh_backdrop(mob/mymob)
	var/was_deferred = filter_updates_deferred
	filter_updates_deferred = TRUE
	backdrop(mymob)
	filter_updates_deferred = was_deferred
	if(was_deferred || !filters_dirty)
		return
	filters_dirty = FALSE
	update_filters()

/// prefs зрителя: клиент получает их не сразу после входа.
/atom/movable/screen/plane_master/proc/viewer_prefs(mob/viewer)
	if(!istype(viewer))
		return null
	var/datum/client_interface/viewer_client = GET_CLIENT(viewer)
	return viewer_client?.prefs

/atom/movable/screen/plane_master/Destroy()
	stop_singularity_filters()
	if(home)
		home.plane_masters -= "[plane]"
		home = null
	QDEL_LIST(relays)
	return ..()

/// Скрытый этаж теряет только свои реле: сам мастер остаётся на экране и по-прежнему
/// собирает всё, что лежит на его плоскости (подложки, зеркала параллакса, чужие реле).
/// Снятый с экрана мастер оставил бы это рисоваться сырым под плитой. Альфой гасить нельзя:
/// пустая плоскость с BLEND_MULTIPLY всё равно складывается в плиту и красит её подложку.
/atom/movable/screen/plane_master/proc/set_hidden(should_hide, mob/viewer)
	if(force_hidden == should_hide)
		return
	force_hidden = should_hide
	var/client/our_client = viewer?.client
	if(!our_client)
		return
	if(should_hide)
		our_client.screen -= relays
		return
	our_client.screen += relays

/atom/movable/screen/plane_master/proc/show_to(mob/mymob)
	SHOULD_CALL_PARENT(TRUE)
	var/client/our_client = mymob?.client
	if(!our_client)
		return TRUE
	refresh_backdrop(mymob)
	our_client.screen += src
	if(!force_hidden)
		our_client.screen += relays
	return TRUE

/atom/movable/screen/plane_master/proc/hide_from(mob/oldmob)
	SHOULD_CALL_PARENT(TRUE)
	var/client/their_client = oldmob?.client
	if(!their_client)
		return
	their_client.screen -= src
	their_client.screen -= relays

/// Реле - экранный объект с render_source нашего render_target: кладёт нашу картинку на чужую плоскость.
/atom/movable/screen/plane_master/proc/generate_render_relays()
	if(!length(render_relay_planes))
		return
	var/list/existing = list()
	for(var/atom/movable/screen/render_plane_relay/relay as anything in relays)
		existing += relay.plane
	for(var/relay_plane in (render_relay_planes - existing))
		generate_relay_to(relay_plane)
	//Режим наложения сдающего мастера уехал в реле; сам он с *-таргетом не рисуется.
	if(blend_mode != BLEND_MULTIPLY)
		blend_mode = BLEND_DEFAULT

/proc/get_plane_master_render_base(name)
	return "*[name]: AUTOGENERATED RENDER TGT"

/atom/movable/screen/plane_master/proc/generate_relay_to(target_plane, blend_override, relay_layer)
	if(!length(relays) && !initial(render_target))
		render_target = OFFSET_RENDER_TARGET(get_plane_master_render_base(initial(name)), offset)

	var/blend_to_use = blend_override
	if(isnull(blend_to_use))
		blend_to_use = initial(blend_mode)

	var/atom/movable/screen/render_plane_relay/relay = new()
	relay.render_source = render_target
	relay.plane = target_plane
	relay.screen_loc = home?.relay_loc || "1,1"
	//Без assigned_map реле на вторичной карте отвергает client.register_map_obj().
	if(home?.map)
		relay.assigned_map = home.map
	//Слой обязан быть положительным: отрицательные BYOND считает float-слоями.
	relay.layer = relay_layer || (plane + PLANE_RANGE * (MAX_SUPPORTED_Z_DEPTH + 1))
	relay.blend_mode = blend_to_use
	relay.mouse_opacity = mouse_opacity
	relay.name = render_target
	relays += relay
	var/client/watcher = force_hidden ? null : home?.our_hud?.mymob?.client
	if(watcher)
		watcher.screen += relay
	return relay

/atom/movable/screen/plane_master/proc/add_relay_to(target_plane, blend_override, relay_layer)
	if(get_relay_to(target_plane))
		return
	generate_relay_to(target_plane, blend_override, relay_layer)

/atom/movable/screen/plane_master/proc/remove_relay_from(target_plane)
	var/atom/movable/screen/render_plane_relay/existing = get_relay_to(target_plane)
	if(!existing)
		return
	relays -= existing
	var/client/watcher = home?.our_hud?.mymob?.client
	if(watcher)
		watcher.screen -= existing
	qdel(existing)
	if(!length(relays) && !initial(render_target))
		render_target = null

/atom/movable/screen/plane_master/proc/get_relay_to(target_plane)
	for(var/atom/movable/screen/render_plane_relay/relay as anything in relays)
		if(relay.plane == target_plane)
			return relay
	return null

/atom/movable/screen/plane_master/openspace
	name = "open space plane master"
	plane = OPENSPACE_PLANE
	appearance_flags = PLANE_MASTER
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	wants_world_distortion = TRUE
	wants_vision_cone = TRUE

/// Искажения мира: гравитационный импульс и четыре ступени сингулярности.
/atom/movable/screen/plane_master/proc/apply_world_distortion()
	queue_filter("displacer", 1, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(GRAVITY_PULSE_RENDER_TARGET, offset), size = 10))

	queue_filter("singularity_0", 1, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_0_RENDER_TARGET, offset), size = -20))
	queue_filter("singularity_1", 2, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_1_RENDER_TARGET, offset), size = 75))
	queue_filter("singularity_2", 3, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_2_RENDER_TARGET, offset), size = 400))
	queue_filter("singularity_3", 4, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_3_RENDER_TARGET, offset), size = 700))
	update_filters()

/// Фильтр без пересборки списка: несколько подряд собираются одним update_filters().
/atom/movable/screen/plane_master/proc/queue_filter(name, priority, list/params)
	var/list/entry = params.Copy()
	entry["priority"] = priority
	LAZYSET(filter_data, name, entry)

/// Пересобранные фильтры приходят без анимации, линзу сингулярности заводим заново.
/atom/movable/screen/plane_master/update_filters()
	if(filter_updates_deferred)
		filters_dirty = TRUE
		return
	stop_singularity_filters()
	. = ..()
	if(world_distortion_applied)
		animate_singularity_filters()

/// Глаз сменил этаж: искажения и декор встают на плоскость одной пересборкой фильтров.
/atom/movable/screen/plane_master/proc/sync_to_eye_floor(viewer_offset)
	filter_updates_deferred = TRUE
	sync_to_viewer(viewer_offset)
	set_eye_floor(offset == viewer_offset)
	filter_updates_deferred = FALSE
	if(!filters_dirty)
		return
	filters_dirty = FALSE
	update_filters()

/atom/movable/screen/plane_master/add_filter(name, priority, list/params)
	if(is_eye_floor || !(name in eye_floor_filters))
		return ..()
	var/list/entry = params.Copy()
	entry["priority"] = priority
	LAZYSET(stashed_floor_filters, name, entry)

/atom/movable/screen/plane_master/remove_filter(name_or_names)
	if(stashed_floor_filters)
		stashed_floor_filters -= name_or_names
		UNSETEMPTY(stashed_floor_filters)
	return ..()

/// Этаж глаза забирает отложенные декоративные фильтры, остальные этажи отдают их в запас.
/atom/movable/screen/plane_master/proc/set_eye_floor(eye_floor)
	if(is_eye_floor == eye_floor)
		return
	is_eye_floor = eye_floor
	if(!length(eye_floor_filters))
		return
	var/changed = FALSE
	if(eye_floor)
		for(var/name in stashed_floor_filters)
			LAZYSET(filter_data, name, stashed_floor_filters[name])
			changed = TRUE
		stashed_floor_filters = null
	else
		for(var/name in eye_floor_filters)
			var/list/entry = LAZYACCESS(filter_data, name)
			if(!entry)
				continue
			LAZYSET(stashed_floor_filters, name, entry)
			filter_data -= name
			changed = TRUE
	if(changed)
		update_filters()

/atom/movable/screen/plane_master/proc/animate_singularity_filters()
	singularity_animated = TRUE
	animate(get_filter("singularity_0"), size = -20, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = -30, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_1"), size = 50, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 100, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_2"), size = 400, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 300, time = 10, easing = LINEAR_EASING, loop = -1)

	animate(get_filter("singularity_3"), size = 750, time = 10, easing = LINEAR_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(size = 600, time = 10, easing = LINEAR_EASING, loop = -1)

/atom/movable/screen/plane_master/proc/clear_world_distortion()
	stop_singularity_filters()
	remove_filter(list("displacer", "singularity_0", "singularity_1", "singularity_2", "singularity_3"))

/// Цикл переживает удаление фильтра и пересборку списка и копится на мастере, поэтому гасим его до них.
/atom/movable/screen/plane_master/proc/stop_singularity_filters()
	if(!singularity_animated)
		return
	singularity_animated = FALSE
	for(var/filter_name in GLOB.singularity_filter_names)
		var/existing = get_filter(filter_name)
		if(existing)
			animate(existing)

GLOBAL_LIST_INIT(singularity_filter_names, list("singularity_0", "singularity_1", "singularity_2", "singularity_3"))

/atom/movable/screen/plane_master/proc/apply_ambient_occlusion(mob/mymob, strength, color)
	if(!mymob?.client?.prefs?.ambientocclusion)
		remove_filter("ambient_occlusion")
		return
	var/blur_lvl = mymob.client.prefs.lighting_blur || 0
	add_filter("ambient_occlusion", 0, AMBIENT_OCCLUSION_SCALED(strength, color, blur_lvl))

/atom/movable/screen/plane_master/proc/outline(_size, _color)
	filters += filter(type = "outline", size = _size, color = _color)

/atom/movable/screen/plane_master/proc/shadow(_size, _offset = 0, _x = 0, _y = 0, _color = "#04080FAA")
	filters += filter(type = "drop_shadow", x = _x, y = _y, color = _color, size = _size, offset = _offset)

///Contains just the floor
/atom/movable/screen/plane_master/floor
	name = "floor plane master"
	plane = FLOOR_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	wants_world_distortion = TRUE
	eye_floor_filters = list("ambient_occlusion")

/atom/movable/screen/plane_master/floor/backdrop(mob/mymob)
	apply_ambient_occlusion(mymob, 2, "#04080F32")

/atom/movable/screen/plane_master/wall
	name = "wall plane master"
	plane = WALL_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	wants_world_distortion = TRUE
	wants_vision_cone = TRUE
	eye_floor_filters = list("ambient_occlusion")

/atom/movable/screen/plane_master/wall/backdrop(mob/mymob)
	apply_ambient_occlusion(mymob, 4, "#04080FAA")

/atom/movable/screen/plane_master/above_wall
	name = "above wall plane master"
	plane = ABOVE_WALL_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	wants_world_distortion = TRUE
	wants_vision_cone = TRUE
	eye_floor_filters = list("ambient_occlusion")

/atom/movable/screen/plane_master/above_wall/backdrop(mob/mymob)
	apply_ambient_occlusion(mymob, 3, "#04080F64")

///Contains most things in the game world
/atom/movable/screen/plane_master/game_world
	name = "game world plane master"
	plane = GAME_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER //should use client color
	blend_mode = BLEND_OVERLAY
	render_target = GAME_PLANE_RENDER_TARGET
	wants_world_distortion = TRUE
	wants_vision_cone = TRUE
	eye_floor_filters = list("ambient_occlusion")

/atom/movable/screen/plane_master/game_world/update_offset()
	. = ..()
	if(home?.use_render_plates)
		render_target = "*[render_target]"

/atom/movable/screen/plane_master/game_world/backdrop(mob/mymob)
	apply_ambient_occlusion(mymob, 4, "#04080FAA")

///Contains all shadow cone masks, whose image overrides are displayed only to their respective owners.
/atom/movable/screen/plane_master/field_of_vision
	name = "field of vision mask plane master"
	plane = FIELD_OF_VISION_PLANE
	render_target = FIELD_OF_VISION_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_planes = list()
	/// Конус один на всю стопку: картинки компонента лежат на несмещённых плоскостях, а фильтры всех этажей читают этот же таргет.
	offsetting_flags = BLOCKS_PLANE_OFFSETTING

/atom/movable/screen/plane_master/field_of_vision/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	filters += filter(type="alpha", render_source=OFFSET_RENDER_TARGET(FIELD_OF_VISION_BLOCKER_RENDER_TARGET, offset), flags=MASK_INVERSE)

///Used to display the owner and its adjacent surroundings through the FoV plane mask.
/atom/movable/screen/plane_master/field_of_vision_blocker
	name = "field of vision blocker plane master"
	plane = FIELD_OF_VISION_BLOCKER_PLANE
	render_target = FIELD_OF_VISION_BLOCKER_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_planes = list()
	offsetting_flags = BLOCKS_PLANE_OFFSETTING

///Stores the visible portion of the FoV shadow cone.
/atom/movable/screen/plane_master/field_of_vision_visual
	name = "field of vision visual plane master"
	plane = FIELD_OF_VISION_VISUAL_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	offsetting_flags = BLOCKS_PLANE_OFFSETTING

/atom/movable/screen/plane_master/field_of_vision_visual/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	filters += filter(type="alpha", render_source=OFFSET_RENDER_TARGET(FIELD_OF_VISION_BLOCKER_RENDER_TARGET, offset), flags=MASK_INVERSE)

/// Тень конуса едет на плиту этажа глаза: плита нулевого этажа спрятана, пока глаз ниже.
/atom/movable/screen/plane_master/field_of_vision_visual/sync_to_viewer(viewer_offset)
	. = ..()
	var/wanted_plane = GET_NEW_PLANE(RENDER_PLANE_GAME_WORLD, viewer_offset)
	var/list/stale_planes = list()
	for(var/atom/movable/screen/render_plane_relay/relay as anything in relays)
		if(relay.plane != wanted_plane)
			stale_planes += relay.plane
	for(var/stale_plane in stale_planes)
		remove_relay_from(stale_plane)
	add_relay_to(wanted_plane)

///Contains all lighting objects
/atom/movable/screen/plane_master/lighting
	name = "lighting plane master"
	plane = LIGHTING_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	wants_world_distortion = TRUE
	eye_floor_filters = list("lighting_blur", "lighting_blur_edge_fix")
	/// update_sight() переставляет порог на каждом шаге, а пересборка фильтров дорогая.
	var/applied_cutoff_key

/atom/movable/screen/plane_master/lighting/backdrop(mob/mymob)
	if(!mymob)
		return
	//Подложки - экраны основной карты: попапу их не вешаем, а фильтры нужны каждому его этажу.
	if(!home?.map)
		//Только этажи своей связки: у чужих показанного мастера нет вовсе.
		if(offset > (home?.our_hud?.current_stack_depth || 0))
			return
		//Подложка своя у каждого этажа и лежит на его плоскости: BLEND_MULTIPLY по пустоте даёт чёрный.
		var/atom/movable/screen/backdrop = mymob.overlay_fullscreen("lighting_backdrop_lit_[offset]", /atom/movable/screen/fullscreen/special/lighting_backdrop/lit)
		SET_PLANE_W_SCALAR(backdrop, LIGHTING_PLANE, offset)
		backdrop = mymob.overlay_fullscreen("lighting_backdrop_unlit_[offset]", /atom/movable/screen/fullscreen/special/lighting_backdrop/unlit)
		SET_PLANE_W_SCALAR(backdrop, LIGHTING_PLANE, offset)
	var/datum/preferences/prefs = viewer_prefs(mymob)
	var/is_fast = (prefs?.lighting_quality == LIGHTING_QUALITY_FAST)
	if(is_fast)
		remove_filter("lighting_blur")
		remove_filter("lighting_blur_edge_fix")
	else
		var/blur_level = prefs?.lighting_blur || 0
		var/effective_blur = LIGHTING_BLUR_BASE + blur_level * LIGHTING_BLUR_MULTIPLIER
		if(effective_blur > 0)
			add_filter("lighting_blur", 0, list("type" = "blur", "size" = effective_blur))
			//Размытие оставляет у края экрана полупрозрачный свет, и BLEND_MULTIPLY там недотемняет.
			//Альфу насыщаем, а не ставим в 1: у попапа нет подложки, и пустой этаж иначе зачернил бы этажи под собой.
			add_filter("lighting_blur_edge_fix", 1, color_matrix_filter(list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,LIGHTING_BLUR_EDGE_ALPHA_GAIN, 0,0,0,0)))
		else
			remove_filter("lighting_blur")
			remove_filter("lighting_blur_edge_fix")
	remove_filter("user_brightness")
	if(is_fast)
		// В режиме Быстро - стандартное освещение до LightUp, без пользовательской яркости
		return
	var/brightness = prefs?.lighting_brightness
	if(isnull(brightness))
		brightness = LIGHTING_BRIGHTNESS_DEFAULT
	brightness = clamp(brightness, LIGHTING_BRIGHTNESS_MIN, LIGHTING_BRIGHTNESS_MAX)
	// Диапазон 0-60 растянут на 0-100: 0 = старая 0, 100 = старая 60
	var/mapped = brightness * 0.6
	var/ratio = (mapped - LIGHTING_BRIGHTNESS_DEFAULT) / 200
	if(ratio != 0)
		add_filter("user_brightness", 5, color_matrix_filter(list(
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			0,0,0,1,
			ratio, ratio, ratio, 0
		)))

/// Прячем этаж - забираем и его подложки: без видимого мастера белый lit-квадрат рисуется сырым.
/atom/movable/screen/plane_master/lighting/hide_from(mob/oldmob)
	. = ..()
	if(!oldmob)
		return
	oldmob.clear_fullscreen("lighting_backdrop_lit_[offset]", 0)
	oldmob.clear_fullscreen("lighting_backdrop_unlit_[offset]", 0)

/*!
 * This system works by exploiting BYONDs color matrix filter to use layers to handle emissive blockers.
 *
 * Emissive overlays are pasted with an atom color that converts them to be entirely some specific color.
 * Emissive blockers are pasted with an atom color that converts them to be entirely some different color.
 * Emissive overlays and emissive blockers are put onto the same plane.
 * The layers for the emissive overlays and emissive blockers cause them to mask eachother similar to normal BYOND objects.
 * A color matrix filter is applied to the emissive plane to mask out anything that isn't whatever the emissive color is.
 * This is then used to alpha mask the lighting plane.
 */

/atom/movable/screen/plane_master/lighting/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	add_filter("emissives", 2, alpha_mask_filter(render_source = OFFSET_RENDER_TARGET(EMISSIVE_RENDER_TARGET, offset), flags = MASK_INVERSE))
	apply_light_cutoff(0)
	if(!home?.use_render_plates)
		add_filter("object_lighting", 3, alpha_mask_filter(render_source = OFFSET_RENDER_TARGET(O_LIGHTING_VISUAL_RENDER_TARGET, offset), flags = MASK_INVERSE))

/// Маски эмиссива и оверлейного света ложатся раньше искажений, иначе линза сингулярности размажет вырезанные ими дырки.
/atom/movable/screen/plane_master/lighting/apply_world_distortion()
	queue_filter("singularity_0", 4, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_0_RENDER_TARGET, offset), size = -20))
	queue_filter("singularity_1", 4, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_1_RENDER_TARGET, offset), size = 75))
	queue_filter("singularity_2", 4, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_2_RENDER_TARGET, offset), size = 400))
	queue_filter("singularity_3", 4, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(SINGULARITY_3_RENDER_TARGET, offset), size = 700))

	queue_filter("displacer", 5, displacement_map_filter(render_source = OFFSET_RENDER_TARGET(GRAVITY_PULSE_RENDER_TARGET, offset), size = 10))
	update_filters()

/atom/movable/screen/plane_master/lighting/proc/apply_light_cutoff(cutoff, list/color_cutoffs)
	var/cutoff_key = "[cutoff]|[islist(color_cutoffs) ? jointext(color_cutoffs, ",") : "-"]"
	if(cutoff_key == applied_cutoff_key)
		return
	applied_cutoff_key = cutoff_key
	if(!cutoff && !color_cutoffs)
		remove_filter("light_cutoff")
		return
	var/ratio = cutoff / 100
	var/list/rgb_add = list(ratio, ratio, ratio)
	if(length(color_cutoffs) == 3)
		rgb_add[1] += color_cutoffs[1] / 100
		rgb_add[2] += color_cutoffs[2] / 100
		rgb_add[3] += color_cutoffs[3] / 100
	add_filter("light_cutoff", 6, color_matrix_filter(list(
		1,0,0,0,
		0,1,0,0,
		0,0,1,0,
		0,0,0,1,
		rgb_add[1], rgb_add[2], rgb_add[3], 0
	)))

///Оверлейный свет (/datum/component/overlay_lighting): BLEND_ADD-маски источников этажа.
///Альфа масок высветляет тьму, цвет тонирует картинку умножением. В плитах оба шага делают реле в освещение своего этажа,
///без плит - фильтр "object_lighting" плоскости освещения и сама плоскость.
/atom/movable/screen/plane_master/o_light_visual
	name = "overlight light visual plane master"
	plane = O_LIGHTING_VISUAL_PLANE
	render_target = O_LIGHTING_VISUAL_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_planes = list(LIGHTING_PLANE)
	blend_mode = BLEND_MULTIPLY
	/// Масштаб этажа даёт плоскость освещения, в которую уходят реле.
	multiz_scaled = FALSE

/atom/movable/screen/plane_master/o_light_visual/update_offset()
	. = ..()
	if(home?.use_render_plates)
		render_target = "*[render_target]"

/atom/movable/screen/plane_master/o_light_visual/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	var/atom/movable/screen/render_plane_relay/tint = get_relay_to(GET_NEW_PLANE(LIGHTING_PLANE, offset))
	if(!tint)
		return
	//Высветление обязано лечь до умножения на цвет, поэтому слой реле ниже.
	var/atom/movable/screen/render_plane_relay/brighten = generate_relay_to(tint.plane, BLEND_OVERLAY, tint.layer - 1)
	brighten.color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 1,1,1,0)

/**
 * Handles emissive overlays and emissive blockers.
 */
/atom/movable/screen/plane_master/emissive
	name = "emissive plane master"
	plane = EMISSIVE_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = EMISSIVE_RENDER_TARGET
	render_relay_planes = list()
	eye_floor_filters = list("emissive_bloom")

/atom/movable/screen/plane_master/emissive/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	add_filter("em_block_masking", 1, color_matrix_filter(GLOB.em_mask_matrix))
	// emissive_bloom added conditionally in backdrop() based on blur quality setting

/atom/movable/screen/plane_master/emissive/backdrop(mob/mymob)
	if(mymob?.client?.prefs?.lighting_quality == LIGHTING_QUALITY_FAST)
		remove_filter("emissive_bloom")
		return
	var/blur_level = mymob?.client?.prefs?.lighting_blur || 0
	var/bloom_intensity = mymob?.client?.prefs?.lighting_bloom_intensity
	if(isnull(bloom_intensity))
		bloom_intensity = LIGHTING_BLOOM_INTENSITY_DEFAULT
	if(bloom_intensity <= 0)
		remove_filter("emissive_bloom")
		return
	if(blur_level >= 2)
		// Bloom on emissive - intensity 0-200, 100 = старый максимум (текущие 100 -> 50)
		var/bloom_alpha = clamp(30 + bloom_intensity * 0.32, 20, 85)
		var/bloom_size = max(1, round(blur_level * (0.6 + bloom_intensity / 100 * 0.6)))
		add_filter("emissive_bloom", 2, bloom_filter(threshold = COLOR_BLACK, size = bloom_size, offset = 1, alpha = bloom_alpha))
	else
		remove_filter("emissive_bloom")

/atom/movable/screen/plane_master/lamps
	name = "lamps plane master"
	plane = LIGHTING_LAMPS_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = LIGHTING_LAMPS_RENDER_TARGET

// Свечение ламп не должно просвечивать сквозь мобов/объекты: гасим его там, где непрозрачен
// игровой план. Фильтр один на весь тип, поэтому и обычные, и floor-варианты (/floor вызывают
// ..()) получают его бесплатно.
/atom/movable/screen/plane_master/lamps/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	add_filter("lamps_game_mask", 1, alpha_mask_filter(render_source = "[home?.use_render_plates ? "*" : ""][OFFSET_RENDER_TARGET(GAME_PLANE_RENDER_TARGET, offset)]", flags = MASK_INVERSE))

/atom/movable/screen/plane_master/lamps/backdrop(mob/mymob)
	remove_filter("user_brightness")
	if(mymob?.client?.prefs?.lighting_quality == LIGHTING_QUALITY_FAST)
		return
	var/brightness = mymob?.client?.prefs?.lighting_lamp_brightness
	if(isnull(brightness))
		brightness = LIGHTING_LAMP_BRIGHTNESS_DEFAULT
	brightness = clamp(brightness, LIGHTING_LAMP_BRIGHTNESS_MIN, LIGHTING_LAMP_BRIGHTNESS_MAX)
	// Диапазон ламп 60-100 растянут на 0-100, нормализовано: макс +0.25
	var/mapped = 60 + brightness * 0.4
	var/ratio = (mapped - LIGHTING_LAMP_BRIGHTNESS_DEFAULT) / 200
	if(ratio != 0)
		add_filter("user_brightness", 5, color_matrix_filter(list(
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			0,0,0,1,
			ratio, ratio, ratio, 0
		)))

/atom/movable/screen/plane_master/lamps/floor
	name = "floor lamps plane master"
	plane = FLOOR_LIGHTING_LAMPS_PLANE
	render_target = FLOOR_LIGHTING_LAMPS_RENDER_TARGET

/atom/movable/screen/plane_master/exposure
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	name = "exposure plane master"
	plane = LIGHTING_EXPOSURE_PLANE
	appearance_flags = PLANE_MASTER|PIXEL_SCALE
	blend_mode = BLEND_ADD
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	eye_floor_filters = list("blur_exposure")

/// Без размытия экспозиция - жёсткие пятна, поэтому чужой этаж её гасит.
/atom/movable/screen/plane_master/exposure/set_eye_floor(eye_floor)
	. = ..()
	alpha = (is_eye_floor && LAZYACCESS(filter_data, "blur_exposure")) ? 255 : 0

/atom/movable/screen/plane_master/exposure/backdrop(mob/mymob)
	remove_filter("blur_exposure")
	remove_filter("user_brightness")
	alpha = 0
	var/datum/preferences/prefs = viewer_prefs(mymob)
	if(!prefs || prefs.lighting_quality == LIGHTING_QUALITY_FAST)
		return
	var/brightness = prefs.lighting_lamp_brightness
	if(isnull(brightness))
		brightness = LIGHTING_LAMP_BRIGHTNESS_DEFAULT
	brightness = clamp(brightness, LIGHTING_LAMP_BRIGHTNESS_MIN, LIGHTING_LAMP_BRIGHTNESS_MAX)
	var/mapped = 60 + brightness * 0.4
	var/ratio = (mapped - LIGHTING_LAMP_BRIGHTNESS_DEFAULT) / 200
	if(ratio != 0)
		add_filter("user_brightness", 5, color_matrix_filter(list(
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			0,0,0,1,
			ratio, ratio, ratio, 0
		)))
	var/has_legacy_light_pref = ("light" in prefs.vars)
	var/enabled = TRUE
	if(has_legacy_light_pref)
		enabled = (prefs.light & LIGHT_EXPOSURE)
	else
		enabled = (prefs.lighting_blur >= 1)
	if(enabled)
		alpha = is_eye_floor ? 255 : 0
		var/bloom_intensity = prefs.lighting_bloom_intensity
		if(isnull(bloom_intensity))
			bloom_intensity = LIGHTING_BLOOM_INTENSITY_DEFAULT
		// Экспозиция масштабируется интенсивностью 0-200
		var/blur_size = clamp(12 + bloom_intensity * 0.12, 8, 28)
		add_filter("blur_exposure", 1, gauss_blur_filter(size = blur_size))

/atom/movable/screen/plane_master/lamps_selfglow
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	name = "lamps selfglow plane master"
	plane = LIGHTING_LAMPS_SELFGLOW
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_ADD
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	eye_floor_filters = list("add_lamps_to_selfglow", "lamps_selfglow_bloom", "selfglow_game_mask")
	var/target_rendering = LIGHTING_LAMPS_RENDER_TARGET

/atom/movable/screen/plane_master/lamps_selfglow/floor
	name = "floor lamps selfglow plane master"
	plane = FLOOR_LIGHTING_LAMPS_SELFGLOW
	target_rendering = FLOOR_LIGHTING_LAMPS_RENDER_TARGET

/atom/movable/screen/plane_master/lamps_selfglow/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	add_filter("selfglow_game_mask", 1, alpha_mask_filter(render_source = "[home?.use_render_plates ? "*" : ""][OFFSET_RENDER_TARGET(GAME_PLANE_RENDER_TARGET, offset)]", flags = MASK_INVERSE))

/atom/movable/screen/plane_master/lamps_selfglow/backdrop(mob/mymob)
	remove_filter("add_lamps_to_selfglow")
	remove_filter("lamps_selfglow_bloom")
	remove_filter("user_brightness")
	var/datum/preferences/prefs = viewer_prefs(mymob)
	if(!prefs || prefs.lighting_quality == LIGHTING_QUALITY_FAST)
		return
	var/brightness = prefs.lighting_lamp_brightness
	if(isnull(brightness))
		brightness = LIGHTING_LAMP_BRIGHTNESS_DEFAULT
	brightness = clamp(brightness, LIGHTING_LAMP_BRIGHTNESS_MIN, LIGHTING_LAMP_BRIGHTNESS_MAX)
	var/mapped = 60 + brightness * 0.4
	var/ratio = (mapped - LIGHTING_LAMP_BRIGHTNESS_DEFAULT) / 200
	if(ratio != 0)
		add_filter("user_brightness", 5, color_matrix_filter(list(
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			0,0,0,1,
			ratio, ratio, ratio, 0
		)))
	var/has_legacy_light_pref = ("light" in prefs.vars)
	var/has_glowlevel = ("glowlevel" in prefs.vars)
	var/level
	if(has_legacy_light_pref && has_glowlevel)
		if(!(prefs.light & LIGHT_NEW_LIGHTING))
			return
		level = prefs.glowlevel
	else
		var/blur = prefs.lighting_blur || 0
		if(blur <= 0)
			return
		else if(blur == 1)
			level = GLOW_LOW
		else if(blur == 2)
			level = GLOW_MED
		else
			level = GLOW_HIGH
	if(isnull(level))
		return
	var/bloomsize = 0
	var/bloomoffset = 0
	switch(level)
		if(GLOW_LOW)
			bloomsize = 2
			bloomoffset = 1
		if(GLOW_MED)
			bloomsize = 3
			bloomoffset = 2
		if(GLOW_HIGH)
			bloomsize = 4
			bloomoffset = 2
		else
			return
	var/bloom_intensity = prefs.lighting_bloom_intensity
	if(isnull(bloom_intensity))
		bloom_intensity = LIGHTING_BLOOM_INTENSITY_DEFAULT
	if(bloom_intensity <= 0)
		return
	// Блум 0-200, где 100 = старый максимум (текущие 100 -> 50)
	var/bloom_alpha = clamp(25 + bloom_intensity * 0.28, 15, 85)
	var/bloom_scale = 0.5 + bloom_intensity / 200 * 0.9
	bloomsize = max(1, round(bloomsize * bloom_scale))
	bloomoffset = max(1, round(bloomoffset * bloom_scale))
	add_filter("add_lamps_to_selfglow", 1, layering_filter(render_source = OFFSET_RENDER_TARGET(target_rendering, offset), blend_mode = BLEND_OVERLAY))
	add_filter("lamps_selfglow_bloom", 1, bloom_filter(threshold = LIGHT_COLOR_BLOOM_THRESHOLD, size = bloomsize, offset = bloomoffset, alpha = bloom_alpha))

/atom/movable/screen/plane_master/lamps_glare
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	name = "lamps glare plane master"
	plane = LIGHTING_LAMPS_GLARE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	eye_floor_filters = list("add_lamps_to_glare", "lamps_glare", "glare_game_mask")
	var/target_rendering = LIGHTING_LAMPS_RENDER_TARGET

/atom/movable/screen/plane_master/lamps_glare/floor
	name = "floor lamps glare plane master"
	plane = FLOOR_LIGHTING_LAMPS_GLARE
	target_rendering = FLOOR_LIGHTING_LAMPS_RENDER_TARGET

/atom/movable/screen/plane_master/lamps_glare/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	add_filter("glare_game_mask", 1, alpha_mask_filter(render_source = "[home?.use_render_plates ? "*" : ""][OFFSET_RENDER_TARGET(GAME_PLANE_RENDER_TARGET, offset)]", flags = MASK_INVERSE))

/atom/movable/screen/plane_master/lamps_glare/backdrop(mob/mymob)
	remove_filter("add_lamps_to_glare")
	remove_filter("lamps_glare")
	remove_filter("user_brightness")
	var/datum/preferences/prefs = viewer_prefs(mymob)
	if(!prefs || prefs.lighting_quality == LIGHTING_QUALITY_FAST)
		return
	var/brightness = prefs.lighting_lamp_brightness
	if(isnull(brightness))
		brightness = LIGHTING_LAMP_BRIGHTNESS_DEFAULT
	brightness = clamp(brightness, LIGHTING_LAMP_BRIGHTNESS_MIN, LIGHTING_LAMP_BRIGHTNESS_MAX)
	var/mapped = 60 + brightness * 0.4
	var/ratio = (mapped - LIGHTING_LAMP_BRIGHTNESS_DEFAULT) / 200
	if(ratio != 0)
		add_filter("user_brightness", 5, color_matrix_filter(list(
			1,0,0,0,
			0,1,0,0,
			0,0,1,0,
			0,0,0,1,
			ratio, ratio, ratio, 0
		)))
	var/has_legacy_light_pref = ("light" in prefs.vars)
	var/enabled = TRUE
	if(has_legacy_light_pref)
		enabled = (prefs.light & LIGHT_GLARE)
	else
		enabled = (prefs.lighting_blur >= 2)
	if(enabled)
		add_filter("add_lamps_to_glare", 1, layering_filter(render_source = OFFSET_RENDER_TARGET(target_rendering, offset), blend_mode = BLEND_ADD))
		// Комфортнее: чуть слабее radial blur
		add_filter("lamps_glare", 1, radial_blur_filter(size = 0.025))

///Contains space parallax
/atom/movable/screen/plane_master/parallax
	name = "parallax plane master"
	plane = PLANE_SPACE_PARALLAX
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = PLANE_SPACE_PARALLAX_RENDER_TARGET
	multiz_scaled = FALSE
	/// Слои параллакса лежат в client.screen на несмещённой плоскости: их собирает нулевой этаж и раздаёт остальным.
	mirrors_to_all_floors = TRUE

/// Зеркало от нулевого этажа заводит сам построенный этаж: реле на плоскость без мастера рисуется сырым под плитами и проступает в невидимых и тёмных клетках.
/// BLEND_OVERLAY: умножит мастер этажа-получателя, второе умножение выжгло бы звёзды.
/atom/movable/screen/plane_master/parallax/Initialize(mapload, datum/hud/hud_owner, datum/plane_master_group/home, offset = 0)
	. = ..()
	//У вторичной карты своих слоёв нет.
	if(!offset || home?.map)
		return
	var/atom/movable/screen/plane_master/parallax/source = home?.plane_masters["[PLANE_SPACE_PARALLAX]"]
	source?.add_relay_to(plane, BLEND_OVERLAY)

/atom/movable/screen/plane_master/parallax_white
	name = "parallax backdrop/space turf plane master"
	plane = PLANE_SPACE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	wants_world_distortion = TRUE

///Надсветовое: лампочки шлюзов, искры, свечение флоры, иконки билдмода. Свет его не гасит - реле плиты лежит слоем выше реле освещения.
/atom/movable/screen/plane_master/above_lighting
	name = "above lighting plane master"
	plane = ABOVE_LIGHTING_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

///Области: погодные оверлеи. Лежит под освещением, чтобы буря гасла в темноте.
/atom/movable/screen/plane_master/area
	name = "area plane master"
	plane = AREA_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

///Пузырь "показать предмет": выше освещения, но в картинке своего этажа.
/atom/movable/screen/plane_master/point
	name = "point plane master"
	plane = POINT_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/camera_static
	name = "camera static plane master"
	plane = CAMERA_STATIC_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY

//Reserved to chat messages, so they are still displayed above the field of vision masking.
/atom/movable/screen/plane_master/chat_messages
	name = "runechat plane master"
	plane = CHAT_PLANE
	render_relay_planes = list(RENDER_PLANE_GAME_WORLD)
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY


/atom/movable/screen/plane_master/gravpulse
	name = "gravpulse plane"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = GRAVITY_PULSE_PLANE
	render_target = GRAVITY_PULSE_RENDER_TARGET
	blend_mode = BLEND_ADD
	render_relay_planes = list()
