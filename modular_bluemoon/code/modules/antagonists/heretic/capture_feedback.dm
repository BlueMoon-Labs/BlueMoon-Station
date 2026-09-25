#define HERETIC_FX_GRIP_INK "#c9404f"
#define HERETIC_FX_HOLY_INK "#fff3c4"
#define HERETIC_FX_HOLD_FADE_IN (0.3 SECONDS)
#define HERETIC_FX_HOLD_FADE_OUT (0.5 SECONDS)
#define HERETIC_FX_QUIET_VOLUME 20
#define HERETIC_FX_HOLD_VOLUME 30
#define HERETIC_FX_EVENT_VOLUME 45
#define HERETIC_FX_LOUD_VOLUME 55
#define HERETIC_FX_CRAFT_PULSE (0.8 SECONDS)
#define HERETIC_FX_CRAFT_BURST (0.1 SECONDS)
#define HERETIC_FX_DISPEL_PULSE (0.6 SECONDS)
#define HERETIC_FX_SHAKE_PULSE (0.5 SECONDS)
#define HERETIC_FX_FLASH_RANGE 2
#define HERETIC_FX_FLASH_POWER 1.5
#define HERETIC_FX_FLASH_TIME (0.4 SECONDS)
#define HERETIC_FX_SEAM_WIDTH 0.12
#define HERETIC_FX_SEAM_HEIGHT 0.45
#define HERETIC_FX_SEAM_TAIL (0.3 SECONDS)
#define HERETIC_FX_SEAM_ALPHA 220
#define HERETIC_FX_RIFT_OPEN (0.35 SECONDS)
#define HERETIC_FX_RIFT_CLOSE (0.4 SECONDS)
#define HERETIC_FX_PULL_MIN (0.4 SECONDS)
#define HERETIC_FX_PULL_RADIUS 48
#define HERETIC_FX_PULL_ARMS 5
#define HERETIC_FX_PULL_SWIRL 0.5
#define HERETIC_FX_VANISH_TIME (0.4 SECONDS)
#define HERETIC_FX_VANISH_SQUEEZE 0.1
#define HERETIC_FX_VANISH_STRETCH 1.25
#define HERETIC_FX_STEP_OUT (0.9 SECONDS)
#define HERETIC_FX_GHOST_ALPHA 190
#define HERETIC_FX_QUAKE_RADIUS 3
#define HERETIC_FX_QUAKE_STRENGTH 0.6
#define HERETIC_FX_QUAKE_TIME (0.4 SECONDS)
#define HERETIC_FX_TEAR_SHAKE 2
#define HERETIC_FX_TEAR_STEP (0.15 SECONDS)
#define HERETIC_FX_WARNING_BLINK (0.5 SECONDS)
#define HERETIC_FX_WARNING_ALPHA 110
#define HERETIC_FX_GRIP_TIME (0.5 SECONDS)
#define HERETIC_FX_GRIP_DUST (0.8 SECONDS)
#define HERETIC_FX_REFUSAL_PULSE (0.4 SECONDS)
#define HERETIC_FX_REFUSAL_QUAKE (0.3 SECONDS)
#define HERETIC_FX_REFUSAL_SWING (0.12 SECONDS)
#define HERETIC_FX_REFUSAL_FADE (0.3 SECONDS)
#define HERETIC_FX_REFUSAL_RAISED 20
#define HERETIC_FX_REFUSAL_STRUCK 110
#define HERETIC_FX_REFUSAL_SCALE 1.3
#define HERETIC_FX_REFUSAL_LIFT 18
#define HERETIC_FX_REFUSAL_ALPHA 190
#define HERETIC_FX_REFUSAL_SPRAY 180
#define HERETIC_FX_BREACH_POWER 3
#define HERETIC_FX_OUTLINE_THIN 1
#define HERETIC_FX_OUTLINE_WIDE 2
#define HERETIC_FX_GATHER_CLOSE 1
#define HERETIC_FX_GATHER_RADIUS 2
#define HERETIC_FX_FLASH_NEAR 1
#define HERETIC_FX_QUAKE_SELF 0
#define HERETIC_FX_QUAKE_HIT 1
#define HERETIC_FX_FIZZLE_COOLDOWN (2 SECONDS)
#define HERETIC_FX_FIZZLE_PULSE (0.3 SECONDS)

