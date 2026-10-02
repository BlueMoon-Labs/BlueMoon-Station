#define HERETIC_BLADE_ORBIT_SPIN (3 SECONDS)
#define HERETIC_BLADE_ORBIT_RADIUS 16
#define HERETIC_BLADE_ORBIT_SEGMENTS 24
#define HERETIC_BLADE_HOVER_LIFT 2
#define HERETIC_BLADE_HOVER_SWAY 1
#define HERETIC_BLADE_HOVER_PERIOD (1.6 SECONDS)
#define HERETIC_BLADE_SWAY_PERIOD (2.3 SECONDS)
#define HERETIC_BLADE_HOVER_SPREAD (0.2 SECONDS)
#define HERETIC_BLADE_EDGE_GLOW 110
#define HERETIC_BLADE_GROW_START 0.05
#define HERETIC_BLADE_GROW_TIME (0.45 SECONDS)
#define HERETIC_BLADE_FLARE_LIGHT 0.7
#define HERETIC_BLADE_FLARE_BLUE 0.75
#define HERETIC_BLADE_SHATTER_TIME (0.35 SECONDS)
#define HERETIC_BLADE_SHATTER_SCALE 1.6
#define HERETIC_BLADE_FADE_TIME (0.5 SECONDS)
#define HERETIC_BLADE_FADE_DROP 6
#define HERETIC_BLADE_IMPACT_FLASH_RANGE 1
#define HERETIC_BLADE_IMPACT_FLASH_POWER 1.5
#define HERETIC_BLADE_IMPACT_FLASH_TIME (0.2 SECONDS)
#define HERETIC_BLADE_IMPACT_VOLUME 40
#define HERETIC_BLADE_CAST_PULSE_SIZE 2
#define HERETIC_BLADE_CAST_PULSE (0.4 SECONDS)
#define HERETIC_BLADE_STREAK_BEND 12
#define HERETIC_BLADE_STREAK_FLARE 1.3
#define HERETIC_BLADE_STREAK_SETTLE (0.15 SECONDS)
#define HERETIC_BLADE_STREAK_FADE (0.25 SECONDS)
#define HERETIC_BLADE_STREAK_BLUR 2
#define HERETIC_BLADE_STORM_QUAKE 0.1
#define HERETIC_BLADE_STORM_QUAKE_TIME (0.3 SECONDS)
#define HERETIC_BLADE_GHOST_TIME (0.25 SECONDS)
#define HERETIC_BLADE_GHOST_ALPHA 150
#define HERETIC_BLADE_GHOST_MIN_WEIGHT 0.4

/// Разбитый клинок орбиты вспыхивает на своём месте круга, осколки летят в сторону удара.
/proc/heretic_blade_shatter_fx(turf/place, blade_angle, attack_angle)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_blade_shatter(place, blade_angle)
	heretic_vfx_spray(place, /particles/heretic_ascension/blade/shatter, attack_angle, HERETIC_BLADE_ORBIT_RADIUS)

/// Вспышка броска Бури на самом еретике.
/proc/heretic_blade_storm_cast_fx(mob/living/user)
	heretic_vfx_pulse(user, heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_CAST_PULSE_SIZE, HERETIC_BLADE_CAST_PULSE)

/// Удар Бури приходит вместе с уроном: по дуге от орбиты к цели тает след, клинок вонзается в цель с искрами.
/proc/heretic_blade_storm_fx(turf/origin, mob/living/victim, launch_angle, bend = 1, shakes = FALSE)
	var/turf/finish = get_turf(victim)
	if(!origin || !finish)
		return
	new /obj/effect/temp_visual/heretic_blade_streak(origin, finish, launch_angle, bend)
	var/heading = Get_Angle(origin, finish)
	new /obj/effect/temp_visual/dir_setting/heretic_slash(finish, angle2dir(heading))
	heretic_vfx_spray(finish, /particles/heretic_ascension/blade/sparks, heading)
	heretic_vfx_flash(finish, heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_IMPACT_FLASH_RANGE, HERETIC_BLADE_IMPACT_FLASH_POWER, HERETIC_BLADE_IMPACT_FLASH_TIME)
	playsound(finish, 'sound/weapons/bladeslice.ogg', HERETIC_BLADE_IMPACT_VOLUME, TRUE)
	if(shakes)
		heretic_vfx_quake(finish, HERETIC_BLADE_STORM_RANGE, HERETIC_BLADE_STORM_QUAKE, HERETIC_BLADE_STORM_QUAKE_TIME)

