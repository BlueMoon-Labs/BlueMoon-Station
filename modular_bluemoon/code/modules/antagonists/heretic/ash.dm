#define HERETIC_ASH_EMBER_RATE 0.4
#define HERETIC_ASH_SMOKE_RATE 0.2
#define HERETIC_ASH_KINDLE_START 0.3
#define HERETIC_ASH_FLARE_SCALE 1.25
#define HERETIC_ASH_FLARE_RISE (0.2 SECONDS)
#define HERETIC_ASH_FLARE_SETTLE (0.4 SECONDS)
#define HERETIC_ASH_FLARE_RANGE 2
#define HERETIC_ASH_FLARE_POWER 1.5
#define HERETIC_ASH_FLARE_TIME (0.3 SECONDS)
#define HERETIC_ASH_FLARE_VOLUME 35
#define HERETIC_ASH_HISS_VOLUME 50
#define HERETIC_ASH_QUENCH_TIME (0.5 SECONDS)
#define HERETIC_ASH_QUENCH_WIDTH 0.6
#define HERETIC_ASH_QUENCH_HEIGHT 0.2
#define HERETIC_ASH_QUENCH_SINK 10
#define HERETIC_ASH_TRAIL_KINDLE (0.25 SECONDS)
#define HERETIC_ASH_TRAIL_DIE_DOWN (0.15 SECONDS)
#define HERETIC_ASH_TRAIL_EMBERS (0.2 SECONDS)
#define HERETIC_ASH_TRAIL_LOW_SCALE 0.7
#define HERETIC_ASH_TRAIL_LOW_SINK 4
#define HERETIC_ASH_TRAIL_EMBER_ALPHA 230
#define HERETIC_ASH_TRAIL_LOW_ALPHA 70
#define HERETIC_ASH_INK heretic_path_ink(PATH_ASH)
#define HERETIC_ASH_SHIMMER_FILTER "heretic_ash_shimmer"
#define HERETIC_ASH_SHIMMER_TIME (0.3 SECONDS)
#define HERETIC_ASH_SHIMMER_SIZE 2
#define HERETIC_ASH_SHIMMER_WAVELENGTH 6
#define HERETIC_ASH_CASCADE_WAVE_RADIUS 3
#define HERETIC_ASH_CASCADE_WAVE_TIME (0.6 SECONDS)
#define HERETIC_ASH_CASCADE_FLASH_RANGE 4
#define HERETIC_ASH_CASCADE_FLASH_POWER 2
#define HERETIC_ASH_CASCADE_QUAKE 0.12
#define HERETIC_ASH_CASCADE_QUAKE_TIME (0.3 SECONDS)
#define HERETIC_ASH_CASCADE_VOLUME 60
#define HERETIC_ASH_RING_RADIUS 26
#define HERETIC_ASH_RING_SPIN (2.4 SECONDS)
#define HERETIC_ASH_RING_SEGMENTS 12
#define HERETIC_ASH_RING_FADE (0.4 SECONDS)
#define HERETIC_ASH_MOTE_OFFSET 8

/datum/eldritch_knowledge/final_eldritch/ash_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	user.AddComponent(/datum/component/heretic_ash_lord)

/datum/eldritch_knowledge/final_eldritch/ash_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_ash_lord))
	return ..()

/// Пепельный владыка: пока сух, горит, лечится в собственном пламени и оставляет огненный след.
/datum/component/heretic_ash_lord
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/effect/heretic_ash_aura/aura
	var/obj/effect/abstract/heretic_particle_holder/embers
	var/obj/effect/abstract/heretic_particle_holder/smoke
	var/obj/effect/dummy/lighting_obj/moblight/glow
	var/wet_until = 0
	var/burning = FALSE

/datum/component/heretic_ash_lord/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	aura = new
	embers = heretic_vfx_attach_particles(parent, /particles/heretic_ascension/ash/lord_embers)
	smoke = heretic_vfx_attach_particles(parent, /particles/heretic_ascension/ash/lord_smoke, FALSE)
	update_flame()

/datum/component/heretic_ash_lord/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_ash_lord/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_LIFE, COMSIG_PARENT_EXAMINE))

