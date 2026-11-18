/datum/AI_Module/large/drone_factory
	module_name = "Фабрика дронов"
	mod_pick_name = "dronefactory"
	description = "Позволяет установить фабрику, производящую боевых или разведывательных дронов."
	cost = 50
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/place_drone_factory
	unlock_text = "<span class='notice'>Вы заказали фабрику дронов. Выберите тайл под камерой для её установки.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/AI_Module/small/combat_drone
	module_name = "Боевой дрон"
	mod_pick_name = "combatdrone"
	description = "Создаёт одного боевого дрона у ближайшей фабрики в пределах 6 тайлов от глаза ИИ. Покупку можно повторять."
	cost = 10
	power_type = /datum/action/innate/ai/buy_combat_drone
	unlock_text = "<span class='notice'>Модуль боевого дрона загружен. Активация создаст одного дрона у ближайшей фабрики рядом с глазом ИИ.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/action/innate/ai/buy_combat_drone
	name = "Создать боевого дрона"
	desc = "Создаёт одного боевого дрона у ближайшей фабрики, рядом с которой находится глаз ИИ."
	uses = 1
	auto_use_uses = FALSE

/datum/action/innate/ai/buy_combat_drone/Activate()
	if(!owner_AI || QDELETED(owner_AI))
		return FALSE
	if(!owner_AI.eyeobj)
		to_chat(owner_AI, span_warning("Для выпуска боевого дрона необходимо активное глазное устройство ИИ."))
		return FALSE

	var/turf/eye_turf = get_turf(owner_AI.eyeobj)
	if(!eye_turf)
		to_chat(owner_AI, span_warning("Невозможно определить положение глаза ИИ."))
		return FALSE

	var/obj/machinery/malf_drone_factory/nearest_factory
	var/nearest_distance = 7
	for(var/obj/machinery/malf_drone_factory/factory in GLOB.machines)
		if(QDELETED(factory) || factory.owner_AI != owner_AI || factory.machine_stat & BROKEN)
			continue
		var/turf/candidate_factory_turf = get_turf(factory)
		if(!candidate_factory_turf || candidate_factory_turf.z != eye_turf.z)
			continue
		var/distance = get_dist(eye_turf, candidate_factory_turf)
		if(distance > 6 || distance >= nearest_distance)
			continue
		nearest_factory = factory
		nearest_distance = distance

	if(!nearest_factory)
		to_chat(owner_AI, span_warning("Для выпуска дрона разместите глаз ИИ не дальше 6 тайлов от исправной фабрики дронов."))
		return FALSE

	var/turf/spawn_origin = get_turf(nearest_factory)
	var/turf/spawn_turf
	for(var/direction in list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
		var/turf/candidate = get_step(spawn_origin, direction)
		if(!isfloorturf(candidate))
			continue
		var/blocked = FALSE
		for(var/atom/movable/movable_atom in candidate)
			if(movable_atom.density)
				blocked = TRUE
				break
		if(!blocked)
			spawn_turf = candidate
			break

	if(!spawn_turf)
		to_chat(owner_AI, span_warning("Рядом с ближайшей фабрикой нет свободного места для боевого дрона."))
		return FALSE

	new /mob/living/simple_animal/hostile/malf_drone/factory(spawn_turf)
	playsound(spawn_turf, 'sound/effects/phasein.ogg', 100, TRUE)
	adjust_uses(-1)
	return TRUE

/datum/action/innate/ai/place_drone_factory
	name = "Установить фабрику дронов"
	desc = "Устанавливает фабрику дронов на открытый пол под текущей камерой."
	button_icon_state = "robotic_factory"
	uses = 1
	auto_use_uses = FALSE

/datum/action/innate/ai/place_drone_factory/Activate()
	if(!owner_AI || !owner_AI.can_place_drone_factory())
		return
	if(alert(owner, "Установить фабрику дронов здесь?", "Подтверждение установки", "Да", "Нет") != "Да")
		return
	if(!owner_AI || !owner_AI.can_place_drone_factory())
		return

	var/turf/placement_turf = get_turf(owner_AI.eyeobj)
	new /obj/machinery/malf_drone_factory(placement_turf, owner_AI)
	playsound(placement_turf, 'sound/effects/phasein.ogg', 100, TRUE)
	adjust_uses(-1)

/mob/living/silicon/ai/proc/can_place_drone_factory()
	if(!eyeobj || incapacitated())
		return FALSE

	var/turf/placement_turf = get_turf(eyeobj)
	if(!isfloorturf(placement_turf))
		to_chat(src, span_warning("Фабрику можно установить только на открытый пол."))
		return FALSE

	var/datum/camerachunk/camera_chunk = GLOB.cameranet.getCameraChunk(placement_turf.x, placement_turf.y, placement_turf.z)
	if(!camera_chunk || !camera_chunk.visibleTurfs[placement_turf])
		to_chat(src, span_warning("Камера не видит выбранный тайл."))
		return FALSE

	var/valid_distance = FALSE
	var/turf/ai_turf = get_turf(src)
	if(isturf(loc) && ai_turf && ai_turf.z == placement_turf.z && get_dist(ai_turf, placement_turf) <= 6)
		valid_distance = TRUE
	else
		var/mob/living/silicon/ai/base_ai = parent || src
		for(var/obj/machinery/power/apc/apc in GLOB.apcs_list)
			if(!apc.malfhack || apc.malfai != base_ai)
				continue
			var/turf/apc_turf = get_turf(apc)
			if(apc_turf.z == placement_turf.z && get_dist(apc_turf, placement_turf) <= 3)
				valid_distance = TRUE
				break
	if(!valid_distance)
		to_chat(src, span_warning("Фабрику можно установить не дальше 6 тайлов от ядра ИИ или 3 тайлов от взломанного вами АПЦ."))
		return FALSE

	for(var/atom/movable/movable_atom in placement_turf)
		if(movable_atom.density)
			to_chat(src, span_warning("Для установки фабрики освободите выбранный тайл."))
			return FALSE
	return TRUE

/obj/machinery/malf_drone_factory
	name = "фабрика дронов"
	desc = "Автономная фабрика, производящая разведывательных дронов. Ограничение — три активных дрона."
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "fab_robot"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	max_integrity = 250
	interaction_flags_machine = NONE

	var/mob/living/silicon/ai/owner_AI
	var/next_production = 0
	var/production_interval = 80
	var/max_drones = 3
	var/list/produced_drones = list()

/obj/machinery/malf_drone_factory/Initialize(mapload, mob/living/silicon/ai/creator)
	. = ..()
	owner_AI = creator

/obj/machinery/malf_drone_factory/Destroy()
	produced_drones = null
	owner_AI = null
	return ..()

/obj/machinery/malf_drone_factory/process()
	if(machine_stat & BROKEN)
		return

	for(var/mob/living/simple_animal/drone in produced_drones)
		if(QDELETED(drone) || drone.stat == DEAD)
			produced_drones -= drone

	if(length(produced_drones) >= max_drones || next_production > world.time)
		return

	var/mob/living/simple_animal/new_drone = new /mob/living/simple_animal/hostile/viscerator/malf_scout(loc)
	produced_drones += new_drone
	next_production = world.time + production_interval
	visible_message(span_notice("[src] заканчивает сборку [new_drone]."))

/mob/living/simple_animal/hostile/malf_drone/factory
	name = "Combat Drone"
	desc = "A ranged combat drone manufactured by a malfunctioning AI."
	initial_language_holder = /datum/language_holder/drone
	speech_span = SPAN_ROBOT
	gold_core_spawnable = NO_SPAWN
	playable_by_ghost = TRUE
	AIStatus = AI_OFF
	can_have_ai = FALSE
	faction = list("silicon", "malf_drone")

/mob/living/simple_animal/hostile/malf_drone/factory/Initialize(mapload)
	. = ..()
	name = "[initial(name)] ([rand(100, 999)])"
	real_name = name
	grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)
	new /obj/effect/mob_spawn/malf_drone(src, src)

