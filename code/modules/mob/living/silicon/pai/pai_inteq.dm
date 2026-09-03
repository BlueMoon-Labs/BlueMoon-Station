// InteQ pAI

/datum/antagonist/inteq_pai
	name = "InteQ pAI"
	job_rank = ROLE_PAI
	show_to_ghosts = TRUE
	show_in_antagpanel = TRUE
	antag_hud_type = ANTAG_HUD_TRAITOR
	antag_hud_name = "traitor"
	soft_antag = TRUE

/datum/antagonist/inteq_pai/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/M = owner?.current
	if(M)
		var/datum/atom_hud/antag/hud = GLOB.huds[antag_hud_type]
		if(hud)
			hud.join_hud(M)
			set_antag_hud(M, antag_hud_name)

/datum/antagonist/inteq_pai/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/M = owner?.current
	if(M)
		var/datum/atom_hud/antag/hud = GLOB.huds[antag_hud_type]
		if(hud)
			hud.leave_hud(M)
			set_antag_hud(M, null)

/mob/living/silicon/pai/inteq
	name = "InteQ pAI"
	desc = "Мобильный голографический излучатель твёрдого света pAI InteQ. Кажется, он деактивирован."
	var/chemical_injector_active = FALSE
	var/chemical_storage = 0
	var/chemical_max = 30
	var/chemical_regen_time = 0

/mob/living/silicon/pai/inteq/Initialize(mapload)
	inteq_model = TRUE
	chemical_injector_active = TRUE
	software = list("thermal vision", "chemical injector", "internal camera bug", "weakened ai capability")
	log_world("PAI_DEBUG: inteq Initialize running mob=[src] type=[type]")
	. = ..()
	log_world("PAI_DEBUG: inteq Initialize done cell=[cell?.type] cell_charge=[cell?.charge] radio=[radio?.type]")
	if(cell)
		QDEL_NULL(cell)
	cell = new /obj/item/stock_parts/cell/bluespace(src)
	cell.charge = cell.maxcharge
	if(radio)
		QDEL_NULL(radio)
	radio = new /obj/item/radio/headset/silicon/pai/inteq(src)
	if(pda)
		pda.store_file(new /datum/computer_file/program/secureye())

/mob/living/silicon/pai/inteq/proc/apply_inteq_antag()
	if(!mind.has_antag_datum(/datum/antagonist/inteq_pai))
		mind.special_role = ROLE_PAI
		mind.add_antag_datum(/datum/antagonist/inteq_pai)

/mob/living/silicon/pai/inteq/Login()
	log_world("PAI_DEBUG: inteq Login mob=[src] type=[type] mind=[mind] mind?.current=[mind?.current]")
	. = ..()
	if(mind)
		log_world("PAI_DEBUG: inteq applying antag")
		apply_inteq_antag()
	else
		log_world("PAI_DEBUG: inteq mind is null at Login, creating mind")
		mind_initialize()
		if(mind)
			apply_inteq_antag()

/mob/living/silicon/pai/inteq/mind_initialize()
	. = ..()

/mob/living/silicon/pai/inteq/BiologicalLife(delta_time, times_fired)
	. = ..()
	if(!(.))
		return
	if(chemical_injector_active && chemical_storage < chemical_max)
		if(world.time >= chemical_regen_time)
			chemical_storage = min(chemical_storage + 5, chemical_max)
			chemical_regen_time = world.time + 15 SECONDS

/mob/living/silicon/pai/inteq/proc/inject_chemicals(reagent_key)
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
	var/static/list/reagent_map = list(
		"kelotane" = /datum/reagent/medicine/kelotane,
		"bicaridine" = /datum/reagent/medicine/bicaridine,
		"epinephrine" = /datum/reagent/medicine/epinephrine,
		"salbutamol" = /datum/reagent/medicine/salbutamol,
		"salglu_solution" = /datum/reagent/medicine/salglu_solution,
		"mannitol" = /datum/reagent/medicine/mannitol,
		"earthsblood" = /datum/reagent/medicine/earthsblood,
	)
	var/reagent_type = reagent_map[reagent_key]
	if(!reagent_type)
		to_chat(src, "<span class='warning'>Неизвестный реагент.</span>")
		return
	var/static/list/reagent_names = list(
		"kelotane" = "Келотан",
		"bicaridine" = "Бикаридин",
		"epinephrine" = "Эпинефрин",
		"salbutamol" = "Сальбутамол",
		"salglu_solution" = "Сальглю",
		"mannitol" = "Маннитол",
		"earthsblood" = "Земляная кровь",
	)
	var/reagent_cost = (reagent_type == /datum/reagent/medicine/earthsblood) ? 30 : 5
	if(chemical_storage < reagent_cost)
		to_chat(src, "<span class='warning'>Недостаточно химикатов. Нужно: [reagent_cost], осталось: [chemical_storage]/[chemical_max] юнитов.</span>")
		return
	carrier.reagents?.add_reagent(reagent_type, 5)
	chemical_storage -= reagent_cost
	to_chat(src, "<span class='notice'>Впрыснуто 5u [reagent_names[reagent_key]] в [carrier]. Остаток: [chemical_storage]/[chemical_max]</span>")
	to_chat(carrier, "<span class='notice'>Что-то щёлкает, и вы чувствуете лёгкий укол...</span>")
	return FALSE

/mob/living/silicon/pai/inteq/ui_data(mob/user)
	var/list/data = ..()
	data["inteq_model"] = TRUE
	data["thermal_vision"] = thermal_vision_active
	data["chemical_injector"] = chemical_injector_active
	data["chemical_storage"] = chemical_storage
	data["chemical_max"] = chemical_max
	data["chemical_reagents"] = list(
		list("id" = "kelotane", "name" = "Келотан (ожоги)", "cost" = 5),
		list("id" = "bicaridine", "name" = "Бикаридин (ушибы)", "cost" = 5),
		list("id" = "epinephrine", "name" = "Эпинефрин (критическое состояние)", "cost" = 5),
		list("id" = "salbutamol", "name" = "Сальбутамол (кислород)", "cost" = 5),
		list("id" = "salglu_solution", "name" = "Глюкоза (кровь)", "cost" = 5),
		list("id" = "mannitol", "name" = "Маннитол (мозг)", "cost" = 5),
		list("id" = "earthsblood", "name" = "Земляная кровь", "cost" = 30),
	)
	return data

/mob/living/silicon/pai/inteq/Destroy()
	return ..()
