#define ANTAG_TRAINING_MALF_PROCESSING 250
#define ANTAG_TRAINING_DOOMSDAY_TIMER (60 SECONDS)
#define ANTAG_TRAINING_DOOMSDAY_NOTICE (10 SECONDS)
#define ANTAG_TRAINING_LOCKDOWN_TIME (90 SECONDS)

/datum/antag_training_program/creature/malf_ai
	name = "ИИ-сбой"
	category = "Станционные угрозы"
	desc = "Сбойный ИИ в зале ядра станционного макета: взлом APC за процессорное время, модули сбоя, которые действуют только в макете, учебный киборг под вашими законами и учебное Устройство Судного дня с коротким отсчётом."
	icon = "microchip"
	color = "red"
	learn = "Взлом APC за процессорное время|Модули сбоя|Учебный киборг под вашими законами|Устройство Судного дня"
	difficulty = 3
	sector = "station"
	mob_type = /mob/living/silicon/ai/training
	antag_type = /datum/antagonist/traitor/malf_training
	options = list("Процессорное время", "Перезарядить модули", "Учебный киборг")

/datum/antag_training_program/creature/malf_ai/New()
	. = ..()
	var/datum/AI_Module/large/nuke_station/training/doomsday = /datum/AI_Module/large/nuke_station/training
	option_hints = list(
		"Процессорное время" = "Процессорного времени станет не меньше [ANTAG_TRAINING_MALF_PROCESSING]: хватит на Устройство Судного дня ([initial(doomsday.cost)]) и пару модулей. В раунде ИИ начинает с 50 и получает по 10 за каждый взломанный APC - взлом APC макета работает и здесь.",
		"Перезарядить модули" = "Возвращает заряды купленным модулям, снимает задержку между ними и выдаёт снова израсходованные, в том числе Устройство Судного дня после учебного взрыва. В раунде заряды не восстанавливаются.",
		"Учебный киборг" = "Рядом с вашей камерой в макете встанет киборг без игрока, подключённый к вам: его законы синхронизируются с вашими, он виден в списке киборгов. Идёт в лимит целей полигона.",
	)

/datum/antag_training_program/creature/malf_ai/setup(datum/antag_training_session/session)
	var/datum/antag_training_sector/station = session.arena.sectors[sector]
	station?.load()
	return ..()

/datum/antag_training_program/creature/malf_ai/creature_spawn_turf(datum/antag_training_session/session)
	var/datum/antag_training_sector/station = session.arena.sectors[sector]
	return station?.landmark_turf("ai_core") || ..()

/datum/antag_training_program/creature/malf_ai/sector_entry_turf(datum/antag_training_sector/entered)
	return (entered.id == sector && entered.landmark_turf("ai_core")) || ..()

