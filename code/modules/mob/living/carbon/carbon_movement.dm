/mob/living/carbon/slip(knockdown_amount, obj/O, lube)
	if(movement_type & (FLYING | FLOATING) && !(lube & FLYING_DOESNT_HELP))
		return FALSE
	if(!(lube&SLIDE_ICE))
		log_combat(src, (O ? O : get_turf(src)), "slipped on the", null, ((lube & SLIDE) ? "(LUBE)" : null))
	return loc.handle_slip(src, knockdown_amount, O, lube)

/mob/living/carbon/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	if(..(movement_dir, continuous_move))
		return TRUE
	if(!isturf(loc))
		return FALSE

	// Do we have a jetpack implant (and is it on)? Same as tank jetpack: drift tick is not "key thrust".
	// Стабилизаторов у импланта нет по описанию, поэтому гасить дрейф он не умеет - только толкать.
	var/obj/item/organ/cyberimp/chest/thrusters/implant = getorganslot(ORGAN_SLOT_THRUSTERS)
	if(istype(implant) && !continuous_move && movement_dir)
		if(implant.allow_thrust(0.01, consume = thrust_alters_velocity(movement_dir, continuous_move, FALSE)))
			return TRUE

	// *continuous_move* is the newtonian drift tick: [movement_dir] is drift, not keyinput — do not let jet (without stabilizers) "win" and kill inertia
	var/obj/item/thruster = get_jetpack()
	if(istype(thruster, /obj/item/tank/jetpack))
		var/obj/item/tank/jetpack/pack = thruster
		if(thruster_engages(movement_dir, continuous_move, pack.stabilizers))
			if(pack.allow_thrust(0.01, src, consume = thrust_alters_velocity(movement_dir, continuous_move, pack.stabilizers)))
				return TRUE
	else if(istype(thruster, /obj/item/mod/module/jetpack))
		var/obj/item/mod/module/jetpack/module = thruster
		if(thruster_engages(movement_dir, continuous_move, module.stabilizers))
			if(module.allow_thrust(consume = thrust_alters_velocity(movement_dir, continuous_move, module.stabilizers)))
				return TRUE

/// Вмешивается ли двигатель в это движение: тик дрейфа перебивает только стабилизация, ручной шаг - и она, и обычная тяга.
/mob/living/carbon/proc/thruster_engages(movement_dir, continuous_move, stabilizing)
	return continuous_move ? stabilizing : (movement_dir || stabilizing)

/**
 * Меняет ли этот шаг вектор дрейфа - то есть должен ли двигатель за него заплатить.
 *
 * Разгон, торможение и поворот стоят топлива. Накат по курсу на крейсерской скорости не стоит
 * ничего: двигатель в этот момент не работает, он просто разрешает шагать. Раньше платили за
 * каждое движение подряд, включая шаги самого дрейфа, и вдобавок по второму разу из
 * `Process_Spacemove` - отсюда и севшая за пару минут батарея из баг-репорта.
 */
/mob/living/carbon/proc/thrust_alters_velocity(movement_dir, continuous_move, stabilizing)
	if(continuous_move)
		// Тик дрейфа: работа есть, только если стабилизация реально гасит существующий дрейф.
		return stabilizing && !isnull(drift_handler)
	if(!movement_dir)
		return FALSE
	if(stabilizing || isnull(drift_handler))
		// Держать себя против пустоты и трогаться с места - всегда работа.
		return TRUE
	if(drift_handler.drift_force < self_thrust_cap)
		return TRUE
	// На крейсерской скорости платим только за смену курса.
	var/datum/move_loop/smooth_move/loop = drift_handler.drifting_loop
	if(isnull(loop))
		return TRUE
	return abs(closer_angle_difference(dir2angle(movement_dir), loop.angle)) > INERTIA_THRUST_TURN_ANGLE

/mob/living/carbon/Moved()
	. = ..()
	if(. && !(movement_type & FLOATING)) //floating is easy
		if(HAS_TRAIT(src, TRAIT_NOHUNGER))
			set_nutrition(NUTRITION_LEVEL_FED - 1)	//just less than feeling vigorous
		else if(nutrition && stat != DEAD)
			var/loss = HUNGER_FACTOR/10
			if(m_intent == MOVE_INTENT_RUN)
				loss *= 2
			adjust_nutrition(-loss)

		if(HAS_TRAIT(src, TRAIT_NOTHIRST))
			set_thirst(THIRST_LEVEL_BIT_THIRSTY - 1)
		else if(thirst && stat != DEAD)
			var/loss = THIRST_FACTOR/10
			if(m_intent == MOVE_INTENT_RUN)
				loss *= 2
			adjust_thirst(-loss)

/mob/living/carbon/can_move_under_living(mob/living/other)
	. = ..()
	if(!.)		//we failed earlier don't need to fail again
		return
	if(!other.lying && lying)		//they're up, we're down.
		return FALSE
