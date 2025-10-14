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

	var/list/datum/action/shadekin/action_templates = list()



/datum/component/shadekin/Initialize(...)
	if(!isshadekin(parent) || !ismob(parent))
		return COMPONENT_INCOMPATIBLE
	owner = parent

/datum/component/shadekin/proc/use_energy(amount)
	var/temp = min(dark_energy, amount)
	if(temp < 0)
		return FALSE
	dark_energy -= temp
	return TRUE

/datum/component/shadekin/proc/signal_use_energy(datum/source, amount)
	SIGNAL_HANDLER
	return use_energy(amount)

/datum/component/shadekin/proc/append_actions_from_templates(list/actions_path)
	for(var/datum/action/shadekin/template in action_templates)
		template = new()
		template.Grant(owner)


