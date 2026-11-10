// the disposal outlet machine
/obj/structure/disposaloutlet
	name = "disposal outlet"
	desc = "An outlet for the pneumatic disposal system."
	icon = 'icons/obj/atmospherics/pipes/disposal.dmi'
	icon_state = "outlet"
	density = TRUE
	anchored = TRUE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	var/active = FALSE
	var/turf/target	// this will be where the output objects are 'thrown' to.
	var/obj/structure/disposalpipe/trunk/trunk // the attached pipe trunk
	var/obj/structure/disposalconstruct/stored
	var/start_eject = 0
	var/eject_range = 2

/obj/structure/disposaloutlet/Initialize(mapload, obj/structure/disposalconstruct/make_from)
	. = ..()
	if(make_from)
		setDir(make_from.dir)
		make_from.forceMove(src)
		stored = make_from
	else
		stored = new /obj/structure/disposalconstruct(src, null , SOUTH , FALSE , src)

	target = get_ranged_target_turf(src, dir, 10)

	trunk = locate() in loc
	if(trunk)
		trunk.linked = src	// link the pipe trunk to self

/obj/structure/disposaloutlet/Destroy()
	if(trunk)
		trunk.linked = null
		trunk = null
	QDEL_NULL(stored)
	return ..()

//BLUEMOON ADD START
//При смещении мусорного выхода разъединяет связь с трубой под ним
/obj/structure/disposaloutlet/Move()
	if(trunk)
		trunk.linked = null
		trunk = null
	QDEL_NULL(stored)
	return ..()
//BLUEMOON ADD END

// expel the contents of the holder object, then delete it
// called when the holder exits the outlet
/obj/structure/disposaloutlet/proc/expel(obj/structure/disposalholder/H)
	H.active = FALSE
	flick("outlet-open", src)
	if((start_eject + 30) < world.time)
		start_eject = world.time
		playsound(src, 'sound/machines/warning-buzzer.ogg', 50, 0, 0)
		addtimer(CALLBACK(src, PROC_REF(expel_holder), H, TRUE), 20)
	else
		addtimer(CALLBACK(src, PROC_REF(expel_holder), H), 20)

/obj/structure/disposaloutlet/proc/expel_holder(obj/structure/disposalholder/H, playsound=FALSE)
	if(playsound)
		playsound(src, 'sound/machines/hiss.ogg', 50, 0, 0)

	if(QDELETED(H))
		return

	var/turf/T = get_turf(src)
	var/eject_dir = dir
	var/turf/eject_target = target
	var/range = eject_range

	// Слитые в трубе пачки бывают по сотне предметов, и каждый бросок на общий турф дороже
	// предыдущего: выброс идёт кусками по тикам. Холдер в это время могут слить с новым.
	for(var/atom/movable/AM as anything in H)
		if(QDELETED(H))
			return
		if(AM.loc != H)
			continue
		AM.forceMove(T)
		AM.pipe_eject(eject_dir)
		AM.throw_at(eject_target, range, 1)
		CHECK_TICK

	if(QDELETED(H))
		return
	H.vent_gas(T)
	qdel(H)

/obj/structure/disposaloutlet/welder_act(mob/living/user, obj/item/I)
	if(!I.tool_start_check(user, amount=0))
		return TRUE

	playsound(src, 'sound/items/welder2.ogg', 100, 1)
	to_chat(user, "<span class='notice'>You start slicing the floorweld off [src]...</span>")
	if(I.use_tool(src, user, 20))
		to_chat(user, "<span class='notice'>You slice the floorweld off [src].</span>")
		stored.forceMove(loc)
		transfer_fingerprints_to(stored)
		stored = null
		qdel(src)
	return TRUE
