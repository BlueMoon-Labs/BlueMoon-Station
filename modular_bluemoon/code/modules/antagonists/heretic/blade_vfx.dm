#define HERETIC_BLADE_BACKSTAB_OUTLINE 2
#define HERETIC_BLADE_BACKSTAB_PULSE (0.4 SECONDS)
#define HERETIC_BLADE_REFLEX_FLASH 6
#define HERETIC_BLADE_DANCE_PULSE (0.6 SECONDS)
#define HERETIC_BLADE_TRAIL_DRIFT 4
#define HERETIC_BLADE_CHALLENGE_THREAD (1 SECONDS)
#define HERETIC_BLADE_MARK_LIFT 10
#define HERETIC_BLADE_THROAT_FADE (0.2 SECONDS)
#define HERETIC_BLADE_THROAT_GLINT (1 SECONDS)
#define HERETIC_BLADE_GLINT_VOLUME 25
/// Дуги камертона нарисованы на холсте 16x16 справа от груди; слева их зеркальная копия.
#define HERETIC_BLADE_HUM_SIZE 16
#define HERETIC_BLADE_HUM_SIDE 23
#define HERETIC_BLADE_HUM_HEIGHT 8
#define HERETIC_BLADE_ORBIT_SPIN (3 SECONDS)
#define HERETIC_BLADE_ORBIT_RADIUS 16
#define HERETIC_BLADE_ORBIT_SEGMENTS 24
/// Клинок нарисован на холсте 16x16: сдвиг ставит его центр в центр тайла.
#define HERETIC_BLADE_SPRITE_SHIFT 8
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

/proc/heretic_blade_riposte_sound()
	return pick('modular_bluemoon/sound/heretic/blade_riposte_1.ogg', 'modular_bluemoon/sound/heretic/blade_riposte_2.ogg', 'modular_bluemoon/sound/heretic/blade_riposte_3.ogg')

/// Стойка «Выжидание»: дуга стали на полу перед еретиком поворачивается с ним; задняя половина под ногами, передняя поверх.
/proc/heretic_blade_guard_appearance(atom/offset_spokesman)
	var/list/parts = list()
	for(var/state in list("blade_guard", "blade_guard_front"))
		var/mutable_appearance/part = mutable_appearance('modular_bluemoon/icons/obj/heretic_blade_fx.dmi', state, state == "blade_guard" ? BELOW_MOB_LAYER : ABOVE_MOB_LAYER)
		part.overlays += emissive_appearance(part.icon, "[state]_glow", offset_spokesman = offset_spokesman)
		parts += part
	return parts

/// Хватка со спины: стальная вспышка по контуру, резкий удар и искры от спины цели.
/proc/heretic_blade_backstab_fx(mob/living/user, mob/living/victim)
	var/turf/place = get_turf(victim)
	if(!place)
		return
	heretic_vfx_pulse(victim, heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_BACKSTAB_OUTLINE, HERETIC_BLADE_BACKSTAB_PULSE)
	heretic_vfx_spray(place, /particles/heretic_ascension/blade/sparks, Get_Angle(user, victim))
	new /obj/effect/temp_visual/dir_setting/heretic_slash(get_turf(user), get_dir(user, victim))
	playsound(place, 'modular_bluemoon/sound/heretic/blade_backstab.ogg', HERETIC_BLADE_IMPACT_VOLUME, TRUE)

/// Клинок сам встречает удар: блик в сторону нападающего и звон парирования.
/proc/heretic_blade_reflex_fx(mob/living/source, mob/living/aggressor)
	new /obj/effect/temp_visual/heretic_path_feedback(get_turf(source), "eye_flash", heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_REFLEX_FLASH, get_dir(source, aggressor))
	heretic_vfx_spray(source, /particles/heretic_ascension/blade/sparks, Get_Angle(source, aggressor), HERETIC_BLADE_ORBIT_RADIUS / 2)
	playsound(source, 'modular_bluemoon/sound/heretic/parry.ogg', HERETIC_BLADE_IMPACT_VOLUME, TRUE)

/// Начало Танца граней: клинок описывает круг, по контуру пробегает сталь.
/proc/heretic_blade_dance_start_fx(mob/living/dancer)
	heretic_vfx_pulse(dancer, heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_BACKSTAB_OUTLINE, HERETIC_BLADE_DANCE_PULSE)
	heretic_vfx_burst(dancer, /particles/heretic_ascension/blade/regrow)
	playsound(dancer, 'modular_bluemoon/sound/heretic/blade_dance.ogg', HERETIC_BLADE_IMPACT_VOLUME, TRUE)

