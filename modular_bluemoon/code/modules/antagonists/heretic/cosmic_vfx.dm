#define HERETIC_STARGAZER_CENTER_Y 32
#define HERETIC_STARGAZER_HAND_X 9
#define HERETIC_STARGAZER_HAND_Y 68
#define HERETIC_STARGAZER_RIFT_TIME (1.1 SECONDS)
#define HERETIC_STARGAZER_ASSEMBLE_DELAY (0.25 SECONDS)
#define HERETIC_STARGAZER_ASSEMBLE_TIME (0.7 SECONDS)
#define HERETIC_STARGAZER_ASSEMBLE_SCALE 0.35
#define HERETIC_STARGAZER_GATHER_RADIUS 72
#define HERETIC_STARGAZER_GATHER_TRAVEL (0.7 SECONDS)
#define HERETIC_STARGAZER_GATHER_EMIT (0.3 SECONDS)
#define HERETIC_STARGAZER_GATHER_ARMS 8
#define HERETIC_STARGAZER_GATHER_SWIRL 0.8
#define HERETIC_STARGAZER_ARRIVAL_QUAKE 0.2
#define HERETIC_STARGAZER_CHARGE_TIME (0.2 SECONDS)
#define HERETIC_STARGAZER_CHARGE_HOLD (0.6 SECONDS)
#define HERETIC_STARGAZER_CHARGE_SEED 0.4
#define HERETIC_STARGAZER_FLARE_TIME (0.25 SECONDS)
#define HERETIC_STARGAZER_FLARE_SCALE 1.8
#define HERETIC_STARGAZER_BEAM_CORE "#f4ecff"
#define HERETIC_STARGAZER_BEAM_TIME (0.4 SECONDS)
#define HERETIC_STARGAZER_SWELL 1.12
#define HERETIC_STARGAZER_SWELL_TIME (0.15 SECONDS)
#define HERETIC_STARGAZER_SHRINK 0.15
#define HERETIC_STARGAZER_SHRINK_TURN 90
#define HERETIC_STARGAZER_SCATTER_SHARE 0.7
#define HERETIC_STARGAZER_LEASH_FADE (0.4 SECONDS)
#define HERETIC_COSMIC_TWINKLE_TIME (0.6 SECONDS)
#define HERETIC_STARGAZER_ASSEMBLE_ALPHA 25
#define HERETIC_STARGAZER_ARRIVAL_WAVE_RADIUS 4
#define HERETIC_STARGAZER_ARRIVAL_WAVE_TIME (0.8 SECONDS)
#define HERETIC_STARGAZER_ARRIVAL_FLASH_RANGE 4
#define HERETIC_STARGAZER_ARRIVAL_FLASH_POWER 2
#define HERETIC_STARGAZER_ARRIVAL_FLASH_TIME (0.6 SECONDS)
#define HERETIC_STARGAZER_ARRIVAL_QUAKE_RADIUS 7
#define HERETIC_STARGAZER_SCATTER_WAVE_RADIUS 3
#define HERETIC_STARGAZER_SCATTER_WAVE_TIME (0.8 SECONDS)
#define HERETIC_STARGAZER_SCATTER_FLASH_RANGE 3
#define HERETIC_STARGAZER_SCATTER_FLASH_POWER 2
#define HERETIC_STARGAZER_SCATTER_FLASH_TIME (0.5 SECONDS)
#define HERETIC_STARGAZER_IMPACT_FLASH_RANGE 2
#define HERETIC_STARGAZER_IMPACT_FLASH_POWER 1
#define HERETIC_STARGAZER_IMPACT_FLASH_TIME (0.3 SECONDS)
#define HERETIC_STARGAZER_REMNANT_TIME (1 SECONDS)
#define HERETIC_COSMIC_TWINKLE_FLASH_RANGE 1
#define HERETIC_COSMIC_TWINKLE_FLASH_POWER 1
#define HERETIC_COSMIC_TWINKLE_FLASH_TIME (0.3 SECONDS)

