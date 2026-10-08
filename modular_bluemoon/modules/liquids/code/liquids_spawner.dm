/obj/effect/spawner/liquids_spawner
	name = "Liquids Spawner (Water, Waist-Deep)"
	icon = 'modular_bluemoon/modules/liquids/icons/obj/effects/liquid.dmi'
	icon_state = "spawner"
	color = "#AAAAAA77"
	var/list/reagent_list = list(/datum/reagent/water = ONE_LIQUIDS_HEIGHT * LIQUID_WAIST_LEVEL_HEIGHT)
	var/temp = T20C

/obj/effect/spawner/liquids_spawner/Initialize(mapload)
	. = ..()
	if(!isturf(loc))
		return INITIALIZE_HINT_QDEL
	var/turf/spawn_turf = loc
	spawn_turf.add_liquid_list(reagent_list, FALSE, temp)
	return INITIALIZE_HINT_QDEL
