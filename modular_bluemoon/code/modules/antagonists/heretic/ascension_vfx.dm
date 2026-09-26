#define HERETIC_VFX_RING_ICON_SIZE 256
#define HERETIC_VFX_RING_RADIUS 118
#define HERETIC_VFX_RING_INNER 88
#define HERETIC_VFX_RING_OUTER 122
#define HERETIC_VFX_WAVE_START_SCALE 0.08
#define HERETIC_VFX_WAVE_HOLD 0.35
#define HERETIC_VFX_RIPPLE_FILTER "heretic_vfx_ripple"
#define HERETIC_VFX_RIPPLE_SIZE 3
#define HERETIC_VFX_RIPPLE_REPEAT 12
#define HERETIC_VFX_FLASH_TAIL_POWER 0.5
#define HERETIC_VFX_FLASH_TAIL_STRETCH 2.5
#define HERETIC_VFX_RISE_SHARE 0.3
#define HERETIC_VFX_PULSE_PRIORITY 10
#define HERETIC_VFX_RAYS_PRIORITY 11
#define HERETIC_VFX_RAYS_SIZE 72
#define HERETIC_VFX_RAYS_DENSITY 14
#define HERETIC_VFX_RAYS_THRESHOLD 0.25
#define HERETIC_VFX_RAYS_FACTOR 0.5
#define HERETIC_VFX_RAYS_TURN 8
#define HERETIC_CRESCENDO_EMITTERS 8
#define HERETIC_CRESCENDO_RADIUS 56
#define HERETIC_CRESCENDO_SPREAD 8
#define HERETIC_CRESCENDO_JITTER 0.3
#define HERETIC_CRESCENDO_TRAVEL (1.6 SECONDS)
#define HERETIC_CRESCENDO_EDGE_FADE (0.4 SECONDS)
#define HERETIC_CRESCENDO_COUNT 12
#define HERETIC_CRESCENDO_SHRINK -0.02
#define HERETIC_CRESCENDO_PULSE_LOW 40
#define HERETIC_CRESCENDO_QUAKE_RADIUS 5
#define HERETIC_CRESCENDO_QUAKE_TIME (0.3 SECONDS)
#define HERETIC_CRESCENDO_FADE (1.6 SECONDS)
#define HERETIC_CRESCENDO_OVERRUN (5 SECONDS)
#define HERETIC_CRESCENDO_LIGHT_STEPS 3
#define HERETIC_CRESCENDO_CANVAS 160
#define HERETIC_VFX_SPRAY_SPEED 5
#define HERETIC_VFX_SPRAY_SPREAD 0.45
#define HERETIC_VFX_GATHER_RISE 0.7
#define HERETIC_VFX_WATCH_RANGE 8
#define HERETIC_VFX_TINT_LIFT 0.35
#define HERETIC_VFX_TINT_GAIN 1.6
#define HERETIC_VFX_THREAD_MIN_SHARE 0.02
#define HERETIC_VFX_THREAD_SNAP_WIDTH 1.75
#define HERETIC_VFX_THREAD_SNAP_RISE 0.3
#define HERETIC_VFX_CONVERGE_MARGIN 32
#define HERETIC_VFX_CONVERGE_SPREAD 5
#define HERETIC_VFX_STREAM_MARGIN 64

/datum/heretic_path
	/// Частицы пути для вспышек вознесения. Спрайты несут свой цвет; чернила пути красят волну, лучи и свет.
	var/vfx_particles
	/// Второй оттенок пути для его эффектов; без него берутся чернила книги.
	var/vfx_accent

/datum/heretic_path/ash
	vfx_particles = /particles/heretic_ascension/ash

/datum/heretic_path/rust
	vfx_particles = /particles/heretic_ascension/rust
	vfx_accent = "#c8642a"

/datum/heretic_path/flesh
	vfx_particles = /particles/heretic_ascension/flesh
	vfx_accent = "#a3182b"

/datum/heretic_path/void
	vfx_particles = /particles/heretic_ascension/void

/datum/heretic_path/blade
	vfx_particles = /particles/heretic_ascension/blade
	vfx_accent = "#d9c8ff"

/datum/heretic_path/moon
	vfx_particles = /particles/heretic_ascension/moon

/datum/heretic_path/cosmic
	vfx_particles = /particles/heretic_ascension/cosmic
	vfx_accent = "#c9a6ff"

/datum/heretic_path/lock
	vfx_particles = /particles/heretic_ascension/lock

/datum/heretic_path/tide
	vfx_particles = /particles/heretic_ascension/tide

/datum/heretic_path/glass
	vfx_particles = /particles/heretic_ascension/glass

/datum/heretic_path/blood
	vfx_particles = /particles/heretic_ascension/blood
	vfx_accent = "#b3122f"

/datum/heretic_path/echo
	vfx_particles = /particles/heretic_ascension/echo

/datum/heretic_path/sand
	vfx_particles = /particles/heretic_ascension/sand

/datum/heretic_path/wax
	vfx_particles = /particles/heretic_ascension/wax
	vfx_accent = "#3fd0c6"

/datum/heretic_path/spirit
	vfx_particles = /particles/heretic_ascension/spirit

/// Чернила пути, а с accent - его второй оттенок, если он задан.
/proc/heretic_path_ink(path_id, accent = FALSE)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path)
		return COLOR_WHITE
	return (accent && path.vfx_accent) || path.book_ink

/// Есть ли рядом хоть один игрок: частые мелкие эффекты без зрителей не создаются.
/proc/heretic_vfx_watched(atom/center, radius = HERETIC_VFX_WATCH_RANGE)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return FALSE
	var/list/listeners = SSspatial_grid.initialized ? SSspatial_grid.orthogonal_range_search(center_turf, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, radius) : GLOB.player_list
	for(var/mob/witness as anything in listeners)
		var/turf/witness_turf = get_turf(witness)
		if(witness?.client && witness_turf?.z == center_turf.z && get_dist(witness_turf, center_turf) <= radius)
			return TRUE
	return FALSE

/// Волна в чернилах пути от центра до radius клеток и настоящее искажение пространства под ней.
/proc/heretic_vfx_shockwave(atom/center, color, radius = 7, duration = 1 SECONDS, offset_x = 0, offset_y = 0)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return null
	var/obj/effect/temp_visual/heretic_vfx/warp/warp = new(center_turf, radius, duration)
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = new(center_turf, color, radius, duration)
	for(var/obj/effect/temp_visual/heretic_vfx/part as anything in list(warp, wave))
		part.pixel_x += round(offset_x)
		part.pixel_y += round(offset_y)
	return wave

/// Кольцо стягивается из radius клеток в центр, светлея к концу: предвестие удара.
/proc/heretic_vfx_gather(atom/center, color, radius = 3, duration = 0.8 SECONDS)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return null
	return new /obj/effect/temp_visual/heretic_vfx/gather(center_turf, color, radius, duration)

