/obj/item/encryptionkey
	name = "standard encryption key"
	desc = "An encryption key for a radio headset."
	icon = 'icons/obj/radio.dmi'
	icon_state = "cypherkey"
	w_class = WEIGHT_CLASS_TINY
	var/translate_binary = FALSE
	var/syndie = FALSE
	//The single antagonist frequency this key decrypts (syndicate/inteq/pirate). 0 for a regular key.
	//Antagonist keys are separate nets, so a syndicate radio can't listen to InteQ or pirate chatter.
	var/syndie_freq = 0
	var/independent = FALSE
	var/list/channels = list()

/obj/item/encryptionkey/Initialize(mapload)
	. = ..()
	if(!length(channels) && !translate_binary)
		desc = "An encryption key for a radio headset. Has no special codes in it. You should probably tell a coder!"

/obj/item/encryptionkey/examine(mob/user)
	. = ..()
	if(LAZYLEN(channels))
		var/list/examine_text_list = list()
		for(var/i in channels)
			examine_text_list += "[GLOB.channel_tokens[i]] - [lowertext(i)]"

		. += "<span class='notice'>It can access the following channels; [jointext(examine_text_list, ", ")].</span>"
	if(translate_binary)
		. += "<span class='notice'>It also allows access to the special binary channel used by silicons."

/obj/item/encryptionkey/headset_sec
	name = "Security Radio Encryption Key"
	icon_state = "sec_cypherkey"
	channels = list(RADIO_CHANNEL_SECURITY = 1)

/obj/item/encryptionkey/headset_law // BlueMoon Fink added
	name = "Law Radio Encryption Key"
	icon = 'modular_bluemoon/icons/obj/radio.dmi'
	icon_state = "law_cypherkey"
	channels = list(RADIO_CHANNEL_LAW = 1, RADIO_CHANNEL_SECURITY = 1)

