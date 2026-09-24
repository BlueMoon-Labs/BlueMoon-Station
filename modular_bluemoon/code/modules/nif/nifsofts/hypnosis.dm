/obj/item/disk/nifsoft_uploader/dorms/hypnosis
	name = "Purpura Eye"
	loaded_nifsoft = /datum/nifsoft/action_granter/hypnosis

/datum/nifsoft/action_granter/hypnosis
	name = "Libidine Eye"
	program_desc = "Based on the hypnotic equipment provided by the LustWish vendor, the Libidine Eye NIFSoft allows the user to ensnare others in a hypnotic trance. ((This is intended as a tool for ERP, don't use this for gameplay reasons.))"
	buying_category = NIFSOFT_CATEGORY_FUN
	lewd_nifsoft = TRUE
	purchase_price = 150
	able_to_keep = TRUE
	active_cost = 0.1
	ui_icon = "eye"
	action_to_grant = /datum/action/cooldown/hypnotize
