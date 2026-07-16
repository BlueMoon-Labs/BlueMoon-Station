///сколько /mob/oranges_ear прогенерировать на ините (аллокации сверх этого создают новые)
#define NUMBER_OF_PREGENERATED_ORANGES_EARS 2500

/**
 * # Spatial Grid Cell
 *
 * Ячейка спатиал-грида: хранит списки содержимого своей области по каналам.
 * Ячейки - только данные; наполняет и опустошает их SSspatial_grid.
 */
/datum/spatial_grid_cell
	///наш x-индекс в строке ячеек
	var/cell_x
	///наш y-индекс (индекс строки в гриде z-уровня)
	var/cell_y
	///z-уровень, которому принадлежит наш грид
	var/cell_z

	//пустые списки содержимого - это ссылка на общий dummy_list подсистемы,
	//чтобы не платить памятью за пустые списки и не проверять null в поиске

	///все слышащие movables в ячейке
	var/list/hearing_contents
	///все мобы с клиентом в ячейке
	var/list/client_contents

/datum/spatial_grid_cell/New(cell_x, cell_y, cell_z)
	. = ..()
	src.cell_x = cell_x
	src.cell_y = cell_y
	src.cell_z = cell_z

	var/list/dummy_list = SSspatial_grid.dummy_list
	if(length(dummy_list))
		dummy_list.Cut()
		stack_trace("SSspatial_grid.dummy_list was polluted! It must always stay empty.")
	hearing_contents = dummy_list
	client_contents = dummy_list

/datum/spatial_grid_cell/Destroy(force)
	if(!force) //ячейки живут вечно вместе со своим z-уровнем
		stack_trace("qdel(/datum/spatial_grid_cell) without force")
		return QDEL_HINT_LETMELIVE
	return ..()

/**
 * # Spatial Grid
 *
 * Порт tg (только каналы HEARING и CLIENTS; атмос у нас нативный и в гриде
 * не нуждается). Каждый z-уровень покрыт сеткой ячеек 17x17 турфов, в
 * ячейках лежат списки слышащих атомов и клиент-мобов. Запрос "кто рядом" -
 * это обход нескольких ячеек вместо view() или полного списка игроков:
 * см. orthogonal_range_search() и has_nearby_player().
 *
 * Расширение world.maxx/maxy после инита у нас не происходит (нет
 * аналога EXPANDED_WORLD_BOUNDS), новые z-уровни подключает add_new_zlevel.
 */
SUBSYSTEM_DEF(spatial_grid)
	name = "Spatial Grid"
	init_order = INIT_ORDER_SPATIAL_GRID
	flags = SS_NO_FIRE

	///гриды ячеек по z-уровню; внутри - строки по y, в строках ячейки по x
	var/list/grids_by_z_level = list()
	///очередь movables, созданных до инициализации подсистемы
	var/list/waiting_to_add_by_type = list(SPATIAL_GRID_CONTENTS_TYPE_HEARING = list(), SPATIAL_GRID_CONTENTS_TYPE_CLIENTS = list())
	///кэш категорий: movable.spatial_grid_key (строка) -> отсортированный список каналов
	var/list/spatial_grid_categories = list()

	var/cells_on_x_axis = 0
	var/cells_on_y_axis = 0

	///общий пустой список, на который ссылаются пустые списки ячеек
	var/list/dummy_list = list()

	///пул прогенерированных /mob/oranges_ear для ускорения view()-фильтрации
	var/list/mob/oranges_ear/pregenerated_oranges_ears = list()
	///размер пула ушей; в норме никогда не растёт после инита
	var/number_of_oranges_ears = NUMBER_OF_PREGENERATED_ORANGES_EARS

/datum/controller/subsystem/spatial_grid/Initialize(start_timeofday)
	cells_on_x_axis = SPATIAL_GRID_CELLS_PER_SIDE(world.maxx)
	cells_on_y_axis = SPATIAL_GRID_CELLS_PER_SIDE(world.maxy)

	// enter_cell/propogate работают только после этого флага; ставим до
	// раскладки очереди (родительский Initialize выставит его же ещё раз)
	initialized = TRUE

	for(var/datum/space_level/z_level as anything in SSmapping.z_list)
		propogate_spatial_grid_to_new_z(z_level)
		CHECK_TICK

	//всё, что успело создаться до нас - раскладываем по ячейкам
	for(var/channel_type in waiting_to_add_by_type)
		var/list/queue = waiting_to_add_by_type[channel_type]
		for(var/atom/movable/movable as anything in queue)
			var/turf/movable_turf = get_turf(movable)
			if(movable_turf)
				enter_cell(movable, movable_turf)
			UnregisterSignal(movable, COMSIG_PARENT_QDELETING)
		waiting_to_add_by_type[channel_type] = list()

	pregenerate_more_oranges_ears(NUMBER_OF_PREGENERATED_ORANGES_EARS)

	return ..()

