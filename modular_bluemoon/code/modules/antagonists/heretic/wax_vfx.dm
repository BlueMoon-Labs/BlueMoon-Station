#define HERETIC_WAX_EFFECTS_ICON 'modular_bluemoon/icons/obj/heretic_wax_effects.dmi'
#define HERETIC_WAX_ANCHOR_BREATH (1.4 SECONDS)
#define HERETIC_WAX_ANCHOR_GLOW_SIZE 2
#define HERETIC_WAX_ANCHOR_GLOW_COLOR "#fff0c0"
#define HERETIC_WAX_ANCHOR_FLAME_ALPHA 230
#define HERETIC_WAX_DOLL_SPREAD 1.25
#define HERETIC_WAX_DOLL_SQUASH 0.3
#define HERETIC_WAX_DOLL_SINK 10
#define HERETIC_WAX_DOLL_DRIP_TIME (8 SECONDS)
#define HERETIC_WAX_MELT_SPREAD 1.3
#define HERETIC_WAX_MELT_SQUASH 0.15
#define HERETIC_WAX_MELT_SINK 12
#define HERETIC_WAX_CANDLE_MELT (0.4 SECONDS)
#define HERETIC_WAX_CANDLE_RISE (0.3 SECONDS)
#define HERETIC_WAX_CANDLE_RISE_DEPTH 6
#define HERETIC_WAX_FLARE_TIME (0.5 SECONDS)
#define HERETIC_WAX_FLARE_RISE (0.15 SECONDS)
#define HERETIC_WAX_FLARE_SCALE 1.5
#define HERETIC_WAX_COLUMN_TIME (1 SECONDS)
#define HERETIC_WAX_RISE_FILTER "heretic_wax_rise"
#define HERETIC_WAX_RISE_PRIORITY 12
#define HERETIC_WAX_RISE_HOLD (0.3 SECONDS)
#define HERETIC_WAX_RISE_SOLIDIFY (0.7 SECONDS)
#define HERETIC_WAX_RISE_ALPHA 0.15
#define HERETIC_WAX_MATRIX_ALPHA 16
#define HERETIC_WAX_FLARE_LIFT 0.8
#define HERETIC_WAX_PULSE_RADIUS 2
#define HERETIC_WAX_PULSE_WAVE (0.6 SECONDS)
#define HERETIC_WAX_CROWN_QUAKE 0.15
#define HERETIC_WAX_CROWN_QUAKE_RADIUS 7
#define HERETIC_WAX_CROWN_FLASH_RANGE 4
#define HERETIC_WAX_CROWN_FLASH_POWER 2
#define HERETIC_WAX_CROWN_FLASH_TIME (0.6 SECONDS)
#define HERETIC_WAX_PULSE_FLASH_RANGE 2
#define HERETIC_WAX_PULSE_FLASH_POWER 1
#define HERETIC_WAX_PULSE_FLASH_TIME (0.3 SECONDS)
#define HERETIC_WAX_RISE_FLASH_RANGE 3
#define HERETIC_WAX_RISE_FLASH_POWER 2
#define HERETIC_WAX_RISE_FLASH_TIME (0.6 SECONDS)
#define HERETIC_WAX_WICK_DROP 2
#define HERETIC_WAX_CANDLE_STATE "candle"
#define HERETIC_WAX_CANDLE_LIGHT_STEPS 3

/datum/eldritch_knowledge/base_wax
	/// Холодные огоньки над свечами-якорями: свеча -> огонёк.
	var/list/anchor_flames = list()

/// Контур якоря дышит золотом, над мёртвым фитилём загорается холодный огонёк.
/datum/eldritch_knowledge/base_wax/proc/light_anchor(obj/item/candle/candle, outline, outline_color)
	if(outline)
		animate(outline, size = HERETIC_WAX_ANCHOR_GLOW_SIZE, color = HERETIC_WAX_ANCHOR_GLOW_COLOR, time = HERETIC_WAX_ANCHOR_BREATH, easing = SINE_EASING, loop = -1)
		animate(size = 1, color = outline_color, time = HERETIC_WAX_ANCHOR_BREATH, easing = SINE_EASING)
	if(anchor_flames[candle])
		return
	var/obj/effect/abstract/heretic_vfx_attached/flame = heretic_vfx_attach(candle, 'modular_bluemoon/icons/effects/heretic_vfx.dmi', "wax_anchor_flame", HERETIC_WAX_ANCHOR_FLAME_ALPHA)
	if(!flame)
		return
	anchor_flames[candle] = flame
	RegisterSignal(candle, COMSIG_ATOM_UPDATED_ICON, PROC_REF(on_anchor_icon_updated))
	fit_anchor_flame(candle, flame)

