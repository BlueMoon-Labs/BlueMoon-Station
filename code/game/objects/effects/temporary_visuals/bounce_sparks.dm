// Emissive pixel sparks with bounce physics, ported from MyHornyHell's
// bounce_sparks.dm. Used for bullet impacts on metal walls — the sparks
// are real moving atoms, not a DMI animation.
// Adapted to BlueMoon: no LinkBlockedWithAccess pass-info (simple
// open-turf + dense-content check), single emissive color, and no
// COMSIG_ATOM_TOUCHED_SPARKS consumers (sparks only heat the turf).

#define BOUNCE_SPARK_TICK 0.08 SECONDS
#define BOUNCE_SPARK_GRAVITY 0.55
#define BOUNCE_SPARK_FRICTION 0.93
#define BOUNCE_SPARK_BOUNCE_DAMPING 0.45
#define BOUNCE_SPARK_GROUND_FRICTION 0.7
#define BOUNCE_SPARK_FLOOR_Y 2
#define BOUNCE_SPARK_MAX_TICKS 28
#define BOUNCE_SPARK_DIE_SPEED 1.2
#define BOUNCE_SPARK_DIE_SPEED_SQ (BOUNCE_SPARK_DIE_SPEED * BOUNCE_SPARK_DIE_SPEED)
#define BOUNCE_SPARK_COUNT_MULT 2.1
#define BOUNCE_SPARK_COUNT_MIN 7
#define BOUNCE_SPARK_COUNT_CAP 18
#define BOUNCE_SPARK_BULLET_SPEED_MIN 7
#define BOUNCE_SPARK_BULLET_SPEED_MAX 9
#define BOUNCE_SPARK_FADE_TIME 0.3 SECONDS
#define BOUNCE_SPARK_CENTER_OFFSET 16
#define BOUNCE_SPARK_TILE_X 32
#define BOUNCE_SPARK_TILE_Y 32

/// Open enough to spawn/fly into — ignore dense contents (chairs, people). Closed turfs blocked.
/proc/bounce_spark_turf_open(turf/check_turf)
	return check_turf && !check_turf.density && !isclosedturf(check_turf)

/// Can a spark cross from one open turf to an adjacent one? Walls block.
/proc/bounce_spark_can_cross(turf/from_turf, turf/to_turf)
	if(!from_turf || !to_turf)
		return FALSE
	return bounce_spark_turf_open(to_turf) && !to_turf.is_blocked_turf(exclude_mobs = TRUE)

/proc/scale_bounce_spark_count(requested)
	return clamp(max(round(requested * BOUNCE_SPARK_COUNT_MULT), BOUNCE_SPARK_COUNT_MIN), 1, BOUNCE_SPARK_COUNT_CAP)

/proc/bounce_spark_rand_bullet_speed()
	return rand(BOUNCE_SPARK_BULLET_SPEED_MIN * 10, BOUNCE_SPARK_BULLET_SPEED_MAX * 10) / 10

/// Spawns one spark on the given turf at tile-pixel coords (0..32).
/proc/spawn_bounce_spark_at(turf/spawn_turf, start_px, start_py, vel_x, vel_y, ignite = FALSE)
	if(!spawn_turf)
		return null
	var/obj/effect/temp_visual/bounce_spark/spark = new(spawn_turf, start_px, start_py, vel_x, vel_y)
	if(ignite && spark)
		spark.perform_world_interact()
	return spark

/// Resolve where sparks should actually appear. Closed turfs (walls) shift onto a free neighbor.
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

/// Pick an open turf next to a wall for spark spray.
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

