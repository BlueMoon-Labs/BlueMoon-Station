// Advanced brainwash disk
/obj/item/disk/nifsoft_uploader/dorms/hypnosis/brainwashing
	name = "mesmer eye"
	loaded_nifsoft = /datum/nifsoft/action_granter/hypnosis/brainwashing

// More advanced variant for full brainwashing
/datum/nifsoft/action_granter/hypnosis/brainwashing
	name = "Mesmer Eye"
	program_desc = "Основанный на запрещённой технологии похитителей, NIFSoft Mesmer Eye позволяет пользователю полностью контролировать действия других. В отличие от Libidine Eye, жертвы не могут сопротивляться после получения приказа. Вы несёте ответственность за действия своей цели."

	// Has a cost
	active_cost = 0.1
	activation_cost = 1

	// Cannot be kept
	able_to_keep = FALSE

	// Grants different action
	action_to_grant = /datum/action/cooldown/hypnotize/brainwash

/datum/action/cooldown/hypnotize/brainwash
	name = "Brainwash"
	desc = "Пристально посмотрите в глаза человеку и заставьте его стать вашим верным рабом."
	button_icon_state = "Hypno_eye"
	icon_icon = 'modular_splurt/icons/mob/actions/lewd_actions/lewd_icons.dmi'
	background_icon_state = "bg_alien"

	// Should this create a brainwashed victim?
	mode_brainwash = TRUE

	// Terminology used
	term_hypno = "brainwash"
	term_suggest = "command"

	cooldown_time = 30 SECONDS
