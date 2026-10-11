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
	duration = 10
	light_range = 2
	light_color = "#ff762e"

/obj/effect/temp_visual/heretic_oldpath/ash/trail
	icon_state = "smoke"
	duration = 15
	layer = BELOW_MOB_LAYER
	light_range = 0

/obj/effect/temp_visual/heretic_ash_flame
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "ash_flame"
	duration = 0.6 SECONDS
	randomdir = FALSE

#define HERETIC_ASH_FLAME_RISE (0.12 SECONDS)
#define HERETIC_ASH_FLAME_FALL (0.25 SECONDS)
#define HERETIC_ASH_FLAME_BUD_WIDTH 0.5
#define HERETIC_ASH_FLAME_BUD_HEIGHT 0.3
#define HERETIC_ASH_FLAME_BUD_SINK 10
#define HERETIC_ASH_FLAME_EBB_WIDTH 0.8
#define HERETIC_ASH_FLAME_EBB_HEIGHT 0.5
#define HERETIC_ASH_FLAME_EBB_SINK 8

/// Язык огня вырастает из пола, горит и опадает, а не мигает целиком.
/obj/effect/temp_visual/heretic_ash_flame/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state, offset_spokesman = src))
	alpha = 0
	transform = matrix(HERETIC_ASH_FLAME_BUD_WIDTH, 0, 0, 0, HERETIC_ASH_FLAME_BUD_HEIGHT, -HERETIC_ASH_FLAME_BUD_SINK)
	animate(src, alpha = 255, transform = matrix(), time = HERETIC_ASH_FLAME_RISE, easing = CUBIC_EASING | EASE_OUT)
	animate(alpha = 255, time = duration - HERETIC_ASH_FLAME_RISE - HERETIC_ASH_FLAME_FALL)
	animate(alpha = 0, transform = matrix(HERETIC_ASH_FLAME_EBB_WIDTH, 0, 0, 0, HERETIC_ASH_FLAME_EBB_HEIGHT, -HERETIC_ASH_FLAME_EBB_SINK), time = HERETIC_ASH_FLAME_FALL, easing = SINE_EASING | EASE_IN)

#undef HERETIC_ASH_FLAME_RISE
#undef HERETIC_ASH_FLAME_FALL
#undef HERETIC_ASH_FLAME_BUD_WIDTH
#undef HERETIC_ASH_FLAME_BUD_HEIGHT
#undef HERETIC_ASH_FLAME_BUD_SINK
#undef HERETIC_ASH_FLAME_EBB_WIDTH
#undef HERETIC_ASH_FLAME_EBB_HEIGHT
#undef HERETIC_ASH_FLAME_EBB_SINK

/obj/effect/temp_visual/heretic_oldpath/rust
	icon = 'modular_bluemoon/icons/obj/heretic_rust_fx.dmi'
	icon_state = "rust_bloom"
	duration = 10
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_oldpath/flesh
	icon_state = "flesh_rend"

/obj/effect/temp_visual/heretic_oldpath/flesh/mend
	icon = 'modular_bluemoon/icons/obj/heretic_oldpath_effects.dmi'
	icon_state = "flesh_mend"
	color = null
	duration = 15
	layer = BELOW_MOB_LAYER

#define HERETIC_VOID_GRASP_HOLD (0.8 SECONDS)
#define HERETIC_VOID_GRASP_FADE (0.3 SECONDS)

/// Ледяная звезда прорастает, обрастает инеем и раскалывается; рисунок в родном пикселе, без масштаба.
/obj/effect/temp_visual/heretic_oldpath/void
	icon_state = "void_grasp"
	duration = HERETIC_VOID_GRASP_HOLD + HERETIC_VOID_GRASP_FADE
	light_range = 1
	light_color = "#abedff"

/obj/effect/temp_visual/heretic_oldpath/void/Initialize(mapload)
	. = ..()
	animate(src, alpha = 255, time = HERETIC_VOID_GRASP_HOLD)
	animate(alpha = 0, time = HERETIC_VOID_GRASP_FADE, easing = SINE_EASING | EASE_IN)

#undef HERETIC_VOID_GRASP_HOLD
#undef HERETIC_VOID_GRASP_FADE

GLOBAL_LIST_INIT(heretic_void_mark_burst_sounds, list(
	'modular_bluemoon/sound/heretic/void_mark_burst_1.ogg',
	'modular_bluemoon/sound/heretic/void_mark_burst_2.ogg',
))

/// Взрыв метки старого пути: свой рисунок у каждого пути, не повторяет вспышку хватки.
/obj/effect/temp_visual/heretic_mark_burst
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_mark_burst/ash
	icon_state = "ash_mark_burst"
	light_range = 2
	light_color = "#ff762e"

/obj/effect/temp_visual/heretic_mark_burst/rust
	icon_state = "rust_mark_burst"

/obj/effect/temp_visual/heretic_mark_burst/flesh
	icon_state = "flesh_mark_burst"

/obj/effect/temp_visual/heretic_mark_burst/void
	icon_state = "void_mark_burst"
	light_range = 1
	light_color = "#abedff"

/// Новые пути различаются силуэтом: лезвия, расколотое зеркало и звёздная вспышка.
/obj/effect/temp_visual/heretic_grasp
	icon = 'modular_bluemoon/icons/obj/heretic_grasp.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	duration = 0.6 SECONDS

/obj/effect/temp_visual/heretic_grasp/blade
	icon_state = "blade_grasp"

/obj/effect/temp_visual/heretic_grasp/moon
	icon_state = "moon_grasp"
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_grasp/cosmic
	icon = 'modular_bluemoon/icons/obj/heretic_grasp_large.dmi'
	icon_state = "cosmic_grasp"
	pixel_x = -16
	pixel_y = -16
	duration = 1.2 SECONDS

/// Край поля лежит внутри затронутой клетки: шаг через него выводит из области.
/obj/effect/heretic_field_edge
	name = "Mansus boundary"
	desc = "Светящийся край области. За его пределами сила печати не действует."
	icon = 'modular_bluemoon/icons/obj/heretic_oldpath_effects.dmi'
	icon_state = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
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
			add_overlay(emissive_appearance(icon, edge_states["[direction]"], offset_spokesman = src))
