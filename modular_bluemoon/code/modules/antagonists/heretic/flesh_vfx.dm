#define HERETIC_FLESH_RUPTURE_TIME (0.6 SECONDS)
#define HERETIC_FLESH_CONVULSE_STEPS 5
#define HERETIC_FLESH_CONVULSE_STEP (0.06 SECONDS)
#define HERETIC_FLESH_CONVULSE_SHIFT 2
#define HERETIC_FLESH_CONVULSE_TURN 3
#define HERETIC_FLESH_HUSK_SWELL 1.3
#define HERETIC_FLESH_HUSK_BURST 1.6
#define HERETIC_FLESH_HUSK_BURST_TIME (0.1 SECONDS)
#define HERETIC_FLESH_HUSK_LIFT 0.2
#define HERETIC_FLESH_EMERGE_STEP (0.07 SECONDS)
#define HERETIC_FLESH_EMERGE_TIME (0.3 SECONDS)
#define HERETIC_FLESH_EMERGE_SCALE 0.3
#define HERETIC_FLESH_EMERGE_ALPHA 40
#define HERETIC_FLESH_EMERGE_DEPTH 8
#define HERETIC_FLESH_SHED_QUAKE 0.25
#define HERETIC_FLESH_CONTRACT_TIME (0.35 SECONDS)
#define HERETIC_FLESH_CONTRACT_STEP (0.02 SECONDS)
#define HERETIC_FLESH_CONTRACT_SCALE 0.3
#define HERETIC_FLESH_MEMBRANE_TIME (0.4 SECONDS)
#define HERETIC_FLESH_MEMBRANE_SCALE 1.35
#define HERETIC_FLESH_MEMBRANE_ALPHA 200
#define HERETIC_FLESH_LUNGE_BACK 3
#define HERETIC_FLESH_LUNGE_BITE 6
#define HERETIC_FLESH_LUNGE_REAR (0.35 SECONDS)
#define HERETIC_FLESH_LUNGE_STRIKE (0.12 SECONDS)
#define HERETIC_FLESH_LUNGE_RECOVER (0.25 SECONDS)
#define HERETIC_FLESH_BITE_SPRAY_OFFSET 6
#define HERETIC_FLESH_GULP_WIDE 1.15
#define HERETIC_FLESH_GULP_FLAT 0.88
#define HERETIC_FLESH_GULP_TIME (0.1 SECONDS)
#define HERETIC_FLESH_GULP_SETTLE (0.3 SECONDS)
#define HERETIC_FLESH_SHED_WAVE_RADIUS 4
#define HERETIC_FLESH_SHED_WAVE_TIME (0.8 SECONDS)
#define HERETIC_FLESH_SHED_FLASH_RANGE 3
#define HERETIC_FLESH_SHED_FLASH_POWER 1
#define HERETIC_FLESH_SHED_FLASH_TIME (0.5 SECONDS)
#define HERETIC_FLESH_SHED_QUAKE_RADIUS 7
#define HERETIC_FLESH_EXPEL_FLASH_RANGE 2
#define HERETIC_FLESH_EXPEL_FLASH_POWER 0.8
#define HERETIC_FLESH_EXPEL_FLASH_TIME (0.4 SECONDS)
#define HERETIC_FLESH_GORE_FLASH_RANGE 2
#define HERETIC_FLESH_GORE_FLASH_POWER 0.8
#define HERETIC_FLESH_GORE_FLASH_TIME (0.4 SECONDS)

/mob/living/simple_animal/hostile/eldritch/armsy/prime
	var/datum/weakref/feast_ref
	var/feast_timer

/// Облик и место каждого сегмента, пока червь ещё цел: по ним рисуется его сжатие.
/mob/living/simple_animal/hostile/eldritch/armsy/proc/flesh_shape()
	. = list()
	for(var/mob/living/simple_animal/hostile/eldritch/armsy/segment = src, segment, segment = segment.back)
		var/turf/place = get_turf(segment)
		if(place)
			. += list(list(place, segment.appearance))

