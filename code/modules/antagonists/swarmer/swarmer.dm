#define SWARMER_CARBON_MOB_TELEPORT_REWARD 5

/mob/living/simple_animal/hostile/swarmer
	name = "Swarmer"
	desc = "Свармер — автономная единица роя."
	icon = 'icons/mob/swarmer.dmi'
	icon_state = "swarmer_old"
	icon_living = "swarmer_old"
	health = 45
	maxHealth = 45
	status_flags = CANPUSH
	speak_emote = list("гудит")
	bubble_icon = "swarmer"
	mob_size = MOB_SIZE_SMALL
	melee_damage_type = STAMINA
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	hud_possible = list(ANTAG_HUD, DIAG_STAT_HUD, DIAG_HUD)
	obj_damage = 0
	faction = list(ROLE_SWARMER)
	AIStatus = AI_OFF
	wander = 0
	attack_sound = 'sound/effects/empulse.ogg'
	deathmessage = "взрывается с резким хлопком!"
	del_on_death = 1
	loot = list(/obj/effect/decal/cleanable/robot_debris, /obj/item/stack/ore/bluespace_crystal)
	light_color = LIGHT_COLOR_CYAN
	light_range = 3
	light_on = FALSE
	lighting_alpha = LIGHTING_PLANE_ALPHA_NV_TRAIT
	see_in_dark = 8
	hud_type = /datum/hud/swarmer
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 0
	minbodytemp = 0
	maxbodytemp = INFINITY
	move_force = MOVE_FORCE_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	pressure_resistance = 100
	possible_a_intents = list(INTENT_HELP, INTENT_DISARM, INTENT_GRAB, INTENT_HARM)
	simple_mob_flags = SIMPLE_MOB_PROJECTILE_ARMOR
	ranged_message = null
	ranged_ignores_vision = TRUE
	ranged_pixel_aim = TRUE
	blood_volume = 0
	var/swarmer_class_info = "Вы не должны это видеть."
	var/dismantle_speed = NORMAL_SWARMER_DISMANTLE_DELAY
	var/stack_extract_amount = 3
	var/swap_resource_cost = 0
	var/can_swap_to = FALSE
	var/datum/team/swarmer_team/team
	var/datum/effect_system/spark_spread/spark_system
	var/obj/item/mmi/mmi
	var/sliding_under_doors = FALSE
	var/list/datum/action/swarmer_actions = list()
	var/datum/weakref/object_attack_target
	var/object_attack_timer
	var/object_attack_consumes = FALSE
	var/secondary_weapon_hint
	var/datum/action/cooldown/swarmer/consume_tile/active_tile_attack
	COOLDOWN_DECLARE(damage_sparks_cooldown)

/mob/living/simple_animal/hostile/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	join_swarm(swarm_team)
	spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	grant_language(/datum/language/swarmer)
	ADD_TRAIT(src, TRAIT_NEGATES_GRAVITY, INNATE_TRAIT)

	var/datum/atom_hud/data/diagnostic/diag_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
	diag_hud?.add_hud_to(src)
	diag_hud?.add_to_hud(src)
	diag_hud_set_swarmerhealth()
	diag_hud_set_swarmerstat()

	for(var/action_type in GLOB.common_swarmer_actions)
		grant_swarmer_action(action_type)
	for(var/action_type in GLOB.swarmer_actions_by_type[type])
		grant_swarmer_action(action_type)

/mob/living/simple_animal/hostile/swarmer/proc/grant_swarmer_action(action_type)
	var/datum/action/action = new action_type
	swarmer_actions += action
	action.Grant(src)

/mob/living/simple_animal/hostile/swarmer/proc/join_swarm(datum/team/swarmer_team/swarm_team)
	if(team == swarm_team)
		return
	if(team)
		LAZYREMOVE(team.bodies, src)
	team = swarm_team
	if(team)
		LAZYADD(team.bodies, src)
	var/datum/hud/swarmer/swarmer_hud = hud_used
	if(istype(swarmer_hud))
		swarmer_hud.update_core_arrow()
		swarmer_hud.update_core_stats()