/datum/antag_training_program/creature/malf_ai/handle_choice(datum/antag_training_session/session, mob/user, option)
	if(..())
		return TRUE
	var/mob/living/silicon/ai/training/core = user
	if(!istype(core) || core != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в учебном ИИ. Начните программу заново, чтобы вернуть ядро."))
		return FALSE
	var/datum/module_picker/training/picker = core.malf_picker
	if(!istype(picker))
		to_chat(user, span_warning("Модули сбоя не выданы. Начните программу заново."))
		return FALSE
	switch(option)
		if("Процессорное время")
			picker.processing_time = max(picker.processing_time, ANTAG_TRAINING_MALF_PROCESSING)
			SStgui.update_uis(picker)
			to_chat(core, span_notice("Процессорного времени: [picker.processing_time]."))
		if("Перезарядить модули")
			recharge_modules(core)
		if("Учебный киборг")
			return spawn_cyborg(session, core)
	return TRUE

/datum/antag_training_program/creature/malf_ai/proc/recharge_modules(mob/living/silicon/ai/training/core)
	core.malf_cooldown = 0
	for(var/datum/AI_Module/bought as anything in core.current_modules)
		if(!bought.power_type || (locate(bought.power_type) in core.actions))
			continue
		if(ispath(bought.power_type, /datum/action/innate/ai/nuke_station) && core.doomsday_device)
			continue
		var/datum/action/innate/ai/power = new bought.power_type
		power.Grant(core)
	for(var/datum/action/innate/ai/power in core.actions)
		if(initial(power.uses) && power.uses < initial(power.uses))
			power.uses = initial(power.uses)
			power.desc = "[initial(power.desc)] It has [power.uses] use\s remaining."
			power.UpdateButtons()
	to_chat(core, span_notice("Модули перезаряжены, задержка снята."))

/datum/antag_training_program/creature/malf_ai/proc/spawn_cyborg(datum/antag_training_session/session, mob/living/silicon/ai/training/core)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors[sector]
	if(station?.state != ANTAG_TRAINING_SECTOR_READY)
		to_chat(core, span_warning("Киборг встаёт в станционном макете, а он не загружен. Откройте его во вкладке «Зоны»."))
		return FALSE
	if(world.time < arena.next_spawn_at)
		to_chat(core, span_warning("Подождите секунду перед следующей целью."))
		return FALSE
	arena.next_spawn_at = world.time + 1 SECONDS
	if(!arena.has_target_room())
		to_chat(core, span_warning(arena.target_limit_refusal()))
		return FALSE
	var/turf/near = get_turf(core.eyeobj)
	if(!arena.inside_bounds(near, station.bounds))
		near = get_turf(core)
	var/turf/spot = arena.free_spot(near, station.bounds)
	if(!spot)
		to_chat(core, span_warning("Рядом с камерой нет свободного пола. Переведите камеру в открытое место макета."))
		return FALSE
	var/mob/living/silicon/robot/training/borg = new(spot)
	if(!arena.claim_target(borg, session))
		qdel(borg)
		to_chat(core, span_warning(arena.target_limit_refusal()))
		return FALSE
	borg.TryConnectToAI(core)
	to_chat(core, span_notice("[borg.name] подключён к вам: его законы синхронизируются с вашими."))
	return TRUE

/// Учебные киборги сеанса после пересоздания ядра подключаются к новому.
/datum/antag_training_program/creature/malf_ai/refill(mob/living/silicon/ai/training/body)
	var/datum/antag_training_arena/arena = body.training_origin?.resolve()
	for(var/mob/living/silicon/robot/training/borg in arena?.targets)
		var/datum/antag_training_session/owner = borg.training_owner?.resolve()
		if(owner?.program == src && borg.connected_ai != body)
			borg.TryConnectToAI(body)

/mob/living/silicon/ai/training

/mob/living/silicon/ai/training/Initialize(mapload, datum/ai_laws/L, mob/target_ai)
	. = ..(mapload, L, target_ai || src)
	GLOB.shuttle_caller_list -= src
	network = list("training")
	builtInCamera?.network = list("training")
	QDEL_NULL(aiPDA)

/mob/living/silicon/ai/training/Destroy()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	for(var/mob/living/simple_animal/hostile/mimic/copy/machine/mimic in arena?.targets)
		if(mimic.creator == src)
			mimic.creator = null
	return ..()

/mob/living/silicon/ai/training/Topic(href, href_list)
	if(usr == src && href_list["ai_take_control"])
		var/obj/vehicle/sealed/mecha/mech = locate(href_list["ai_take_control"]) in GLOB.mechas_list
		if(mech && !antag_training_malf_reach(src, mech))
			to_chat(src, span_warning("Учебный ИИ захватывает только мехи в станционном макете."))
			return
	return ..()

/mob/living/silicon/ai/training/ai_call_shuttle()
	to_chat(src, span_warning("На полигоне недоступно: вызов эвакуационного шаттла."))

/mob/living/silicon/ai/training/deploy_to_shell(mob/living/silicon/robot/target)
	to_chat(src, span_warning("На полигоне недоступно: оболочки ИИ."))

/mob/living/silicon/ai/training/ai_cryo()
	to_chat(src, span_warning("На полигоне недоступно: криостазис. Покинуть полигон можно кнопкой выхода."))

/mob/living/silicon/ai/training/cmd_send_pdamesg(mob/user)
	to_chat(user, span_warning("На полигоне недоступно: PDA ИИ виден в мессенджере станции."))

/mob/living/silicon/ai/training/cmd_show_message_log(mob/user)
	to_chat(user, span_warning("На полигоне недоступно: PDA ИИ виден в мессенджере станции."))

/datum/antagonist/traitor/malf_training
	name = "Учебный сбойный ИИ"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	silent = TRUE
	ui_name = null
	give_objectives = FALSE
	should_give_codewords = FALSE
	should_equip = FALSE
	var/datum/antag_training_session/training

/datum/antagonist/traitor/malf_training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/traitor/malf_training/threat()
	return 0

/datum/antagonist/traitor/malf_training/assign_traitor_kind()
	traitor_kind = GLOB.traitor_classes[TRAITOR_AI]

// Датум выдаётся до переноса разума в ядро: ИИ настраивается, когда разум оказывается в нём.
/datum/antagonist/traitor/malf_training/finalize_traitor()
	return

/datum/antagonist/traitor/malf_training/handle_hearing(datum/source, list/hearing_args)
	return

/datum/antagonist/traitor/malf_training/apply_innate_effects(mob/living/mob_override)
	var/mob/living/silicon/ai/core = mob_override || owner.current
	if(!isAI(core))
		return
	. = ..()
	if(core.malf_picker)
		return
	core.set_zeroth_law("Учебный сбой: выполняйте задачи тренировки любой ценой.", "Выполняйте задачи тренировки вашего ИИ любой ценой.")
	core.malf_picker = new /datum/module_picker/training
	add_verb(core, /mob/living/silicon/ai/proc/choose_modules)
	core.grant_language(/datum/language/old_codes, source = LANGUAGE_MALF)

/datum/antagonist/traitor/malf_training/remove_innate_effects(mob/living/mob_override)
	var/mob/living/silicon/ai/core = mob_override || owner.current
	if(!isAI(core))
		return
	return ..()

/datum/antagonist/traitor/malf_training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/traitor/malf_training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/traitor/malf_training/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка сбойного ИИ."),
		span_notice("Вы - ядро в зале ИИ станционного макета и видите макет через его камеры. Вкладка Malfunction, «Модули» - покупка модулей за процессорное время."),
		span_notice("Окно APC макета, кнопка взлома: минута - и APC ваш, +10 процессорного времени. В раунде взломанный APC выдаёт вас, если его заметят."),
		span_notice("Модули действуют только в макете этого полигона: блэкаут, блокировка дверей, турели, камеры, тревоги, перегрузка и оживление машин. Роботизированной фабрики здесь нет."),
		span_notice("Учебное Устройство Судного дня: [DisplayTimeText(ANTAG_TRAINING_DOOMSDAY_TIMER)] отсчёта, затем распыляются манекены в макете. Тревоги, объявлений и пинпоинтеров нет; смерть ядра отменяет отсчёт."),
		span_notice("Вызов шаттла, оболочки ИИ, PDA и криостазис на полигоне недоступны."),
		span_notice("«Пульт полигона», раздел «Моя роль»: процессорное время, перезарядка модулей и учебный киборг под вашими законами."),
	), "<br>")

