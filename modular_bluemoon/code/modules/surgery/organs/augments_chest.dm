#define HEALER_IMPLANT_HEAL_AMOUNT 0.4

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

/obj/item/organ/cyberimp/chest/nutrimentextreme/on_life(seconds, times_fired)	// Check if this user can process thrist/hunger at all. Yes this is a total mess, but works fine, doesn't cause any runtimes.
	. = ..()
	if(!. || HAS_TRAIT(owner, TRAIT_NO_PROCESS_FOOD))
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
	name = "Broken Healer implant"
	desc = "Implant is broken and useless."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "healerbrute"
	slot = ORGAN_SLOT_HEART_AID
	var/brute_heal = 0
	var/fire_heal = 0
	var/tox_heal = 0
	var/oxy_heal = 0

/obj/item/organ/cyberimp/chest/healer/on_life()
	. = ..()
	if(!.)
		return
	heal(FALSE)

#define HEAL_FORMULA(amount) round((kill ? amount : -amount)*multiplier, 0.1)

/obj/item/organ/cyberimp/chest/healer/proc/heal(kill = FALSE, multiplier = 1)
	if(brute_heal)
		owner.adjustBruteLoss(HEAL_FORMULA(brute_heal), FALSE)
	if(fire_heal)
		owner.adjustFireLoss(HEAL_FORMULA(fire_heal), FALSE)
	if(tox_heal)
		owner.adjustToxLoss(HEAL_FORMULA(tox_heal), FALSE, TRUE) // don't kill slimes
	if(oxy_heal)
		owner.adjustOxyLoss(HEAL_FORMULA(oxy_heal), FALSE)

#undef HEAL_FORMULA

/obj/item/organ/cyberimp/chest/healer/emp_act(severity)
	. = ..()
	if(!owner || (. & EMP_PROTECT_SELF))
		return
	to_chat(owner, span_warning("Вы чувствуете жжение от [src] в вашей груди!"))
	heal(TRUE, severity*0.2)

/obj/item/organ/cyberimp/chest/healer/bruteburn
	name = "Healer-BB implant"
	desc = "This implant will slowly mend localized damage that it can find. This version mends only brute and fire injures!"
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "healerbrute"
	brute_heal = HEALER_IMPLANT_HEAL_AMOUNT
	fire_heal = HEALER_IMPLANT_HEAL_AMOUNT

/obj/item/organ/cyberimp/chest/healer/toxoxy
	name = "Healer-TO implant"
	desc = "This implant will slowly mend localized damage that it can find. This version filters out toxins, as well as considers any lack of oxygen in the bloodstream!"
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "healertox"
	slot = ORGAN_SLOT_HEART_AID
	tox_heal = HEALER_IMPLANT_HEAL_AMOUNT
	oxy_heal = HEALER_IMPLANT_HEAL_AMOUNT

//Ultimate version of healer
/obj/item/organ/cyberimp/chest/healer/revitilzer
	name = "Revitalizing Cortex"
	desc = "This attachable to the torso cortex optimizes the body's processes in order to preserve the body. Provides overall basic mending."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "revitilizer"
	slot = ORGAN_SLOT_HEART_AID
	brute_heal = HEALER_IMPLANT_HEAL_AMOUNT
	fire_heal = HEALER_IMPLANT_HEAL_AMOUNT
	tox_heal = HEALER_IMPLANT_HEAL_AMOUNT
	oxy_heal = HEALER_IMPLANT_HEAL_AMOUNT

#undef HEALER_IMPLANT_HEAL_AMOUNT
