/turf/open/openspace
	name = "open space"
	desc = "Watch your step!"
	icon_state = "invisible"
	baseturfs = /turf/open/openspace
	CanAtmosPassVertical = ATMOS_PASS_YES
	turf_flags = TURF_FLAGS_DEFAULT & ~TURF_INTACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/can_cover_up = TRUE
	var/can_build_on = TRUE
	var/show_bottom_level = FALSE

/turf/open/openspace/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/openspace/Initialize(mapload) // handle plane and layer here so that they don't cover other obs/turfs in Dream Maker
	. = ..()
	ADD_TRAIT(src, TURF_Z_OPENSPACE_TRAIT, TURF_TRAIT)
	return INITIALIZE_HINT_LATELOAD

/turf/open/openspace/LateInitialize()
	. = ..()
	AddElement(/datum/element/turf_z_transparency, show_bottom_level)
	//AddElement мог откатить турф в пол, а ссылка на турф адресует координату: src здесь уже может быть полом.
	if(istype(src, /turf/open/openspace))
		RegisterSignal(src, COMSIG_ATOM_CREATED, PROC_REF(on_atom_created))

/// Взводит флаг падения, если шаг удастся. Именно Enter(): forceMove() его не зовёт, а oldloc == mover.loc отсекает примерочные вызовы.
/turf/open/openspace/Enter(atom/movable/mover, atom/oldloc, no_side_effects = FALSE)
	. = ..()
	if(. && !no_side_effects && oldloc == mover.loc)
		mover.set_currently_z_moving(CURRENTLY_Z_FALLING_FROM_MOVE)

/turf/open/openspace/Entered(atom/movable/AM)
	. = ..()
	if(QDELETED(AM) || AM.loc != src)
		return
	if(AM.set_currently_z_moving(CURRENTLY_Z_FALLING))
		zFall(AM, falling_from_move = TRUE)

/// Роняет заспавненное над дырой. Сигнал приходит в начале Initialize() атома, двигать его оттуда нельзя - отсюда таймер.
/turf/open/openspace/proc/on_atom_created(datum/source, atom/created_atom)
	SIGNAL_HANDLER
	if((!isobj(created_atom) && !isliving(created_atom)) || SSatoms.initialized != INITIALIZATION_INNEW_REGULAR)
		return
	addtimer(CALLBACK(src, PROC_REF(zfall_if_on_turf), created_atom), 0)

/turf/open/openspace/can_have_cabling()
	if(locate(/obj/structure/lattice/catwalk, src))
		return TRUE
	return FALSE

/turf/open/openspace/zAirIn()
	return TRUE

/turf/open/openspace/zAirOut()
	return TRUE

/turf/open/openspace/zPassIn(atom/movable/A, direction, turf/source)
	if(direction == DOWN)
		for(var/obj/O in contents)
			if(O.obj_flags & BLOCK_Z_IN_DOWN)
				return FALSE
		return TRUE
	if(direction == UP)
		for(var/obj/O in contents)
			if(O.obj_flags & BLOCK_Z_IN_UP)
				return FALSE
		return TRUE
	return FALSE

/turf/open/openspace/zPassOut(atom/movable/A, direction, turf/destination)
	if(A.anchored && !istype(A, /obj/vehicle/sealed))
		return FALSE
	if(direction == DOWN)
		for(var/obj/O in contents)
			if(O.obj_flags & BLOCK_Z_OUT_DOWN)
				return FALSE
		return TRUE
	if(direction == UP)
		for(var/obj/O in contents)
			if(O.obj_flags & BLOCK_Z_OUT_UP)
				return FALSE
		return TRUE
	return FALSE

/turf/open/openspace/proc/CanCoverUp()
	return can_cover_up

/turf/open/openspace/proc/CanBuildHere()
	return can_build_on

/turf/open/openspace/attackby(obj/item/C, mob/user, params)
	..()
	if(!CanBuildHere())
		return
	if(istype(C, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = C
		var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
		var/obj/structure/lattice/catwalk/W = locate(/obj/structure/lattice/catwalk, src)
		if(W)
			to_chat(user, "<span class='warning'>There is already a catwalk here!</span>")
			return
		if(L)
			if(R.use(1))
				qdel(L)
				to_chat(user, "<span class='notice'>You construct a catwalk.</span>")
				playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
				new/obj/structure/lattice/catwalk(src)
			else
				to_chat(user, "<span class='warning'>You need two rods to build a catwalk!</span>")
			return
		if(!HasAdjacentSupport())
			user.balloon_alert(user, "Не за что крепить! Нужна опора!")
			return
		if(R.use(1))
			to_chat(user, "<span class='notice'>You construct a lattice.</span>")
			playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
			ReplaceWithLattice()
		else
			to_chat(user, "<span class='warning'>You need one rod to build a lattice.</span>")
		return
	if(istype(C, /obj/item/stack/tile/plasteel))
		if(!CanCoverUp())
			return
		var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
		if(L)
			var/obj/item/stack/tile/plasteel/S = C
			if(S.use(1))
				playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
				to_chat(user, "<span class='notice'>You build a floor.</span>")
				//Пол сначала, решётку потом: снос опоры над дырой роняет всё, что на ней стоит.
				PlaceOnTop(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
				qdel(L)
			else
				to_chat(user, "<span class='warning'>You need one floor tile to build a floor!</span>")
		else
			to_chat(user, "<span class='warning'>The plating is going to need some support! Place iron rods first.</span>")

/turf/open/openspace/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(!CanBuildHere())
		return FALSE

	switch(the_rcd.mode)
		if(RCD_FLOORWALL)
			var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
			if(L)
				return list("mode" = RCD_FLOORWALL, "delay" = 0, "cost" = 1)
			else
				return list("mode" = RCD_FLOORWALL, "delay" = 0, "cost" = 3)
	return FALSE

/turf/open/openspace/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_FLOORWALL)
			to_chat(user, "<span class='notice'>You build a floor.</span>")
			PlaceOnTop(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
			return TRUE
	return FALSE

/turf/open/openspace/icemoon
	name = "ice chasm"
	baseturfs = /turf/open/openspace/icemoon
	initial_gas_mix = ICEMOON_DEFAULT_ATMOS
	planetary_atmos = TRUE
	var/replacement_turf = /turf/open/floor/plating/asteroid/snow/icemoon
	/// Replaces itself with replacement_turf if the turf below this one is in a no ruins allowed area (usually ruins themselves)
	var/protect_ruin = TRUE
	/// If true mineral turfs below this openspace turf will be mined automatically
	var/drill_below = TRUE

/turf/open/openspace/icemoon/Initialize(mapload)
	. = ..()
	var/turf/T = GET_TURF_BELOW(src)
	if(!T)
		return
	if(T.flags_1 & NO_RUINS_1 && protect_ruin)
		ChangeTurf(replacement_turf, null, CHANGETURF_IGNORE_AIR)
		return
	if(!ismineralturf(T) || !drill_below)
		return
	var/turf/closed/mineral/M = T
	M.mineralAmt = 0
	M.gets_drilled()
	baseturfs = /turf/open/openspace/icemoon //This is to ensure that IF random turf generation produces a openturf, there won't be other turfs assigned other than openspace.

/turf/open/openspace/icemoon/keep_below
	drill_below = FALSE

/turf/open/openspace/icemoon/ruins
	protect_ruin = FALSE
	drill_below = FALSE
