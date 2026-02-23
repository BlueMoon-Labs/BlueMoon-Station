/datum/interaction
	/// Interaction type for Plug13: `PLUG13_EMOTE_` type.
	/// This one is for the doer/fucker/attacker.
	///
	/// Set it to `null` to disable.
	var/p13user_emote = null

	/// Interaction strength for Plug13: `PLUG13_STRENGTH_` type or number `1-100`.
	/// This one is for the doer/fucker/attacker.
	var/p13user_strength = PLUG13_STRENGTH_DEFAULT

	/// Interaction duration for Plug13: `PLUG13_DURATION_` type or deciseconds number.
	/// This one is for the doer/fucker/attacker.
	var/p13user_duration = PLUG13_DURATION_DEFAULT

	/// Interaction type for plug13: `PLUG13_EMOTE_` type.
	/// This one is for the target/victim.
	///
	/// Set it to `null` to disable.
	var/p13target_emote = null
	/// Interaction strength for Plug13: `PLUG13_STRENGTH_` type or number `1-100`.
	/// This one is for the target/victim.
	var/p13target_strength = PLUG13_STRENGTH_DEFAULT
	/// Interaction duration for Plug13: `PLUG13_DURATION_` type or deciseconds number.
	/// This one is for the target/victim.
	var/p13target_duration = PLUG13_DURATION_DEFAULT


/datum/interaction/post_interaction(mob/living/user, mob/living/target)
	. = ..()
	if (p13user_emote && p13user_strength && p13user_duration)
		user.client?.plug13.send_emote(
			p13user_emote,
			clamp(p13user_strength + get_lust_modifier(user), 10, 100),
			p13user_duration
		)

	if (p13target_emote && p13target_strength && p13target_duration)
		target.client?.plug13.send_emote(
			p13target_emote,
			min(p13target_strength + get_lust_modifier(target), 10, 100),
			p13target_duration
		)

	if(interaction_flags & INTERACTION_FLAG_ADJACENT && user != target)
		SEND_SIGNAL(user, COMSIG_INTERACTION_ADJACENT, target)
		SEND_SIGNAL(target, COMSIG_INTERACTION_ADJACENT, user)

/datum/interaction/proc/get_lust_modifier(mob/living/user)
	return (20 * (user.get_lust() / user.get_lust_tolerance())) - 10
