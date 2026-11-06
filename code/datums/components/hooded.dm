/// Вешается костюмом на любой предмет головы, чтобы тот вёл себя как его капюшон.
/datum/component/suit_hood
	var/obj/item/clothing/suit/hooded/suit

/datum/component/suit_hood/Initialize(obj/item/clothing/suit/hooded/hood_suit)
	if(!istype(parent, /obj/item/clothing/head) || !istype(hood_suit))
		return COMPONENT_INCOMPATIBLE
	suit = hood_suit
	RegisterSignal(suit, COMSIG_PARENT_QDELETING, PROC_REF(on_suit_qdel))

/datum/component/suit_hood/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))

/datum/component/suit_hood/proc/on_equipped(datum/source, mob/user, slot)
	SIGNAL_HANDLER
	if(slot == ITEM_SLOT_HEAD)
		return
	if(suit)
		suit.RemoveHood()
	else
		qdel(parent)

/datum/component/suit_hood/proc/on_dropped(datum/source, mob/user)
	SIGNAL_HANDLER
	suit?.RemoveHood()

/datum/component/suit_hood/proc/on_suit_qdel(datum/source)
	SIGNAL_HANDLER
	suit = null

/datum/component/suit_hood/Destroy()
	if(suit)
		UnregisterSignal(suit, COMSIG_PARENT_QDELETING)
		suit = null
	return ..()
