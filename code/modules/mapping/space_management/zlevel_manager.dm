// Populate the space level list and prepare space transitions
/datum/controller/subsystem/mapping/proc/InitializeDefaultZLevels()
	if (z_list)  // subsystem/Recover or badminnery, no need
		return

	z_list = list()
	var/list/default_map_traits = DEFAULT_MAP_TRAITS

	if (default_map_traits.len != world.maxz)
		WARNING("More or less map attributes pre-defined ([default_map_traits.len]) than existent z-levels ([world.maxz]). Ignoring the larger.")
		if (default_map_traits.len > world.maxz)
			default_map_traits.Cut(world.maxz + 1)

	for (var/I in 1 to default_map_traits.len)
		var/list/features = default_map_traits[I]
		var/datum/space_level/S = new(I, features[DL_NAME], features[DL_TRAITS])
		z_list += S
		calculate_z_level_gravity(I)

	build_z_stacks()

/datum/controller/subsystem/mapping/proc/add_new_zlevel(name, traits = list(), z_type = /datum/space_level)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NEW_Z, args)
	var/new_z = z_list.len + 1
	if (world.maxz < new_z)
		world.incrementMaxZ()
		CHECK_TICK
	// TODO: sleep here if the Z level needs to be cleared
	var/datum/space_level/S = new z_type(new_z, name, traits)
	z_list += S
	calculate_z_level_gravity(new_z)
	//z-уровни, созданные до инита грида, разложит SSspatial_grid/Initialize сам
	SSspatial_grid.propogate_spatial_grid_to_new_z(S)
	build_z_stacks()
	return S

/// Раскладывает z-уровни по вертикальным связкам, кэшируя сами связки, смещения плоскостей и соседей сверху-снизу.
/datum/controller/subsystem/mapping/proc/build_z_stacks()
	var/level_count = length(z_list)
	var/list/old_plane_offsets = z_level_to_plane_offset
	z_level_to_stack = new /list(level_count)
	z_level_to_plane_offset = new /list(level_count)
	z_level_to_lowest_plane_offset = new /list(level_count)
	z_level_below = new /list(level_count)
	z_level_above = new /list(level_count)
	var/deepest_stack = 0

	if(!plane_offset_to_true)
		plane_offset_to_true = list()
		true_to_offset_planes = list()
		plane_to_offset = list()
		plane_offset_blacklist = list()
		render_offset_blacklist = list()
		critical_planes = list()
		//FLOAT_PLANE наследует плоскость родителя, смещать его нельзя: оверлеи разъедутся по этажам.
		plane_offset_to_true["[FLOAT_PLANE]"] = FLOAT_PLANE
		true_to_offset_planes["[FLOAT_PLANE]"] = list(FLOAT_PLANE)
		plane_to_offset["[FLOAT_PLANE]"] = 0
		plane_offset_blacklist["[FLOAT_PLANE]"] = TRUE
		//Плоскости без мастера смещать некуда: смещённый номер уходит под экранную плиту.
		for(var/masterless_plane in list(EMISSIVE_BLOCKER_PLANE, BYOND_LIGHTING_PLANE, HIGH_GAME_PLANE))
			plane_offset_blacklist["[masterless_plane]"] = TRUE
		create_plane_offsets(0, 0)

	for(var/z in 1 to level_count)
		if(z_level_to_stack[z])
			continue //уже разложен вместе со своей связкой

		//Гард по числу шагов - страховка от карты с закольцованными трейтами Up/Down.
		var/bottom = z
		var/steps = 0
		var/offset = level_trait(bottom, ZTRAIT_DOWN)
		while(isnum(offset) && offset && steps++ < level_count)
			var/next = bottom + offset
			if(next < 1 || next > level_count)
				break
			bottom = next
			offset = level_trait(bottom, ZTRAIT_DOWN)

		var/list/stack = list(bottom)
		var/top = bottom
		steps = 0
		offset = level_trait(top, ZTRAIT_UP)
		while(isnum(offset) && offset && steps++ < level_count)
			var/next = top + offset
			if(next < 1 || next > level_count || (next in stack))
				break
			//Связь обязана быть обоюдной: односторонний Up склеивает две несвязанные карты в одну стопку.
			if(level_trait(next, ZTRAIT_DOWN) != -offset)
				log_mapping("Мульти-Z: у z=[top] ZTRAIT_UP=[offset] ведёт на z=[next], но обратного ZTRAIT_DOWN там нет - связка оборвана.")
				break
			top = next
			stack += top
			offset = level_trait(top, ZTRAIT_UP)

		if(!(z in stack))
			log_mapping("Мульти-Z: z=[z] не нашёл себя в собранной связке [json_encode(stack)] - трейты Up/Down несимметричны, уровень остаётся одиночкой.")
			stack = list(z)

		//По связке ходят лестницы, звук и get_turf_above(), а куб нужен только там, где видно сквозь пол.
		var/skip_plane_stack = FALSE
		for(var/member in stack)
			if(level_trait(member, ZTRAIT_NO_PLANE_STACK))
				skip_plane_stack = TRUE
				break

		//Глубже рендер не выдержит: слой реле уходит в минус и порядок этажей рассыпается.
		var/highest_offset = skip_plane_stack ? 0 : (length(stack) - 1)
		if(highest_offset > MAX_SUPPORTED_Z_DEPTH)
			stack_trace("Связка [json_encode(stack)] глубиной [highest_offset] превышает MAX_SUPPORTED_Z_DEPTH ([MAX_SUPPORTED_Z_DEPTH]): куб обрезан, нижние этажи делят смещение с последним поддерживаемым.")
			highest_offset = MAX_SUPPORTED_Z_DEPTH
		for(var/index in 1 to length(stack))
			var/member = stack[index]
			//Граф Up допускает слияние путей: перетереть чужую связку значит развести соседей по разным раскладам.
			var/list/claimed = z_level_to_stack[member]
			if(claimed && claimed != stack)
				stack_trace("z=[member] уже расписан связкой [json_encode(claimed)], а z=[z] тянет его в [json_encode(stack)]. Трейты Up/Down на карте противоречивы.")
				continue
			z_level_to_stack[member] = stack
			z_level_to_plane_offset[member] = skip_plane_stack ? 0 : min(length(stack) - index, MAX_SUPPORTED_Z_DEPTH)
			z_level_to_lowest_plane_offset[member] = highest_offset
			z_level_below[member] = index > 1 ? stack[index - 1] : 0
			z_level_above[member] = index < length(stack) ? stack[index + 1] : 0
		deepest_stack = max(deepest_stack, highest_offset)

	if(deepest_stack > max_plane_offset)
		var/old_max = max_plane_offset
		max_plane_offset = deepest_stack
		//Списки перевода плоскостей обязаны быть готовы до сигнала: по нему строят мастеров на новые этажи.
		create_plane_offsets(old_max + 1, max_plane_offset)
		SEND_SIGNAL(src, COMSIG_PLANE_OFFSET_INCREASE, old_max, max_plane_offset)
		if(max_plane_offset > MAX_EXPECTED_Z_DEPTH)
			stack_trace("Загружена карта глубже MAX_EXPECTED_Z_DEPTH ([max_plane_offset] > [MAX_EXPECTED_Z_DEPTH]): настройки игрока не покроют всю глубину.")

	//После старта турфы нового уровня никто не инициализирует, а Initialize уже прошедших этаж не сменит.
	if(SSatoms.initialized != INITIALIZATION_INSSATOMS)
		for(var/z in 1 to level_count)
			var/old_offset = (z <= length(old_plane_offsets) ? old_plane_offsets[z] : 0) || 0
			var/new_offset = z_level_to_plane_offset[z] || 0
			if(new_offset == old_offset)
				continue
			var/moved = apply_level_plane_offset(z)
			log_mapping("Мульти-Z: z=[z] сменил смещение [old_offset] -> [new_offset], турфов переложено на плоскости этажа: [moved].")

	//Строго последним: прозрачным турфам нужны уже достроенные мастера смещённых плоскостей.
	apply_transparent_space()

