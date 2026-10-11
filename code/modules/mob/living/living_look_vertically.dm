/mob/living
	/// UP или DOWN, пока моб смотрит на соседний этаж.
	var/looking_vertically = NONE
	/// Глаз клиента на соседнем этаже. Держатель, а не турф, чтобы взгляд скользил вслед за мобом.
	var/obj/effect/abstract/looking_holder/looking_holder

/obj/effect/abstract/looking_holder
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/look_direction
	/// Атом на турфе, за которым едет взгляд: сам моб или то, внутри чего он сидит.
	var/atom/movable/container
	var/mob/living/owner

/obj/effect/abstract/looking_holder/Initialize(mapload, mob/living/looker, direction)
	. = ..()
	if(!istype(looker))
		return INITIALIZE_HINT_QDEL
	owner = looker
	look_direction = direction
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_qdeleting))
	RegisterSignal(owner, COMSIG_MOB_RESET_PERSPECTIVE, PROC_REF(on_owner_reset_perspective))
	update_container()

/obj/effect/abstract/looking_holder/Destroy(force)
	owner = null
	container = null
	return ..()

/obj/effect/abstract/looking_holder/proc/update_container()
	SIGNAL_HANDLER
	var/atom/movable/new_container = get_atom_on_turf(owner)
	if(new_container == container)
		return
	if(container)
		UnregisterSignal(container, COMSIG_MOVABLE_MOVED)
	if(container != owner)
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	container = new_container
	RegisterSignal(container, COMSIG_MOVABLE_MOVED, PROC_REF(mirror_move))
	if(container != owner)
		RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(update_container))

/obj/effect/abstract/looking_holder/proc/mirror_move(datum/source)
	SIGNAL_HANDLER
	if(!isturf(owner.loc))
		update_container()
	set_glide_size(container.glide_size)
	var/turf/looking_turf = owner.get_looking_turf(look_direction)
	if(!looking_turf)
		owner.end_look()
		return
	abstract_move(looking_turf)

/obj/effect/abstract/looking_holder/proc/on_owner_qdeleting(datum/source)
	SIGNAL_HANDLER
	owner.end_look(reset_view = FALSE)

/// Камера, шкаф или forceMove() забрали глаз - взгляд кончился, но вид не трогаем.
/obj/effect/abstract/looking_holder/proc/on_owner_reset_perspective(datum/source, atom/new_eye)
	SIGNAL_HANDLER
	if(new_eye != src)
		owner.end_look(reset_view = FALSE)

/mob/living/proc/can_look_vertically()
	if(next_move > world.time)
		return FALSE
	if(incapacitated(ignore_restraints = TRUE))
		return FALSE
	return TRUE

/// Переводит глаз на соседний этаж. Повторный вызов в другую сторону только возвращает взгляд.
/mob/living/proc/look_vertically(direction)
	if(looking_vertically == direction)
		return FALSE
	if(looking_vertically)
		end_look()
		return FALSE
	if(!can_look_vertically())
		return FALSE
	changeNext_move(CLICK_CD_LOOK_UP)
	var/turf/looking_turf = get_looking_turf(direction)
	if(!looking_turf)
		return FALSE
	looking_vertically = direction
	looking_holder = new(looking_turf, src, direction)
	reset_perspective(looking_holder)
	return TRUE

/mob/living/proc/end_look(reset_view = TRUE)
	if(!looking_vertically)
		return
	looking_vertically = NONE
	QDEL_NULL(looking_holder)
	if(reset_view)
		reset_perspective()

/// Турф, куда встанет глаз: над дырой в потолке или под дырой в полу - своей, перед мобом или соседней.
/mob/living/proc/get_looking_turf(direction)
	if(!get_turf(src))
		return null
	if(!get_step_multiz(src, direction))
		to_chat(src, span_warning((direction == UP ? "Выше этажей нет." : "Ниже этажей нет.")))
		return null
	var/turf/hole = direction == UP ? get_step_multiz(src, UP) : get_turf(src)
	if(!hole.shows_level_below())
		var/turf/front_hole = get_step(hole, dir)
		if(front_hole?.shows_level_below())
			hole = front_hole
		else
			for(var/turf/neighbour as anything in TURF_NEIGHBORS(hole))
				if(neighbour.shows_level_below())
					hole = neighbour
					break
		if(!hole.shows_level_below())
			to_chat(src, span_warning((direction == UP ? "Сквозь потолок ничего не видно." : "Сквозь пол ничего не видно.")))
			return null
	return direction == UP ? hole : GET_TURF_BELOW(hole)

/mob/living/proc/toggle_look_vertically(direction)
	if(looking_vertically)
		end_look()
		to_chat(src, span_notice("Вы снова смотрите прямо перед собой."))
		return
	if(look_vertically(direction))
		to_chat(src, span_notice((direction == UP ? "Вы смотрите на этаж выше." : "Вы смотрите на этаж ниже.")))

/mob/living/verb/lookup()
	set name = "Look Up"
	set category = "IC.Z Layer Move"

	toggle_look_vertically(UP)

/mob/living/verb/lookdown()
	set name = "Look Down"
	set category = "IC.Z Layer Move"

	toggle_look_vertically(DOWN)
