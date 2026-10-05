#define HERETIC_SKY_BREATH_TINT (9 SECONDS)
#define HERETIC_SKY_BREATH_GLOW (7 SECONDS)
#define HERETIC_SKY_GLOW_BREATH_SCALE 1.08
#define HERETIC_SKY_TINT_BREATH_LOW 0.3
#define HERETIC_SKY_FLASH_RISE 2
#define HERETIC_SKY_FLASH_FALL 14
#define HERETIC_SKY_FLASH_BRIGHTNESS 1.6
#define HERETIC_SKY_CROWD_SCALE 0.75
/// Знаки ближе планеты: их параллакс чуть быстрее, при ходьбе они плывут поверх диска.
#define HERETIC_SKY_FRONT_DEPTH 1.15
/// Корона первого Знака выходит за край диска на эту долю радиуса.
#define HERETIC_SKY_CORONA_REACH 1.6
#define HERETIC_SKY_CORONA_EDGE_SCALE 1.2
#define HERETIC_SKY_VEIL_TILE 672
#define HERETIC_SKY_FIELD_HALF_WIDTH 480
#define HERETIC_SKY_FIELD_HALF_HEIGHT 320
#define HERETIC_SKY_FIELD_COUNT 140
#define HERETIC_SKY_FIELD_SPAWNING 0.9
#define HERETIC_SKY_BURST_FACTOR 8
#define HERETIC_SKY_BURST_TIME (1.5 SECONDS)

/**
 * Слой неба вознесения. Какому голосу он служит, решает слот: координатор при каждой
 * сборке шаблона z красит и расставляет слои по голосам своей группы.
 */
/atom/movable/screen/parallax_layer/heretic_sky
	icon = null
	parallax_intensity = PARALLAX_LOW
	var/sky_role
	/// 0 - слой всей группы (затемнение, вспышка).
	var/sky_slot = 0
	/// Цвет покоя: к нему возвращаются дыхание и вспышка.
	var/base_color = COLOR_WHITE
	/// Петли уже заведены на этом экземпляре. Клоном не наследуется.
	var/breathing = FALSE

/atom/movable/screen/parallax_layer/heretic_sky/Clone()
	var/atom/movable/screen/parallax_layer/heretic_sky/layer = ..()
	layer.base_color = base_color
	layer.particles = particles
	return layer

/atom/movable/screen/parallax_layer/heretic_sky/OnApplied()
	if(breathing)
		return
	breathing = TRUE
	breathe()

/atom/movable/screen/parallax_layer/heretic_sky/proc/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	return

/// Слой всей группы: голоса у него нет, только сцена.
/atom/movable/screen/parallax_layer/heretic_sky/proc/apply_group(atom/movable/screen/parallax_layer/anchor)
	return

/atom/movable/screen/parallax_layer/heretic_sky/proc/target_alpha(datum/heretic_sky/sky, group)
	var/datum/heretic_sky_voice/voice = sky.slot_voice(group, sky_slot)
	return voice ? voice.role_alpha(sky_role) : 0

