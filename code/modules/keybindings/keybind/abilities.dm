/datum/keybinding/living/ability_slot
	description = "Использовать способность роли из указанного слота. Номера указаны в книге еретика. Клавиши можно переназначить."
	var/ability_slot = 0

/datum/keybinding/living/ability_slot/down(client/user)
	return user.mob.activate_ability_hotkey(ability_slot)

/datum/keybinding/living/cancel_ability
	hotkey_keys = list("AltQ")
	name = "cancel_ability"
	full_name = "Отменить подготовленную способность"
	description = "Снять прицеливание и рассеять контактную способность, сохранив обычные предметы в руках."

/datum/keybinding/living/cancel_ability/down(client/user)
	return user.mob.cancel_prepared_abilities()

/mob/proc/cancel_prepared_abilities(obj/effect/proc_holder/except)
	return FALSE

/mob/proc/prepare_ability(obj/effect/proc_holder/ability)
	cancel_prepared_abilities(ability)

/mob/proc/activate_ability_hotkey(slot)
	return FALSE

/mob/living/activate_ability_hotkey(slot)
	for(var/datum/antagonist/role as anything in mind?.antag_datums)
		if(role.activate_ability_hotkey(src, slot))
			return TRUE
	return FALSE

/datum/antagonist/proc/activate_ability_hotkey(mob/living/user, slot)
	return FALSE

/datum/keybinding/proc/format_keys(datum/preferences/preferences)
	var/list/keys = list()
	if(preferences)
		for(var/key in preferences.key_bindings)
			if(name in preferences.key_bindings[key])
				keys |= key
		for(var/key in preferences.modless_key_bindings)
			if(preferences.modless_key_bindings[key] == name)
				keys |= key
	else
		keys = hotkey_keys?.Copy() || list()
	keys -= "Unbound"
	var/list/labels = list()
	for(var/key in keys)
		var/list/parts = list()
		for(var/modifier in list("Alt", "Ctrl", "Shift"))
			if(findtext(key, modifier) == 1 && length(key) > length(modifier))
				parts += modifier
				key = copytext(key, length(modifier) + 1)
		parts += key
		labels += parts.Join("+")
	return length(labels) ? labels.Join(" / ") : "Не назначена"

/datum/keybinding/living/ability_slot/slot_1
	hotkey_keys = list("Alt1")
	name = "ability_slot_1"
	full_name = "Способность 1"
	ability_slot = 1

/datum/keybinding/living/ability_slot/slot_2
	hotkey_keys = list("Alt2")
	name = "ability_slot_2"
	full_name = "Способность 2"
	ability_slot = 2

/datum/keybinding/living/ability_slot/slot_3
	hotkey_keys = list("Alt3")
	name = "ability_slot_3"
	full_name = "Способность 3"
	ability_slot = 3

/datum/keybinding/living/ability_slot/slot_4
	hotkey_keys = list("Alt4")
	name = "ability_slot_4"
	full_name = "Способность 4"
	ability_slot = 4

/datum/keybinding/living/ability_slot/slot_5
	hotkey_keys = list("Alt5")
	name = "ability_slot_5"
	full_name = "Способность 5"
	ability_slot = 5

/datum/keybinding/living/ability_slot/slot_6
	hotkey_keys = list("Alt6")
	name = "ability_slot_6"
	full_name = "Способность 6"
	ability_slot = 6

/datum/keybinding/living/ability_slot/slot_7
	hotkey_keys = list("Alt7")
	name = "ability_slot_7"
	full_name = "Способность 7"
	ability_slot = 7

/datum/keybinding/living/ability_slot/slot_8
	hotkey_keys = list("Alt8")
	name = "ability_slot_8"
	full_name = "Способность 8"
	ability_slot = 8

/datum/keybinding/living/ability_slot/slot_9
	hotkey_keys = list("Alt9")
	name = "ability_slot_9"
	full_name = "Способность 9"
	ability_slot = 9

/datum/keybinding/living/ability_slot/slot_10
	hotkey_keys = list("Alt0")
	name = "ability_slot_10"
	full_name = "Способность 10"
	ability_slot = 10