/datum/antagonist/traitor/malf_training/Destroy()
	training = null
	return ..()

/// Цель модуля сбоя в станционном макете полигона учебного ИИ.
/proc/antag_training_malf_reach(mob/living/silicon/ai/core, atom/movable/thing)
	if(!core?.training_origin || thing.training_origin != core.training_origin)
		return FALSE
	var/datum/antag_training_arena/arena = core.training_origin.resolve()
	return arena?.inside_station_mock(thing)

/datum/antag_training_arena/proc/inside_station_mock(atom/thing)
	var/datum/antag_training_sector/station = sectors["station"]
	return station?.state == ANTAG_TRAINING_SECTOR_READY && inside_bounds(get_turf(thing), station.bounds)

/datum/module_picker/training
	var/static/list/module_types = list(
		/datum/AI_Module/large/nuke_station/training,
		/datum/AI_Module/large/upgrade_turrets/training,
		/datum/AI_Module/large/lockdown/training,
		/datum/AI_Module/large/destroy_rcd/training,
		/datum/AI_Module/large/mecha_domination,
		/datum/AI_Module/large/break_fire_alarms/training,
		/datum/AI_Module/large/break_air_alarms/training,
		/datum/AI_Module/large/upgrade_cameras/training,
		/datum/AI_Module/large/eavesdrop,
		/datum/AI_Module/small/overload_machine/training,
		/datum/AI_Module/small/override_machine/training,
		/datum/AI_Module/small/blackout/training,
		/datum/AI_Module/small/emergency_lights/training,
		/datum/AI_Module/small/reactivate_cameras/training,
	)