/// Выброс частиц пути: эмиттер порождает их duration и удаляется, когда долетает последняя.
/proc/heretic_vfx_burst(atom/center, particles_type, duration = HERETIC_VFX_BURST_TIME, glow = TRUE)
	var/turf/center_turf = get_turf(center)
	if(!center_turf || !ispath(particles_type, /particles/heretic_ascension))
		return null
	return new /obj/effect/temp_visual/heretic_vfx/burst(center_turf, particles_type, duration, glow)

/// Выброс частиц в сторону angle (по часовой от севера) из точки в offset пикселях от центра клетки.
/proc/heretic_vfx_spray(atom/center, particles_type, angle, offset = 0, speed = HERETIC_VFX_SPRAY_SPEED, duration = HERETIC_VFX_BURST_TIME, glow = TRUE)
	var/obj/effect/temp_visual/heretic_vfx/burst/burst = heretic_vfx_burst(center, particles_type, duration, glow)
	if(!burst)
		return null
	var/dir_x = sin(angle)
	var/dir_y = cos(angle)
	burst.pixel_x = round(dir_x * offset)
	burst.pixel_y = round(dir_y * offset)
	var/spread = speed * HERETIC_VFX_SPRAY_SPREAD
	burst.particles.velocity = generator("box", list(dir_x * speed - spread, dir_y * speed - spread, 0), list(dir_x * speed + spread, dir_y * speed + spread, 0))
	return burst

/// Поток частиц от source к destination: каждая долетает до цели ровно за своё время жизни и гаснет на ней.
/proc/heretic_vfx_stream(atom/source, atom/destination, particles_type, duration = HERETIC_VFX_BURST_TIME)
	var/turf/start = get_turf(source)
	var/turf/finish = get_turf(destination)
	if(!start || !finish || start.z != finish.z)
		return null
	var/obj/effect/temp_visual/heretic_vfx/burst/burst = heretic_vfx_burst(start, particles_type, duration)
	if(!burst)
		return null
	var/particles/flow = burst.particles
	var/travel = flow.lifespan
	var/delta_x = (finish.x - start.x) * world.icon_size
	var/delta_y = (finish.y - start.y) * world.icon_size
	flow.width = max(flow.width, 2 * abs(delta_x) + HERETIC_VFX_STREAM_MARGIN)
	flow.height = max(flow.height, 2 * abs(delta_y) + HERETIC_VFX_STREAM_MARGIN)
	flow.velocity = list(delta_x / travel, delta_y / travel, 0)
	flow.gravity = list(0, 0, 0)
	flow.friction = 0
	return burst

/// Частицы стягиваются к центру с radius пикселей по arms рукавам; swirl закручивает их, но долетают они точно в центр.
/proc/heretic_vfx_converge(atom/center, particles_type, radius = 64, travel = 0.8 SECONDS, emit_time = 0.4 SECONDS, arms = 6, swirl = 0)
	var/turf/center_turf = get_turf(center)
	if(!center_turf || !ispath(particles_type, /particles/heretic_ascension) || arms <= 0)
		return null
	return new /obj/effect/temp_visual/heretic_vfx/converge(center_turf, particles_type, radius, travel, emit_time, arms, swirl)

/// Нить от source к target в чернилах пути: отрезок растягивается вдоль линии; дальше её ведут grow, reel, snap и fizzle.
/proc/heretic_vfx_thread(atom/source, atom/target, ink, lifetime = 1 SECONDS, width = 1)
	var/turf/start = get_turf(source)
	var/turf/finish = get_turf(target)
	if(!start || !finish || start == finish || start.z != finish.z)
		return null
	return new /obj/effect/temp_visual/heretic_vfx/thread(start, finish, ink, lifetime, width)

/// Отпечаток облика model на клетке place; движение ведёт вызвавший, сам отпечаток лишь исчезает в срок. Невидимый образец следа не оставляет.
/proc/heretic_vfx_ghost(atom/model, atom/place, tint, lifetime = 0.5 SECONDS, glow = FALSE)
	if(QDELETED(model) || model.invisibility)
		return null
	var/turf/place_turf = get_turf(place || model)
	if(!place_turf)
		return null
	var/obj/effect/temp_visual/heretic_vfx/ghost/ghost = new(place_turf, model, tint, lifetime, glow)
	return QDELETED(ghost) ? null : ghost

/// Матрица призрака: облик становится чернилами пути, тени поднимаются до lift, светлое остаётся ярким.
/proc/heretic_vfx_ink_tint(ink, lift = HERETIC_VFX_TINT_LIFT)
	var/list/channels = ReadRGB(ink)
	if(length(channels) < 3)
		return null
	var/list/tint = list()
	for(var/luma in list(LUMA_R, LUMA_G, LUMA_B))
		for(var/channel in 1 to 3)
			tint += luma * HERETIC_VFX_TINT_GAIN * (1 - lift) * channels[channel] / 255
		tint += 0
	tint += list(0, 0, 0, 1)
	for(var/channel in 1 to 3)
		tint += lift * channels[channel] / 255
	tint += 0
	return tint

/// Постоянный эмиттер на атоме: частицы идут от носителя, пока его не снимут.
/proc/heretic_vfx_attach_particles(atom/movable/host, particles_type, glow = TRUE)
	if(QDELETED(host))
		return null
	var/obj/effect/abstract/heretic_particle_holder/holder = new(null, particles_type, glow)
	if(QDELETED(holder))
		return null
	host.vis_contents += holder
	return holder

/// Снятый эмиттер больше не порождает частиц, уже летящие догорают на месте носителя.
/proc/heretic_vfx_release_particles(atom/movable/host, obj/effect/abstract/heretic_particle_holder/holder)
	if(QDELETED(holder))
		return
	var/turf/place = get_turf(host)
	if(host)
		host.vis_contents -= holder
		holder.pixel_x += host.pixel_x
		holder.pixel_y += host.pixel_y
	if(!place || !holder.particles)
		qdel(holder)
		return
	holder.particles.spawning = 0
	holder.layer = ABOVE_MOB_LAYER
	holder.forceMove(place)
	QDEL_IN(holder, holder.particles.lifespan)

/// Рисунок на носителе: проступает за fade_in и держится, пока его не погасят fade_out или удалением. upright не даёт ему лечь вместе с носителем.
/proc/heretic_vfx_attach(atom/movable/host, visual_icon, visual_state, target_alpha = 255, fade_in = HERETIC_VFX_ATTACH_FADE, glow = TRUE, upright = TRUE)
	if(QDELETED(host))
		return null
	var/obj/effect/abstract/heretic_vfx_attached/visual = new(null, host, visual_icon, visual_state, target_alpha, fade_in, glow, upright)
	return QDELETED(visual) ? null : visual

