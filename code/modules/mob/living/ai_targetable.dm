// ===== Канал AI_TARGETS спатиал-грида: регистрация живых мобов =====
//
// Живые мобы числятся в SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, чтобы hostile
// AI искал цели обходом ячеек грида вместо hearers()-сканов. В канале только
// живые (stat != DEAD): охотники на трупы и прочие нестандартные искатели
// идут своими slow-path-провайдерами. Точная фильтрация (фракции, LOS,
// невидимость, обиды) остаётся за потребителем канала.
//
// Механика membership повторяет CLIENTS-канал (см. atoms_movable.dm,
// enable_client_mobs_in_contents): идемпотентная запись в
// important_recursive_contents всех вложенных locs + членство в ячейке.
// Благодаря рекурсивным контентам моб в шкафу числится в ячейке шкафа.

///Прописать живого моба в AI_TARGETS-канал грида и вложенных locs
/mob/living/proc/become_ai_targetable()
	if(important_recursive_contents && (src in important_recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS]))
		return

	for(var/atom/movable/movable_loc as anything in get_nested_locs(src) + src)
		LAZYINITLIST(movable_loc.important_recursive_contents)
		var/list/recursive_contents = movable_loc.important_recursive_contents
		if(!length(recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS]))
			SSspatial_grid.add_grid_awareness(movable_loc, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS)
		LAZYINITLIST(recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS])
		recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS] |= src

	var/turf/our_turf = get_turf(src)
	SSspatial_grid.add_grid_membership(src, our_turf, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS)

///Убрать моба из AI_TARGETS-канала грида и вложенных locs
/mob/living/proc/lose_ai_targetable()
	if(!important_recursive_contents || !(src in important_recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS]))
		return

	var/turf/our_turf = get_turf(src)
	SSspatial_grid.remove_grid_membership(src, our_turf, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS)

	for(var/atom/movable/movable_loc as anything in get_nested_locs(src) + src)
		LAZYINITLIST(movable_loc.important_recursive_contents)
		var/list/recursive_contents = movable_loc.important_recursive_contents
		LAZYINITLIST(recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS])
		recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS] -= src
		if(!length(recursive_contents[RECURSIVE_CONTENTS_AI_TARGETS]))
			SSspatial_grid.remove_grid_awareness(movable_loc, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS)
		ASSOC_UNSETEMPTY(recursive_contents, RECURSIVE_CONTENTS_AI_TARGETS)
		UNSETEMPTY(movable_loc.important_recursive_contents)

///Смерть/оживление двигают членство в канале; прямые записи stat мимо
///сеттера дают лишь протухшую запись, которую отфильтрует потребитель
/mob/living/set_stat(new_stat)
	. = ..()
	if(isnull(.)) //стат не поменялся
		return
	//смена stat меняет ветку троттла Life (жив/мёртв, сознание) - бронь бакета
	//больше не действительна
	wake_life()
	if(stat == DEAD)
		lose_ai_targetable()
	else if(. == DEAD) //ожил
		become_ai_targetable()
