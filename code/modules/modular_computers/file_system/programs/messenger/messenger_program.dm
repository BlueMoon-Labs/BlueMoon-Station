/// Maximum PDA message length
#define MAX_PDA_MESSAGE_LEN 1024
/// Format of message timestamps
#define PDA_MESSAGE_TIMESTAMP_FORMAT "hh:mm"

/// Returns cached list of emoji names, initializing on first call
/proc/get_emoji_list()
	if(!length(GLOB.cached_emoji_list))
		GLOB.cached_emoji_list = list()
		GLOB.cached_emoji_base64 = list()
		var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/chat)
		for(var/sprite_name in sheet.sprites)
			if(findtextEx(sprite_name, "emoji-") == 1)
				var/emoji_name = copytext(sprite_name, 7)
				if(emoji_name != "")
					GLOB.cached_emoji_list |= emoji_name
		if(!length(GLOB.cached_emoji_list))
			GLOB.cached_emoji_list = list("smile", "grin", "laughing", "wink", "frown", "angry", "cry", "heart", "ok", "thumbup")
		else if(length(GLOB.cached_emoji_list) > 200)
			GLOB.cached_emoji_list = GLOB.cached_emoji_list.Copy(1, 200)
		for(var/emoji_name in GLOB.cached_emoji_list)
			var/icon/emoji_icon = icon('icons/emoji.dmi', emoji_name)
			if(!length(icon_states(emoji_icon)))
				emoji_icon = icon('icons/emoji_32.dmi', emoji_name)
			if(length(icon_states(emoji_icon)))
				GLOB.cached_emoji_base64[emoji_name] = icon2base64(emoji_icon)
	return GLOB.cached_emoji_list

/// Returns cached base64 dict of emoji icons
/proc/get_emoji_base64()
	if(!length(GLOB.cached_emoji_base64))
		get_emoji_list()
	return GLOB.cached_emoji_base64

/proc/parse_emoji_message(message)
	. = message
	if(!length(GLOB.cached_emoji_list))
		get_emoji_list()
	for(var/emoji_name in GLOB.cached_emoji_list)
		var/base64 = GLOB.cached_emoji_base64[emoji_name]
		if(base64)
			. = replacetext(., ":[emoji_name]:", "<img class='emoji-inline' src='data:image/png;base64,[base64]' alt=':[emoji_name]:' />")
	return .

/datum/computer_file/program/messenger
	filename = "nt_messenger"
	filedesc = "Direct Messenger"
	category = PROGRAM_CATEGORY_DEVICE
	program_icon_state = "text"
	extended_desc = "Позволяет вести классическую переписку с другими модульными устройствами."
	size = 0
	undeletable = TRUE
	usage_flags = PROGRAM_ON_TABLETS
	ui_header = "ntnrc_idle.gif"
	tgui_id = "NtosMessenger"
	program_icon = "comment-alt"
	alert_able = TRUE

	/// Whether the user is invisible to the message list.
	var/invisible = FALSE
	/// Cooldown to prevent spam
	COOLDOWN_DECLARE(last_text)
	/// Cooldown for everyone messages
	COOLDOWN_DECLARE(last_text_everyone)
	/// Whether this is a mime PDA (emoji only)
	var/mime_mode = FALSE
	/// Whether this app can send messages to all.
	var/spam_mode = FALSE

	/// Associative list of chats: chatref -> pda_chat
	var/list/saved_chats = list()
	/// Whose chatlogs we currently have open. Null = contacts list.
	var/viewing_messages_of = null

	/// The current ringtone
	var/ringtone = MESSENGER_RINGTONE_DEFAULT
	/// Whether sorting by job
	var/sort_by_job = TRUE
	/// Whether sending and receiving messages
	var/sending_and_receiving = TRUE
	/// Selected photo for sending
	var/selected_image = null
	/// Admin-set external photo URL
	var/admin_photo_url = null
	/// Whether sending a virus
	var/sending_virus = FALSE

	detomatix_resistance = 0

/datum/computer_file/program/messenger/on_install()
	. = ..()
	RegisterSignal(computer, COMSIG_MODULAR_PDA_IMPRINT_UPDATED, PROC_REF(on_imprint_added))
	RegisterSignal(computer, COMSIG_MODULAR_PDA_IMPRINT_RESET, PROC_REF(on_imprint_reset))
	add_messenger(src)

