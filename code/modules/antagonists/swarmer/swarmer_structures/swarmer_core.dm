#define SHOCK_COOLDOWN 3 SECONDS
#define HEALING_AURA_AMOUNT 2
#define HEALING_AURA_RANGE 5
#define FREE_SWARMER_SPAWN_TIMER 8 MINUTES
#define SWARMER_LAMBDA_SOUND_DURATION 11 SECONDS
#define SWARMER_FINAL_PHASE_DURATION 6 MINUTES
#define SWARMER_FINAL_ANNOUNCE_INTERVAL 1 MINUTES
#define SWARMER_MEGA_POLL_INTERVAL 30 SECONDS
#define SWARMER_EVAC_ARRIVAL_TIME 3 MINUTES

/obj/structure/swarmer/core
	name = "swarmer core"
	desc = "Главное сооружение \"Свармеров\", которое являются связующим для всех остальных сооружений и созданий."
	icon_state = "swarmer_core"
	layer = ABOVE_ALL_MOB_LAYER
	max_integrity = 600
	armor_type = /datum/armor/swarmer_core
	var/static/list/selection_classes
	COOLDOWN_DECLARE(shock_cooldown)
	var/burn_damage = 15
	var/stamina_damage = 20
	var/datum/effect_system/spark_spread/spark_system
	var/last_swarmer_spawn_value = 0
	var/free_spawn_timer
	var/mega_retry_timer
	var/mega_poll_active = FALSE
	var/recruit_poll_active = FALSE
	var/mega_phase_started = FALSE
	var/mega_phase_deadline
	var/mega_phase_timer

/obj/structure/swarmer/core/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	if(!swarm_team)
		swarm_team = new /datum/team/swarmer_team
	. = ..()

	if(team?.swarmer_core)
		return INITIALIZE_HINT_QDEL

	team.on_core_init(src)
	if(!selection_classes)
		generate_class_selection()

	spark_system = new
	spark_system.set_up(3, 0, src)
	spark_system.attach(src)

	if(!team.training)
		free_spawn_timer = addtimer(CALLBACK(src, PROC_REF(spawn_swarmer_from_ghost)), FREE_SWARMER_SPAWN_TIMER, TIMER_LOOP | TIMER_STOPPABLE)
	COOLDOWN_START(src, shock_cooldown, SHOCK_COOLDOWN)

/obj/structure/swarmer/core/ComponentInitialize()
	AddComponent( \
		/datum/component/aura_healing, \
		range = HEALING_AURA_RANGE, \
		simple_heal = HEALING_AURA_AMOUNT, \
		limit_to_trait = TRAIT_HEALS_FROM_SWARMER_CORES, \
		healing_color = COLOR_BLUE, \
	)

/obj/structure/swarmer/core/Adjacent(atom/neighbor)
	var/turf/core_turf = loc
	var/mob/living/simple_animal/hostile/swarmer/swarmer = neighbor
	if(istype(core_turf) && istype(swarmer) && swarmer.team == team && isturf(swarmer.loc))
		return core_turf.Adjacent(swarmer, src, swarmer)
	return ..()

/obj/structure/swarmer/core/Destroy(force)
	if(free_spawn_timer)
		deltimer(free_spawn_timer)
	if(mega_retry_timer)
		deltimer(mega_retry_timer)
	if(mega_phase_timer)
		deltimer(mega_phase_timer)
	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)
	team?.on_core_destroy(src)
	QDEL_NULL(spark_system)
	return ..()

/obj/structure/swarmer/core/attack_hand(mob/living/user)
	. = ..()
	if(!.)
		return

	user.apply_damages(burn = burn_damage, stamina = stamina_damage * SWARMER_STAMINA_SCALE)
	if(!COOLDOWN_FINISHED(src, shock_cooldown))
		return

	COOLDOWN_START(src, shock_cooldown, SHOCK_COOLDOWN)
	if(user.electrocute_act(rand(5, 20), src))
		spark_system.start()

/obj/structure/swarmer/core/repair_damage(amount)
	. = ..()
	if(.)
		team?.update_core_stats()