/datum/component/heretic_ash_lord/Destroy()
	var/atom/movable/owner = parent
	owner.vis_contents -= aura
	var/turf/place = get_turf(owner)
	if(burning && place)
		new /obj/effect/temp_visual/heretic_ash_quench(place)
	heretic_vfx_release_particles(owner, embers)
	heretic_vfx_release_particles(owner, smoke)
	embers = null
	smoke = null
	QDEL_NULL(aura)
	QDEL_NULL(glow)
	return ..()

/// Вода уводит fire_stacks ниже нуля, а Life сушит их за тик, поэтому намокание держится отдельным сроком.
/datum/component/heretic_ash_lord/proc/is_wet()
	var/mob/living/owner = parent
	if(owner.fire_stacks < 0)
		wet_until = world.time + HERETIC_ASH_WET_DURATION
	return world.time < wet_until

/datum/component/heretic_ash_lord/proc/update_flame()
	var/mob/living/owner = parent
	var/lit = !is_wet() && owner.stat != DEAD
	if(lit != burning)
		burning = lit
		if(lit)
			kindle()
		else
			quench()
	if(lit)
		if(!(aura in owner.vis_contents))
			owner.vis_contents += aura
		if(QDELETED(glow))
			glow = new(owner, LIGHT_COLOR_FIRE, LIGHT_RANGE_FIRE)
		return TRUE
	owner.vis_contents -= aura
	QDEL_NULL(glow)
	return FALSE

/// Пламя разгорается из искры со вспышкой и выбросом углей.
/datum/component/heretic_ash_lord/proc/kindle()
	var/mob/living/owner = parent
	set_smouldering(TRUE)
	aura.alpha = 0
	aura.transform = matrix(HERETIC_ASH_KINDLE_START, 0, 0, 0, HERETIC_ASH_KINDLE_START, 0)
	animate(aura, alpha = 255, transform = matrix(HERETIC_ASH_FLARE_SCALE, 0, 0, 0, HERETIC_ASH_FLARE_SCALE, 0), time = HERETIC_ASH_FLARE_RISE, easing = CUBIC_EASING | EASE_OUT)
	animate(transform = matrix(), time = HERETIC_ASH_FLARE_SETTLE, easing = SINE_EASING)
	heretic_vfx_burst(owner, /particles/heretic_ascension/ash)
	heretic_vfx_flash(owner, LIGHT_COLOR_FIRE, HERETIC_ASH_FLARE_RANGE, HERETIC_ASH_FLARE_POWER, HERETIC_ASH_FLARE_TIME)
	playsound(owner, 'modular_bluemoon/sound/heretic/ash_burst.ogg', HERETIC_ASH_FLARE_VOLUME, TRUE)

/// Сбитое водой пламя шипит паром и опадает к ногам; сам нимб огня уходит сразу.
/datum/component/heretic_ash_lord/proc/quench()
	var/mob/living/owner = parent
	set_smouldering(FALSE)
	owner.vis_contents += new /obj/effect/temp_visual/heretic_ash_quench(null)
	if(owner.stat == DEAD)
		return
	heretic_vfx_burst(owner, /particles/heretic_ascension/steam)
	playsound(owner, 'sound/effects/extinguish.ogg', HERETIC_ASH_HISS_VOLUME, TRUE)

/datum/component/heretic_ash_lord/proc/set_smouldering(active)
	if(embers?.particles)
		embers.particles.spawning = active ? HERETIC_ASH_EMBER_RATE : 0
	if(smoke?.particles)
		smoke.particles.spawning = active ? HERETIC_ASH_SMOKE_RATE : 0

/datum/component/heretic_ash_lord/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(!update_flame())
		return
	var/turf/left = old_loc
	if(!isopenturf(left) || isgroundlessturf(left))
		return
	var/obj/effect/heretic_combat_zone/ash/lord_trail/trail = locate() in left
	if(trail)
		trail.rekindle()
		return
	new /obj/effect/heretic_combat_zone/ash/lord_trail(left, source.mind)

/datum/component/heretic_ash_lord/proc/on_life(mob/living/source, seconds, times_fired)
	SIGNAL_HANDLER
	if(update_flame())
		heretic_heal_damage(source, 0, HERETIC_ASH_LORD_HEAL)