/datum/computer_file/program/messenger/run_program(mob/living/user)
	. = ..()
	if(.)
		add_messenger(src)

/datum/computer_file/program/messenger/proc/on_imprint_added(sender)
	SIGNAL_HANDLER
	add_messenger(src)

/datum/computer_file/program/messenger/proc/on_imprint_reset(sender)
	SIGNAL_HANDLER
	remove_messenger(src)
	QDEL_LIST_ASSOC_VAL(saved_chats)
	selected_image = null
	viewing_messages_of = null

/datum/computer_file/program/messenger/Destroy(force)
	if(!QDELETED(computer))
		UnregisterSignal(computer, list(
			COMSIG_MODULAR_PDA_IMPRINT_UPDATED,
			COMSIG_MODULAR_PDA_IMPRINT_RESET,
		))
	remove_messenger(src)
	for(var/other_ref in GLOB.pda_messengers)
		var/datum/computer_file/program/messenger/other = GLOB.pda_messengers[other_ref]
		if(other == src || QDELETED(other))
			continue
		var/list/to_remove = list()
		for(var/chat_ref in other.saved_chats)
			var/datum/pda_chat/chat = other.saved_chats[chat_ref]
			var/datum/computer_file/program/messenger/recipient = chat.recipient?.resolve()
			if(recipient == src)
				to_remove += chat_ref
		for(var/chat_ref in to_remove)
			var/datum/pda_chat/chat = other.saved_chats[chat_ref]
			other.saved_chats -= chat_ref
			qdel(chat)
		if(other.computer)
			SStgui.update_uis(other.computer)
	QDEL_LIST_ASSOC_VAL(saved_chats)
	return ..()

/// Gets the list of available messengers
/datum/computer_file/program/messenger/proc/get_messengers()
	var/list/dictionary = list()
	var/list/unsorted = list()

	for(var/obj/item/modular_computer/pda/pda_device in GLOB.PDAs)
		if(pda_device == computer)
			continue
		if(pda_device.toff || pda_device.hidden)
			continue
		if(!pda_device.saved_identification && !pda_device.saved_job)
			continue
		var/datum/computer_file/program/messenger/messenger = locate() in pda_device.get_all_files()
		if(!istype(messenger) || messenger.invisible)
			continue

		var/list/data = list()
		data["name"] = pda_device.saved_identification || "Unknown"
		data["job"] = pda_device.saved_job || "Unknown"
		data["ref"] = REF(messenger)
		unsorted += list(data)

	if(sort_by_job)
		sortTim(unsorted, /proc/cmp_list_data_job)
	else
		sortTim(unsorted, /proc/cmp_list_data_name)

	for(var/list/entry in unsorted)
		dictionary[entry["ref"]] = entry

	return dictionary

/// Checks if the person can send an everyone message
/datum/computer_file/program/messenger/proc/can_send_everyone_message()
	return COOLDOWN_FINISHED(src, last_text) && COOLDOWN_FINISHED(src, last_text_everyone)

/// Set the ringtone if possible. Also handles encoding.
/datum/computer_file/program/messenger/proc/set_ringtone(new_ringtone, mob/user)
	// html_encode is required: a custom ringtone reaches an UNESCAPED maptext sink via
	// computer.ring() -> balloon_alert(). To avoid double-encoding on re-edit, the
	// PDA_ringSet dialog html_decode()s this value back when pre-filling its default.
	new_ringtone = trim(html_encode(new_ringtone), MESSENGER_RINGTONE_MAX_LENGTH)
	if(!new_ringtone)
		return FALSE

	if(SEND_SIGNAL(computer, COMSIG_TABLET_CHANGE_ID, user, new_ringtone) & COMPONENT_STOP_RINGTONE_CHANGE)
		return FALSE

	ringtone = new_ringtone

	// Update character preferences if possible
	if(user?.client?.prefs)
		user.client.prefs.pda_ringtone = new_ringtone
		user.client.prefs.save_preferences()

	return TRUE