/datum/eldritch_knowledge/base_wax/proc/snuff_anchor(obj/item/candle/candle)
	UnregisterSignal(candle, COMSIG_ATOM_UPDATED_ICON)
	var/obj/effect/abstract/heretic_vfx_attached/flame = anchor_flames[candle]
	anchor_flames -= candle
	if(QDELETED(candle))
		qdel(flame)
		return
	flame?.fade_out()

/datum/eldritch_knowledge/base_wax/proc/on_anchor_icon_updated(obj/item/candle/source)
	SIGNAL_HANDLER
	fit_anchor_flame(source, anchor_flames[source])

/// Огонёк держится над фитилём оплывающей свечи и прячется, пока горит её настоящее пламя.
/datum/eldritch_knowledge/base_wax/proc/fit_anchor_flame(obj/item/candle/candle, obj/effect/abstract/heretic_vfx_attached/flame)
	if(QDELETED(flame) || flame.fading)
		return
	var/prefix_length = length(HERETIC_WAX_CANDLE_STATE)
	var/stage = text2num(copytext(candle.icon_state, prefix_length + 1, prefix_length + 2)) || 1
	flame.pixel_y = -(stage - 1) * HERETIC_WAX_WICK_DROP
	flame.alpha = candle.lit ? 0 : HERETIC_WAX_ANCHOR_FLAME_ALPHA

/// Кукла оплывает: оседает к полу, расползается и тает к концу срока.
/obj/effect/temp_visual/heretic_wax_doll/proc/melt_down()
	var/matrix/melted = matrix(transform)
	melted.Scale(HERETIC_WAX_DOLL_SPREAD, HERETIC_WAX_DOLL_SQUASH)
	melted.Translate(0, -HERETIC_WAX_DOLL_SINK)
	animate(src, transform = melted, time = duration, easing = QUAD_EASING | EASE_IN)
	animate(src, alpha = 0, time = duration, easing = CUBIC_EASING | EASE_IN, flags = ANIMATION_PARALLEL)

/// Возвращение к свече: у куклы капает воск, свеча вспыхивает и оплывает, столб воска поднимается и стекает с тела.
/proc/heretic_wax_rise_fx(mob/living/body, turf/fall_spot, turf/destination, anchor_look)
	var/cold = heretic_path_ink(PATH_WAX, TRUE)
	if(fall_spot)
		heretic_vfx_burst(fall_spot, /particles/heretic_ascension/wax/drip, HERETIC_WAX_DOLL_DRIP_TIME, FALSE)
	if(!destination)
		return
	new /obj/effect/temp_visual/heretic_wax_column(destination)
	if(anchor_look)
		new /obj/effect/temp_visual/heretic_wax_melt/flare(destination, anchor_look)
	heretic_vfx_burst(destination, /particles/heretic_ascension/wax)
	heretic_vfx_flash(destination, cold, HERETIC_WAX_RISE_FLASH_RANGE, HERETIC_WAX_RISE_FLASH_POWER, HERETIC_WAX_RISE_FLASH_TIME)
	if(QDELETED(body))
		return
	var/list/cast = heretic_vfx_ink_tint(heretic_path_ink(PATH_WAX))
	cast[HERETIC_WAX_MATRIX_ALPHA] = HERETIC_WAX_RISE_ALPHA
	body.add_filter(HERETIC_WAX_RISE_FILTER, HERETIC_WAX_RISE_PRIORITY, color_matrix_filter(cast))
	var/filter = body.get_filter(HERETIC_WAX_RISE_FILTER)
	animate(filter, color = cast, time = HERETIC_WAX_RISE_HOLD)
	animate(color = color_matrix_identity(), time = HERETIC_WAX_RISE_SOLIDIFY, easing = SINE_EASING)
	addtimer(CALLBACK(body, TYPE_PROC_REF(/atom, remove_filter), HERETIC_WAX_RISE_FILTER), HERETIC_WAX_RISE_HOLD + HERETIC_WAX_RISE_SOLIDIFY, TIMER_UNIQUE | TIMER_OVERRIDE)