/// Шаг в танце оставляет призрака, чуть отставшего от тела: через раз сталь холоднее.
/proc/heretic_blade_dance_step_fx(mob/living/dancer, turf/left_from, movement_dir)
	var/static/step_parity = FALSE
	step_parity = !step_parity
	var/obj/effect/temp_visual/heretic_afterimage/trail = new(left_from, dancer, step_parity ? heretic_path_ink(PATH_BLADE, TRUE) : heretic_path_ink(PATH_BLADE))
	var/shift_x = (movement_dir & EAST) ? -HERETIC_BLADE_TRAIL_DRIFT : ((movement_dir & WEST) ? HERETIC_BLADE_TRAIL_DRIFT : 0)
	var/shift_y = (movement_dir & NORTH) ? -HERETIC_BLADE_TRAIL_DRIFT : ((movement_dir & SOUTH) ? HERETIC_BLADE_TRAIL_DRIFT : 0)
	animate(trail, pixel_x = trail.pixel_x + shift_x, pixel_y = trail.pixel_y + shift_y, time = trail.duration, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)

/// Зов клинка: клинок срывается с пола и по дуге летит в руку, вдоль дуги тают его тени.
/proc/heretic_blade_recall_fx(turf/lying_at, mob/living/user)
	var/turf/hand = get_turf(user)
	if(lying_at && hand && lying_at != hand && lying_at.z == hand.z)
		new /obj/effect/temp_visual/heretic_blade_streak(lying_at, hand, Get_Angle(hand, lying_at), pick(-1, 1))
	heretic_vfx_pulse(user, heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_BACKSTAB_OUTLINE, HERETIC_BLADE_BACKSTAB_PULSE)
	playsound(user, 'modular_bluemoon/sound/heretic/blade_recall.ogg', HERETIC_BLADE_IMPACT_VOLUME, TRUE)

/// Вызов: салют клинком, стальная нить к вызванному и знак скрещённых клинков над ним, пока ждут ответа.
/proc/heretic_blade_challenge_fx(mob/living/user, mob/living/target)
	playsound(user, 'modular_bluemoon/sound/heretic/blade_challenge.ogg', HERETIC_BLADE_IMPACT_VOLUME, TRUE)
	heretic_vfx_pulse(user, heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_BACKSTAB_OUTLINE, HERETIC_BLADE_BACKSTAB_PULSE)
	var/obj/effect/temp_visual/heretic_vfx/thread/thread = heretic_vfx_thread(user, target, heretic_path_ink(PATH_BLADE, TRUE), HERETIC_BLADE_CHALLENGE_THREAD)
	thread?.grow(HERETIC_BLADE_CHALLENGE_THREAD / 2)
	var/obj/effect/abstract/heretic_vfx_attached/mark = heretic_vfx_attach(target, 'modular_bluemoon/icons/obj/heretic_blade_fx.dmi', "duel_mark")
	mark?.pixel_y = HERETIC_BLADE_MARK_LIFT
	return mark

/// Камертон звенит: дуги вибрации расходятся от груди настраивающего в обе стороны.
/obj/effect/temp_visual/heretic_fork_hum
	icon = 'modular_bluemoon/icons/obj/heretic_blade_orbit.dmi'
	icon_state = "fork_hum"
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	pixel_x = HERETIC_BLADE_HUM_SIDE
	pixel_y = HERETIC_BLADE_HUM_HEIGHT

/obj/effect/temp_visual/heretic_fork_hum/Initialize(mapload, lifetime)
	if(!isnull(lifetime))
		duration = lifetime
	. = ..()
	var/mutable_appearance/mirrored = mutable_appearance(icon, icon_state)
	mirrored.transform = matrix(-1, 0, 0, 0, 1, 0)
	mirrored.pixel_x = world.icon_size - 2 * HERETIC_BLADE_HUM_SIDE - HERETIC_BLADE_HUM_SIZE
	add_overlay(mirrored)

/// Тёмный клинок у шеи заложника: лежит вместе с телом и смотрит рукоятью на держащего.
/obj/effect/abstract/heretic_throat_blade
	icon = 'modular_bluemoon/icons/obj/heretic_blade_fx.dmi'
	icon_state = "throat_blade"
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | PIXEL_SCALE | KEEP_APART
	vis_flags = VIS_INHERIT_PLANE
	var/datum/weakref/hostage_ref
	var/datum/weakref/holder_ref
	var/withdrawing = FALSE
	COOLDOWN_DECLARE(glint_cooldown)

/obj/effect/abstract/heretic_throat_blade/Initialize(mapload, mob/living/hostage, mob/living/holder)
	. = ..()
	if(QDELETED(hostage) || QDELETED(holder))
		return INITIALIZE_HINT_QDEL
	hostage_ref = WEAKREF(hostage)
	holder_ref = WEAKREF(holder)
	add_floor_overlay(emissive_appearance(icon, "throat_blade_glow", offset_spokesman = src))
	hostage.add_vis_on_floor(src)
	RegisterSignals(hostage, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_SET_BODY_POSITION), PROC_REF(face_holder))
	RegisterSignal(holder, COMSIG_MOVABLE_MOVED, PROC_REF(face_holder))
	face_holder()
	alpha = 0
	animate(src, alpha = 255, time = HERETIC_BLADE_THROAT_FADE, easing = SINE_EASING | EASE_OUT)
	glint()

