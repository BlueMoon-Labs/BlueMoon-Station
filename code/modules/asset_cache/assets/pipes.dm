/datum/asset/spritesheet_batched/pipes
	name = "pipes"
	// Часть стейтов труб нарисована не во все 8 дирсов (мусоропровод и дакты - вообще
	// в один), и rust-g жалуется на каждый отсутствующий. Набор дирсов у стейта заранее
	// неизвестен, поэтому жалобу глушим: остальной лист при этом собирается целиком, а
	// RPD запрашивает у листа ровно те дирсы, которые есть у dirtype его рецепта.
	ignore_dir_errors = TRUE

/datum/asset/spritesheet_batched/pipes/create_spritesheets()
	for(var/icon_file in list('icons/obj/atmospherics/pipes/pipe_item.dmi', 'icons/obj/atmospherics/pipes/disposal.dmi', 'icons/obj/atmospherics/pipes/transit_tube.dmi', 'icons/obj/plumbing/fluid_ducts.dmi'))
		insert_all_icons("", icon_file, GLOB.alldirs)