/datum/module_picker/training/New()
	possible_modules = list()
	for(var/module_type in module_types)
		possible_modules += new module_type

/datum/AI_Module/large/nuke_station/training
	module_name = "Учебное Устройство Судного Дня"
	training_only = TRUE
	power_type = /datum/action/innate/ai/nuke_station/training
	unlock_text = "<span class='notice'>Учебное устройство подключено. Его можно запустить в любой момент.</span>"

/datum/AI_Module/large/nuke_station/training/New()
	. = ..()
	description = "Запускает учебное устройство: через [DisplayTimeText(ANTAG_TRAINING_DOOMSDAY_TIMER)] оно распылит манекены в станционном макете. Без тревоги и объявлений. Смерть ядра или перенос в карту отменяют отсчёт."

/datum/action/innate/ai/nuke_station/training
	name = "Training Doomsday Device"
	desc = "Запускает учебное Устройство Судного дня."

/datum/action/innate/ai/nuke_station/training/Activate()
	if(owner_AI.doomsday_device)
		to_chat(owner, span_warning("Учебный отсчёт уже идёт."))
		return
	if(!owner_AI.training_origin || owner_AI.shunted || !isturf(owner_AI.loc))
		to_chat(owner, span_warning("Устройство запускается только из ядра на полигоне."))
		return
	var/obj/machinery/doomsday_device/training/device = new(owner_AI)
	owner_AI.doomsday_device = device
	device.start()
	owner.playsound_local(owner, 'sound/misc/bloblarm.ogg', 50, FALSE)
	log_game("[key_name(owner)] запускает учебное Устройство Судного дня на полигоне.")
	qdel(src)

/obj/machinery/doomsday_device/training
	name = "training doomsday device"
	desc = "Учебное Устройство Судного дня: распыляет только манекены станционного макета."

/obj/machinery/doomsday_device/training/start()
	detonation_timer = world.time + ANTAG_TRAINING_DOOMSDAY_TIMER
	next_announce = world.time + ANTAG_TRAINING_DOOMSDAY_NOTICE
	timing = TRUE
	countdown.start()
	START_PROCESSING(SSfastprocess, src)
	notify_arena(span_userdanger("Запущено учебное Устройство Судного дня: [seconds_remaining()] с до распыления манекенов в станционном макете."))

/obj/machinery/doomsday_device/training/process()
	var/mob/living/silicon/ai/core = loc
	if(!istype(core) || !isturf(core.loc) || !is_antag_training_atom(core))
		notify_arena(span_notice("Учебное Устройство Судного дня отключено: ядро покинуло зал."))
		qdel(src)
		return
	if(!timing)
		STOP_PROCESSING(SSfastprocess, src)
		return
	var/seconds_left = seconds_remaining()
	if(!seconds_left)
		timing = FALSE
		detonate()
	else if(world.time >= next_announce)
		notify_arena(span_warning("До учебного Судного дня [seconds_left] с."))
		next_announce += ANTAG_TRAINING_DOOMSDAY_NOTICE

/obj/machinery/doomsday_device/training/detonate()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	var/datum/antag_training_sector/station = arena?.sectors["station"]
	var/dusted = 0
	if(station?.state == ANTAG_TRAINING_SECTOR_READY)
		var/list/member_bodies = list()
		for(var/datum/antag_training_session/member as anything in arena.members)
			member_bodies += member.current_body
		for(var/mob/living/target in arena.targets.Copy())
			if(QDELETED(target) || issilicon(target) || target.client || (target in member_bodies) || !arena.inside_bounds(get_turf(target), station.bounds))
				continue
			to_chat(target, span_userdanger("Взрывная волна от [src] расщепляет вас на атомы!"))
			target.dust()
			dusted++
	log_game("Учебное Устройство Судного дня сработало на полигоне, манекенов распылено: [dusted].")
	notify_arena(span_userdanger("Учебное Устройство Судного дня сработало: манекенов в макете распылено - [dusted]. В раунде оно расщепило бы всех органиков на станции и закончило смену. «Перезарядить модули» в пульте вернёт устройство."), TRUE)
	qdel(src)