/datum/computer_file/program/messenger/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(isobserver(usr))
		return FALSE
	switch(action)
		if("PDA_ringSet")
			var/mob/living/user = usr
			var/new_ringtone = tgui_input_text(user, "Enter a new ringtone", "Ringtone", html_decode(ringtone), max_length = MAX_MESSAGE_LEN, encode = FALSE)
			if(!new_ringtone)
				return FALSE
			return set_ringtone(new_ringtone, user)

		if("PDA_ringSetPreset")
			var/new_ringtone = params["ringtone"]
			if(!new_ringtone || !(new_ringtone in GLOB.pda_ringtone_list))
				return FALSE
			return set_ringtone(new_ringtone, usr)

		if("PDA_toggleAlerts")
			alert_silenced = !alert_silenced
			return TRUE

		if("PDA_toggleSendingAndReceiving")
			sending_and_receiving = !sending_and_receiving
			return TRUE

		if("PDA_viewMessages")
			if(viewing_messages_of in saved_chats)
				var/datum/pda_chat/chat = saved_chats[viewing_messages_of]
				chat.unread_messages = 0

			viewing_messages_of = params["ref"]

			if(viewing_messages_of in saved_chats)
				var/datum/pda_chat/chat = saved_chats[viewing_messages_of]
				chat.visible_in_recents = TRUE

			selected_image = null
			return TRUE

		if("PDA_closeMessages")
			var/target = params["ref"]

			if(!(target in saved_chats))
				return FALSE

			var/datum/pda_chat/chat = saved_chats[target]
			chat.visible_in_recents = FALSE
			if(viewing_messages_of == target)
				viewing_messages_of = null
			return TRUE

		if("PDA_clearMessages")
			var/chat_ref = params["ref"]

			if(chat_ref in saved_chats)
				saved_chats.Remove(chat_ref)
			else if(isnull(chat_ref))
				saved_chats = list()

			viewing_messages_of = null
			return TRUE

		if("PDA_changeSortStyle")
			sort_by_job = !sort_by_job
			return TRUE

		if("PDA_sendEveryone")
			if(!sending_and_receiving)
				to_chat(usr, span_notice("ERROR: This device has sending disabled."))
				return FALSE

			if(!spam_mode)
				to_chat(usr, span_notice("ERROR: This device does not have mass-messaging perms."))
				return FALSE

			if(!can_send_everyone_message())
				return FALSE

			return send_message_to_all(usr, params["message"])

		if("PDA_saveMessageDraft")
			var/target_chat_ref = params["ref"]
			var/message_draft = params["message"]

			if(!(target_chat_ref in saved_chats))
				return FALSE

			var/datum/pda_chat/chat = saved_chats[target_chat_ref]
			chat.message_draft = message_draft
			return TRUE

		if("PDA_clearUnreads")
			var/target_chat_ref = params["ref"]

			if(!(target_chat_ref in saved_chats))
				return FALSE

			var/datum/pda_chat/chat = saved_chats[target_chat_ref]
			chat.unread_messages = 0
			return TRUE

		if("PDA_toggleBlock")
			var/target_chat_ref = params["ref"]

			if(!(target_chat_ref in saved_chats))
				return FALSE

			var/datum/pda_chat/chat = saved_chats[target_chat_ref]
			chat.blocked = !chat.blocked
			if(chat.blocked)
				to_chat(usr, span_notice("[chat.get_recipient_name()] заблокирован."))
			else
				to_chat(usr, span_notice("[chat.get_recipient_name()] разблокирован."))
			return TRUE

		if("PDA_sendMessage")
			if(!sending_and_receiving)
				to_chat(usr, span_notice("ERROR: This device has sending disabled."))
				return FALSE

			var/target_ref = params["ref"]
			var/target = null

			if(target_ref in saved_chats)
				target = saved_chats[target_ref]
			else if(target_ref in GLOB.pda_messengers)
				target = GLOB.pda_messengers[target_ref]
			else
				// Fallback: search all PDAs for the messenger
				for(var/obj/item/modular_computer/pda/pda_device in GLOB.PDAs)
					var/datum/computer_file/program/messenger/messenger = locate() in pda_device.get_all_files()
					if(istype(messenger) && REF(messenger) == target_ref)
						target = messenger
						add_messenger(messenger)
						break
				if(!target)
					return FALSE

			if(sending_virus)
				var/obj/item/cartridge/virus/disk = computer.inserted_disk
				if(!istype(disk))
					to_chat(usr, span_notice("ERROR: No virus cartridge installed."))
					return FALSE

				var/datum/computer_file/program/messenger/target_messenger = null

				if(istype(target, /datum/pda_chat))
					var/datum/pda_chat/target_chat = target
					target_messenger = target_chat.recipient?.resolve()
					if(!istype(target_messenger))
						to_chat(usr, span_notice("ERROR: Recipient no longer exists."))
						return FALSE
				else if(istype(target, /datum/computer_file/program/messenger))
					target_messenger = target

				if(!istype(target_messenger?.computer))
					to_chat(usr, span_notice("ERROR: Invalid target."))
					return FALSE
				return disk.send_virus(computer, target_messenger.computer, usr, params["message"])

			return send_message(usr, params["message"], list(target))

		if("PDA_clearPhoto")
			selected_image = null
			var/obj/item/modular_computer/pda/pda_device = computer
			if(istype(pda_device))
				pda_device.picture = null
			return TRUE

		if("PDA_toggleVirus")
			sending_virus = !sending_virus
			return TRUE

		if("PDA_setAdminPhoto")
			if(!usr.client?.holder && !is_donator_group(usr.ckey, DONATOR_GROUP_TIER_2))
				to_chat(usr, span_warning("Only administrators and sponsors can use this feature."))
				return FALSE
			var/url = params["url"]
			if(url && istext(url))
				admin_photo_url = url
			else
				admin_photo_url = null
			return TRUE

		if("PDA_clearAdminPhoto")
			admin_photo_url = null
			return TRUE

		if("PDA_openMedia")
			var/url = params["url"]
			if(url && istext(url))
				usr << link(url)
			return TRUE

