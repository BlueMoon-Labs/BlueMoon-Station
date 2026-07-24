/**
 * # oranges_ear (порт tg)
 *
 * view() тратит заметную часть времени на сборку списков видимого содержимого,
 * а потом мы ещё и фильтруем сотни movables ради пары слышащих. Внутри BYOND
 * contents турфа - это два связных списка (/obj и /mob), и view() умеет
 * обходить только один из них, если искомый тип это позволяет.
 *
 * Поэтому на каждый турф с кандидатами-слышащими ставится один такой моб со
 * ссылками на них, и hearers()/view() фильтрует уже только мобов: список на
 * выходе в разы короче, вложенные в контейнеры слышащие представлены ушами
 * своего турфа. Пул ушей прогенерирован в SSspatial_grid.
 */
/mob/oranges_ear
	icon_state = null
	density = FALSE
	move_resist = INFINITY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	flags_1 = NONE //не наследуем HEAR_1 от /mob: уши не должны попадать в грид
	//списки базового /mob, которые для ушей не нужны вовсе
	logging = null
	held_items = null
	alerts = null
	client_colours = null
	///ссылки на все интересующие нас movables "на" нашем турфе (включая
	///вложенных в контейнеры, у которых get_turf() == наш турф)
	var/list/references = list()

/mob/oranges_ear/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE) //полный мобовый инит (GLOB-списки, худы) ушам не нужен
	if(flags_1 & INITIALIZED_1)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_1 |= INITIALIZED_1
	return INITIALIZE_HINT_NORMAL

/mob/oranges_ear/Destroy(force)
	var/old_length = length(SSspatial_grid.pregenerated_oranges_ears)
	SSspatial_grid.pregenerated_oranges_ears -= src
	if(length(SSspatial_grid.pregenerated_oranges_ears) < old_length)
		SSspatial_grid.number_of_oranges_ears -= 1

	var/turf/our_loc = get_turf(src)
	if(our_loc && our_loc.assigned_oranges_ear == src)
		our_loc.assigned_oranges_ear = null

	return ..()

/mob/oranges_ear/Move()
	SHOULD_CALL_PARENT(FALSE)
	stack_trace("SOMEHOW A /mob/oranges_ear MOVED")
	return FALSE

/mob/oranges_ear/abstract_move(atom/destination)
	SHOULD_CALL_PARENT(FALSE)
	stack_trace("SOMEHOW A /mob/oranges_ear MOVED")
	return FALSE

/mob/oranges_ear/Bump()
	SHOULD_CALL_PARENT(FALSE)
	return FALSE

///вернуть ухо в пул после запроса
/mob/oranges_ear/proc/unassign()
	var/turf/turf_loc = loc
	turf_loc.assigned_oranges_ear = null //loc обязан быть турфом; рант тут - сам себе диагностика
	loc = null
	references.Cut()
