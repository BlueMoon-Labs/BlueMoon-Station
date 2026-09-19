//WHITE-STEEL PORT - упрощённая адаптация под bluemoon
/datum/orbital_objective/headhunt
	name = "Охота за головами"
	var/generated = FALSE
	var/objective_z_level
	var/mob/living/mob_to_recover
	var/obj/structure/closet/supplypod/extractionpod/extraction_pod
	min_payout = 20 * CARGO_CRATE_VALUE
	max_payout = 50 * CARGO_CRATE_VALUE

/datum/orbital_objective/headhunt/get_text()
	return "Требуется ликвидировать опасного преступника, скрывающегося на [station_name]. \
			Живым или мертвым, его необходимо доставить на мостик и отправить к вашему нанимателю с помощью предоставленной системы доставки. \
			Следует принять во внимание, что преступник может быть экипирован гораздо лучше обычного рейнджера. \
			Возможно, может потребоваться помощь сотрудников службы безопасности. \
			Задание будет провалено в случае побега преступника со станции живым и без наручников, или в случае уничтожения его тела!"

/datum/orbital_objective/headhunt/on_assign(obj/machinery/computer/objective/objective_computer)
	var/area/A = GLOB.areas_by_type[/area/command]
	if(!A)
		return
	var/turf/open/T = pick(A.get_unobstructed_turfs())
	if(!T)
		T = locate() in shuffle(A.contents)
	if(!T)
		return
	extraction_pod = new()
	extraction_pod.name = "орбитальная система доставки Nanotrasen"
	extraction_pod.desc = "Сюда сувать того самого преступника с [station_name]. Пожалуйста, игнорируйте символику синдиката, это трофейный под со Второй Космической."
	new /obj/effect/pod_landingzone(T, extraction_pod)
	extraction_pod.stay_after_drop = TRUE
	extraction_pod.reversing = TRUE
	extraction_pod.explosionSize = list(0,0,0,1)
	extraction_pod.leavingSound = 'sound/effects/podwoosh.ogg'
	RegisterSignal(extraction_pod, COMSIG_ATOM_ENTERED, .proc/enter_check)

/datum/orbital_objective/headhunt/proc/enter_check(datum/source, entered_mob)
	SIGNAL_HANDLER
	if(!istype(source, /obj/structure/closet/supplypod/extractionpod))
		return
	if(!isliving(entered_mob))
		return
	if(entered_mob != mob_to_recover)
		return
	var/mob/living/M = entered_mob
	if(iscarbon(M))
		for(var/obj/item/W in M)
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				if(W == H.w_uniform)
					continue
				if(W == H.shoes)
					continue
			M.dropItemToGround(W)
	var/obj/structure/closet/supplypod/extractionpod/pod = source
	pod.startExitSequence(pod)
	complete_objective()

/datum/orbital_objective/headhunt/generate_objective_stuff(turf/chosen_turf)
	var/mob/living/carbon/human/created_human = new(chosen_turf)
	objective_z_level = created_human.z
	created_human.mind_initialize()
	mob_to_recover = created_human
	for(var/mob/living/simple_animal/hostile/SA in range(10, created_human))
		qdel(SA)
	var/turf/open/T = locate() in shuffle(view(1, created_human))
	if(T)
		new /obj/item/clothing/suit/space/hardsuit/ancient(T)
		new /obj/item/tank/internals/oxygen(T)
		new /obj/item/clothing/mask/gas(T)
		new /obj/item/storage/belt/utility/full(T)
	created_human.equipOutfit(/datum/outfit/job/assistant)
	generated = TRUE

/datum/orbital_objective/headhunt/check_failed()
	if(generated)
		if(!mob_to_recover || QDELETED(mob_to_recover))
			. = TRUE
		else if(mob_to_recover.z != objective_z_level && mob_to_recover.stat != DEAD)
			. = TRUE
			if(iscarbon(mob_to_recover))
				var/mob/living/carbon/C = mob_to_recover
				if(C.get_item_by_slot(ITEM_SLOT_HANDCUFFED))
					. = FALSE
	if(.) 
		if(extraction_pod)
			extraction_pod.startExitSequence(extraction_pod)
