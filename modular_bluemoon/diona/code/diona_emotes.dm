/datum/emote/sound/diona
	mob_type_allowed_typecache = list(/mob/living/carbon/human)
	emote_type = EMOTE_AUDIBLE
	emote_cooldown = 2 SECONDS

/datum/emote/sound/diona/can_run_emote(mob/living/user, status_check, intentional)
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	return istype(H.dna?.species, /datum/species/diona)

/datum/emote/sound/diona/chirp
	key = "chirp"
	key_third_person = "chirps"
	message = "чирпает!"
	sound = 'modular_bluemoon/diona/sound/nymphchirp.ogg'

/datum/emote/sound/diona/multichirp
	key = "mchirp"
	key_third_person = "mchirps"
	message = "чирпает целой какофонией звуков!"
	sound = 'modular_bluemoon/diona/sound/multichirp.ogg'
