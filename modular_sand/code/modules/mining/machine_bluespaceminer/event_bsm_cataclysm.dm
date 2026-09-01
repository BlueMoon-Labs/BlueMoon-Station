/// Админский ивент (weight = 0, admin_only): запускается только вручную через
/// "Admin.Events -> Trigger Event" и наводит tunguska-класс блюспейс-метеорит на цель.
/// Админ может выбрать конкретный турф (любой на станции), турф под собой — либо оставить
/// "Случайный майнер" как цель по умолчанию. Также можно задать сторону света, с которой
/// метеор будет лететь.

/proc/bsm_get_all_miners()
	var/list/miners = list()
	var/list/by_zlevel = SSmachines.bluespaceminer_by_zlevel
	if(!islist(by_zlevel))
		return miners
	for(var/z in 1 to length(by_zlevel))
		var/list/z_miners = by_zlevel[z]
		if(!islist(z_miners))
			continue
		for(var/obj/machinery/mineral/bluespace_miner/miner as anything in z_miners)
			if(miner && !QDELETED(miner))
				miners += miner
	return miners

/proc/bsm_pick_random_miner()
	var/list/miners = bsm_get_all_miners()
	if(!length(miners))
		return null
	return pick(miners)

/// Если на таргетном турфе есть живой моб, возвращает его (метеор будет гнаться за ним),
/// иначе возвращает сам турф как статичную цель.
/proc/bsm_pick_living_target_on(turf/T)
	if(!T)
		return null
	for(var/mob/living/L in T)
		if(L.stat != DEAD && !QDELETED(L))
			return L
	return T

/datum/round_event_control/bsm_cataclysm
	name = "Bluespace Cataclysm Meteor"
	typepath = /datum/round_event/bsm_cataclysm
	category = EVENT_CATEGORY_SPACE
	description = "Крупный привязанный к блюспейсу метеорит пронзает станцию и бьёт по выбранному админом месту (турфу или случайному майнеру)."
	weight = 0
	admin_only = TRUE
	max_occurrences = 0
	earliest_start = 0
	min_players = 0
	severity = DIRECTOR_SEVERITY_MAJOR
	admin_setup = list(/datum/event_admin_setup/bsm_cataclysm_target, /datum/event_admin_setup/direction/bsm_cataclysm)

/datum/round_event/bsm_cataclysm
	start_when = 1
	end_when = 2
	/// Цель метеора (турф или объект), выбранная админом; null = случайный майнер.
	var/atom/chosen_target
	/// Сторона света, с которой летит метеор; null = случайная.
	var/chosen_side

/datum/round_event/bsm_cataclysm/start()
	var/atom/target = chosen_target
	if(QDELETED(target))
		target = bsm_pick_random_miner()
	if(QDELETED(target))
		message_admins("Bluespace Cataclysm Meteor не нашёл ни одного рабочего блюспейс-майнера и не был запущен.")
		return
	bsm_spawn_cataclysm(target, chosen_side)
	var/target_desc
	if(isliving(target))
		target_desc = "моб [target] ([AREACOORD(target)])"
	else if(istype(target, /obj/machinery/mineral/bluespace_miner))
		target_desc = "майнер [AREACOORD(target)]"
	else
		target_desc = "плитка [AREACOORD(target)]"
	log_game("Bluespace miner cataclysm (admin event): метеорит прицелился на [target_desc].")
	message_admins(span_adminnotice("Bluespace miner cataclysm (admin event): метеорит прицелился на [target_desc] [ADMIN_VERBOSEJMP(target)]"))

/// Позволяет админу прицелиться: случайный майнер, текущий турф или любой турф станции
/// (через выбор зоны и точного турфа).
/datum/event_admin_setup/bsm_cataclysm_target
	var/input_text = "Куда направить блюспейс-метеор?"
	/// Выбранная цель (турф или объект); null = случайный майнер.
	var/atom/chosen_target

/datum/event_admin_setup/bsm_cataclysm_target/prompt_admins()
	var/list/options = list()
	options["Случайный майнер"] = "random"
	options["Текущий турф (под вами)"] = "current"
	options["Выбрать зону станции..."] = "zone"
	var/choice = tgui_input_list(usr, input_text, event_control.name, options)
	if(isnull(choice))
		return ADMIN_CANCEL_EVENT
	switch(choice)
		if("random")
			chosen_target = null
		if("current")
			chosen_target = bsm_pick_living_target_on(get_turf(usr))
		if("zone")
			var/area/chosen_area = tgui_input_list(usr, "Выберите зону станции", event_control.name, GLOB.sortedAreas)
			if(!chosen_area)
				return ADMIN_CANCEL_EVENT
			var/list/turf_options = list()
			for(var/turf/T in chosen_area)
				if(T && !QDELETED(T))
					turf_options["[AREACOORD(T)]"] = T
			if(!length(turf_options))
				tgui_alert(usr, "В выбранной зоне не оказалось тайлов.", "Ошибка")
				return ADMIN_CANCEL_EVENT
			var/turf/picked_turf = tgui_input_list(usr, "Выберите точный турф внутри зоны", event_control.name, turf_options)
			if(isnull(picked_turf))
				return ADMIN_CANCEL_EVENT
			chosen_target = bsm_pick_living_target_on(picked_turf)

/datum/event_admin_setup/bsm_cataclysm_target/apply_to_event(datum/round_event/bsm_cataclysm/event)
	event.chosen_target = chosen_target
	var/target_text = chosen_target ? "[AREACOORD(chosen_target)]" : "случайный майнер"
	message_admins("[key_name_admin(usr)] направил блюспейс-метеор на [target_text].")
	log_admin("[key_name(usr)] aimed the bluespace cataclysm meteor at [target_text].")

/datum/event_admin_setup/direction/bsm_cataclysm
	input_text = "С какой стороны света будет лететь блюспейс-метеор?"

/datum/event_admin_setup/direction/bsm_cataclysm/apply_to_event(datum/round_event/bsm_cataclysm/event)
	event.chosen_side = chosen_side
