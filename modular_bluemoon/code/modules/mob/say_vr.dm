/mob/living/verb/subtler_indicatored()
	set name = "Subtler Anti-Ghost (Indicator)"
	set category = "Say"
	if(GLOB.say_disabled)
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	display_typing_indicator(isMe = TRUE)

	var/message = ""
	if(client?.prefs.tgui_input_verbs)
		message = tgui_input_text(src, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение", null, MAX_MESSAGE_LEN, TRUE, TRUE)
	else
		message = stripped_multiline_input_or_reflect(src, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение")
		
	clear_typing_indicator()
	if(!length(message))
		return
	usr.emote("subtler", message = message)

// Добавляем в IC панель для хуманов
/mob/living/carbon/human/Initialize(mapload)
	add_verb(src, /mob/living/verb/subtler_indicatored)
	. = ..()

// Хоткей
/datum/keybinding/client/communication/subtler_indicatored
	hotkey_keys = list("Unbound")
	name = "Subtler (Indicatored)"
	full_name = "Subtler Anti-Ghost Emote (with indicator)"
	clientside = "subtler-anti-ghost-indicatored"

/datum/keybinding/client/communication/subtler_indicatored/down(client/user)
	var/mob/living/L = user.mob
	if(istype(L))
		L.subtler_indicatored()
	return TRUE

/datum/emote/sound/human/subtle
	emote_cooldown = 0

/datum/emote/sound/human/subtler
	emote_cooldown = 0

/datum/emote/sound/human/subtler_table
	emote_cooldown = 0