/mob/living/simple_animal/hostile/swarmer/set_hud_used(datum/hud/new_hud)
	if(hud_used == new_hud)
		return ..()
	var/datum/hud/swarmer/previous_hud = hud_used
	if(istype(previous_hud))
		previous_hud.detach_core_tracking()
	var/datum/action/cooldown/swarmer/consume_tile/selection = click_intercept
	if(istype(selection))
		selection.cancel()
	active_tile_attack?.stop()
	. = ..()
	var/datum/hud/swarmer/current_hud = hud_used
	if(istype(current_hud))
		current_hud.attach_core_tracking()

/mob/living/simple_animal/hostile/swarmer/proc/add_datum_if_not_exist()
	if(mind && team && !mind.has_antag_datum(/datum/antagonist/swarmer))
		mind.add_antag_datum(/datum/antagonist/swarmer, team)

/mob/living/simple_animal/hostile/swarmer/med_hud_set_health()
	return diag_hud_set_swarmerhealth()

/mob/living/simple_animal/hostile/swarmer/med_hud_set_status()
	return diag_hud_set_swarmerstat()

/mob/living/simple_animal/hostile/swarmer/proc/diag_hud_set_swarmerhealth()
	if(stat == DEAD)
		set_hud_image_state(DIAG_HUD, "huddiagdead")
	else
		set_hud_image_state(DIAG_HUD, "huddiag[RoundDiagBar(health/maxHealth)]")

/mob/living/simple_animal/hostile/swarmer/proc/diag_hud_set_swarmerstat()
	if(stat == DEAD)
		set_hud_image_state(DIAG_STAT_HUD, "huddead2")
	else if(stat == UNCONSCIOUS)
		set_hud_image_state(DIAG_STAT_HUD, "hudoffline")
	else
		set_hud_image_state(DIAG_STAT_HUD, "hudstat")

/mob/living/simple_animal/hostile/swarmer/Destroy()
	stop_object_attack()
	QDEL_LIST(swarmer_actions)
	if(team)
		LAZYREMOVE(team.bodies, src)
	QDEL_NULL(spark_system)
	var/datum/atom_hud/data/diagnostic/diag_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
	diag_hud?.remove_hud_from(src, TRUE)
	team = null
	handle_mmi_on_destroy()
	return ..()

/mob/living/simple_animal/hostile/swarmer/proc/handle_mmi_on_destroy()
	if(QDELETED(mmi))
		return
	if(!mind || QDELETED(mmi.brainmob))
		mmi.forceMove(get_turf(src))
		mmi = null
		return

	mind.remove_antag_datum(/datum/antagonist/swarmer)
	mind.transfer_to(mmi.brainmob)
	mmi.forceMove(get_turf(src))
	mmi = null

/mob/living/simple_animal/hostile/swarmer/death(gibbed)
	spark_system.start()
	return ..()

/mob/living/simple_animal/hostile/swarmer/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	var/previous_damage = bruteloss
	. = ..()
	if(bruteloss > previous_damage && stat != DEAD && COOLDOWN_FINISHED(src, damage_sparks_cooldown))
		COOLDOWN_START(src, damage_sparks_cooldown, 2 SECONDS)
		spark_system?.start()

/mob/living/simple_animal/hostile/swarmer/get_status_tab_items()
	. = ..()
	. += "Металл в ядре: [round(team?.metallic_resources || 0, 0.01)]"
	. += "Органика в ядре: [round(team?.organic_resources || 0, 0.01)]"
	if(team?.swarmer_core)
		. += "Здоровье ядра: [team.swarmer_core.obj_integrity]/[team.swarmer_core.max_integrity]"
	if(team)
		. += "Штурмовые турели: [team.get_structure_limit_status(/obj/machinery/porta_turret/swarmer/turret)]"
		. += "Снайперские турели: [team.get_structure_limit_status(/obj/machinery/porta_turret/swarmer/sniper)]"
		. += "Установки ACP: [team.get_structure_limit_status(/obj/structure/swarmer/acp_turret)]"
		. += "Ремонтные станции: [team.get_structure_limit_status(/obj/structure/swarmer/repair_station)]"