/// Рисунок нарисован стоя: на лежащем теле сторона держащего поворачивается вместе с телом.
/obj/effect/abstract/heretic_throat_blade/proc/face_holder()
	SIGNAL_HANDLER
	var/mob/living/hostage = hostage_ref?.resolve()
	var/mob/living/holder = holder_ref?.resolve()
	if(!hostage || !holder || hostage.z != holder.z)
		return
	var/side = get_cardinal_dir(hostage, holder)
	if(side)
		setDir(turn(side, hostage.lying))

/// Попытка растолкать: блик бежит по кромке, клинок вжимается в шею.
/obj/effect/abstract/heretic_throat_blade/proc/glint()
	if(withdrawing || !COOLDOWN_FINISHED(src, glint_cooldown))
		return FALSE
	COOLDOWN_START(src, glint_cooldown, HERETIC_BLADE_THROAT_GLINT)
	flick("throat_blade_glint", src)
	var/mob/living/hostage = hostage_ref?.resolve()
	if(hostage)
		playsound(hostage, 'modular_bluemoon/sound/heretic/blade_feint.ogg', HERETIC_BLADE_GLINT_VOLUME, TRUE, SILENCED_SOUND_EXTRARANGE)
	return TRUE

/obj/effect/abstract/heretic_throat_blade/proc/withdraw()
	if(withdrawing || QDELETED(src))
		return
	withdrawing = TRUE
	release_hosts()
	animate(src, alpha = 0, time = HERETIC_BLADE_THROAT_FADE, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, HERETIC_BLADE_THROAT_FADE)

/obj/effect/abstract/heretic_throat_blade/proc/release_hosts()
	var/mob/living/hostage = hostage_ref?.resolve()
	var/mob/living/holder = holder_ref?.resolve()
	if(hostage)
		UnregisterSignal(hostage, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_SET_BODY_POSITION))
	if(holder)
		UnregisterSignal(holder, COMSIG_MOVABLE_MOVED)
	holder_ref = null

/obj/effect/abstract/heretic_throat_blade/Destroy()
	release_hosts()
	var/mob/living/hostage = hostage_ref?.resolve()
	if(hostage)
		hostage.vis_contents -= src
	hostage_ref = null
	return ..()

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
	playsound(finish, heretic_blade_riposte_sound(), HERETIC_BLADE_IMPACT_VOLUME, TRUE)
	if(shakes)
		heretic_vfx_quake(finish, HERETIC_BLADE_STORM_RANGE, HERETIC_BLADE_STORM_QUAKE, HERETIC_BLADE_STORM_QUAKE_TIME)

/// Сталь раскаляется добела: к каждому каналу прибавляется свет, прозрачность своя.
/proc/heretic_blade_flare_matrix()
	var/static/list/flare = list(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, HERETIC_BLADE_FLARE_LIGHT, HERETIC_BLADE_FLARE_LIGHT, HERETIC_BLADE_FLARE_BLUE, 0)
	return flare.Copy()

/// Место клинка на круге орбиты под углом angle - смещением; остриё по ходу орбиты одной из восьми сторон рисунка.
/proc/heretic_blade_place_on_orbit(atom/movable/blade, angle, shift = HERETIC_BLADE_SPRITE_SHIFT)
	blade.pixel_x = sin(angle) * HERETIC_BLADE_ORBIT_RADIUS + shift
	blade.pixel_y = cos(angle) * HERETIC_BLADE_ORBIT_RADIUS + shift
	blade.dir = angle2dir(angle + 90)

/// Плечо орбиты обходит круг ломаной по смещению и поворачивает клинок по ходу, сам клинок висит на нём дочерним объектом.
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
	steel = new(null, slot, grown)
	add_vis_on_floor(steel)
	circle_orbit()

