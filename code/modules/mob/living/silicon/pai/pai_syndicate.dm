// Syndicate pAI

/mob/living/silicon/pai/syndicate
	name = "Syndicate pAI"
	desc = "A Syndicate pAI mobile hard-light holographics emitter. It seems to be deactivated."
	software = list("thermal vision", "chemical injector")
	var/chemical_injector_active = FALSE
	var/chemical_storage = 0
	var/chemical_max = 30
	var/chemical_regen_time = 0

/mob/living/silicon/pai/syndicate/Initialize(mapload)
	. = ..()
	if(radio)
		QDEL_NULL(radio)
	radio = new /obj/item/radio/headset/silicon/pai/syndicate(src)
	if(pda)
		pda.store_file(new /datum/computer_file/program/secureye())

/mob/living/silicon/pai/syndicate/BiologicalLife(delta_time, times_fired)
	. = ..()
	if(!(.))
		return
	if(chemical_injector_active && chemical_storage < chemical_max)
		if(world.time >= chemical_regen_time)
			chemical_storage = min(chemical_storage + 5, chemical_max)
			chemical_regen_time = world.time + 15 SECONDS

/mob/living/silicon/pai/syndicate/proc/toggle_thermal_vision()
	thermal_vision_active = !thermal_vision_active
	if(thermal_vision_active)
		sight |= SEE_MOBS
		lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
		to_chat(src, "<span class='notice'>Термальное зрение активировано.</span>")
	else
		sight &= ~SEE_MOBS
		lighting_alpha = initial(lighting_alpha)
		to_chat(src, "<span class='notice'>Термальное зрение деактивировано.</span>")
	update_sight()

/mob/living/silicon/pai/syndicate/proc/inject_chemicals()
	if(!chemical_injector_active)
		to_chat(src, "<span class='warning'>Инъектор не активирован.</span>")
		return
	var/mob/living/carrier = null
	var/atom/current_loc = loc
	while(current_loc)
		if(isliving(current_loc))
			carrier = current_loc
			break
		current_loc = current_loc.loc
	if(!carrier)
		to_chat(src, "<span class='warning'>Носитель не обнаружен.</span>")
		return
	if(chemical_storage < 5)
		to_chat(src, "<span class='warning'>Недостаточно химикатов. Осталось: [chemical_storage]/[chemical_max] юнитов.</span>")
		return
	var/list/available_reagents = list("kelotane", "bicaridine", "epinephrine", "salbutamol", "glucose", "mannitol", "earthsblood")
	var/chosen = pick(available_reagents)
	carrier.reagents?.add_reagent(chosen, 5)
	chemical_storage -= 5
	to_chat(src, "<span class='notice'>Впрыснуто 5u [chosen] в [carrier]. Остаток: [chemical_storage]/[chemical_max]</span>")
	to_chat(carrier, "<span class='notice'>Что-то щёлкает, и вы чувствуете лёгкую укол...</span>")

/mob/living/silicon/pai/syndicate/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	switch(action)
		if("toggle_thermal_vision")
			toggle_thermal_vision()
			return TRUE
		if("inject_chemicals")
			inject_chemicals()
			return TRUE
		if("toggle_chemical_injector")
			chemical_injector_active = !chemical_injector_active
			if(chemical_injector_active)
				to_chat(src, "<span class='notice'>Инъектор химикатов активирован. Хранилище: [chemical_storage]/[chemical_max]</span>")
			else
				to_chat(src, "<span class='notice'>Инъектор химикатов деактивирован.</span>")
			return TRUE
	return FALSE

/mob/living/silicon/pai/syndicate/ui_data(mob/user)
	var/list/data = ..()
	data["thermal_vision"] = thermal_vision_active
	data["chemical_injector"] = chemical_injector_active
	data["chemical_storage"] = chemical_storage
	data["chemical_max"] = chemical_max
	return data

/mob/living/silicon/pai/syndicate/Destroy()
	return ..()
