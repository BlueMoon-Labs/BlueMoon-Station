/datum/emote/sound/human/custom
	emote_cooldown = 0

/datum/emote/sound/human_emote/laugh/run_emote(mob/living/user, params)
	. = ..()
	if(!.)
		return
	var/laugh_sound = pick(get_laugh_sound(user.get_laugh_token(), key == "laugh_soft" ? TRUE : FALSE))
	playsound(user, laugh_sound, 50, 1)

/mob/living/proc/get_laugh_token()
	return null

/mob/living/carbon/get_laugh_token()
	var/choosen_token
	if(gender == FEMALE || (gender == PLURAL && isfeminine(src)))
		choosen_token = "Female"
	else
		choosen_token = "Male"
	return choosen_token

/mob/living/carbon/human/get_laugh_token()
	if(laugh_override)
		return laugh_override

	var/choosen_token
	if(iscatperson(src))
		choosen_token = "Felinid"

	else if(isinsect(src))
		choosen_token = "Insect"

	else if(isvox(src))
		choosen_token = "Vox"

	else if(isjellyperson(src))
		if(dna?.features["mam_ears"] == "Cat" || dna?.features["mam_ears"] == "Cat, Big") //slime have cat ear. slime go nya.
			choosen_token = "Slime Cat"
		else if(gender == FEMALE || (gender == PLURAL && isfeminine(src)))
			choosen_token = "Slime Female"
		else
			choosen_token = "Slime Male"

	return choosen_token ? choosen_token : ..()

/proc/get_laugh_sound(var/token, var/soft = FALSE)
	var/list/choosen_sound = list()
	switch(token)
		if("Felinid")
			choosen_sound = list('sound/voice/catpeople/nyahaha1.ogg',
				'sound/voice/catpeople/nyahaha2.ogg',
				'sound/voice/catpeople/nyaha.ogg',
				'sound/voice/catpeople/nyahehe.ogg')
		if("Insect")
			choosen_sound += 'sound/voice/moth/mothlaugh.ogg'
		if("Vox")
			choosen_sound += 'modular_bluemoon/kovac_shitcode/sound/species/voxrustle.ogg'
		if("Slime Cat")
			choosen_sound = list('sound/voice/jelly/nyahaha1.ogg',
							'sound/voice/jelly/nyahaha2.ogg',
							'sound/voice/jelly/nyaha.ogg',
							'sound/voice/jelly/nyahehe.ogg')
		if("Slime Male")
			choosen_sound = list('sound/voice/jelly/manlaugh1.ogg', 'sound/voice/jelly/manlaugh2.ogg')
		if("Slime Female")
			choosen_sound += 'sound/voice/jelly/womanlaugh.ogg'
		if("Male")
			choosen_sound = list('sound/voice/human/manlaugh1.ogg',
								'sound/voice/human/manlaugh2.ogg')
			if(!soft)
				choosen_sound.Add('sound/voice/laugh_m1.ogg',
								'sound/voice/laugh_m3.ogg')
		if("Female")
			choosen_sound += 'sound/voice/human/womanlaugh.ogg'
			if(!soft)
				choosen_sound.Add('sound/voice/female_laugh1.ogg',
									'sound/voice/female_laugh2.ogg',
									'sound/voice/female_laugh3.ogg')
	return choosen_sound.len ? choosen_sound : null

/datum/emote/sound/human_emote/laugh/soft
	name = "Тихо смеяться"
	key = "laugh_soft"
	key_third_person = "laughs soft"

/datum/emote/sound/human/sniff/snuffle
	name = "Шмыгнуть"
	key = "snuffle"
	key_third_person = "snuffles"
	message = "шмыгает носом."