/datum/computer_file/program/messenger/ui_static_data(mob/user)
	var/list/static_data = list()
	static_data["can_spam"] = spam_mode
	static_data["is_silicon"] = issilicon(user)
	static_data["remote_silicon"] = (isAI(user) || iscyborg(user)) && !computer.get_ntnet_status()
	static_data["alert_able"] = alert_able
	return static_data

/datum/computer_file/program/messenger/ui_data(mob/user)
	var/list/data = get_header_data()

	var/list/chats_data = list()
	for(var/chat_ref in saved_chats)
		var/datum/pda_chat/chat = saved_chats[chat_ref]
		var/list/chat_data = chat.get_ui_data(user)
		chats_data[chat_ref] = chat_data

	var/list/messengers = get_messengers()

	data["owner"] = ((REF(src) in GLOB.pda_messengers) ? list(
			"name" = computer.saved_identification || "Unknown",
			"job" = computer.saved_job || "Unknown",
			"ref" = REF(src)
		) : null)
	data["saved_chats"] = chats_data
	data["messengers"] = messengers
	data["sort_by_job"] = sort_by_job
	data["alert_silenced"] = alert_silenced
	data["sending_and_receiving"] = sending_and_receiving
	data["open_chat"] = viewing_messages_of

	data["stored_photos"] = list()
	data["selected_photo_path"] = null
	data["on_spam_cooldown"] = !can_send_everyone_message()
	data["ringtone_list"] = GLOB.pda_ringtone_list
	data["current_ringtone"] = ringtone
	data["emoji_list"] = get_emoji_list()
	data["emoji_base64"] = get_emoji_base64()

	var/obj/item/modular_computer/pda/pda_device = computer
	if(istype(pda_device) && pda_device.picture)
		data["has_scanned_photo"] = TRUE
		var/datum/picture/pic = pda_device.picture
		if(pic && pic.picture_image)
			var/icon/img = pic.picture_image
			var/base64 = icon2base64(img)
			if(base64)
				data["selected_photo_path"] = "data:image/png;base64,[base64]"
			else
				data["selected_photo_path"] = null
		else
			data["selected_photo_path"] = null
	else
		data["has_scanned_photo"] = FALSE
		data["selected_photo_path"] = null

	data["admin_photo_url"] = admin_photo_url
	data["can_set_url_photo"] = !!user.client?.holder || is_donator_group(user.ckey, DONATOR_GROUP_TIER_1)

	var/obj/item/disk = computer.inserted_disk
	if(istype(disk, /obj/item/cartridge/virus))
		data["virus_attach"] = TRUE
		data["sending_virus"] = sending_virus
	return data

/datum/computer_file/program/messenger/ui_assets(mob/user)
	return ..()

//////////////////////
// MESSAGE HANDLING //
//////////////////////