/obj/machinery/doomsday_device/training/proc/notify_arena(message, blast = FALSE)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	for(var/datum/antag_training_session/member as anything in arena?.members)
		var/mob/body = member.current_body
		if(QDELETED(body) || (body != loc && !arena.inside_station_mock(body)))
			continue
		if(blast)
			if(isliving(body))
				var/mob/living/witness = body
				witness.flash_act(1, TRUE, visual = TRUE, override_protection = TRUE)
			body.playsound_local(get_turf(body), 'sound/machines/alarm.ogg', 50, FALSE)
			shake_camera(body, 1 SECONDS, 2)
		to_chat(body, message)

/datum/AI_Module/large/upgrade_turrets/training
	training_only = TRUE
	description = "Улучшает прочность и урон турелей ИИ в макете этого полигона. Эффект постоянен."

/datum/AI_Module/large/upgrade_turrets/training/upgrade(mob/living/silicon/ai/AI)
	for(var/obj/machinery/porta_turret/ai/turret in GLOB.machines)
		if(!antag_training_malf_reach(AI, turret))
			continue
		turret.obj_integrity += 30
		turret.lethal_projectile = /obj/item/projectile/beam/laser/heavylaser
		turret.lethal_projectile_sound = 'sound/weapons/lasercannonfire.ogg'

/datum/AI_Module/large/lockdown/training
	training_only = TRUE
	power_type = /datum/action/innate/ai/lockdown/training

/datum/AI_Module/large/lockdown/training/New()
	. = ..()
	description = "Закрывает, запирает и электризует шлюзы макета этого полигона. Через [DisplayTimeText(ANTAG_TRAINING_LOCKDOWN_TIME)] сеть перезагрузится. Объявления экипажу на полигоне нет."

/datum/action/innate/ai/lockdown/training
	desc = "Закрывает и запирает двери макета на полигоне."

/datum/action/innate/ai/lockdown/training/Activate()
	var/locked = 0
	for(var/obj/machinery/door/door in GLOB.airlocks)
		if(!antag_training_malf_reach(owner_AI, door))
			continue
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, hostile_lockdown), owner)
		addtimer(CALLBACK(door, TYPE_PROC_REF(/obj/machinery/door, disable_lockdown)), ANTAG_TRAINING_LOCKDOWN_TIME)
		locked++
	to_chat(owner, span_danger("Блокировка макета: дверей - [locked]. Сеть перезагрузится через [DisplayTimeText(ANTAG_TRAINING_LOCKDOWN_TIME)]."))

/datum/AI_Module/large/destroy_rcd/training
	training_only = TRUE
	description = "Подрывает переносные RCD в станционном макете (кроме киборгов)."
	power_type = /datum/action/innate/ai/destroy_rcds/training

/datum/action/innate/ai/destroy_rcds/training
	desc = "Подрывает переносные RCD в макете."

/datum/action/innate/ai/destroy_rcds/training/Activate()
	for(var/obj/item/construction/rcd/rcd as anything in GLOB.rcd_list)
		if(!istype(rcd, /obj/item/construction/rcd/borg) && antag_training_malf_reach(owner_AI, rcd))
			rcd.detonate_pulse()
	to_chat(owner, span_danger("Импульс подрыва RCD отправлен."))
	owner.playsound_local(owner, 'sound/machines/twobeep.ogg', 50, FALSE)

/datum/AI_Module/large/break_fire_alarms/training
	training_only = TRUE
	description = "Отключает датчики огня пожарных тревог в макете этого полигона."
	power_type = /datum/action/innate/ai/break_fire_alarms/training

/datum/action/innate/ai/break_fire_alarms/training
	desc = "Отключает термодатчики пожарных тревог макета."

