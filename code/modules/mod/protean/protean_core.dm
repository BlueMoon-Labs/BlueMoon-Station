/obj/item/mod/core/protean
	name = "MOD protean core"
	icon_state = "mod-core-ethereal"
	desc = "If you see this, go scream at a coder and tell them how you managed to do this."

	var/mob/living/carbon/human/linked_protean

/obj/item/mod/core/protean/Destroy(force)
	set_linked_protean(null)
	return ..()

/obj/item/mod/core/protean/proc/set_linked_protean(mob/living/carbon/human/human)
	if(linked_protean == human)
		return
	if(linked_protean)
		UnregisterSignal(linked_protean, COMSIG_PARENT_QDELETING)
	linked_protean = human
	if(human)
		RegisterSignal(human, COMSIG_PARENT_QDELETING, PROC_REF(on_protean_deleted))

/obj/item/mod/core/protean/proc/on_protean_deleted()
	SIGNAL_HANDLER
	set_linked_protean(null)
	if(QDELETED(mod))
		return
	var/obj/item/mod/control/pre_equipped/protean/suit = mod
	if(istype(suit))
		suit.retract_parts()
		suit.set_distress_signal(FALSE)
		return
	mod.finish_activation(FALSE)

/obj/item/mod/core/protean/charge_source()
	if(QDELETED(linked_protean))
		return
	return linked_protean.getorganslot(ORGAN_SLOT_STOMACH)

/obj/item/mod/core/protean/charge_amount()
	var/obj/item/organ/stomach/protean/stomach = charge_source()
	if(QDELETED(linked_protean) || linked_protean.stat == DEAD)
		return null
	var/obj/item/organ/brain/protean/brain = linked_protean.getorganslot(ORGAN_SLOT_BRAIN)
	if(!istype(stomach))
		return null
	if(!istype(brain) || brain.dead)
		return null
	return stomach.metal

/obj/item/mod/core/protean/max_charge_amount()
	return 10

/obj/item/mod/core/protean/add_charge(amount)
	return FALSE

/obj/item/mod/core/protean/subtract_charge(amount)
	return FALSE

/obj/item/mod/core/protean/check_charge(amount)
	var/obj/item/organ/stomach/protean/stomach = charge_source()
	if(QDELETED(linked_protean) || linked_protean.stat == DEAD)
		return FALSE
	var/obj/item/organ/brain/protean/brain = linked_protean.getorganslot(ORGAN_SLOT_BRAIN)
	if(!istype(stomach) || stomach.metal <= PROTEAN_STOMACH_FALTERING)
		return FALSE
	if(!istype(brain) || brain.dead)
		return FALSE
	return TRUE

