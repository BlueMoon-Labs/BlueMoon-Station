/datum/element/wuv/headpat/pet_the_dog(mob/target, mob/user) //For instances where only the headpat applies
	if(QDELETED(target) || QDELETED(user) || target.stat != CONSCIOUS)
		return
	if(!(check_zone(user.zone_selected) == BODY_ZONE_HEAD) || user == target)
		return
	new /obj/effect/temp_visual/heart(target.loc)
	if(pet_emote)
		target.emote("me", pet_type, pet_emote)
	if(pet_moodlet && !(target.flags_1 & HOLOGRAM_1)) //prevents unlimited happiness petting park exploit.
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "petting_bonus", pet_moodlet, target)

/datum/element/wuv/headpat/kick_the_dog(mob/target, mob/user)
	return //No kicking the dog >:(( (until I find an use for this that is)
