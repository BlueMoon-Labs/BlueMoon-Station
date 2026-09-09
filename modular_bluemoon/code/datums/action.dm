// Custom flags were added for logic actions - lying should not prevent ~98% of all actions

/datum/action/item_action/toggle_helmet_light
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/toggle_helmet_mode
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/toggle_helmet
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/set_internals
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/toggle_gunlight
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/toggle_hood
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/toggle_gloves
	name = "Activate"
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/no_drop_toggle
	name = "No Drop"
	desc = "Предмет не выпадет из рук!"
	icon_icon = 'icons/obj/items_and_weapons.dmi'
	button_icon_state = "disintegrate"
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = MOBILITY_HOLD

/datum/action/item_action/no_drop_toggle/Trigger()
	. = ..()
	if(!. || !isitem(target) || !isliving(usr))
		return FALSE
	var/obj/item/I = target
	var/mob/living/L = usr
	if(!L.is_holding(I))
		return FALSE
	if(HAS_TRAIT_FROM(I, TRAIT_NODROP, REF(src)))
		REMOVE_TRAIT(I, TRAIT_NODROP, REF(src))
		to_chat(L, "Ты расжимаешь хватку.")
	else
		ADD_TRAIT(I, TRAIT_NODROP, REF(src))
		to_chat(L, "Ты цепляешься к предмету мёртвой хваткой!")
		L.playsound_local(L, 'modular_bluemoon/sound/items/equip/glove_equip.ogg', 100, FALSE)
	UpdateButtons()

/datum/action/item_action/no_drop_toggle/UpdateButton(atom/movable/screen/movable/action_button/button, status_only, force)
	if(isitem(target) && HAS_TRAIT_FROM(target, TRAIT_NODROP, REF(src)))
		background_icon_state = "bg_default_on"
	else
		background_icon_state = "bg_default"
	. = ..()

/datum/action/item_action/no_drop_toggle/Remove()
	if(isitem(target) && !QDELETED(target))
		REMOVE_TRAIT(target, TRAIT_NODROP, REF(src))
	. = ..()

/datum/action/item_action/no_drop_toggle/Destroy()
	if(isitem(target))
		REMOVE_TRAIT(target, TRAIT_NODROP, REF(src))
	. = ..()