/mob/living/simple_animal/hostile/swarmer/emp_act(severity)
	..()
	adjustHealth(SWARMER_MOB_EMP_DAMAGE(severity), forced = TRUE)

/mob/living/simple_animal/hostile/swarmer/electrocute_act(shock_damage, atom/source, siemens_coeff = 1, flags = NONE, jitter_time = 10 SECONDS, stutter_time = 6 SECONDS, stun_duration = 4 SECONDS)
	if(!(flags & SHOCK_TESLA))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/swarmer/get_ear_protection()
	return INFINITY

/mob/living/simple_animal/hostile/swarmer/getarmor(def_zone, type)
	switch(type)
		if(BULLET)
			return SWARMER_BULLET_ARMOR_BONUS
		if(LASER)
			return SWARMER_LASER_ARMOR_BONUS
	return ..()

/mob/living/simple_animal/hostile/swarmer/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_swarmerprojectile(mover))
		return TRUE

/mob/living/simple_animal/hostile/swarmer/AttackingTarget()
	active_tile_attack?.stop()
	if(isswarmer(target))
		return FALSE

	if(a_intent == INTENT_GRAB)
		pulled(target)
		return TRUE

	. = ..()
	if(!. || !isliving(target) || ishuman(target))
		return

	var/mob/living/difficult_target = target
	var/damage = rand(melee_damage_lower, melee_damage_upper) / SWARMER_STAMINA_SCALE
	difficult_target.apply_damage(damage, BURN, blocked = difficult_target.getarmor(null, MELEE))

/mob/living/simple_animal/hostile/swarmer/UnarmedAttack(atom/A, proximity, intent = a_intent, flags = NONE)
	if(proximity && isopenturf(A) && A != loc)
		for(var/mob/living/victim in A)
			if(victim.stat == DEAD || isswarmer(victim) || victim.invisibility > see_invisible || victim.IsObscured() || !Adjacent(victim))
				continue
			. = ..(victim, proximity, intent, flags)
			if(!(. & NO_AUTO_CLICKDELAY_HANDLING))
				DelayNextAction(CLICK_CD_MELEE)
			return
	if(training_origin && A != src && (!isswarmer(A) && !is_swarmer_object(A)) && training_refuses(A))
		return
	if(proximity && handle_swarmer_act(A, proximity, null))
		return
	return ..()

/mob/living/simple_animal/hostile/swarmer/AltUnarmedAttack(atom/A, proximity_flag)
	if(secondary_weapon_hint)
		fire_secondary_weapon(A)
		return TRUE
	return use_swarmer_secondary_interaction(A, proximity_flag)

/mob/living/simple_animal/hostile/swarmer/proc/use_swarmer_secondary_interaction(atom/A, proximity_flag)
	if(!proximity_flag || !team?.swarmer_core || !CheckActionCooldown(immediate = TRUE))
		return TRUE
	if(training_origin && isliving(A) && A != src && !isswarmer(A))
		training_disperse(A)
		return TRUE
	return A.attack_swarmer_secondary(src)

/mob/living/simple_animal/hostile/swarmer/AltRangedAttack(atom/A, params)
	if(secondary_weapon_hint)
		fire_secondary_weapon(A, params)
		return TRUE
	if(isliving(A))
		balloon_alert(src, "подойдите ближе!")
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/swarmer/CtrlClickOn(atom/A)
	if(isliving(A) && A != src && Adjacent(A) && !incapacitated() && team?.swarmer_core)
		return use_swarmer_secondary_interaction(A, TRUE)
	return ..()

/mob/living/simple_animal/hostile/swarmer/right_click_needs_clicks()
	return secondary_weapon_hint || ..()

/mob/living/simple_animal/hostile/swarmer/right_click_map_clicks(shift)
	return (!shift && secondary_weapon_hint) || ..()

/mob/living/simple_animal/hostile/swarmer/proc/fire_secondary_weapon(atom/targeted_atom, params)
	return