/datum/component/heretic_ash_lord/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(is_wet())
		examine_list += span_notice("Пламя на теле сбито водой и ненадолго погасло.")
	else
		examine_list += span_warning("Тело объято колдовским пламенем, за каждым шагом остаётся огненный след. Вода собьёт этот огонь на несколько секунд.")

/obj/effect/heretic_ash_aura
	name = "ashen flame"
	icon = 'icons/mob/OnFire.dmi'
	icon_state = "Standing"
	appearance_flags = RESET_COLOR | PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER

/// Погасшее пламя владыки опадает к ногам и тает.
/obj/effect/temp_visual/heretic_ash_quench
	icon = 'icons/mob/OnFire.dmi'
	icon_state = "Standing"
	randomdir = FALSE
	appearance_flags = RESET_COLOR | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER
	duration = HERETIC_ASH_QUENCH_TIME

/obj/effect/temp_visual/heretic_ash_quench/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, transform = matrix(HERETIC_ASH_QUENCH_WIDTH, 0, 0, 0, HERETIC_ASH_QUENCH_HEIGHT, -HERETIC_ASH_QUENCH_SINK), time = duration, easing = SINE_EASING | EASE_IN)

/// Одна клетка огня без атмосферы: поджигает так же, как печать Угасания, но только на своей клетке.
/obj/effect/heretic_combat_zone/ash/lord_trail
	name = "burning footprints"
	desc = "Угли тлеют на полу без всякого топлива и поджигают любого, кто на них встанет. Через несколько секунд гаснут сами."
	icon = 'icons/effects/turf_fire.dmi'
	icon_state = "red_small"
	layer = BELOW_MOB_LAYER
	appearance_flags = PIXEL_SCALE
	radius = 0
	duration = HERETIC_ASH_TRAIL_DURATION
	applies_slowdown = FALSE
	var/static/mutable_appearance/trail_glow

/obj/effect/heretic_combat_zone/ash/lord_trail/Initialize(mapload, datum/mind/master)
	. = ..()
	if(!trail_glow)
		trail_glow = emissive_appearance('modular_bluemoon/icons/effects/heretic_vfx.dmi', "ash_trail_glow")
	add_overlay(trail_glow)
	alpha = 0
	transform = matrix(HERETIC_ASH_KINDLE_START, 0, 0, 0, HERETIC_ASH_KINDLE_START, 0)
	burn_down()