/mob/living/simple_animal/heretic_stargazer
	/// Звезда в поднятой руке, пока копится свет для луча.
	var/obj/effect/abstract/heretic_vfx_attached/hand_glow
	var/charge_timer

/// Звездочёт выходит из разрыва: прореха раскрывается, звёзды сходятся к нему, и он проступает из них.
/mob/living/simple_animal/heretic_stargazer/proc/arrive(mob/living/summoner)
	var/turf/place = get_turf(src)
	if(!place)
		return
	var/ink = heretic_path_ink(PATH_COSMIC)
	var/accent = heretic_path_ink(PATH_COSMIC, TRUE)
	new /obj/effect/temp_visual/heretic_stargazer_rift(place)
	var/obj/effect/temp_visual/heretic_vfx/converge/stars = heretic_vfx_converge(place, /particles/heretic_ascension/cosmic, HERETIC_STARGAZER_GATHER_RADIUS, HERETIC_STARGAZER_GATHER_TRAVEL, HERETIC_STARGAZER_GATHER_EMIT, HERETIC_STARGAZER_GATHER_ARMS, HERETIC_STARGAZER_GATHER_SWIRL)
	if(stars)
		stars.pixel_y = HERETIC_STARGAZER_CENTER_Y
	var/matrix/rest = matrix(transform)
	var/matrix/seed = matrix(rest)
	seed.Scale(HERETIC_STARGAZER_ASSEMBLE_SCALE)
	var/rest_alpha = alpha
	transform = seed
	alpha = HERETIC_STARGAZER_ASSEMBLE_ALPHA
	animate(src, alpha = HERETIC_STARGAZER_ASSEMBLE_ALPHA, time = HERETIC_STARGAZER_ASSEMBLE_DELAY)
	animate(alpha = rest_alpha, transform = rest, time = HERETIC_STARGAZER_ASSEMBLE_TIME, easing = CUBIC_EASING | EASE_OUT)
	heretic_vfx_rays(src, accent, HERETIC_STARGAZER_ASSEMBLE_DELAY + HERETIC_STARGAZER_ASSEMBLE_TIME)
	heretic_vfx_shockwave(place, ink, HERETIC_STARGAZER_ARRIVAL_WAVE_RADIUS, HERETIC_STARGAZER_ARRIVAL_WAVE_TIME)
	heretic_vfx_flash(place, accent, HERETIC_STARGAZER_ARRIVAL_FLASH_RANGE, HERETIC_STARGAZER_ARRIVAL_FLASH_POWER, HERETIC_STARGAZER_ARRIVAL_FLASH_TIME)
	heretic_vfx_quake(place, HERETIC_STARGAZER_ARRIVAL_QUAKE_RADIUS, HERETIC_STARGAZER_ARRIVAL_QUAKE)
	if(summoner)
		heretic_vfx_pulse(summoner, ink)

/// Луч выйдет на ближайшем такте обработки: звезда в руке начинает копить свет за долю секунды до него.
/mob/living/simple_animal/heretic_stargazer/proc/plan_charge()
	var/left = COOLDOWN_TIMELEFT(src, beam_cooldown)
	if(charge_timer || left <= 0 || left > SSprocessing.wait || !heretic_vfx_watched(src))
		return FALSE
	charge_timer = addtimer(CALLBACK(src, PROC_REF(start_charge)), max(world.tick_lag, SSprocessing.wait - HERETIC_STARGAZER_CHARGE_TIME), TIMER_STOPPABLE)
	return TRUE