/// Тряска экрана у игроков в радиусе, ближе к центру сильнее. Возвращает число встряхнутых.
/proc/heretic_vfx_quake(atom/center, radius = 7, strength = 1, duration = 0.5 SECONDS)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return 0
	var/list/listeners = SSspatial_grid.initialized ? SSspatial_grid.orthogonal_range_search(center_turf, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, radius) : GLOB.player_list
	var/shaken = 0
	for(var/mob/witness as anything in listeners)
		var/turf/witness_turf = get_turf(witness)
		if(!witness?.client || !witness_turf || witness_turf.z != center_turf.z)
			continue
		var/distance = max(0, get_dist(witness_turf, center_turf))
		if(distance > radius)
			continue
		shake_camera(witness, duration, strength * (1 - distance / (radius + 1)))
		shaken++
	return shaken

/// Вспышка света в цвете пути: яркий пик и вдвое слабее - дольше, чтобы свет не обрывался разом.
/proc/heretic_vfx_flash(atom/center, color, range = 4, power = 2, duration = 0.5 SECONDS)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return
	center_turf.flash_lighting_fx(range, power, color, duration)
	center_turf.flash_lighting_fx(range, power * HERETIC_VFX_FLASH_TAIL_POWER, color, duration * HERETIC_VFX_FLASH_TAIL_STRETCH)

/// Короткий контур на атоме: вспыхивает, гаснет, затем фильтр снимается.
/proc/heretic_vfx_pulse(atom/target, color, size = 2, duration = 0.4 SECONDS)
	if(QDELETED(target))
		return FALSE
	target.add_filter(HERETIC_VFX_PULSE_FILTER, HERETIC_VFX_PULSE_PRIORITY, outline_filter(size = 0, color = color))
	animate(target.get_filter(HERETIC_VFX_PULSE_FILTER), size = size, time = duration * HERETIC_VFX_RISE_SHARE, easing = SINE_EASING | EASE_OUT)
	animate(size = 0, time = duration * (1 - HERETIC_VFX_RISE_SHARE), easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(target, TYPE_PROC_REF(/atom, remove_filter), HERETIC_VFX_PULSE_FILTER), duration, TIMER_UNIQUE | TIMER_OVERRIDE)
	return TRUE

/// Лучи из-за спины: раскрываются, проворачиваются и гаснут, затем фильтр снимается.
/proc/heretic_vfx_rays(atom/target, color, duration = 1.5 SECONDS)
	if(QDELETED(target))
		return FALSE
	target.add_filter(HERETIC_VFX_RAYS_FILTER, HERETIC_VFX_RAYS_PRIORITY, rays_filter(size = 0, color = color, density = HERETIC_VFX_RAYS_DENSITY, threshold = HERETIC_VFX_RAYS_THRESHOLD, factor = HERETIC_VFX_RAYS_FACTOR, flags = FILTER_UNDERLAY))
	animate(target.get_filter(HERETIC_VFX_RAYS_FILTER), size = HERETIC_VFX_RAYS_SIZE, offset = HERETIC_VFX_RAYS_TURN, time = duration * HERETIC_VFX_RISE_SHARE, easing = CUBIC_EASING | EASE_OUT)
	animate(size = 0, offset = HERETIC_VFX_RAYS_TURN * 2, time = duration * (1 - HERETIC_VFX_RISE_SHARE), easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(target, TYPE_PROC_REF(/atom, remove_filter), HERETIC_VFX_RAYS_FILTER), duration, TIMER_UNIQUE | TIMER_OVERRIDE)
	return TRUE

/// Матрица перекраски серой заготовки чернилами пути: серый 0.5 даёт сами чернила, белый остаётся белым.
/proc/heretic_vfx_ink_ramp(ink)
	var/list/channels = ReadRGB(ink)
	if(length(channels) < 3)
		return null
	var/list/scale = list()
	var/list/offset = list()
	for(var/channel in 1 to 3)
		var/level = channels[channel] / 255
		scale += 2 * (1 - level)
		offset += 2 * level - 1
	return list(scale[1], 0, 0, 0, 0, scale[2], 0, 0, 0, 0, scale[3], 0, 0, 0, 0, 1, offset[1], offset[2], offset[3], 0)

/// Матрица заливки чернилами: любой цвет становится цветом пути, прозрачность остаётся своей.
/proc/heretic_vfx_ink_fill(ink)
	var/list/channels = ReadRGB(ink)
	if(length(channels) < 3)
		return null
	return list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, channels[1] / 255, channels[2] / 255, channels[3] / 255, 0)

/// Светящаяся копия атома: то, что он рисует (частицы тоже), видно в темноте в своём цвете и гаснет вместе с ним.
/proc/heretic_vfx_attach_glow(atom/movable/source)
	if(!source.render_target)
		source.render_target = REF(source)
	var/obj/effect/abstract/heretic_vfx_glow/glow = new(null, source.render_target)
	source.vis_contents += glow
	return glow

/obj/effect/abstract/heretic_vfx_glow
	icon = null
	plane = EMISSIVE_PLANE
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_TRANSFORM | RESET_COLOR | RESET_ALPHA
	vis_flags = NONE

/obj/effect/abstract/heretic_vfx_glow/Initialize(mapload, render_from)
	. = ..()
	render_source = render_from
	color = GLOB.emissive_color

/// Эмиттер в vis_contents носителя: цвет и поворот носителя его не трогают, свой поворот работает; прозрачным носителем гаснет вместе с ним.
/obj/effect/abstract/heretic_particle_holder
	icon = null
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE
	var/obj/effect/abstract/heretic_vfx_glow/glow

/obj/effect/abstract/heretic_particle_holder/Initialize(mapload, particles_type, add_glow = TRUE)
	. = ..()
	if(!ispath(particles_type, /particles))
		return INITIALIZE_HINT_QDEL
	particles = new particles_type
	if(add_glow)
		glow = heretic_vfx_attach_glow(src)

/obj/effect/abstract/heretic_particle_holder/Destroy()
	vis_contents -= glow
	QDEL_NULL(glow)
	particles = null
	return ..()

/// Рисунок в vis_contents носителя: цвет носителя его не трогает, прозрачность наследуется; удаляясь, сам снимается с носителя.
/obj/effect/abstract/heretic_vfx_attached
	icon = null
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE
	var/datum/weakref/host_ref
	var/obj/effect/abstract/heretic_vfx_glow/glow
	var/fading = FALSE