/// Перекладывает турфы уровня на плоскости его смещения: космос за границами шаблона создаётся как world.turf без Initialize. Возвращает число тронутых турфов.
/datum/controller/subsystem/mapping/proc/apply_level_plane_offset(z)
	if(!max_plane_offset || z < 1 || z > length(z_level_to_plane_offset))
		return 0
	var/offset = z_level_to_plane_offset[z] || 0
	. = 0
	for(var/turf/level_turf as anything in Z_TURFS(z))
		if(level_turf.plane == GET_NEW_PLANE(PLANE_TO_TRUE(level_turf.plane), offset))
			continue
		SET_PLANE_W_SCALAR(level_turf, PLANE_TO_TRUE(level_turf.plane), offset)
		.++
		CHECK_TICK

/// Сцепляет пары этажей (низ, верх) взаимными смещениями и пересобирает связки. Объявленную маппером вертикаль не трогает.
/datum/controller/subsystem/mapping/proc/link_z_level_pairs(list/pairs)
	var/linked = FALSE
	for(var/list/pair as anything in pairs)
		var/datum/space_level/lower = pair[1]
		var/datum/space_level/upper = pair[2]
		if(!isnull(lower.traits[ZTRAIT_UP]) || !isnull(upper.traits[ZTRAIT_DOWN]))
			continue
		lower.traits[ZTRAIT_UP] = upper.z_value - lower.z_value
		upper.traits[ZTRAIT_DOWN] = lower.z_value - upper.z_value
		linked = TRUE

	if(linked)
		build_z_stacks()
	return linked

