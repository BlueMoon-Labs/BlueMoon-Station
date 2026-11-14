/mob/living/carbon/human/resist_a_rest(automatic = FALSE, ignoretimer = FALSE)
	if(!resting || stat || (combat_flags & COMBAT_FLAG_RESISTING_REST))
		return FALSE
	// Бесполезная попытка встать не должна запускать do_after и показывать прогресс.
	if(lying && !get_leg_ignore() && !get_num_supporting_limbs())
		if(!automatic)
			if(HAS_TRAIT(src, TRAIT_NAGA_ANATOMY))
				if(mind && !HAS_MIND_TRAIT(src, TRAIT_NAGA_LOCOMOTION))
					to_chat(src, span_warning("Вы не можете встать: вы не умеете пользоваться опорным хвостом этого тела."))
				else
					to_chat(src, span_warning("Вы не можете встать: ваш опорный хвост отсутствует или не может служить опорой."))
			else if(HAS_MIND_TRAIT(src, TRAIT_NAGA_LOCOMOTION))
				to_chat(src, span_warning("Вы не можете встать: вы умеете передвигаться только опорным хвостом и не умеете пользоваться ногами этого тела."))
			else
				to_chat(src, span_warning("Вы не можете встать: ни одна из ваших ног не может служить опорой."))
		return FALSE
	if(ignoretimer)
		set_resting(FALSE, FALSE)
		return TRUE
	if(!lying)				//if they're in a chair or something they don't need to force themselves off the ground.
		set_resting(FALSE, FALSE)
		return TRUE
	else if(!CHECK_MOBILITY(src, MOBILITY_RESIST))
		if(!automatic)
			to_chat(src, "<span class='warning'>Вы не можете встать в данный момент.</span>")
		return FALSE
	else
		var/totaldelay = 3 //A little bit less than half of a second as a baseline for getting up from a rest
		if(IS_STAMCRIT(src))
			to_chat(src, "<span class='warning'>Вы слишком устали, чтобы подняться!")
			return FALSE
		combat_flags |= COMBAT_FLAG_RESISTING_REST
		var/health_deficiency = max((maxHealth - (health - getStaminaLoss()))*0.5, 0)
		if(!has_gravity())
			health_deficiency = health_deficiency*0.2
		totaldelay += health_deficiency
		var/standupwarning = "[src] and everyone around them should probably yell at the dev team"
		switch(health_deficiency)
			if(-INFINITY to 10)
				standupwarning = "[src] встает!"
			if(10 to 35)
				standupwarning = "[src] встаёт."
			if(35 to 60)
				standupwarning = "[src] медленно поднимается."
			if(60 to 80)
				standupwarning = "[src] вяло поднимается."
			if(80 to INFINITY)
				standupwarning = "[src] с трудом поднимается."
		var/usernotice = automatic ? "<span class='notice'>Вы сейчас встаете. (Автоматически)</span>" : "<span class='notice'>Вы сейчас встаете.</span>"
		visible_message("<span class='notice'>[standupwarning]</span>", usernotice, vision_distance = 5)
		if(do_after(src, totaldelay, target = src, timed_action_flags = (IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM|IGNORE_INCAPACITATED), extra_checks = CALLBACK(src, PROC_REF(cuff_resist_check))))
			set_resting(FALSE, TRUE)

			combat_flags &= ~COMBAT_FLAG_RESISTING_REST
			return TRUE
		else
			combat_flags &= ~COMBAT_FLAG_RESISTING_REST
			if(resting)		//we didn't shove ourselves up or something
				visible_message("<span class='notice'>[src] падает под себя.</span>", "<span class='notice'>Вы падаете под себя.</span>")
				update_icon()
				if(has_gravity())
					playsound(src, "bodyfall", 20, 1)
			return FALSE