/obj/effect/abstract/heretic_vfx_attached/Initialize(mapload, atom/movable/host, visual_icon, visual_state, target_alpha = 255, fade_in = HERETIC_VFX_ATTACH_FADE, add_glow = TRUE, upright = TRUE)
	. = ..()
	if(QDELETED(host) || !visual_icon)
		return INITIALIZE_HINT_QDEL
	if(upright)
		appearance_flags |= RESET_TRANSFORM
	icon = visual_icon
	icon_state = visual_state
	host_ref = WEAKREF(host)
	host.vis_contents += src
	if(add_glow)
		glow = heretic_vfx_attach_glow(src)
	alpha = 0
	animate(src, alpha = target_alpha, time = fade_in, easing = SINE_EASING | EASE_OUT)

/// Гаснет за fade_time и удаляется; повторный вызов не продлевает угасание.
/obj/effect/abstract/heretic_vfx_attached/proc/fade_out(fade_time = HERETIC_VFX_ATTACH_FADE)
	if(fading || QDELETED(src))
		return
	fading = TRUE
	animate(src, alpha = 0, time = fade_time, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, fade_time)

/obj/effect/abstract/heretic_vfx_attached/Destroy()
	var/atom/movable/host = host_ref?.resolve()
	if(host)
		host.vis_contents -= src
	host_ref = null
	vis_contents -= glow
	QDEL_NULL(glow)
	return ..()

/obj/effect/temp_visual/heretic_vfx
	icon = null
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE

/// Вырастает от точки до radius клеток с замедлением и гаснет во второй части пути.
/obj/effect/temp_visual/heretic_vfx/proc/expand(radius)
	pixel_x = (world.icon_size - HERETIC_VFX_RING_ICON_SIZE) / 2
	pixel_y = pixel_x
	var/end_scale = radius * world.icon_size / HERETIC_VFX_RING_RADIUS
	transform = matrix(HERETIC_VFX_WAVE_START_SCALE, 0, 0, 0, HERETIC_VFX_WAVE_START_SCALE, 0)
	animate(src, transform = matrix(end_scale, 0, 0, 0, end_scale, 0), time = duration, easing = CUBIC_EASING | EASE_OUT)
	animate(src, alpha = 255, time = duration * HERETIC_VFX_WAVE_HOLD, flags = ANIMATION_PARALLEL)
	animate(alpha = 0, time = duration * (1 - HERETIC_VFX_WAVE_HOLD), easing = SINE_EASING | EASE_IN)

/// Видимое кольцо волны: пока фронт держит яркость, по полосе кольца бежит рябь, затем стихает вместе с ним.
/obj/effect/temp_visual/heretic_vfx/shockwave
	icon = 'modular_bluemoon/icons/effects/heretic_shockwave.dmi'
	icon_state = "ring"
	layer = BELOW_MOB_LAYER
	appearance_flags = NONE

/obj/effect/temp_visual/heretic_vfx/shockwave/Initialize(mapload, ink, radius = 7, lifetime = 1 SECONDS)
	duration = lifetime
	. = ..()
	color = heretic_vfx_ink_ramp(ink || COLOR_WHITE)
	add_overlay(emissive_appearance(icon, icon_state))
	add_filter(HERETIC_VFX_RIPPLE_FILTER, 1, ripple_filter(radius = HERETIC_VFX_RING_INNER, size = HERETIC_VFX_RIPPLE_SIZE, repeat = HERETIC_VFX_RIPPLE_REPEAT))
	var/hold_radius = HERETIC_VFX_RING_INNER + (HERETIC_VFX_RING_OUTER - HERETIC_VFX_RING_INNER) * HERETIC_VFX_WAVE_HOLD
	animate(get_filter(HERETIC_VFX_RIPPLE_FILTER), radius = hold_radius, time = lifetime * HERETIC_VFX_WAVE_HOLD)
	animate(radius = HERETIC_VFX_RING_OUTER, size = 0, time = lifetime * (1 - HERETIC_VFX_WAVE_HOLD), easing = SINE_EASING | EASE_IN)
	expand(radius)

/// Та же волна картой смещения: пол и стены гнутся под фронтом и отыгрывают назад за ним.
/obj/effect/temp_visual/heretic_vfx/warp
	icon = 'modular_bluemoon/icons/effects/heretic_shockwave.dmi'
	icon_state = "warp"
	plane = GRAVITY_PULSE_PLANE
	appearance_flags = NONE

/obj/effect/temp_visual/heretic_vfx/warp/Initialize(mapload, radius = 7, lifetime = 1 SECONDS)
	duration = lifetime
	. = ..()
	expand(radius)

/obj/effect/temp_visual/heretic_vfx/gather
	icon = 'modular_bluemoon/icons/effects/heretic_shockwave.dmi'
	icon_state = "ring"
	layer = BELOW_MOB_LAYER
	appearance_flags = NONE

/obj/effect/temp_visual/heretic_vfx/gather/Initialize(mapload, ink, radius = 3, lifetime = 0.8 SECONDS)
	duration = lifetime
	. = ..()
	color = heretic_vfx_ink_ramp(ink || COLOR_WHITE)
	add_overlay(emissive_appearance(icon, icon_state))
	pixel_x = (world.icon_size - HERETIC_VFX_RING_ICON_SIZE) / 2
	pixel_y = pixel_x
	var/start_scale = radius * world.icon_size / HERETIC_VFX_RING_RADIUS
	transform = matrix(start_scale, 0, 0, 0, start_scale, 0)
	alpha = 0
	animate(src, transform = matrix(HERETIC_VFX_WAVE_START_SCALE, 0, 0, 0, HERETIC_VFX_WAVE_START_SCALE, 0), time = lifetime, easing = QUAD_EASING | EASE_IN)
	animate(src, alpha = 255, time = lifetime * HERETIC_VFX_GATHER_RISE, easing = SINE_EASING | EASE_IN, flags = ANIMATION_PARALLEL)
	animate(alpha = 0, time = lifetime * (1 - HERETIC_VFX_GATHER_RISE), easing = SINE_EASING | EASE_IN)

/obj/effect/temp_visual/heretic_vfx/burst
	layer = ABOVE_MOB_LAYER
	var/obj/effect/abstract/heretic_vfx_glow/glow

/obj/effect/temp_visual/heretic_vfx/burst/Initialize(mapload, particles_type, emit_time = HERETIC_VFX_BURST_TIME, add_glow = TRUE)
	if(ispath(particles_type, /particles/heretic_ascension))
		var/particles/emitter = new particles_type
		particles = emitter
		duration = emit_time + emitter.lifespan
	. = ..()
	if(!particles)
		return INITIALIZE_HINT_QDEL
	if(add_glow)
		glow = heretic_vfx_attach_glow(src)
	addtimer(CALLBACK(src, PROC_REF(stop_emitting)), emit_time)

/obj/effect/temp_visual/heretic_vfx/burst/proc/stop_emitting()
	if(particles)
		particles.spawning = 0