/// Сталь раскаляется добела: к каждому каналу прибавляется свет, прозрачность своя.
/proc/heretic_blade_flare_matrix()
	var/static/list/flare = list(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, HERETIC_BLADE_FLARE_LIGHT, HERETIC_BLADE_FLARE_LIGHT, HERETIC_BLADE_FLARE_BLUE, 0)
	return flare.Copy()

/// Рисунок клинка лежит остриём на восток.
/proc/heretic_blade_facing(angle, scale = 1)
	var/matrix/facing = matrix()
	facing.Scale(scale)
	facing.Turn(angle - 90)
	return facing

/// Место клинка на круге орбиты под углом angle.
/proc/heretic_blade_orbit_matrix(angle)
	var/matrix/placement = matrix()
	placement.Translate(0, HERETIC_BLADE_ORBIT_RADIUS)
	placement.Turn(angle)
	return placement

/// Плечо орбиты: только поворот по кругу, сам клинок висит на нём дочерним объектом.
/obj/effect/heretic_orbit_blade
	name = "orbiting blade"
	icon = null
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE
	var/slot = 0
	var/obj/effect/abstract/heretic_orbit_steel/steel

/obj/effect/heretic_orbit_blade/Initialize(mapload, orbit_slot = 0, grown = FALSE)
	. = ..()
	slot = orbit_slot
	transform = heretic_blade_orbit_matrix(orbit_angle())
	SpinAnimation(HERETIC_BLADE_ORBIT_SPIN, -1, TRUE, HERETIC_BLADE_ORBIT_SEGMENTS, parallel = FALSE)
	steel = new(null, slot, grown)
	vis_contents += steel

/// Фаза считается от world.time, поэтому клинки, выросшие в разное время, идут ровным кругом.
/obj/effect/heretic_orbit_blade/proc/orbit_angle()
	return slot * (360 / HERETIC_BLADE_ORBIT_MAX) + 360 * MODULUS(world.time, HERETIC_BLADE_ORBIT_SPIN) / HERETIC_BLADE_ORBIT_SPIN

/obj/effect/heretic_orbit_blade/Destroy()
	vis_contents -= steel
	QDEL_NULL(steel)
	return ..()

/// Клинок на плече орбиты парит со своим периодом, по кромке бежит блик, выросший проступает из точки со вспышкой.
/obj/effect/abstract/heretic_orbit_steel
	icon = 'modular_bluemoon/icons/obj/heretic_blade_orbit.dmi'
	icon_state = "blade_orbit"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER

/obj/effect/abstract/heretic_orbit_steel/Initialize(mapload, slot = 0, grown = FALSE)
	. = ..()
	add_overlay(mutable_appearance(icon, "blade_orbit_glint"))
	add_overlay(emissive_appearance(icon, "blade_orbit_glow", alpha = HERETIC_BLADE_EDGE_GLOW))
	add_overlay(emissive_appearance(icon, "blade_orbit_glint"))
	var/lift_period = HERETIC_BLADE_HOVER_PERIOD + slot * HERETIC_BLADE_HOVER_SPREAD
	var/sway_period = HERETIC_BLADE_SWAY_PERIOD - slot * HERETIC_BLADE_HOVER_SPREAD
	animate(src, pixel_y = HERETIC_BLADE_HOVER_LIFT, time = lift_period / 2, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(pixel_y = -HERETIC_BLADE_HOVER_LIFT, time = lift_period / 2, easing = SINE_EASING)
	animate(src, pixel_x = HERETIC_BLADE_HOVER_SWAY, time = sway_period / 2, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(pixel_x = -HERETIC_BLADE_HOVER_SWAY, time = sway_period / 2, easing = SINE_EASING)
	if(grown)
		materialise()

/obj/effect/abstract/heretic_orbit_steel/proc/materialise()
	transform = matrix(HERETIC_BLADE_GROW_START, 0, 0, 0, HERETIC_BLADE_GROW_START, 0)
	color = heretic_blade_flare_matrix()
	animate(src, transform = matrix(), time = HERETIC_BLADE_GROW_TIME, easing = BACK_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	animate(src, color = color_matrix_identity(), time = HERETIC_BLADE_GROW_TIME * 2, easing = SINE_EASING | EASE_IN, flags = ANIMATION_PARALLEL)

/// Разбитый клинок вспыхивает на своём месте круга и разлетается наружу.
/obj/effect/temp_visual/heretic_blade_shatter
	icon = 'modular_bluemoon/icons/obj/heretic_blade_orbit.dmi'
	icon_state = "blade_orbit"
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_BLADE_SHATTER_TIME

/obj/effect/temp_visual/heretic_blade_shatter/Initialize(mapload, angle = 0)
	. = ..()
	var/matrix/placement = heretic_blade_orbit_matrix(angle)
	transform = placement
	color = heretic_blade_flare_matrix()
	add_overlay(emissive_appearance(icon, icon_state))
	var/matrix/burst = matrix(placement)
	burst.Scale(HERETIC_BLADE_SHATTER_SCALE)
	animate(src, transform = burst, alpha = 0, time = duration, easing = CUBIC_EASING | EASE_OUT)

/// Клинок орбиты мёртвого вознесённого опадает со своего места на круге и тает.
/obj/effect/temp_visual/heretic_blade_fade
	icon = 'modular_bluemoon/icons/obj/heretic_blade_orbit.dmi'
	icon_state = "blade_orbit"
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_BLADE_FADE_TIME

/obj/effect/temp_visual/heretic_blade_fade/Initialize(mapload, angle = 0)
	. = ..()
	var/matrix/placement = heretic_blade_orbit_matrix(angle)
	transform = placement
	var/matrix/fallen = matrix(placement)
	fallen.Translate(0, -HERETIC_BLADE_FADE_DROP)
	animate(src, transform = fallen, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/// Удар Бури уже случился: вдоль дуги тают тени клинка, сам клинок вспыхивает в цели и гаснет.
/obj/effect/temp_visual/heretic_blade_streak
	icon = 'modular_bluemoon/icons/obj/heretic_blade_orbit.dmi'
	icon_state = "blade_orbit"
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_BLADE_STREAK_SETTLE + HERETIC_BLADE_STREAK_FADE

/obj/effect/temp_visual/heretic_blade_streak/Initialize(mapload, turf/finish, start_angle = 0, bend = 1)
	. = ..()
	var/turf/start = get_turf(src)
	if(!start || !finish)
		return
	var/start_x = sin(start_angle) * HERETIC_BLADE_ORBIT_RADIUS
	var/start_y = cos(start_angle) * HERETIC_BLADE_ORBIT_RADIUS
	var/end_x = (finish.x - start.x) * world.icon_size
	var/end_y = (finish.y - start.y) * world.icon_size
	var/heading = Get_Angle(start, finish)
	var/control_x = 2 * ((start_x + end_x) / 2 + cos(heading) * HERETIC_BLADE_STREAK_BEND * bend) - (start_x + end_x) / 2
	var/control_y = 2 * ((start_y + end_y) / 2 - sin(heading) * HERETIC_BLADE_STREAK_BEND * bend) - (start_y + end_y) / 2
	for(var/index in 1 to HERETIC_BLADE_STREAK_GHOSTS)
		var/share = index / (HERETIC_BLADE_STREAK_GHOSTS + 1)
		var/point_x = (1 - share) ** 2 * start_x + 2 * (1 - share) * share * control_x + share ** 2 * end_x
		var/point_y = (1 - share) ** 2 * start_y + 2 * (1 - share) * share * control_y + share ** 2 * end_y
		var/tangent = Get_Pixel_Angle((1 - share) * (control_y - start_y) + share * (end_y - control_y), (1 - share) * (control_x - start_x) + share * (end_x - control_x))
		new /obj/effect/temp_visual/heretic_blade_ghost(start, round(point_x), round(point_y), tangent, share)
	var/final_heading = Get_Pixel_Angle(end_y - control_y, end_x - control_x)
	pixel_x = end_x
	pixel_y = end_y
	transform = heretic_blade_facing(final_heading, HERETIC_BLADE_STREAK_FLARE)
	color = heretic_blade_flare_matrix()
	add_overlay(emissive_appearance(icon, icon_state))
	add_filter("streak_blur", 1, motion_blur_filter(sin(final_heading) * HERETIC_BLADE_STREAK_BLUR, cos(final_heading) * HERETIC_BLADE_STREAK_BLUR))
	animate(src, transform = heretic_blade_facing(final_heading), color = color_matrix_identity(), time = HERETIC_BLADE_STREAK_SETTLE, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 0, time = HERETIC_BLADE_STREAK_FADE, easing = SINE_EASING | EASE_IN)

/// Тень клинка на дуге Бури: ближе к цели ярче и держится дольше, так след читается как полёт.
/obj/effect/temp_visual/heretic_blade_ghost
	icon = 'modular_bluemoon/icons/obj/heretic_blade_orbit.dmi'
	icon_state = "blade_orbit"
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_BLADE_GHOST_TIME

/obj/effect/temp_visual/heretic_blade_ghost/Initialize(mapload, ghost_x = 0, ghost_y = 0, angle = 0, weight = 1)
	duration = HERETIC_BLADE_GHOST_TIME * (HERETIC_BLADE_GHOST_MIN_WEIGHT + (1 - HERETIC_BLADE_GHOST_MIN_WEIGHT) * weight)
	. = ..()
	color = heretic_path_ink(PATH_BLADE, TRUE)
	alpha = HERETIC_BLADE_GHOST_ALPHA * (HERETIC_BLADE_GHOST_MIN_WEIGHT + (1 - HERETIC_BLADE_GHOST_MIN_WEIGHT) * weight)
	pixel_x = ghost_x
	pixel_y = ghost_y
	transform = heretic_blade_facing(angle)
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/// Клинок: осколки разбитого клинка орбиты.
/particles/heretic_ascension/blade/shatter
	icon_state = list("steel_shard" = 3, "steel_glint" = 1)
	count = 10
	spawning = 10
	gravity = list(0, -0.2)
	friction = 0.12
	lifespan = 0.6 SECONDS
	fade = 0.3 SECONDS

/// Клинок: искры удара Бури.
/particles/heretic_ascension/blade/sparks
	icon_state = list("steel_glint" = 3, "steel_shard" = 1)
	count = 10
	spawning = 10
	friction = 0.18
	lifespan = 0.5 SECONDS
	fade = 0.25 SECONDS

/// Клинок: блики у выросшего клинка.
/particles/heretic_ascension/blade/regrow
	icon_state = "steel_glint"
	count = 6
	spawning = 6
	position = generator("circle", 12, 18)
	velocity = generator("circle", 0.5, 1.5)
	friction = 0.1
	lifespan = 0.6 SECONDS
	fade = 0.3 SECONDS
	fadein = 0.1 SECONDS

/// Клинок: алые искры жизни текут от раны к владельцу клинка.
/particles/heretic_ascension/blade/lifesteal
	icon_state = list("blood_wisp_1" = 2, "blood_wisp_2" = 3)
	count = 14
	spawning = 4
	position = generator("circle", 0, 5)
	drift = generator("box", list(-0.4, -0.4, 0), list(0.4, 0.4, 0))
	spin = 0
	grow = -0.03
	lifespan = 0.5 SECONDS
	fade = 0.2 SECONDS
	fadein = 0.1 SECONDS

#undef HERETIC_BLADE_ORBIT_SPIN
#undef HERETIC_BLADE_ORBIT_RADIUS
#undef HERETIC_BLADE_ORBIT_SEGMENTS
#undef HERETIC_BLADE_HOVER_LIFT
#undef HERETIC_BLADE_HOVER_SWAY
#undef HERETIC_BLADE_HOVER_PERIOD
#undef HERETIC_BLADE_SWAY_PERIOD
#undef HERETIC_BLADE_HOVER_SPREAD
#undef HERETIC_BLADE_EDGE_GLOW
#undef HERETIC_BLADE_GROW_START
#undef HERETIC_BLADE_GROW_TIME
#undef HERETIC_BLADE_FLARE_LIGHT
#undef HERETIC_BLADE_FLARE_BLUE
#undef HERETIC_BLADE_SHATTER_TIME
#undef HERETIC_BLADE_SHATTER_SCALE
#undef HERETIC_BLADE_FADE_TIME
#undef HERETIC_BLADE_FADE_DROP
#undef HERETIC_BLADE_IMPACT_FLASH_RANGE
#undef HERETIC_BLADE_IMPACT_FLASH_POWER
#undef HERETIC_BLADE_IMPACT_FLASH_TIME
#undef HERETIC_BLADE_IMPACT_VOLUME
#undef HERETIC_BLADE_CAST_PULSE_SIZE
#undef HERETIC_BLADE_CAST_PULSE
#undef HERETIC_BLADE_STREAK_BEND
#undef HERETIC_BLADE_STREAK_FLARE
#undef HERETIC_BLADE_STREAK_SETTLE
#undef HERETIC_BLADE_STREAK_FADE
#undef HERETIC_BLADE_STREAK_BLUR
#undef HERETIC_BLADE_STORM_QUAKE
#undef HERETIC_BLADE_STORM_QUAKE_TIME
#undef HERETIC_BLADE_GHOST_TIME
#undef HERETIC_BLADE_GHOST_ALPHA
#undef HERETIC_BLADE_GHOST_MIN_WEIGHT
