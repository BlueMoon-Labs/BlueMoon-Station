// Syndicate pAI

/datum/antagonist/syndicate_pai
	name = "Syndicate pAI"
	job_rank = ROLE_PAI
	show_to_ghosts = TRUE
	show_in_antagpanel = TRUE
	antag_hud_type = ANTAG_HUD_TRAITOR
	antag_hud_name = "traitor"
	soft_antag = TRUE

/datum/antagonist/syndicate_pai/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/M = owner?.current
	if(M)
		var/datum/atom_hud/antag/hud = GLOB.huds[antag_hud_type]
		if(hud)
			hud.join_hud(M)
			set_antag_hud(M, antag_hud_name)

/datum/antagonist/syndicate_pai/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/M = owner?.current
	if(M)
		var/datum/atom_hud/antag/hud = GLOB.huds[antag_hud_type]
		if(hud)
			hud.leave_hud(M)
			set_antag_hud(M, null)

/mob/living/silicon/pai/syndicate
	name = "Syndicate pAI"
	desc = "Мобильный голографический излучатель твёрдого света pAI Синдиката. Кажется, он деактивирован."
	var/chemical_injector_active = FALSE
	var/chemical_storage = 0
	var/chemical_max = 30
	var/chemical_regen_time = 0

/mob/living/silicon/pai/syndicate/Initialize(mapload)
	syndicate_model = TRUE
	chemical_injector_active = TRUE
	software = list("thermal vision", "chemical injector", "internal camera bug", "weakened ai capability")
	log_world("PAI_DEBUG: syndicate Initialize running mob=[src] type=[type]")
	. = ..()
	log_world("PAI_DEBUG: syndicate Initialize done cell=[cell?.type] cell_charge=[cell?.charge] radio=[radio?.type]")
	if(cell)
		QDEL_NULL(cell)
	cell = new /obj/item/stock_parts/cell/bluespace(src)
	cell.charge = cell.maxcharge
	if(radio)
		QDEL_NULL(radio)
	radio = new /obj/item/radio/headset/silicon/pai/syndicate(src)
	if(pda)
		pda.store_file(new /datum/computer_file/program/secureye())

/mob/living/silicon/pai/syndicate/proc/apply_syndicate_antag()
	if(!mind.has_antag_datum(/datum/antagonist/syndicate_pai))
		mind.special_role = ROLE_PAI
		mind.add_antag_datum(/datum/antagonist/syndicate_pai)

/mob/living/silicon/pai/syndicate/Login()
	log_world("PAI_DEBUG: syndicate Login mob=[src] type=[type] mind=[mind] mind?.current=[mind?.current]")
	. = ..()
	if(mind)
		log_world("PAI_DEBUG: syndicate applying antag")
		apply_syndicate_antag()
	else
		log_world("PAI_DEBUG: syndicate mind is null at Login, creating mind")
		mind_initialize()
		if(mind)
			apply_syndicate_antag()

/mob/living/silicon/pai/syndicate/mind_initialize()
	. = ..()

/mob/living/silicon/pai/syndicate/BiologicalLife(delta_time, times_fired)
	. = ..()
	if(!(.))
		return
	if(chemical_injector_active && chemical_storage < chemical_max)
		if(world.time >= chemical_regen_time)
			chemical_storage = min(chemical_storage + 5, chemical_max)
			chemical_regen_time = world.time + 15 SECONDS

/mob/living/silicon/pai/syndicate/proc/inject_chemicals()
	if(!use_power(300))
		to_chat(src, "<span class='warning'>Недостаточно энергии для инъекции.</span>")
		return
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
	var/list/available_reagents = list(/datum/reagent/medicine/kelotane, /datum/reagent/medicine/bicaridine, /datum/reagent/medicine/epinephrine, /datum/reagent/medicine/salbutamol, /datum/reagent/medicine/salglu_solution, /datum/reagent/medicine/mannitol, /datum/reagent/medicine/earthsblood)
	var/chosen = pick(available_reagents)
	carrier.reagents?.add_reagent(chosen, 5)
	chemical_storage -= 5
	to_chat(src, "<span class='notice'>Впрыснуто 5u [chosen] в [carrier]. Остаток: [chemical_storage]/[chemical_max]</span>")
	to_chat(carrier, "<span class='notice'>Что-то щёлкает, и вы чувствуете лёгкую укол...</span>")

/mob/living/silicon/pai/syndicate/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	switch(action)
		if("open_secureye")
			if(!pda)
				log_world("PAI_DEBUG: open_secureye - no pda")
				return TRUE
			var/datum/computer_file/program/secureye/SP = locate() in pda.get_all_files()
			log_world("PAI_DEBUG: open_secureye - locate=[SP] pda=[pda] file_count=[length(pda.get_all_files())]")
			if(!SP)
				SP = secureye_program
				log_world("PAI_DEBUG: open_secureye - using mob var=[SP]")
			if(!SP)
				log_world("PAI_DEBUG: open_secureye - no secureye found at all")
				return TRUE
			if(!use_power(100))
				temp = "Недостаточно энергии."
				return TRUE
			SP.computer = pda
			SP.run_program(src)
			pda.active_program = SP
			SP.ui_interact(src)
			return TRUE
	return FALSE

/mob/living/silicon/pai/syndicate/ui_data(mob/user)
	var/list/data = ..()
	data["syndicate_model"] = TRUE
	data["thermal_vision"] = thermal_vision_active
	data["chemical_injector"] = chemical_injector_active
	data["chemical_storage"] = chemical_storage
	data["chemical_max"] = chemical_max
	return data

/mob/living/silicon/pai/syndicate/Destroy()
	return ..()