/mob/living/simple_animal/heretic_stargazer/proc/start_charge()
	charge_timer = null
	if(stat != CONSCIOUS || !QDELETED(hand_glow))
		return
	hand_glow = attach_hand_star(HERETIC_STARGAZER_CHARGE_TIME)
	if(!hand_glow)
		return
	var/matrix/seed = matrix()
	seed.Scale(HERETIC_STARGAZER_CHARGE_SEED)
	hand_glow.transform = seed
	animate(hand_glow, transform = matrix(), time = HERETIC_STARGAZER_CHARGE_TIME, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	addtimer(CALLBACK(src, PROC_REF(drop_charge)), HERETIC_STARGAZER_CHARGE_TIME + HERETIC_STARGAZER_CHARGE_HOLD)

/mob/living/simple_animal/heretic_stargazer/proc/attach_hand_star(fade_in)
	var/obj/effect/abstract/heretic_vfx_attached/star = heretic_vfx_attach(src, 'modular_bluemoon/icons/effects/heretic_vfx.dmi', "stargazer_charge", 255, fade_in, TRUE, FALSE)
	if(star)
		star.pixel_x = HERETIC_STARGAZER_HAND_X
		star.pixel_y = HERETIC_STARGAZER_HAND_Y
	return star

/// Луч так и не вышел: накопленный свет гаснет.
/mob/living/simple_animal/heretic_stargazer/proc/drop_charge()
	var/obj/effect/abstract/heretic_vfx_attached/star = hand_glow
	hand_glow = null
	star?.fade_out()

/// Выстрел: звезда в руке вспыхивает и рассыпается.
/mob/living/simple_animal/heretic_stargazer/proc/discharge()
	deltimer(charge_timer)
	charge_timer = null
	var/obj/effect/abstract/heretic_vfx_attached/star = hand_glow
	hand_glow = null
	if(QDELETED(star))
		star = attach_hand_star(0)
	if(!star)
		return
	star.fading = TRUE
	var/matrix/flared = matrix()
	flared.Scale(HERETIC_STARGAZER_FLARE_SCALE)
	animate(star, transform = flared, alpha = 0, time = HERETIC_STARGAZER_FLARE_TIME, easing = CUBIC_EASING | EASE_OUT)
	QDEL_IN(star, HERETIC_STARGAZER_FLARE_TIME)

/// Смерть: Звездочёт вздрагивает, сжимается в точку и рассыпается звёздами.
/mob/living/simple_animal/heretic_stargazer/proc/collapse(time)
	deltimer(charge_timer)
	charge_timer = null
	QDEL_NULL(hand_glow)
	heretic_stargazer_implode(src, time)
	heretic_stargazer_scatter(get_turf(src), time)

/// Разрыв поводка: Звездочёт осыпается звёздами на старом месте и проступает рядом с героем.
/mob/living/simple_animal/heretic_stargazer/proc/leap(turf/from, look)
	if(from && look)
		new /obj/effect/temp_visual/heretic_stargazer_remnant(from, look, HERETIC_STARGAZER_LEASH_FADE)
	var/rest_alpha = alpha
	alpha = HERETIC_STARGAZER_ASSEMBLE_ALPHA
	animate(src, alpha = rest_alpha, time = HERETIC_STARGAZER_LEASH_FADE, easing = SINE_EASING | EASE_OUT)

/proc/heretic_stargazer_implode(atom/movable/body, time)
	var/matrix/swell = matrix(body.transform)
	swell.Scale(HERETIC_STARGAZER_SWELL)
	var/matrix/point = matrix(body.transform)
	point.Scale(HERETIC_STARGAZER_SHRINK)
	point.Turn(HERETIC_STARGAZER_SHRINK_TURN)
	animate(body, transform = swell, time = HERETIC_STARGAZER_SWELL_TIME, easing = SINE_EASING | EASE_OUT)
	animate(transform = point, alpha = 0, time = max(world.tick_lag, time - HERETIC_STARGAZER_SWELL_TIME), easing = CUBIC_EASING | EASE_IN)

/proc/heretic_stargazer_scatter(turf/place, time)
	if(!place)
		return
	var/obj/effect/temp_visual/heretic_vfx/burst/stars = heretic_vfx_burst(place, /particles/heretic_ascension/cosmic/scatter, time * HERETIC_STARGAZER_SCATTER_SHARE)
	if(stars)
		stars.pixel_y = HERETIC_STARGAZER_CENTER_Y
	heretic_vfx_shockwave(place, heretic_path_ink(PATH_COSMIC), HERETIC_STARGAZER_SCATTER_WAVE_RADIUS, HERETIC_STARGAZER_SCATTER_WAVE_TIME)
	heretic_vfx_flash(place, heretic_path_ink(PATH_COSMIC, TRUE), HERETIC_STARGAZER_SCATTER_FLASH_RANGE, HERETIC_STARGAZER_SCATTER_FLASH_POWER, HERETIC_STARGAZER_SCATTER_FLASH_TIME)

/// Луч Звездочёта: яркая сердцевина вспыхивает вдоль луча, в цели взрываются звёзды.
/proc/heretic_stargazer_beam_fx(atom/source, atom/target)
	var/turf/hit = get_turf(target)
	if(!hit)
		return
	var/obj/effect/temp_visual/heretic_vfx/thread/core = heretic_vfx_thread(source, hit, HERETIC_STARGAZER_BEAM_CORE, HERETIC_STARGAZER_BEAM_TIME)
	core?.snap(HERETIC_STARGAZER_BEAM_TIME)
	heretic_vfx_burst(hit, /particles/heretic_ascension/cosmic/impact)
	heretic_vfx_flash(hit, heretic_path_ink(PATH_COSMIC, TRUE), HERETIC_STARGAZER_IMPACT_FLASH_RANGE, HERETIC_STARGAZER_IMPACT_FLASH_POWER, HERETIC_STARGAZER_IMPACT_FLASH_TIME)

/// Звезда следа загорается бликом.
/proc/heretic_cosmic_twinkle(turf/place)
	if(!place)
		return null
	heretic_vfx_flash(place, heretic_path_ink(PATH_COSMIC), HERETIC_COSMIC_TWINKLE_FLASH_RANGE, HERETIC_COSMIC_TWINKLE_FLASH_POWER, HERETIC_COSMIC_TWINKLE_FLASH_TIME)
	return new /obj/effect/temp_visual/heretic_cosmic_twinkle(place)

/// Разрыв пространства, из которого выходит Звездочёт.
/obj/effect/temp_visual/heretic_stargazer_rift
	icon = 'modular_bluemoon/icons/mob/heretic_stargazer.dmi'
	icon_state = "stargazer_rift"
	duration = HERETIC_STARGAZER_RIFT_TIME
	randomdir = FALSE
	pixel_x = -32
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_stargazer_rift/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))

