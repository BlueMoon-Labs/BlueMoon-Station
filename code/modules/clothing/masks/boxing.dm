/obj/item/clothing/mask/balaclava
	name = "Balaclava"
	desc = "LOADSAMONEY"
	icon_state = "balaclava"
	item_state = "balaclava"
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	visor_flags_inv = HIDEFACE|HIDEFACIALHAIR
	w_class = WEIGHT_CLASS_SMALL
	actions_types = list(/datum/action/item_action/adjust)
	mutantrace_variation = STYLE_MUZZLE

/obj/item/clothing/mask/balaclava/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/balaclava/breath
	name = "Breathaclava"
	clothing_flags = ALLOWINTERNALS

//Bluemoon donator add

/obj/item/clothing/mask/balaclava/breath/goal
	name = "Goal mask"
	desc = "Mask that looks like a weird bear."
	icon_state = "goal"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/mask/screammask
	name = "Scream Mask"
	desc = "ЧУВАААААК."
	mob_overlay_icon = 'icons/mob/clothing/custom_w.dmi'
	icon_state = "krik"
	item_state = "krik"
	clothing_flags = ALLOWINTERNALS
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	unique_reskin = list(
		"Standart" = list(
			"icon_state" = "krik",
			"item_state" = "krik",
			"name" = "Scream Mask"
		),
		"Freak" = list(
			"icon_state" = "krikfreak",
			"item_state" = "krikfreak",
			"name" = "Freak Scream Mask"
		)
	)
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

//Bluemoon donator add end

/obj/item/clothing/mask/infiltrator
	name = "Insidious Balaclava"
	desc = "An incredibly suspicious balaclava made with Syndicate nanofibers to absorb impacts slightly while obfuscating the voice and face using a garbled vocoder."
	icon_state = "syndicate_balaclava"
	item_state = "syndicate_balaclava"
	clothing_flags = ALLOWINTERNALS
	flags_cover = HEADCOVERSEYES
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	visor_flags_inv = HIDEFACE|HIDEFACIALHAIR
	w_class = WEIGHT_CLASS_SMALL
	armor = list(MELEE = 10, BULLET = 5, LASER = 5,ENERGY = 5, BOMB = 0, BIO = 0, RAD = 10, FIRE = 30, ACID = 30)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	mutantrace_variation = STYLE_MUZZLE
	var/voice_unknown = TRUE ///This makes it so that your name shows up as unknown when wearing the mask.

/obj/item/clothing/mask/luchador
	name = "Luchador Mask"
	desc = "Worn by robust fighters, flying high to defeat their foes!"
	icon_state = "luchag"
	item_state = "luchag"
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	w_class = WEIGHT_CLASS_SMALL
	mutantrace_variation = STYLE_MUZZLE
	modifies_speech = TRUE

/obj/item/clothing/mask/luchador/handle_speech(datum/source, list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*" && message[1] != "!")
		message = replacetext(message, "captain", "CAPITÁN")
		message = replacetext(message, "station", "ESTACIÓN")
		message = replacetext(message, "sir", "SEÑOR")
		message = replacetext(message, "the ", "el ")
		message = replacetext(message, "my ", "mi ")
		message = replacetext(message, "is ", "es ")
		message = replacetext(message, "it's", "es")
		message = replacetext(message, "friend", "amigo")
		message = replacetext(message, "buddy", "amigo")
		message = replacetext(message, "hello", "hola")
		message = replacetext(message, " hot", " caliente")
		message = replacetext(message, " very ", " muy ")
		message = replacetext(message, "sword", "espada")
		message = replacetext(message, "library", "biblioteca")
		message = replacetext(message, "traitor", "traidor")
		message = replacetext(message, "wizard", "mago")
		message = uppertext(message)	//Things end up looking better this way (no mixed cases), and it fits the macho wrestler image.
		if(prob(25))
			message += " OLE!"
	speech_args[SPEECH_MESSAGE] = message

/obj/item/clothing/mask/luchador/tecnicos
	name = "Tecnicos Mask"
	desc = "Worn by robust fighters who uphold justice and fight honorably."
	icon_state = "luchador"
	item_state = "luchador"

/obj/item/clothing/mask/luchador/rudos
	name = "Rudos Mask"
	desc = "Worn by robust fighters who are willing to do anything to win."
	icon_state = "luchar"
	item_state = "luchar"

/obj/item/clothing/mask/russian_balaclava
	name = "russian balaclava"
	desc = "Protects your face from snow."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_balaclava"
	item_state = "balaclava"
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	visor_flags_inv = HIDEFACE|HIDEFACIALHAIR
	w_class = WEIGHT_CLASS_SMALL