/// Brings up the quick reply prompt from chat
/datum/computer_file/program/messenger/proc/quick_reply_prompt(mob/living/user, datum/pda_chat/chat)
	if(!istype(chat))
		return
	var/datum/computer_file/program/messenger/target = chat.recipient?.resolve()
	if(!istype(target) || !istype(target.computer))
		to_chat(user, span_notice("ERROR: Recipient no longer exists."))
		chat.recipient = null
		chat.can_reply = FALSE
		return
	var/target_name = target.computer.saved_identification
	var/input_message
	var/input_title = "NT Messaging[target_name ? " ([target_name])" : ""]"
	var/input_desc = "Enter [mime_mode ? "emojis":"a message"]."
	if(user.client?.prefs.tgui_input_verbs)
		input_message = tgui_input_text(user, input_desc, input_title, max_length = MAX_MESSAGE_LEN, encode = FALSE)
	else
		input_message = stripped_input(user, input_desc, input_title)
	if(!input_message)
		return
	send_message(user, input_message, list(chat))

/// Helper that sends a message to everyone
/datum/computer_file/program/messenger/proc/send_message_to_all(mob/living/user, message)
	var/list/datum/pda_chat/chats = list()
	var/list/messenger_targets = list()

	for(var/mc in get_messengers())
		messenger_targets += mc

	for(var/chatref in saved_chats)
		var/datum/pda_chat/chat = saved_chats[chatref]
		if(!(chat.recipient?.reference in messenger_targets))
			continue
		messenger_targets -= chat.recipient.reference
		chats += chat

	for(var/missing_messenger in messenger_targets)
		var/datum/pda_chat/new_chat = create_chat(missing_messenger)
		chats += new_chat

	if(send_message(user, message, chats, everyone = TRUE))
		COOLDOWN_START(src, last_text_everyone, 2 MINUTES)

/// Creates a chat and adds it to saved_chats. Returns the new chat.
/datum/computer_file/program/messenger/proc/create_chat(recipient_ref, name, job)
	var/datum/computer_file/program/messenger/recipient = null

	if(isnull(name) && isnull(job))
		if(!(recipient_ref in GLOB.pda_messengers))
			return null
		recipient = GLOB.pda_messengers[recipient_ref]

	var/datum/pda_chat/new_chat = new(recipient)

	// Fake user (automated or forged message)
	if(!istype(recipient))
		new_chat.cached_name = name
		new_chat.cached_job = job
		new_chat.can_reply = FALSE

	saved_chats[REF(new_chat)] = new_chat
	return new_chat

/// Gets the chat by the recipient
/datum/computer_file/program/messenger/proc/find_chat_by_recipient(recipient, fake_user = FALSE)
	for(var/chat_ref in saved_chats)
		var/datum/pda_chat/chat = saved_chats[chat_ref]
		if(fake_user && chat.cached_name == recipient)
			return chat
		else if(chat.recipient?.reference == recipient)
			return chat
	return null

/// Sanitizes a PDA message
/datum/computer_file/program/messenger/proc/sanitize_pda_message(message, mob/sender)
	message = sanitize(trim(message, MAX_PDA_MESSAGE_LEN))

	if(mime_mode)
		message = emoji_sanitize(message)

	return parse_emoji_message(message)