/obj/effect/temp_visual/heretic_vfx/burst/Destroy()
	vis_contents -= glow
	QDEL_NULL(glow)
	particles = null
	return ..()

/obj/effect/temp_visual/heretic_vfx/converge
	layer = ABOVE_MOB_LAYER
	var/list/arms = list()
	var/obj/effect/abstract/heretic_vfx_glow/glow

/obj/effect/temp_visual/heretic_vfx/converge/Initialize(mapload, particles_type, radius = 64, travel = 0.8 SECONDS, emit_time = 0.4 SECONDS, arm_count = 6, swirl = 0)
	duration = emit_time + travel
	. = ..()
	if(!ispath(particles_type, /particles/heretic_ascension) || arm_count <= 0)
		return INITIALIZE_HINT_QDEL
	for(var/index in 1 to arm_count)
		var/obj/effect/abstract/heretic_vfx_converge_arm/arm = new(null, particles_type, index * 360 / arm_count, radius, travel, swirl)
		arms += arm
		vis_contents += arm
	glow = heretic_vfx_attach_glow(src)
	addtimer(CALLBACK(src, PROC_REF(stop_emitting)), emit_time)

/obj/effect/temp_visual/heretic_vfx/converge/proc/stop_emitting()
	for(var/obj/effect/abstract/heretic_vfx_converge_arm/arm as anything in arms)
		arm.particles?.spawning = 0

/obj/effect/temp_visual/heretic_vfx/converge/Destroy()
	vis_contents.Cut()
	QDEL_LIST(arms)
	QDEL_NULL(glow)
	return ..()

/// Рукав сходящихся частиц: постоянное притяжение подобрано так, что с любой закруткой частица приходит в центр к концу жизни.
/obj/effect/abstract/heretic_vfx_converge_arm
	icon = null
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_ALPHA | RESET_COLOR | PIXEL_SCALE
	var/start_x = 0
	var/start_y = 0

/obj/effect/abstract/heretic_vfx_converge_arm/Initialize(mapload, particles_type, angle = 0, radius = 64, travel = 0.8 SECONDS, swirl = 0)
	. = ..()
	if(!ispath(particles_type, /particles/heretic_ascension) || travel <= 0)
		return INITIALIZE_HINT_QDEL
	var/particles/gather = new particles_type
	gather.width = radius * 2 + HERETIC_VFX_CONVERGE_MARGIN
	gather.height = gather.width
	start_x = radius * sin(angle)
	start_y = radius * cos(angle)
	var/tangent_x = swirl * radius / travel * cos(angle)
	var/tangent_y = -swirl * radius / travel * sin(angle)
	var/pull = 2 / (travel * travel)
	gather.position = generator("box", list(start_x - HERETIC_VFX_CONVERGE_SPREAD, start_y - HERETIC_VFX_CONVERGE_SPREAD, 0), list(start_x + HERETIC_VFX_CONVERGE_SPREAD, start_y + HERETIC_VFX_CONVERGE_SPREAD, 0))
	gather.velocity = list(tangent_x, tangent_y, 0)
	gather.gravity = list(-(start_x + tangent_x * travel) * pull, -(start_y + tangent_y * travel) * pull, 0)
	gather.drift = list(0, 0, 0)
	gather.friction = 0
	gather.lifespan = travel
	gather.fadein = min(gather.fadein, travel / 4)
	gather.fade = min(gather.fade, travel / 3)
	particles = gather

/obj/effect/abstract/heretic_vfx_converge_arm/Destroy()
	particles = null
	return ..()

/// Растянутый отрезок нити: доли длины от начала задают, какая часть линии видна.
/obj/effect/temp_visual/heretic_vfx/thread
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "vfx_thread"
	layer = ABOVE_MOB_LAYER
	appearance_flags = NONE
	var/angle = 0
	var/length = 0
	var/width = 1
	var/settled = FALSE

/obj/effect/temp_visual/heretic_vfx/thread/Initialize(mapload, turf/finish, ink, lifetime = 1 SECONDS, thread_width = 1)
	duration = lifetime
	. = ..()
	if(!isturf(finish) || !isturf(loc) || finish == loc)
		return INITIALIZE_HINT_QDEL
	color = heretic_vfx_ink_ramp(ink || COLOR_WHITE)
	add_overlay(emissive_appearance(icon, icon_state))
	width = thread_width
	var/delta_x = (finish.x - x) * world.icon_size
	var/delta_y = (finish.y - y) * world.icon_size
	length = sqrt(delta_x * delta_x + delta_y * delta_y)
	angle = Get_Angle(loc, finish)
	transform = span(0, 1)

/// Матрица видимой части нити от доли from_share до доли to_share её длины.
/obj/effect/temp_visual/heretic_vfx/thread/proc/span(from_share, to_share, span_width = width)
	var/share = max(to_share - from_share, HERETIC_VFX_THREAD_MIN_SHARE)
	var/matrix/line = matrix()
	line.Scale(span_width, length * share / world.icon_size)
	line.Translate(0, length * (min(from_share, 1 - share) + share / 2))
	line.Turn(angle)
	return line

/// Нить прорастает от начала к концу.
/obj/effect/temp_visual/heretic_vfx/thread/proc/grow(time)
	transform = span(0, 0)
	alpha = 0
	animate(src, transform = span(0, 1), alpha = 255, time = time, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_LINEAR_TRANSFORM)

/// Нить втягивается в конец: начало бежит к цели.
/obj/effect/temp_visual/heretic_vfx/thread/proc/reel(time)
	finish_in(time)
	animate(src, transform = span(1, 1), time = time, easing = QUAD_EASING | EASE_IN, flags = ANIMATION_LINEAR_TRANSFORM)

/// Нить вспыхивает во всю толщину и уходит в конец.
/obj/effect/temp_visual/heretic_vfx/thread/proc/snap(time)
	finish_in(time)
	animate(src, transform = span(0, 1, width * HERETIC_VFX_THREAD_SNAP_WIDTH), alpha = 255, time = time * HERETIC_VFX_THREAD_SNAP_RISE, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_LINEAR_TRANSFORM)
	animate(transform = span(1, 1), alpha = 0, time = time * (1 - HERETIC_VFX_THREAD_SNAP_RISE), easing = QUAD_EASING | EASE_IN, flags = ANIMATION_LINEAR_TRANSFORM)

/// Нить гаснет, не вспыхнув.
/obj/effect/temp_visual/heretic_vfx/thread/proc/fizzle(time)
	finish_in(time)
	animate(src, alpha = 0, time = time, easing = SINE_EASING | EASE_IN)

/obj/effect/temp_visual/heretic_vfx/thread/proc/finish_in(time)
	settled = TRUE
	deltimer(timerid)
	timerid = QDEL_IN_STOPPABLE(src, time)

