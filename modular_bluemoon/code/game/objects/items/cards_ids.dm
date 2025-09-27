/obj/item/card/id/syndicate
	var/uses = 10 // Даём гражданской Синди-Карте одно использование вместо десяти.

/obj/item/card/id/callsign
	name = "сallsign id card"
	desc = "A card used to provide ID and determine access across various facilities. This one belongs to NanoTrasen and has a small graved in label, marking it as \"Callsing Changing ID\"."
	icon_state = "card_black"
	assignment = "All-Callsigns-Check-In"
	var/forged = FALSE //have we set a custom name and job assignment, or will we use what we're given when we chameleon change?
	var/callsign = ""

/obj/item/card/id/callsign/Initialize(mapload)
	. = ..()
	var/datum/action/item_action/chameleon/change/chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/card/id
	chameleon_action.chameleon_name = "ID Card"
	chameleon_action.initialize_disguises()

/obj/item/card/id/callsign/attack_self(mob/user)
	if(isliving(user) && user.mind)

		var/popup_input
		popup_input = alert(user, "Choose Action", "Callsign ID", "Show", "Forge/Reset")
		if(!user.canUseTopic(src, BE_CLOSE, FALSE))
			return
		if(popup_input == "Forge/Reset" && !forged)
			var/desired_callsign = stripped_input(user, "What callsign would you like to put on this card? Leave blank to remove.", "Callsign card", callsign, MAX_NAME_LEN)
			desired_callsign = reject_bad_name(desired_callsign)
			if(!desired_callsign)
				desired_callsign = ""

			callsign = desired_callsign

			update_label()
			forged = TRUE
			to_chat(user, "<span class='notice'>You successfully forge the ID card.</span>")
			return
		else if (popup_input == "Forge/Reset" && forged)
			callsign = ""

			update_label()
			forged = FALSE
			to_chat(user, "<span class='notice'>You successfully reset the ID card.</span>")
			return
	return ..()

/obj/item/card/id/callsign/update_label(newname, newjob)
	if(newname || newjob)
		name = "[(!newname)	? "identification card"	: "[newname] - ID Card"][(!newjob) ? "" : " ([newjob])"]"
		update_icon()
		return

	name = "[(!registered_name)	? "identification card"	: "[registered_name] [callsign ? "'[callsign]'" : ""] - ID Card"][(!assignment) ? "" : " ([assignment])"]"

	update_icon()

/obj/item/card/id/callsign/loadout
	var/registred = FALSE

// Используется именно такая функция, т.к. при выдаче через лодаут карта помещается в рюкзак
/obj/item/card/id/callsign/loadout/on_enter_storage()
	if(!registred)
		var/mob/living/carbon/human/my_owner = null

		if(ishuman(loc.loc)) // Если карта появляется в сумке
			my_owner = loc.loc
		if(ishuman(loc)) // Если карта в кармане или где угодно, но на персонаже
			my_owner = loc

		if(my_owner) // копирование свойств старой карты и её замена
			var/obj/item/card/id/id_card = my_owner.get_item_by_slot(ITEM_SLOT_ID)

			// Если взять эту карту из лодаута и зайти на авейку, она может удалить старую карту у персонажа, что приведёт к нежелательным последствиям
			if(istype(id_card, /obj/item/card/id/inteq) || istype(id_card, /obj/item/card/id/syndicate))
				to_chat(my_owner, span_warning("Ваша карта уже обладает свойствами, доступными гражданской карте синдиката! Лишняя была удалена."))
				qdel(src)
				return

			// Зэкам эта карта не положена
			if(istype(id_card, /obj/item/card/id/prisoner))
				to_chat(my_owner, span_warning("Ваша основная карта принадлежит заключенному! Лишняя была удалена."))
				qdel(src)
				return

			if(id_card?.access.len)
				access |= id_card.access
				assignment = id_card.assignment
				registered_account = id_card.registered_account
				rank = id_card.rank
				registered_name = id_card.registered_name
				name = id_card.name
				update_icon()

				qdel(id_card)
				my_owner.equip_to_slot_if_possible(src, ITEM_SLOT_ID, disable_warning = TRUE, bypass_equip_delay_self = TRUE)

		registred = TRUE

		if(src != my_owner?.get_item_by_slot(ITEM_SLOT_ID)) // Если в будущем что-то переделают и карта будет спавниться в отдельной коробке или вроде того
			visible_message(span_warning("ID карта из лодаута не нашла цель для копирования доступа, сообщите разработчикам."))
	. = ..()

/obj/item/card/id/nri
	name = "\improper NRI Military ID"
	desc = "An Novaya Rossiyskya Imperia Spetsnaz ID card."
	icon_state = "nri"
	registered_name = "NRI"
	assignment = "NRI"
	uses_overlays = FALSE
	special_assignment = "nri"

/obj/item/card/id/nri/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("commander")-ACCESS_CHANGE_IDS
	. = ..()

/obj/item/card/id/sol
	name = "\improper SolFed Military ID"
	desc = "An Solar Federation Military ID card. Provided with special sensors, allowing to unlock all necessary doors for combatants, slightly reminding emag functions."
	icon_state = "sol"
	registered_name = "Sol"
	assignment = "Sol"
	uses_overlays = FALSE
	special_assignment = "sol"

/obj/item/card/id/sol/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("commander")-ACCESS_CHANGE_IDS
	. = ..()

/obj/item/card/id/heresy
	icon = 'modular_bluemoon/icons/obj/card.dmi'
	name = "Occult ID Card"
	desc = "ID for research related to occult activities whose nature of phenomena is poorly supported by scientific evidence."
	icon_state = "occult_id"
	assignment = "Herecit"
	uses_overlays = FALSE
	card_sticker = TRUE
	special_assignment = "heresy"

/obj/item/card/id/lust
	icon = 'modular_bluemoon/icons/obj/card.dmi'
	name = "Sex Worker ID"
	desc = "ID for employee of Silver Love Co."
	icon_state = "lust_id"
	assignment = "Sex worker"
	uses_overlays = FALSE
	card_sticker = TRUE
	special_assignment = "lust"

/obj/item/card/id/agony
	icon = 'modular_bluemoon/icons/obj/card.dmi'
	name = "Ravenheart Resident ID"
	desc = "ID for research related to extreme activities whose nature of agony is strictly prohibited by scientific evidence."
	icon_state = "agony_id"
	assignment = "Ravenheart Resident"
	uses_overlays = FALSE
	card_sticker = TRUE
	special_assignment = "agony"

/obj/item/card/id/muck
	icon = 'modular_bluemoon/icons/obj/card.dmi'
	name = "Muck ID Card"
	desc = "Жрать гавно."
	icon_state = "muck_id"
	assignment = "Mucker"
	uses_overlays = FALSE
	card_sticker = TRUE
	special_assignment = "muck"
