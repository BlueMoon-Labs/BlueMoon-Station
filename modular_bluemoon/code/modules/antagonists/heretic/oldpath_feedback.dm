/// Короткие боевые сигналы; сами эффекты не меняют состояние цели.
/obj/effect/temp_visual/heretic_oldpath
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	icon_state = "cleave"
	duration = 8
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_oldpath/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration)

/obj/effect/temp_visual/heretic_oldpath/ash
	icon_state = "cloud_swirl"
	color = "#ff8b3d"
	duration = 10
	light_range = 2
	light_color = "#ff762e"

/obj/effect/temp_visual/heretic_oldpath/ash/trail
	icon_state = "smoke"
	color = "#b5a38e"
	duration = 15
	layer = BELOW_MOB_LAYER
	light_range = 0

/obj/effect/temp_visual/heretic_oldpath/rust
	icon_state = "sigil_rust"
	duration = 12
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_oldpath/flesh
	icon_state = "cleave"
	color = "#ff4067"

/obj/effect/temp_visual/heretic_oldpath/flesh/mend
	icon_state = "sigil_flesh"
	color = null
	duration = 15
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_oldpath/void
	icon_state = "ring_leader_effect"
	color = "#abedff"
	duration = 15

/obj/effect/temp_visual/heretic_oldpath/void/Initialize(mapload)
	. = ..()
	transform = matrix() * 1.8
	animate(src, transform = matrix() * 0.2, alpha = 0, time = duration)

/// Новые пути различаются силуэтом: лезвия, расколотое зеркало и звёздная вспышка.
/obj/effect/temp_visual/heretic_grasp
	icon = 'modular_bluemoon/icons/obj/heretic_grasp.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	duration = 0.6 SECONDS

/obj/effect/temp_visual/heretic_grasp/blade
	icon_state = "blade_grasp"

/obj/effect/temp_visual/heretic_grasp/blade/Initialize(mapload)
	. = ..()
	var/mutable_appearance/crossing_blade = mutable_appearance(icon, icon_state)
	crossing_blade.transform = matrix(90, MATRIX_ROTATE)
	add_overlay(crossing_blade)
	transform = matrix(-45, MATRIX_ROTATE) * 1.3
	alpha = 230
	animate(src, transform = matrix(20, MATRIX_ROTATE) * 0.4, alpha = 0, time = duration)

/obj/effect/temp_visual/heretic_grasp/moon
	icon_state = "moon_grasp"
	duration = 1.2 SECONDS

/obj/effect/temp_visual/heretic_grasp/moon/Initialize(mapload)
	. = ..()
	color = color_matrix_multiply(color_matrix_saturation(0), color_hex2color_matrix("#d9d5ff"))
	transform = matrix() * 1.35
	animate(src, alpha = 0, time = duration)

/obj/effect/temp_visual/heretic_grasp/cosmic
	icon = 'modular_bluemoon/icons/obj/heretic_grasp_large.dmi'
	icon_state = "cosmic_grasp"
	pixel_x = -16
	pixel_y = -16
	duration = 0.5 SECONDS

/// Край поля лежит внутри затронутой клетки: шаг через него выводит из области.
/obj/effect/heretic_field_edge
	name = "граница Мансуса"
	desc = "Светящийся край области. За его пределами сила печати не действует."
	icon = 'modular_bluemoon/icons/obj/heretic_oldpath_effects.dmi'
	icon_state = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_LIGHTING_LAYER
	alpha = 210
	var/edge_directions

/obj/effect/heretic_field_edge/Initialize(mapload, list/field, tint)
	. = ..()
	color = color_matrix_multiply(color_matrix_saturation(0), color_hex2color_matrix(tint))
	refresh_edges(field)

/obj/effect/heretic_field_edge/proc/refresh_edges(list/field)
	var/new_directions = NONE
	for(var/direction in GLOB.cardinals)
		if(!(get_step(src, direction) in field))
			new_directions |= direction
	if(new_directions == edge_directions)
		return
	edge_directions = new_directions
	// Донор называет край по направлению к центру; здесь показываем сторону выхода.
	var/static/list/edge_states = list("[NORTH]" = "space_protection_south", "[SOUTH]" = "space_protection_north", "[EAST]" = "space_protection_west", "[WEST]" = "space_protection_east")
	cut_overlays()
	for(var/direction in GLOB.cardinals)
		if(edge_directions & direction)
			add_overlay(edge_states["[direction]"])
