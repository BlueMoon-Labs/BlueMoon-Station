// If an item has this element, it can be dried on a drying rack.
/datum/element/dryable
	element_flags = ELEMENT_BESPOKE
	id_arg_index = 2
	/// The type of atom that is spawned by this element on drying.
	var/atom/dry_result

/datum/element/dryable/Attach(datum/target, atom/dry_result)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	src.dry_result = dry_result

	RegisterSignal(target, COMSIG_ITEM_DRIED, PROC_REF(finish_drying))
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	ADD_TRAIT(target, TRAIT_DRYABLE, ELEMENT_TRAIT(type))

/datum/element/dryable/Detach(datum/source)
	. = ..()
	UnregisterSignal(source, list(COMSIG_ITEM_DRIED, COMSIG_PARENT_EXAMINE))
	REMOVE_TRAIT(source, TRAIT_DRYABLE, ELEMENT_TRAIT(type))

/datum/element/dryable/proc/finish_drying(atom/source, datum/weakref/drying_user)
	SIGNAL_HANDLER
	var/atom/dried_atom = source
	if(dry_result == dried_atom.type)//if the dried type is the same as our currrent state, don't bother creating a whole new item, just re-color it.
		var/atom/movable/resulting_atom = dried_atom
		resulting_atom.add_atom_colour("#ad7257", FIXED_COLOUR_PRIORITY)
		apply_dried_status(resulting_atom, drying_user)
		return
	else if(isstack(source)) //Check if its a sheet
		var/obj/item/stack/itemstack = dried_atom
		for(var/i in 1 to itemstack.amount)
			var/atom/movable/resulting_atom = new dry_result(source.loc)
			apply_dried_status(resulting_atom, drying_user)
		qdel(source)
		return

	var/obj/item/reagent_containers/food/snacks/resulting_atom = new dry_result(source.loc)
	if(istype(source, /obj/item/reagent_containers/food/snacks) && ispath(dry_result, /obj/item/reagent_containers/food/snacks))
		var/obj/item/reagent_containers/food/snacks/source_food = source
		resulting_atom.reagents.clear_reagents()
		source_food.reagents.trans_to(resulting_atom, source_food.reagents.total_volume)
	resulting_atom.set_custom_materials(source.custom_materials)
	apply_dried_status(resulting_atom, drying_user)
	qdel(source)

/datum/element/dryable/proc/apply_dried_status(atom/target, datum/weakref/drying_user)
	ADD_TRAIT(target, TRAIT_DRIED, ELEMENT_TRAIT(type))
	var/datum/mind/user_mind = drying_user?.resolve()
	if(user_mind && IS_EDIBLE(target))
		ADD_TRAIT(target, TRAIT_FOOD_CHEF_MADE, REF(user_mind))

/**
 * Signal proc for [COMSIG_PARENT_EXAMINE].
 */
/datum/element/dryable/proc/on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(source.type == dry_result)
		examine_list += span_notice("Возможно немного высушить в [span_bold("сушилке")].")
	else
		examine_list += span_notice("Возможно высушить в [span_bold("сушилке")] в [initial(dry_result.name)].")
