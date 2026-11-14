/obj/item/mod/control/pre_equipped/protean/canStrip(mob/stripper, mob/owner)
	return TRUE

/obj/item/mod/control/pre_equipped/protean/doStrip(mob/living/stripper, mob/owner)
	if(owner != get_protean())
		REMOVE_TRAIT(src, TRAIT_NODROP, PROTEAN_TRAIT)
		return ..()
	var/datum/component/storage/storage = GetComponent(/datum/component/storage)
	storage?.do_quick_empty(drop_location())
	return TRUE

/datum/element/strippable/protean/Attach(datum/target, list/items, should_strip_proc_path)
	. = ..()
	RegisterSignal(target, COMSIG_CLICK_CTRL_SHIFT, PROC_REF(open_protean))

/datum/element/strippable/protean/Detach(datum/source)
	UnregisterSignal(source, COMSIG_CLICK_CTRL_SHIFT)
	return ..()

/datum/element/strippable/protean/proc/open_protean(obj/item/mod/control/pre_equipped/protean/suit, mob/living/user)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/human = suit.get_protean()
	if(!human || human.loc != suit || human == user || !user.Adjacent(suit) || user.incapacitated())
		return
	if(!user.can_hold_items() && !HAS_TRAIT(user, TRAIT_CAN_STRIP))
		return
	var/datum/strip_menu/protean/menu = LAZYACCESS(strip_menus, suit)
	if(!menu)
		menu = new(human, src)
		LAZYSET(strip_menus, suit, menu)
	INVOKE_ASYNC(menu, TYPE_PROC_REF(/datum, ui_interact), user)

/datum/strip_menu/protean/ui_status(mob/user, datum/ui_state/state)
	var/mob/living/carbon/human/human = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	if(!suit || human.loc != suit || !user.Adjacent(suit))
		return UI_CLOSE
	if(IsAdminGhost(user))
		return UI_INTERACTIVE
	if(!isliving(user) || user.incapacitated() || (!user.can_hold_items() && !HAS_TRAIT(user, TRAIT_CAN_STRIP)))
		return UI_UPDATE
	return UI_INTERACTIVE

/datum/controller/subsystem/job/proc/store_protean_loadout(mob/living/carbon/human/human, obj/item/item, slot)
	if(slot != ITEM_SLOT_BACK || !isprotean(human))
		return FALSE
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	if(QDELETED(suit) || human.back != suit || item == suit)
		return FALSE
	if(!SEND_SIGNAL(suit, COMSIG_TRY_STORAGE_INSERT, item, null, TRUE, TRUE))
		item.forceMove(suit)
	return TRUE

/datum/species/protean/proc/prepare_outfit(mob/living/carbon/human/human)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	suit?.drop_suit()
	return suit

/datum/species/protean/proc/finish_outfit(mob/living/carbon/human/human, obj/item/mod/control/pre_equipped/protean/suit)
	if(QDELETED(suit) || human.dna.species != src)
		return
	var/obj/item/backpack = human.back
	var/list/saved_contents = backpack?.contents.Copy()
	for(var/atom/movable/item in saved_contents)
		item.moveToNullspace()
	var/obj/item/mod/control/job_suit = istype(backpack, /obj/item/mod/control) ? backpack : null
	if(job_suit)
		job_suit.finish_activation(FALSE)
		for(var/obj/item/clothing/mod_part/part in job_suit.get_mod_parts(include_cell = FALSE))
			if(part.loc == human)
				job_suit.conceal(human, part, TRUE)
	if(backpack)
		human.temporarilyRemoveItemFromInventory(backpack, force = TRUE)
	equip_modsuit(human)
	ADD_TRAIT(suit, TRAIT_NODROP, PROTEAN_TRAIT)
	if(job_suit)
		job_suit.forceMove(human)
		suit.assimilate_modsuit(human, job_suit, TRUE)
	else if(backpack)
		qdel(backpack)
	for(var/atom/movable/item in saved_contents)
		item.forceMove(suit)

/mob/living/carbon/human/protean/empty/Initialize(mapload)
	. = ..()
	qdel(getorganslot(ORGAN_SLOT_HEART))
	qdel(getorganslot(ORGAN_SLOT_BRAIN))
	adjustBruteLoss(250, forced = TRUE, only_organic = FALSE)

/datum/supply_pack/science/protean_organs
	name = "Protean Organs"
	desc = "Two refactories and two orchestrator modules for Protean crewmembers."
	contains = list(/obj/item/organ/stomach/protean, /obj/item/organ/stomach/protean, /obj/item/organ/heart/protean, /obj/item/organ/heart/protean)
	crate_name = "protean organs"
	access = ACCESS_ROBOTICS
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/protean_vessel
	name = "Protean Vessel"
	desc = "A blank Protean body ready to receive a core and an orchestrator module."
	cost = CARGO_CRATE_VALUE * 5
	contains = list(/mob/living/carbon/human/protean/empty)
	crate_name = "protean vessel"
	access = ACCESS_ROBOTICS
	crate_type = /obj/structure/closet/crate/secure/science
