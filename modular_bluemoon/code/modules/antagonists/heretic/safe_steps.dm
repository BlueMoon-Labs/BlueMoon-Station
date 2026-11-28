/// Диагональный шаг Move делит на два прямых через соседние клетки: опора нужна под обеими, иначе цель провалится или сгорит по пути.
/proc/heretic_diagonal_step_safe(turf/here, direction)
	if(!ISDIAGONALDIR(direction))
		return TRUE
	var/turf/vertical = get_step(here, direction & (NORTH|SOUTH))
	var/turf/horizontal = get_step(here, direction & (EAST|WEST))
	return !isgroundlessturf(vertical) && !isgroundlessturf(horizontal)