/obj/effect/temp_visual/heretic_vfx/ghost
	var/obj/effect/abstract/heretic_vfx_glow/glow
	var/model_alpha = 255
	var/peak_alpha = 0

/obj/effect/temp_visual/heretic_vfx/ghost/Initialize(mapload, atom/model, tint, lifetime = 0.5 SECONDS, add_glow = FALSE)
	duration = lifetime
	if(model)
		appearance = model.appearance
		render_target = null
		model_alpha = model.alpha
		if(tint)
			color = tint
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	. = ..()
	if(!model || model.invisibility)
		return INITIALIZE_HINT_QDEL
	if(add_glow)
		glow = heretic_vfx_attach_glow(src)

/// Прозрачность, до которой проявится призрак, в долях облика: полупрозрачный образец оставляет и призрак бледнее.
/obj/effect/temp_visual/heretic_vfx/ghost/proc/model_share(target_alpha)
	peak_alpha = round(target_alpha * model_alpha / 255)
	return peak_alpha

/obj/effect/temp_visual/heretic_vfx/ghost/Destroy()
	vis_contents -= glow
	QDEL_NULL(glow)
	return ..()

/particles/heretic_ascension
	icon = 'modular_bluemoon/icons/effects/heretic_particles.dmi'
	width = 256
	height = 256
	count = HERETIC_VFX_MAX_PARTICLES
	spawning = HERETIC_VFX_MAX_SPAWNING
	lifespan = 1.5 SECONDS
	fade = 0.6 SECONDS
	position = generator("circle", 0, 8)
	velocity = generator("circle", 2, 4)
	friction = 0.06

/// Пепел: угли взлетают и тлеют, их сносит тягой вверх.
/particles/heretic_ascension/ash
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("ash_1" = 3, "ash_2" = 2, "ash_3" = 1)
	velocity = generator("circle", 3, 6)
	gravity = list(0, 0.25)
	friction = 0.08
	drift = generator("box", list(-0.3, 0, 0), list(0.3, 0.2, 0))
	lifespan = 1.8 SECONDS
	fade = 0.8 SECONDS

/// Ржавчина: хлопья расползаются, кувыркаются и осыпаются.
/particles/heretic_ascension/rust
	icon_state = list("rust_flake_1" = 2, "rust_flake_2" = 2, "rust_flake_3" = 3)
	velocity = generator("circle", 2, 4)
	gravity = list(0, -0.2)
	friction = 0.07
	spin = generator("num", -10, 10)
	lifespan = 1.8 SECONDS

/// Плоть: тяжёлые куски рывком разлетаются и падают.
/particles/heretic_ascension/flesh
	icon_state = list("flesh_bit_1" = 2, "flesh_bit_2" = 3)
	velocity = generator("circle", 4, 7)
	gravity = list(0, -0.4)
	friction = 0.12
	spin = generator("num", -15, 15)
	lifespan = 1.2 SECONDS
	fade = 0.4 SECONDS

/// Пустота: снег медленно расходится в тишине и почти не падает.
/particles/heretic_ascension/void
	icon_state = list("void_flake" = 2, "void_mote" = 3)
	velocity = generator("circle", 1.5, 3.5)
	gravity = list(0, -0.05)
	friction = 0.04
	drift = generator("box", list(-0.15, -0.1, 0), list(0.15, 0.05, 0))
	spin = generator("num", -3, 3)
	lifespan = 2.4 SECONDS
	fade = 1.2 SECONDS
	fadein = 0.2 SECONDS

/// Клинок: блики и осколки стали режут воздух и резко встают.
/particles/heretic_ascension/blade
	icon_state = list("steel_glint" = 2, "steel_shard" = 3)
	velocity = generator("circle", 6, 9)
	friction = 0.2
	spin = generator("num", -20, 20)
	lifespan = 0.9 SECONDS
	fade = 0.4 SECONDS

/// Луна: серпы и искры отражений плывут и мерцают.
/particles/heretic_ascension/moon
	icon_state = list("moon_crescent" = 2, "moon_mote" = 3)
	velocity = generator("circle", 1, 2.5)
	friction = 0.03
	spin = generator("num", -4, 4)
	lifespan = 2.2 SECONDS
	fade = 1 SECONDS
	fadein = 0.3 SECONDS

/// Космос: звёзды расходятся по орбитам и мерцают.
/particles/heretic_ascension/cosmic
	icon_state = list("star_small" = 3, "star_big" = 1)
	velocity = generator("circle", 1.5, 3)
	friction = 0.05
	drift = generator("circle", 0, 0.15)
	lifespan = 2 SECONDS
	fade = 0.8 SECONDS
	fadein = 0.3 SECONDS

/// Замок: ключи проворачиваются, золотые искры щёлкают.
/particles/heretic_ascension/lock
	icon_state = list("lock_key" = 1, "gold_spark" = 3)
	velocity = generator("circle", 2.5, 4.5)
	gravity = list(0, -0.12)
	friction = 0.1
	spin = generator("num", -12, 12)
	lifespan = 1.4 SECONDS
	fade = 0.5 SECONDS

/// Пучина: брызги и пена взлетают и опадают.
/particles/heretic_ascension/tide
	icon_state = list("water_drop" = 3, "foam_bubble" = 2)
	velocity = generator("box", list(-3, 2, 0), list(3, 5, 0))
	gravity = list(0, -0.35)
	friction = 0.04
	lifespan = 1.4 SECONDS
	fade = 0.5 SECONDS

/// Стекло: осколки вращаются и ловят свет гранями.
/particles/heretic_ascension/glass
	icon_state = list("glass_shard_1" = 2, "glass_shard_2" = 3)
	velocity = generator("circle", 4, 6)
	gravity = list(0, -0.15)
	friction = 0.1
	spin = generator("num", -18, 18)
	lifespan = 1.3 SECONDS
	fade = 0.5 SECONDS

/// Кровь: капли брызгают и падают.
/particles/heretic_ascension/blood
	icon_state = list("blood_drop_1" = 3, "blood_drop_2" = 2)
	velocity = generator("circle", 3, 5)
	gravity = list(0, -0.3)
	friction = 0.06
	lifespan = 1.4 SECONDS
	fade = 0.5 SECONDS

/// Эхо: латунные кольца расходятся и растут, как звук.
/particles/heretic_ascension/echo
	icon_state = list("echo_ring" = 2, "echo_mote" = 3)
	velocity = generator("circle", 1, 2.5)
	friction = 0.05
	grow = 0.05
	lifespan = 1.4 SECONDS
	fade = 0.8 SECONDS

