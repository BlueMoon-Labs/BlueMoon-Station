// PORT: tgstation@14140a6355d1 code/modules/spatial_grid/cell_tracker.dm
//
// Трекер ячеек спатиал-грида: держит набор ячеек вокруг движущегося "окна",
// превращая паттерн "всё в радиусе от меня" в дешёвую entered/exited логику.
// Внутреннее окно добавляет ячейки в членство, внешнее (больше в ratio раз)
// удерживает их - гистерезис против дребезга на границе ячеек.
//
// Не подходит для логики со строгими требованиями к тому, чего НЕ должно быть
// в обрабатываемых записях: трекер оптимизирует только "что вошло в окно".

/datum/cell_tracker
	var/list/datum/spatial_grid_cell/member_cells = list()
	///радиус внутреннего окна по x: ячейка внутри - добавляется в членство
	var/inner_window_x_radius
	///радиус внутреннего окна по y
	var/inner_window_y_radius
	///радиус внешнего окна по x: ячейка снаружи - удаляется из членства
	var/outer_window_x_radius
	///радиус внешнего окна по y
	var/outer_window_y_radius
	///Индексы ячеек окон прошлого пересчёта (внутреннее * 64 + внешнее) и его z; 0 - пересчёта не было
	var/last_z = 0
	var/last_min_x
	var/last_max_x
	var/last_min_y
	var/last_max_y

/datum/cell_tracker/New(width, height, inner_outer_ratio)
	set_bounds(width, height, inner_outer_ratio)
	return ..()

/datum/cell_tracker/Destroy(force)
	if(!force)
		stack_trace("Attempted to delete a cell tracker. They don't hold any refs outside of cells, what are you doing")
		return QDEL_HINT_LETMELIVE
	member_cells.Cut()
	return ..()

///Задать внутреннее окно из ширины/высоты и интерполировать внешнее через ratio
/datum/cell_tracker/proc/set_bounds(width = 0, height = 0, ratio = 2)
	//храним радиусы, а не ширину/высоту - так удобнее коду грида
	var/x_radius = CEILING(width, 2)
	var/y_radius = CEILING(height, 2)
	inner_window_x_radius = x_radius
	inner_window_y_radius = y_radius
	last_z = 0

	outer_window_x_radius = x_radius * ratio
	outer_window_y_radius = y_radius * ratio

///Пересчитать членство от нового центра; вернуть list(новые ячейки, ушедшие ячейки)
/datum/cell_tracker/proc/recalculate_cells(turf/center)
	if(!center)
		CRASH("/datum/cell_tracker had an invalid location on refresh")

	var/list/datum/spatial_grid_cell/inner_window = SSspatial_grid.get_cells_in_bounds(center, inner_window_x_radius, inner_window_y_radius)
	var/list/datum/spatial_grid_cell/outer_window = SSspatial_grid.get_cells_in_bounds(center, outer_window_x_radius, outer_window_y_radius)

	var/list/datum/spatial_grid_cell/new_cells = inner_window - member_cells
	//внешнее окно может содержать ячейки, которых у нас и не было
	var/list/datum/spatial_grid_cell/old_cells = member_cells - outer_window

	member_cells -= old_cells
	member_cells += new_cells

	remember_window(center)
	return list(new_cells, old_cells)

///Индексы ячеек окна по одной оси: внутреннее * 64 + внешнее
#define CELL_TRACKER_BOUND(coord, inner, outer) (GET_SPATIAL_INDEX(coord + inner) * 64 + GET_SPATIAL_INDEX(coord + outer))

/datum/cell_tracker/proc/remember_window(turf/center)
	last_z = center.z <= length(SSspatial_grid.grids_by_z_level) ? center.z : 0
	last_min_x = CELL_TRACKER_BOUND(center.x, -inner_window_x_radius, -outer_window_x_radius)
	last_max_x = CELL_TRACKER_BOUND(center.x, inner_window_x_radius, outer_window_x_radius)
	last_min_y = CELL_TRACKER_BOUND(center.y, -inner_window_y_radius, -outer_window_y_radius)
	last_max_y = CELL_TRACKER_BOUND(center.y, inner_window_y_radius, outer_window_y_radius)

///TRUE, если окна от center покрывают те же ячейки, что при прошлом пересчёте: он ничего бы не поменял
/datum/cell_tracker/proc/window_unchanged(turf/center)
	if(!last_z || center.z != last_z)
		return FALSE
	if(last_min_x != CELL_TRACKER_BOUND(center.x, -inner_window_x_radius, -outer_window_x_radius) || last_max_x != CELL_TRACKER_BOUND(center.x, inner_window_x_radius, outer_window_x_radius))
		return FALSE
	return last_min_y == CELL_TRACKER_BOUND(center.y, -inner_window_y_radius, -outer_window_y_radius) && last_max_y == CELL_TRACKER_BOUND(center.y, inner_window_y_radius, outer_window_y_radius)

#undef CELL_TRACKER_BOUND

///Бросить членство: следующий пересчёт соберёт окно заново
/datum/cell_tracker/proc/forget_cells()
	member_cells.Cut()
	last_z = 0

///Вернуть содержимое канала type из новых и ушедших ячеек: list(новые, бывшие)
/datum/cell_tracker/proc/recalculate_type_members(turf/center, type)
	var/list/new_and_old = recalculate_cells(center)

	var/list/new_members = list()
	var/list/former_members = list()
	switch(type)
		if(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)
			for(var/datum/spatial_grid_cell/cell as anything in new_and_old[1])
				new_members += cell.client_contents
			for(var/datum/spatial_grid_cell/cell as anything in new_and_old[2])
				former_members += cell.client_contents
		if(SPATIAL_GRID_CONTENTS_TYPE_HEARING)
			for(var/datum/spatial_grid_cell/cell as anything in new_and_old[1])
				new_members += cell.hearing_contents
			for(var/datum/spatial_grid_cell/cell as anything in new_and_old[2])
				former_members += cell.hearing_contents
		if(SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS)
			for(var/datum/spatial_grid_cell/cell as anything in new_and_old[1])
				new_members += cell.ai_target_contents
			for(var/datum/spatial_grid_cell/cell as anything in new_and_old[2])
				former_members += cell.ai_target_contents

	return list(new_members, former_members)