/// Sends a message to targets via PDA
/datum/computer_file/program/messenger/proc/send_message(atom/source, message, list/targets, everyone = FALSE)
	var/mob/living/sender
	if(isliving(source))
		sender = source

	var/photo_path = null
	var/photo_asset = null
	var/obj/item/modular_computer/pda/pda_device = computer
	if(istype(pda_device) && pda_device.picture)
		var/datum/picture/pic = pda_device.picture
		if(pic && pic.picture_image)
			var/icon/img = pic.picture_image
			var/base64 = icon2base64(img)
			if(base64)
				photo_path = "data:image/png;base64,[base64]"
				photo_asset = photo_path
			pda_device.picture = null

	if(admin_photo_url)
		photo_path = admin_photo_url
		photo_asset = admin_photo_url
		admin_photo_url = null

	message = sanitize_pda_message(message, sender)
	if(!message && !photo_path)
		return FALSE

	// Filter targets
	var/list/datum/computer_file/program/messenger/target_messengers = list()
	var/list/datum/pda_chat/target_chats = list()

	var/should_alert = length(targets) == 1 && sender

	for(var/target in targets)
		var/datum/pda_chat/target_chat = null
		var/datum/computer_file/program/messenger/target_messenger = null

		if(istype(target, /datum/pda_chat))
			target_chat = target

			if(!target_chat.can_reply)
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient has receiving disabled."))
				continue

			target_messenger = target_chat.recipient?.resolve()

			if(!istype(target_messenger))
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient no longer exists."))
				target_chat.can_reply = FALSE
				target_chat.recipient = null
				continue

			if(!target_messenger.sending_and_receiving)
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient has receiving disabled."))
				continue

		else if(istype(target, /datum/computer_file/program/messenger))
			target_messenger = target

			if(!target_messenger.sending_and_receiving)
				if(should_alert)
					to_chat(sender, span_notice("ERROR: Recipient has receiving disabled."))
				continue

			target_chat = find_chat_by_recipient(REF(target))

			if(!istype(target_chat))
				target_chat = create_chat(REF(target))
			if(!target_chat)
				continue

		else
			continue

		target_chats += target_chat
		target_messengers += target_messenger

	if(!send_message_signal(source, message, target_messengers, photo_path, everyone))
		return FALSE

	// Log in our chat
	var/datum/pda_message/message_datum = new(message, TRUE, STATION_TIME_TIMESTAMP(PDA_MESSAGE_TIMESTAMP_FORMAT, world.time), photo_asset, everyone)
	for(var/datum/pda_chat/target_chat as anything in target_chats)
		if(!target_chat)
			continue
		target_chat.add_message(message_datum, show_in_recents = !everyone)
		target_chat.unread_messages = 0

	// Switch chat screen after sending
	if(!everyone)
		viewing_messages_of = REF(target_chats[1])

	return TRUE

/// Sends a rigged message that explodes when the recipient tries to reply
/datum/computer_file/program/messenger/proc/send_rigged_message(mob/sender, message, list/datum/computer_file/program/messenger/targets, fake_name, fake_job)
	message = sanitize_pda_message(message, sender)
	if(!message)
		return FALSE
	return send_message_signal(sender, message, targets, null, FALSE, TRUE, fake_name, fake_job)

/datum/computer_file/program/messenger/proc/send_message_signal(atom/source, message, list/datum/computer_file/program/messenger/targets, photo_path = null, everyone = FALSE, rigged = FALSE, fake_name = null, fake_job = null)
	var/mob/sender
	if(ismob(source))
		sender = source
		if(!sender.canUseTopic(computer, BE_CLOSE, check_resting = FALSE))
			return FALSE

	if(!COOLDOWN_FINISHED(src, last_text))
		return FALSE

	if(!length(targets))
		return FALSE

	// Check for jammers
	if(is_within_radio_jammer_range(computer) && !rigged)
		if(sender)
			to_chat(sender, span_notice("ERROR: Network unavailable, please try again later."))
		if(alert_able && !alert_silenced)
			playsound(computer, 'sound/machines/terminal_error.ogg', 15, TRUE)
		return FALSE

	// Build the signal
	var/list/stringified_targets = list()
	for(var/datum/computer_file/program/messenger/messenger as anything in targets)
		stringified_targets += get_messenger_name(messenger)

	var/datum/signal/subspace/messaging/tablet_message/signal = new(computer, list(
		"ref" = REF(src),
		"message" = message,
		"targets" = targets,
		"rigged" = rigged,
		"everyone" = everyone,
		"photo" = photo_path,
		"automated" = FALSE,
	))
	if(rigged)
		signal.data["fakename"] = fake_name
		signal.data["fakejob"] = fake_job
		signal.server_type = /obj/machinery/telecomms/hub
		signal.data["reject"] = FALSE

	signal.send_to_receivers()

	// If it didn't reach
	if(!signal.data["done"])
		if(SSnetworks.ntnet_debug_global_signal)
			// Debug override: bypass telecomms infrastructure and deliver directly
			signal.broadcast()
			signal.mark_done()
		else
			if(sender)
				to_chat(sender, span_notice("ERROR: Server is not responding."))
			if(alert_able && !alert_silenced)
				playsound(computer, 'sound/machines/terminal_error.ogg', 15, TRUE)
			return FALSE

	var/shell_addendum = ""

	// Log in the talk log
	source.log_talk(message, LOG_PDA, tag="[shell_addendum][rigged ? "Rigged" : ""] PDA: [computer.saved_identification || "Unknown"] to [signal.format_target()]")
	if(rigged)
		var/log_text = "[key_name(sender)] sent a rigged PDA message (Name: [fake_name]. Job: [fake_job]) to [english_list(stringified_targets)] [sender.mind?.special_role ? "" : "(SENT BY NON-ANTAG)"]"
		log_game(log_text)
		message_admins(log_text)

	// Show to ghosts
	var/ghost_message = span_notice("[span_name(signal.format_sender())] [rigged ? "(as [span_name(fake_name)]) Rigged " : ""]PDA Message --> [span_name("[signal.format_target()]")]: \"[signal.format_message()]\"")
	var/list/message_listeners = GLOB.dead_mob_list + GLOB.current_observers_list
	for(var/mob/listener as anything in message_listeners)
		if(!listener.client)
			continue
		if(!(get_chat_toggles(listener.client) & CHAT_GHOSTPDA))
			continue
		to_chat(listener, "[FOLLOW_LINK(listener, source)] [ghost_message]")

	if(sender)
		to_chat(sender, span_info("PDA message sent to [signal.format_target()]: \"[message]\""))

	if(alert_able && !alert_silenced)
		computer.send_sound()

	COOLDOWN_START(src, last_text, 1 SECONDS)

	SEND_SIGNAL(computer, COMSIG_MODULAR_PDA_MESSAGE_SENT, source, signal)

	selected_image = null
	return TRUE