/mob/living/simple_animal/hostile/swarmer/shoot_with_projectile(atom/targeted_atom, projectile_type, params)
	. = ..()
	if(.)
		active_tile_attack?.stop()

/atom/proc/attack_swarmer_secondary(mob/living/simple_animal/hostile/swarmer/user)
	return FALSE

/mob/living/collect_screentip_context(mob/living/user, obj/item/held_item, list/context)
	. = ..()
	var/mob/living/simple_animal/hostile/swarmer/swarmer = user
	if(!istype(swarmer) || !swarmer.team?.swarmer_core)
		return
	if(isswarmer(src))
		return
	var/secondary_hint = "Отправить в анализатор или телепортировать"
	if(iscyborg(src) && !swarmer.training_origin)
		secondary_hint = "Пересобрать в свармера"
	else if(swarmer.training_origin)
		secondary_hint = "Телепортировать"
	LAZYSET(context[SCREENTIP_CONTEXT_RMB], INTENT_ANY, swarmer.secondary_weapon_hint || secondary_hint)
	LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, secondary_hint)
	return . | CONTEXTUAL_SCREENTIP_SET

/mob/living/simple_animal/hostile/swarmer/proc/handle_swarmer_act(atom/atom, proximity_flag, list/modifiers)
	. = COMPONENT_CANCEL_ATTACK_CHAIN
	var/swarmer_act_result = atom.swarmer_act(src)
	if(swarmer_act_result & SWARMER_ACT_RIGHT_CLICK_DEFAULT)
		if(LAZYACCESS(modifiers, RIGHT_CLICK))
			return FALSE

	if(swarmer_act_result & SWARMER_ACT_POSSIBLE)
		return handle_possible_swarmer_act(atom, swarmer_act_result, proximity_flag, modifiers)

	if(swarmer_act_result & SWARMER_ACT_IMPOSSIBLE)
		return handle_impossible_swarmer_act(atom, swarmer_act_result, proximity_flag, modifiers)

	stack_trace("Swarmer act was called without either of the two main flags. Atom called on: [atom.type], act return value: [swarmer_act_result].")

/mob/living/simple_animal/hostile/swarmer/proc/handle_impossible_swarmer_act(atom/atom, swarmer_act_result, proximity_flag, list/modifiers)
	. = COMPONENT_CANCEL_ATTACK_CHAIN
	if(swarmer_act_result & SWARMER_ACT_IMPOSSIBLE_REASON_DEFAULT)
		return FALSE

	DelayNextAction(CLICK_CD_MELEE)
	if(swarmer_act_result == SWARMER_ACT_IMPOSSIBLE)
		balloon_alert(src, "нельзя!")
		return

	if(swarmer_act_result & SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE)
		return

	if(swarmer_act_result & SWARMER_ACT_IMPOSSIBLE_REASON_ENERGY)
		balloon_alert(src, "повредит электроэнергию!")
	else if(swarmer_act_result & SWARMER_ACT_IMPOSSIBLE_REASON_LIVING)
		balloon_alert(src, "повредит жизни экипажа!")
	else if(swarmer_act_result & SWARMER_ACT_IMPOSSIBLE_REASON_ATMOS)
		balloon_alert(src, "повредит системе воздуха!")
	else if(swarmer_act_result & SWARMER_ACT_IMPOSSIBLE_REASON_TEAM)
		balloon_alert(src, "повредит команде!")

/mob/living/simple_animal/hostile/swarmer/proc/handle_possible_swarmer_act(atom/atom, swarmer_act_result, proximity_flag, list/modifiers)
	. = COMPONENT_CANCEL_ATTACK_CHAIN
	if(swarmer_act_result == SWARMER_ACT_POSSIBLE)
		CRASH("Swarmer act returned only SWARMER_ACT_POSSIBLE flag, which should not happen. Atom: [atom.type].")

	if((swarmer_act_result & (SWARMER_ACT_POSSIBLE_ACTION_DAMAGE | SWARMER_ACT_POSSIBLE_ACTION_CONSUME)) && object_attack_target?.resolve() == atom)
		return

	if(swarmer_act_result & SWARMER_ACT_POSSIBLE_ACTION_PROCESS_ORGANIC)
		process_organic(atom)
		DelayNextAction(CLICK_CD_MELEE)
		return
	DelayNextAction(CLICK_CD_MELEE)
	if(!can_disassemble(atom))
		return

	if(swarmer_act_result & SWARMER_ACT_POSSIBLE_ACTION_DAMAGE)
		start_object_attack(atom)
	else if(swarmer_act_result & SWARMER_ACT_POSSIBLE_ACTION_CONSUME)
		start_object_attack(atom, consume = TRUE)
	else if(swarmer_act_result & SWARMER_ACT_POSSIBLE_ACTION_DISMANTLE)
		dismantle_machine(atom)
	else if(swarmer_act_result & SWARMER_ACT_POSSIBLE_ACTION_DESTROY)
		destroy_object(atom)
	else
		CRASH("Swarmer act returned SWARMER_ACT_POSSIBLE flag with none of the correct flag combinations. Atom: [atom.type], flag: [swarmer_act_result]")

/mob/living/simple_animal/hostile/swarmer/proc/can_disassemble(atom/target, quiet = FALSE)
	var/obj/target_object = target
	if((istype(target_object) && (target_object.resistance_flags & INDESTRUCTIBLE)) || isindestructiblewall(target))
		if(!quiet)
			balloon_alert(src, "невозможно сломать!")
		return FALSE
	if(isitem(target))
		return TRUE

	var/turf/target_turf = get_turf(target)
	if(!target_turf || istype(get_area(target_turf), /area/engineering/supermatter))
		if(!quiet)
			balloon_alert(src, "нельзя, опасная среда!")
		return FALSE
	if(locate(/mob/living) in target)
		if(!quiet)
			balloon_alert(src, "внутри живое существо!")
		return FALSE
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(target_turf, direction)
		if(isspaceturf(neighbor) && !CANATMOSPASS(target, neighbor))
			if(!quiet)
				balloon_alert(src, "нельзя, возможна разгерметизация!")
			return FALSE
	return TRUE

/mob/living/simple_animal/hostile/swarmer/proc/process_organic(atom/target, datum/callback/extra_checks)
	var/obj/machinery/hydroponics/tray = target
	var/is_tray = istype(tray)
	balloon_alert(src, is_tray ? "отправка растения..." : "отправка...")
	if(!do_after(src, SWARMER_SEND_ORGANIC_DELAY, target, extra_checks = extra_checks) || QDELETED(target) || (extra_checks && !extra_checks.Invoke(TRUE)))
		if(!extra_checks)
			balloon_alert(src, "сбито!")
		return FALSE

	if(is_tray && !tray.harvest_for_swarmer())
		return FALSE
	var/obj/item/item = is_tray ? null : target
	var/process_result = team?.try_process_organic(item) || SWARMER_PROCESS_NONE
	if(process_result & SWARMER_PROCESS_FOUND)
		spark_system.start()
		balloon_alert(src, "успешно отправлено!")
		playsound(loc, 'sound/swarmer/swarmer_send.ogg', 100, TRUE)
		return TRUE

	if(process_result & SWARMER_PROCESS_NONE)
		balloon_alert(src, "нету переработчиков!")
	else if(process_result & SWARMER_PROCESS_BUSY)
		balloon_alert(src, "нету свободных обработчиков!")
	else
		CRASH("Swarmer team try_process_organic returned none of the supposed bitflags. Return value: [process_result]")
	return is_tray