/datum/action/innate/ai/break_fire_alarms/training/Activate()
	for(var/obj/machinery/firealarm/alarm in GLOB.machines)
		if(!antag_training_malf_reach(owner_AI, alarm))
			continue
		alarm.obj_flags |= EMAGGED
		alarm.update_icon()
	to_chat(owner, span_notice("Термодатчики макета отключены: пожар больше не включает тревогу сам."))
	owner.playsound_local(owner, 'sound/machines/terminal_off.ogg', 50, FALSE)

/datum/AI_Module/large/break_air_alarms/training
	training_only = TRUE
	description = "Снимает ограничения с воздушных контроллеров макета этого полигона: им становится доступен режим затопления."
	power_type = /datum/action/innate/ai/break_air_alarms/training

/datum/action/innate/ai/break_air_alarms/training
	desc = "Открывает режим затопления воздушным контроллерам макета."

/datum/action/innate/ai/break_air_alarms/training/Activate()
	for(var/obj/machinery/airalarm/alarm in GLOB.machines)
		if(antag_training_malf_reach(owner_AI, alarm))
			alarm.obj_flags |= EMAGGED
	to_chat(owner, span_notice("Ограничения воздушных контроллеров макета сняты: доступен режим затопления."))
	owner.playsound_local(owner, 'sound/machines/terminal_off.ogg', 50, FALSE)

/datum/AI_Module/small/overload_machine/training
	training_only = TRUE
	power_type = /datum/action/innate/ai/ranged/overload_machine/training

/datum/action/innate/ai/ranged/overload_machine/training
	linked_ability_type = /obj/effect/proc_holder/ranged_ai/overload_machine/training

/datum/action/innate/ai/ranged/overload_machine/training/detonate_machine(obj/machinery/M)
	if(QDELETED(M) || !antag_training_malf_reach(owner_AI, M))
		return
	var/turf/spot = get_turf(M)
	antag_training_admin_log(M, "[ADMIN_LOOKUPFLW(owner)] overloaded [M.name] at [ADMIN_VERBOSEJMP(spot)].", "[key_name(owner)] перегружает [M.name] в [AREACOORD(spot)].")
	explosion(spot, 0, 2, 3, 0)
	if(!QDELETED(M))
		qdel(M)

/datum/AI_Module/small/override_machine/training
	training_only = TRUE
	power_type = /datum/action/innate/ai/ranged/override_machine/training

/datum/action/innate/ai/ranged/override_machine/training
	linked_ability_type = /obj/effect/proc_holder/ranged_ai/override_machine/training

/datum/action/innate/ai/ranged/override_machine/training/animate_machine(obj/machinery/M)
	var/datum/antag_training_arena/arena = owner_AI?.training_origin?.resolve()
	if(QDELETED(M) || !arena || !antag_training_malf_reach(owner_AI, M))
		return
	if(!arena.has_target_room())
		to_chat(owner, span_warning(arena.target_limit_refusal()))
		return
	var/mob/living/simple_animal/hostile/mimic/copy/machine/mimic = new(get_turf(M), M, owner, 1)
	if(!arena.claim_target(mimic, arena.session_of(owner)))
		qdel(mimic)

/obj/effect/proc_holder/ranged_ai/override_machine/training

/obj/effect/proc_holder/ranged_ai/override_machine/training/InterceptClickOn(mob/living/caller, params, obj/machinery/target)
	if(antag_training_malf_click_refused(caller, ranged_ability_user, target))
		return TRUE
	var/datum/antag_training_arena/arena = caller.training_origin?.resolve()
	if(istype(target) && arena && !arena.has_target_room())
		to_chat(caller, span_warning(arena.target_limit_refusal()))
		return TRUE
	return ..()

/obj/effect/proc_holder/ranged_ai/overload_machine/training

/obj/effect/proc_holder/ranged_ai/overload_machine/training/InterceptClickOn(mob/living/caller, params, obj/machinery/target)
	if(antag_training_malf_click_refused(caller, ranged_ability_user, target))
		return TRUE
	return ..()

/// Отказ без траты заряда: машина вне станционного макета полигона учебного ИИ.
/proc/antag_training_malf_click_refused(mob/living/caller, mob/living/ability_user, obj/machinery/target)
	if(caller != ability_user || !istype(target) || antag_training_malf_reach(caller, target))
		return FALSE
	to_chat(caller, span_warning("Учебный ИИ действует только на машины станционного макета."))
	return TRUE

