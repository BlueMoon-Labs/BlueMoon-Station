/datum/element/dusts_on_catatonia
	element_flags = ELEMENT_DETACH
	var/list/mob/attached_mobs = list()

/datum/element/dusts_on_catatonia/Attach(datum/target,penalize = FALSE)
	. = ..()
	if(!ismob(target))
		return ELEMENT_INCOMPATIBLE
	var/mob/M = target
	if(!(M in attached_mobs))
		attached_mobs += M
	START_PROCESSING(SSprocessing,src)

/datum/element/dusts_on_catatonia/Detach(mob/M)
	. = ..()
	if(M in attached_mobs)
		attached_mobs -= M
	if(!attached_mobs.len)
		STOP_PROCESSING(SSprocessing,src)

/datum/element/dusts_on_catatonia/process()
	var/found_null = FALSE
	for(var/mob/attached_mob as anything in attached_mobs)
		if(isnull(attached_mob))
			found_null = TRUE
			continue
		if(!attached_mob.key && !attached_mob.get_ghost())
			attached_mob.dust(TRUE, FALSE, TRUE)
			Detach(attached_mob)
	if(found_null)
		listclearnulls(attached_mobs)
		if(!attached_mobs.len)
			STOP_PROCESSING(SSprocessing, src)
