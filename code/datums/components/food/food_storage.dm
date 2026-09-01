/// --Food storage component--
/// This component lets you slide one item into large foods, such as bread, cheese wheels, or cakes.
/// Consuming food storages with an item inside can cause unique interactions, such as eating glass shards.

/datum/component/food_storage
	/// Reference to what we have in our food.
	VAR_FINAL/obj/item/stored_item
	/// The amount of volume the food has on creation - Used for probabilities
	var/initial_volume = 10
	/// Minimum size items that can be inserted
	var/minimum_weight_class = WEIGHT_CLASS_SMALL
	/// What are the odds we see the stored item before we bite it?
	var/chance_of_discovery = 100

/datum/component/food_storage/Initialize(_minimum_weight_class = WEIGHT_CLASS_SMALL, _discovery_chance = 100)

	RegisterSignal(parent, COMSIG_CLICK_CTRL_SHIFT, PROC_REF(try_inserting_item))
	RegisterSignal(parent, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, PROC_REF(on_requesting_context_from_item))
	RegisterSignal(parent, COMSIG_CLICK_CTRL, PROC_REF(try_removing_item))
	RegisterSignal(parent, COMSIG_FOOD_EATEN, PROC_REF(consume_food_storage))
	RegisterSignals(parent, list(COMSIG_FOOD_CONSUMED, COMSIG_OBJ_DECONSTRUCT), PROC_REF(storage_consumed))

	var/atom/food = parent
	initial_volume = food.reagents.total_volume

	minimum_weight_class = _minimum_weight_class
	chance_of_discovery = _discovery_chance

	food.flags_1 |= HAS_CONTEXTUAL_SCREENTIPS_1

/datum/component/food_storage/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_CLICK_CTRL_SHIFT,
		COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM,
		COMSIG_CLICK_CTRL,
		COMSIG_FOOD_CONSUMED,
		COMSIG_FOOD_EATEN,
		COMSIG_OBJ_DECONSTRUCT,
	))
	if(QDELING(parent) || QDELETED(stored_item))
		return
	stored_item.forceMove(stored_item.drop_location())
	stored_item = null

/** Begins the process of inserted an item.
 *
 * Clicking on the food storage with an item will begin a do_after, which if successful inserts the item.
 *
 * Arguments
 * user - the person inserting the item
 */
/datum/component/food_storage/proc/try_inserting_item(datum/source, mob/living/user)
	SIGNAL_HANDLER

	var/obj/item/inserted_item = user.get_active_held_item()
	if(isnull(inserted_item))
		return NONE
	// No matryoshka-ing food storage
	if(istype(inserted_item, /obj/item/storage) || IS_EDIBLE(inserted_item))
		return NONE

	if(inserted_item.w_class > minimum_weight_class)
		to_chat(user, span_warning("[inserted_item] won't fit in [parent]."))
		return STOP_ATTACK_PROC_CHAIN

	if(!QDELETED(stored_item))
		to_chat(user, span_warning("There's something in [parent]."))
		return STOP_ATTACK_PROC_CHAIN

	user.visible_message(
		span_notice("[user] begins inserting [inserted_item] into [parent]."),
		span_notice("You start to insert the [inserted_item] into [parent]."),
	)

	INVOKE_ASYNC(src, PROC_REF(insert_item), inserted_item, user)
	return STOP_ATTACK_PROC_CHAIN

/** Begins the process of attempting to remove the stored item.
 *
 * Clicking on food storage on grab intent will begin a do_after, which if successful removes the stored_item.
 *
 * Arguments
 * user - the person removing the item.
 */
/datum/component/food_storage/proc/try_removing_item(datum/source, mob/user)
	SIGNAL_HANDLER

	var/atom/food = parent

	if(!food.can_interact(user))
		return STOP_ATTACK_PROC_CHAIN

	user.visible_message(span_notice("[user] begins tearing at [parent]."), \
					span_notice("You start to rip into [parent]."))

	INVOKE_ASYNC(src, PROC_REF(begin_remove_item), user)
	return STOP_ATTACK_PROC_CHAIN

/** Inserts the item into the food, after a do_after.
 *
 * Arguments
 * inserted_item - The item being inserted.
 * user - the person inserting the item.
 */
