// Sleeper, Medical Beam, and Syringe gun

/obj/item/mecha_parts/mecha_equipment/medical
	mech_flags = EXOSUIT_MODULE_MEDICAL
	compatible_mecha_types = MECHA_TYPE_MEDICAL

/obj/item/mecha_parts/mecha_equipment/medical/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/mecha_parts/mecha_equipment/medical/attach(obj/vehicle/sealed/mecha/M)
	..()
	START_PROCESSING(SSobj, src)

/obj/item/mecha_parts/mecha_equipment/medical/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/medical/process()
	if(!chassis)
		return PROCESS_KILL

/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam/detach()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/medical/sleeper
	name = "mounted sleeper"
	desc = "Оборудование для медицинских экзокостюмов. Установленная медицинская капсула, стабилизирующая пациентов и способная вводить реагенты из резервуара экзокостюма."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	energy_drain = 20
	range = MECHA_MELEE
	equip_cooldown = 20
	var/mob/living/carbon/patient = null
	var/inject_amount = 10
	salvageable = 0

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/Destroy()
	for(var/atom/movable/AM in src)
		AM.forceMove(get_turf(src))
	return ..()

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/Exit(atom/movable/O)
	return FALSE

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/action(mob/source, mob/living/carbon/target, params)
	if(!action_checks(target))
		return
	if(!istype(target))
		return
	if(!patient_insertion_check(target))
		return
	to_chat(source, "[icon2html(src, source)][span_notice("Вы начинаете помещать [target] в [src]...")]")
	chassis.visible_message(span_warning("[chassis] начинает помещать [target] в [src]."))
	if(do_after(source, equip_cooldown, target=target))
		if(!chassis || (src != chassis.selected && src != chassis.selected_right) || !(get_dir(chassis, target)&chassis.dir))
			return
		if(!patient_insertion_check(target, source))
			return
		target.forceMove(src)
		patient = target
		START_PROCESSING(SSobj, src)
		update_equip_info()
		to_chat(source, "[icon2html(src, source)][span_notice("[target] помещён в [src]. Система жизнеобеспечения включена.")]")
		chassis.visible_message(span_warning("[chassis] помещает [target] в [src]."))
		log_message("[target] помещён в капсулу. Система жизнеобеспечения включена.", LOG_MECHA)
		return ..()

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/proc/patient_insertion_check(mob/living/carbon/target, mob/user)
	if(target.buckled)
		to_chat(user, "[icon2html(src, user)][span_warning("Нельзя поместить [target] в капсулу: [target.ru_who()] пристёгнут[target.ru_a()] к [target.buckled]!")]")
		return
	if(target.has_buckled_mobs())
		to_chat(user, "[icon2html(src, user)][span_warning("Нельзя поместить [target] в капсулу: к пациенту прикреплены другие существа!")]")
		return
	if(patient)
		to_chat(user, "[icon2html(src, user)][span_warning("Капсула уже занята!")]")
		return
	return TRUE

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/proc/go_out()
	if(!patient)
		return
	patient.forceMove(get_turf(src))
	to_chat(chassis.occupants, "[icon2html(src, chassis.occupants)][span_notice("[patient] извлечён из капсулы. Система жизнеобеспечения отключена.")]")
	log_message("[patient] извлечён из капсулы. Система жизнеобеспечения отключена.", LOG_MECHA)
	STOP_PROCESSING(SSobj, src)
	patient = null
	update_equip_info()

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/detach()
	if(patient)
		to_chat(chassis.occupants, "[icon2html(src, chassis.occupants)][span_warning("Нельзя снять [src]: внутри находится пациент!")]")
		return
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/get_ui_data()
	. = ..()
	var/list/patient_data
	var/list/contained_reagents = list()
	var/list/injectible_reagents = list()
	if(patient)
		patient_data = list(
			"patient_name" = patient.name,
			"patient_health" = patient.health / patient.maxHealth,
			"patient_state" = patient.stat == DEAD ? "Мёртв" : patient.stat == CONSCIOUS ? "В сознании" : "Без сознания",
			"core_temp" = round(patient.bodytemperature - T0C, 0.1),
			"brute_loss" = patient.getBruteLoss(),
			"burn_loss" = patient.getFireLoss(),
			"toxin_loss" = patient.getToxLoss(),
			"oxygen_loss" = patient.getOxyLoss(),
		)
		for(var/datum/reagent/reagent as anything in patient.reagents.reagent_list)
			contained_reagents += list(list("name" = reagent.name, "volume" = round(reagent.volume, 0.1)))
		var/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/gun = locate() in chassis.equipment
		if(gun)
			for(var/datum/reagent/reagent as anything in gun.reagents.reagent_list)
				injectible_reagents += list(list("name" = reagent.name, "volume" = round(reagent.volume, 0.1), "id" = REF(reagent)))
	.["snowflake"] = list("kind" = "sleeper", "patient" = patient_data, "contained_reagents" = contained_reagents, "injectible_reagents" = injectible_reagents)

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/handle_ui_act(action, list/params)
	. = ..()
	if(.)
		return TRUE
	if(action == "eject")
		go_out()
		return TRUE
	if(action == "inject_reagent")
		var/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/gun = locate() in chassis.equipment
		if(!gun)
			return FALSE
		var/datum/reagent/reagent = locate(params["reagent"]) in gun.reagents.reagent_list
		if(!istype(reagent))
			return FALSE
		inject_reagent(reagent, gun)
		return TRUE
	return FALSE

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/proc/inject_reagent(datum/reagent/R,obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/SG)
	if(!R || !patient || !SG || !(SG in chassis.equipment))
		return FALSE
	var/to_inject = min(R.volume, inject_amount)
	if(to_inject && patient.reagents.get_reagent_amount(R.type) + to_inject <= inject_amount*2)
		to_chat(chassis.occupants, "[icon2html(src, chassis.occupants)][span_notice("Введение [to_inject] ед. реагента [R.name] пациенту [patient].")]")
		log_message("Введение [to_inject] ед. реагента [R.name] пациенту [patient].", LOG_MECHA)
		log_combat(chassis.occupants, patient, "injected", "[name] ([R] - [to_inject] units)")
		SG.reagents.trans_id_to(patient,R.type,to_inject)
		update_equip_info()
	return

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/container_resist(mob/living/user)
	go_out()

