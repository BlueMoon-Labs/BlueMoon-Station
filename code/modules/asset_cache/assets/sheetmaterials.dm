/datum/asset/spritesheet_batched/sheetmaterials
	name = "sheetmaterials"

/datum/asset/spritesheet_batched/sheetmaterials/create_spritesheets()
	insert_all_icons("", 'icons/obj/stack_objects.dmi')
	// polycrystal живёт в телесайенсе, а не в stack_objects.dmi. Вставляем его после
	// общего прохода: если одноимённый стейт когда-нибудь появится в stack_objects.dmi,
	// приоритет останется за телесайенсом - ровно как на старом DM-пути.
	insert_icon("polycrystal", uni_icon('icons/obj/telescience.dmi', "polycrystal"))
