/datum/asset/spritesheet/sheetmaterials
	name = "sheetmaterials"

/datum/asset/spritesheet/sheetmaterials/register()
	// Insert polycrystal from telescience first so it won't be duplicated when stacking from stack_objects.dmi
	Insert("polycrystal", 'icons/obj/telescience.dmi', "polycrystal")
	for (var/icon_state_name in icon_states('icons/obj/stack_objects.dmi'))
		if (icon_state_name == "polycrystal")
			continue
		Insert(icon_state_name, 'icons/obj/stack_objects.dmi', icon_state_name)
	..()