/// Bullet strike on a metal wall: spray of sparks that physically bounce off surfaces.
/proc/spawn_metal_wall_bullet_sparks(turf/wall, impact_px, impact_py, impact_angle)
	if(!wall)
		return

	var/list/resolved = resolve_bounce_spark_spawn(wall, impact_angle, impact_px, impact_py)
	if(!resolved)
		return

	var/turf/spawn_turf = resolved[1]
	var/out_dir = resolved[2]
	var/px = resolved[3]
	var/py = resolved[4]
	var/base_angle = out_dir ? dir2angle(out_dir) : SIMPLIFY_DEGREES(impact_angle + 180)
	var/spark_count = rand(7, 11)

	for(var/i in 1 to spark_count)
		var/launch_angle = SIMPLIFY_DEGREES(base_angle + rand(-40, 40))
		var/speed = bounce_spark_rand_bullet_speed()
		spawn_bounce_spark_at(
			spawn_turf,
			px + rand(-3, 3),
			py + rand(-3, 3),
			sin(launch_angle) * speed,
			cos(launch_angle) * speed,
			ignite = (i == 1),
		)

	if(prob(40))
		playsound(wall, get_sfx(SFX_SPARKS), 22, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/effect/temp_visual/bounce_spark
	name = "spark"
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = "dot"
	layer = ABOVE_OBJ_LAYER
	duration = 30
	randomdir = FALSE
	blocks_emissive = EMISSIVE_BLOCK_NONE
	/// Movement is driven entirely by manual pixel animation; disable BYOND's auto-glide so
	/// crossing a turf boundary doesn't fight the pixel tween and rubber-band ("slingshot").
	animate_movement = NO_STEPS
	var/mutable_appearance/spark_glow_overlay
	var/vel_x
	var/vel_y
	var/pos_x
	var/pos_y
	var/tick_count = 0
	var/floor_bounces = 0
	var/dying = FALSE
	var/retiring = FALSE
	var/physics_timer
	var/retire_timer

/obj/effect/temp_visual/bounce_spark/Initialize(mapload, start_px, start_py, initial_vel_x, initial_vel_y)
	apply_spawn_state(start_px, start_py, initial_vel_x, initial_vel_y)
	. = ..()
	deltimer(timerid)
	timerid = null
	setup_emissive_glow()
	start_physics()

/obj/effect/temp_visual/bounce_spark/proc/apply_spawn_state(start_px, start_py, initial_vel_x, initial_vel_y)
	pos_x = start_px
	pos_y = start_py
	pixel_x = round(start_px) - BOUNCE_SPARK_CENTER_OFFSET
	pixel_y = round(start_py) - BOUNCE_SPARK_CENTER_OFFSET
	// Hard clamp — kills "random bullet speed" from bad args / leftover state.
	vel_x = clamp(initial_vel_x, -BOUNCE_SPARK_BULLET_SPEED_MAX, BOUNCE_SPARK_BULLET_SPEED_MAX)
	vel_y = clamp(initial_vel_y, -BOUNCE_SPARK_BULLET_SPEED_MAX, BOUNCE_SPARK_BULLET_SPEED_MAX)
	dying = FALSE
	retiring = FALSE
	floor_bounces = 0
	tick_count = 0
	pick_spark_color()
	transform = matrix().Scale(rand(7, 10) / 10, rand(7, 10) / 10)
	alpha = initial(alpha)

/obj/effect/temp_visual/bounce_spark/proc/pick_spark_color()
	color = pick("#FFE080", "#FFB040", "#FFFFFF")

/obj/effect/temp_visual/bounce_spark/proc/setup_emissive_glow()
	if(spark_glow_overlay)
		return
	spark_glow_overlay = emissive_appearance(icon, icon_state, offset_spokesman = src, alpha = 200)
	add_overlay(spark_glow_overlay)

/obj/effect/temp_visual/bounce_spark/proc/clear_emissive_glow()
	if(!spark_glow_overlay)
		return
	cut_overlay(spark_glow_overlay)
	spark_glow_overlay = null

/obj/effect/temp_visual/bounce_spark/proc/start_physics()
	if(physics_timer)
		deltimer(physics_timer)
	physics_timer = addtimer(CALLBACK(src, PROC_REF(physics_tick)), BOUNCE_SPARK_TICK, TIMER_LOOP | TIMER_STOPPABLE)

/obj/effect/temp_visual/bounce_spark/proc/stop_physics()
	if(physics_timer)
		deltimer(physics_timer)
		physics_timer = null
	if(retire_timer)
		deltimer(retire_timer)
		retire_timer = null

/obj/effect/temp_visual/bounce_spark/proc/physics_tick()
	if(QDELETED(src) || dying || retiring)
		return

	tick_count++
	if(tick_count > BOUNCE_SPARK_MAX_TICKS)
		retire_spark()
		return

	vel_y -= BOUNCE_SPARK_GRAVITY
	vel_x *= BOUNCE_SPARK_FRICTION
	vel_y *= BOUNCE_SPARK_FRICTION

	pos_x += vel_x
	pos_y += vel_y

	var/turf/current = loc
	if(!isturf(current))
		current = get_turf(src)

	while(pos_x < 0)
		var/turf/west = get_step(current, WEST)
		if(bounce_spark_can_cross(current, west))
			current = west
			pos_x += BOUNCE_SPARK_TILE_X
		else
			vel_x = abs(vel_x) * BOUNCE_SPARK_BOUNCE_DAMPING
			pos_x = 1
			break

	while(pos_x >= BOUNCE_SPARK_TILE_X)
		var/turf/east = get_step(current, EAST)
		if(bounce_spark_can_cross(current, east))
			current = east
			pos_x -= BOUNCE_SPARK_TILE_X
		else
			vel_x = -abs(vel_x) * BOUNCE_SPARK_BOUNCE_DAMPING
			pos_x = BOUNCE_SPARK_TILE_X - 1
			break

	while(pos_y >= BOUNCE_SPARK_TILE_Y)
		var/turf/north = get_step(current, NORTH)
		if(bounce_spark_can_cross(current, north))
			current = north
			pos_y -= BOUNCE_SPARK_TILE_Y
		else
			vel_y = -abs(vel_y) * BOUNCE_SPARK_BOUNCE_DAMPING
			pos_y = BOUNCE_SPARK_TILE_Y - 1
			break

	while(pos_y < 0)
		var/turf/south = get_step(current, SOUTH)
		if(bounce_spark_can_cross(current, south))
			current = south
			pos_y += BOUNCE_SPARK_TILE_Y
		else
			vel_y = abs(vel_y) * BOUNCE_SPARK_BOUNCE_DAMPING
			pos_y = 1
			break

	if(pos_y < BOUNCE_SPARK_FLOOR_Y && vel_y < 0)
		pos_y = BOUNCE_SPARK_FLOOR_Y
		vel_y = -vel_y * BOUNCE_SPARK_BOUNCE_DAMPING
		vel_x *= BOUNCE_SPARK_GROUND_FRICTION
		floor_bounces++

	apply_visual_position(current, pos_x, pos_y)

	if(floor_bounces >= 1 && (vel_x * vel_x + vel_y * vel_y) < BOUNCE_SPARK_DIE_SPEED_SQ)
		begin_dying()

/obj/effect/temp_visual/bounce_spark/proc/apply_visual_position(turf/target_turf, target_px, target_py)
	if(!target_turf)
		return

	var/turf/old_turf = loc
	if(!isturf(old_turf))
		old_turf = get_turf(src)

	var/target_pixel_x = round(target_px) - BOUNCE_SPARK_CENTER_OFFSET
	var/target_pixel_y = round(target_py) - BOUNCE_SPARK_CENTER_OFFSET

	if(old_turf && target_turf != old_turf)
		var/x_diff = target_turf.x - old_turf.x
		var/y_diff = target_turf.y - old_turf.y
		abstract_move(target_turf)
		if(x_diff)
			pixel_x -= x_diff * BOUNCE_SPARK_TILE_X
		if(y_diff)
			pixel_y -= y_diff * BOUNCE_SPARK_TILE_Y
	else if(!old_turf)
		abstract_move(target_turf)

	pos_x = target_px
	pos_y = target_py

	if(pixel_x == target_pixel_x && pixel_y == target_pixel_y)
		return

	animate(src, flags = ANIMATION_END_NOW)
	animate(
		src,
		pixel_x = target_pixel_x,
		pixel_y = target_pixel_y,
		time = BOUNCE_SPARK_TICK,
		flags = ANIMATION_PARALLEL,
	)

/obj/effect/temp_visual/bounce_spark/proc/begin_dying()
	if(dying || retiring)
		return
	dying = TRUE
	if(physics_timer)
		deltimer(physics_timer)
		physics_timer = null
		animate(src, alpha = 0, time = BOUNCE_SPARK_FADE_TIME, flags = ANIMATION_PARALLEL)
	retire_timer = addtimer(CALLBACK(src, PROC_REF(retire_spark)), BOUNCE_SPARK_FADE_TIME, TIMER_STOPPABLE)

/obj/effect/temp_visual/bounce_spark/proc/perform_world_interact()
	var/turf/location = get_turf(src)
	if(!isturf(location))
		return
	location.hotspot_expose(1000, 100)

/obj/effect/temp_visual/bounce_spark/proc/retire_spark()
	if(QDELETED(src) || retiring)
		return
	retiring = TRUE
	stop_physics()
	animate(src, flags = ANIMATION_END_NOW)
	qdel(src)

/obj/effect/temp_visual/bounce_spark/Destroy()
	stop_physics()
	animate(src, flags = ANIMATION_END_NOW)
	clear_emissive_glow()
	return ..()
