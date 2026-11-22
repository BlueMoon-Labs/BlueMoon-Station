// Bullet-impact sparks on metal walls, ported from MyHornyHell's
// bounce_sparks.dm but reimplemented as a native /particles burst —
// zero atoms per spark, so automatic fire stays cheap. The sparks no
// longer bounce off geometry; the burst sprays out from the wall edge
// and fades, while the projectile ricochet itself is unchanged.

#define BOUNCE_SPARK_CENTER_OFFSET 16
#define BOUNCE_SPARK_TILE_X 32
#define BOUNCE_SPARK_TILE_Y 32

/particles/bullet_sparks
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = "dot"
	count = 12
	spawning = 12
	lifespan = 0.45 SECONDS
	fade = 0.2 SECONDS
	fadein = 0.02 SECONDS
	scale = generator("num", 0.15, 0.3)
	position = generator("box", list(-4, -4, 0), list(4, 4, 0))
	drift = generator("box", list(-0.3, -0.3, 0), list(0.3, 0.3, 0))
	gravity = list(0, 0.1, 0)
	color = "#FFCF7A"

/// Open enough to spawn into — ignore dense contents (chairs, people). Closed turfs blocked.
/proc/bounce_spark_turf_open(turf/check_turf)
	return check_turf && !check_turf.density && !isclosedturf(check_turf)

/// Resolve where the burst should actually appear. Closed turfs (walls) shift onto a free neighbor.
/// Returns list(spawn_turf, into_dir_or_0, start_px, start_py)
/proc/resolve_bounce_spark_spawn(atom/source, impact_angle = 0, impact_px = 0, impact_py = 0)
	var/turf/base = get_turf(source)
	if(!base)
		return null

	if(bounce_spark_turf_open(base))
		return list(base, 0, 16 + rand(-8, 8), 16 + rand(-8, 8))

	var/list/exit = pick_bounce_spark_wall_exit(base, impact_angle, impact_px, impact_py)
	if(exit)
		var/list/edge = bounce_spark_wall_edge_pixels(exit[2], impact_px, impact_py)
		return list(exit[1], exit[2], edge[1], edge[2])

	// Last resort: still show something on the closed turf.
	return list(base, 0, clamp(impact_px + BOUNCE_SPARK_CENTER_OFFSET, 4, BOUNCE_SPARK_TILE_X - 4), clamp(impact_py + BOUNCE_SPARK_CENTER_OFFSET, 4, BOUNCE_SPARK_TILE_Y - 4))

/// Pick an open turf next to a wall for the spark spray.
/proc/pick_bounce_spark_wall_exit(turf/wall, impact_angle, impact_px, impact_py)
	if(!wall)
		return null

	var/list/try_dirs = list()
	var/preferred = turn(angle2dir(impact_angle), 180)
	if(preferred)
		try_dirs += preferred

	// Face of the wall that was hit (impact is centered -16..16 on the wall tile).
	if(impact_px > 6)
		try_dirs += EAST
	else if(impact_px < -6)
		try_dirs += WEST
	if(impact_py > 6)
		try_dirs += NORTH
	else if(impact_py < -6)
		try_dirs += SOUTH

	try_dirs += GLOB.cardinals
	try_dirs += GLOB.diagonals

	var/list/seen = list()
	for(var/check_dir as anything in try_dirs)
		if(seen["[check_dir]"])
			continue
		seen["[check_dir]"] = TRUE
		var/turf/candidate = get_step(wall, check_dir)
		if(bounce_spark_turf_open(candidate))
			return list(candidate, check_dir)

	return null

/// Pixel spawn on the open exit turf, pinned to the edge that touches the wall.
/proc/bounce_spark_wall_edge_pixels(into_room, impact_px, impact_py)
	var/px = clamp(impact_px + BOUNCE_SPARK_CENTER_OFFSET, 4, BOUNCE_SPARK_TILE_X - 4)
	var/py = clamp(impact_py + BOUNCE_SPARK_CENTER_OFFSET, 4, BOUNCE_SPARK_TILE_Y - 4)
	switch(into_room)
		if(NORTH)
			py = rand(2, 6)
		if(SOUTH)
			py = rand(BOUNCE_SPARK_TILE_Y - 6, BOUNCE_SPARK_TILE_Y - 2)
		if(EAST)
			px = rand(2, 6)
		if(WEST)
			px = rand(BOUNCE_SPARK_TILE_X - 6, BOUNCE_SPARK_TILE_X - 2)
		if(NORTHEAST)
			px = rand(2, 8)
			py = rand(2, 8)
		if(NORTHWEST)
			px = rand(BOUNCE_SPARK_TILE_X - 8, BOUNCE_SPARK_TILE_X - 2)
			py = rand(2, 8)
		if(SOUTHEAST)
			px = rand(2, 8)
			py = rand(BOUNCE_SPARK_TILE_Y - 8, BOUNCE_SPARK_TILE_Y - 2)
		if(SOUTHWEST)
			px = rand(BOUNCE_SPARK_TILE_X - 8, BOUNCE_SPARK_TILE_X - 2)
			py = rand(BOUNCE_SPARK_TILE_Y - 8, BOUNCE_SPARK_TILE_Y - 2)
	return list(px, py)

