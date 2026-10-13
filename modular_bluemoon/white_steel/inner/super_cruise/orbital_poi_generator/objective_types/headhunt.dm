//WHITE-STEEL PORT - упрощённая адаптация под bluemoon
/datum/orbital_objective/headhunt
	name = "Охота за головами"
	var/generated = FALSE
	var/objective_z_level
	var/mob/living/mob_to_recover
	var/obj/structure/closet/supplypod/extractionpod/extraction_pod
	//WHITE-STEEL PORT: статус экспедиционного шаттла относительно руины.
	var/frontier_shuttle_docked = FALSE
	var/frontier_shuttle_left = FALSE
	var/auto_return_triggered = FALSE
	var/objective_ended = FALSE
	min_payout = 225 * CARGO_CRATE_VALUE
	max_payout = 300 * CARGO_CRATE_VALUE

/datum/orbital_objective/headhunt/get_text()
	return "Требуется ликвидировать опасного преступника, скрывающегося на [station_name]. \
			Живым или мертвым, его необходимо доставить на мостик и отправить к вашему нанимателю с помощью предоставленной системы доставки. \
			Следует принять во внимание, что преступник может быть экипирован гораздо лучше обычного рейнджера. \
			Возможно, может потребоваться помощь сотрудников службы безопасности. \
			Задание будет провалено в случае побега преступника со станции живым и без наручников, или в случае уничтожения его тела, \
			а также если преступник продержится на руине до отлёта шаттла авангарда: подмога InteQ уже в пути!"

/datum/orbital_objective/headhunt/get_target()
	return mob_to_recover

/datum/orbital_objective/headhunt/Destroy()
	//WHITE-STEEL FIX: разрываем цепочку утечек вокруг преступника.
	//1) Моб был добавлен в GLOB.mob_spawners[real_name] и держался этим глобальным списком
	//   вечно — снимаем его.
	//2) Личная цель преступника (mind -> antag -> objective) хранила linked_objective = src,
	//   отчего живой моб удерживал удалённое задание. Обнуляем обратную ссылку.
	if(!QDELETED(mob_to_recover))
		var/target_name = mob_to_recover.real_name
		if(istext(target_name))
			LAZYREMOVE(GLOB.mob_spawners[target_name], mob_to_recover)
			if(!LAZYLEN(GLOB.mob_spawners[target_name]))
				GLOB.mob_spawners -= target_name
		if(mob_to_recover.mind)
			var/datum/antagonist/headhunt_survive/antag = mob_to_recover.mind.has_antag_datum(/datum/antagonist/headhunt_survive)
			if(antag)
				for(var/datum/objective/headhunt_survive/hunt_objective in antag.objectives)
					hunt_objective.linked_objective = null
	mob_to_recover = null
	extraction_pod = null
	return ..()

/datum/orbital_objective/headhunt/on_assign(obj/machinery/computer/objective/objective_computer)
	//WHITE-STEEL PORT: капсула должна прибывать на мостик шаттла к консоли заданий,
	//а не на мостик станции (/area/command). Повторяем логику nuke_ruin.
	var/turf/open/T
	var/area/A = get_area(objective_computer)
	if(A)
		var/list/pickable_turfs = A.get_unobstructed_turfs()
		if(length(pickable_turfs))
			T = pick(pickable_turfs)
	if(!T)
		T = get_turf(objective_computer)
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
	//WHITE-STEEL PORT: у преступника появляется личная цель — продержаться до подлёта подмоги.
	var/datum/antagonist/headhunt_survive/antag = created_human.mind.add_antag_datum(/datum/antagonist/headhunt_survive)
	for(var/datum/objective/headhunt_survive/hunt_objective in antag.objectives)
		hunt_objective.linked_objective = src
	//WHITE-STEEL PORT: объявляем призракам, что они могут занять роль преступника.
	LAZYADD(GLOB.mob_spawners[created_human.real_name], created_human)
	notify_ghosts("Охота за головами: преступник может быть занят.", source = created_human, action = NOTIFY_ORBIT, flashwindow = FALSE, ignore_key = POLL_IGNORE_HEADHUNT, ignore_dnr_observers = FALSE)
	created_human.AddElement(/datum/element/point_of_interest)
	for(var/mob/living/simple_animal/hostile/SA in range(10, created_human))
		qdel(SA)
	//Экипируем преступника набором InteQ Operative - Full Kit (без взрывного импланта).
	created_human.equipOutfit(/datum/outfit/inteq/full/expedition)
	//WHITE-STEEL PORT: растворение в скелет при побеге (свободном прибытии на станцию).
	created_human.AddComponent(/datum/component/headhunt_skeleton)
	//WHITE-STEEL PORT: преступника можно занять призраку — mind с целью сохраняется за телом.
	created_human.AddComponent(/datum/component/ghost_takeover, "преступника-нелегала", "Вы — нелегал, цель «Охота за головами»! Держитесь на руине, пока шаттл наёмников авангарда не улетит — подмога InteQ уже близко.")
	generated = TRUE