/datum/computer_file/program/messenger/proc/receive_message(datum/signal/subspace/messaging/tablet_message/signal)
	var/datum/pda_chat/chat = null

	var/is_rigged = signal.data["rigged"]
	var/is_automated = signal.data["automated"]
	var/is_fake_user = is_rigged || is_automated || isnull(signal.data["ref"])
	var/fake_name = is_fake_user ? signal.data["fakename"] : null
	var/fake_job = is_fake_user ? signal.data["fakejob"] : null

	var/sender_ref = signal.data["ref"]

	// Don't create a new chat for rigged messages
	if(!is_rigged)
		chat = find_chat_by_recipient(is_fake_user ? fake_name : sender_ref, is_fake_user)
		if(!istype(chat))
			chat = create_chat(!is_fake_user ? sender_ref : null, fake_name, fake_job)
		if(!chat)
			return
		if(chat.blocked)
			if(!is_fake_user)
				var/datum/computer_file/program/messenger/sender_messenger = GLOB.pda_messengers[sender_ref]
				if(istype(sender_messenger))
					var/obj/item/modular_computer/sender_computer = sender_messenger.computer
					if(istype(sender_computer) && isliving(sender_computer.loc))
						to_chat(sender_computer.loc, span_warning("Пользователь вас заблокировал."))
			return
		var/datum/pda_message/message = new(signal.data["message"], FALSE, STATION_TIME_TIMESTAMP(PDA_MESSAGE_TIMESTAMP_FORMAT, world.time), signal.data["photo"], signal.data["everyone"])
		chat.add_message(message)
		chat.unread_messages++

		// Update view if currently viewing sender's chat
		if(!isnull(viewing_messages_of) && viewing_messages_of == sender_ref)
			viewing_messages_of = REF(chat)

	var/list/mob/living/receivers = list()
	if(computer.inserted_pai && computer.inserted_pai.pai)
		receivers += computer.inserted_pai.pai
	if(isliving(computer.loc))
		receivers += computer.loc
	else if(isliving(computer.loc?.loc))
		receivers += computer.loc.loc

	var/datum/computer_file/program/messenger/sender_messenger = chat?.recipient?.resolve()

	var/sender_title = is_fake_user ? STRINGIFY_PDA_TARGET(fake_name, fake_job) : get_messenger_name(sender_messenger)
	var/sender_name = is_fake_user ? fake_name : (sender_messenger?.computer?.saved_identification || "Unknown")

	SEND_SIGNAL(computer, COMSIG_MODULAR_PDA_MESSAGE_RECEIVED, signal, fake_job || sender_messenger?.computer?.saved_job || "Unknown", sender_name)

	for(var/mob/living/messaged_mob as anything in receivers)
		if(messaged_mob.stat >= UNCONSCIOUS)
			continue
		if(!messaged_mob.is_literate())
			continue
		var/reply_href = signal.data["rigged"] ? "explode" : "message"
		var/reply
		if(is_automated)
			reply = "\[Automated Message\]"
		else
			reply = "(<a href='byond://?src=[REF(src)];choice=[reply_href];skiprefresh=1;target=[REF(chat)]'>Ответ</a>) (<a href='byond://?src=[REF(src)];choice=block;skiprefresh=1;target=[REF(chat)]'>Блок</a>)"

		if(isAI(messaged_mob))
			sender_title = "<a href='byond://?src=[REF(messaged_mob)];track=[html_encode(sender_name)]'>[sender_title]</a>"

		var/inbound_message = "[signal.format_message()]"
		var/photo = signal.data["photo"]
		var/photo_html = ""
		if(photo)
			var/regex/video_regex = new(@"\.(webm|mp4)(\?.*)?$", "i")
			if(video_regex.Find(photo))
				var/video_type = findtext(photo, ".mp4") ? "video/mp4" : "video/webm"
				photo_html = "<br><video autoplay loop controls style='max-width:300px;max-height:300px;display:block;margin-top:5px;'><source src='[html_encode(photo)]' type='[video_type]' /></video>"
			else
				photo_html = "<br><img src='[html_encode(photo)]' style='max-width:300px;max-height:300px;display:block;margin-top:5px;' />"

		to_chat(messaged_mob, span_info("[icon2html(computer, messaged_mob)] <b>PDA message from [sender_title], </b>\"[inbound_message]\" [reply][photo_html]"))

		SEND_SIGNAL(computer, COMSIG_COMPUTER_RECEIVED_MESSAGE, sender_title, inbound_message)

	if(alert_able && (!alert_silenced || is_rigged))
		computer.ring(ringtone, receivers)

	if(istype(computer, /obj/item/modular_computer/pda))
		var/obj/item/modular_computer/pda/pda = computer
		pda.receive_message(signal)

	SStgui.update_uis(computer)