/// Импульс Бессмертной процессии: мягкая волна и брызги воска; первый ещё вспыхивает холодом и трясёт землю.
/proc/heretic_wax_crown_pulse(mob/living/bearer, first = FALSE)
	if(QDELETED(bearer))
		return
	var/ink = heretic_path_ink(PATH_WAX)
	var/cold = heretic_path_ink(PATH_WAX, TRUE)
	heretic_vfx_shockwave(bearer, ink, HERETIC_WAX_PULSE_RADIUS, HERETIC_WAX_PULSE_WAVE)
	heretic_vfx_burst(bearer, /particles/heretic_ascension/wax/pulse)
	if(!first)
		heretic_vfx_flash(bearer, cold, HERETIC_WAX_PULSE_FLASH_RANGE, HERETIC_WAX_PULSE_FLASH_POWER, HERETIC_WAX_PULSE_FLASH_TIME)
		return
	heretic_vfx_pulse(bearer, cold)
	heretic_vfx_flash(bearer, cold, HERETIC_WAX_CROWN_FLASH_RANGE, HERETIC_WAX_CROWN_FLASH_POWER, HERETIC_WAX_CROWN_FLASH_TIME)
	heretic_vfx_quake(bearer, HERETIC_WAX_CROWN_QUAKE_RADIUS, HERETIC_WAX_CROWN_QUAKE)

/// Погребальная свеча поднимается из пола и разгорается вместе с подъёмом, а не появляется рывком.
/obj/structure/heretic_wax_candle/proc/rise_from_floor()
	alpha = 0
	pixel_y = base_pixel_y - HERETIC_WAX_CANDLE_RISE_DEPTH
	animate(src, alpha = 255, pixel_y = base_pixel_y, time = HERETIC_WAX_CANDLE_RISE, easing = BACK_EASING | EASE_OUT)
	var/full_power = light_power
	set_light(l_power = full_power / HERETIC_WAX_CANDLE_LIGHT_STEPS)
	for(var/light_step in 2 to HERETIC_WAX_CANDLE_LIGHT_STEPS)
		addtimer(CALLBACK(src, PROC_REF(brighten), full_power * light_step / HERETIC_WAX_CANDLE_LIGHT_STEPS), HERETIC_WAX_CANDLE_RISE * (light_step - 1) / (HERETIC_WAX_CANDLE_LIGHT_STEPS - 1))

/obj/structure/heretic_wax_candle/proc/brighten(power)
	set_light(l_power = power)

/// Столб расплавленного воска: поднимается из лужи по телу, трескается холодным светом и стекает обратно; в темноте светятся только трещины и огонёк.
/obj/effect/temp_visual/heretic_wax_column
	icon = HERETIC_WAX_EFFECTS_ICON
	icon_state = "wax_column"
	duration = HERETIC_WAX_COLUMN_TIME
	randomdir = FALSE
	pixel_x = -16
	pixel_y = -16
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_wax_column/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, "wax_column_glow"))

/// Снимок свечи оплывает лужицей; вспышка сначала раздувает его холодным светом.
/obj/effect/temp_visual/heretic_wax_melt
	randomdir = FALSE
	duration = HERETIC_WAX_CANDLE_MELT
	var/obj/effect/abstract/heretic_vfx_glow/glow

/obj/effect/temp_visual/heretic_wax_melt/Initialize(mapload, look)
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
	melt()

/obj/effect/temp_visual/heretic_wax_melt/proc/melt()
	var/matrix/melted = matrix(transform)
	melted.Scale(HERETIC_WAX_MELT_SPREAD, HERETIC_WAX_MELT_SQUASH)
	melted.Translate(0, -HERETIC_WAX_MELT_SINK)
	animate(src, transform = melted, alpha = 0, time = duration, easing = QUAD_EASING | EASE_IN)

/obj/effect/temp_visual/heretic_wax_melt/Destroy()
	vis_contents -= glow
	QDEL_NULL(glow)
	return ..()

/obj/effect/temp_visual/heretic_wax_melt/flare
	duration = HERETIC_WAX_FLARE_TIME

