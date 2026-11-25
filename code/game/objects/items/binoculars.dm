/obj/item/binoculars
	name = "binoculars"
	desc = "Used for long-distance surveillance."
	item_state = "binoculars"
	icon_state = "binoculars"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	var/mob/listeningTo
	var/scope_range = 4

/obj/item/binoculars/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/binoculars/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=8, force_wielded=12)
	AddComponent(/datum/component/scope, range_modifier = scope_range, category = "scope_binoculars", severity = 0)

/obj/item/binoculars/Destroy()
	if(listeningTo)
		unwield(listeningTo)
	listeningTo = null
	return ..()

/obj/item/binoculars/proc/on_wield(obj/item/source, mob/user)
	if(!user?.client)
		return
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_walk))
	listeningTo = user
	user.visible_message("<span class='notice'>[user] holds [src] up to [user.ru_ego()] eyes.</span>", "<span class='notice'>You hold [src] up to your eyes.</span>")
	item_state = "binoculars_wielded"
	user.regenerate_icons()
	var/datum/component/scope/scope = GetComponent(/datum/component/scope)
	scope?.zoom(user)

/obj/item/binoculars/proc/on_walk()
	attack_self(listeningTo)

/obj/item/binoculars/proc/on_unwield(obj/item/source, mob/user)
	unwield(user)

/obj/item/binoculars/proc/unwield(mob/user)
	if(!user)
		listeningTo = null
		return
	if(listeningTo)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		listeningTo = null
	user.visible_message("<span class='notice'>[user] lowers [src].</span>", "<span class='notice'>You lower [src].</span>")
	item_state = "binoculars"
	user.regenerate_icons()
	var/datum/component/scope/scope = GetComponent(/datum/component/scope)
	scope?.stop_zooming(user)

/obj/item/binoculars/strong
	name = "advanced binoculars"
	desc = "A high-grade pair of binoculars with reinforced titanium optics, granting significantly better magnification."
	scope_range = 6
