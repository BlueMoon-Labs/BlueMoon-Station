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
		//WHITE-STEEL PORT: у космоса нет соседств и активной атмосферы - чистить нечего.
		if(!isspaceturf(T))
			T.clear_adjacencies()
			if(T.excited)
				SSair.remove_from_active(T)
		CHECK_TICK

//init_turfs - необязательный список турфов, которые нужно переинициализировать
//(турфы, реально поставленные генератором). Если он не передан - проходим весь Z,
//минуя космос. Раньше Initalize_Atmos() звался на всех ~65k турфов уровня, отсюда
//многолетние фризы при генерации руин на каждом Z.
/datum/controller/subsystem/air/proc/unpause_z(z_level, list/init_turfs)
	LAZYREMOVE(paused_z_levels, z_level)
	if(init_turfs)
		for(var/turf/T in init_turfs)
			if(istype(T, /turf/open) && !isspaceturf(T))
				T.Initalize_Atmos()
			CHECK_TICK
		return
	for(var/turf/open/T in block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level)))
		if(!isspaceturf(T))
			T.Initalize_Atmos()
		CHECK_TICK