///поставить movable в очередь до инициализации грида
/datum/controller/subsystem/spatial_grid/proc/enter_pre_init_queue(atom/movable/waiting_movable, type)
	//override: один movable может встать в очередь по обоим каналам из независимых проков
	RegisterSignal(waiting_movable, COMSIG_PARENT_QDELETING, PROC_REF(queued_item_deleted), override = TRUE)
	waiting_to_add_by_type[type] += waiting_movable

///убрать movable из очереди (exclusive_type = null убирает из всех каналов)
/datum/controller/subsystem/spatial_grid/proc/remove_from_pre_init_queue(atom/movable/movable_to_remove, exclusive_type)
	if(exclusive_type)
		waiting_to_add_by_type[exclusive_type] -= movable_to_remove

		for(var/type in waiting_to_add_by_type)
			if(movable_to_remove in waiting_to_add_by_type[type])
				return //ещё числится в другом канале - сигнал не снимаем

		UnregisterSignal(movable_to_remove, COMSIG_PARENT_QDELETING)
		return

	UnregisterSignal(movable_to_remove, COMSIG_PARENT_QDELETING)
	for(var/type in waiting_to_add_by_type)
		waiting_to_add_by_type[type] -= movable_to_remove

///удаляемый movable не должен висеть в очереди
/datum/controller/subsystem/spatial_grid/proc/queued_item_deleted(atom/movable/movable_being_deleted)
	SIGNAL_HANDLER
	remove_from_pre_init_queue(movable_being_deleted, null)

///создать грид ячеек для нового z-уровня; зовётся из Initialize и add_new_zlevel
/datum/controller/subsystem/spatial_grid/proc/propogate_spatial_grid_to_new_z(datum/space_level/z_level)
	if(!initialized)
		return

	var/list/new_cell_grid = list()
	grids_by_z_level += list(new_cell_grid)

	for(var/y in 1 to cells_on_y_axis)
		new_cell_grid += list(list())
		for(var/x in 1 to cells_on_x_axis)
			var/datum/spatial_grid_cell/cell = new(x, y, z_level.z_value)
			new_cell_grid[y] += cell

///нижний/левый индекс прямоугольника поиска
#define BOUNDING_BOX_MIN(center_coord) max(GET_SPATIAL_INDEX((center_coord) - range), 1)
///верхний/правый индекс прямоугольника поиска, не выходя за грид
#define BOUNDING_BOX_MAX(center_coord, axis_size) min(GET_SPATIAL_INDEX((center_coord) + range), axis_size)

/**
 * Ортогональный поиск: собрать содержимое канала type из всех ячеек,
 * пересекающих квадрат со стороной 2*range вокруг center.
 *
 * ВАЖНО: возвращает содержимое ЯЧЕЕК, то есть больше, чем радиус range -
 * дистанцию до конкретной цели фильтруйте сами (get_dist).
 */