/mob/living/simple_animal/hostile/swarmer/proc/try_analyze(mob/living/target)
	balloon_alert(src, "отправка...")
	if(!do_after(src, SWARMER_SEND_ANALYZER_DELAY, target))
		balloon_alert(src, "сбито!")
		return

	var/analyze_result = team?.try_analyze_mob(target) || SWARMER_ANALYZE_NONE
	if(analyze_result & SWARMER_ANALYZE_FOUND)
		balloon_alert(src, "отправлено в анализатор!")
		playsound(loc, 'sound/swarmer/swarmer_send.ogg', 100, TRUE)
		spark_system.start()
		return

	if(analyze_result & SWARMER_ANALYZE_NONE)
		balloon_alert(src, "нету анализаторов, телепорт!")
	else if(analyze_result & SWARMER_ANALYZE_BUSY)
		balloon_alert(src, "анализаторы заняты, телепорт!")
	else
		CRASH("Swarmer team try_analyze_proc returned none of the supposed bitflags. Return value: [analyze_result]")

	spark_system.start()
	fail_disperse_teleport(target)

/mob/living/simple_animal/hostile/swarmer/proc/fail_disperse_teleport(mob/living/target)
	var/turf/origin = get_turf(target)
	var/turf/safe_turf = team?.find_disperse_turf(target)
	if(!safe_turf || !team.teleport_disperse_target(target, safe_turf) || QDELETED(target) || get_turf(target) == origin)
		return

	if(iscarbon(target))
		team?.adjust_organic(SWARMER_CARBON_MOB_TELEPORT_REWARD)
		var/mob/living/carbon/carbon_target = target
		if(!carbon_target.handcuffed)
			carbon_target.handcuffed = new /obj/item/restraints/handcuffs/energy/used(carbon_target)
			carbon_target.update_handcuffed()

	target.Sleeping(10 SECONDS)

/mob/living/simple_animal/hostile/swarmer/proc/try_convert(mob/living/silicon/robot/target)
	if(target.shell)
		balloon_alert(src, "нельзя пересобрать оболочку ИИ!")
		return
	if(training_origin || !target.mind)
		balloon_alert(src, "не имеет разума!")
		return
	balloon_alert(src, "пересобираем...")
	if(!do_after(src, 15 SECONDS, target))
		balloon_alert(src, "сбито!")
		return
	if(QDELETED(target) || target.shell || !target.mind || !team?.swarmer_core)
		return
	var/mob/living/simple_animal/hostile/swarmer/combat/new_swarmer = new(get_turf(target), team)
	if(target.mmi)
		new_swarmer.mmi = target.mmi
		target.mmi.forceMove(new_swarmer)
		target.mmi = null
	target.mind.transfer_to(new_swarmer)
	new_swarmer.add_datum_if_not_exist()
	balloon_alert(src, "успех!")
	new_swarmer.spark_system.start()
	log_combat(src, target, "Converted into [new_swarmer.name].")
	qdel(target)

/mob/living/simple_animal/hostile/swarmer/proc/extract_resources(atom/target, quiet = FALSE)
	if(QDELETED(target) || !team?.swarmer_core)
		if(!quiet)
			balloon_alert(src, "нет ядра!")
		return FALSE

	var/resource_gain = target.integrate_amount()
	if(isnull(resource_gain))
		CRASH("[target.type] swarmer_act uses consume return value, yet integrate_amount() proc returned null.")
	if(istype(target, /obj/item/storage))
		SEND_SIGNAL(target, COMSIG_TRY_STORAGE_QUICK_EMPTY, target.drop_location())
	if(!resource_gain)
		if(!quiet)
			balloon_alert(src, "не совместимо!")
		return FALSE

	if(!isstack(target))
		animate_resource_extraction(target)
		team.adjust_metal(resource_gain, TRUE)
		qdel(target)
		return TRUE

	var/obj/item/stack/stack_item = target
	var/stack_amount_consumed = min(stack_extract_amount, stack_item.get_amount())
	if(stack_amount_consumed <= 0)
		return FALSE
	animate_resource_extraction(target)
	if(!stack_item.use(stack_amount_consumed))
		return FALSE
	team.adjust_metal(resource_gain * stack_amount_consumed, TRUE)
	return TRUE

/mob/living/simple_animal/hostile/swarmer/proc/animate_resource_extraction(atom/target)
	do_attack_animation(target, no_effect = TRUE)
	var/obj/effect/temp_visual/swarmer/integrate/integrate_effect = new(get_turf(target))
	integrate_effect.adjust_size(target)