/// Песок: песчинки быстро теряют скорость и осыпаются.
/particles/heretic_ascension/sand
	icon_state = list("sand_grain_1" = 3, "sand_grain_2" = 3, "sand_grain_3" = 2)
	velocity = generator("circle", 2, 4)
	gravity = list(0, -0.12)
	friction = 0.15
	lifespan = 2.2 SECONDS
	fade = 1 SECONDS

/// Воск: капли стекают, холодные огоньки падают вместе с ними.
/particles/heretic_ascension/wax
	icon_state = list("wax_drop" = 3, "wax_flame" = 2)
	velocity = generator("box", list(-2.5, 1, 0), list(2.5, 4, 0))
	gravity = list(0, -0.2)
	friction = 0.05
	lifespan = 1.8 SECONDS

/// Дух: души поднимаются полупрозрачными шлейфами и покачиваются.
/particles/heretic_ascension/spirit
	icon_state = list("wisp_1" = 2, "wisp_2" = 3)
	velocity = generator("circle", 1, 2.5)
	gravity = list(0, 0.12)
	friction = 0.04
	drift = generator("box", list(-0.2, 0, 0), list(0.2, 0, 0))
	lifespan = 2.4 SECONDS
	fade = 1 SECONDS
	fadein = 0.3 SECONDS

/// Нарастание обряда вознесения: руна пульсирует всё ярче и чаще, частицы пути стягиваются к центру, свет и искажение растут.
/obj/effect/heretic_ritual_crescendo
	icon = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	appearance_flags = PIXEL_SCALE
	var/ink
	var/ritual_duration
	var/stage = 0
	var/dissipating = FALSE
	var/datum/weakref/performer_ref
	var/list/stage_timers = list()
	var/list/emitters = list()
	var/obj/effect/abstract/heretic_rune_pulse/pulse
	var/obj/effect/abstract/heretic_vfx_glow/glow
	var/obj/effect/abstract/heretic_crescendo_warp/warp
	/// Такты от начала обряда: 0, 10, 20 и 27 секунд из 30.
	var/static/list/stage_at = list(0, 1 / 3, 2 / 3, 0.9)
	var/static/list/stage_spawning = list(0.1, 0.25, 0.45, 0.8)
	var/static/list/stage_pulse_alpha = list(90, 140, 190, 245)
	var/static/list/stage_period = list(2 SECONDS, 1.4 SECONDS, 0.9 SECONDS, 0.5 SECONDS)
	var/static/list/stage_light_range = list(2, 3, 4, 5)
	var/static/list/stage_light_power = list(0.5, 0.9, 1.3, 1.8)
	var/static/list/stage_warp_scale = list(0.3, 0.45, 0.65, 0.85)
	var/static/list/stage_quake = list(0, 0, 0.06, 0.1)
	var/static/list/stage_sound = list(null, 'modular_bluemoon/sound/heretic/ritual_begin.ogg', 'sound/magic/curse.ogg', 'sound/magic/lightning_chargeup.ogg')
	var/static/list/stage_volume = list(0, 45, 55, 65)

/obj/effect/heretic_ritual_crescendo/Initialize(mapload, path_id, duration, atom/movable/rune, mob/living/performer)
	. = ..()
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	if(!path || !ispath(path.vfx_particles, /particles/heretic_ascension))
		return INITIALIZE_HINT_QDEL
	ink = path.book_ink
	ritual_duration = duration
	performer_ref = WEAKREF(performer)
	pulse = new(loc, ink, rune?.transform)
	for(var/index in 1 to HERETIC_CRESCENDO_EMITTERS)
		var/obj/effect/abstract/heretic_vfx_emitter/emitter = new(null, path.vfx_particles, index * 360 / HERETIC_CRESCENDO_EMITTERS)
		emitters += emitter
		vis_contents += emitter
	glow = heretic_vfx_attach_glow(src)
	warp = new(loc)
	set_stage(1)
	for(var/next_stage in 2 to length(stage_at))
		stage_timers += addtimer(CALLBACK(src, PROC_REF(set_stage), next_stage), ritual_duration * stage_at[next_stage], TIMER_STOPPABLE)
	stage_timers += addtimer(CALLBACK(src, PROC_REF(dissipate)), ritual_duration + HERETIC_CRESCENDO_OVERRUN, TIMER_STOPPABLE)

/obj/effect/heretic_ritual_crescendo/proc/set_stage(new_stage)
	if(dissipating || new_stage <= stage)
		return
	stage = new_stage
	for(var/obj/effect/abstract/heretic_vfx_emitter/emitter as anything in emitters)
		emitter.particles.spawning = stage_spawning[stage]
	var/period = stage_period[stage]
	animate(pulse, alpha = stage_pulse_alpha[stage], time = period / 2, easing = SINE_EASING, loop = -1)
	animate(alpha = HERETIC_CRESCENDO_PULSE_LOW, time = period / 2, easing = SINE_EASING)
	warp.beat(stage_warp_scale[stage], period)
	set_light(stage_light_range[stage], stage_light_power[stage], ink)
	var/mob/living/performer = performer_ref?.resolve()
	if(performer)
		heretic_vfx_pulse(performer, ink, stage, period)
	if(stage_quake[stage])
		heretic_vfx_quake(src, HERETIC_CRESCENDO_QUAKE_RADIUS, stage_quake[stage], HERETIC_CRESCENDO_QUAKE_TIME)
	if(stage_sound[stage])
		playsound(src, stage_sound[stage], stage_volume[stage], TRUE)

/// Обряд закончился или сорван: поток частиц встаёт, долетевшие гаснут, свет и пульс затухают ступенями, затем всё удаляется.
/obj/effect/heretic_ritual_crescendo/proc/dissipate()
	if(dissipating || QDELETED(src))
		return
	dissipating = TRUE
	for(var/timer in stage_timers)
		deltimer(timer)
	stage_timers.Cut()
	for(var/obj/effect/abstract/heretic_vfx_emitter/emitter as anything in emitters)
		emitter.particles.spawning = 0
	animate(pulse, alpha = 0, time = HERETIC_CRESCENDO_FADE, easing = SINE_EASING | EASE_IN)
	animate(warp, alpha = 0, time = HERETIC_CRESCENDO_FADE / 2)
	var/start_power = light_power
	for(var/step in 1 to HERETIC_CRESCENDO_LIGHT_STEPS)
		var/share = step / (HERETIC_CRESCENDO_LIGHT_STEPS + 1)
		addtimer(CALLBACK(src, PROC_REF(dim_light), start_power * (1 - share)), HERETIC_CRESCENDO_FADE * share)
	QDEL_IN(src, HERETIC_CRESCENDO_FADE)

/obj/effect/heretic_ritual_crescendo/proc/dim_light(power)
	set_light(l_power = power)

