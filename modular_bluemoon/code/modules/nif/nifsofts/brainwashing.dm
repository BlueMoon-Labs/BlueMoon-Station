// Advanced brainwash disk
/obj/item/disk/nifsoft_uploader/dorms/hypnosis/brainwashing
	name = "mesmer eye"
	loaded_nifsoft = /datum/nifsoft/action_granter/hypnosis/brainwashing

// More advanced variant for full brainwashing
/datum/nifsoft/action_granter/hypnosis/brainwashing
	name = "Mesmer Eye"
	program_desc = "Based on illegal abductor technology, the Mesmer Eye NIFSoft allows the user to completely control others actions. Unlike Libidine Eye, victims are unable to resist once given an order. You will be held responsible for your target's actions."

	// Has a cost
	active_cost = 0.1
	activation_cost = 1

	// Cannot be kept
	able_to_keep = FALSE

	// Grants different action
	action_to_grant = /datum/action/cooldown/hypnotize/brainwash

/datum/action/cooldown/hypnotize/brainwash
	name = "Brainwash"
	desc = "Stare deeply into someone's eyes, and force them to become your loyal slave."
	button_icon_state = "Hypno_eye"
	icon_icon = 'modular_splurt/icons/mob/actions/lewd_actions/lewd_icons.dmi'
	background_icon_state = "bg_alien"

	// Should this create a brainwashed victim?
	mode_brainwash = TRUE

	// Terminology used
	term_hypno = "brainwash"
	term_suggest = "command"

	cooldown_time = 30 SECONDS
