GLOBAL_LIST_EMPTY(lighting_update_lights) // List of lighting sources  queued for update.
GLOBAL_LIST_EMPTY(lighting_update_corners) // List of lighting corners  queued for update.
GLOBAL_LIST_EMPTY(lighting_update_objects) // List of lighting objects queued for update.

/// Maximum light sources processed per fire to prevent tick budget monopolization during mass events (explosions, power changes).
/// Corners and objects are cheap operations and rely solely on MC_TICK_CHECK for budget gating.
#define LIGHTING_MAX_SOURCES_PER_FIRE 75

SUBSYSTEM_DEF(lighting)
	name = "Lighting"
	wait = 1
	init_order = INIT_ORDER_LIGHTING
	flags = SS_TICKER

/datum/controller/subsystem/lighting/stat_entry(msg)
	msg = "L:[length(GLOB.lighting_update_lights)]|C:[length(GLOB.lighting_update_corners)]|O:[length(GLOB.lighting_update_objects)]"
	return ..()

/datum/controller/subsystem/lighting/Initialize(timeofday)
	if(!initialized)
		if (CONFIG_GET(flag/starlight))
			for(var/I in GLOB.sortedAreas)
				var/area/A = I
				if (A.dynamic_lighting == DYNAMIC_LIGHTING_IFSTARLIGHT)
					A.luminosity = 0

		create_all_lighting_objects()
		initialized = TRUE

	fire(FALSE, TRUE)

	return ..()

/datum/controller/subsystem/lighting/fire(resumed, init_tick_checks)
	MC_SPLIT_TICK_INIT(3)
	if(!init_tick_checks)
		MC_SPLIT_TICK
	var/i = 0
	var/phase_limit
	phase_limit = init_tick_checks ? GLOB.lighting_update_lights.len : min(GLOB.lighting_update_lights.len, LIGHTING_MAX_SOURCES_PER_FIRE)
	for (i in 1 to phase_limit)
		if (i > GLOB.lighting_update_lights.len)
			break
		var/datum/light_source/L = GLOB.lighting_update_lights[i]
		if (QDELETED(L))
			continue

		L.update_corners()

		L.needs_update = LIGHTING_NO_UPDATE

		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		GLOB.lighting_update_lights.Cut(1, min(i + 1, length(GLOB.lighting_update_lights) + 1))
		i = 0

	if(!init_tick_checks)
		MC_SPLIT_TICK

	for (i in 1 to GLOB.lighting_update_corners.len)
		var/datum/lighting_corner/C = GLOB.lighting_update_corners[i]

		C.update_objects()
		C.needs_update = FALSE
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		GLOB.lighting_update_corners.Cut(1, min(i + 1, length(GLOB.lighting_update_corners) + 1))
		i = 0


	if(!init_tick_checks)
		MC_SPLIT_TICK

	for (i in 1 to GLOB.lighting_update_objects.len)
		var/datum/lighting_object/O = GLOB.lighting_update_objects[i]

		if (QDELETED(O))
			continue

		O.update()
		O.needs_update = FALSE
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		GLOB.lighting_update_objects.Cut(1, min(i + 1, length(GLOB.lighting_update_objects) + 1))


/datum/controller/subsystem/lighting/Recover()
	initialized = SSlighting.initialized
	..()
