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

/datum/action/item_action/toggle_welding_screen
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE
	icon_icon = 'icons/obj/clothing/hats.dmi'
	button_icon_state = "weldvisor" 			// for easier indication

/datum/action/item_action/toggle_hood
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/item_action/toggle_gloves
	name = "Activate"
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE
