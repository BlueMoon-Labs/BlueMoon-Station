/obj/item/disk/nifsoft_uploader/dorms/hypnosis
	name = "Purpura Eye"
	loaded_nifsoft = /datum/nifsoft/action_granter/hypnosis

/datum/nifsoft/action_granter/hypnosis
	name = "Libidine Eye"
	program_desc = "Основанный на гипнотическом оборудовании торговца LustWish, NIFSoft Libidine Eye позволяет пользователю вводить других в гипнотический транс. ((Предназначен исключительно как инструмент для ERP-ролеплея, не используйте для игровых преимуществ.))"
	buying_category = NIFSOFT_CATEGORY_FUN
	lewd_nifsoft = TRUE
	purchase_price = 150
	able_to_keep = TRUE
	active_cost = 0.1
	ui_icon = "eye"
	action_to_grant = /datum/action/cooldown/hypnotize