/mob/living/simple_animal/hostile/malf_drone/factory/binarycheck()
	return TRUE

/mob/living/simple_animal/hostile/malf_drone/factory/attack_ghost(mob/user)
	var/obj/effect/mob_spawn/malf_drone/spawner = locate() in contents
	if(spawner?.ghost_usable)
		return spawner.attack_ghost(user)
	return ..()

/mob/living/simple_animal/hostile/viscerator/malf_scout
	name = "Viscerator"
	desc = "A fast robotic scout with access to ordinary doors. It cannot attack."
	initial_language_holder = /datum/language_holder/drone
	speech_span = SPAN_ROBOT
	gold_core_spawnable = NO_SPAWN
	playable_by_ghost = TRUE
	faction = list("silicon", "malf_drone")
	speed = -1
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	a_intent = INTENT_HELP
	possible_a_intents = list(INTENT_HELP)
	access_card = /obj/item/card/id

/mob/living/simple_animal/hostile/viscerator/malf_scout/Initialize(mapload)
	. = ..()
	name = "[initial(name)] ([rand(100, 999)])"
	real_name = name
	grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)
	access_card = new access_card(src)
	var/datum/job/captain/captain_job = new /datum/job/captain
	access_card.access = captain_job.get_access()
	qdel(captain_job)
	ADD_TRAIT(access_card, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)
	if(ai_controller)
		ai_controller.set_blackboard_key(BB_AI_TARGETING_STRATEGY, /datum/targeting_strategy/malf_drone_scout)
	new /obj/effect/mob_spawn/malf_drone(src, src)

