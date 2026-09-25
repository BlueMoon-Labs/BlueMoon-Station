//WHITE-STEEL PORT: zclear atmos freeze
//BLUEMOON ADAPTATION: bluemoon SSair is a custom rewrite. White's pause_z called
//ImmediateDisableAdjacency; here the mechanical equivalent is clearing the turf's
//adjacency cache (halts all gas sharing) and evicting it from the active turf list
//through SSair's own O(1) helpers.

/datum/controller/subsystem/air
	//Z-levels whose atmos simulation is currently frozen during a zclear wipe.
	var/list/paused_z_levels = list()

/datum/controller/subsystem/air/proc/pause_z(z_level)
	if(!z_level)
		return
	LAZYOR(paused_z_levels, z_level)
	for(var/turf/open/T in block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level)))
		T.clear_adjacencies()
		if(T.excited)
			SSair.remove_from_active(T)
		CHECK_TICK

/datum/controller/subsystem/air/proc/unpause_z(z_level)
	LAZYREMOVE(paused_z_levels, z_level)
	for(var/turf/open/T in block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level)))
		T.Initalize_Atmos()
		CHECK_TICK