/// Звук из набора пути в Мансусе: deposit, warning, hit, escape, step, pickup.
/proc/heretic_fx_theme_sound(path_id, key)
	var/list/theme = GLOB.heretic_mansus_themes[path_id]
	return theme?[key]

/// Частицы пути для мелких событий или null.
/proc/heretic_fx_particles(path_id)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	return path?.vfx_particles

/// Путь захвата: по метке «путь_...», по знанию усыпившего захвата или по изнанке, куда цель увели.
/proc/heretic_fx_capture_path(mob/living/victim, source)
	if(istext(source))
		if(findtext(source, "\[0x") == 1)
			var/datum/status_effect/heretic_capture_knockout/knockout = locate(source)
			if(istype(knockout))
				var/datum/eldritch_knowledge/knowledge = knockout.knowledge_ref?.resolve()
				return knowledge?.route
		for(var/path_id in GLOB.heretic_paths)
			if(findtext(source, lowertext(path_id)) == 1)
				return path_id
	for(var/datum/heretic_pocket/pocket as anything in GLOB.heretic_pockets)
		if(pocket.active && pocket.victim == victim)
			return pocket.owner?.selected_path
	return null

// Ремесло: тихая вспышка на помеченном объекте и рассеивание нулевым жезлом.

/proc/heretic_craft_placed_fx(atom/crafted, datum/eldritch_knowledge/owner)
	if(QDELETED(crafted))
		return
	var/path_id = owner?.route
	heretic_vfx_pulse(crafted, heretic_path_ink(path_id), HERETIC_FX_OUTLINE_THIN, HERETIC_FX_CRAFT_PULSE)
	var/particles_type = heretic_fx_particles(path_id)
	if(particles_type && heretic_vfx_watched(crafted))
		heretic_vfx_burst(crafted, particles_type, HERETIC_FX_CRAFT_BURST)
	var/deposit = heretic_fx_theme_sound(path_id, "deposit")
	if(deposit)
		playsound(crafted, deposit, HERETIC_FX_QUIET_VOLUME, TRUE, SILENCED_SOUND_EXTRARANGE)

