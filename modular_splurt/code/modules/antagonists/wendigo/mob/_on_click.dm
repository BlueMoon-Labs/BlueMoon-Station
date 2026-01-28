/mob/living/carbon/wendigo/UnarmedAttack(atom/A, proximity)
	A.attack_hand(src)

/mob/living/carbon/wendigo/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE, check_resting=FALSE, silent = FALSE)
	if(incapacitated() || lying)
		if(!silent)
			to_chat(src, "<span class='warning'>You can't do that right now!</span>")
		return FALSE
	if(be_close && !in_range(M, src))
		if(!silent)
			to_chat(src, "<span class='warning'>You are too far away!</span>")
		return FALSE
	return TRUE