/datum/controller/subsystem/spatial_grid/proc/orthogonal_range_search(atom/center, type, range)
	var/turf/center_turf = get_turf(center)
	if(!center_turf || center_turf.z > length(grids_by_z_level))
		return list()

	var/center_x = center_turf.x //используются внутри макросов
	var/center_y = center_turf.y

	. = list()

	var/list/list/datum/spatial_grid_cell/grid_level = grids_by_z_level[center_turf.z]

	switch(type)
		if(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
			for(var/row in BOUNDING_BOX_MIN(center_y) to BOUNDING_BOX_MAX(center_y, cells_on_y_axis))
				for(var/x_index in BOUNDING_BOX_MIN(center_x) to BOUNDING_BOX_MAX(center_x, cells_on_x_axis))
					. += grid_level[row][x_index].client_contents

		if(SPATIAL_GRID_CONTENTS_TYPE_HEARING)
			for(var/row in BOUNDING_BOX_MIN(center_y) to BOUNDING_BOX_MAX(center_y, cells_on_y_axis))
				for(var/x_index in BOUNDING_BOX_MIN(center_x) to BOUNDING_BOX_MAX(center_x, cells_on_x_axis))
					. += grid_level[row][x_index].hearing_contents

	return .

///ячейка, накрывающая координаты target (null, если target вне мира/грида)
/datum/controller/subsystem/spatial_grid/proc/get_cell_of(atom/target) as /datum/spatial_grid_cell
	var/turf/target_turf = get_turf(target)
	if(!target_turf || target_turf.z > length(grids_by_z_level))
		return

	return grids_by_z_level[target_turf.z][GET_SPATIAL_INDEX(target_turf.y)][GET_SPATIAL_INDEX(target_turf.x)]

///все ячейки, пересекающие квадрат со стороной 2*range вокруг center
/datum/controller/subsystem/spatial_grid/proc/get_cells_in_range(atom/center, range)
	var/turf/center_turf = get_turf(center)
	if(!center_turf || center_turf.z > length(grids_by_z_level))
		return list()

	var/list/intersecting_grid_cells = list()

	var/min_x = max(GET_SPATIAL_INDEX(center_turf.x - range), 1)
	var/min_y = max(GET_SPATIAL_INDEX(center_turf.y - range), 1)
	var/max_x = min(GET_SPATIAL_INDEX(center_turf.x + range), cells_on_x_axis)
	var/max_y = min(GET_SPATIAL_INDEX(center_turf.y + range), cells_on_y_axis)

	var/list/grid_level = grids_by_z_level[center_turf.z]
	for(var/row in min_y to max_y)
		var/list/grid_row = grid_level[row]
		for(var/x_index in min_x to max_x)
			intersecting_grid_cells += grid_row[x_index]

	return intersecting_grid_cells

/// Добавить movable "осведомлённость" о канале: при пересечении границы
/// ячеек он будет вызывать exit_cell/enter_cell (см. Moved)
/datum/controller/subsystem/spatial_grid/proc/add_grid_awareness(atom/movable/add_to, type)
	//ключ - строка, а списки каналов в кэше общие, поэтому всегда собираем новый список
	var/list/current_list = spatial_grid_categories[add_to.spatial_grid_key]
	if(current_list)
		current_list = current_list.Copy()
	else
		current_list = list()

	//вставка с сохранением сортировки, чтобы не плодить эквивалентные ключи
	//вида "A-B" и "B-A" (каналов всего два, цикл тривиален)
	var/insert_at = length(current_list) + 1
	for(var/i in 1 to length(current_list))
		if(current_list[i] == type)
			return //уже осведомлён
		if(sorttext(type, current_list[i]) >= 0)
			insert_at = i
			break
	current_list.Insert(insert_at, type)
	update_grid_awareness(add_to, current_list)

///снять с movable осведомлённость о канале
/datum/controller/subsystem/spatial_grid/proc/remove_grid_awareness(atom/movable/remove_from, type)
	var/list/current_list = spatial_grid_categories[remove_from.spatial_grid_key]
	if(current_list)
		current_list = current_list.Copy()
	else
		current_list = list()
	current_list -= type
	update_grid_awareness(remove_from, current_list)

///членство: положить movable в его текущую ячейку по каналу type
/datum/controller/subsystem/spatial_grid/proc/add_grid_membership(atom/movable/add_to, turf/target_turf, type)
	if(!target_turf)
		return
	if(initialized)
		add_single_type(add_to, target_turf, type)
	else
		enter_pre_init_queue(add_to, type)

///членство: убрать movable из его текущей ячейки по каналу type
/datum/controller/subsystem/spatial_grid/proc/remove_grid_membership(atom/movable/remove_from, turf/target_turf, type)
	if(!target_turf)
		return
	if(initialized)
		remove_single_type(remove_from, target_turf, type)
	else
		remove_from_pre_init_queue(remove_from, type)

///пересобрать spatial_grid_key movable'а из нового списка каналов
/datum/controller/subsystem/spatial_grid/proc/update_grid_awareness(atom/movable/update, list/new_list)
	//храним строку, а не список: ей нельзя навредить снаружи
	update.spatial_grid_key = new_list.Join("-")
	if(!spatial_grid_categories[update.spatial_grid_key])
		spatial_grid_categories[update.spatial_grid_key] = new_list

///положить new_target во все каналы его ключа в ячейке турфа target_turf
/datum/controller/subsystem/spatial_grid/proc/enter_cell(atom/movable/new_target, turf/target_turf)
	if(!initialized)
		return
	if(QDELETED(new_target))
		CRASH("qdeleted or null target trying to enter the spatial grid!")
	if(!target_turf || !new_target.spatial_grid_key)
		CRASH("null turf loc or a new_target without a spatial_grid_key trying to enter the spatial grid!")
	if(target_turf.z > length(grids_by_z_level))
		return

	var/datum/spatial_grid_cell/intersecting_cell = grids_by_z_level[target_turf.z][GET_SPATIAL_INDEX(target_turf.y)][GET_SPATIAL_INDEX(target_turf.x)]

	for(var/type in spatial_grid_categories[new_target.spatial_grid_key])
		switch(type)
			if(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
				var/list/new_target_contents = new_target.important_recursive_contents
				GRID_CELL_SET(intersecting_cell.client_contents, new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_CLIENTS])
				SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_CLIENTS])

			if(SPATIAL_GRID_CONTENTS_TYPE_HEARING)
				var/list/new_target_contents = new_target.important_recursive_contents
				GRID_CELL_SET(intersecting_cell.hearing_contents, new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_HEARING])
				SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_HEARING), new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_HEARING])

///как enter_cell, но только для одного канала
/datum/controller/subsystem/spatial_grid/proc/add_single_type(atom/movable/new_target, turf/target_turf, exclusive_type)
	if(!initialized)
		return
	if(QDELETED(new_target))
		CRASH("qdeleted or null target trying to enter the spatial grid!")
	if(!target_turf || !(exclusive_type in spatial_grid_categories[new_target.spatial_grid_key]))
		CRASH("null turf loc or a new_target outside the [exclusive_type] channel trying to enter the spatial grid!")
	if(target_turf.z > length(grids_by_z_level))
		return

	var/datum/spatial_grid_cell/intersecting_cell = grids_by_z_level[target_turf.z][GET_SPATIAL_INDEX(target_turf.y)][GET_SPATIAL_INDEX(target_turf.x)]

	switch(exclusive_type)
		if(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
			var/list/new_target_contents = new_target.important_recursive_contents
			GRID_CELL_SET(intersecting_cell.client_contents, new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_CLIENTS])
			SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_CLIENTS])

		if(SPATIAL_GRID_CONTENTS_TYPE_HEARING)
			var/list/new_target_contents = new_target.important_recursive_contents
			GRID_CELL_SET(intersecting_cell.hearing_contents, new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_HEARING])
			SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_HEARING), new_target_contents[SPATIAL_GRID_CONTENTS_TYPE_HEARING])

	return intersecting_cell

///убрать old_target (и содержимое его каналов) из ячейки турфа target_turf
/datum/controller/subsystem/spatial_grid/proc/exit_cell(atom/movable/old_target, turf/target_turf)
	if(!initialized)
		return
	if(!target_turf || !old_target.spatial_grid_key)
		stack_trace("spatial_grid exit_cell(): null turf or a target without a spatial_grid_key!")
		return FALSE
	if(target_turf.z > length(grids_by_z_level))
		return FALSE

	var/datum/spatial_grid_cell/intersecting_cell = grids_by_z_level[target_turf.z][GET_SPATIAL_INDEX(target_turf.y)][GET_SPATIAL_INDEX(target_turf.x)]

	for(var/type in spatial_grid_categories[old_target.spatial_grid_key])
		switch(type)
			if(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
				var/list/old_target_contents = old_target.important_recursive_contents?[type] || old_target
				GRID_CELL_REMOVE(intersecting_cell.client_contents, old_target_contents)
				SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_EXITED(type), old_target_contents)

			if(SPATIAL_GRID_CONTENTS_TYPE_HEARING)
				var/list/old_target_contents = old_target.important_recursive_contents?[type] || old_target
				GRID_CELL_REMOVE(intersecting_cell.hearing_contents, old_target_contents)
				SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_EXITED(type), old_target_contents)

	return TRUE

///как exit_cell, но только для одного канала
/datum/controller/subsystem/spatial_grid/proc/remove_single_type(atom/movable/old_target, turf/target_turf, exclusive_type)
	if(!target_turf || !exclusive_type || !old_target.spatial_grid_key)
		stack_trace("spatial_grid remove_single_type(): null arguments or a target without a spatial_grid_key!")
		return FALSE
	if(!(exclusive_type in spatial_grid_categories[old_target.spatial_grid_key]))
		return FALSE
	if(target_turf.z > length(grids_by_z_level))
		return FALSE

	var/datum/spatial_grid_cell/intersecting_cell = grids_by_z_level[target_turf.z][GET_SPATIAL_INDEX(target_turf.y)][GET_SPATIAL_INDEX(target_turf.x)]

	switch(exclusive_type)
		if(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
			var/list/old_target_contents = old_target.important_recursive_contents?[exclusive_type] || old_target
			GRID_CELL_REMOVE(intersecting_cell.client_contents, old_target_contents)
			SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_EXITED(exclusive_type), old_target_contents)

		if(SPATIAL_GRID_CONTENTS_TYPE_HEARING)
			var/list/old_target_contents = old_target.important_recursive_contents?[exclusive_type] || old_target
			GRID_CELL_REMOVE(intersecting_cell.hearing_contents, old_target_contents)
			SEND_SIGNAL(intersecting_cell, SPATIAL_GRID_CELL_EXITED(exclusive_type), old_target_contents)

	return TRUE