/proc/heretic_craft_dispel_fx(atom/crafted, datum/eldritch_knowledge/owner)
	if(QDELETED(crafted))
		return
	heretic_vfx_pulse(crafted, HERETIC_FX_HOLY_INK, HERETIC_FX_OUTLINE_WIDE, HERETIC_FX_DISPEL_PULSE)
	heretic_vfx_flash(crafted, HERETIC_FX_HOLY_INK, HERETIC_FX_FLASH_RANGE, HERETIC_FX_FLASH_POWER, HERETIC_FX_FLASH_TIME)
	var/particles_type = heretic_fx_particles(owner?.route)
	if(particles_type)
		heretic_vfx_burst(crafted, particles_type)
	playsound(crafted, 'sound/magic/Teleport_diss.ogg', HERETIC_FX_EVENT_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

// Захват: пока хоть один захват держит цель, у её ног лужа Мансуса и щупальца в чернилах пути.

/mob/living
	var/obj/effect/abstract/heretic_capture_mark/front/heretic_capture_mark

/proc/heretic_capture_hold_fx(mob/living/victim, source)
	if(QDELETED(victim))
		return null
	if(victim.heretic_capture_mark)
		return victim.heretic_capture_mark
	var/path_id = heretic_fx_capture_path(victim, source)
	var/obj/effect/abstract/heretic_capture_mark/front/mark = new(null, victim, path_id)
	if(QDELETED(mark))
		return null
	victim.heretic_capture_mark = mark
	var/grip_sound = heretic_fx_theme_sound(path_id, "hit")
	if(grip_sound && isturf(victim.loc))
		playsound(victim, grip_sound, HERETIC_FX_HOLD_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	return mark

/proc/heretic_capture_unhold_fx(mob/living/victim)
	victim?.heretic_capture_mark?.fade_out()

/// Цель растолкали: хватка вспыхивает и рвётся, дальше метка гаснет вместе с захватом.
/proc/heretic_capture_shaken_fx(mob/living/helper, mob/living/victim)
	if(QDELETED(victim))
		return
	var/obj/effect/abstract/heretic_capture_mark/front/mark = victim.heretic_capture_mark
	heretic_vfx_pulse(victim, mark?.ink || HERETIC_FX_GRIP_INK, HERETIC_FX_OUTLINE_WIDE, HERETIC_FX_SHAKE_PULSE)
	var/particles_type = heretic_fx_particles(mark?.path_id)
	if(particles_type)
		heretic_vfx_burst(victim, particles_type)
	playsound(victim, 'sound/magic/Repulse.ogg', HERETIC_FX_EVENT_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/// Слой метки в vis_contents цели: не ложится вместе с ней и не перекрашивается её цветом.
/obj/effect/abstract/heretic_capture_mark
	icon = 'modular_bluemoon/icons/obj/heretic_capture.dmi'
	icon_state = "hold_back"
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE | VIS_UNDERLAY
	var/datum/weakref/host_ref
	var/path_id
	var/ink

/obj/effect/abstract/heretic_capture_mark/Initialize(mapload, mob/living/host, new_path_id)
	. = ..()
	if(QDELETED(host))
		return INITIALIZE_HINT_QDEL
	path_id = new_path_id
	ink = path_id ? heretic_path_ink(path_id) : HERETIC_FX_GRIP_INK
	color = ink
	add_overlay(emissive_appearance(icon, "[icon_state]_glow"))
	host_ref = WEAKREF(host)
	host.vis_contents += src
	alpha = 0
	animate(src, alpha = 255, time = HERETIC_FX_HOLD_FADE_IN, easing = SINE_EASING | EASE_OUT)

/obj/effect/abstract/heretic_capture_mark/Destroy()
	var/mob/living/host = host_ref?.resolve()
	if(host)
		host.vis_contents -= src
	host_ref = null
	return ..()

/obj/effect/abstract/heretic_capture_mark/front
	icon_state = "hold_front"
	vis_flags = VIS_INHERIT_PLANE
	var/obj/effect/abstract/heretic_capture_mark/back
	var/fading = FALSE

/obj/effect/abstract/heretic_capture_mark/front/Initialize(mapload, mob/living/host, new_path_id)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	back = new(null, host, new_path_id)
	RegisterSignal(host, COMSIG_PARENT_QDELETING, PROC_REF(on_host_deleted))

/obj/effect/abstract/heretic_capture_mark/front/proc/on_host_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Щупальца отпускают за HERETIC_FX_HOLD_FADE_OUT; новый захват в это время рисует свою метку.
/obj/effect/abstract/heretic_capture_mark/front/proc/fade_out()
	var/mob/living/host = host_ref?.resolve()
	if(host?.heretic_capture_mark == src)
		host.heretic_capture_mark = null
	if(fading || QDELETED(src))
		return
	fading = TRUE
	animate(src, alpha = 0, time = HERETIC_FX_HOLD_FADE_OUT, easing = SINE_EASING | EASE_IN)
	if(back)
		animate(back, alpha = 0, time = HERETIC_FX_HOLD_FADE_OUT, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, HERETIC_FX_HOLD_FADE_OUT)

/obj/effect/abstract/heretic_capture_mark/front/Destroy()
	var/mob/living/host = host_ref?.resolve()
	if(host)
		UnregisterSignal(host, COMSIG_PARENT_QDELETING)
		if(host.heretic_capture_mark == src)
			host.heretic_capture_mark = null
	QDEL_NULL(back)
	return ..()

// Изнанка: шов перед уводом, разрыв открывается и схлопывается, выход к своему месту.

/// Копия разрыва изнанки на клетке: раскрывается из щели за open_time и стягивается обратно к концу жизни.
/obj/effect/temp_visual/heretic_vfx/pocket_seam
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "pocket_rift"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_vfx/pocket_seam/Initialize(mapload, ink, lifetime = HERETIC_FX_STEP_OUT, open_time = HERETIC_FX_RIFT_OPEN, peak_alpha = 255)
	duration = lifetime
	. = ..()
	var/mutable_appearance/edge = mutable_appearance(icon, "pocket_rift_glow")
	edge.color = ink
	add_overlay(edge)
	add_overlay(emissive_appearance(icon, "pocket_rift_glow"))
	var/matrix/slit = matrix(HERETIC_FX_SEAM_WIDTH, 0, 0, 0, HERETIC_FX_SEAM_HEIGHT, 0)
	open_time = clamp(open_time, 0, lifetime)
	if(!open_time)
		alpha = peak_alpha
		animate(src, transform = slit, alpha = 0, time = lifetime, easing = QUAD_EASING | EASE_IN)
		return
	transform = slit
	alpha = 0
	animate(src, transform = matrix(), alpha = peak_alpha, time = open_time, easing = BACK_EASING | EASE_OUT)
	animate(transform = slit, alpha = 0, time = lifetime - open_time, easing = SINE_EASING | EASE_IN)

/// Телеграф увода: у цели прорезается шов, чернила пути стягиваются к ней, издалека тянется нить еретика.
/proc/heretic_pocket_pull_fx(mob/living/user, mob/living/victim, turf/entry, pull_time, path_id)
	var/turf/place = get_turf(victim)
	if(!place)
		return
	var/ink = heretic_path_ink(path_id)
	var/warning = heretic_fx_theme_sound(path_id, "warning")
	if(warning)
		playsound(place, warning, HERETIC_FX_EVENT_VOLUME, TRUE)
	heretic_vfx_pulse(victim, ink, HERETIC_FX_OUTLINE_WIDE, max(pull_time, HERETIC_FX_PULL_MIN))
	if(pull_time <= 0)
		return
	new /obj/effect/temp_visual/heretic_vfx/pocket_seam(entry || place, ink, pull_time + HERETIC_FX_SEAM_TAIL, pull_time, HERETIC_FX_SEAM_ALPHA)
	heretic_vfx_gather(place, ink, HERETIC_FX_GATHER_RADIUS, pull_time)
	var/particles_type = heretic_fx_particles(path_id)
	if(particles_type && heretic_vfx_watched(place))
		heretic_vfx_converge(place, particles_type, HERETIC_FX_PULL_RADIUS, pull_time, pull_time / 2, HERETIC_FX_PULL_ARMS, HERETIC_FX_PULL_SWIRL)
	if(user && get_dist(user, victim) > 1)
		var/obj/effect/temp_visual/heretic_vfx/thread/thread = heretic_vfx_thread(user, victim, ink, pull_time)
		thread?.grow(pull_time / 2)
		heretic_vfx_pulse(user, ink, HERETIC_FX_OUTLINE_THIN, pull_time)

/// Уходящие в изнанку сплющиваются в щель и втягиваются к разрыву.
/proc/heretic_pocket_vanish_fx(list/travellers, turf/entry, path_id)
	var/list/tint = heretic_vfx_ink_tint(heretic_path_ink(path_id))
	for(var/mob/living/traveller as anything in travellers)
		var/turf/from = get_turf(traveller)
		if(!from)
			continue
		var/obj/effect/temp_visual/heretic_vfx/ghost/ghost = heretic_vfx_ghost(traveller, from, tint, HERETIC_FX_VANISH_TIME, TRUE)
		if(!ghost)
			continue
		ghost.alpha = ghost.model_share(HERETIC_FX_GHOST_ALPHA)
		var/matrix/squeezed = matrix(ghost.transform)
		squeezed.Scale(HERETIC_FX_VANISH_SQUEEZE, HERETIC_FX_VANISH_STRETCH)
		var/shift_x = entry && entry.z == from.z ? (entry.x - from.x) * world.icon_size : 0
		var/shift_y = entry && entry.z == from.z ? (entry.y - from.y) * world.icon_size : 0
		animate(ghost, transform = squeezed, alpha = 0, pixel_x = ghost.pixel_x + shift_x, pixel_y = ghost.pixel_y + shift_y, time = HERETIC_FX_VANISH_TIME, easing = QUAD_EASING | EASE_IN)

/// Разрыв распахивается из щели со вспышкой и выбросом частиц пути.
/proc/heretic_pocket_rift_open_fx(obj/effect/heretic_pocket_rift/rift, path_id)
	var/turf/place = get_turf(rift)
	if(!place)
		return
	var/matrix/slit = matrix(HERETIC_FX_SEAM_WIDTH, 0, 0, 0, HERETIC_FX_SEAM_HEIGHT, 0)
	rift.transform = slit
	animate(rift, transform = matrix(), time = HERETIC_FX_RIFT_OPEN, easing = BACK_EASING | EASE_OUT)
	var/ink = heretic_path_ink(path_id)
	heretic_vfx_flash(place, ink, HERETIC_FX_FLASH_RANGE, HERETIC_FX_FLASH_POWER, HERETIC_FX_FLASH_TIME)
	var/particles_type = heretic_fx_particles(path_id)
	if(particles_type && heretic_vfx_watched(place))
		heretic_vfx_burst(place, particles_type)
	playsound(place, 'sound/magic/voidpull.ogg', HERETIC_FX_EVENT_VOLUME, TRUE)

/// Удалённый разрыв оставляет копию, которая стягивается в щель.
/proc/heretic_pocket_rift_close_fx(obj/effect/heretic_pocket_rift/rift, path_id)
	var/turf/place = get_turf(rift)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_vfx/pocket_seam(place, heretic_path_ink(path_id), HERETIC_FX_RIFT_CLOSE, 0)
	var/particles_type = heretic_fx_particles(path_id)
	if(particles_type && heretic_vfx_watched(place))
		heretic_vfx_burst(place, particles_type)

/// Изнанка истончается: оба разрыва мигают до конца, снаружи и внутри слышно предупреждение пути.
/proc/heretic_pocket_warning_fx(datum/heretic_pocket/pocket)
	var/warning = heretic_fx_theme_sound(pocket?.owner?.selected_path, "warning")
	for(var/obj/effect/heretic_pocket_rift/rift as anything in list(pocket?.rift, pocket?.inner_rift))
		if(QDELETED(rift))
			continue
		var/blinks = max(1, round(HERETIC_POCKET_WARNING / (HERETIC_FX_WARNING_BLINK * 2)))
		animate(rift, alpha = HERETIC_FX_WARNING_ALPHA, time = HERETIC_FX_WARNING_BLINK, loop = blinks, easing = SINE_EASING)
		animate(alpha = 255, time = HERETIC_FX_WARNING_BLINK, easing = SINE_EASING)
		if(warning)
			playsound(rift, warning, HERETIC_FX_EVENT_VOLUME, TRUE)
	if(pocket?.inner_rift)
		heretic_vfx_quake(pocket.inner_rift, HERETIC_FX_QUAKE_RADIUS, HERETIC_FX_QUAKE_STRENGTH, HERETIC_FX_QUAKE_TIME)

/// Разрыв рвут руками: кромка дрожит всё время попытки.
/proc/heretic_pocket_tear_fx(obj/effect/heretic_pocket_rift/rift, tear_time)
	if(QDELETED(rift))
		return
	var/shakes = max(1, round(tear_time / (HERETIC_FX_TEAR_STEP * 3)))
	animate(rift, pixel_x = HERETIC_FX_TEAR_SHAKE, time = HERETIC_FX_TEAR_STEP, loop = shakes)
	animate(pixel_x = -HERETIC_FX_TEAR_SHAKE, time = HERETIC_FX_TEAR_STEP)
	animate(pixel_x = 0, time = HERETIC_FX_TEAR_STEP)
	playsound(rift, 'sound/effects/dimensional_rend.ogg', HERETIC_FX_EVENT_VOLUME, TRUE)

/proc/heretic_pocket_tear_stop_fx(obj/effect/heretic_pocket_rift/rift)
	if(QDELETED(rift))
		return
	animate(rift, pixel_x = 0, time = HERETIC_FX_TEAR_STEP)

/// Разрыв закрыли святыней или разорвали руками: вспышка у разрыва, всех рядом встряхивает.
/proc/heretic_pocket_breach_fx(obj/effect/heretic_pocket_rift/rift, holy = FALSE)
	var/turf/place = get_turf(rift)
	if(!place)
		return
	heretic_vfx_flash(place, holy ? HERETIC_FX_HOLY_INK : heretic_path_ink(rift.pocket?.owner?.selected_path), HERETIC_FX_FLASH_RANGE, HERETIC_FX_BREACH_POWER, HERETIC_FX_FLASH_TIME)
	heretic_vfx_quake(place, HERETIC_FX_QUAKE_RADIUS, HERETIC_FX_QUAKE_STRENGTH, HERETIC_FX_QUAKE_TIME)
	if(holy)
		playsound(place, 'sound/magic/Teleport_diss.ogg', HERETIC_FX_LOUD_VOLUME, TRUE)

/// Выход из изнанки: воздух расходится щелью, фигура проступает из неё, ремесло пути рядом отзывается.
/proc/heretic_pocket_exit_fx(mob/living/traveller, turf/landing, path_id)
	landing ||= get_turf(traveller)
	if(!landing)
		return
	var/ink = heretic_path_ink(path_id)
	new /obj/effect/temp_visual/heretic_vfx/pocket_seam(landing, ink)
	var/obj/effect/temp_visual/heretic_vfx/ghost/ghost = heretic_vfx_ghost(traveller, landing, heretic_vfx_ink_tint(ink), HERETIC_FX_STEP_OUT, TRUE)
	if(ghost)
		var/matrix/natural = matrix(ghost.transform)
		var/matrix/slit = matrix(natural)
		slit.Scale(HERETIC_FX_VANISH_SQUEEZE, HERETIC_FX_VANISH_STRETCH)
		ghost.transform = slit
		ghost.alpha = 0
		animate(ghost, transform = natural, alpha = ghost.model_share(HERETIC_FX_GHOST_ALPHA), time = HERETIC_FX_STEP_OUT / 3, easing = CUBIC_EASING | EASE_OUT)
		animate(alpha = 0, time = HERETIC_FX_STEP_OUT * 2 / 3, easing = SINE_EASING | EASE_IN)
	heretic_vfx_flash(landing, ink, HERETIC_FX_FLASH_RANGE, HERETIC_FX_FLASH_POWER, HERETIC_FX_FLASH_TIME)
	var/particles_type = heretic_fx_particles(path_id)
	if(particles_type && heretic_vfx_watched(landing))
		heretic_vfx_burst(landing, particles_type)
	var/escape = heretic_fx_theme_sound(path_id, "escape")
	if(escape)
		playsound(landing, escape, HERETIC_FX_EVENT_VOLUME, TRUE)
	for(var/atom/nearby as anything in range(1, landing))
		if(nearby.GetComponent(/datum/component/heretic_craft))
			heretic_vfx_pulse(nearby, ink, HERETIC_FX_OUTLINE_WIDE, HERETIC_FX_STEP_OUT)

/// Вещи и цель выпадают у входа схлопнувшейся изнанки.
/proc/heretic_pocket_drop_fx(turf/exit, path_id)
	if(!exit || !heretic_vfx_watched(exit))
		return
	var/particles_type = heretic_fx_particles(path_id)
	if(particles_type)
		heretic_vfx_burst(exit, particles_type)
	heretic_vfx_flash(exit, heretic_path_ink(path_id), HERETIC_FX_FLASH_RANGE, HERETIC_FX_FLASH_POWER, HERETIC_FX_FLASH_TIME)

// Отдача механик, которые подключаются одной строкой.

/// Сердце прижимает цель к полу: удар сердца, кольцо давит на неё, у ног поднимается пыль. Вызывать при наложении прижатия.
/proc/heretic_door_grip_fx(mob/living/victim)
	var/turf/place = get_turf(victim)
	if(!place)
		return
	playsound(place, 'sound/effects/singlebeat.ogg', HERETIC_FX_LOUD_VOLUME, TRUE)
	heretic_vfx_gather(place, HERETIC_FX_GRIP_INK, HERETIC_FX_GATHER_RADIUS, HERETIC_FX_GRIP_TIME)
	heretic_vfx_pulse(victim, HERETIC_FX_GRIP_INK, HERETIC_FX_OUTLINE_WIDE, HERETIC_FX_GRIP_TIME)
	new /obj/effect/temp_visual/heretic_path_feedback(place, "cloud_swirl", HERETIC_FX_GRIP_INK, HERETIC_FX_GRIP_DUST)
	heretic_vfx_quake(place, HERETIC_FX_QUAKE_SELF, HERETIC_FX_QUAKE_HIT, HERETIC_FX_GRIP_TIME)

/// Невидимый клинок бьёт отказавшегося от дуэли плашмя сверху: след клинка, искры, звон стали.
/proc/heretic_blade_refusal_fx(mob/living/target)
	var/turf/place = get_turf(target)
	if(!place)
		return
	var/ink = heretic_path_ink(PATH_BLADE, TRUE)
	new /obj/effect/temp_visual/heretic_blade_refusal(place)
	new /obj/effect/temp_visual/dir_setting/heretic_slash(place, SOUTH)
	heretic_vfx_spray(place, /particles/heretic_ascension/blade/sparks, HERETIC_FX_REFUSAL_SPRAY)
	heretic_vfx_flash(place, ink, HERETIC_FX_FLASH_NEAR, HERETIC_FX_FLASH_POWER, HERETIC_FX_FLASH_TIME)
	heretic_vfx_pulse(target, ink, HERETIC_FX_OUTLINE_WIDE, HERETIC_FX_REFUSAL_PULSE)
	heretic_vfx_quake(place, HERETIC_FX_QUAKE_SELF, HERETIC_FX_QUAKE_HIT, HERETIC_FX_REFUSAL_QUAKE)
	playsound(place, 'sound/weapons/slashmiss.ogg', HERETIC_FX_EVENT_VOLUME, TRUE)
	playsound(place, heretic_fx_theme_sound(PATH_BLADE, "hit"), HERETIC_FX_LOUD_VOLUME, TRUE)

/// Призрачный клинок поднят над целью и падает плашмя, раскалённый добела; гаснет после удара.
/obj/effect/temp_visual/heretic_blade_refusal
	icon = 'modular_bluemoon/icons/obj/heretic_blade_orbit.dmi'
	icon_state = "blade_orbit"
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_FX_REFUSAL_SWING + HERETIC_FX_REFUSAL_FADE

/obj/effect/temp_visual/heretic_blade_refusal/Initialize(mapload)
	. = ..()
	color = heretic_blade_flare_matrix()
	add_overlay(emissive_appearance(icon, icon_state))
	transform = heretic_blade_facing(HERETIC_FX_REFUSAL_RAISED, HERETIC_FX_REFUSAL_SCALE)
	pixel_y = HERETIC_FX_REFUSAL_LIFT
	alpha = HERETIC_FX_REFUSAL_ALPHA
	animate(src, transform = heretic_blade_facing(HERETIC_FX_REFUSAL_STRUCK, HERETIC_FX_REFUSAL_SCALE), pixel_y = 0, time = HERETIC_FX_REFUSAL_SWING, easing = QUAD_EASING | EASE_IN)
	animate(alpha = 0, time = HERETIC_FX_REFUSAL_FADE, easing = SINE_EASING | EASE_IN)

/// Замах к горлу: кольцо в стальных чернилах сжимается на цели, пока клинок идёт к ней.
/proc/heretic_blade_throat_fx(mob/living/victim, telegraph)
	var/ink = heretic_path_ink(PATH_BLADE, TRUE)
	heretic_vfx_gather(victim, ink, HERETIC_FX_GATHER_CLOSE, telegraph)
	heretic_vfx_pulse(victim, ink, HERETIC_FX_OUTLINE_THIN, telegraph)

/// Кукла тает: над рукой еретика капает воск, у цели шипит пар.
/proc/heretic_wax_melt_fx(mob/living/model, mob/living/caster)
	if(!QDELETED(caster))
		heretic_vfx_pulse(caster, heretic_path_ink(PATH_WAX, TRUE), HERETIC_FX_OUTLINE_THIN, HERETIC_WAX_PUPPET_SLEEP_CHANNEL)
		heretic_vfx_burst(caster, /particles/heretic_ascension/wax/drip)
	if(!QDELETED(model))
		playsound(model, 'modular_bluemoon/sound/heretic/wax_cast.ogg', HERETIC_FX_EVENT_VOLUME, TRUE)

/obj/effect/proc_holder/spell
	COOLDOWN_DECLARE(heretic_fizzle_cooldown)

/// Заклинание не сложилось под оглушением или в оковах: знаки пути гаснут у рук, видно и слышно рядом.
/obj/effect/proc_holder/spell/proc/heretic_fizzle_fx(mob/living/user)
	if(!isliving(user) || !COOLDOWN_FINISHED(src, heretic_fizzle_cooldown))
		return
	COOLDOWN_START(src, heretic_fizzle_cooldown, HERETIC_FX_FIZZLE_COOLDOWN)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/path_id = heretic?.selected_path
	heretic_vfx_pulse(user, heretic_path_ink(path_id), HERETIC_FX_OUTLINE_THIN, HERETIC_FX_FIZZLE_PULSE)
	var/particles_type = heretic_fx_particles(path_id)
	if(particles_type && heretic_vfx_watched(user))
		heretic_vfx_burst(user, particles_type, HERETIC_FX_CRAFT_BURST)
	playsound(user, 'sound/effects/light_flicker.ogg', HERETIC_FX_HOLD_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	user.balloon_alert(user, "знаки гаснут")

#undef HERETIC_FX_GRIP_INK
#undef HERETIC_FX_HOLY_INK
#undef HERETIC_FX_HOLD_FADE_IN
#undef HERETIC_FX_HOLD_FADE_OUT
#undef HERETIC_FX_QUIET_VOLUME
#undef HERETIC_FX_HOLD_VOLUME
#undef HERETIC_FX_EVENT_VOLUME
#undef HERETIC_FX_LOUD_VOLUME
#undef HERETIC_FX_CRAFT_PULSE
#undef HERETIC_FX_CRAFT_BURST
#undef HERETIC_FX_DISPEL_PULSE
#undef HERETIC_FX_SHAKE_PULSE
#undef HERETIC_FX_FLASH_RANGE
#undef HERETIC_FX_FLASH_POWER
#undef HERETIC_FX_FLASH_TIME
#undef HERETIC_FX_SEAM_WIDTH
#undef HERETIC_FX_SEAM_HEIGHT
#undef HERETIC_FX_SEAM_TAIL
#undef HERETIC_FX_SEAM_ALPHA
#undef HERETIC_FX_RIFT_OPEN
#undef HERETIC_FX_RIFT_CLOSE
#undef HERETIC_FX_PULL_MIN
#undef HERETIC_FX_PULL_RADIUS
#undef HERETIC_FX_PULL_ARMS
#undef HERETIC_FX_PULL_SWIRL
#undef HERETIC_FX_VANISH_TIME
#undef HERETIC_FX_VANISH_SQUEEZE
#undef HERETIC_FX_VANISH_STRETCH
#undef HERETIC_FX_STEP_OUT
#undef HERETIC_FX_GHOST_ALPHA
#undef HERETIC_FX_QUAKE_RADIUS
#undef HERETIC_FX_QUAKE_STRENGTH
#undef HERETIC_FX_QUAKE_TIME
#undef HERETIC_FX_TEAR_SHAKE
#undef HERETIC_FX_TEAR_STEP
#undef HERETIC_FX_WARNING_BLINK
#undef HERETIC_FX_WARNING_ALPHA
#undef HERETIC_FX_GRIP_TIME
#undef HERETIC_FX_GRIP_DUST
#undef HERETIC_FX_REFUSAL_PULSE
#undef HERETIC_FX_REFUSAL_QUAKE
#undef HERETIC_FX_REFUSAL_SWING
#undef HERETIC_FX_REFUSAL_FADE
#undef HERETIC_FX_REFUSAL_RAISED
#undef HERETIC_FX_REFUSAL_STRUCK
#undef HERETIC_FX_REFUSAL_SCALE
#undef HERETIC_FX_REFUSAL_LIFT
#undef HERETIC_FX_REFUSAL_ALPHA
#undef HERETIC_FX_REFUSAL_SPRAY
#undef HERETIC_FX_BREACH_POWER
#undef HERETIC_FX_OUTLINE_THIN
#undef HERETIC_FX_OUTLINE_WIDE
#undef HERETIC_FX_GATHER_CLOSE
#undef HERETIC_FX_GATHER_RADIUS
#undef HERETIC_FX_FLASH_NEAR
#undef HERETIC_FX_QUAKE_SELF
#undef HERETIC_FX_QUAKE_HIT
#undef HERETIC_FX_FIZZLE_COOLDOWN
#undef HERETIC_FX_FIZZLE_PULSE
