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
#define HERETIC_ASH_RING_RADIUS 26
#define HERETIC_ASH_RING_SPIN (2.4 SECONDS)
#define HERETIC_ASH_RING_SEGMENTS 12
#define HERETIC_ASH_RING_FADE (0.4 SECONDS)
#define HERETIC_ASH_MOTE_OFFSET 8
#define HERETIC_ASH_FIELD_RIPPLE (0.08 SECONDS)
#define HERETIC_ASH_FIELD_DIE_DOWN (0.4 SECONDS)
#define HERETIC_ASH_FIELD_EMBERS (0.8 SECONDS)
#define HERETIC_ASH_FIELD_FADE (0.3 SECONDS)
#define HERETIC_ASH_ARC_TIME (0.6 SECONDS)
#define HERETIC_ASH_DRAIN_TIME (1.2 SECONDS)
#define HERETIC_ASH_DRAIN_RANGE 6

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
	playsound(owner, HERETIC_ASH_REKINDLE_SOUND, HERETIC_ASH_FLARE_VOLUME, TRUE)

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
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "ash_lord_aura"
	appearance_flags = RESET_COLOR | PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER | VIS_INHERIT_DIR

/// Погасшее пламя владыки опадает к ногам и тает.
/obj/effect/temp_visual/heretic_ash_quench
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "ash_lord_quench"
	randomdir = FALSE
	appearance_flags = RESET_COLOR | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER
	duration = HERETIC_ASH_QUENCH_TIME

/obj/effect/temp_visual/heretic_ash_quench/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/// Одна клетка огня без атмосферы: поджигает так же, как печать Угасания, но только на своей клетке.
/obj/effect/heretic_combat_zone/ash/lord_trail
	name = "burning footprints"
	desc = "Угли тлеют на полу без всякого топлива и поджигают любого, кто на них встанет. Через несколько секунд гаснут сами."
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "ash_trail_flame"
	layer = BELOW_MOB_LAYER
	appearance_flags = PIXEL_SCALE
	radius = 0
	duration = HERETIC_ASH_TRAIL_DURATION
	applies_slowdown = FALSE
	water_douses = FALSE
	/// Свечение следа по смещению этажа
	var/static/list/trail_glows = list()

/obj/effect/heretic_combat_zone/ash/lord_trail/Initialize(mapload, datum/mind/master)
	. = ..()
	var/offset_key = "[GET_TURF_PLANE_OFFSET(src)]"
	if(!trail_glows[offset_key])
		trail_glows[offset_key] = emissive_appearance('modular_bluemoon/icons/effects/heretic_vfx.dmi', "ash_trail_glow", offset_spokesman = src)
	add_overlay(trail_glows[offset_key])
	alpha = 0
	transform = matrix(HERETIC_ASH_KINDLE_START, 0, 0, 0, HERETIC_ASH_KINDLE_START, 0)
	burn_down()

/// Огонь разгорается и горит почти весь срок, в последние доли секунды опадает до углей; пламя и угли светятся в темноте.
/obj/effect/heretic_combat_zone/ash/lord_trail/proc/burn_down()
	var/rest_alpha = initial(alpha)
	var/hold = max(0, duration - HERETIC_ASH_TRAIL_KINDLE - HERETIC_ASH_TRAIL_DIE_DOWN - HERETIC_ASH_TRAIL_EMBERS)
	animate(src, alpha = rest_alpha, transform = matrix(), icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi', icon_state = "ash_trail_flame", time = HERETIC_ASH_TRAIL_KINDLE, easing = SINE_EASING | EASE_OUT)
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

/obj/effect/heretic_combat_zone/ash
	/// Вода и пена гасят огонь целиком; след вознёсшегося им не поддаётся.
	var/water_douses = TRUE
	/// Клетка поля -> язык огня на ней.
	var/list/field_flames
	var/doused = FALSE

/obj/effect/heretic_combat_zone/ash/Initialize(mapload, datum/mind/master)
	. = ..()
	if(water_douses)
		RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))

