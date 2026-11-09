#define SHOCK_COOLDOWN 3 SECONDS
#define HEALING_AURA_AMOUNT 2
#define HEALING_AURA_RANGE 5
#define FREE_SWARMER_SPAWN_TIMER 8 MINUTES

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
	var/last_mega_swarmer_spawn_value = 0
	var/free_spawn_timer
	var/mega_retry_timer
	var/mega_poll_active = FALSE
	var/recruit_poll_active = FALSE

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
	if((team.organic_resources - last_swarmer_spawn_value) < SWARMER_SPAWN_VALUE)
		return

	if((team.organic_resources - last_mega_swarmer_spawn_value) < MEGA_SWARMER_SPAWN_VALUE)
		last_swarmer_spawn_value = team.organic_resources
		INVOKE_ASYNC(src, PROC_REF(spawn_swarmer_from_ghost))
		return

	last_mega_swarmer_spawn_value = team.organic_resources
	if(!mega_poll_active && !mega_retry_timer)
		INVOKE_ASYNC(src, PROC_REF(spawn_mega_swarmer_from_ghost))

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
	var/list/mob/dead/observer/candidates = pollGhostCandidates("Хотите сыграть за свармера?", ROLE_ALIEN, null, 0, 15 SECONDS, POLL_IGNORE_SWARMER)
	recruit_poll_active = FALSE
	if(QDELETED(src) || QDELETED(team))
		return
	for(var/obj/effect/mob_spawn/swarmer/shell as anything in team.shells?.Copy())
		while(length(candidates))
			var/mob/dead/observer/candidate = pick_n_take(candidates)
			if(candidate?.client && candidate.can_reenter_round())
				shell.create(candidate.ckey)
				break

/obj/structure/swarmer/core/proc/spawn_mega_swarmer_from_ghost()
	mega_retry_timer = null
	if(mega_poll_active || QDELETED(src) || QDELETED(team))
		return
	mega_poll_active = TRUE
	var/list/mob/dead/observer/candidates = pollGhostCandidates("Хотите сыграть за мегасвармера?", ROLE_ALIEN, null, 0, 30 SECONDS, POLL_IGNORE_SWARMER)
	mega_poll_active = FALSE
	if(QDELETED(src) || QDELETED(team))
		return
	while(length(candidates))
		var/mob/dead/observer/candidate = pick_n_take(candidates)
		if(!candidate?.client || !candidate.can_reenter_round())
			continue
		var/mob/living/simple_animal/hostile/swarmer/mega/swarmer = new(get_turf(src), team)
		swarmer.key = candidate.key
		swarmer.add_datum_if_not_exist()
		team.on_mega_swarmer_spawn(swarmer)
		log_game("[key_name(swarmer)] получил роль мегасвармера.")
		return
	mega_retry_timer = addtimer(CALLBACK(src, PROC_REF(spawn_mega_swarmer_from_ghost)), 30 SECONDS, TIMER_STOPPABLE)

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
	data["classes"] = selection_classes
	return data

/obj/structure/swarmer/core/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	if(action != "select_class" || !isswarmer(ui.user))
		return

	var/mob/living/simple_animal/hostile/swarmer/old_swarmer = ui.user
	if(old_swarmer.team != team || !Adjacent(old_swarmer) || !old_swarmer.mind || old_swarmer.incapacitated())
		return
	var/confirm = tgui_alert(old_swarmer, "Вы уверены, что хотите выбрать данный класс?", "Выбор класса", list("Да", "Нет"))
	if(confirm != "Да" || QDELETED(src) || QDELETED(old_swarmer) || old_swarmer.team != team || !old_swarmer.mind || !old_swarmer.client || !Adjacent(old_swarmer) || old_swarmer.incapacitated())
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
			"icon" = "data:image/png;base64,[icon2base64(icon(swarmer::icon, swarmer::icon_state, SOUTH, 1))]",
			"path" = path,
			"additional_info" = swarmer::swarmer_class_info,
			"cost" = swarmer::swap_resource_cost,
		)
		selection_classes += list(new_class)

#undef SHOCK_COOLDOWN
#undef HEALING_AURA_AMOUNT
#undef HEALING_AURA_RANGE
#undef FREE_SWARMER_SPAWN_TIMER

/datum/armor/swarmer_core
	melee = 25
	bullet = 25
	laser = 25
	energy = 25
	bio = 100
	fire = 100
	acid = 100