/// Снимок Звездочёта сжимается и рассыпается там, где его уже нет.
/obj/effect/temp_visual/heretic_stargazer_remnant
	randomdir = FALSE
	var/obj/effect/abstract/heretic_vfx_glow/glow

/obj/effect/temp_visual/heretic_stargazer_remnant/Initialize(mapload, look, lifetime = HERETIC_STARGAZER_REMNANT_TIME)
	duration = lifetime
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
	glow = heretic_vfx_attach_glow(src)
	heretic_stargazer_implode(src, lifetime)
	var/obj/effect/temp_visual/heretic_vfx/burst/stars = heretic_vfx_burst(loc, /particles/heretic_ascension/cosmic/scatter, lifetime * HERETIC_STARGAZER_SCATTER_SHARE)
	if(stars)
		stars.pixel_y = HERETIC_STARGAZER_CENTER_Y

/obj/effect/temp_visual/heretic_stargazer_remnant/Destroy()
	vis_contents -= glow
	QDEL_NULL(glow)
	return ..()

/obj/effect/temp_visual/heretic_cosmic_twinkle
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "star_twinkle"
	duration = HERETIC_COSMIC_TWINKLE_TIME
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_cosmic_twinkle/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))

/// Космос: звёзды разлетаются из точки удара луча.
/particles/heretic_ascension/cosmic/impact
	count = 16
	spawning = 8
	velocity = generator("circle", 4, 7)
	friction = 0.15
	lifespan = 0.8 SECONDS
	fade = 0.4 SECONDS
	fadein = 0