/// Сегмент выползает из разорванного тела: снизу, из точки, с задержкой по номеру.
/mob/living/simple_animal/hostile/eldritch/armsy/proc/emerge(order)
	var/matrix/rest = matrix(transform)
	var/matrix/folded = matrix(rest)
	folded.Scale(HERETIC_FLESH_EMERGE_SCALE)
	transform = folded
	alpha = HERETIC_FLESH_EMERGE_ALPHA
	pixel_y = base_pixel_y - HERETIC_FLESH_EMERGE_DEPTH
	animate(src, alpha = HERETIC_FLESH_EMERGE_ALPHA, time = order * HERETIC_FLESH_EMERGE_STEP)
	animate(alpha = 255, transform = rest, pixel_y = base_pixel_y, time = HERETIC_FLESH_EMERGE_TIME, easing = BACK_EASING | EASE_OUT)

/// Тело героя бьётся в судорогах и лопается, из раны сегмент за сегментом выползает червь.
/proc/heretic_flesh_shed_fx(mob/living/simple_animal/hostile/eldritch/armsy/head, human_look)
	var/turf/place = get_turf(head)
	if(!place)
		return
	var/ink = heretic_path_ink(PATH_FLESH)
	var/accent = heretic_path_ink(PATH_FLESH, TRUE)
	if(human_look)
		new /obj/effect/temp_visual/heretic_flesh_husk(place, human_look)
	new /obj/effect/temp_visual/heretic_flesh_rupture(place)
	heretic_vfx_burst(place, /particles/heretic_ascension/flesh/rupture, glow = FALSE)
	heretic_vfx_shockwave(place, ink, HERETIC_FLESH_SHED_WAVE_RADIUS, HERETIC_FLESH_SHED_WAVE_TIME)
	heretic_vfx_flash(place, accent, HERETIC_FLESH_SHED_FLASH_RANGE, HERETIC_FLESH_SHED_FLASH_POWER, HERETIC_FLESH_SHED_FLASH_TIME)
	heretic_vfx_quake(place, HERETIC_FLESH_SHED_QUAKE_RADIUS, HERETIC_FLESH_SHED_QUAKE)
	var/order = 0
	for(var/mob/living/simple_animal/hostile/eldritch/armsy/segment = head, segment, segment = segment.back)
		segment.emerge(order++)

/// Червь стягивается к голове и выплёвывает тело героя вместе с кровью и ошмётками.
/proc/heretic_flesh_expel_fx(mob/living/body, list/shape)
	var/turf/place = get_turf(body)
	if(!place)
		return
	var/accent = heretic_path_ink(PATH_FLESH, TRUE)
	var/order = 0
	for(var/list/part as anything in shape)
		new /obj/effect/temp_visual/heretic_flesh_husk/segment(part[1], part[2], place, order++)
	new /obj/effect/temp_visual/heretic_flesh_husk/membrane(place, body.appearance)
	heretic_vfx_burst(place, /particles/heretic_ascension/flesh/rupture, glow = FALSE)
	heretic_vfx_flash(place, accent, HERETIC_FLESH_EXPEL_FLASH_RANGE, HERETIC_FLESH_EXPEL_FLASH_POWER, HERETIC_FLESH_EXPEL_FLASH_TIME)
	heretic_vfx_pulse(body, accent)

