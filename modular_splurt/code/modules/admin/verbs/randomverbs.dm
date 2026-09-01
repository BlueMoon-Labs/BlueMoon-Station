/client/proc/cmd_admin_subtle_headset_message(mob/M, sender = null)
	if(!ismob(M))
		return
	if(!check_rights(R_ADMIN))
		return

	if (!sender)
		var/list/subtle_message_options = list("Voice in head", RADIO_CHANNEL_CENTCOM, RADIO_CHANNEL_SYNDICATE)
		sender = tgui_input_list(usr, "Choose the method of subtle messaging", "Subtle Message", subtle_message_options)
		if (!sender)
			return

	message_admins("[key_name_admin(src)] has started answering [ADMIN_LOOKUPFLW(M)]'s prayer / faction PM.")
	var/msg = input("Contents of the message", text("Subtle PM to [M.key]")) as text
	if (!msg)
		message_admins("[key_name_admin(src)] decided not to answer [ADMIN_LOOKUPFLW(M)]'s prayer / faction PM.")
		return

	if (sender == "Voice in head")
		M.balloon_alert(M, "Голос в голове")
		SEND_SOUND(M, sound('sound/effects/ghost2.ogg'))
		to_chat(M, "<i>Вы слышите голос в голове... <b>[msg]</i></b>")
	else
		var/mob/living/carbon/human/H = M

		if(!istype(H))
			to_chat(usr, "The person you are trying to contact is not human. Unsent message: [msg]")
			return

		if(!istype(H.ears, /obj/item/radio/headset))
			to_chat(usr, "The person you are trying to contact is not wearing a headset. Unsent message: [msg]")
			return

		var/channel_name = sender == RADIO_CHANNEL_SYNDICATE ? "Синдиката" : "ЦК"
		var/channel_sound = sender == RADIO_CHANNEL_SYNDICATE ? 'sound/ambience/antag/TatorAlert.ogg' : 'sound/machines/signal.ogg'
		H.balloon_alert(H, "Получена передача от [channel_name]")
		SEND_SOUND(H, sound(channel_sound))
		to_chat(H, "Вы слышите щелчок в ухе прежде, чем голос в вашей голове начинает говорить.  \"Прослушайте сообщение от [sender == RADIO_CHANNEL_SYNDICATE ? "ваших нанимателей" : "ЦК"].  Содержание сообщения[sender == RADIO_CHANNEL_SYNDICATE ? ", агент." : ":"] <span class='bold'>[msg].</span> Конец сообщения.\"")


	log_admin("SubtlePM ([sender]): [key_name(usr)] -> [key_name(M)] : [msg]")
	msg = "<span class='adminnotice'><b> SubtleMessage ([sender]): [key_name_admin(usr)] -> [key_name_admin(M)] :</b> [msg]</span>"
	message_admins(msg)
	admin_ticket_log(M, msg)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Subtle Message") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