/// Огонь разгорается и горит почти весь срок, в последние доли секунды опадает до углей; пламя и угли светятся в темноте.
/obj/effect/heretic_combat_zone/ash/lord_trail/proc/burn_down()
	var/rest_alpha = initial(alpha)
	var/hold = max(0, duration - HERETIC_ASH_TRAIL_KINDLE - HERETIC_ASH_TRAIL_DIE_DOWN - HERETIC_ASH_TRAIL_EMBERS)
	animate(src, alpha = rest_alpha, transform = matrix(), icon = 'icons/effects/turf_fire.dmi', icon_state = "red_small", time = HERETIC_ASH_TRAIL_KINDLE, easing = SINE_EASING | EASE_OUT)
	animate(alpha = rest_alpha, time = hold)
	animate(alpha = HERETIC_ASH_TRAIL_LOW_ALPHA, transform = matrix(HERETIC_ASH_TRAIL_LOW_SCALE, 0, 0, 0, HERETIC_ASH_TRAIL_LOW_SCALE, -HERETIC_ASH_TRAIL_LOW_SINK), time = HERETIC_ASH_TRAIL_DIE_DOWN, easing = SINE_EASING | EASE_IN)
	animate(icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi', icon_state = "ash_embers", alpha = HERETIC_ASH_TRAIL_EMBER_ALPHA, transform = matrix(), time = 0)
	animate(alpha = 0, time = HERETIC_ASH_TRAIL_EMBERS, easing = SINE_EASING | EASE_IN)

/obj/effect/heretic_combat_zone/ash/lord_trail/refresh_boundary(list/visible)
	field_turfs = isopenturf(loc) ? list(loc) : list()

/obj/effect/heretic_combat_zone/ash/lord_trail/process()
	var/datum/mind/master = master_mind?.resolve()
	var/mob/living/user = master?.current
	if(QDELETED(user) || user.stat == DEAD || !IS_HERETIC(user))
		qdel(src)
		return
	var/list/victims = list()
	for(var/mob/living/victim in loc)
		victims += victim
	if(length(victims))
		tick_zone(user, victims)

/obj/effect/heretic_combat_zone/ash/lord_trail/proc/rekindle()
	deltimer(expiry_timer)
	expires_at = world.time + duration
	expiry_timer = QDEL_IN_STOPPABLE(src, duration)
	burn_down()

/// Жар перед каскадом: воздух над владыкой дрожит, затем от него расходится огненная волна с выбросом углей.
/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big/cascade_opening(turf/origin, atom/centre)
	. = ..()
	heretic_ash_heat_shimmer(centre)
	heretic_vfx_shockwave(origin, HERETIC_ASH_INK, HERETIC_ASH_CASCADE_WAVE_RADIUS, HERETIC_ASH_CASCADE_WAVE_TIME)
	heretic_vfx_burst(origin, /particles/heretic_ascension/ash)
	heretic_vfx_flash(origin, LIGHT_COLOR_FIRE, HERETIC_ASH_CASCADE_FLASH_RANGE, HERETIC_ASH_CASCADE_FLASH_POWER)
	heretic_vfx_quake(origin, HERETIC_ASH_CASCADE_RANGE, HERETIC_ASH_CASCADE_QUAKE, HERETIC_ASH_CASCADE_QUAKE_TIME)
	playsound(origin, 'modular_bluemoon/sound/heretic/ash_burst.ogg', HERETIC_ASH_CASCADE_VOLUME, TRUE)

/// Марево жара: волна по фигуре набегает и спадает, затем фильтр снимается.
/proc/heretic_ash_heat_shimmer(atom/target)
	if(QDELETED(target))
		return FALSE
	target.add_filter(HERETIC_ASH_SHIMMER_FILTER, 1, wave_filter(x = HERETIC_ASH_SHIMMER_WAVELENGTH, size = 0))
	var/shimmer = target.get_filter(HERETIC_ASH_SHIMMER_FILTER)
	animate(shimmer, size = HERETIC_ASH_SHIMMER_SIZE, offset = 1, time = HERETIC_ASH_SHIMMER_TIME / 2, easing = SINE_EASING | EASE_OUT)
	animate(size = 0, offset = 2, time = HERETIC_ASH_SHIMMER_TIME / 2, easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(target, TYPE_PROC_REF(/atom, remove_filter), HERETIC_ASH_SHIMMER_FILTER), HERETIC_ASH_SHIMMER_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)
	return TRUE

/// Кольцо Клятвы огня: огненные кометы кружат вокруг владыки, хвостом по ходу вращения.
/obj/effect/abstract/heretic_fire_ring
	icon = null
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE

/obj/effect/abstract/heretic_fire_ring/Initialize(mapload)
	. = ..()
	for(var/index in 1 to HERETIC_ASH_RING_MOTES)
		var/angle = index * 360 / HERETIC_ASH_RING_MOTES
		var/matrix/heading = matrix()
		heading.Turn(angle)
		for(var/mutable_appearance/mote as anything in list(mutable_appearance('modular_bluemoon/icons/effects/heretic_particles.dmi', "flame_mote"), emissive_appearance('modular_bluemoon/icons/effects/heretic_particles.dmi', "flame_mote")))
			mote.pixel_x = round(sin(angle) * HERETIC_ASH_RING_RADIUS) + HERETIC_ASH_MOTE_OFFSET
			mote.pixel_y = round(cos(angle) * HERETIC_ASH_RING_RADIUS) + HERETIC_ASH_MOTE_OFFSET
			mote.transform = heading
			add_overlay(mote)
	SpinAnimation(HERETIC_ASH_RING_SPIN, -1, TRUE, HERETIC_ASH_RING_SEGMENTS, parallel = FALSE)
	alpha = 0
	animate(src, alpha = 255, time = HERETIC_ASH_RING_FADE, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)

/obj/effect/abstract/heretic_fire_ring/proc/fade_out()
	animate(src, alpha = 0, time = HERETIC_ASH_RING_FADE, easing = SINE_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
	QDEL_IN(src, HERETIC_ASH_RING_FADE)

/// Пепел: угли, взлетающие от горящего владыки.
/particles/heretic_ascension/ash/lord_embers
	count = 12
	spawning = HERETIC_ASH_EMBER_RATE
	position = generator("box", list(-9, -12, 0), list(9, 6, 0))
	velocity = generator("box", list(-0.3, 0.4, 0), list(0.3, 1.2, 0))
	gravity = list(0, 0.12)
	friction = 0.02
	lifespan = 1.4 SECONDS
	fade = 0.6 SECONDS
	fadein = 0.1 SECONDS

/// Пепел: редкий дым над пламенем владыки.
/particles/heretic_ascension/ash/lord_smoke
	icon_state = list("smoke_1" = 2, "smoke_2" = 2, "smoke_3" = 1)
	count = 6
	spawning = HERETIC_ASH_SMOKE_RATE
	position = generator("box", list(-6, 4, 0), list(6, 12, 0))
	velocity = generator("box", list(-0.2, 0.5, 0), list(0.2, 0.9, 0))
	gravity = list(0, 0.05)
	drift = generator("box", list(-0.15, 0, 0), list(0.15, 0, 0))
	grow = 0.02
	lifespan = 1.6 SECONDS
	fade = 1 SECONDS
	fadein = 0.3 SECONDS

/// Пар над сбитым водой пламенем.
/particles/heretic_ascension/steam
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("steam_1" = 3, "steam_2" = 2, "steam_3" = 1)
	count = 14
	spawning = 7
	position = generator("box", list(-8, -10, 0), list(8, 6, 0))
	velocity = generator("box", list(-1, 0.5, 0), list(1, 2, 0))
	gravity = list(0, 0.15)
	friction = 0.08
	grow = 0.03
	lifespan = 1.2 SECONDS
	fade = 0.7 SECONDS
	fadein = 0.1 SECONDS

#undef HERETIC_ASH_EMBER_RATE
#undef HERETIC_ASH_SMOKE_RATE
#undef HERETIC_ASH_KINDLE_START
#undef HERETIC_ASH_FLARE_SCALE
#undef HERETIC_ASH_FLARE_RISE
#undef HERETIC_ASH_FLARE_SETTLE
#undef HERETIC_ASH_FLARE_RANGE
#undef HERETIC_ASH_FLARE_POWER
#undef HERETIC_ASH_FLARE_TIME
#undef HERETIC_ASH_FLARE_VOLUME
#undef HERETIC_ASH_HISS_VOLUME
#undef HERETIC_ASH_QUENCH_TIME
#undef HERETIC_ASH_QUENCH_WIDTH
#undef HERETIC_ASH_QUENCH_HEIGHT
#undef HERETIC_ASH_QUENCH_SINK
#undef HERETIC_ASH_TRAIL_KINDLE
#undef HERETIC_ASH_TRAIL_DIE_DOWN
#undef HERETIC_ASH_TRAIL_EMBERS
#undef HERETIC_ASH_TRAIL_LOW_SCALE
#undef HERETIC_ASH_TRAIL_LOW_SINK
#undef HERETIC_ASH_TRAIL_EMBER_ALPHA
#undef HERETIC_ASH_TRAIL_LOW_ALPHA
#undef HERETIC_ASH_INK
#undef HERETIC_ASH_SHIMMER_FILTER
#undef HERETIC_ASH_SHIMMER_TIME
#undef HERETIC_ASH_SHIMMER_SIZE
#undef HERETIC_ASH_SHIMMER_WAVELENGTH
#undef HERETIC_ASH_CASCADE_WAVE_RADIUS
#undef HERETIC_ASH_CASCADE_WAVE_TIME
#undef HERETIC_ASH_CASCADE_FLASH_RANGE
#undef HERETIC_ASH_CASCADE_FLASH_POWER
#undef HERETIC_ASH_CASCADE_QUAKE
#undef HERETIC_ASH_CASCADE_QUAKE_TIME
#undef HERETIC_ASH_CASCADE_VOLUME
#undef HERETIC_ASH_RING_RADIUS
#undef HERETIC_ASH_RING_SPIN
#undef HERETIC_ASH_RING_SEGMENTS
#undef HERETIC_ASH_RING_FADE
#undef HERETIC_ASH_MOTE_OFFSET
