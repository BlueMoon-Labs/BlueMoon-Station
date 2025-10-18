#define BLUE_EYES 1
#define RED_EYES 2
#define PURPLE_EYES 3
#define YELLOW_EYES 4
#define GREEN_EYES 5
#define ORANGE_EYES 6

#define DARK_ENERGY_BLOCK_SOURCE_SUIT "dark_stop_suit"

#define NUTRITION_ENERGY_CONVERSION (0 << 1)

/datum/component/shadekin

	var/mob/living/carbon/human/owner
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/flags = NUTRITION_ENERGY_CONVERSION

	var/dark_energy = 100
	var/max_dark_energy = 100

	var/dark_gain_in_dark = 0.75
	var/dark_gain_in_light = 0.25

	var/passive_heal_in_dark = 0.1

	var/nutrition_conversion_scaling = 0.5

	var/list/action_templates = list()



/datum/component/shadekin/Initialize(...)
	if(!isshadekin(parent) || !ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	owner = parent

/datum/component/shadekin/RegisterWithParent()
	RegisterSignal(owner, COMSIG_SHADEKIN_GEN_DARK_ENERGY, PROC_REF(get_energy))
	RegisterSignal(owner, COMSIG_ADJUST_DARK_ENERGY, PROC_REF(signal_use_energy))
	RegisterSignal(owner, COMSIG_LIVING_LIFE, PROC_REF(handle_life))
	RegisterSignal(owner, COMSIG_MOB_ITEM_EQUIPPED, PROC_REF(equip_item_reaction))
	RegisterSignal(owner, COMSIG_MOB_ITEM_DROPPED, PROC_REF(unequip_item_reaction))


/datum/component/shadekin/UnregisterFromParent()
	UnregisterSignal(owner, list(
		COMSIG_SHADEKIN_GEN_DARK_ENERGY,
		COMSIG_ADJUST_DARK_ENERGY,
		COMSIG_LIVING_LIFE,
		COMSIG_MOB_ITEM_EQUIPPED,
		COMSIG_MOB_ITEM_DROPPED
	))

/datum/component/shadekin/proc/set_shadekin_eyecolor()

	var/mob/living/carbon/human/H = owner
	var/eyecolor_rgb = BlendRGB(owner.left_eye_color, owner.right_eye_color, 0.5)

	var/list/hsv_color = rgb2num(eyecolor_rgb, COLORSPACE_HSV)
	var/eyecolor_hue = hsv_color[1]
	var/eyecolor_sat = hsv_color[2]
	var/eyecolor_val = hsv_color[3]

	//First, clamp the saturation/value to prevent black/grey/white eyes
	if(eyecolor_sat < 10)
		eyecolor_sat = 10
	if(eyecolor_val < 40)
		eyecolor_val = 40

	eyecolor_rgb = rgb(eyecolor_hue, eyecolor_sat, eyecolor_val, space=COLORSPACE_HSV)

	owner.left_eye_color = eyecolor_rgb
	owner.right_eye_color = eyecolor_rgb
	owner.update_body()
	
	var/eye_color
	//Now determine what color we fall into.
	switch(eyecolor_hue)
		if(0 to 20)
			eye_color = RED_EYES
		if(21 to 50)
			eye_color = ORANGE_EYES
		if(51 to 70)
			eye_color = YELLOW_EYES
		if(71 to 160)
			eye_color = GREEN_EYES
		if(161 to 260)
			eye_color = BLUE_EYES
		if(261 to 340)
			eye_color = PURPLE_EYES
		if(341 to 360)
			eye_color = RED_EYES
	return eye_color


/datum/component/shadekin/proc/get_energy(datum/source)
	SIGNAL_HANDLER
	return dark_energy

/datum/component/shadekin/proc/use_energy(amount)
	var/temp = dark_energy - amount
	if(temp < 0)
		return FALSE
	dark_energy = temp
	SEND_SIGNAL(owner, COMSIG_INFORM_NEW_ENERGY_LEVEL, dark_energy)
	return TRUE

/datum/component/shadekin/proc/signal_use_energy(datum/source, amount)
	SIGNAL_HANDLER
	return use_energy(amount)

/datum/component/shadekin/proc/append_actions_from_templates(list/actions_path)
	for(var/template in action_templates)
		var/datum/action/shadekin/temp = new template(owner)
		temp.Grant(owner)

/datum/component/shadekin/proc/check_is_dark()
	var/turf/T = get_turf(owner)
	var/darkness = 1
	if(!T)
		return FALSE

	var/brightness = T.get_lumcount()
	darkness = 1-brightness
	if(darkness >= 0.5)
		return darkness
	return FALSE

/datum/component/shadekin/proc/equip_item_reaction(datum/source, obj/item/W, slot)
	if((slot == ITEM_SLOT_SUITSTORE) && (!HAS_TRAIT_FROM(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)) && istype(W, /obj/item/clothing/suit))
		to_chat(owner, span_warning("Вы чувствуете, что ваша энергия иссякает, а тяжелое снаряжение, которое вы носите, блокирует ваши силы!"))
		ADD_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)
		use_energy(dark_energy)
		return

/datum/component/shadekin/proc/unequip_item_reaction(datum/source, obj/item/W, slot)
	if(((slot == ITEM_SLOT_SUITSTORE) && (HAS_TRAIT_FROM(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT))) && istype(W, /obj/item/clothing/suit))
		REMOVE_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)
		return

/datum/component/shadekin/proc/energy_gain(dark_level)

/datum/component/shadekin/proc/nutriment_dark_gauns_modifer(energy_to_add)
	if(!(flags & NUTRITION_ENERGY_CONVERSION))
		return energy_to_add
	if(shadekin_get_energy() == 100 && energy_to_add > 0)
		owner.nutrition += energy_to_add * 5 * nutrition_conversion_scaling
	else if(shadekin_get_energy() < 50 && owner.nutrition > 500)
		owner.nutrition -= nutrition_conversion_scaling * 50
		energy_to_add += nutrition_conversion_scaling
	
	return energy_to_add

/datum/component/shadekin/proc/passive_dark_heal(dark_level)
	owner.adjustFireLoss((-0.10)*dark_level)
	owner.adjustBruteLoss((-0.10)*dark_level)
	owner.adjustToxLoss((-0.10)*dark_level)

/datum/component/shadekin/proc/handle_life(...)
	SIGNAL_HANDLER

	if(QDELETED(parent))
		return
	if(owner.stat == DEAD)
		return
	if(HAS_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED))
		return

	var/energy_to_add = 0
	var/dark_level = check_is_dark()

	if(!HAS_TRAIT(owner, TRAIT_IN_PHASE_SHIFT))
		energy_to_add = dark_level ? dark_gain_in_dark : dark_gain_in_light
	energy_gain(dark_level)

	passive_dark_heal(dark_level)