/// Космос: гибнущий Звездочёт осыпается звёздами по всему росту.
/particles/heretic_ascension/cosmic/scatter
	count = 30
	spawning = 3
	position = generator("box", list(-14, -30, 0), list(14, 30, 0))
	velocity = generator("circle", 1.5, 4)
	friction = 0.03
	lifespan = 1.6 SECONDS
	fade = 0.8 SECONDS
	fadein = 0.1 SECONDS

#undef HERETIC_STARGAZER_CENTER_Y
#undef HERETIC_STARGAZER_HAND_X
#undef HERETIC_STARGAZER_HAND_Y
#undef HERETIC_STARGAZER_RIFT_TIME
#undef HERETIC_STARGAZER_ASSEMBLE_DELAY
#undef HERETIC_STARGAZER_ASSEMBLE_TIME
#undef HERETIC_STARGAZER_ASSEMBLE_SCALE
#undef HERETIC_STARGAZER_GATHER_RADIUS
#undef HERETIC_STARGAZER_GATHER_TRAVEL
#undef HERETIC_STARGAZER_GATHER_EMIT
#undef HERETIC_STARGAZER_GATHER_ARMS
#undef HERETIC_STARGAZER_GATHER_SWIRL
#undef HERETIC_STARGAZER_ARRIVAL_QUAKE
#undef HERETIC_STARGAZER_CHARGE_TIME
#undef HERETIC_STARGAZER_CHARGE_HOLD
#undef HERETIC_STARGAZER_CHARGE_SEED
#undef HERETIC_STARGAZER_FLARE_TIME
#undef HERETIC_STARGAZER_FLARE_SCALE
#undef HERETIC_STARGAZER_BEAM_CORE
#undef HERETIC_STARGAZER_BEAM_TIME
#undef HERETIC_STARGAZER_SWELL
#undef HERETIC_STARGAZER_SWELL_TIME
#undef HERETIC_STARGAZER_SHRINK
#undef HERETIC_STARGAZER_SHRINK_TURN
#undef HERETIC_STARGAZER_SCATTER_SHARE
#undef HERETIC_STARGAZER_LEASH_FADE
#undef HERETIC_COSMIC_TWINKLE_TIME
#undef HERETIC_STARGAZER_ASSEMBLE_ALPHA
#undef HERETIC_STARGAZER_ARRIVAL_WAVE_RADIUS
#undef HERETIC_STARGAZER_ARRIVAL_WAVE_TIME
#undef HERETIC_STARGAZER_ARRIVAL_FLASH_RANGE
#undef HERETIC_STARGAZER_ARRIVAL_FLASH_POWER
#undef HERETIC_STARGAZER_ARRIVAL_FLASH_TIME
#undef HERETIC_STARGAZER_ARRIVAL_QUAKE_RADIUS
#undef HERETIC_STARGAZER_SCATTER_WAVE_RADIUS
#undef HERETIC_STARGAZER_SCATTER_WAVE_TIME
#undef HERETIC_STARGAZER_SCATTER_FLASH_RANGE
#undef HERETIC_STARGAZER_SCATTER_FLASH_POWER
#undef HERETIC_STARGAZER_SCATTER_FLASH_TIME
#undef HERETIC_STARGAZER_IMPACT_FLASH_RANGE
#undef HERETIC_STARGAZER_IMPACT_FLASH_POWER
#undef HERETIC_STARGAZER_IMPACT_FLASH_TIME
#undef HERETIC_STARGAZER_REMNANT_TIME
#undef HERETIC_COSMIC_TWINKLE_FLASH_RANGE
#undef HERETIC_COSMIC_TWINKLE_FLASH_POWER
#undef HERETIC_COSMIC_TWINKLE_FLASH_TIME
