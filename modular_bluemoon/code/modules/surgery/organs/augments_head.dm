//General idea: set of chips that go into brain and give jobtraits. For a time being sprites will be of head implants, but recoloured.
/obj/item/organ/cyberimp/brainchip //replica of cyberimp/brain since you can add more. I will also give it some good sprite later on.
	name = "cybernetic brain chip"
	desc = "Additional memory banks for humanoid creatures to enforce additional learning capabilities."
	icon_state = "brain_implant"
	implant_overlay = "brain_implant_overlay"
	slot = ORGAN_SLOT_BRAIN_ROBOT_RADSHIELDING //The reason for this is simple: They can provide really good benefits, so only one at a time.
	zone = BODY_ZONE_HEAD
	w_class = WEIGHT_CLASS_TINY
	var/list/traits_list = list()
	var/active = FALSE

/obj/item/organ/cyberimp/brainchip/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!.)
		return
	code_activate()

/obj/item/organ/cyberimp/brainchip/code_activate()
	. = ..()
	if(active || !LAZYLEN(traits_list) || !owner.mind)
		return
	for(var/trait in traits_list)
		ADD_TRAIT(owner.mind, trait, TRAIT_GENERIC)
	to_chat(owner, "Вы чувствуете, как [src] активируется и загружает в ваш мозг новые знания.")
	active = !active

/obj/item/organ/cyberimp/brainchip/deactivate(removing)
	. = ..()
	if(!active || !LAZYLEN(traits_list) || !owner.mind)
		return
	for(var/trait in traits_list)
		REMOVE_TRAIT(owner.mind, trait, TRAIT_GENERIC)
	if(!removing)
		to_chat(owner, "Вы чувствуете, как [src] отключается, а знания пропадают.")
	active = !active

/obj/item/organ/cyberimp/brainchip/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(0.6*severity))
		to_chat(owner, "<span class='warning'>You feel a bewitching scratches inside your brain!</span>")
		owner.losebreath += 15 //This is an experimental tech, not EMP-proof enough.

//Medical chip. Provides SURGERY_T2/QUICK_CARRY/REAGENT_EXPERT
/obj/item/organ/cyberimp/brainchip/medical
	name = "Advanced medical data chip"
	desc = "Special implant that was designed to help field operators with medical care for their fallen brethren. Allows advanced surgical procedures outside of the sterile conditions."
	implant_color = "#05dbeb" //Should be light-blue, since medical and stuff.
	traits_list = list(TRAIT_KNOW_MED_SURGERY_T2, TRAIT_QUICK_CARRY, TRAIT_REAGENT_EXPERT)

//Engin-ie chip. Provides TRAIT_KNOW_ENGI_WIRES.
/obj/item/organ/cyberimp/brainchip/engi
	name = "Advanced electrical data chip"
	desc = "Special implant that was designed to provide a quick learning for field engineers and inadept electricians."
	implant_color = "#eb9e05" //Should be orange-yellow, just like supermatter, or radioactive piss.
	traits_list = list(TRAIT_KNOW_ENGI_WIRES)

//Robotic chip. Provides TRAIT_KNOW_CYBORG_WIRES.
/obj/item/organ/cyberimp/brainchip/robotic
	name = "Advanced robotical data chip"
	desc = "Special implant that was designed to provide a quick learning for inadept roboticians and on-field crew."
	implant_color = "#463d82" //Should be purple-ish, just like RnD.
	traits_list = list(TRAIT_KNOW_CYBORG_WIRES)
