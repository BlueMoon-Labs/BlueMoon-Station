/datum/keybinding/client/communication
	category = CATEGORY_COMMUNICATION

/datum/keybinding/client/communication/say
	hotkey_keys = list("CtrlT")
	classic_keys = list("Unbound")
	name = "Say"
	full_name = "IC Say"
	clientside = "Say"
	clientside_byond = "Say "

/datum/keybinding/client/communication/say_with_indicator
	hotkey_keys = list("T")
	name = "say_with_indicator"
	full_name = "Say with Typing Indicator"
	clientside = "Say (Indicator)"

/datum/keybinding/client/communication/whisper
	hotkey_keys = list("CtrlY")
	classic_keys = list("Unbound")
	name = "Whisper"
	full_name = "Whisper"
	clientside = "Whisper"
	clientside_byond = "Whisper "

/datum/keybinding/client/communication/whisper_with_indicator
	hotkey_keys = list("Y")
	name = "whisper_with_indicator"
	full_name = "Whisper with Typing Indicator"
	clientside = "Whisper (Indicator)"

/datum/keybinding/client/communication/looc
	hotkey_keys = list("L")
	name = "LOOC"
	full_name = "Local Out of Character chat"
	clientside = "looc"

/datum/keybinding/client/communication/ooc
	hotkey_keys = list("O")
	name = "OOC"
	full_name = "Out Of Character Say (OOC)"
	clientside = "ooc"

////////////////////////// ME LOGS //////////////////////////
/datum/keybinding/client/communication/me
	hotkey_keys = list("CtrlM")
	classic_keys = list("Unbound")
	name = "Me"
	full_name = "Me (emote)"
	clientside = "Me"
	clientside_byond = "Me "

/datum/keybinding/client/communication/me_with_indicator
	hotkey_keys = list("M")
	name = "me_with_indicator"
	full_name = "Me (emote) with Typing Indicator"

/datum/keybinding/client/communication/me_with_indicator/down(client/user)
	var/mob/M = user.mob
	M.me_typing_indicator()
	return TRUE

////////////////////////// ACTIVITY //////////////////////////
/datum/keybinding/client/communication/set_activity
	hotkey_keys = list("ShiftM")
	name = "set_activity"
	full_name = "Set Activity"

/datum/keybinding/client/communication/set_activity/down(client/user)
	var/mob/living/L = user.mob
	L.set_activity()
	return TRUE

////////////////////////// NARRATE //////////////////////////
//А тут ничего нету ¯\_(ツ)_/¯

////////////////////////// SUBTLERS //////////////////////////
/* Вырезан за ненадобностью
/datum/keybinding/client/communication/subtle
	hotkey_keys = list("5")
	name = "Subtle"
	full_name = "Subtle Emote"
	clientside = "subtle"

/datum/keybinding/client/communication/subtle_indicator
	hotkey_keys = list("5")
	name = "Subtle_Indicator"
	full_name = "Subtle Emote (with indicator)"
	clientside = "subtle-indicator"

/datum/keybinding/client/communication/subtle_indicator/down(client/user)
	var/mob/living/mob_keybound = user.mob
	mob_keybound.subtle_indicator()
	return TRUE
*/

/datum/keybinding/client/communication/subtler
	hotkey_keys = list("Ctrl5")
	classic_keys = list("Unbound")
	name = "subtler"
	full_name = "Subtler Anti-Ghost Emote"
	clientside = "Subtler Anti-Ghost"
	clientside_byond = "Subtler Anti-Ghost "

/datum/keybinding/client/communication/subtler_indicatored
	hotkey_keys = list("Unbound")
	classic_keys = list("Unbound")
	name = "subtler_indicatored"
	full_name = "Subtler Anti-Ghost Emote (with indicator)"
	clientside = "Subtler Anti-Ghost (Indicator)"

/datum/keybinding/client/communication/subtler_target
	hotkey_keys = list("Unbound")
	classic_keys = list("Unbound")
	name = "subtler_target"
	full_name = "Subtler Target Emote"
	clientside = "Subtler Target"
	clientside_byond = "Subtler Target "

/datum/keybinding/client/communication/subtler_target_indicatored
	hotkey_keys = list("Unbound")
	classic_keys = list("Unbound")
	name = "subtler_target_indicatored"
	full_name = "Subtler Target Emote (with indicator)"
	clientside = "Subtler Target (Indicator)"
