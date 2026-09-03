//Helper procs for clockwork power, used by structures and items and that kind of jazz.

/proc/get_clockwork_power(amount) //If no amount is provided, returns the clockwork power; otherwise, returns if there's enough power for that amount.
	return amount ? GLOB.clockwork_power >= amount : GLOB.clockwork_power

/// The transmission sigil only has a handful of visible power levels. Keep
/// this calculation shared with update_icon so small power changes can skip a
/// full scan of every clockwork object when the resulting visuals are equal.
/proc/get_transmission_sigil_alpha(power)
	return min(CEILING(TRANSMISSION_SIGIL_BASE_ALPHA + power * TRANSMISSION_SIGIL_POWER_ALPHA_SCALE, TRANSMISSION_SIGIL_ALPHA_STEP), 255)

/proc/adjust_clockwork_power(amount) //Adjusts the global clockwork power by this amount (min 0.)
	var/old_visual_alpha = get_transmission_sigil_alpha(GLOB.clockwork_power)
	var/old_powered = !!GLOB.clockwork_power
	var/current_power
	if(GLOB.ratvar_approaches)
		amount *= 0.75 //The herald's beacon reduces power costs by 25% across the board!
	if(GLOB.ratvar_awakens)
		current_power = GLOB.clockwork_power = INFINITY
	else
		current_power = GLOB.clockwork_power = clamp(GLOB.clockwork_power + amount, 0, MAX_CLOCKWORK_POWER)
	var/new_visual_alpha = GLOB.ratvar_awakens ? 255 : get_transmission_sigil_alpha(current_power)
	if(old_visual_alpha != new_visual_alpha || old_powered != !!current_power)
		for(var/obj/effect/clockwork/sigil/transmission/T in GLOB.all_clockwork_objects)
			T.update_icon()
	var/unlock_message
	if(current_power >= SCRIPT_UNLOCK_THRESHOLD && !GLOB.script_scripture_unlocked)
		GLOB.script_scripture_unlocked = TRUE
		unlock_message = "<span class='large_brass bold'>Ковчег расширяется по мере достижения ключевого порога мощности. Теперь доступны новые священные писания.</span>"
	if(current_power >= APPLICATION_UNLOCK_THRESHOLD && !GLOB.application_scripture_unlocked)
		GLOB.application_scripture_unlocked = TRUE
		unlock_message = "<span class='large_brass bold'>Ковчег расширяется по достижении ключевого порога мощности. Теперь доступны новые священные писания для практического применения.</span>"
	if(unlock_message && GLOB.servants_active)
		hierophant_message(unlock_message)
	return TRUE

/proc/can_access_clockwork_power(atom/movable/access_point, amount) //Returns true if the access point has access to clockwork power (and optionally, a number of watts for it)
	if(amount && !get_clockwork_power(amount)) //No point in trying if we don't have the power anyway
		return
	var/list/possible_conduits = view(5, access_point)
	return locate(/obj/effect/clockwork/sigil/transmission) in possible_conduits || GLOB.ratvar_awakens