/obj/effect/temp_visual/heretic_wax_melt/flare/melt()
	layer = ABOVE_MOB_LAYER
	glow = heretic_vfx_attach_glow(src)
	var/matrix/rest = matrix(transform)
	var/matrix/flared = matrix(rest)
	flared.Scale(HERETIC_WAX_FLARE_SCALE)
	var/matrix/melted = matrix(rest)
	melted.Scale(HERETIC_WAX_MELT_SPREAD, HERETIC_WAX_MELT_SQUASH)
	melted.Translate(0, -HERETIC_WAX_MELT_SINK)
	color = heretic_vfx_ink_tint(heretic_path_ink(PATH_WAX, TRUE), HERETIC_WAX_FLARE_LIFT)
	animate(src, transform = flared, time = HERETIC_WAX_FLARE_RISE, easing = CUBIC_EASING | EASE_OUT)
	animate(transform = melted, alpha = 0, time = duration - HERETIC_WAX_FLARE_RISE, easing = QUAD_EASING | EASE_IN)

/// Воск: капли стекают с тающей куклы и падают на пол.
/particles/heretic_ascension/wax/drip
	icon_state = list("wax_drop" = 1)
	count = 12
	spawning = 0.4
	lifespan = 1 SECONDS
	fade = 0.4 SECONDS
	position = generator("box", list(-10, -6, 0), list(10, 8, 0))
	velocity = list(0, -0.4, 0)
	gravity = list(0, -0.12, 0)
	friction = 0

/// Воск: импульс процессии бросает капли и холодные огоньки кольцом.
/particles/heretic_ascension/wax/pulse
	count = 24
	velocity = generator("circle", 3, 5)
	gravity = list(0, -0.1)
	friction = 0.08
	lifespan = 1.2 SECONDS
	fade = 0.5 SECONDS

#undef HERETIC_WAX_EFFECTS_ICON
#undef HERETIC_WAX_ANCHOR_BREATH
#undef HERETIC_WAX_ANCHOR_GLOW_SIZE
#undef HERETIC_WAX_ANCHOR_GLOW_COLOR
#undef HERETIC_WAX_ANCHOR_FLAME_ALPHA
#undef HERETIC_WAX_DOLL_SPREAD
#undef HERETIC_WAX_DOLL_SQUASH
#undef HERETIC_WAX_DOLL_SINK
#undef HERETIC_WAX_DOLL_DRIP_TIME
#undef HERETIC_WAX_MELT_SPREAD
#undef HERETIC_WAX_MELT_SQUASH
#undef HERETIC_WAX_MELT_SINK
#undef HERETIC_WAX_CANDLE_MELT
#undef HERETIC_WAX_CANDLE_RISE
#undef HERETIC_WAX_CANDLE_RISE_DEPTH
#undef HERETIC_WAX_FLARE_TIME
#undef HERETIC_WAX_FLARE_RISE
#undef HERETIC_WAX_FLARE_SCALE
#undef HERETIC_WAX_COLUMN_TIME
#undef HERETIC_WAX_RISE_FILTER
#undef HERETIC_WAX_RISE_PRIORITY
#undef HERETIC_WAX_RISE_HOLD
#undef HERETIC_WAX_RISE_SOLIDIFY
#undef HERETIC_WAX_RISE_ALPHA
#undef HERETIC_WAX_MATRIX_ALPHA
#undef HERETIC_WAX_FLARE_LIFT
#undef HERETIC_WAX_PULSE_RADIUS
#undef HERETIC_WAX_PULSE_WAVE
#undef HERETIC_WAX_CROWN_QUAKE
#undef HERETIC_WAX_CROWN_QUAKE_RADIUS
#undef HERETIC_WAX_CROWN_FLASH_RANGE
#undef HERETIC_WAX_CROWN_FLASH_POWER
#undef HERETIC_WAX_CROWN_FLASH_TIME
#undef HERETIC_WAX_PULSE_FLASH_RANGE
#undef HERETIC_WAX_PULSE_FLASH_POWER
#undef HERETIC_WAX_PULSE_FLASH_TIME
#undef HERETIC_WAX_RISE_FLASH_RANGE
#undef HERETIC_WAX_RISE_FLASH_POWER
#undef HERETIC_WAX_RISE_FLASH_TIME
#undef HERETIC_WAX_WICK_DROP
#undef HERETIC_WAX_CANDLE_STATE
#undef HERETIC_WAX_CANDLE_LIGHT_STEPS