/// Сторона рисунка меняется в начале отрезка и берётся по касательной в его середине.
/obj/effect/heretic_orbit_blade/proc/circle_orbit()
	var/start = orbit_angle()
	var/step_angle = 360 / HERETIC_BLADE_ORBIT_SEGMENTS
	var/step_time = HERETIC_BLADE_ORBIT_SPIN / HERETIC_BLADE_ORBIT_SEGMENTS
	heretic_blade_place_on_orbit(src, start, 0)
	for(var/index in 1 to HERETIC_BLADE_ORBIT_SEGMENTS)
		var/angle = start + index * step_angle
		var/heading = angle2dir(angle - step_angle / 2 + 90)
		if(index == 1)
			animate(src, pixel_x = sin(angle) * HERETIC_BLADE_ORBIT_RADIUS, pixel_y = cos(angle) * HERETIC_BLADE_ORBIT_RADIUS, dir = heading, time = step_time, loop = -1)
		else
			animate(pixel_x = sin(angle) * HERETIC_BLADE_ORBIT_RADIUS, pixel_y = cos(angle) * HERETIC_BLADE_ORBIT_RADIUS, dir = heading, time = step_time)

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
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER | VIS_INHERIT_DIR
	pixel_x = HERETIC_BLADE_SPRITE_SHIFT
	pixel_y = HERETIC_BLADE_SPRITE_SHIFT

/obj/effect/abstract/heretic_orbit_steel/Initialize(mapload, slot = 0, grown = FALSE)
	. = ..()
	add_overlay(mutable_appearance(icon, "blade_orbit_glint"))
	add_floor_overlay(emissive_appearance(icon, "blade_orbit_glow", alpha = HERETIC_BLADE_EDGE_GLOW, offset_spokesman = src))
	add_floor_overlay(emissive_appearance(icon, "blade_orbit_glint", offset_spokesman = src))
	var/lift_period = HERETIC_BLADE_HOVER_PERIOD + slot * HERETIC_BLADE_HOVER_SPREAD
	var/sway_period = HERETIC_BLADE_SWAY_PERIOD - slot * HERETIC_BLADE_HOVER_SPREAD
	animate(src, pixel_y = HERETIC_BLADE_SPRITE_SHIFT + HERETIC_BLADE_HOVER_LIFT, time = lift_period / 2, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(pixel_y = HERETIC_BLADE_SPRITE_SHIFT - HERETIC_BLADE_HOVER_LIFT, time = lift_period / 2, easing = SINE_EASING)
	animate(src, pixel_x = HERETIC_BLADE_SPRITE_SHIFT + HERETIC_BLADE_HOVER_SWAY, time = sway_period / 2, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(pixel_x = HERETIC_BLADE_SPRITE_SHIFT - HERETIC_BLADE_HOVER_SWAY, time = sway_period / 2, easing = SINE_EASING)
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
	heretic_blade_place_on_orbit(src, angle)
	color = heretic_blade_flare_matrix()
	add_overlay(emissive_appearance(icon, icon_state, offset_spokesman = src))
	animate(src, transform = matrix(HERETIC_BLADE_SHATTER_SCALE, 0, 0, 0, HERETIC_BLADE_SHATTER_SCALE, 0), alpha = 0, time = duration, easing = CUBIC_EASING | EASE_OUT)

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
	heretic_blade_place_on_orbit(src, angle)
	animate(src, pixel_y = pixel_y - HERETIC_BLADE_FADE_DROP, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

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
	pixel_x = end_x + HERETIC_BLADE_SPRITE_SHIFT
	pixel_y = end_y + HERETIC_BLADE_SPRITE_SHIFT
	dir = angle2dir(final_heading)
	transform = matrix(HERETIC_BLADE_STREAK_FLARE, 0, 0, 0, HERETIC_BLADE_STREAK_FLARE, 0)
	color = heretic_blade_flare_matrix()
	add_overlay(emissive_appearance(icon, icon_state, offset_spokesman = src))
	add_filter("streak_blur", 1, motion_blur_filter(sin(final_heading) * HERETIC_BLADE_STREAK_BLUR, cos(final_heading) * HERETIC_BLADE_STREAK_BLUR))
	animate(src, transform = matrix(), color = color_matrix_identity(), time = HERETIC_BLADE_STREAK_SETTLE, easing = SINE_EASING | EASE_OUT)
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
	pixel_x = ghost_x + HERETIC_BLADE_SPRITE_SHIFT
	pixel_y = ghost_y + HERETIC_BLADE_SPRITE_SHIFT
	dir = angle2dir(angle)
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
#undef HERETIC_BLADE_SPRITE_SHIFT
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
#undef HERETIC_BLADE_BACKSTAB_OUTLINE
#undef HERETIC_BLADE_BACKSTAB_PULSE
#undef HERETIC_BLADE_REFLEX_FLASH
#undef HERETIC_BLADE_DANCE_PULSE
#undef HERETIC_BLADE_TRAIL_DRIFT
#undef HERETIC_BLADE_CHALLENGE_THREAD
#undef HERETIC_BLADE_MARK_LIFT
#undef HERETIC_BLADE_THROAT_FADE
#undef HERETIC_BLADE_THROAT_GLINT
#undef HERETIC_BLADE_GLINT_VOLUME
#undef HERETIC_BLADE_HUM_SIZE
#undef HERETIC_BLADE_HUM_SIDE
#undef HERETIC_BLADE_HUM_HEIGHT