/// Прозрачность космосу уровней с ZTRAIT_TRANSPARENT_SPACE. Турф делает это сам в Initialize, но только если этаж под ним уже есть.
/datum/controller/subsystem/mapping/proc/apply_transparent_space()
	for(var/z in 1 to length(z_list))
		//Ключ строкой: числовой индекс на обычном списке - это позиция, а не ключ.
		if(transparent_space_applied["[z]"])
			continue
		if(!level_trait(z, ZTRAIT_TRANSPARENT_SPACE))
			continue
		//Показывать нечего - и отметку не ставим: этаж под уровнем может приехать позже.
		if(!z_level_below[z])
			continue
		transparent_space_applied["[z]"] = TRUE

		if(level_trait(z, ZTRAIT_NO_PLANE_STACK))
			log_mapping("Мульти-Z: z=[z] просит прозрачный космос, но его связка помечена ZTRAIT_NO_PLANE_STACK - этаж снизу будет виден без собственного света и без сжатия.")

		//Турфы карты ещё не проинициализированы: их Initialize сделает это сам.
		if(SSatoms.initialized == INITIALIZATION_INSSATOMS)
			continue

		var/opened = 0
		for(var/turf/open/space/space_turf in Z_TURFS(z))
			if(space_turf.make_space_transparent())
				opened++
			CHECK_TICK
		log_mapping("Мульти-Z: прозрачный космос на z=[z], открыто турфов: [opened].")

/// Справочники перевода между настоящей плоскостью и её смещёнными версиями; без них куб не собирается.
/datum/controller/subsystem/mapping/proc/create_plane_offsets(gen_from, new_offset)
	for(var/plane_offset in gen_from to new_offset)
		//У абстрактной плиты своей плоскости нет: в таблицу смещений уехал бы номер плоскости худа.
		for(var/atom/movable/screen/plane_master/master_type as anything in (subtypesof(/atom/movable/screen/plane_master) - /atom/movable/screen/plane_master/rendering_plate))
			var/true_plane = initial(master_type.plane)
			var/string_true = "[true_plane]"
			var/offset_plane = GET_NEW_PLANE(true_plane, plane_offset)
			var/string_offset = "[offset_plane]"

			if(initial(master_type.offsetting_flags) & BLOCKS_PLANE_OFFSETTING)
				plane_offset_blacklist[string_offset] = TRUE
				var/target = initial(master_type.render_target) || get_plane_master_render_base(initial(master_type.name))
				render_offset_blacklist[target] = TRUE
				if(plane_offset != 0)
					continue

			plane_offset_to_true[string_offset] = true_plane
			plane_to_offset[string_offset] = plane_offset
			if(!true_to_offset_planes[string_true])
				true_to_offset_planes[string_true] = list()
			true_to_offset_planes[string_true] |= offset_plane

/// Уровни связки снизу вверх, сам z тоже в списке. Возвращается кэш, а не копия: менять его нельзя.
/datum/controller/subsystem/mapping/proc/get_connected_levels(z) as /list
	if(isatom(z))
		var/atom/thing = z
		z = thing.z
	if(!isnum(z) || z < 1 || z > length(z_level_to_stack))
		return list(z)
	return z_level_to_stack[z] || list(z)

/// Уровни связки, видимые с z: сам z и всё под ним. Свежий список.
/datum/controller/subsystem/mapping/proc/get_levels_visible_from(z) as /list
	var/list/stack = get_connected_levels(z)
	var/index = stack.Find(z)
	return index ? stack.Copy(1, index + 1) : list(z)

/// Уровни связки, с которых виден z: сам z и всё над ним. Свежий список.
/datum/controller/subsystem/mapping/proc/get_levels_viewing(z) as /list
	var/list/stack = get_connected_levels(z)
	var/index = stack.Find(z)
	return index ? stack.Copy(index) : list(z)

/datum/controller/subsystem/mapping/proc/get_level(z) as /datum/space_level
	if (z_list && z >= 1 && z <= z_list.len)
		return z_list[z]
	CRASH("Unmanaged z-level [z]! maxz = [world.maxz], z_list.len = [z_list ? z_list.len : "null"]")

/// Пересчитать кэш гравитации z-уровня: max(setting) включённых генераторов,
/// иначе ZTRAIT_GRAVITY. Трейты после создания уровня не меняются, поэтому
/// инвалидация нужна только генераторам (update_list()).
/datum/controller/subsystem/mapping/proc/calculate_z_level_gravity(z_level_number)
	if(!isnum(z_level_number) || z_level_number < 1)
		return FALSE

	var/max_gravity = 0
	for(var/obj/machinery/gravity_generator/main/grav_gen as anything in GLOB.gravity_generators["[z_level_number]"])
		max_gravity = max(grav_gen.setting, max_gravity)

	max_gravity = max_gravity || level_trait(z_level_number, ZTRAIT_GRAVITY) || 0
	if(z_level_number > length(gravity_by_z_level))
		gravity_by_z_level.len = z_level_number
	gravity_by_z_level[z_level_number] = max_gravity
	return max_gravity