/obj/item/mecha_parts/mecha_equipment/medical/sleeper/process()
	if(..())
		return
	if(!chassis.has_charge(energy_drain))
		log_message("Выключен.", LOG_MECHA)
		to_chat(chassis.occupants, "[icon2html(src, chassis.occupants)][span_warning("[src] отключён: нет питания.")]")
		STOP_PROCESSING(SSobj, src)
		return
	var/mob/living/carbon/M = patient
	if(!M)
		return
	if(M.health > 0)
		M.adjustOxyLoss(-1)
	M.AdjustStun(-80)
	M.AdjustKnockdown(-80)
	M.AdjustParalyzed(-80)
	M.AdjustImmobilized(-80)
	M.AdjustUnconscious(-80)
	if(M.reagents.get_reagent_amount(/datum/reagent/medicine/epinephrine) < 5)
		M.reagents.add_reagent(/datum/reagent/medicine/epinephrine, 5)
	chassis.use_power(energy_drain)
	update_equip_info()




///////////////////////////////// Syringe Gun ///////////////////////////////////////////////////////////////


/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun
	name = "exosuit syringe gun"
	desc = "Оборудование для медицинских экзокостюмов. Химический синтезатор со шприцем-пистолетом. Реагенты внутри находятся в стазисе, так что никаких реакций не произойдёт."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "syringegun"
	var/list/syringes
	var/list/known_reagents
	var/list/processed_reagents
	var/max_syringes = 10
	var/max_volume = 75 //max reagent volume
	var/synth_speed = 5 //[num] reagent units per cycle
	energy_drain = 10
	var/mode = 0 //0 - fire syringe, 1 - analyze reagents.
	range = MECHA_MELEE|MECHA_RANGED
	equip_cooldown = 10

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/Initialize(mapload)
	. = ..()
	create_reagents(max_volume, NO_REACT)
	syringes = new
	known_reagents = list(/datum/reagent/medicine/epinephrine="Эпинефрин")
	processed_reagents = new

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/detach()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/action(mob/source, atom/movable/target, params)
	if(!action_checks(target))
		return
	if(istype(target, /obj/item/reagent_containers/syringe))
		return load_syringe(target)
	if(istype(target, /obj/item/storage))//Loads syringes from boxes
		for(var/obj/item/reagent_containers/syringe/S in target.contents)
			load_syringe(S, source)
		return
	if(mode)
		return analyze_reagents(target, source)
	if(!syringes.len)
		to_chat(source, "[icon2html(src, source)][span_alert("Нет загруженных шприцев.")]")
		return
	if(reagents.total_volume<=0)
		to_chat(source, "[icon2html(src, source)][span_alert("Нет реагентов для заполнения шприца.")]")
		return
	if(HAS_TRAIT(source, TRAIT_PACIFISM))
		to_chat(source, span_alert("[src] может причинить смертельный вред! Вы не хотите никому навредить..."))
		return
	var/turf/trg = get_turf(target)
	var/obj/item/reagent_containers/syringe/mechsyringe = syringes[1]
	mechsyringe.forceMove(get_turf(chassis))
	reagents.trans_to(mechsyringe, min(mechsyringe.volume, reagents.total_volume))
	syringes -= mechsyringe
	mechsyringe.icon = 'icons/obj/chemical.dmi'
	mechsyringe.icon_state = "syringeproj"
	playsound(chassis, 'sound/items/syringeproj.ogg', 50, TRUE)
	log_message("[source] запускает [mechsyringe] из [src] в цель [target].", LOG_MECHA)
	spawn(0)	//This code is trash and whoever wrote it should feel bad
		for(var/i=0, i<6, i++)
			if(!mechsyringe)
				break
			if(step_towards(mechsyringe,trg))
				var/list/mobs = new
				for(var/mob/living/carbon/M in mechsyringe.loc)
					mobs += M
				if(length(mobs))
					var/mob/living/carbon/M = pick(mobs)
					var/R
					mechsyringe.visible_message(span_attack("Шприц попадает в [M]!"))
					if(M.can_inject(null, 1))
						if(mechsyringe.reagents)
							for(var/datum/reagent/A in mechsyringe.reagents.reagent_list)
								R += "[A.name] ([num2text(A.volume)]"
						mechsyringe.icon_state = initial(mechsyringe.icon_state)
						mechsyringe.icon = initial(mechsyringe.icon)
						mechsyringe.reagents.reaction(M, INJECT)
						mechsyringe.reagents.trans_to(M, mechsyringe.reagents.total_volume, log = TRUE)
						M.take_bodypart_damage(2)
						log_combat(source, M, "shot", "syringegun")
					break
				else if(mechsyringe.loc == trg)
					mechsyringe.icon_state = initial(mechsyringe.icon_state)
					mechsyringe.icon = initial(mechsyringe.icon)
					mechsyringe.update_icon()
					break
			else
				mechsyringe.icon_state = initial(mechsyringe.icon_state)
				mechsyringe.icon = initial(mechsyringe.icon)
				mechsyringe.update_icon()
				break
			sleep(1)
	return ..()


