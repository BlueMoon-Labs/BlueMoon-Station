/datum/element/sword_point
	element_flags = ELEMENT_DETACH

/datum/element/sword_point/Attach(datum/target)
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE)
		return
	if(!istype(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ITEM_ALT_AFTERATTACK, PROC_REF(point), override = TRUE)
	RegisterSignal(target, COMSIG_ITEM_REQUESTING_CONTEXT_FOR_TARGET, PROC_REF(add_context), override = TRUE)
	var/obj/item/item_target = target
	if(istype(item_target))
		item_target.item_flags |= ITEM_HAS_CONTEXTUAL_SCREENTIPS

/datum/element/sword_point/Detach(datum/source)
	. = ..()
	UnregisterSignal(source, list(COMSIG_ITEM_ALT_AFTERATTACK, COMSIG_ITEM_REQUESTING_CONTEXT_FOR_TARGET))

/datum/element/sword_point/proc/point(datum/source, atom/target, mob/user, proximity_flag, params)
	if(!proximity_flag && ismob(target))
		user.visible_message("<span class='warning'>[user] указывает кончиком своего [source] на [target].</span>", "<span class='warning'>Ты направляешь кончик своего [source] на [target].</span>")

/datum/element/sword_point/proc/add_context(obj/item/source, list/context, atom/target, mob/living/user)
	SIGNAL_HANDLER
	if(!ismob(target) || user.CanReach(target, source))
		return NONE
	LAZYSET(context[SCREENTIP_CONTEXT_RMB], INTENT_ANY, "Указать клинком")
	return CONTEXTUAL_SCREENTIP_SET