/obj/effect/heretic_ritual_crescendo/Destroy()
	for(var/timer in stage_timers)
		deltimer(timer)
	stage_timers.Cut()
	vis_contents.Cut()
	QDEL_LIST(emitters)
	QDEL_NULL(pulse)
	QDEL_NULL(glow)
	QDEL_NULL(warp)
	performer_ref = null
	return ..()

/// Пульс руны светится своей маской на слое печатей: тела на руне закрывают свечение, а не подсвечиваются им.
/obj/effect/abstract/heretic_rune_pulse
	icon = 'modular_bluemoon/icons/obj/heretic_rune_visuals.dmi'
	icon_state = HERETIC_RUNE_VISUAL_RITUAL
	layer = HIGH_SIGIL_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE
	pixel_x = -32
	pixel_y = -32
	alpha = 0

/obj/effect/abstract/heretic_rune_pulse/Initialize(mapload, ink, matrix/rune_transform)
	. = ..()
	color = ink
	if(rune_transform)
		transform = rune_transform
	add_overlay(emissive_appearance(icon, icon_state, layer = HIGH_SIGIL_LAYER))

/// Частицы пути появляются на краю круга и с разгоном втягиваются в центр руны, уменьшаясь.
/obj/effect/abstract/heretic_vfx_emitter
	icon = null
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_ALPHA | RESET_COLOR | PIXEL_SCALE

/obj/effect/abstract/heretic_vfx_emitter/Initialize(mapload, particles_type, angle)
	. = ..()
	if(!ispath(particles_type, /particles/heretic_ascension))
		return INITIALIZE_HINT_QDEL
	var/particles/gather = new particles_type
	gather.width = HERETIC_CRESCENDO_CANVAS
	gather.height = HERETIC_CRESCENDO_CANVAS
	var/start_x = HERETIC_CRESCENDO_RADIUS * sin(angle)
	var/start_y = HERETIC_CRESCENDO_RADIUS * cos(angle)
	var/pull = 2 / (HERETIC_CRESCENDO_TRAVEL * HERETIC_CRESCENDO_TRAVEL)
	gather.position = generator("box", list(start_x - HERETIC_CRESCENDO_SPREAD, start_y - HERETIC_CRESCENDO_SPREAD, 0), list(start_x + HERETIC_CRESCENDO_SPREAD, start_y + HERETIC_CRESCENDO_SPREAD, 0))
	gather.velocity = generator("circle", 0, HERETIC_CRESCENDO_JITTER)
	gather.gravity = list(-start_x * pull, -start_y * pull, 0)
	gather.drift = list(0, 0, 0)
	gather.friction = 0
	gather.grow = HERETIC_CRESCENDO_SHRINK
	gather.lifespan = HERETIC_CRESCENDO_TRAVEL
	gather.fadein = HERETIC_CRESCENDO_EDGE_FADE
	gather.fade = HERETIC_CRESCENDO_EDGE_FADE
	gather.count = HERETIC_CRESCENDO_COUNT
	gather.spawning = 0
	particles = gather

/obj/effect/abstract/heretic_vfx_emitter/Destroy()
	particles = null
	return ..()

/// Искажение пространства над руной бьётся в такт пульсу, чаще и шире к концу обряда.
/obj/effect/abstract/heretic_crescendo_warp
	icon = 'modular_bluemoon/icons/effects/heretic_shockwave.dmi'
	icon_state = "warp"
	plane = GRAVITY_PULSE_PLANE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0

/obj/effect/abstract/heretic_crescendo_warp/Initialize(mapload)
	. = ..()
	pixel_x = (world.icon_size - HERETIC_VFX_RING_ICON_SIZE) / 2
	pixel_y = pixel_x

/obj/effect/abstract/heretic_crescendo_warp/proc/beat(scale, period)
	animate(src, transform = matrix(HERETIC_VFX_WAVE_START_SCALE, 0, 0, 0, HERETIC_VFX_WAVE_START_SCALE, 0), alpha = 255, time = 0, loop = -1)
	animate(transform = matrix(scale, 0, 0, 0, scale, 0), alpha = 0, time = period, easing = CUBIC_EASING | EASE_OUT)

#undef HERETIC_VFX_RING_ICON_SIZE
#undef HERETIC_VFX_RING_RADIUS
#undef HERETIC_VFX_RING_INNER
#undef HERETIC_VFX_RING_OUTER
#undef HERETIC_VFX_WAVE_START_SCALE
#undef HERETIC_VFX_WAVE_HOLD
#undef HERETIC_VFX_RIPPLE_FILTER
#undef HERETIC_VFX_RIPPLE_SIZE
#undef HERETIC_VFX_RIPPLE_REPEAT
#undef HERETIC_VFX_FLASH_TAIL_POWER
#undef HERETIC_VFX_FLASH_TAIL_STRETCH
#undef HERETIC_VFX_RISE_SHARE
#undef HERETIC_VFX_PULSE_PRIORITY
#undef HERETIC_VFX_RAYS_PRIORITY
#undef HERETIC_VFX_RAYS_SIZE
#undef HERETIC_VFX_RAYS_DENSITY
#undef HERETIC_VFX_RAYS_THRESHOLD
#undef HERETIC_VFX_RAYS_FACTOR
#undef HERETIC_VFX_RAYS_TURN
#undef HERETIC_CRESCENDO_EMITTERS
#undef HERETIC_CRESCENDO_RADIUS
#undef HERETIC_CRESCENDO_SPREAD
#undef HERETIC_CRESCENDO_JITTER
#undef HERETIC_CRESCENDO_TRAVEL
#undef HERETIC_CRESCENDO_EDGE_FADE
#undef HERETIC_CRESCENDO_COUNT
#undef HERETIC_CRESCENDO_SHRINK
#undef HERETIC_CRESCENDO_PULSE_LOW
#undef HERETIC_CRESCENDO_QUAKE_RADIUS
#undef HERETIC_CRESCENDO_QUAKE_TIME
#undef HERETIC_CRESCENDO_FADE
#undef HERETIC_CRESCENDO_OVERRUN
#undef HERETIC_CRESCENDO_LIGHT_STEPS
#undef HERETIC_CRESCENDO_CANVAS
#undef HERETIC_VFX_SPRAY_SPEED
#undef HERETIC_VFX_SPRAY_SPREAD
#undef HERETIC_VFX_GATHER_RISE
#undef HERETIC_VFX_WATCH_RANGE
#undef HERETIC_VFX_TINT_LIFT
#undef HERETIC_VFX_TINT_GAIN
#undef HERETIC_VFX_THREAD_MIN_SHARE
#undef HERETIC_VFX_THREAD_SNAP_WIDTH
#undef HERETIC_VFX_THREAD_SNAP_RISE
#undef HERETIC_VFX_CONVERGE_MARGIN
#undef HERETIC_VFX_CONVERGE_SPREAD
#undef HERETIC_VFX_STREAM_MARGIN