/atom/movable/screen/parallax_layer/heretic_sky/proc/sync_alpha(datum/heretic_sky/sky, group, time)
	var/target = target_alpha(sky, group)
	if(time > 0)
		animate(src, alpha = target, time = time, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	else
		alpha = target

/atom/movable/screen/parallax_layer/heretic_sky/proc/flash(flash_color, peak)
	return

/atom/movable/screen/parallax_layer/heretic_sky/proc/breathe()
	return

/// Несколько Знаков в небе: затмевающий остаётся крупным, остальные мельче, чтобы не наезжать на него.
/atom/movable/screen/parallax_layer/heretic_sky/proc/fit_crowd(datum/heretic_sky_voice/voice)
	var/shrink = sky_slot > 1 && GLOB.heretic_sky.crowded(voice.group)
	base_scale = initial(base_scale) * (shrink ? HERETIC_SKY_CROWD_SCALE : 1)

/// Ставит слой к своему Знаку: на диск планеты, если она есть в сцене, иначе в угол экрана.
/atom/movable/screen/parallax_layer/heretic_sky/proc/place(atom/movable/screen/parallax_layer/anchor, depth = HERETIC_SKY_FRONT_DEPTH)
	if(anchor)
		place_on_anchor(anchor, depth)
	else
		place_at_slot()

/// Центр слоя в точке слота при игроке в середине карты; шаг игрока сдвигает его на speed пикселей.
/atom/movable/screen/parallax_layer/heretic_sky/proc/place_at_slot()
	var/list/offset = GLOB.heretic_sky_slot_offsets[clamp(sky_slot, 1, HERETIC_SKY_MAX_SLOTS)]
	center_x = -offset[1] - speed * world.maxx / 2
	center_y = -offset[2] - speed * world.maxy / 2

/// Центр слоя в месте слота на диске планеты при игроке в середине карты; разброс планеты повторяется через pixel_x/y.
/atom/movable/screen/parallax_layer/heretic_sky/proc/place_on_anchor(atom/movable/screen/parallax_layer/anchor, depth)
	var/list/disc = GLOB.heretic_sky_anchors[anchor.type]
	var/list/spot = GLOB.heretic_sky_sign_spots[clamp(sky_slot, 1, HERETIC_SKY_MAX_SLOTS)]
	var/distance = disc[1] * anchor.base_scale * spot[2]
	var/offset_x = (disc[2] - anchor.tile_size / 2) * anchor.base_scale + cos(spot[1]) * distance
	var/offset_y = (disc[3] - anchor.tile_size / 2) * anchor.base_scale + sin(spot[1]) * distance
	speed = anchor.speed * depth
	pixel_x = anchor.pixel_x
	pixel_y = anchor.pixel_y
	center_x = anchor.center_x + (anchor.speed - speed) * world.maxx / 2 - offset_x
	center_y = anchor.center_y + (anchor.speed - speed) * world.maxy / 2 - offset_y

/// Затемнение звёзд под Знаками: одно на группу, сила по самому тёмному пути.
/atom/movable/screen/parallax_layer/heretic_sky/dim
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	color = COLOR_BLACK
	blend_mode = BLEND_MULTIPLY
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	layer_mode = PARALLAX_MODE_OVERLAY
	layer = 3.4
	sky_role = HERETIC_SKY_ROLE_DIM

/atom/movable/screen/parallax_layer/heretic_sky/dim/target_alpha(datum/heretic_sky/sky, group)
	return sky.group_role_alpha(group, sky_role)

/// Тень затмения: чёрный силуэт планеты поверх неё самой, пока Знак закрывает её свет. Одна на группу.
/atom/movable/screen/parallax_layer/heretic_sky/eclipse
	blend_mode = BLEND_OVERLAY
	layer_mode = PARALLAX_MODE_STATIC
	layer = 30.1
	sky_role = HERETIC_SKY_ROLE_ECLIPSE
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS
	/// Без планеты затмевать нечего.
	var/lit = FALSE

/atom/movable/screen/parallax_layer/heretic_sky/eclipse/Clone()
	var/atom/movable/screen/parallax_layer/heretic_sky/eclipse/layer = ..()
	layer.lit = lit
	return layer

/atom/movable/screen/parallax_layer/heretic_sky/eclipse/apply_group(atom/movable/screen/parallax_layer/anchor)
	lit = !!anchor
	if(!anchor)
		return
	icon = anchor.icon
	icon_state = anchor.icon_state
	tile_size = anchor.tile_size
	base_scale = anchor.base_scale
	speed = anchor.speed
	center_x = anchor.center_x
	center_y = anchor.center_y
	pixel_x = anchor.pixel_x
	pixel_y = anchor.pixel_y
	ApplyLayerMode()
	color = list(0, 0, 0, 0, 0, 0, 0, 0, 0)

/atom/movable/screen/parallax_layer/heretic_sky/eclipse/target_alpha(datum/heretic_sky/sky, group)
	return lit ? sky.group_role_alpha(group, sky_role) : 0

/// Вспышка всего неба: кульминация и главные события путей.
/atom/movable/screen/parallax_layer/heretic_sky/flash
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	blend_mode = BLEND_ADD
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	layer_mode = PARALLAX_MODE_OVERLAY
	layer = 36
	alpha = 0
	sky_role = HERETIC_SKY_ROLE_FLASH

/atom/movable/screen/parallax_layer/heretic_sky/flash/sync_alpha(datum/heretic_sky/sky, group, time)
	if(time <= 0)
		alpha = 0

/atom/movable/screen/parallax_layer/heretic_sky/flash/flash(flash_color, peak)
	color = flash_color
	animate(src, alpha = peak, time = HERETIC_SKY_FLASH_RISE, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	animate(alpha = 0, time = HERETIC_SKY_FLASH_FALL, easing = SINE_EASING)

/atom/movable/screen/parallax_layer/heretic_sky/tint
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	blend_mode = BLEND_ADD
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	layer_mode = PARALLAX_MODE_OVERLAY
	layer = 4.4
	sky_role = HERETIC_SKY_ROLE_TINT

/atom/movable/screen/parallax_layer/heretic_sky/tint/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	base_color = voice.path().sky_tint
	color = base_color

/atom/movable/screen/parallax_layer/heretic_sky/tint/breathe()
	var/low = BlendRGB(base_color, COLOR_BLACK, HERETIC_SKY_TINT_BREATH_LOW)
	animate(src, color = low, time = HERETIC_SKY_BREATH_TINT, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(color = base_color, time = HERETIC_SKY_BREATH_TINT, easing = SINE_EASING)

/// Туманность пути среди звёздных ярусов, за планетой. Свои фактуры есть только у Пляски, остальным небо заполняют
/// облака изнанки из погоды параллакса: дальний ярус в цвете пути, ближний в цвете зарева.
/atom/movable/screen/parallax_layer/heretic_sky/texture
	blend_mode = BLEND_ADD
	layer_mode = PARALLAX_MODE_TILED
	tile_size = HERETIC_SKY_VEIL_TILE
	layer = 3.5
	sky_role = HERETIC_SKY_ROLE_TEXTURE
	var/texture_index = 1

/atom/movable/screen/parallax_layer/heretic_sky/texture/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	var/datum/heretic_path/path = voice.path()
	var/list/params = path.sky_texture_params(texture_index)
	speed = params[1]
	drift_time = params[2]
	drift_angle = params[3]
	if(length(path.sky_texture_states))
		icon = path.sky_icon
		tile_size = path.sky_icon_size
		icon_state = path.sky_texture_states[texture_index]
		ApplyLayerMode()
		return
	var/list/veil = GLOB.heretic_sky_veils[texture_index]
	icon = veil[1]
	icon_state = veil[2]
	tile_size = HERETIC_SKY_VEIL_TILE
	ApplyLayerMode()
	color = heretic_sky_veil_matrix(texture_index == 1 ? path.sky_tint : voice.glow_color(), veil[3])

/// Цвет пути вместо цвета шума, прозрачность из яркости шума: тёмные провалы облаков пропускают звёзды.
/proc/heretic_sky_veil_matrix(veil_color, strength)
	var/list/channels = rgb2num(veil_color)
	return list(0, 0, 0, strength, 0, 0, 0, strength, 0, 0, 0, strength, 0, 0, 0, 1, channels[1] / 255, channels[2] / 255, channels[3] / 255, -1)

/atom/movable/screen/parallax_layer/heretic_sky/texture/near
	layer = 3.6
	sky_role = HERETIC_SKY_ROLE_TEXTURE_NEAR
	texture_index = 2

/// Ореол Знака в цвете пути: поверх планеты, но под самим Знаком.
/atom/movable/screen/parallax_layer/heretic_sky/glow
	icon = 'icons/effects/light_overlays/light_256.dmi'
	icon_state = "light"
	blend_mode = BLEND_ADD
	layer_mode = PARALLAX_MODE_STATIC
	tile_size = 256
	base_scale = 1.6
	speed = 0.25
	layer = 30.5
	sky_role = HERETIC_SKY_ROLE_GLOW
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS

/atom/movable/screen/parallax_layer/heretic_sky/glow/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	base_color = voice.glow_color()
	color = base_color
	fit_crowd(voice)
	place(anchor)
	ApplyLayerMode()

/// Корона затмения за диском планеты: у первого Знака горит по всему краю, у остальных - на краю под Знаком.
/atom/movable/screen/parallax_layer/heretic_sky/glow/corona
	base_scale = HERETIC_SKY_CORONA_EDGE_SCALE
	layer = 29.5
	sky_role = HERETIC_SKY_ROLE_CORONA
	/// Без планеты короне не из-за чего выходить.
	var/lit = FALSE

/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/Clone()
	var/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/layer = ..()
	layer.lit = lit
	return layer

/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	base_color = voice.glow_color()
	color = base_color
	lit = !!anchor
	if(anchor)
		var/list/spot = GLOB.heretic_sky_sign_spots[clamp(sky_slot, 1, HERETIC_SKY_MAX_SLOTS)]
		var/list/disc = GLOB.heretic_sky_anchors[anchor.type]
		base_scale = spot[2] ? HERETIC_SKY_CORONA_EDGE_SCALE : disc[1] * anchor.base_scale * HERETIC_SKY_CORONA_REACH / (tile_size / 2)
	place(anchor, 1)
	ApplyLayerMode()

/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/target_alpha(datum/heretic_sky/sky, group)
	return lit ? ..() : 0

/atom/movable/screen/parallax_layer/heretic_sky/glow/breathe()
	var/matrix/wide = BaseTransform()
	wide.Scale(HERETIC_SKY_GLOW_BREATH_SCALE, HERETIC_SKY_GLOW_BREATH_SCALE)
	animate(src, transform = wide, time = HERETIC_SKY_BREATH_GLOW, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(transform = BaseTransform(), time = HERETIC_SKY_BREATH_GLOW, easing = SINE_EASING)

/atom/movable/screen/parallax_layer/heretic_sky/glow/flash(flash_color, peak)
	animate(src, color = COLOR_WHITE, time = HERETIC_SKY_FLASH_RISE, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	animate(color = base_color, time = HERETIC_SKY_FLASH_FALL, easing = SINE_EASING)

/// Знак пути - небесное тело перед планетой (её слой 30). Живописный лист показывается 1:1, всё движение нарисовано
/// в кадрах: поворот и масштаб кодом на произвольный угол дают рябь.
/atom/movable/screen/parallax_layer/heretic_sky/presence
	blend_mode = BLEND_OVERLAY
	appearance_flags = KEEP_TOGETHER | TILE_BOUND
	layer_mode = PARALLAX_MODE_STATIC
	tile_size = 240
	speed = 0.25
	layer = 30.6
	sky_role = HERETIC_SKY_ROLE_PRESENCE
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS

/atom/movable/screen/parallax_layer/heretic_sky/presence/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	var/datum/heretic_path/path = voice.path()
	icon = path.sky_icon
	icon_state = "presence"
	tile_size = path.sky_icon_size
	fit_crowd(voice)
	place(anchor)
	ApplyLayerMode()

/atom/movable/screen/parallax_layer/heretic_sky/presence/flash(flash_color, peak)
	var/static/list/bright = list(HERETIC_SKY_FLASH_BRIGHTNESS, 0, 0, 0, HERETIC_SKY_FLASH_BRIGHTNESS, 0, 0, 0, HERETIC_SKY_FLASH_BRIGHTNESS)
	var/static/list/rest = list(1, 0, 0, 0, 1, 0, 0, 0, 1)
	animate(src, color = bright, time = HERETIC_SKY_FLASH_RISE, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	animate(color = rest, time = HERETIC_SKY_FLASH_FALL, easing = SINE_EASING)

/// Материал пути срывается с Знака плавными клиентскими частицами; на событиях пути - выброс.
/atom/movable/screen/parallax_layer/heretic_sky/particles
	layer_mode = PARALLAX_MODE_STATIC
	tile_size = 32
	speed = 0.5
	layer = 31
	sky_role = HERETIC_SKY_ROLE_PARTICLES
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS
	var/base_spawning = 0

/atom/movable/screen/parallax_layer/heretic_sky/particles/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	var/particle_type = voice.path().sky_particles
	particles = particle_type ? new particle_type : null
	base_spawning = particles?.spawning
	place(anchor)
	ApplyLayerMode()

/// Частицы у всех клонов общие с шаблоном, поэтому выброс правится один раз на шаблоне z.
/atom/movable/screen/parallax_layer/heretic_sky/particles/proc/burst()
	if(!particles)
		return
	particles.spawning = base_spawning * HERETIC_SKY_BURST_FACTOR
	addtimer(CALLBACK(src, PROC_REF(end_burst)), HERETIC_SKY_BURST_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)

/atom/movable/screen/parallax_layer/heretic_sky/particles/proc/end_burst()
	if(particles)
		particles.spawning = base_spawning

/// Материал пути по всему небу за планетой: тот же, что срывается со Знака, но редкий и во весь экран.
/atom/movable/screen/parallax_layer/heretic_sky/field
	layer_mode = PARALLAX_MODE_STATIC
	tile_size = 32
	speed = 0.4
	layer = 4.6
	sky_role = HERETIC_SKY_ROLE_FIELD
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS

/atom/movable/screen/parallax_layer/heretic_sky/field/apply_voice(datum/heretic_sky_voice/voice, atom/movable/screen/parallax_layer/anchor)
	var/particle_type = voice.path().sky_particles
	particles = particle_type ? new particle_type : null
	if(particles)
		particles.position = generator("box", list(-HERETIC_SKY_FIELD_HALF_WIDTH, -HERETIC_SKY_FIELD_HALF_HEIGHT, 0), list(HERETIC_SKY_FIELD_HALF_WIDTH, HERETIC_SKY_FIELD_HALF_HEIGHT, 0))
		particles.width = HERETIC_SKY_FIELD_HALF_WIDTH * 2 + world.icon_size * 2
		particles.height = HERETIC_SKY_FIELD_HALF_HEIGHT * 2 + world.icon_size * 2
		particles.count = HERETIC_SKY_FIELD_COUNT
		particles.spawning = HERETIC_SKY_FIELD_SPAWNING
	center_x = -speed * world.maxx / 2
	center_y = -speed * world.maxy / 2
	ApplyLayerMode()

/atom/movable/screen/parallax_layer/heretic_sky/tint/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/tint/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/tint/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/tint/slot4
	sky_slot = 4

/atom/movable/screen/parallax_layer/heretic_sky/texture/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/texture/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/texture/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/texture/slot4
	sky_slot = 4

/atom/movable/screen/parallax_layer/heretic_sky/texture/near/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/texture/near/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/texture/near/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/texture/near/slot4
	sky_slot = 4

/atom/movable/screen/parallax_layer/heretic_sky/glow/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/glow/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/glow/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/glow/slot4
	sky_slot = 4

/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/glow/corona/slot4
	sky_slot = 4

/atom/movable/screen/parallax_layer/heretic_sky/presence/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/presence/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/presence/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/presence/slot4
	sky_slot = 4

/atom/movable/screen/parallax_layer/heretic_sky/particles/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/particles/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/particles/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/particles/slot4
	sky_slot = 4

/atom/movable/screen/parallax_layer/heretic_sky/field/slot1
	sky_slot = 1
/atom/movable/screen/parallax_layer/heretic_sky/field/slot2
	sky_slot = 2
/atom/movable/screen/parallax_layer/heretic_sky/field/slot3
	sky_slot = 3
/atom/movable/screen/parallax_layer/heretic_sky/field/slot4
	sky_slot = 4

/// Материал Знака: срывается с края фигуры и плавно уходит в небо; моты те же, что у вспышек вознесения.
/particles/heretic_sky
	icon = 'modular_bluemoon/icons/effects/heretic_particles.dmi'
	width = 640
	height = 640
	count = 60
	spawning = 0.5
	lifespan = 6 SECONDS
	fade = 2 SECONDS
	fadein = 0.5 SECONDS
	position = generator("circle", 60, 100)
	velocity = generator("circle", 0.15, 0.4)
	friction = 0.01

/particles/heretic_sky/ash
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("ash_1" = 3, "ash_2" = 2, "ash_3" = 1)
	velocity = generator("circle", 0.2, 0.5)
	gravity = list(0, 0.01)
	drift = generator("box", list(-0.02, 0, 0), list(0.02, 0.01, 0))

/particles/heretic_sky/rust
	icon_state = list("rust_flake_1" = 2, "rust_flake_2" = 2, "rust_flake_3" = 3)
	gravity = list(0, -0.012)
	spin = generator("num", -3, 3)

/particles/heretic_sky/flesh
	icon_state = list("flesh_bit_1" = 2, "flesh_bit_2" = 3)
	velocity = generator("circle", 0.1, 0.3)
	gravity = list(0, -0.02)
	spin = generator("num", -4, 4)

/particles/heretic_sky/void
	icon_state = list("void_flake" = 2, "void_mote" = 3)
	velocity = generator("circle", 0.05, 0.2)
	spin = generator("num", -1, 1)
	lifespan = 9 SECONDS
	fade = 3 SECONDS

/particles/heretic_sky/blade
	icon_state = list("steel_glint" = 2, "steel_shard" = 3)
	velocity = generator("circle", 0.3, 0.7)
	friction = 0.03
	spin = generator("num", -6, 6)

/particles/heretic_sky/moon
	icon_state = list("moon_crescent" = 2, "moon_mote" = 3)
	velocity = generator("circle", 0.05, 0.2)
	spin = generator("num", -1, 1)
	lifespan = 8 SECONDS

/particles/heretic_sky/cosmic
	icon_state = list("star_small" = 3, "star_big" = 1)
	velocity = generator("circle", 0.1, 0.3)
	lifespan = 8 SECONDS
	fade = 3 SECONDS

/particles/heretic_sky/lock
	icon_state = list("lock_key" = 1, "gold_spark" = 4)
	gravity = list(0, -0.01)
	spin = generator("num", -3, 3)

/particles/heretic_sky/tide
	icon_state = list("water_drop" = 2, "foam_bubble" = 3)
	velocity = generator("circle", 0.1, 0.3)
	gravity = list(0, 0.012)
	drift = generator("box", list(-0.02, 0, 0), list(0.02, 0, 0))

/particles/heretic_sky/glass
	icon_state = list("glass_shard_1" = 2, "glass_shard_2" = 2, "mirror_shard_1" = 1)
	gravity = list(0, -0.01)
	spin = generator("num", -4, 4)

/particles/heretic_sky/blood
	icon_state = list("blood_drop_1" = 3, "blood_drop_2" = 2, "blood_wisp_1" = 1)
	velocity = generator("circle", 0.05, 0.15)
	gravity = list(0, -0.025)

/particles/heretic_sky/echo
	icon_state = list("echo_ring" = 2, "echo_mote" = 3)
	velocity = generator("circle", 0.2, 0.4)
	grow = 0.004

/particles/heretic_sky/sand
	icon_state = list("sand_grain_1" = 3, "sand_grain_2" = 3, "sand_grain_3" = 2)
	velocity = generator("box", list(0.3, -0.2, 0), list(0.6, 0, 0))
	gravity = list(0, -0.008)

/particles/heretic_sky/wax
	icon_state = list("wax_drop" = 3, "wax_flame" = 2)
	velocity = generator("circle", 0.05, 0.2)
	gravity = list(0, -0.018)

/particles/heretic_sky/spirit
	icon_state = list("wisp_1" = 2, "wisp_2" = 3)
	velocity = generator("circle", 0.05, 0.2)
	gravity = list(0, 0.012)
	drift = generator("box", list(-0.02, 0, 0), list(0.02, 0, 0))

/particles/heretic_sky/dance
	icon_state = list("dance_confetti_1" = 3, "dance_confetti_2" = 3, "dance_confetti_3" = 2)
	gravity = list(0, -0.01)
	spin = generator("num", -5, 5)

#undef HERETIC_SKY_BREATH_TINT
#undef HERETIC_SKY_BREATH_GLOW
#undef HERETIC_SKY_GLOW_BREATH_SCALE
#undef HERETIC_SKY_TINT_BREATH_LOW
#undef HERETIC_SKY_FLASH_RISE
#undef HERETIC_SKY_FLASH_FALL
#undef HERETIC_SKY_FLASH_BRIGHTNESS
#undef HERETIC_SKY_CROWD_SCALE
#undef HERETIC_SKY_FRONT_DEPTH
#undef HERETIC_SKY_CORONA_REACH
#undef HERETIC_SKY_CORONA_EDGE_SCALE
#undef HERETIC_SKY_VEIL_TILE
#undef HERETIC_SKY_FIELD_HALF_WIDTH
#undef HERETIC_SKY_FIELD_HALF_HEIGHT
#undef HERETIC_SKY_FIELD_COUNT
#undef HERETIC_SKY_FIELD_SPAWNING
#undef HERETIC_SKY_BURST_FACTOR
#undef HERETIC_SKY_BURST_TIME