/// Only plain metal walls spark — mineral/ice/rock walls use the normal impact effect.
/proc/is_metal_bullet_spark_surface(atom/target)
	if(!iswallturf(target))
		return FALSE
	if(istype(target, /turf/closed/wall/ice) || istype(target, /turf/closed/wall/mineral/snow))
		return FALSE
	if(istype(target, /turf/closed/wall/mineral/wood))
		return FALSE
	if(istype(target, /turf/closed/wall/mineral/sandstone) || istype(target, /turf/closed/wall/rock))
		return FALSE
	if(istype(target, /turf/closed/wall/mineral/diamond) || istype(target, /turf/closed/wall/mineral/plasma))
		return FALSE
	return TRUE

/// Bullet strike on a metal wall: one particle burst spraying away from the impact face.
/// Pellet clouds and automatic fire would otherwise stack a burst per
/// pellet/shot onto the same wall patch — collapse bursts on one turf
/// inside a short window into a single spray.
GLOBAL_LIST_INIT(bounce_spark_throttle, list())

/proc/spawn_metal_wall_bullet_sparks(turf/wall, impact_px, impact_py, impact_angle)
	if(!wall)
		return

	var/last_burst = GLOB.bounce_spark_throttle[wall]
	if(last_burst && world.realtime - last_burst < 0.15)
		return
	GLOB.bounce_spark_throttle[wall] = world.realtime
	if(length(GLOB.bounce_spark_throttle) > 500)
		GLOB.bounce_spark_throttle.Cut()

	var/list/resolved = resolve_bounce_spark_spawn(wall, impact_angle, impact_px, impact_py)
	if(!resolved)
		return

	var/turf/spawn_turf = resolved[1]
	var/out_dir = resolved[2]
	var/px = resolved[3]
	var/py = resolved[4]
	var/base_angle = out_dir ? dir2angle(out_dir) : SIMPLIFY_DEGREES(impact_angle + 180)

	var/obj/effect/bullet_spark_burst/burst = new(spawn_turf, base_angle, px, py)
	if(!burst)
		return

	// Dust/smoke puff where the round struck, drifting up off the wall.
	var/obj/effect/firing_smoke/hit_smoke = new /obj/effect/firing_smoke(spawn_turf)
	if(hit_smoke)
		hit_smoke.pixel_x = px - BOUNCE_SPARK_CENTER_OFFSET
		hit_smoke.pixel_y = py - BOUNCE_SPARK_CENTER_OFFSET
		hit_smoke.particles.velocity = list(rand(-15, 15), rand(-30, -10), 0)

	// Same incidental heat the old atom sparks applied on their first spark.
	spawn_turf.hotspot_expose(1000, 100)

	if(prob(40))
		playsound(wall, get_sfx(SFX_SPARKS), 22, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/// Short-lived emitter pinned to the wall-edge pixel; dies on its own, the
/// particles inside die with their own lifespan.
/obj/effect/bullet_spark_burst
	name = "sparks"
	icon = null
	layer = ABOVE_OBJ_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE
	anchored = TRUE

/obj/effect/bullet_spark_burst/Initialize(mapload, launch_angle, spawn_px, spawn_py, power = FALSE)
	. = ..()
	pixel_x = spawn_px - BOUNCE_SPARK_CENTER_OFFSET
	pixel_y = spawn_py - BOUNCE_SPARK_CENTER_OFFSET
	particles = new /particles/bullet_sparks
	var/p_speed
	if(power)
		// Muzzle blast: a short scatter of powder flecks, kept dim so it
		// doesn't read as a second flash.
		particles.count = particles.spawning = rand(10, 16)
		particles.scale = generator("num", 0.1, 0.2)
		particles.lifespan = 0.35 SECONDS
		particles.fade = 0.18 SECONDS
		p_speed = rand(50, 75) / 10
	else
		particles.count = particles.spawning = rand(8, 12)
		p_speed = rand(30, 50) / 10
	// dir2angle(): 0 = north, clockwise; screen y grows downward.
	var/vx = sin(launch_angle) * p_speed
	var/vy = -cos(launch_angle) * p_speed
	var/spread = p_speed * 0.6
	particles.velocity = generator("vector", list(vx - spread, vy - spread, 0), list(vx + spread, vy + spread, 0))
	particles.color = pick("#FFB060", "#E8A050", "#FFD9A0")
	QDEL_IN(src, power ? 0.45 SECONDS : 0.5 SECONDS)

/obj/effect/bullet_spark_burst/Destroy()
	particles = null
	return ..()
