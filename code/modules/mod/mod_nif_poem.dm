/datum/mind
	var/list/nif_poem_senders

/datum/nifsoft/soul_poem
	name = "Poem of Communal Souls"
	program_desc = "Обменивается короткими визитками с другими NIF поблизости. Сообщения хранятся только в текущей программе до конца раунда."
	purchase_price = 0
	category = "Общение"
	active_mode = FALSE
	var/transmitting = TRUE
	var/receiving = TRUE
	var/transmitted_name
	var/transmitted_message
	var/transmitted_identifier
	var/list/messages = list()
	var/list/notified_senders = list()

/datum/nifsoft/soul_poem/New(obj/item/organ/cyberimp/brain/nif/implant)
	. = ..()
	if(QDELETED(src))
		return
	transmitted_name = linked_mob.real_name
	transmitted_message = "Привет! Рад знакомству."
	transmitted_identifier = text_ref(linked_mob.mind || linked_mob)
	RegisterSignal(linked_mob, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/nifsoft/soul_poem/Destroy()
	if(linked_mob)
		UnregisterSignal(linked_mob, COMSIG_MOVABLE_MOVED)
	messages.Cut()
	notified_senders = null
	return ..()

/datum/nifsoft/soul_poem/activate()
	if(!can_activate())
		return FALSE
	var/choice = tgui_input_list(linked_mob, "Выберите действие.", name, list("Мои сообщения", "Имя в визитке", "Текст визитки", "Передача", "Приём"))
	if(!can_activate())
		return FALSE
	switch(choice)
		if("Мои сообщения")
			show_messages()
		if("Имя в визитке")
			var/text = tgui_input_text(linked_mob, "Имя в визитке.", name, transmitted_name, max_length = MAX_NAME_LEN)
			if(can_activate() && !isnull(text))
				transmitted_name = text
		if("Текст визитки")
			var/text = tgui_input_text(linked_mob, "Текст визитки.", name, transmitted_message, max_length = MAX_MESSAGE_LEN)
			if(can_activate() && !isnull(text))
				transmitted_message = text
		if("Передача")
			transmitting = !transmitting
			to_chat(linked_mob, span_notice("NIF: передача визиток [transmitting ? "включена" : "выключена"]."))
		if("Приём")
			receiving = !receiving
			to_chat(linked_mob, span_notice("NIF: приём визиток [receiving ? "включён" : "выключен"]."))
	return TRUE

/datum/nifsoft/soul_poem/proc/on_moved()
	SIGNAL_HANDLER
	if(!can_activate() || !isturf(linked_mob.loc))
		return
	for(var/mob/living/carbon/human/human in view(NIF_POEM_RANGE, linked_mob))
		if(human == linked_mob)
			continue
		var/obj/item/organ/cyberimp/brain/nif/implant = human.getorganslot(ORGAN_SLOT_BRAIN_NIF)
		var/datum/nifsoft/soul_poem/other = locate() in implant?.loaded_nifsofts
		if(other?.can_activate())
			exchange(other)

/datum/nifsoft/soul_poem/proc/exchange(datum/nifsoft/soul_poem/other)
	if(!can_activate() || !other?.can_activate() || !linked_mob.Adjacent(other.linked_mob))
		return FALSE
	if(transmitting)
		other.receive_message(transmitted_identifier, transmitted_name, transmitted_message)
	if(other.transmitting)
		receive_message(other.transmitted_identifier, other.transmitted_name, other.transmitted_message)
	return TRUE

/datum/nifsoft/soul_poem/proc/receive_message(identifier, sender, text)
	if(!receiving || !length(text))
		return FALSE
	if(!(identifier in messages) && length(messages) >= NIF_POEM_LIMIT)
		messages.Cut(1, 2)
	messages[identifier] = list("sender" = sender, "text" = text)
	notify_sender(identifier, sender)
	return TRUE

/datum/nifsoft/soul_poem/proc/notify_sender(identifier, sender)
	if(!linked_mob)
		return
	var/list/notified = notified_senders
	if(linked_mob.mind)
		LAZYINITLIST(linked_mob.mind.nif_poem_senders)
		notified = linked_mob.mind.nif_poem_senders
	if(identifier in notified)
		return
	notified[identifier] = TRUE
	to_chat(linked_mob, span_notice("NIF: Poem of Communal Souls получил новую визитку от [html_encode(sender)]."))

/datum/nifsoft/soul_poem/proc/show_messages()
	var/list/options = list()
	for(var/identifier in messages)
		var/list/message = messages[identifier]
		options["[message["sender"]] ([length(options) + 1])"] = identifier
	var/selected = tgui_input_list(linked_mob, "Выберите визитку.", name, options)
	if(!can_activate() || !selected)
		return
	var/identifier = options[selected]
	var/list/message = messages[identifier]
	if(!islist(message))
		return
	var/choice = tgui_alert(linked_mob, message["text"], message["sender"], list("Закрыть", "Удалить"))
	if(can_activate() && choice == "Удалить")
		messages -= identifier

/obj/item/disk/nifsoft_uploader/soul_poem
	name = "Soul Poem NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/soul_poem