/mob/living/simple_animal/hostile/swarmer/proc/damage_object(atom/target)
	do_attack_animation(target, no_effect = TRUE)
	var/obj/effect/temp_visual/swarmer/disintegration/disintegrate_effect = new(get_turf(target))
	disintegrate_effect.adjust_size(target)
	target.ex_act(EXPLODE_LIGHT)

/mob/living/simple_animal/hostile/swarmer/proc/start_object_attack(atom/attack_target, consume = FALSE)
	stop_object_attack()
	if(!apply_object_attack(attack_target, consume) || !client)
		return
	object_attack_target = WEAKREF(attack_target)
	object_attack_consumes = consume
	RegisterSignals(src, list(COMSIG_MOVABLE_PRE_MOVE, COMSIG_MOVABLE_MOVED, COMSIG_MOB_CLIENT_LOGOUT), PROC_REF(stop_object_attack))
	RegisterSignal(src, COMSIG_MOB_CLICKON, PROC_REF(on_object_attack_click))
	RegisterSignal(attack_target, COMSIG_PARENT_QDELETING, PROC_REF(stop_object_attack))
	queue_object_attack()

/mob/living/simple_animal/hostile/swarmer/proc/apply_object_attack(atom/attack_target, consume)
	if(consume)
		return extract_resources(attack_target) && isstack(attack_target) && !QDELETED(attack_target)
	var/obj/target_object = attack_target
	var/old_integrity = istype(target_object) ? target_object.obj_integrity : 0
	damage_object(attack_target)
	if(QDELETED(src) || QDELETED(attack_target))
		return FALSE
	// У стен слабый взрыв разбирает стену с вероятностью hardness, без накопления урона.
	var/turf/closed/wall/target_wall = attack_target
	return (istype(target_wall) && target_wall.hardness > 0) || (istype(target_object) && target_object.obj_integrity < old_integrity)

