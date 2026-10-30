/area/antag_training/sector/robotics
	name = "Training Robotics Sector"

/datum/antag_training_sector/robotics
	id = "robotics"
	name = "Робототехника"
	desc = "Мастерская «Механикус»: экзофабрикатор с материалами, стеллажи деталей, рамы киборга, «Одиссей» на стапеле и шасси Рипли, зарядная станция, мех-бей и обгорелый испытательный бокс. Мозг для киборга - из учебной цели."
	map_path = "_maps/templates/antag_training/robotics.dmm"
	area_type = /area/antag_training/sector/robotics
	origin_x = 161
	origin_y = 1
	spawn_offset = list(2, 15)
	target_offset = list(21, 24)

/obj/item/robot_suit/prebuilt/training
	name = "training cyborg endoskeleton"
	desc = "Учебный эндоскелет киборга. Собранный на нём киборг не подключается к ИИ станции, не синхронизирует законы и не виден станционным камерам. Вставьте MMI с мозгом учебной цели."
	cyborg_type = /mob/living/silicon/robot/training
	lawsync = FALSE
	aisync = FALSE

/obj/item/robot_suit/prebuilt/training/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/borg/upgrade/ai))
		to_chat(user, span_warning("Оболочки ИИ на полигоне недоступны."))
		return
	return ..()

/obj/item/robot_suit/prebuilt/training/mind_ready(mob/living/brain/brain_mob, mob/user)
	if(brain_mob.mind)
		return TRUE
	to_chat(user, span_warning("В MMI нет разума: возьмите мозг учебной цели."))
	return FALSE

/obj/item/robot_suit/prebuilt/training/bind_to_station(mob/living/silicon/robot/borg, obj/item/mmi/mmi)
	if(mmi.laws && mmi.laws.id != DEFAULT_AI_LAWID)
		borg.laws = mmi.laws
		mmi.laws.associate(borg)

/obj/item/robot_suit/prebuilt/training/Interact(mob/user)
	var/dat = "Обозначение: <A href='?src=[REF(src)];Name=1'>[created_name || "по умолчанию"]</a><br>"
	dat += "Сервоприводы: <A href='?src=[REF(src)];Loco=1'>[locomotion ? "включены" : "заблокированы"]</a><br>"
	dat += "Замок панели: <A href='?src=[REF(src)];Panel=1'>[panel_locked ? "закрыт" : "открыт"]</a><br><br>"
	dat += "Связь с ИИ и синхронизация законов на учебной раме отключены."
	var/datum/browser/popup = new(user, "robotdebug", "Отладка учебной рамы", 310, 220)
	popup.set_content(dat)
	popup.open()

/obj/item/robot_suit/prebuilt/training/Topic(href, href_list)
	if(href_list["Master"] || href_list["AI"] || href_list["Law"])
		return
	return ..()

/mob/living/silicon/robot/training
	lawupdate = FALSE
	scrambledcodes = TRUE

/mob/living/silicon/robot/training/Initialize(mapload)
	. = ..()
	QDEL_NULL(aiPDA)
	QDEL_NULL(wires)
	set_wires(new /datum/wires/robot/training(src))
	make_laws()

/mob/living/silicon/robot/training/Login()
	. = ..()
	to_chat(src, span_boldnotice("Учебный киборг: связи с ИИ станции нет, законы не синхронизируются, станционные камеры вас не видят."))

/mob/living/silicon/robot/training/set_connected_ai(new_ai)
	var/mob/living/silicon/ai/training/trainer = new_ai
	return ..(istype(trainer) && trainer.training_origin && trainer.training_origin == training_origin ? trainer : null)

/mob/living/silicon/robot/training/binarycheck()
	return FALSE

/mob/living/silicon/robot/training/apply_upgrade(obj/item/borg/upgrade/new_upgrade, mob/user, admin_added)
	if(istype(new_upgrade, /obj/item/borg/upgrade/ai))
		to_chat(user, span_warning("Оболочки ИИ на полигоне недоступны."))
		return FALSE
	return ..()

/mob/living/silicon/robot/training/make_shell(obj/item/borg/upgrade/ai/board)
	return FALSE

/datum/wires/robot/training

/datum/wires/robot/training/on_pulse(wire, user)
	if(wire != WIRE_AI)
		return ..()
	if(user)
		to_chat(user, span_warning("Канал связи с ИИ у учебного киборга отключён."))

/obj/machinery/mecha_part_fabricator/offstation/training
	name = "training exosuit fabricator"
	desc = "Учебный экзофабрикатор: материалы уже загружены, к силосу и R&D он не подключён. Маячков слежения, модулей управления ИИ и станционных эндоскелетов среди его чертежей нет."
	flags_1 = DEFAULT_RICOCHET_1 | NODECONSTRUCT_1
	var/list/starting_sheets = list(
		/datum/material/iron = 50,
		/datum/material/glass = 50,
		/datum/material/silver = 50,
		/datum/material/gold = 50,
		/datum/material/plasma = 50,
		/datum/material/diamond = 10,
	)

/obj/machinery/mecha_part_fabricator/offstation/training/Initialize(mapload)
	stored_research = new /datum/techweb/specialized/autounlocking/exofab/training
	. = ..()
	UnregisterSignal(SSdcs, list(COMSIG_GLOB_RESEARCH_NODE_UNLOCKED, COMSIG_GLOB_RESEARCH_BATCH_COMPLETE))
	var/preload = 0
	for(var/material in starting_sheets)
		preload += starting_sheets[material] * MINERAL_MATERIAL_AMOUNT
	rmat.set_local_size(rmat.local_size + preload)
	for(var/material in starting_sheets)
		rmat.mat_container.insert_amount_mat(starting_sheets[material] * MINERAL_MATERIAL_AMOUNT, material)

/obj/machinery/mecha_part_fabricator/offstation/training/sync(ignore_timer = FALSE, is_silent = FALSE)
	if(!is_silent && COOLDOWN_FINISHED(src, cooldown_say))
		COOLDOWN_START(src, cooldown_say, cooldown_say_time)
		say("Учебный экзофабрикатор не связан с R&D: все учебные чертежи уже загружены.")
	return FALSE

/datum/techweb/specialized/autounlocking/exofab/training
	pays_research_bounty = FALSE

/datum/techweb/specialized/autounlocking/exofab/training/add_design(datum/design/design, custom = FALSE)
	if(ispath(design?.build_path, /obj/item/mecha_parts/mecha_tracking) || ispath(design?.build_path, /obj/item/borg/upgrade/ai) || design?.build_path == /obj/item/robot_suit)
		return FALSE
	return ..()
