#define BLUE_EYES 1
#define RED_EYES 2
#define PURPLE_EYES 3
#define YELLOW_EYES 4
#define GREEN_EYES 5
#define ORANGE_EYES 6

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



/datum/component/shadekin/proc/handle_life(...)
	SIGNAL_HANDLER

