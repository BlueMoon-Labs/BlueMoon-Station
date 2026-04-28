/datum/element/sword_point
	element_flags = ELEMENT_DETACH

/datum/element/sword_point/Attach(datum/target)
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE)
		return
	if(!istype(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ITEM_ALT_AFTERATTACK, PROC_REF(point), override = TRUE)

/datum/element/sword_point/Detach(datum/source)
	. = ..()
	UnregisterSignal(source, COMSIG_ITEM_ALT_AFTERATTACK)

/datum/element/sword_point/proc/point(datum/source, atom/target, mob/user, proximity_flag, params)
	if(!proximity_flag && ismob(target))
		user.visible_message("<span class='warning'>[user] указывает кончиком своего [source] на [target].</span>", "<span class='warning'>Ты направляешь кончик своего [source] на [target].</span>")