/// Topic handler for reply links in chat
/datum/computer_file/program/messenger/Topic(href, href_list)
	..()

	if(QDELETED(src))
		return
	if(!usr.canUseTopic(computer, BE_CLOSE, no_tk = TRUE, check_resting = FALSE))
		return
	if(isobserver(usr))
		return

	// Ensure computer is on
	if(!computer.enabled)
		computer.turn_on(usr, FALSE)
		if(!computer.enabled)
			return

	var/target_href = href_list["target"]

	switch(href_list["choice"])
		if("message")
			if(!(target_href in saved_chats))
				return
			quick_reply_prompt(usr, saved_chats[target_href])

		if("explode")
			if(!HAS_TRAIT(computer, TRAIT_PDA_CAN_EXPLODE))
				return
			var/obj/item/modular_computer/pda/comp = computer
			if(istype(comp))
				comp.explode(usr, from_message_menu = TRUE)

		if("block")
			if(!(target_href in saved_chats))
				return
			var/datum/pda_chat/chat = saved_chats[target_href]
			chat.blocked = !chat.blocked
			if(chat.blocked)
				to_chat(usr, span_notice("[chat.get_recipient_name()] заблокирован."))
			else
				to_chat(usr, span_notice("[chat.get_recipient_name()] разблокирован."))
			SStgui.update_uis(computer)

/datum/computer_file/program/messenger/proc/compare_name(datum/computer_file/program/messenger/rhs)
	return sorttext(rhs.computer?.saved_identification || "", computer?.saved_identification || "")

/datum/computer_file/program/messenger/proc/compare_job(datum/computer_file/program/messenger/rhs)
	return sorttext(rhs.computer?.saved_job || "", computer?.saved_job || "")

/// Sort by job then name for messenger contact lists
/proc/cmp_list_data_job(list/a, list/b)
	var/job_cmp = sorttext(b["job"], a["job"])
	if(job_cmp != 0)
		return job_cmp
	return sorttext(b["name"], a["name"])

/// Sort by name for messenger contact lists
/proc/cmp_list_data_name(list/a, list/b)
	return sorttext(b["name"], a["name"])

#undef PDA_MESSAGE_TIMESTAMP_FORMAT
#undef MAX_PDA_MESSAGE_LEN
