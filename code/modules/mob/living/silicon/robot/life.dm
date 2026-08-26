/mob/living/silicon/robot/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	handle_robot_hud_updates()
	handle_robot_cell()

/mob/living/silicon/robot/proc/handle_robot_cell()
	if(stat != DEAD)
		if(low_power_mode)
			if(cell?.charge)
				low_power_mode = FALSE
		else if(stat == CONSCIOUS)
			use_power()

/mob/living/silicon/robot/proc/use_power()
	if(cell?.charge)
		if((cell.charge <= 500) && (vtec != initial(vtec)))
			disable_vtec("<span class='warning'>Critical cell charge! VTEC is temporarily disabled.</span>")
		if(cell.charge <= 100)
			uneq_all()
		var/amt = clamp((lamp_enabled * lamp_intensity),1,cell.charge) //Lamp will use a max of 5 charge, depending on brightness of lamp. If lamp is off, borg systems consume 1 point of charge, or the rest of the cell if it's lower than that.
		cell.use(amt) //Usage table: 1/tick if off/lowest setting, 4 = 4/tick, 6 = 8/tick, 8 = 12/tick, 10 = 16/tick
	else
		uneq_all()
		disable_vtec()
		low_power_mode = TRUE
		toggle_headlamp(TRUE)
	//VTEC power drain
	if((vtec != initial(vtec)) && (!vtec_disabled))
		if(vtec_expire && world.time >= vtec_expire) //лимит по времени есть только у форсажа; крейсерский режим бесконечен
			vtec_overdrive_expired("<span class='notice'>Форсаж VTEC исчерпан, система перешла в крейсерский режим.</span>")
		else if(cell?.charge)
			if(!cell.use(vtec_drain))
				disable_vtec("<span class='warning'>Critical cell charge! VTEC is temporarily disabled.</span>")
	diag_hud_set_borgcell()

/// Гасит активный разгон VTEC: сбрасывает скорость, таймер и расход. Кнопку способности и перезарядку не трогает.
/mob/living/silicon/robot/proc/clear_vtec_boost(message)
	vtec = initial(vtec)
	vtec_expire = 0
	vtec_drain = 0
	if(message)
		to_chat(src, message)

/// Включает крейсерский режим VTEC (режим 2): скорость обычного человека, без лимита времени
/mob/living/silicon/robot/proc/activate_vtec_cruise()
	clear_vtec_boost()
	vtec = initial(vtec) - 0.5 //гасит штатный штраф борга +0.5 из movement_delay(), итог - скорость бегущего человека
	vtec_drain = VTEC_CRUISE_DRAIN //while changing this value check /mob/living/silicon/robot/proc/use_power() to maintain proper power drain

/// Форсаж исчерпан: он уходит на перезарядку, а система проваливается в крейсерский режим (режим 2)
/mob/living/silicon/robot/proc/vtec_overdrive_expired(message)
	vtec_cooldown_until = world.time + VTEC_COOLDOWN
	var/obj/effect/proc_holder/silicon/cyborg/vtecControl/VC = locate() in abilities
	if(VC)
		VC.applyState(src, 1)
	else
		activate_vtec_cruise()
	if(message)
		to_chat(src, message)

/// Полностью выключает VTEC: сброс разгона, перезарядка после форсажа, сброс кнопки способности.
/// На перезарядку уходит только форсаж (vtec_expire выставлен); крейсерский режим выключается свободно.
/mob/living/silicon/robot/proc/disable_vtec(message, force_cooldown = FALSE)
	if(vtec_expire || force_cooldown)
		vtec_cooldown_until = world.time + VTEC_COOLDOWN
	clear_vtec_boost(message)
	var/obj/effect/proc_holder/silicon/cyborg/vtecControl/VC = locate() in abilities
	if(VC && VC.currentState)
		VC.currentState = 0
		VC.action.button_icon_state = "Chevron_State_0"
		VC.action.UpdateButtons()

/mob/living/silicon/robot/proc/handle_robot_hud_updates()
	if(!client)
		return

	update_cell_hud_icon()

/mob/living/silicon/robot/update_health_hud()
	if(!client || !hud_used)
		return
	if(hud_used.healths)
		if(stat != DEAD)
			if(health >= maxHealth)
				hud_used.healths.icon_state = "health0"
			else if(health > maxHealth*0.6)
				hud_used.healths.icon_state = "health2"
			else if(health > maxHealth*0.2)
				hud_used.healths.icon_state = "health3"
			else if(health > -maxHealth*0.2)
				hud_used.healths.icon_state = "health4"
			else if(health > -maxHealth*0.6)
				hud_used.healths.icon_state = "health5"
			else
				hud_used.healths.icon_state = "health6"
		else
			hud_used.healths.icon_state = "health7"

/mob/living/silicon/robot/proc/update_cell_hud_icon()
	if(cell)
		var/cellcharge = cell.charge/cell.maxcharge
		switch(cellcharge)
			if(0.75 to INFINITY)
				clear_alert("charge")
			if(0.5 to 0.75)
				throw_alert("charge", /atom/movable/screen/alert/lowcell, 1)
			if(0.25 to 0.5)
				throw_alert("charge", /atom/movable/screen/alert/lowcell, 2)
			if(0.01 to 0.25)
				throw_alert("charge", /atom/movable/screen/alert/lowcell, 3)
			else
				throw_alert("charge", /atom/movable/screen/alert/emptycell)
	else
		throw_alert("charge", /atom/movable/screen/alert/nocell)

//Robots on fire
/mob/living/silicon/robot/handle_fire()
	if(..())
		return
	if(fire_stacks > 0)
		fire_stacks--
		fire_stacks = max(0, fire_stacks)
	else
		ExtinguishMob()

	//adjustFireLoss(3)
	return

/mob/living/silicon/robot/update_fire()
	var/mutable_appearance/fire_overlay = mutable_appearance('icons/mob/OnFire.dmi', "Generic_mob_burning")
	if(on_fire)
		add_overlay(fire_overlay)
	else
		cut_overlay(fire_overlay)