/mob/living/simple_animal/hostile/swarmer/proc/queue_object_attack()
	object_attack_timer = addtimer(CALLBACK(src, PROC_REF(repeat_object_attack)), max(world.tick_lag, EstimatedNextActionTime() - world.time), TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/swarmer/proc/repeat_object_attack()
	object_attack_timer = null
	var/atom/attack_target = object_attack_target?.resolve()
	if(!attack_target || !client || incapacitated() || !isturf(loc) || !CanReach(attack_target) || attack_target.IsObscured() || !can_disassemble(attack_target))
		stop_object_attack()
		return
	if(CheckActionCooldown(immediate = TRUE))
		DelayNextAction(CLICK_CD_MELEE, flush = TRUE)
		if(!apply_object_attack(attack_target, object_attack_consumes))
			stop_object_attack()
			return
	if(object_attack_target)
		queue_object_attack()

/mob/living/simple_animal/hostile/swarmer/proc/on_object_attack_click(datum/source, atom/clicked)
	SIGNAL_HANDLER
	if(clicked != object_attack_target?.resolve())
		stop_object_attack()

/mob/living/simple_animal/hostile/swarmer/proc/stop_object_attack()
	SIGNAL_HANDLER
	if(!object_attack_target)
		return
	var/atom/attack_target = object_attack_target.hard_resolve()
	if(attack_target)
		UnregisterSignal(attack_target, COMSIG_PARENT_QDELETING)
	object_attack_target = null
	object_attack_consumes = FALSE
	UnregisterSignal(src, list(COMSIG_MOVABLE_PRE_MOVE, COMSIG_MOVABLE_MOVED, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_CLICKON))
	if(object_attack_timer)
		deltimer(object_attack_timer)
		object_attack_timer = null

/mob/living/simple_animal/hostile/swarmer/proc/destroy_object(atom/target)
	do_attack_animation(target, no_effect = TRUE)
	var/obj/effect/temp_visual/swarmer/disintegration/disintegrate_effect = new(get_turf(target))
	disintegrate_effect.adjust_size(target)
	qdel(target)

/mob/living/simple_animal/hostile/swarmer/proc/dismantle_machine(obj/machinery/target, datum/callback/extra_checks)
	do_attack_animation(target, no_effect = TRUE)
	var/obj/effect/temp_visual/swarmer/dismantle/dismantle_effect = new(get_turf(target))
	dismantle_effect.adjust_size(target)
	if(!do_after(src, dismantle_speed, target, extra_checks = extra_checks) || QDELETED(target) || (extra_checks && !extra_checks.Invoke(TRUE)))
		return
	target.deconstruct(TRUE)

/mob/living/simple_animal/hostile/swarmer/proc/toggle_light()
	if(!light_on && is_type_in_typecache(loc, GLOB.ventcrawl_machinery))
		to_chat(src, span_warning("Нельзя переключить свет в вентиляции!"))
		return
	set_light_on(!light_on)

/mob/living/simple_animal/hostile/swarmer/proc/contact_swarmers()
	var/message = tgui_input_text(src, "Передайте сообщение другим \"Свармерам\"", "Канал \"Свармеров\"")
	if(!message)
		return

	swarmer_chat(message)

/mob/living/simple_animal/hostile/swarmer/proc/swarmer_chat(message)
	log_talk(message, LOG_SAY, tag = "рой")
	var/formatted = span_swarmer("[span_bold(name)] передаёт: [html_encode(message)]")
	for(var/mob/living/swarmer as anything in team?.bodies)
		to_chat(swarmer, formatted)
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		if(ghost.client?.prefs?.chat_toggles & CHAT_GHOSTRADIO)
			to_chat(ghost, formatted)

/mob/living/simple_animal/hostile/swarmer/proc/construct_catwalk(turf/target_turf)
	balloon_alert(src, "постройка...")
	if(!do_after(src, 3 SECONDS))
		balloon_alert(src, "провал!")
		return

	if(locate(/obj/structure/lattice/catwalk/swarmer_catwalk) in target_turf)
		return
	if(!team?.adjust_metal(-2))
		balloon_alert(src, "недостаточно ресурсов!")
		return

	balloon_alert(src, "успех!")
	new /obj/structure/lattice/catwalk/swarmer_catwalk(target_turf)

#undef SWARMER_CARBON_MOB_TELEPORT_REWARD

/mob/living/attack_swarmer_secondary(mob/living/simple_animal/hostile/swarmer/user)
	user.try_analyze(src)
	return TRUE

/mob/living/simple_animal/hostile/swarmer/attack_swarmer_secondary(mob/living/simple_animal/hostile/swarmer/user)
	return TRUE

/mob/living/silicon/robot/attack_swarmer_secondary(mob/living/simple_animal/hostile/swarmer/user)
	user.try_convert(src)
	return TRUE

/obj/effect/temp_visual/swarmer
	icon = 'icons/effects/swarmer.dmi'
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/swarmer/proc/adjust_size(atom/target)
	pixel_x = target.pixel_x
	pixel_y = target.pixel_y
	pixel_z = target.pixel_z

/obj/effect/temp_visual/swarmer/Initialize(mapload)
	. = ..()
	playsound(loc, 'sound/effects/sparks4.ogg', 100, TRUE)

/obj/effect/temp_visual/swarmer/disintegration
	icon_state = "disintegrate"

/obj/effect/temp_visual/swarmer/dismantle
	icon_state = "dismantle"
	duration = 25

/obj/effect/temp_visual/swarmer/integrate
	icon_state = "integrate"
	duration = 5

/obj/structure/lattice/catwalk/swarmer_catwalk
	name = "swarmer catwalk"
	desc = "Настил из металла, изготовленный роем свармеров."
	icon = 'icons/obj/smooth_structures/swarmer_catwalk.dmi'
	icon_state = "swarmer_catwalk"
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	armor_type = /datum/armor/lattice/swarmer

/datum/armor/lattice/swarmer
	bullet = SWARMER_BULLET_ARMOR_BONUS
	laser = SWARMER_LASER_ARMOR_BONUS