/datum/component/food_storage/proc/insert_item(obj/item/inserted_item, mob/user)
	if(!do_after(user, 1.5 SECONDS, target = parent))
		return
	if(!user.temporarilyRemoveItemFromInventory(inserted_item))
		to_chat(user, span_warning("You can't seem to insert [inserted_item] into [parent]."))
		return

	var/atom/food = parent
	to_chat(user, span_notice("You slip [inserted_item] inside [parent]."))
	inserted_item.forceMove(food)
	user.log_message("inserted [inserted_item] into [parent].", LOG_ATTACK)
	food.add_fingerprint(user)
	inserted_item.add_fingerprint(user)

	stored_item = inserted_item

/** Removes the item from the food, after a do_after.
 *
 * Arguments
 * user - person removing the item.
 */
/datum/component/food_storage/proc/begin_remove_item(mob/user)
	if(!do_after(user, 10 SECONDS, target = parent))
		return
	if(QDELETED(stored_item))
		to_chat(user, span_warning("There's nothing in [parent]."))
		return
	remove_item(user)

/**
 * Removes the stored item, putting it in user's hands or on the ground, then updates the reference.
 */
/datum/component/food_storage/proc/remove_item(mob/user)
	if(user.put_in_hands(stored_item))
		user.visible_message(span_warning("[user] slowly pulls [stored_item] out of [parent]."), \
							span_warning("You slowly pull [stored_item] out of [parent]."))
	else
		stored_item.visible_message(span_warning("[stored_item] falls out of [parent]."))

	update_stored_item()

/** Checks for stored items when the food is eaten.
 *
 * If the food is eaten while an item is stored in it, calculates the odds that the item will be found.
 * Then, if the item is found before being bitten, the item is removed.
 * If the item is found by biting into it, calls on_accidental_consumption on the stored item.
 * Afterwards, removes the item from the food if it was discovered.
 *
 * Arguments
 * target - person doing the eating (can be the same as user)
 * user - person causing the eating to happen
 * bitecount - how many times the current food has been bitten
 * bitesize - how large bties are for this food
 */
/datum/component/food_storage/proc/consume_food_storage(datum/source, mob/living/target, mob/living/user, bitecount, bitesize)
	SIGNAL_HANDLER

	if(QDELETED(stored_item)) //if the stored item was deleted/null...
		if(!update_stored_item()) //check if there's a replacement item
			return

	var/discovered = FALSE
	if(prob(chance_of_discovery)) //finding the item, without biting it
		discovered = TRUE
		to_chat(target, span_warning("It feels like there's something in [parent]...!"))

	if(!QDELETED(stored_item) && discovered)
		INVOKE_ASYNC(src, PROC_REF(remove_item), user)

/// When fully consumed, just drop the item out on the ground.
/datum/component/food_storage/proc/storage_consumed(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(QDELETED(stored_item))
		return
	stored_item.forceMove(stored_item.drop_location())
	stored_item = null

/** Updates the reference of the stored item.
 *
 * Checks the food's contents for if an alternate item was placed into the food.
 * If there is an alternate item, updates the reference to the new item.
 * If there isn't, updates the reference to null.
 *
 * Returns FALSE if the ref is nulled, or TRUE is another item replaced it.
 */
/datum/component/food_storage/proc/update_stored_item()
	var/atom/food = parent
	if(!food?.contents.len) //if there's no items in the food or food is deleted somehow
		stored_item = null
		return FALSE

	for(var/obj/item/i in food.contents) //search the food's contents for a replacement item
		if(IS_EDIBLE(i))
			continue
		if(QDELETED(i))
			continue

		stored_item = i //we found something to replace it
		return TRUE

	//if there's nothing else in the food, or we found nothing valid
	stored_item = null
	return FALSE

/**
 * Adds context sensitivy directly to the processable file for screentips
 * Arguments:
 * * source - refers to item that will display its screentip
 * * context - refers to, in this case, an item that can be inserted into another item
 * * held_item - refers to item in user's hand, typically the one that will be inserted into the food item
 * * user - refers to user who will see the screentip when the proper context and tool are there
 */

/datum/component/food_storage/proc/on_requesting_context_from_item(datum/source, list/context, obj/item/held_item, mob/user)
	SIGNAL_HANDLER
	context[SCREENTIP_CONTEXT_CTRL_LMB] = "Remove embedded item (if any)"
	. = CONTEXTUAL_SCREENTIP_SET

	if(istype(held_item) && held_item.w_class <= WEIGHT_CLASS_SMALL && held_item != source && !IS_EDIBLE(held_item))
		context[SCREENTIP_CONTEXT_CTRL_SHIFT_LMB] = "Embed item"
		. = CONTEXTUAL_SCREENTIP_SET

	return .
