/mob/living/carbon/human/AltUnarmedAttack(atom/A, proximity)
	if(!has_active_hand())
		to_chat(src, "<span class='notice'>You look at the state of the universe and sigh.</span>") //lets face it, people rarely ever see this message in its intended condition.
		return TRUE

	return A.alt_attack_hand(src)

/mob/living/carbon/human/AltRangedAttack(atom/A, params)
	if(isturf(A) || incapacitated()) // pretty annoying to wave your fist at floors and walls. And useless.
		return
	if(!CheckActionCooldown(CLICK_CD_RANGE))
		return
	DelayNextAction()
	var/list/target_viewers = fov_viewers(11, A) //doesn't check for blindness.
	if(!(src in target_viewers)) //click catcher issuing calls for out of view objects.
		return TRUE
	if(!has_active_hand())
		to_chat(src, "<span class='notice'>You ponder your life choices and sigh.</span>")
		return TRUE
	var/list/src_viewers = viewers(DEFAULT_MESSAGE_RANGE, src) - src // src has a different message.
	var/the_action = "waves to [A]"
	var/what_action = "waves to something you can't see"
	var/self_action = "wave to [A]"
	var/target_action = "waves to you"
	var/emote_icon = "wavefriendly"

	switch(a_intent)
		if(INTENT_DISARM)
			the_action = "shoos away [A]"
			what_action = "shoo away something out of your vision"
			self_action = "shoo away [A]"
			target_action = "shoos you away"
			emote_icon = "dismiss"
		if(INTENT_GRAB)
			the_action = "beckons [A] to come"
			what_action = "beckons something out of your vision to come"
			self_action = "beckon [A] to come"
			target_action = "beckons you to come"
			emote_icon = "beckon"
		if(INTENT_HARM)
			var/pronoun = "[ru_ego()]"
			the_action = "shakes [pronoun] fist at [A]"
			what_action = "shakes [pronoun] fist at something out of your vision"
			self_action = "shake your fist at [A]"
			target_action = "shakes [pronoun] fist at you"
			emote_icon = "taunt"

	if(!eye_blind)
		to_chat(src, "You [self_action].")
	var/mob/living/target
	if(isliving(A))
		target = A
		if(!target.eye_blind)
			to_chat(target, "[src] [target_action].")
		target.show_overhead_rclick_emote(target, emote_icon)
		show_overhead_rclick_emote(src, emote_icon)
	for(var/B in src_viewers)
		var/mob/M = B
		if(M != target && !M.eye_blind)
			var/message = (M in target_viewers) ? the_action : what_action
			to_chat(M, "[src] [message].")
	return TRUE

/mob/living/proc/show_overhead_rclick_emote(mob/living/viewer, icon_state)
	if(!viewer)
		return
	var/image/emote_image = image(icon = 'icons/mob/overhead_effects.dmi', icon_state = icon_state, layer = ABOVE_MOB_LAYER, loc = src)
	emote_image.pixel_y += 20
	emote_image.appearance_flags = RESET_COLOR
	var/appearance_key = "rclick_emote_[REF(emote_image)]"
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/onePerson, appearance_key, emote_image, viewer)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, remove_alt_appearance), appearance_key), 2 SECONDS)

/atom/proc/alt_attack_hand(mob/user)
	return FALSE