/obj/effect/heretic_combat_zone/ash/Destroy()
	for(var/turf/place as anything in field_flames)
		var/obj/effect/heretic_ash_field_flame/flame = field_flames[place]
		flame?.go_out(doused)
	field_flames = null
	return ..()

/obj/effect/heretic_combat_zone/ash/refresh_boundary(list/visible)
	. = ..()
	sync_field_flames()

/// На каждой клетке поля свой огонь: новые клетки загораются, выпавшие гаснут.
/obj/effect/heretic_combat_zone/ash/proc/sync_field_flames()
	LAZYINITLIST(field_flames)
	for(var/turf/place as anything in field_flames.Copy())
		if(place in field_turfs)
			continue
		var/obj/effect/heretic_ash_field_flame/flame = field_flames[place]
		field_flames -= place
		flame?.go_out(FALSE)
	var/lifetime = expires_at ? max(0, expires_at - world.time) : duration
	for(var/turf/place as anything in field_turfs)
		var/obj/effect/heretic_ash_field_flame/flame = field_flames[place]
		if(QDELETED(flame))
			field_flames[place] = new /obj/effect/heretic_ash_field_flame(place, lifetime, max(0, get_dist(place, loc)))

/obj/effect/heretic_combat_zone/ash/style_edge(obj/effect/heretic_field_edge/edge, reused = FALSE)
	. = ..()
	if(water_douses && !reused)
		RegisterSignal(edge, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))

/// Вода или пена на любой клетке гасит весь огонь.
/obj/effect/heretic_combat_zone/ash/proc/on_exposed(atom/source, list/reagents)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water) || istype(reagent, /datum/reagent/firefighting_foam))
			playsound(get_turf(src), 'sound/effects/extinguish.ogg', HERETIC_ASH_HISS_VOLUME, TRUE)
			heretic_vfx_burst(get_turf(src), /particles/heretic_ascension/steam)
			doused = TRUE
			qdel(src)
			return