/datum/orbital_objective/headhunt/check_failed()
	if(objective_ended)
		return TRUE
	track_shuttle_state()
	if(generated)
		//WHITE-STEEL PORT: преступник схвачен и покинул руину вместе с шаттлом — охота успешно завершена.
		if(frontier_shuttle_left && !QDELETED(mob_to_recover) && mob_to_recover.stat != DEAD && is_restrained_target())
			objective_ended = TRUE
			complete_objective()
			return FALSE
		//WHITE-STEEL PORT: преступник продержался на руине до отлёта шаттла авангарда — победа преступника, задание провалено.
		if(frontier_shuttle_left && !QDELETED(mob_to_recover) && mob_to_recover.stat != DEAD && mob_to_recover.z == objective_z_level)
			complete_target_survive()
			objective_ended = TRUE
			return TRUE
		if(!mob_to_recover || QDELETED(mob_to_recover))
			. = TRUE
		else if(mob_to_recover.z != objective_z_level && mob_to_recover.stat != DEAD && !is_restrained_target())
			. = TRUE
	if(.)
		objective_ended = TRUE
		if(extraction_pod)
			extraction_pod.startExitSequence(extraction_pod)
		return
	//WHITE-STEEL PORT: авто-возврат шаттла на базу, если вся высадившаяся охотничья команда мертва.
	handle_auto_return()
	return FALSE

//WHITE-STEEL PORT: отслеживаем, когда экспедиционный шаттл покидает руину.
/datum/orbital_objective/headhunt/proc/track_shuttle_state()
	if(!generated || objective_ended)
		return
	var/obj/docking_port/mobile/exploration_dock = SSshuttle.getShuttle("exploration")
	if(exploration_dock && exploration_dock.z == objective_z_level)
		frontier_shuttle_docked = TRUE
	else if(frontier_shuttle_docked && !frontier_shuttle_left)
		frontier_shuttle_left = TRUE

//WHITE-STEEL PORT: цель преступника в наручниках (схвачен, а не победитель).
/datum/orbital_objective/headhunt/proc/is_restrained_target()
	if(!iscarbon(mob_to_recover))
		return FALSE
	var/mob/living/carbon/C = mob_to_recover
	return !!C.get_item_by_slot(ITEM_SLOT_HANDCUFFED)

//WHITE-STEEL PORT: авто-возврат шаттла на базовый порт, если все активные игроки станции на руине мертвы.
/datum/orbital_objective/headhunt/proc/handle_auto_return()
	if(!generated || objective_ended || auto_return_triggered || !frontier_shuttle_docked || frontier_shuttle_left)
		return
	var/obj/docking_port/mobile/exploration_dock = SSshuttle.getShuttle("exploration")
	if(!exploration_dock || exploration_dock.mode != SHUTTLE_IDLE || exploration_dock.z != objective_z_level)
		return
	//Считаем живых и подключённых игроков станции на руине (преступника игнорируем).
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H == mob_to_recover || H.z != objective_z_level || H.stat == DEAD || !H.mind || !H.client)
			continue
		return
	auto_return_triggered = TRUE
	log_game("Headhunt: вся охотничья команда мертва на руине (z=[objective_z_level]), шаттл авангарда возвращается на базу.")
	SSzclear.temp_keep_z(exploration_dock.z)
	var/obj/docking_port/stationary/home_port = SSshuttle.getDock("exploration_home")
	if(home_port)
		SSzclear.temp_keep_z(home_port.z)
	if(SSshuttle.moveShuttle("exploration", "exploration_home", 1) == 0)
		broadcast_auto_return()

//WHITE-STEEL PORT: сообщение об авто-возврате через общую рацию.
/datum/orbital_objective/headhunt/proc/broadcast_auto_return()
	for(var/obj/machinery/computer/shuttle_flight/exploration/console in GLOB.machines)
		console.speak_common("Потеряна связь с датчиками наёмников авангарда, возвращаюсь на станцию.")
		break

//WHITE-STEEL PORT: преступник продержался до отлёта шаттла — засчитываем его цель.
/datum/orbital_objective/headhunt/proc/complete_target_survive()
	if(QDELETED(mob_to_recover) || mob_to_recover.stat == DEAD || !mob_to_recover.mind)
		return
	var/datum/antagonist/headhunt_survive/antag = mob_to_recover.mind.has_antag_datum(/datum/antagonist/headhunt_survive)
	if(antag)
		for(var/datum/objective/headhunt_survive/hunt_objective in antag.objectives)
			hunt_objective.completed = TRUE
	to_chat(mob_to_recover, span_greentext("Шаттл наёмников авангарда покинул вашу локацию. Подмога InteQ уже близко — вы продержались!"))

//WHITE-STEEL PORT: экспедиционный вариант полного набора InteQ без взрывного импланта.
/datum/outfit/inteq/full/expedition
	give_explosive_implant = FALSE