/// Голова вгрызается в труп: отводится назад и бьёт, каждый укус выбивает кровь.
/mob/living/simple_animal/hostile/eldritch/armsy/prime/proc/start_feast(datum/weakref/corpse_ref)
	var/mob/living/carbon/human/corpse = corpse_ref?.resolve()
	if(!feeding || QDELETED(corpse))
		return
	feast_ref = corpse_ref
	deltimer(feast_timer)
	var/lunge = get_dir(src, corpse)
	var/dx = (lunge & EAST) ? 1 : (lunge & WEST) ? -1 : 0
	var/dy = (lunge & NORTH) ? 1 : (lunge & SOUTH) ? -1 : 0
	animate(src, pixel_x = base_pixel_x - dx * HERETIC_FLESH_LUNGE_BACK, pixel_y = base_pixel_y - dy * HERETIC_FLESH_LUNGE_BACK, time = HERETIC_FLESH_LUNGE_REAR, easing = SINE_EASING | EASE_OUT, loop = -1)
	animate(pixel_x = base_pixel_x + dx * HERETIC_FLESH_LUNGE_BITE, pixel_y = base_pixel_y + dy * HERETIC_FLESH_LUNGE_BITE, time = HERETIC_FLESH_LUNGE_STRIKE, easing = QUAD_EASING | EASE_IN)
	animate(pixel_x = base_pixel_x, pixel_y = base_pixel_y, time = HERETIC_FLESH_LUNGE_RECOVER, easing = SINE_EASING | EASE_OUT)
	feast_timer = addtimer(CALLBACK(src, PROC_REF(feast_bite)), HERETIC_FLESH_LUNGE_REAR + HERETIC_FLESH_LUNGE_STRIKE, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/eldritch/armsy/prime/proc/feast_bite()
	feast_timer = null
	var/mob/living/carbon/human/corpse = feast_ref?.resolve()
	if(!feeding || QDELETED(corpse))
		return
	heretic_vfx_spray(corpse, /particles/heretic_ascension/flesh/feast, Get_Angle(src, corpse), HERETIC_FLESH_BITE_SPRAY_OFFSET, glow = FALSE)
	feast_timer = addtimer(CALLBACK(src, PROC_REF(feast_bite)), HERETIC_FLESH_LUNGE_REAR + HERETIC_FLESH_LUNGE_STRIKE + HERETIC_FLESH_LUNGE_RECOVER, TIMER_STOPPABLE)

/// Трапеза кончилась: рывки встают, голова возвращается на место.
/mob/living/simple_animal/hostile/eldritch/armsy/prime/proc/stop_feast()
	deltimer(feast_timer)
	feast_timer = null
	feast_ref = null
	animate(src, pixel_x = base_pixel_x, pixel_y = base_pixel_y, time = HERETIC_FLESH_LUNGE_RECOVER, easing = SINE_EASING | EASE_OUT)

/// Доеденный труп разлетается кровавыми ошмётками, червь глотает.
/mob/living/simple_animal/hostile/eldritch/armsy/prime/proc/feast_gulp(turf/gore_spot)
	if(!gore_spot)
		return
	var/accent = heretic_path_ink(PATH_FLESH, TRUE)
	heretic_vfx_burst(gore_spot, /particles/heretic_ascension/flesh/gore, glow = FALSE)
	heretic_vfx_flash(gore_spot, accent, HERETIC_FLESH_GORE_FLASH_RANGE, HERETIC_FLESH_GORE_FLASH_POWER, HERETIC_FLESH_GORE_FLASH_TIME)
	heretic_vfx_pulse(src, accent)
	var/matrix/rest = matrix(transform)
	var/matrix/gulp = matrix(rest)
	gulp.Scale(HERETIC_FLESH_GULP_WIDE, HERETIC_FLESH_GULP_FLAT)
	animate(src, transform = gulp, time = HERETIC_FLESH_GULP_TIME, easing = QUAD_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	animate(transform = rest, time = HERETIC_FLESH_GULP_SETTLE, easing = ELASTIC_EASING)

/mob/living/simple_animal/hostile/eldritch/armsy/prime/Destroy()
	deltimer(feast_timer)
	feast_ref = null
	return ..()

/// Разрыв плоти поверх груди: кривое вздутие лопается рваной раной, из неё торчат рёбра и тянутся жилы, бьёт кровь; мясо не светится.
/obj/effect/temp_visual/heretic_flesh_rupture
	icon = 'modular_bluemoon/icons/obj/heretic_flesh_effects.dmi'
	icon_state = "flesh_rupture"
	duration = HERETIC_FLESH_RUPTURE_TIME
	randomdir = FALSE
	pixel_x = -16
	pixel_y = -16
	layer = ABOVE_MOB_LAYER

/// Снимок тела героя: бьётся в судорогах, наливается кровью, раздувается и лопается.
/obj/effect/temp_visual/heretic_flesh_husk
	randomdir = FALSE
	duration = HERETIC_FLESH_CONVULSE_STEPS * HERETIC_FLESH_CONVULSE_STEP + HERETIC_FLESH_HUSK_BURST_TIME

/obj/effect/temp_visual/heretic_flesh_husk/Initialize(mapload, look)
	if(look)
		appearance = look
		render_target = null
		filters = null
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	density = FALSE
	. = ..()
	if(!look)
		return INITIALIZE_HINT_QDEL
	animate_husk()

/obj/effect/temp_visual/heretic_flesh_husk/proc/animate_husk()
	var/list/meat = heretic_vfx_ink_tint(heretic_path_ink(PATH_FLESH, TRUE), HERETIC_FLESH_HUSK_LIFT)
	var/matrix/rest = matrix(transform)
	var/rest_x = pixel_x
	for(var/step in 1 to HERETIC_FLESH_CONVULSE_STEPS)
		var/share = step / HERETIC_FLESH_CONVULSE_STEPS
		var/side = step % 2 ? 1 : -1
		var/matrix/twist = matrix(rest)
		twist.Scale(1 + (HERETIC_FLESH_HUSK_SWELL - 1) * share, 1 + (HERETIC_FLESH_HUSK_SWELL - 1) * share / 2)
		twist.Turn(side * HERETIC_FLESH_CONVULSE_TURN * step)
		if(step == 1)
			animate(src, transform = twist, pixel_x = rest_x + side * HERETIC_FLESH_CONVULSE_SHIFT, color = meat, time = HERETIC_FLESH_CONVULSE_STEP, easing = QUAD_EASING | EASE_OUT)
		else
			animate(transform = twist, pixel_x = rest_x + side * HERETIC_FLESH_CONVULSE_SHIFT, time = HERETIC_FLESH_CONVULSE_STEP, easing = QUAD_EASING | EASE_OUT)
	var/matrix/burst = matrix(rest)
	burst.Scale(HERETIC_FLESH_HUSK_BURST)
	animate(transform = burst, pixel_x = rest_x, alpha = 0, time = HERETIC_FLESH_HUSK_BURST_TIME, easing = CUBIC_EASING | EASE_OUT)

/// Снимок сегмента втягивается в голову и сжимается.
/obj/effect/temp_visual/heretic_flesh_husk/segment
	duration = HERETIC_FLESH_CONTRACT_TIME
	var/turf/head_turf
	var/order = 0

/obj/effect/temp_visual/heretic_flesh_husk/segment/Initialize(mapload, look, turf/head, segment_order = 0)
	head_turf = head
	order = segment_order
	duration = HERETIC_FLESH_CONTRACT_TIME + order * HERETIC_FLESH_CONTRACT_STEP
	return ..()

/obj/effect/temp_visual/heretic_flesh_husk/segment/animate_husk()
	var/matrix/shrunk = matrix(transform)
	shrunk.Scale(HERETIC_FLESH_CONTRACT_SCALE)
	var/shift_x = head_turf ? (head_turf.x - x) * world.icon_size : 0
	var/shift_y = head_turf ? (head_turf.y - y) * world.icon_size : 0
	head_turf = null
	animate(src, pixel_x = pixel_x + shift_x, pixel_y = pixel_y + shift_y, transform = shrunk, alpha = 0, time = duration, easing = QUAD_EASING | EASE_IN)

/// Кровавая плёнка слезает с выплюнутого тела и расползается.
/obj/effect/temp_visual/heretic_flesh_husk/membrane
	duration = HERETIC_FLESH_MEMBRANE_TIME

/obj/effect/temp_visual/heretic_flesh_husk/membrane/animate_husk()
	layer = ABOVE_MOB_LAYER
	color = heretic_vfx_ink_tint(heretic_path_ink(PATH_FLESH, TRUE), HERETIC_FLESH_HUSK_LIFT)
	alpha = HERETIC_FLESH_MEMBRANE_ALPHA
	var/matrix/spread = matrix(transform)
	spread.Scale(HERETIC_FLESH_MEMBRANE_SCALE)
	animate(src, transform = spread, alpha = 0, time = duration, easing = CUBIC_EASING | EASE_OUT)

/// Плоть: тело лопается мясом и кровью.
/particles/heretic_ascension/flesh/rupture
	icon_state = list("flesh_bit_1" = 2, "flesh_bit_2" = 3, "blood_drop_1" = 3, "blood_drop_2" = 2)
	count = 30
	velocity = generator("circle", 5, 9)
	gravity = list(0, -0.5)

/// Плоть: укус выбивает из трупа струйку крови.
/particles/heretic_ascension/flesh/feast
	icon_state = list("blood_drop_1" = 3, "blood_drop_2" = 2, "flesh_bit_2" = 1)
	count = 12
	spawning = 6
	gravity = list(0, -0.45)
	lifespan = 0.8 SECONDS
	fade = 0.3 SECONDS

/// Плоть: доеденный труп разлетается ошмётками вверх и в стороны.
/particles/heretic_ascension/flesh/gore
	icon_state = list("flesh_bit_1" = 3, "flesh_bit_2" = 2, "blood_drop_1" = 3, "blood_drop_2" = 2)
	count = 30
	velocity = generator("box", list(-6, 2, 0), list(6, 9, 0))
	gravity = list(0, -0.55)
	lifespan = 1.4 SECONDS

#undef HERETIC_FLESH_RUPTURE_TIME
#undef HERETIC_FLESH_CONVULSE_STEPS
#undef HERETIC_FLESH_CONVULSE_STEP
#undef HERETIC_FLESH_CONVULSE_SHIFT
#undef HERETIC_FLESH_CONVULSE_TURN
#undef HERETIC_FLESH_HUSK_SWELL
#undef HERETIC_FLESH_HUSK_BURST
#undef HERETIC_FLESH_HUSK_BURST_TIME
#undef HERETIC_FLESH_HUSK_LIFT
#undef HERETIC_FLESH_EMERGE_STEP
#undef HERETIC_FLESH_EMERGE_TIME
#undef HERETIC_FLESH_EMERGE_SCALE
#undef HERETIC_FLESH_EMERGE_ALPHA
#undef HERETIC_FLESH_EMERGE_DEPTH
#undef HERETIC_FLESH_SHED_QUAKE
#undef HERETIC_FLESH_CONTRACT_TIME
#undef HERETIC_FLESH_CONTRACT_STEP
#undef HERETIC_FLESH_CONTRACT_SCALE
#undef HERETIC_FLESH_MEMBRANE_TIME
#undef HERETIC_FLESH_MEMBRANE_SCALE
#undef HERETIC_FLESH_MEMBRANE_ALPHA
#undef HERETIC_FLESH_LUNGE_BACK
#undef HERETIC_FLESH_LUNGE_BITE
#undef HERETIC_FLESH_LUNGE_REAR
#undef HERETIC_FLESH_LUNGE_STRIKE
#undef HERETIC_FLESH_LUNGE_RECOVER
#undef HERETIC_FLESH_BITE_SPRAY_OFFSET
#undef HERETIC_FLESH_GULP_WIDE
#undef HERETIC_FLESH_GULP_FLAT
#undef HERETIC_FLESH_GULP_TIME
#undef HERETIC_FLESH_GULP_SETTLE
#undef HERETIC_FLESH_SHED_WAVE_RADIUS
#undef HERETIC_FLESH_SHED_WAVE_TIME
#undef HERETIC_FLESH_SHED_FLASH_RANGE
#undef HERETIC_FLESH_SHED_FLASH_POWER
#undef HERETIC_FLESH_SHED_FLASH_TIME
#undef HERETIC_FLESH_SHED_QUAKE_RADIUS
#undef HERETIC_FLESH_EXPEL_FLASH_RANGE
#undef HERETIC_FLESH_EXPEL_FLASH_POWER
#undef HERETIC_FLESH_EXPEL_FLASH_TIME
#undef HERETIC_FLESH_GORE_FLASH_RANGE
#undef HERETIC_FLESH_GORE_FLASH_POWER
#undef HERETIC_FLESH_GORE_FLASH_TIME