/obj/item/encryptionkey/headset_ntr // BlueMoon Fink added
	name = "NTR Radio Encryption Key"
	icon = 'modular_bluemoon/icons/obj/radio.dmi'
	icon_state = "ntr_cypherkey"
	channels = list(RADIO_CHANNEL_LAW = 1,  RADIO_CHANNEL_SECURITY = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/headset_most // BlueMoon Fink added
	name = "Bridge Officer Radio Encryption Key"
	icon = 'modular_bluemoon/icons/obj/radio.dmi'
	icon_state = "most_cypherkey"
	channels = list(RADIO_CHANNEL_LAW = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/headset_eng
	name = "Engineering Radio Encryption Key"
	icon_state = "eng_cypherkey"
	channels = list(RADIO_CHANNEL_ENGINEERING = 1)

/obj/item/encryptionkey/headset_med
	name = "Medical Radio Encryption Key"
	icon_state = "med_cypherkey"
	channels = list(RADIO_CHANNEL_MEDICAL = 1)

/obj/item/encryptionkey/headset_sci
	name = "Science Radio Encryption Key"
	icon_state = "sci_cypherkey"
	channels = list(RADIO_CHANNEL_SCIENCE = 1)

/obj/item/encryptionkey/headset_medsci
	name = "Medical Research Radio Encryption Key"
	icon_state = "medsci_cypherkey"
	channels = list(RADIO_CHANNEL_SCIENCE = 1, RADIO_CHANNEL_MEDICAL = 1)

/obj/item/encryptionkey/headset_cargo
	name = "Supply Radio Encryption Key"
	icon_state = "cargo_cypherkey"
	channels = list(RADIO_CHANNEL_SUPPLY = 1)

/obj/item/encryptionkey/headset_mining
	name = "Mining Radio Encryption Key"
	icon_state = "cargo_cypherkey"
	channels = list(RADIO_CHANNEL_SUPPLY = 1, RADIO_CHANNEL_SCIENCE = 1)

/obj/item/encryptionkey/headset_service
	name = "Service Radio Encryption Key"
	icon_state = "srv_cypherkey"
	channels = list(RADIO_CHANNEL_SERVICE = 1)

/obj/item/encryptionkey/headset_com
	name = "Command Radio Encryption Key"
	icon_state = "com_cypherkey"
	channels = list(RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/heads/captain
	name = "\proper The Captain's Encryption Key"
	icon_state = "cap_cypherkey"
	channels = list(RADIO_CHANNEL_COMMAND = 1, RADIO_CHANNEL_SECURITY = 1, RADIO_CHANNEL_ENGINEERING = 1, RADIO_CHANNEL_SCIENCE = 1, RADIO_CHANNEL_MEDICAL = 1, RADIO_CHANNEL_SUPPLY = 1, RADIO_CHANNEL_SERVICE = 1, RADIO_CHANNEL_LAW = 1)

/obj/item/encryptionkey/heads/rd
	name = "\proper The Research Director's Encryption Key"
	icon_state = "rd_cypherkey"
	channels = list(RADIO_CHANNEL_SCIENCE = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/heads/hos
	name = "\proper The Head of Security's Encryption Key"
	icon_state = "hos_cypherkey"
	channels = list(RADIO_CHANNEL_SECURITY = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/heads/ce
	name = "\proper The Chief Engineer's Encryption Key"
	icon_state = "ce_cypherkey"
	channels = list(RADIO_CHANNEL_ENGINEERING = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/heads/cmo
	name = "\proper The Chief Medical officer's Encryption Key"
	icon_state = "cmo_cypherkey"
	channels = list(RADIO_CHANNEL_MEDICAL = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/heads/hop
	name = "\proper The Head of Personnel's Encryption Key"
	icon_state = "hop_cypherkey"
	channels = list(RADIO_CHANNEL_SERVICE = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/heads/qm
	name = "\proper The Quartermaster's Encryption Key"
	desc = "An encryption key for a radio headset.  Channels are as follows: :u - supply, :c - command."
	icon_state = "hop_cypherkey"
	channels = list(RADIO_CHANNEL_SUPPLY = 1, RADIO_CHANNEL_COMMAND = 1)

/obj/item/encryptionkey/headset_cent
	name = "\improper CentCom Radio Encryption Key"
	icon_state = "cent_cypherkey"
	independent = TRUE
	channels = list(RADIO_CHANNEL_CENTCOM = 1)

/obj/item/encryptionkey/syndicate
	name = "Illegal Encryption Key"
	icon_state = "syn_cypherkey"
	channels = list(RADIO_CHANNEL_SYNDICATE = 1)
	syndie = TRUE //Signifies that it de-crypts Syndicate transmissions
	syndie_freq = FREQ_SYNDICATE

/obj/item/encryptionkey/inteq
	name = "InteQ Encryption Key"
	icon_state = "inteq_cypherkey"
	icon = 'modular_bluemoon/icons/obj/radio.dmi'
	channels = list(RADIO_CHANNEL_INTEQ = 1)
	syndie = TRUE //Signifies that it de-crypts Syndicate transmissions
	syndie_freq = FREQ_INTEQ

/obj/item/encryptionkey/pirate
	name = "Pirate Encryption Key"
	icon_state = "syn_cypherkey"
	channels = list(RADIO_CHANNEL_PIRATE = 1)
	syndie = TRUE //Signifies that it de-crypts Syndicate transmissions
	syndie_freq = FREQ_PIRATE

/obj/item/encryptionkey/binary
	name = "Binary Translator Key"
	icon_state = "bin_cypherkey"
	translate_binary = TRUE

/obj/item/encryptionkey/headset_cargo/tarkoff
	name = "Tarkof Industry Radio Encryption Key"
	channels = list(RADIO_CHANNEL_TARKOFF = 1)
	independent = TRUE

/obj/item/encryptionkey/headset_syndicate/ds1
	name = "DS1 Radio Encryption Key"
	channels = list(RADIO_CHANNEL_DS1 = 1)
	independent = TRUE

/obj/item/encryptionkey/headset_syndicate/ds2
	name = "DS2 Radio Encryption Key"
	channels = list(RADIO_CHANNEL_DS2 = 1)
	independent = TRUE

/obj/item/encryptionkey/headset_syndicate/sol
	name = "SolFed Encryption Key"
	channels = list(RADIO_CHANNEL_SOL = 1)
	icon_state = "solgov_cypherkey"
	icon = 'modular_bluemoon/icons/obj/radio.dmi'
	independent = TRUE

/obj/item/encryptionkey/headset_syndicate/nri
	name = "NRI Encryption Key"
	channels = list(RADIO_CHANNEL_NRI = 1)
	icon_state = "rus_cypherkey"
	icon = 'modular_bluemoon/icons/obj/radio.dmi'
	independent = TRUE

/obj/item/encryptionkey/ai //ported from NT, this goes 'inside' the AI.
	channels = list(RADIO_CHANNEL_COMMAND = 1, RADIO_CHANNEL_SECURITY = 1, RADIO_CHANNEL_ENGINEERING = 1, RADIO_CHANNEL_SCIENCE = 1, RADIO_CHANNEL_MEDICAL = 1, RADIO_CHANNEL_SUPPLY = 1, RADIO_CHANNEL_SERVICE = 1, RADIO_CHANNEL_AI_PRIVATE = 1)

/obj/item/encryptionkey/secbot
	channels = list(RADIO_CHANNEL_AI_PRIVATE = 1, RADIO_CHANNEL_SECURITY = 1)

