/datum/emote/sound/human/clack
	name = "Щёлкать жвалами"
	key = "clack"
	key_third_person = "clacks"
	message = "щёлкает жвалами."
	emote_type = EMOTE_AUDIBLE
	restraint_check = FALSE
	sound = 'modular_bluemoon/sound/emotes/centipede_clack1.ogg'

/datum/emote/sound/human/clack/run_emote(mob/user, params)
	sound = pick('modular_bluemoon/sound/emotes/centipede_clack1.ogg', 'modular_bluemoon/sound/emotes/centipede_clack2.ogg', 'modular_bluemoon/sound/emotes/centipede_clack3.ogg')
	return ..()

/datum/bark/centipede_click
	name = "Centipede (Click)"
	id = "centipede_click"
	soundpath = 'modular_bluemoon/sound/voice/barks/centipede_click.ogg'
	maxpitch = 1.2
	minspeed = 3

/datum/bark/centipede_chitter
	name = "Centipede (Chitter)"
	id = "centipede_chitter"
	soundpath = 'modular_bluemoon/sound/voice/barks/centipede_chitter.ogg'
	maxpitch = 1.2
	minspeed = 4