/**
 * Аварийное удаление movable из грида (вызывается из Destroy).
 * Обычно ячейка выводится из loc; если loc уже нет (nullspace) - придётся
 * просканировать все ячейки, это страховка от висящих ссылок.
 */
/datum/controller/subsystem/spatial_grid/proc/force_remove_from_grid(atom/movable/to_remove)
	if(!to_remove?.spatial_grid_key)
		return

	if(!initialized)
		remove_from_pre_init_queue(to_remove, null)
		return

	var/datum/spatial_grid_cell/loc_cell = get_cell_of(to_remove)
	if(loc_cell)
		GRID_CELL_REMOVE_ALL(loc_cell, to_remove)
	else
		find_hanging_cell_refs_for_movable(to_remove, remove_from_cells = TRUE)

///убрать movable из конкретной ячейки
/datum/controller/subsystem/spatial_grid/proc/force_remove_from_cell(atom/movable/to_remove, datum/spatial_grid_cell/input_cell)
	if(!input_cell)
		return
	GRID_CELL_REMOVE_ALL(input_cell, to_remove)

///полный скан: найти (и опционально вычистить) все ячейки, где висит movable
/datum/controller/subsystem/spatial_grid/proc/find_hanging_cell_refs_for_movable(atom/movable/to_remove, remove_from_cells = TRUE)
	var/list/queues_containing_movable = list()
	for(var/queue_channel in waiting_to_add_by_type)
		var/list/queue_list = waiting_to_add_by_type[queue_channel]
		if(to_remove in queue_list)
			queues_containing_movable += queue_channel
			if(remove_from_cells)
				queue_list -= to_remove

	if(!initialized)
		return queues_containing_movable

	var/list/containing_cells = list()
	for(var/list/z_level_grid as anything in grids_by_z_level)
		for(var/list/cell_row as anything in z_level_grid)
			for(var/datum/spatial_grid_cell/cell as anything in cell_row)
				if((to_remove in cell.hearing_contents) || (to_remove in cell.client_contents))
					containing_cells += cell
					if(remove_from_cells)
						force_remove_from_cell(to_remove, cell)

	return containing_cells

///пополнить пул ушей; после инита звать не должно быть нужды
/datum/controller/subsystem/spatial_grid/proc/pregenerate_more_oranges_ears(number_to_generate)
	for(var/new_ear in 1 to number_to_generate)
		pregenerated_oranges_ears += new /mob/oranges_ear(null)

	number_of_oranges_ears = length(pregenerated_oranges_ears)

/**
 * Расставить по одному /mob/oranges_ear на каждый турф, содержащий атомы из
 * atoms_that_need_ears, и раздать ушам ссылки на их атомы. Если на турфе уже
 * стоит ухо этого запроса - атом просто дописывается к нему.
 *
 * Вызывающий обязан после view()-фильтрации снять все уши через unassign()
 * (см. get_hearers_in_view).
 */
/datum/controller/subsystem/spatial_grid/proc/assign_oranges_ears(list/atoms_that_need_ears)
	var/input_length = length(atoms_that_need_ears)

	if(input_length > number_of_oranges_ears)
		stack_trace("assign_oranges_ears() got [input_length] atoms with only [number_of_oranges_ears] pregenerated ears! Growing the pool.")
		pregenerate_more_oranges_ears(input_length - number_of_oranges_ears)

	. = list()

	var/mob/oranges_ear/current_ear
	var/atom/assigned_atom
	var/turf/turf_loc

	for(var/current_ear_index in 1 to input_length)
		assigned_atom = atoms_that_need_ears[current_ear_index]

		turf_loc = get_turf(assigned_atom)
		if(!turf_loc)
			continue

		current_ear = pregenerated_oranges_ears[current_ear_index]

		if(turf_loc.assigned_oranges_ear)
			turf_loc.assigned_oranges_ear.references += assigned_atom
			continue //на этом турфе уже стоит ухо - второе аллоцировать незачем

		current_ear.references += assigned_atom

		//прямое присваивание loc вместо forceMove: ухо должно только числиться
		//в contents турфа для view(), вся движковая обвязка перемещений не нужна
		current_ear.loc = turf_loc
		turf_loc.assigned_oranges_ear = current_ear

		. += current_ear

#undef NUMBER_OF_PREGENERATED_ORANGES_EARS

#undef BOUNDING_BOX_MAX
#undef BOUNDING_BOX_MIN
