/// Короткие вспышки не перекрывают взаимодействие с предметами и не обрабатываются подсистемой.
/obj/effect/temp_visual/heretic_spell
	icon = 'modular_bluemoon/icons/obj/heretic_spell_effects.dmi'
	icon_state = "cosmic_explosion"
	pixel_x = -16
	pixel_y = -16
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	duration = 0.5 SECONDS

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
#define HERETIC_SLASH_SCALE 3
#define HERETIC_SLASH_ANGLE 135
#define HERETIC_SLASH_REVERSE_ANGLE 225

/obj/effect/temp_visual/dir_setting/heretic_slash
	icon = 'modular_bluemoon/icons/obj/heretic_slashes.dmi'
	icon_state = "left_swing"
	color = "#d9c8ff"
	alpha = 190
	duration = 0.6 SECONDS
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

/// Во время обряда знак прорисовывается, затем остаётся до завершения или отмены.
/obj/effect/temp_visual/heretic_ritual
	icon = 'modular_bluemoon/icons/obj/heretic_rituals.dmi'
	icon_state = "fullrune-1"
	randomdir = FALSE
	layer = SIGIL_LAYER
	alpha = 190
	duration = 8 SECONDS
	appearance_flags = PIXEL_SCALE
	var/visual_path
	var/erasing = FALSE

/obj/effect/temp_visual/heretic_ritual/Initialize(mapload, path_id, lifetime)
	visual_path = path_id
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(path)
		color = path.book_ink
	if(path_id == PATH_FLESH || path_id == PATH_MOON || path_id == PATH_COSMIC || path_id == PATH_TIDE)
		icon_state = "fullrune-2"
	if(!isnull(lifetime))
		duration = lifetime
	transform = matrix() * HERETIC_RUNE_SCALE
	. = ..()
	// Как и основной круг, его временные знаки не видны кремниевым.
	var/image/silicon_image = image(icon = icon, icon_state = null, loc = src)
	silicon_image.override = TRUE
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/silicons, "heretic_ritual", silicon_image)
	flick("[icon_state]-[erasing ? "erase" : "write"]", src)

/obj/effect/temp_visual/heretic_ritual/Destroy()
	if(!erasing && isturf(loc))
		new /obj/effect/temp_visual/heretic_ritual/erase(loc, visual_path)
	return ..()

/obj/effect/temp_visual/heretic_ritual/erase
	erasing = TRUE
	duration = 1.9 SECONDS