/mob/living/simple_animal/hostile/viscerator/malf_scout/binarycheck()
	return TRUE

/mob/living/simple_animal/hostile/viscerator/malf_scout/attack_ghost(mob/user)
	var/obj/effect/mob_spawn/malf_drone/spawner = locate() in contents
	if(spawner?.ghost_usable)
		return spawner.attack_ghost(user)
	return ..()

/datum/targeting_strategy/malf_drone_scout/can_attack(mob/living/living_mob, atom/target, vision_range)
	return FALSE

/obj/effect/mob_spawn/malf_drone
	name = "Malfunctioning Drone"
	desc = "An unoccupied drone available for control."
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	anchored = FALSE
	death = FALSE
	roundstart = FALSE
	show_flavour = FALSE
	job_description = "Malfunctioning Drone"
	banType = ROLE_GHOSTROLE
	ghost_usable = FALSE
	var/claiming = FALSE

/obj/effect/mob_spawn/malf_drone/Initialize(mapload, mob/living/simple_animal/hostile/drone_body)
	if(!drone_body || QDELETED(drone_body))
		return INITIALIZE_HINT_QDEL

	name = drone_body.name
	mob_name = drone_body.real_name
	mob_type = drone_body.type
	. = ..()
	RegisterSignal(drone_body, list(COMSIG_MOB_CLIENT_LOGIN, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(update_ghost_access))
	update_ghost_access()
	INVOKE_ASYNC(src, PROC_REF(offer_to_ghosts))

/obj/effect/mob_spawn/malf_drone/Destroy()
	if(ismob(loc))
		UnregisterSignal(loc, list(COMSIG_MOB_CLIENT_LOGIN, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	return ..()

/obj/effect/mob_spawn/malf_drone/proc/body_available()
	var/mob/living/simple_animal/hostile/drone_body = loc
	return istype(drone_body) && !QDELETED(drone_body) && drone_body.stat != DEAD && !drone_body.key && !drone_body.client && SSticker.IsRoundInProgress()

/obj/effect/mob_spawn/malf_drone/proc/update_ghost_access()
	SIGNAL_HANDLER
	var/available = !QDELETED(src) && body_available()
	if(ghost_usable == available)
		return
	ghost_usable = available
	var/job_name = job_description ? job_description : name
	if(available)
		GLOB.poi_list |= src
		LAZYADD(GLOB.mob_spawners[job_name], src)
	else
		GLOB.poi_list -= src
		LAZYREMOVE(GLOB.mob_spawners[job_name], src)
		if(!LAZYLEN(GLOB.mob_spawners[job_name]))
			GLOB.mob_spawners -= job_name

/obj/effect/mob_spawn/malf_drone/proc/offer_to_ghosts()
	if(QDELETED(src) || !body_available())
		return
	var/mob/living/simple_animal/hostile/drone_body = loc
	var/list/mob/dead/observer/candidates = pollGhostCandidates(
		"Хотите сыграть за [mob_name]?",
		ROLE_GHOSTROLE,
		null,
		poll_time = 10 SECONDS,
		priority_check = FALSE,
		poll_header = mob_name,
		poll_alert_pic = mutable_appearance(drone_body.icon, drone_body.icon_state)
	)
	if(QDELETED(src) || !body_available())
		return
	while(length(candidates))
		var/mob/dead/observer/candidate = pick_n_take(candidates)
		if(candidate?.client && candidate.can_reenter_round() && create(candidate.ckey))
			return

/obj/effect/mob_spawn/malf_drone/attack_ghost(mob/user, latejoinercalling)
	if(!SSticker.HasRoundStarted() || !ghost_usable || !allow_spawn(user))
		return
	return ..()

/obj/effect/mob_spawn/malf_drone/allow_spawn(mob/user, silent = FALSE)
	return isobserver(user) && body_available() && !claiming

/obj/effect/mob_spawn/malf_drone/can_latejoin()
	return FALSE

/obj/effect/mob_spawn/malf_drone/create(ckey, name, load_character, spawn_type)
	if(QDELETED(src) || !ckey || claiming || !body_available())
		return
	claiming = TRUE
	return ..()

/obj/effect/mob_spawn/malf_drone/create_body(mob_path)
	return loc
