/// A list of all users who currently have a scryer NIFSoft active.
GLOBAL_LIST_EMPTY(active_nif_scryers)

/obj/item/disk/nifsoft_uploader/scryer
	name = "NIFLink Holocaller"
	loaded_nifsoft = /datum/nifsoft/scryer

/datum/nifsoft/scryer
	name = "NIFLink Holocaller"
	program_desc = "A streamlined version of the NIFLink comms system. While active, the program projects a small holo-emitter necklace that allows the user to send messages to any other currently active NIFLink user, completely bypassing local comms. ((ICly safe to use as a roleplay tool, works globally.))"
	activation_cost = 20
	active_mode = TRUE
	active_cost = 1
	purchase_price = 200
	buying_category = NIFSOFT_CATEGORY_UTILITY
	ui_icon = "video"

	///The scryer device currently being used to communicate.
	var/obj/item/clothing/neck/nif_scryer/linked_scryer

/datum/nifsoft/scryer/activate()
	. = ..()
	if(!.)
		return FALSE

	if(active)
		if(QDELETED(linked_scryer))
			linked_scryer = new(linked_mob)
			linked_mob.equip_to_slot_if_possible(linked_scryer, ITEM_SLOT_NECK)

		GLOB.active_nif_scryers += linked_mob
	else
		QDEL_NULL(linked_scryer)
		GLOB.active_nif_scryers -= linked_mob

	return TRUE

/datum/nifsoft/scryer/Destroy()
	if(linked_mob in GLOB.active_nif_scryers)
		GLOB.active_nif_scryers -= linked_mob

	QDEL_NULL(linked_scryer)
	return ..()

/obj/item/clothing/neck/nif_scryer
	name = "scryer"
	desc = "A cheap holo-emitter necklace, used by NIFLink users to contact other members of the network. A small notice is printed on the back: \"This device is not affiliated with the Nanotrasen Telecommunications Administration.\""
	icon = 'icons/obj/clothing/neck.dmi'
	icon_state = "ties"
	item_state = "tie"
	strip_delay = 40
	w_class = WEIGHT_CLASS_SMALL
	///The user currently equipped with the scryer. Type is a weakref.
	var/datum/weakref/scryer_user

/obj/item/clothing/neck/nif_scryer/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_NECK)
		scryer_user = WEAKREF(user)

/obj/item/clothing/neck/nif_scryer/dropped(mob/user, atom/dropped_loc)
	. = ..()
	scryer_user = null

/obj/item/clothing/neck/nif_scryer/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return

	var/mob/living/sender = scryer_user?.resolve()
	if(!sender)
		balloon_alert(user, "you need to wear this to use it!")
		return

	var/list/recipients = GLOB.active_nif_scryers.Copy() - sender
	var/mob/living/target = tgui_input_list(sender, "Who would you like to message?", "NIFLink Scanner", recipients)
	if(!target)
		return

	var/message = tgui_input_text(sender, "Enter a message to transmit.", "NIFLink Telepathy", max_length = MAX_MESSAGE_LEN)
	if(!message || QDELETED(src) || sender.stat == DEAD)
		return

	var/formatted_message = "<i><font color='#00b7ff'>\[[sender.real_name]'s NIFLink\] <b>[sender]:</b> [message]</font></i>"
	log_directed_talk(sender, target, message, LOG_SAY, "nif scryer")
	to_chat(target, formatted_message)
	to_chat(sender, formatted_message)
