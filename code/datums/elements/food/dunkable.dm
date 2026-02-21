// If an item has the dunkable element, it's able to be dunked into reagent containers like beakers and glasses.
// Dunking the item into a container will transfer reagents from the container to the item.
/datum/element/dunkable
	element_flags = ELEMENT_BESPOKE
	id_arg_index = 2
	var/dunk_amount // the amount of reagents that will be transferred from the container to the item on each click

/datum/element/dunkable/Attach(datum/target, amount_per_dunk)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE
	dunk_amount = amount_per_dunk
	RegisterSignal(target, COMSIG_ITEM_INTERACTING_WITH_ATOM, PROC_REF(get_dunked))
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/element/dunkable/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, list(COMSIG_ITEM_INTERACTING_WITH_ATOM, COMSIG_PARENT_EXAMINE))

/datum/element/dunkable/proc/on_examine(obj/item/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("Выглядит так, будто [source.ru_ego()] можно [span_bold("обмакнуть")] в жидкость.")

/datum/element/dunkable/proc/get_dunked(obj/item/source, mob/user, atom/target, params)
	SIGNAL_HANDLER

	if(target.reagents?.reagents_holder_flags & DUNKABLE) // container should be a valid target for dunking
		if(!target.is_drainable())
			to_chat(user, span_warning("[target] is unable to be dunked in!"))
			return STOP_ATTACK_PROC_CHAIN
		if(target.reagents.trans_to(source, dunk_amount)) //if reagents were transferred, show the message
			to_chat(user, span_notice("You dunk \the [target] into \the [target]."))
			return STOP_ATTACK_PROC_CHAIN
		if(!target.reagents.total_volume)
			to_chat(user, span_warning("[target] is empty!"))
		else
			to_chat(user, span_warning("[source] is full!"))
		return STOP_ATTACK_PROC_CHAIN
	return NONE
