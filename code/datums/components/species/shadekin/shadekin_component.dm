#define BLUE_EYES 1
#define RED_EYES 2
#define PURPLE_EYES 3
#define YELLOW_EYES 4
#define GREEN_EYES 5
#define ORANGE_EYES 6

#define DARK_ENERGY_BLOCK_SOURCE_SUIT "dark_stop_suit"

/datum/component/shadekin

	var/mob/owner
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/dark_energy = 100
	var/max_dark_energy = 100

	var/dark_gain_in_dark = 0.75
	var/dark_gain_in_light = 0.25

	var/passive_heal_in_dark = 0.1

	var/nutrition_conversion_scaling = 0.5

	var/list/action_templates = list()



/datum/component/shadekin/Initialize(...)
	if(!isshadekin(parent) || !ismob(parent))
		return COMPONENT_INCOMPATIBLE
	owner = parent

/datum/component/shadekin/RegisterWithParent()
	RegisterSignal(owner, COMSIG_SHADEKIN_GEN_DARK_ENERGY, PROC_REF(get_energy))
	RegisterSignal(owner, COMSIG_ADJUST_DARK_ENERGY, PROC_REF(signal_use_energy))
	RegisterSignal(owner, COMSIG_LIVING_LIFE, PROC_REF(handle_life))
	RegisterSignal(owner, COMSIG_MOB_ITEM_EQUIPPED, PROC_REF(equip_item_reaction))


/datum/component/shadekin/UnregisterFromParent()
	UnregisterSignal(owner, list(
		COMSIG_SHADEKIN_GEN_DARK_ENERGY,
		COMSIG_ADJUST_DARK_ENERGY,
		COMSIG_LIVING_LIFE,
		COMSIG_MOB_ITEM_EQUIPPED
	))

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
	if((slot == ITEM_SLOT_SUITSTORE) && (HAS_TRAIT_FROM(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)) && istype(W, /obj/item/clothing/suit))
	  	REMOVE_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED, DARK_ENERGY_BLOCK_SOURCE_SUIT)
		return

/datum/component/shadekin/proc/energy_gain()


/datum/component/shadekin/proc/passive_dark_heal(dark_level)
	owner.adjustFireLoss((-0.10)*dark_level)
	owner.adjustBruteLoss((-0.10)*dark_level)
	owner.adjustToxLoss((-0.10)*dark_level)

/datum/component/shadekin/proc/handle_life(...)
	SIGNAL_HANDLER
	var/energy_to_add = 0
	var/dark_level = check_is_dark()

	if(HAS_TRAIT(owner, TRAIT_IN_PHASE_SHIFT) || HAS_TRAIT(owner, TRAIT_DARK_ENERGY_BLOCKED))
		return

	passive_dark_heal(dark_level)


#define COMSIG_MOB_ITEM_EQUIPPED "mob_item_equipped"
#define COMSIG_MOB_ITEM_DROPPING "mob_item_dropping"
#define COMSIG_MOB_ITEM_DROPPED "mob_item_dropped"

