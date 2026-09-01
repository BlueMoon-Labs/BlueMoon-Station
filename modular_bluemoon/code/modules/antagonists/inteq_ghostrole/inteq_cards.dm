/obj/item/card/id/inteq/one_access_copy
	name = "Civilian Mercenary Card"
	uses = 1

/obj/item/card/id/inteq/anyone
	name = "Vanguard Mercenary Card"
	icon_state = "inteq"
	assignment = "Vanguard Mercenary"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_INTEQ, ACCESS_INTEQ_LEADER, ACCESS_SYNDICATE)

/obj/item/card/id/inteq/nuke_leader
	name = "Nuclear Vanguard Mercenary Card"
	icon_state = "inteq"
	assignment = "Vanguard Mercenary"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_INTEQ, ACCESS_INTEQ_LEADER, ACCESS_SYNDICATE)

/obj/item/card/id/inteq/crew_id
	name = "InteQ Vanguard ID card"
	id_type_name = "InteQ ID card"
	desc = "An ID straight from the InteQ."
	registered_name = "InteQ"
	assignment = "InteQ Operative"
	icon_state = "inteq"
	access = list(ACCESS_INTEQ, ACCESS_ROBOTICS, ACCESS_SYNDICATE)
	uses_overlays = FALSE

/obj/item/card/id/inteq/engineer
	name = "InteQ Field Engineer ID card"
	id_type_name = "InteQ ID card"
	desc = "An ID straight from the InteQ."
	registered_name = "InteQ"
	assignment = "InteQ Field Engineer"
	icon_state = "inteq"
	access = list(ACCESS_INTEQ, ACCESS_ROBOTICS, ACCESS_SYNDICATE)
	uses_overlays = FALSE

/obj/item/card/id/inteq/captain_id
	name = "InteQ Vanguard Leader ID card"
	id_type_name = "InteQ captain ID card"
	desc = "An ID straight from the InteQ."
	registered_name = "InteQ"
	assignment = "InteQ Ship Captain"
	icon_state = "inteq"
	access = list(ACCESS_INTEQ, ACCESS_INTEQ_LEADER, ACCESS_ROBOTICS, ACCESS_SYNDICATE)
	uses_overlays = FALSE

/obj/item/card/id/inteq
	name = "Agent Card"
	icon_state = "inteq"
	assignment = "Mercenary"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_INTEQ, ACCESS_SYNDICATE)
	var/anyone = FALSE //Can anyone forge the ID or just InteQ?
	var/forged = FALSE //have we set a custom name and job assignment, or will we use what we're given when we chameleon change?
	var/uses = 10

/obj/item/card/id/inteq/advanced
	name = "Agent Card"
	icon_state = "card_black"

/obj/item/card/id/inteq/Initialize(mapload)
	. = ..()
	var/datum/action/item_action/chameleon/change/chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/card/id
	chameleon_action.chameleon_name = "ID Card"
	chameleon_action.initialize_disguises()
	if(!anyone)
		AddComponent(/datum/component/identification/syndicate, ID_COMPONENT_DEL_ON_IDENTIFY, ID_COMPONENT_EFFECT_NO_ACTIONS, NONE)		//no deconstructive analyzer usage.

/obj/item/card/id/inteq/afterattack(obj/item/O, mob/user, proximity)
	if(!proximity)
		return
	if(istype(O, /obj/item/card/id) && !uses)
		to_chat(usr, "<span class='notice'>Микросканеры устройства издают отрицательное жужжание при попытке использовать их ещё раз.</span>")
		playsound(src, 'sound/effects/light_flicker.ogg', 100, 1)
		return
	if(istype(O, /obj/item/card/id))
		var/obj/item/card/id/I = O
		src.access |= I.access
		uses = max(uses - 1, 0)
		to_chat(usr, "<span class='notice'>Микросканеры устройства активизируются при проведении ею по Идентификационной Карте и копируют её доступ.</span>")
		playsound(src, 'sound/effects/light_flicker.ogg', 100, 1)

/obj/item/card/id/inteq/attack_self(mob/user)
	if(isliving(user) && user.mind)
		var/first_use = registered_name ? FALSE : TRUE
		if(!(user.mind.special_role || anyone)) //Unless anyone is allowed, only syndies can use the card, to stop metagaming.
			if(first_use) //If a non-syndie is the first to forge an unassigned agent ID, then anyone can forge it.
				anyone = TRUE
			else
				return ..()

		var/popup_input
		if(bank_support == ID_FREE_BANK_ACCOUNT)
			popup_input = alert(user, "Choose Action", "Agent ID", "Show", "Forge/Reset", "Change Account ID")
		else
			popup_input = alert(user, "Choose Action", "Agent ID", "Show", "Forge/Reset")
		if(!user.canUseTopic(src, BE_CLOSE, FALSE))
			return
		if(popup_input == "Forge/Reset" && !forged)
			var/input_name = stripped_input(user, "What name would you like to put on this card? Leave blank to randomise.", "Agent card name", registered_name ? registered_name : (ishuman(user) ? user.real_name : user.name), MAX_NAME_LEN)
			input_name = reject_bad_name(input_name)
			if(!input_name)
				// Invalid/blank names give a randomly generated one.
				if(user.gender == MALE)
					input_name = "[pick(GLOB.first_names_male)] [pick(GLOB.last_names)]"
				else if(user.gender == FEMALE)
					input_name = "[pick(GLOB.first_names_female)] [pick(GLOB.last_names)]"
				else
					input_name = "[pick(GLOB.first_names)] [pick(GLOB.last_names)]"

			var/target_occupation = stripped_input(user, "What occupation would you like to put on this card?\nNote: This will not grant any access levels other than Maintenance.", "Agent card job assignment", assignment ? assignment : "Assistant", MAX_MESSAGE_LEN)
			if(!target_occupation)
				return
			registered_name = input_name
			assignment = target_occupation
			update_label()
			forged = TRUE
			to_chat(user, "<span class='notice'>You successfully forge the ID card.</span>")
			log_game("[key_name(user)] has forged \the [initial(name)] with name \"[registered_name]\" and occupation \"[assignment]\".")

			// First time use automatically sets the account id to the user.
			if (first_use && !registered_account)
				if(ishuman(user))
					var/mob/living/carbon/human/accountowner = user

					for(var/bank_account in SSeconomy.bank_accounts)
						var/datum/bank_account/account = bank_account
						if(account.account_id == accountowner.account_id)
							account.bank_cards += src
							registered_account = account
							to_chat(user, "<span class='notice'>Your account number has been automatically assigned.</span>")
			return
		else if (popup_input == "Forge/Reset" && forged)
			registered_name = initial(registered_name)
			assignment = initial(assignment)
			log_game("[key_name(user)] has reset \the [initial(name)] named \"[src]\" to default.")
			update_label()
			forged = FALSE
			to_chat(user, "<span class='notice'>You successfully reset the ID card.</span>")
			return
		else if (popup_input == "Change Account ID")
			set_new_account(user)
			return
	return ..()