/obj/structure/swarmer/core/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(!. || !isliving(user))
		return

	var/mob/living/target = user
	target.apply_damages(burn = burn_damage, stamina = stamina_damage * SWARMER_STAMINA_SCALE)
	if(!COOLDOWN_FINISHED(src, shock_cooldown))
		return

	COOLDOWN_START(src, shock_cooldown, SHOCK_COOLDOWN)
	if(target.electrocute_act(rand(5, 20), src))
		spark_system.start()

/obj/structure/swarmer/core/attack_generic(mob/user, damage_amount = 0, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, armor_penetration = 0)
	. = ..()
	if(!. || !isliving(user))
		return

	var/mob/living/target = user
	target.apply_damage(burn_damage, BURN)
	if(!COOLDOWN_FINISHED(src, shock_cooldown))
		return

	COOLDOWN_START(src, shock_cooldown, SHOCK_COOLDOWN)
	if(target.electrocute_act(rand(5, 20), src))
		spark_system.start()

/obj/structure/swarmer/core/proc/on_organic_changed()
	if(!mega_phase_started && team.organic_resources >= MEGA_SWARMER_SPAWN_VALUE && !mega_poll_active && !mega_retry_timer)
		mega_retry_timer = addtimer(CALLBACK(src, PROC_REF(spawn_mega_swarmer_from_ghost)), 1, TIMER_STOPPABLE)
		return

	if((team.organic_resources - last_swarmer_spawn_value) >= SWARMER_SPAWN_VALUE)
		last_swarmer_spawn_value = team.organic_resources
		INVOKE_ASYNC(src, PROC_REF(spawn_swarmer_from_ghost))

/obj/structure/swarmer/core/proc/spawn_swarmer_from_ghost()
	if(QDELETED(src) || QDELETED(team))
		return
	new /obj/effect/mob_spawn/swarmer(get_turf(src), team)
	recruit_initial_swarmers()

/obj/structure/swarmer/core/proc/recruit_initial_swarmers()
	set waitfor = FALSE
	if(recruit_poll_active || QDELETED(src) || QDELETED(team))
		return
	recruit_poll_active = TRUE
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in team.shells)
		shell.update_ghost_access()
	var/list/mob/dead/observer/candidates = poll_swarmer_ghosts()
	if(QDELETED(src) || QDELETED(team))
		return
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in team.shells?.Copy())
		if(QDELETED(shell) || !get_turf(shell))
			continue
		while(length(candidates))
			var/mob/dead/observer/candidate = pick_n_take(candidates)
			if(candidate?.client && candidate.can_reenter_round() && shell.create(candidate.ckey))
				break
	recruit_poll_active = FALSE
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in team.shells)
		shell.update_ghost_access()

/obj/structure/swarmer/core/proc/spawn_mega_swarmer_from_ghost()
	mega_retry_timer = null
	if(mega_poll_active || QDELETED(src) || QDELETED(team) || !SSticker.IsRoundInProgress())
		return
	mega_poll_active = TRUE
	var/next_poll_at = world.time + SWARMER_MEGA_POLL_INTERVAL
	var/list/mob/dead/observer/candidates = poll_swarmer_ghosts(mega = TRUE)
	mega_poll_active = FALSE
	if(QDELETED(src) || QDELETED(team) || !SSticker.IsRoundInProgress())
		return
	while(length(candidates))
		var/mob/dead/observer/candidate = pick_n_take(candidates)
		if(!candidate?.client || !candidate.can_reenter_round())
			continue
		var/mob/living/simple_animal/hostile/swarmer/mega/swarmer = new(get_turf(src), team)
		swarmer.key = candidate.key
		swarmer.add_datum_if_not_exist()
		log_game("[key_name(swarmer)] получил роль мегасвармера.")
		if(!mega_phase_started)
			prepare_mega_phase()
			return
		break
	mega_retry_timer = addtimer(CALLBACK(src, PROC_REF(spawn_mega_swarmer_from_ghost)), max(1, next_poll_at - world.time), TIMER_STOPPABLE)

/obj/structure/swarmer/core/proc/prepare_mega_phase()
	mega_phase_started = TRUE
	team.swarmer_objective.completed = TRUE
	if(GLOB.security_level == SEC_LEVEL_LAMBDA)
		start_mega_phase()
		return

	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(on_mega_lambda_active))
	SSsecurity_level.set_level(SEC_LEVEL_LAMBDA, bypass_keycard_lock = TRUE)

