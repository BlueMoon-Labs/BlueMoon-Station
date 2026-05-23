/datum/round_event_control/electrical_storm
	name = "Electrical Storm"
	typepath = /datum/round_event/electrical_storm
	earliest_start = 15 MINUTES
	min_players = 15
	weight = 25
	max_occurrences = 2
	alert_observers = FALSE
	category = EVENT_CATEGORY_JANITORIAL

/datum/round_event/electrical_storm
	var/lightsoutAmount	= 1
	var/lightsoutRange	= 25
	announce_when	= 1

/datum/round_event/electrical_storm/announce(fake)
	if(prob(50))
		priority_announce("В вашем районе была обнаружена Электромагнитная Буря. Пожалуйста, устраните возможные перегрузки Осветительных Приборов.", "ВНИМАНИЕ: Электромагнитная Буря")
	else
		print_command_report("В вашем районе была обнаружена Электромагнитная Буря. Пожалуйста, устраните возможные перегрузки Осветительных Приборов.", "ВНИМАНИЕ: Электромагнитная Буря")

/datum/round_event/electrical_storm/start()
	var/list/epicentreList = list()

	for(var/i=1, i <= lightsoutAmount, i++)
		var/turf/T = find_safe_turf()
		if(istype(T))
			epicentreList += T

	if(!epicentreList.len)
		return

	for(var/centre in epicentreList)
		for(var/a in GLOB.apcs_list)
			var/obj/machinery/power/apc/A = a
			if(get_dist(centre, A) <= lightsoutRange)
				A.overload_lighting()

	//BLUEMOON ADD START - уничтожение противометеоритных спутников
	var/satellties_count = 0
	for(var/obj/machinery/satellite/satellite in GLOB.meteor_satellites)
		if(satellties_count >= 2)
			break
		if(satellite.active)
			satellties_count++
			satellite.malfunction()
	//BLUEMOON ADD START

	var/list/safe_z_levels = list()
	safe_z_levels |= SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	safe_z_levels |= SSmapping.levels_by_trait(ZTRAIT_VR)
	safe_z_levels |= SSmapping.levels_by_trait(ZTRAIT_VIRTUAL_REALITY)
	safe_z_levels |= SSmapping.levels_by_trait(ZTRAITS_LAVALAND)
	// Делаем больно синтетикам с уязвимостью к ЭМИ
	for(var/i in GLOB.human_list)
		var/mob/living/carbon/human/H = i
		if(!istype(H) || QDELETED(H))
			continue
		if(H.z in safe_z_levels)
			continue
		if(isrobotic(H) && HAS_TRAIT(H, TRAIT_BLUEMOON_EMP_VULNERABILITY) && H.stat != DEAD)
			var/protection = SEND_SIGNAL(H, COMSIG_ATOM_EMP_ACT, 1)
			if(protection & EMP_PROTECT_CONTENTS)
				continue
			H.visible_message(span_warning("[H] вздрагивает, когда сквозь [H.ru_ego()] корпус проходит электромагнитный импульс."), span_boldwarning("Электромагнитная буря задела вас! Ауч!"))
			H.apply_damage(20, BURN)
			H.adjustToxLoss(20, toxins_type = TOX_SYSCORRUPT)
			H.Jitter(20)
			H.AdjustConfused(40 SECONDS)
			H.Stun(5)
			H.Dizzy(15)