/datum/eldritch_knowledge/base_ash/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	var/list/door = list("name" = "в пепельный круг", "text" = "Пепел вокруг [victim] смыкается кругом и проваливается.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))
	if(shroud_on(victim))
		door["remote"] = TRUE
	return door

/// Цель в своём саване в 3 клетках или готовая цель на своём огне Угасания рядом; след вознёсшегося владыки дверью не служит.
/datum/eldritch_knowledge/base_ash/proc/door_holds(mob/living/user, mob/living/victim)
	if(!door_user_ready(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z)
		return FALSE
	if(shroud_on(victim))
		return get_dist(user, victim) <= HERETIC_ASH_SHROUD_DOOR_RANGE && can_see(user, victim, HERETIC_ASH_SHROUD_DOOR_RANGE)
	if(get_dist(user, victim) > 1 || !door_zone_under(victim, /obj/effect/heretic_combat_zone/ash))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic.hunt_target_ready(victim)

/// Жар перед каскадом: воздух над владыкой дрожит, затем от него расходится огненная волна с выбросом углей.
/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big/cascade_opening(turf/origin, atom/centre)
	. = ..()
	heretic_ash_heat_shimmer(centre)
	var/mob/living/caster = centre
	if(istype(caster))
		heretic_sky_event_for(caster, /datum/eldritch_knowledge/final_eldritch/ash_final)
	heretic_vfx_shockwave(origin, HERETIC_ASH_INK, HERETIC_ASH_CASCADE_WAVE_RADIUS, HERETIC_ASH_CASCADE_WAVE_TIME)
	heretic_vfx_burst(origin, /particles/heretic_ascension/ash)
	heretic_vfx_flash(origin, LIGHT_COLOR_FIRE, HERETIC_ASH_CASCADE_FLASH_RANGE, HERETIC_ASH_CASCADE_FLASH_POWER)
	heretic_vfx_quake(origin, HERETIC_ASH_CASCADE_RANGE, HERETIC_ASH_CASCADE_QUAKE, HERETIC_ASH_CASCADE_QUAKE_TIME)

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
		for(var/mutable_appearance/mote as anything in list(mutable_appearance('modular_bluemoon/icons/effects/heretic_particles.dmi', "flame_mote"), emissive_appearance('modular_bluemoon/icons/effects/heretic_particles.dmi', "flame_mote", offset_spokesman = src)))
			mote.pixel_x = round(sin(angle) * HERETIC_ASH_RING_RADIUS) + HERETIC_ASH_MOTE_OFFSET
			mote.pixel_y = round(cos(angle) * HERETIC_ASH_RING_RADIUS) + HERETIC_ASH_MOTE_OFFSET
			mote.transform = heading
			add_floor_overlay(mote)
	SpinAnimation(HERETIC_ASH_RING_SPIN, -1, TRUE, HERETIC_ASH_RING_SEGMENTS, parallel = FALSE)
	alpha = 0
	animate(src, alpha = 255, time = HERETIC_ASH_RING_FADE, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)

/obj/effect/abstract/heretic_fire_ring/proc/fade_out()
	animate(src, alpha = 0, time = HERETIC_ASH_RING_FADE, easing = SINE_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
	QDEL_IN(src, HERETIC_ASH_RING_FADE)

/// Язык огня Угасания: разгорается волной от центра, горит почти весь срок и опадает углями.
/obj/effect/heretic_ash_field_flame
	name = "ashen fire"
	desc = "Огонь горит на голом полу без всякого топлива."
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "ash_flame_low"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = BELOW_MOB_LAYER
	appearance_flags = PIXEL_SCALE
	var/going_out = FALSE
	/// Высота языка: animate() сразу ставит конечный стейт углей, поэтому выбор хранится отдельно.
	var/flame_state

/obj/effect/heretic_ash_field_flame/Initialize(mapload, lifetime = HERETIC_ASH_TRAIL_DURATION, ring = 0)
	. = ..()
	flame_state = ring ? "ash_flame_low" : "ash_flame"
	icon_state = flame_state
	add_overlay(emissive_appearance(icon, flame_state, offset_spokesman = src))
	alpha = 0
	transform = matrix(HERETIC_ASH_KINDLE_START, 0, 0, 0, HERETIC_ASH_KINDLE_START, 0)
	var/delay = ring * HERETIC_ASH_FIELD_RIPPLE
	var/hold = max(0, lifetime - delay - HERETIC_ASH_TRAIL_KINDLE - HERETIC_ASH_FIELD_DIE_DOWN - HERETIC_ASH_FIELD_EMBERS)
	animate(src, alpha = 0, time = delay)
	animate(alpha = 255, transform = matrix(), time = HERETIC_ASH_TRAIL_KINDLE, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 255, time = hold)
	animate(alpha = HERETIC_ASH_TRAIL_LOW_ALPHA, transform = matrix(HERETIC_ASH_TRAIL_LOW_SCALE, 0, 0, 0, HERETIC_ASH_TRAIL_LOW_SCALE, -HERETIC_ASH_TRAIL_LOW_SINK), time = HERETIC_ASH_FIELD_DIE_DOWN, easing = SINE_EASING | EASE_IN)
	animate(icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi', icon_state = "ash_embers", alpha = HERETIC_ASH_TRAIL_EMBER_ALPHA, transform = matrix(), time = 0)
	animate(alpha = 0, time = HERETIC_ASH_FIELD_EMBERS, easing = SINE_EASING | EASE_IN)

/// Сбитый водой огонь приседает и тает паром, догоревший просто уходит.
/obj/effect/heretic_ash_field_flame/proc/go_out(quenched)
	if(going_out || QDELETED(src))
		return
	going_out = TRUE
	var/fade = quenched ? HERETIC_ASH_QUENCH_TIME : HERETIC_ASH_FIELD_FADE
	if(quenched)
		animate(src, alpha = 0, transform = matrix(HERETIC_ASH_QUENCH_WIDTH, 0, 0, 0, HERETIC_ASH_QUENCH_HEIGHT, -HERETIC_ASH_QUENCH_SINK), time = fade, easing = SINE_EASING | EASE_IN)
	else
		animate(src, alpha = 0, time = fade, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, fade)

/// Искра Метки перескакивает дугой на соседа; на нём вспыхивают угли.
/proc/heretic_ash_mark_arc(atom/source, atom/target)
	var/turf/start = get_turf(source)
	var/turf/finish = get_turf(target)
	if(!start || !finish || start == finish || start.z != finish.z)
		return null
	if(heretic_vfx_watched(finish))
		heretic_vfx_burst(finish, /particles/heretic_ascension/ash, HERETIC_VFX_BURST_TIME / 2)
	return new /obj/effect/temp_visual/heretic_ash_arc(start, finish)

/// Дуга рисуется вертикально и тянется поворотом от клетки к клетке, как песчаная нить.
/obj/effect/temp_visual/heretic_ash_arc
	icon = 'modular_bluemoon/icons/obj/heretic_ash_fx.dmi'
	icon_state = "ash_arc"
	duration = HERETIC_ASH_ARC_TIME
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE

/obj/effect/temp_visual/heretic_ash_arc/Initialize(mapload, turf/finish)
	. = ..()
	add_overlay(emissive_appearance(icon, "ash_arc_glow", offset_spokesman = src))
	if(!isturf(finish))
		return
	var/span_x = (finish.x - x) * world.icon_size
	var/span_y = (finish.y - y) * world.icon_size
	var/span = sqrt(span_x * span_x + span_y * span_y)
	var/matrix/line = matrix()
	line.Scale(1, span / world.icon_size)
	line.Translate(0, span / 2)
	line.Turn(Get_Angle(loc, finish))
	transform = line

/// Жар уходит от горящего врага к еретику по огненной нити.
/proc/heretic_ash_drain(mob/living/victim, mob/living/user)
	if(QDELETED(victim) || QDELETED(user) || victim.z != user.z)
		return null
	new /obj/effect/temp_visual/heretic_oldpath/ash(get_turf(victim))
	return victim.Beam(user, icon_state = "ash_drain", icon = 'modular_bluemoon/icons/obj/heretic_ash_fx.dmi', time = HERETIC_ASH_DRAIN_TIME, maxdistance = HERETIC_ASH_DRAIN_RANGE)

/// Втянутый жар вспыхивает на еретике языком пламени и светом.
/proc/heretic_ash_rebirth_flare(mob/living/user)
	var/turf/place = get_turf(user)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_ash_flame(place)
	heretic_vfx_flash(place, LIGHT_COLOR_FIRE, HERETIC_ASH_FLARE_RANGE, HERETIC_ASH_FLARE_POWER, HERETIC_ASH_DRAIN_TIME / 2)
	heretic_vfx_pulse(user, HERETIC_ASH_INK, HERETIC_ASH_SHIMMER_SIZE, HERETIC_ASH_DRAIN_TIME / 2)

/datum/sound_effect/heretic_ash_grasp
	key = HERETIC_ASH_GRASP_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/ash_grasp1.ogg',
		'modular_bluemoon/sound/heretic/ash_grasp2.ogg',
		'modular_bluemoon/sound/heretic/ash_grasp3.ogg',
	)

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
#undef HERETIC_ASH_RING_RADIUS
#undef HERETIC_ASH_RING_SPIN
#undef HERETIC_ASH_RING_SEGMENTS
#undef HERETIC_ASH_RING_FADE
#undef HERETIC_ASH_MOTE_OFFSET
#undef HERETIC_ASH_FIELD_RIPPLE
#undef HERETIC_ASH_FIELD_DIE_DOWN
#undef HERETIC_ASH_FIELD_EMBERS
#undef HERETIC_ASH_FIELD_FADE
#undef HERETIC_ASH_ARC_TIME
#undef HERETIC_ASH_DRAIN_TIME
#undef HERETIC_ASH_DRAIN_RANGE