/obj/structure/swarmer/core/proc/on_mega_lambda_active(datum/source)
	SIGNAL_HANDLER
	if(GLOB.security_level != SEC_LEVEL_LAMBDA)
		return

	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)
	// Даём записи кода «Лямбда» доиграть перед следующим оповещением.
	mega_phase_timer = addtimer(CALLBACK(src, PROC_REF(start_mega_phase)), SWARMER_LAMBDA_SOUND_DURATION, TIMER_STOPPABLE)

/obj/structure/swarmer/core/proc/start_mega_phase()
	mega_phase_timer = null
	if(!SSticker.IsRoundInProgress())
		return

	mega_phase_deadline = world.time + SWARMER_FINAL_PHASE_DURATION
	var/area/core_area = get_area(src)
	var/core_location = core_area?.name || "неизвестна"
	var/time_left = DisplayTimeText(SWARMER_FINAL_PHASE_DURATION)
	priority_announce("Внимание! Обнаружена телепортация массивной боевой единицы роя. Ядро свармеров перешло в фазу подготовки к массовой телепортации. Немедленно уничтожьте ядро, пока не стало слишком поздно, локация: [core_location], время до полной активации: [time_left].", "Призыв мегасвармера", 'sound/announcer/classic/megaswarmer_teleportation.ogg')
	mega_phase_timer = addtimer(CALLBACK(src, PROC_REF(update_mega_phase)), SWARMER_FINAL_ANNOUNCE_INTERVAL, TIMER_STOPPABLE)

/obj/structure/swarmer/core/proc/update_mega_phase()
	mega_phase_timer = null
	if(!SSticker.IsRoundInProgress())
		return

	var/time_left = mega_phase_deadline - world.time
	if(time_left <= 0)
		var/obj/docking_port/mobile/emergency/shuttle = SSshuttle.emergency
		if(shuttle && (shuttle.mode != SHUTTLE_CALL || shuttle.timeLeft(1) > SWARMER_EVAC_ARRIVAL_TIME))
			SSshuttle.emergencyNoRecall = TRUE
			var/call_coefficient = SWARMER_EVAC_ARRIVAL_TIME / (SSshuttle.emergencyCallTime * shuttle.engine_coeff)
			shuttle.request(reason = " Причина: ядро свармеров начало массовую телепортацию.", set_coefficient = call_coefficient)
		INVOKE_ASYNC(src, PROC_REF(spawn_mega_swarmer_from_ghost))
		return

	var/area/core_area = get_area(src)
	var/core_location = core_area?.name || "неизвестна"
	minor_announce("До полной активации ядра свармеров осталось [DisplayTimeText(time_left)]. Текущее местоположение ядра: [core_location].", "Массовая телепортация роя", TRUE)
	mega_phase_timer = addtimer(CALLBACK(src, PROC_REF(update_mega_phase)), min(time_left, SWARMER_FINAL_ANNOUNCE_INTERVAL), TIMER_STOPPABLE)

/obj/structure/swarmer/core/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	swarmer.balloon_alert(swarmer, "это нельзя открутить!")

/obj/structure/swarmer/core/swarmer_harm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	swarmer.balloon_alert(swarmer, "это нельзя уничтожить!")

/obj/structure/swarmer/core/swarmer_help_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	. = ..()
	if(!.)
		return
	ui_interact(swarmer)

/obj/structure/swarmer/core/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SwarmerCore", "Выбор класса")
		ui.open()

/obj/structure/swarmer/core/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/swarmer/core/ui_data(mob/user)
	var/list/data = list()
	data["organic_resources"] = team.organic_resources
	data["metallic_resources"] = team.metallic_resources
	data["cheaper_swap"] = !is_basicswarmer(user)
	data["current_class_path"] = user.type
	return data

/obj/structure/swarmer/core/ui_static_data(mob/user)
	var/list/data = list()
	data["organic_goal"] = MEGA_SWARMER_SPAWN_VALUE
	data["metal_reference"] = SWARMER_STARTING_METAL
	data["classes"] = selection_classes
	return data

