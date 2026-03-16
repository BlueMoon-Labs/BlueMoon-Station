/obj/item/organ/internal/cyberimp/chest/scanner //Ported from skyrat
	name = "internal health analyzer"
	desc = "An advanced health analyzer implant, designed to directly interface with a host's body and relay scan information to the brain on command."
	slot = ORGAN_SLOT_ANALYZER
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "internal_HA"
	actions_types = list(/datum/action/item_action/organ_action/use)
	w_class = WEIGHT_CLASS_SMALL

/obj/item/organ/internal/cyberimp/chest/scanner/ui_action_click(owner, action)
	if(istype(action, /datum/action/item_action/organ_action/use))
		if(organ_flags & ORGAN_FAILING)
			to_chat(owner, span_warning("Your health analyzer relays an error! It can't interface with your body in its current condition!"))
			return
		else
			healthscan(owner, owner, 1, TRUE)
			chemscan(owner, owner)

//Custom Content. New N-pump, and 3 'rehealer' augments
/obj/item/organ/cyberimp/chest/nutrimentextreme
	name = "Nutriment pump implant EXTREME"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are hungry. This version of the pump also provides a proper water supply."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "pumpextreme"
	slot = ORGAN_SLOT_STOMACH_AID
	var/poison_amount = 5
	var/thrist_threshold = THIRST_LEVEL_BIT_THIRSTY
	var/hunger_threshold = NUTRITION_LEVEL_HUNGRY

/obj/item/organ/cyberimp/chest/nutrimentextreme/on_life()	// Check if this user can process thrist/hunger at all. Yes this is a total mess, but works fine, doesn't cause any runtimes.
	if(HAS_TRAIT(owner, TRAIT_NO_PROCESS_FOOD))
		return

	if(owner.thirst <= thrist_threshold)
		to_chat(owner, "<span class='notice'>You feel less thirsty...</span>")
		owner.adjust_thirst(owner.thirst, THIRST_LEVEL_VERY_QUENCHED)

	if(owner.nutrition <= hunger_threshold)
		to_chat(owner, "<span class='notice'>You feel less hungry...</span>")
		owner.adjust_nutrition(owner.nutrition, NUTRITION_LEVEL_FULL)

/obj/item/organ/cyberimp/chest/nutrimentextreme/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	owner.reagents.add_reagent(/datum/reagent/toxin/bad_food, poison_amount * severity/100)
	to_chat(owner, "<span class='warning'>You feel like your insides are burning.</span>")

/obj/item/organ/cyberimp/chest/healer
	name = "Healer-BB implant"
	desc = "This implant will slowly mend localized damage that it can find. This version mends only brute and fire injures!"
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "healerbrute"
	slot = ORGAN_SLOT_HEART_AID

/obj/item/organ/cyberimp/chest/healer/on_life()
	owner.adjustBruteLoss(-0.4, FALSE) //Provides slow heal for both brute and burn damage.
	owner.adjustFireLoss(-0.4, FALSE)

/obj/item/organ/cyberimp/chest/healer/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(0.6*severity))
		to_chat(owner, "<span class='warning'>Your breathing suddenly collapses!</span>")
		owner.losebreath += 8

/obj/item/organ/cyberimp/chest/healertoxoxy
	name = "Healer-TO implant"
	desc = "This implant will slowly mend localized damage that it can find. This version filters out toxins, as well as considers any lack of oxygen in the bloodstream!"
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "healertox"
	slot = ORGAN_SLOT_HEART_AID

/obj/item/organ/cyberimp/chest/healertoxoxy/on_life()
	owner.adjustToxLoss(-0.4, FALSE) //Provides slow heal for toxin and oxy damage
	owner.adjustOxyLoss(-0.4, FALSE)

/obj/item/organ/cyberimp/chest/healertoxoxy/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(0.6*severity))
		to_chat(owner, "<span class='warning'>Your breathing suddenly collapses!</span>")
		owner.losebreath += 8

//Ultimate version of healer
/obj/item/organ/cyberimp/chest/revitilzer
	name = "Revitalizing Cortex"
	desc = "This attachable to the torso cortex optimizes the body's processes in order to preserve the body. Provides overall basic mending."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "revitilizer"
	slot = ORGAN_SLOT_HEART_AID

/obj/item/organ/cyberimp/chest/revitilzer/on_life()
	owner.adjustToxLoss(-0.4, TRUE) //Provides *very* slow heal to all basic damage. Buffed due to being basically useless against other versions
	owner.adjustOxyLoss(-0.4, FALSE)
	owner.adjustBruteLoss(-0.4, FALSE)
	owner.adjustFireLoss(-0.4, FALSE)

/obj/item/organ/cyberimp/chest/revitilzer/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(0.6*severity))
		to_chat(owner, "<span class='warning'>Your breathing suddenly collapses!</span>")
		owner.losebreath += 8
