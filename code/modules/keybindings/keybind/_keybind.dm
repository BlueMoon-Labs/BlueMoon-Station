/datum/keybinding
	var/list/hotkey_keys
	var/list/classic_keys
	var/name
	var/full_name
	var/description = ""
	var/category = CATEGORY_MISC
	var/weight = WEIGHT_LOWEST
	var/keybind_signal
	/// Если это вызов верба на стороне клиента, то укажите имя верба из set name
	var/clientside
	/// clientside но при отключенном преференсе tgui_input_verbs, для вызова вербов с параметрами, например /mob/verb/say_verb_byond(message as text)
	/// В отличие от обычного input в коде, вербы с параметрами могут открывать несколько инпутов одновременно
	var/clientside_byond
	/// Special - Needs to update special keys on update. clientside implis special.
	var/special = FALSE

/datum/keybinding/New()

	// Default keys to the master "hotkey_keys"
	if(LAZYLEN(hotkey_keys) && !LAZYLEN(classic_keys))
		classic_keys = hotkey_keys.Copy()

/datum/keybinding/proc/down(client/user)
    return FALSE

/datum/keybinding/proc/up(client/user)
	return FALSE

/datum/keybinding/proc/can_use(client/user)
	return TRUE