/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/get_ui_data()
	. = ..()
	var/list/contained_reagents = list()
	var/list/analyzed_reagents = list()
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		contained_reagents += list(list("name" = reagent.name, "volume" = round(reagent.volume, 0.1), "id" = "[reagent.type]"))
	for(var/reagent_type in known_reagents)
		analyzed_reagents += list(list("name" = known_reagents[reagent_type], "id" = "[reagent_type]", "enabled" = (reagent_type in processed_reagents)))
	.["snowflake"] = list(
		"kind" = "syringe",
		"mode" = mode ? "Анализ" : "Стрельба",
		"syringe" = length(syringes),
		"max_syringe" = max_syringes,
		"reagents" = reagents.total_volume,
		"total_reagents" = reagents.maximum_volume,
		"contained_reagents" = contained_reagents,
		"analyzed_reagents" = analyzed_reagents,
		"synthesizing" = !!(datum_flags & DF_ISPROCESSING),
	)

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/handle_ui_act(action, list/params)
	. = ..()
	if(.)
		return TRUE
	switch(action)
		if("change_mode")
			mode = !mode
		if("toggle_reagent")
			var/reagent_type = text2path(params["reagent"])
			if(!(reagent_type in known_reagents))
				return FALSE
			if(reagent_type in processed_reagents)
				processed_reagents -= reagent_type
			else if(length(processed_reagents) < synth_speed)
				processed_reagents += reagent_type
		if("synthesize")
			if(datum_flags & DF_ISPROCESSING)
				STOP_PROCESSING(SSobj, src)
			else if(length(processed_reagents))
				START_PROCESSING(SSobj, src)
		if("purge_reagent")
			var/reagent_type = text2path(params["reagent"])
			if(!ispath(reagent_type, /datum/reagent))
				return FALSE
			reagents.del_reagent(reagent_type)
		if("purge_all")
			reagents.clear_reagents()
		else
			return FALSE
	update_equip_info()
	return TRUE

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/proc/load_syringe(obj/item/reagent_containers/syringe/S, mob/user)
	if(syringes.len<max_syringes)
		if(get_dist(src,S) >= 2)
			to_chat(user, "[icon2html(src, user)][span_warning("Шприц слишком далеко!")]")
			return FALSE
		for(var/obj/structure/D in S.loc)//Basic level check for structures in the way (Like grilles and windows)
			if(!(D.CanPass(S,src.loc)))
				to_chat(user, "[icon2html(src, user)][span_warning("Не удалось загрузить шприц!")]")
				return FALSE
		for(var/obj/machinery/door/D in S.loc)//Checks for doors
			if(!(D.CanPass(S,src.loc)))
				to_chat(user, "[icon2html(src, user)][span_warning("Не удалось загрузить шприц!")]")
				return FALSE
		S.reagents.trans_to(src, S.reagents.total_volume)
		S.forceMove(src)
		syringes += S
		to_chat(user, "[icon2html(src, user)][span_notice("Шприц загружен.")]")
		update_equip_info()
		return TRUE
	to_chat(user, "[icon2html(src, user)][span_warning("Отсек для шприцев [src] заполнен!")]")
	return FALSE

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/proc/analyze_reagents(atom/A, mob/user)
	if(get_dist(src,A) >= 4)
		to_chat(user, "[icon2html(src, user)][span_notice("Объект слишком далеко!")]")
		return FALSE
	if(!A.reagents || ismob(A))
		to_chat(user, "[icon2html(src, user)][span_warning("Не удалось получить сведения о реагентах в [A].")]")
		return FALSE
	to_chat(user, "[icon2html(src, user)][span_notice("Анализ реагентов...")]")
	for(var/datum/reagent/R in A.reagents.reagent_list)
		if(R.can_synth && add_known_reagent(R.type,R.name))
			to_chat(user, "[icon2html(src, user)][span_notice("Реагент определён как [R.name] и добавлен в базу данных.")]")
			update_equip_info()
	to_chat(user, "[icon2html(src, user)][span_notice("Анализ завершён.")]")
	return TRUE

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/proc/add_known_reagent(r_id,r_name)
	if(!(r_id in known_reagents))
		known_reagents += r_id
		known_reagents[r_id] = r_name
		return TRUE
	return FALSE

/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/on_reagent_change(changetype)
	..()
	update_equip_info()


/obj/item/mecha_parts/mecha_equipment/medical/syringe_gun/process()
	if(..())
		return
	if(!processed_reagents.len || reagents.total_volume >= reagents.maximum_volume || !chassis.has_charge(energy_drain))
		to_chat(chassis.occupants, "[icon2html(src, chassis.occupants)][span_alert("Синтез реагентов остановлен.")]")
		log_message("Синтез реагентов остановлен.", LOG_MECHA)
		STOP_PROCESSING(SSobj, src)
		return
	var/amount = synth_speed / processed_reagents.len
	for(var/reagent in processed_reagents)
		reagents.add_reagent(reagent,amount)
		chassis.use_power(energy_drain)

///////////////////////////////// Medical Beam ///////////////////////////////////////////////////////////////

/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam
	name = "exosuit medical beamgun"
	desc = "Оборудование для медицинских экзокостюмов. Генерирует фокусированный луч медицинских нанитов."
	icon_state = "mecha_medigun"
	energy_drain = 10
	range = MECHA_MELEE|MECHA_RANGED
	equip_cooldown = 0
	var/obj/item/gun/medbeam/mech/medigun
	custom_materials = list(/datum/material/iron = 15000, /datum/material/glass = 8000, /datum/material/plasma = 3000, /datum/material/gold = 8000, /datum/material/diamond = 2000)

/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam/Initialize(mapload)
	. = ..()
	medigun = new(src)


/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam/Destroy()
	qdel(medigun)
	return ..()

/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam/process()
	if(..())
		return
	medigun.process()

/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam/action(mob/source, atom/movable/target, params)
	medigun.process_fire(target, loc)


/obj/item/mecha_parts/mecha_equipment/medical/mechmedbeam/detach()
	STOP_PROCESSING(SSobj, src)
	medigun.LoseTarget()
	return ..()
