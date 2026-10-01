/// Короткие вспышки не перекрывают взаимодействие с предметами и не обрабатываются подсистемой.
/obj/effect/temp_visual/heretic_spell
	icon = 'modular_bluemoon/icons/obj/heretic_spell_effects.dmi'
	icon_state = "cosmic_explosion"
	pixel_x = -16
	pixel_y = -16
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	duration = 1.2 SECONDS

/obj/effect/temp_visual/heretic_spell/star_step
	icon_state = "space_explosion"

/obj/effect/temp_visual/heretic_spell/domain
	icon = 'modular_bluemoon/icons/obj/heretic_domain.dmi'
	icon_state = "cosmic_domain"
	pixel_x = -64
	pixel_y = -64
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_spell/moon
	icon_state = "circle_wave"
	color = "#c6d6ff"
	alpha = 180
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_spell/moon/Initialize(mapload)
	. = ..()
	transform = matrix() * 0.25
	animate(src, transform = matrix() * 2.5, alpha = 0, time = duration, easing = SINE_EASING)

/// Дуга центрируется на атакующем: её край проходит через соседнюю клетку цели.
#define HERETIC_SLASH_SCALE 1
#define HERETIC_SLASH_ANGLE 135
#define HERETIC_SLASH_REVERSE_ANGLE 225

/obj/effect/temp_visual/dir_setting/heretic_slash
	icon = 'modular_bluemoon/icons/obj/heretic_slashes.dmi'
	icon_state = "left_swing"
	color = "#d9c8ff"
	alpha = 190
	duration = 0.6 SECONDS
	pixel_x = -32
	pixel_y = -32
	appearance_flags = PIXEL_SCALE

/obj/effect/temp_visual/dir_setting/heretic_slash/Initialize(mapload, set_dir, reverse = FALSE)
	if(reverse)
		icon_state = "right_swing"
	. = ..()
	var/matrix/swing = matrix()
	swing.Scale(reverse ? -HERETIC_SLASH_SCALE : HERETIC_SLASH_SCALE, HERETIC_SLASH_SCALE)
	swing.Turn(dir2angle(set_dir) - (reverse ? HERETIC_SLASH_REVERSE_ANGLE : HERETIC_SLASH_ANGLE))
	transform = swing
	flick(icon_state, src)

#undef HERETIC_SLASH_SCALE
#undef HERETIC_SLASH_ANGLE
#undef HERETIC_SLASH_REVERSE_ANGLE

/// Лучи привязаны к исходным клеткам и исчезают после короткого рывка Пустоты.
/obj/effect/ebeam/heretic_void
	layer = BELOW_MOB_LAYER
	alpha = 180

/// Начертание руны (смола растекается 8 секунд, знак пути проступает в конце) или свет обряда поверх готовой руны.
/obj/effect/temp_visual/heretic_ritual
	icon = 'modular_bluemoon/icons/obj/heretic_rune_visuals.dmi'
	icon_state = HERETIC_RUNE_VISUAL_RITUAL
	randomdir = FALSE
	layer = SIGIL_LAYER
	alpha = 200
	duration = 8 SECONDS
	pixel_x = -32
	pixel_y = -32
	var/visual_path
	var/erasing = FALSE
	/// Завершённое начертание не стирается: на его месте сразу появляется руна.
	var/finished = FALSE
	/// Состояние знака пути поверх смолы (`_draw`, `_erase`) или null, пока знака нет.
	var/inscription_state
	var/inscription_timer

/obj/effect/temp_visual/heretic_ritual/Initialize(mapload, path_id, lifetime, visual_state, atom/movable/source)
	visual_path = path_id
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(path)
		color = path.book_ink
	if(visual_state)
		icon_state = visual_state
	if(!isnull(lifetime))
		duration = lifetime
	if(source)
		transform = source.transform
	. = ..()
	// Как и основной круг, его временные знаки не видны кремниевым.
	var/image/silicon_image = image(icon = icon, icon_state = null, loc = src)
	silicon_image.override = TRUE
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/silicons, "heretic_ritual", silicon_image)
	if(icon_state == HERETIC_RUNE_VISUAL_TRACE && path)
		inscription_timer = addtimer(CALLBACK(src, PROC_REF(show_inscription), "[path.rune_inscription]_draw"), HERETIC_RUNE_INSCRIBE_DELAY, TIMER_STOPPABLE)

/obj/effect/temp_visual/heretic_ritual/Destroy()
	deltimer(inscription_timer)
	if(!erasing && !finished && isturf(loc))
		var/ending = icon_state == HERETIC_RUNE_VISUAL_TRACE ? HERETIC_RUNE_VISUAL_SCATTER : HERETIC_RUNE_VISUAL_RELEASE
		new /obj/effect/temp_visual/heretic_ritual/erase(loc, visual_path, null, ending, src)
	return ..()

/obj/effect/temp_visual/heretic_ritual/proc/show_inscription(state)
	inscription_state = state
	update_appearance(UPDATE_OVERLAYS)

/obj/effect/temp_visual/heretic_ritual/update_overlays()
	. = ..()
	if(inscription_state)
		var/datum/heretic_path/path = GLOB.heretic_paths[visual_path]
		. += heretic_rune_inscription_overlay(inscription_state, path.rune_inscription_icon)

/obj/effect/temp_visual/heretic_ritual/proc/finish()
	finished = TRUE
	qdel(src)

/obj/effect/temp_visual/heretic_ritual/erase
	erasing = TRUE
	duration = HERETIC_RUNE_ERASE_TIME

/obj/effect/temp_visual/heretic_ritual/erase/Initialize(mapload, path_id, lifetime, visual_state, atom/movable/source)
	if(visual_state == HERETIC_RUNE_VISUAL_RELEASE)
		lifetime = HERETIC_RUNE_RELEASE_TIME
	else if(visual_state == HERETIC_RUNE_VISUAL_SCATTER)
		lifetime = HERETIC_RUNE_SCATTER_TIME
	. = ..(mapload, path_id, lifetime, visual_state, source)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(visual_state == HERETIC_RUNE_VISUAL_ERASE && path)
		show_inscription("[path.rune_inscription]_erase")

/// Срабатывание обряда: знак пути вспыхивает над руной и расходится кольцом.
/obj/effect/temp_visual/heretic_cast
	icon = 'modular_bluemoon/icons/obj/ritual_casts.dmi'
	icon_state = "ash_pyre_cast"
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
	duration = HERETIC_RUNE_CAST_TIME
	pixel_x = -32
	pixel_y = -32

/obj/effect/temp_visual/heretic_cast/Initialize(mapload, path_id, atom/movable/source)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(path)
		icon = path.rune_cast_icon
		icon_state = "[path.rune_inscription]_cast"
	if(source)
		transform = source.transform
	return ..()