/obj/structure/swarmer/core/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	if(action != "select_class" || !isswarmer(ui.user))
		return

	var/mob/living/simple_animal/hostile/swarmer/old_swarmer = ui.user
	if(QDELETED(src) || QDELETED(old_swarmer) || old_swarmer.team != team || !old_swarmer.mind || !old_swarmer.client || !Adjacent(old_swarmer) || old_swarmer.incapacitated())
		return

	var/swarmer_path = text2path(params["class"])
	if(!ispath(swarmer_path, /mob/living/simple_animal/hostile/swarmer))
		message_admins("[old_swarmer.ckey] attempted to href exploit swarmer core swap into [swarmer_path]. This can't be a false alarm.")
		return

	var/mob/living/simple_animal/hostile/swarmer/new_swarmer = swarmer_path
	if(new_swarmer::can_swap_to == FALSE)
		message_admins("[old_swarmer.ckey] attempted to href exploit swarmer core swap into non-possible swarmer class. This can't be a false alarm.")
		return

	return swap_class(old_swarmer, swarmer_path)

/obj/structure/swarmer/core/proc/swap_class(mob/living/simple_animal/hostile/swarmer/old_swarmer, swarmer_path)
	var/mob/living/simple_animal/hostile/swarmer/new_swarmer = swarmer_path
	var/turf/spawn_turf = get_turf(old_swarmer)
	if(!ispath(swarmer_path, /mob/living/simple_animal/hostile/swarmer) || !new_swarmer::can_swap_to || !spawn_turf || old_swarmer.team != team || !old_swarmer.mind || old_swarmer.type == swarmer_path)
		return FALSE
	var/swap_cost = is_basicswarmer(old_swarmer) ? new_swarmer::swap_resource_cost : round(new_swarmer::swap_resource_cost / 2)// swarmer classes cost less on non-basic swap
	if(!team?.adjust_metal(-swap_cost))
		old_swarmer.balloon_alert(old_swarmer, "недостаточно ресурсов!")
		return

	new_swarmer = new swarmer_path(spawn_turf, team)
	new_swarmer.training_origin = old_swarmer.training_origin
	if(old_swarmer.mmi)
		old_swarmer.mmi.forceMove(new_swarmer)
		new_swarmer.mmi = old_swarmer.mmi
		old_swarmer.mmi = null

	new_swarmer.health *= old_swarmer.health / old_swarmer.maxHealth
	if(team.training)
		var/datum/antag_training_arena/arena = old_swarmer.training_origin?.resolve()
		var/datum/antag_training_session/session = arena?.session_of(old_swarmer)
		var/datum/antag_training_program/creature/swarmer/program = session?.program
		if(istype(program))
			program.body_ref = WEAKREF(new_swarmer)
	SStgui.close_user_uis(old_swarmer, src)
	old_swarmer.mind.transfer_to(new_swarmer)
	new_swarmer.balloon_alert(new_swarmer, "успех!")
	log_game("[key_name(new_swarmer)] сменил корпус на [new_swarmer.name].")
	spark_system.start()
	qdel(old_swarmer)
	return TRUE

/obj/structure/swarmer/core/proc/generate_class_selection()
	selection_classes = list()
	for(var/path in subtypesof(/mob/living/simple_animal/hostile/swarmer))
		var/mob/living/simple_animal/hostile/swarmer/swarmer = path
		if(swarmer::can_swap_to == FALSE)
			continue
		var/list/new_class = list(
			"name" = swarmer::name,
			"desc" = swarmer::desc,
			"icon" = "data:image/png;base64,[icon2base64(icon(swarmer::icon, swarmer::icon_state, SOUTH, 1, FALSE))]",
			"path" = path,
			"additional_info" = swarmer::swarmer_class_info,
			"cost" = swarmer::swap_resource_cost,
		)
		selection_classes += list(new_class)

#undef SHOCK_COOLDOWN
#undef HEALING_AURA_AMOUNT
#undef HEALING_AURA_RANGE
#undef FREE_SWARMER_SPAWN_TIMER
#undef SWARMER_LAMBDA_SOUND_DURATION
#undef SWARMER_FINAL_PHASE_DURATION
#undef SWARMER_FINAL_ANNOUNCE_INTERVAL
#undef SWARMER_MEGA_POLL_INTERVAL
#undef SWARMER_EVAC_ARRIVAL_TIME

/datum/armor/swarmer_core
	melee = 25
	bullet = 25 + SWARMER_BULLET_ARMOR_BONUS
	laser = 25 + SWARMER_LASER_ARMOR_BONUS
	energy = 25
	bio = 100
	fire = 100
	acid = 100