//=====================
// Цель преступника: продержаться до подлёта подмоги
//=====================
//WHITE-STEEL PORT: личная цель преступника — остаться в живых, пока шаттл наёмников авангарда не покинет руину.
/datum/objective/headhunt_survive
	name = "Продержаться до подлёта подмоги"
	explanation_text = "Оставайтесь в живых на руине, пока шаттл наёмников авангарда не покинет вашу локацию. \
		Как только он улетит, подмога InteQ будет рядом."
	completable = TRUE
	var/datum/orbital_objective/headhunt/linked_objective

/datum/objective/headhunt_survive/check_completion()
	var/mob/living/L = owner?.current
	if(!L || L.stat == DEAD)
		return FALSE
	return !!linked_objective?.frontier_shuttle_left && L.z == linked_objective.objective_z_level

/datum/antagonist/headhunt_survive
	name = "Цель охоты"
	show_in_antagpanel = TRUE
	antagpanel_category = "Other"
	roundend_category = "Ruin VIPs"
	greentext_reward = 25
	antag_memory = "Вы — цель «Охоты за головами» наёмников авангарда. \
		Держитесь на руине и оставайтесь в живых до подлёта подмоги: как только шаттл наёмников \
		покинет вашу локацию, подмога InteQ будет рядом."

/datum/antagonist/headhunt_survive/on_gain()
	var/datum/objective/headhunt_survive/survive_objective = new
	survive_objective.owner = owner
	objectives += survive_objective
	. = ..()

/datum/antagonist/headhunt_survive/greet()
	to_chat(owner, span_boldnotice("[antag_memory]"))
	owner.announce_objectives()

//=====================
// Растворение нелегала при побеге
//=====================
//WHITE-STEEL PORT: нелегалу не суждено добраться до станции — если он прибывает туда живым и
//свободным (без наручников), его тело растворяется в скелет, а всё снаряжение выпадает на землю.
/datum/component/headhunt_skeleton
	var/dissolved = FALSE

/datum/component/headhunt_skeleton/Initialize()
	. = ..()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_target_moved))

/datum/component/headhunt_skeleton/proc/on_target_moved(datum/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(dissolved)
		return
	var/mob/living/carbon/C = parent
	if(C.stat == DEAD)
		return
	if(!SSmapping.level_trait(C.z, ZTRAIT_STATION))
		return
	//Прибыл в наручниках — это не побег, его ещё можно доставить.
	if(C.get_item_by_slot(ITEM_SLOT_HANDCUFFED))
		return
	dissolve(C)

/datum/component/headhunt_skeleton/proc/dissolve(mob/living/carbon/human/H)
	dissolved = TRUE
	H.visible_message(
		span_danger("[H] начинает растворяться, рассыпаясь в скелет!"),
		span_userdanger("Ваше тело растворяется в скелет: нелегалу не суждено достигнуть станции."),
	)
	//Всё снаряжение, включая содержимое сумок, вываливается на землю.
	for(var/obj/item/I in H.contents)
		SEND_SIGNAL(I, COMSIG_TRY_STORAGE_QUICK_EMPTY, get_turf(H))
	H.unequip_everything()
	//Тело превращается в скелет.
	H.set_species(/datum/species/skeleton)
	H.death(FALSE)

//=====================
// Захват тела призраком
//=====================
//WHITE-STEEL PORT: позволяет призраку занять роль существующего живого тела (нелегал, VIP и т.п.).
//Текущий mind тела (с его целями/антагом) сохраняется — переносится только ключ призрака.
/datum/component/ghost_takeover
	var/role_name
	var/takeover_message
	var/claimed = FALSE

/datum/component/ghost_takeover/Initialize(role_name, takeover_message)
	. = ..()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE
	src.role_name = role_name
	src.takeover_message = takeover_message
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_GHOST, PROC_REF(on_ghost_click))

/datum/component/ghost_takeover/proc/on_ghost_click(datum/source, mob/dead/observer/ghost)
	SIGNAL_HANDLER
	if(claimed)
		return
	var/mob/living/carbon/C = parent
	if(QDELETED(C) || C.stat == DEAD || C.key || C.client)
		return
	if(!istype(ghost) || !ghost.client || !SSticker.HasRoundStarted())
		return
	if(!ghost.can_reenter_round())
		to_chat(ghost, span_warning("Вы не можете занять эту роль: вы покинули раунд добровольно."))
		return
	if(tgui_alert(ghost, "Занять роль [role_name]? Это гост-роль — ваш текущий персонаж будет потерян!", "Гост-роль", list("Да", "Нет")) != "Да")
		return
	if(claimed || QDELETED(C) || C.stat == DEAD || C.key || C.client || QDELETED(ghost) || !ghost.client)
		return
	claimed = TRUE
	log_game("Ghost takeover: [key_name(ghost)] занял роль [role_name] ([REF(C)])")
	ghost.transfer_ckey(C, FALSE)
	C.client?.init_verbs()
	if(takeover_message)
		to_chat(C, span_boldnotice(takeover_message))
	return COMPONENT_NO_ATTACK_HAND