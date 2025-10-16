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

	var/dark_energy = 0
	var/dark_energy_regen = 0

	var/list/action_templates = list()



/datum/component/shadekin/Initialize(...)
	if(!isshadekin(parent) || !ismob(parent))
		return COMPONENT_INCOMPATIBLE
	owner = parent

/datum/component/shadekin/RegisterWithParent()
	RegisterSignal(owner, COMSIG_SHADEKIN_GEN_DARK_ENERGY, PROC_REF(get_energy))
	RegisterSignal(owner, COMSIG_ADJUST_DARK_ENERGY, PROC_REF(signal_use_energy))
	RegisterSignal(owner, COMSIG_LIVING_LIFE, PROC_REF(handle_life))


/datum/component/shadekin/UnregisterFromParent()
	UnregisterSignal(owner, list(
		COMSIG_SHADEKIN_GEN_DARK_ENERGY,
		COMSIG_ADJUST_DARK_ENERGY,
		COMSIG_LIVING_LIFE
	))

/datum/component/shadekin/proc/use_energy(amount)
	var/temp = dark_energy - amount
	if(temp < 0)
		return FALSE
	dark_energy = temp
	SEND_SIGNAL(owner, COMSIG_INFORM_NEW_ENERGY_LEVEL, dark_energy)
	return TRUE


/datum/component/shadekin/proc/get_energy(datum/soruce)
	SIGNAL_HANDLER
	return dark_energy

/datum/component/shadekin/proc/signal_use_energy(datum/source, amount)
	SIGNAL_HANDLER
	return use_energy(amount)

/datum/component/shadekin/proc/append_actions_from_templates(list/actions_path)
	for(var/template in action_templates)
		var/datum/action/shadekin/temp = new template(owner)
		temp.Grant(owner)

/datum/component/shadekin/proc/check_in_dark()
	var/turf/T = get_turf(owner)
	var/darkness = 1
	if(!T)
		return FALSE

	var/brightness = T.get_lumcount()
	darkness = 1-brightness
	return darkness >= 0.5

/datum/component/shadekin/proc/equip_item_reaction(datum/source, obj/item/W, slot)

/datum/component/shadekin/proc/unequip_item_reaction(datum/source, obj/item/W, slot)


/datum/component/shadekin/proc/energy_gain()

/datum/component/shadekin/proc/warn_suit(datum/source, obj/item/W, slot)
	SIGNAL_HANDLER
	if(slot != ITEM_SLOT_SUITSTORE || !istype(W, /obj/item/clothing/suit/space))
		return
	to_chat(owner, span_warning("Скафандр блокирует ваши способности!"))

/datum/component/shadekin/proc/handle_life(...)
	SIGNAL_HANDLER
	var/energy_to_add = 0
	var/in_dark = check_in_dark()

	if(HAS_TRAIT(owner, TRAIT_IN_PHASE_SHIFT))
		return
	owner.get_eq