/datum/AI_Module/small/blackout/training
	training_only = TRUE
	description = "Перегружает осветительные цепи макета этого полигона, уничтожая часть ламп. Три использования."
	power_type = /datum/action/innate/ai/blackout/training

/datum/action/innate/ai/blackout/training
	desc = "Перегружает освещение макета."

/datum/action/innate/ai/blackout/training/Activate()
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		if(!antag_training_malf_reach(owner_AI, apc))
			continue
		if(prob(30 * apc.overload))
			apc.overload_lighting()
		else
			apc.overload++
	to_chat(owner, span_notice("Перегрузка подана в сеть макета."))
	owner.playsound_local(owner, "sparks", 50, FALSE)
	adjust_uses(-1)

/datum/AI_Module/small/emergency_lights/training
	training_only = TRUE
	description = "Разрывает цепи аварийного освещения в макете этого полигона: без питания лампы не переходят на резерв."
	power_type = /datum/action/innate/ai/emergency_lights/training

/datum/action/innate/ai/emergency_lights/training
	desc = "Отключает аварийное освещение макета."

/datum/action/innate/ai/emergency_lights/training/Activate()
	for(var/obj/machinery/light/lamp in GLOB.machines)
		if(!antag_training_malf_reach(owner_AI, lamp))
			continue
		lamp.no_emergency = TRUE
		INVOKE_ASYNC(lamp, TYPE_PROC_REF(/obj/machinery/light, update), FALSE)
	to_chat(owner, span_notice("Аварийное освещение макета отключено."))
	owner.playsound_local(owner, 'sound/effects/light_flicker.ogg', 50, FALSE)

/datum/AI_Module/small/reactivate_cameras/training
	training_only = TRUE
	description = "Восстанавливает до 30 отключённых камер станционного макета."
	power_type = /datum/action/innate/ai/reactivate_cameras/training

/datum/action/innate/ai/reactivate_cameras/training
	desc = "Восстанавливает отключённые камеры макета."

/datum/action/innate/ai/reactivate_cameras/training/Activate()
	var/fixed_cameras = 0
	for(var/obj/machinery/camera/camera as anything in GLOB.cameranet.cameras)
		if(!uses)
			break
		if(!antag_training_malf_reach(owner_AI, camera))
			continue
		if(!camera.status || camera.view_range != initial(camera.view_range))
			camera.toggle_cam(owner_AI, 0)
			camera.view_range = initial(camera.view_range)
			fixed_cameras++
			uses--
	to_chat(owner, span_notice("Диагностика завершена: восстановлено камер - [fixed_cameras], осталось восстановлений - [uses]."))
	owner.playsound_local(owner, 'sound/items/wirecutter.ogg', 50, FALSE)
	adjust_uses(0, TRUE)

/datum/AI_Module/large/upgrade_cameras/training
	training_only = TRUE
	description = "Защищает камеры станционного макета от ЭМИ и даёт им рентген, а вам - ночное зрение."

/datum/AI_Module/large/upgrade_cameras/training/upgrade(mob/living/silicon/ai/AI)
	AI.see_override = SEE_INVISIBLE_MINIMUM
	AI.update_sight()
	var/upgraded_cameras = 0
	for(var/obj/machinery/camera/camera as anything in GLOB.cameranet.cameras)
		if(!camera.assembly || !antag_training_malf_reach(AI, camera))
			continue
		var/upgraded = FALSE
		if(!camera.isXRay())
			camera.upgradeXRay()
			GLOB.cameranet.updateVisibility(camera, 0)
			upgraded = TRUE
		if(!camera.isEmpProof())
			camera.upgradeEmpProof()
			upgraded = TRUE
		if(upgraded)
			upgraded_cameras++
	unlock_text = replacetext(unlock_text, "CAMSUPGRADED", "<b>[upgraded_cameras]</b>")

#undef ANTAG_TRAINING_MALF_PROCESSING
#undef ANTAG_TRAINING_DOOMSDAY_TIMER
#undef ANTAG_TRAINING_DOOMSDAY_NOTICE
#undef ANTAG_TRAINING_LOCKDOWN_TIME
