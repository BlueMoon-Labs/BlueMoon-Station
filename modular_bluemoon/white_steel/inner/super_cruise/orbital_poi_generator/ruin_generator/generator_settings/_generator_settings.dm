//A datum for the generation settings of a ruin
/datum/generator_settings
	//Probability of this generator being chosen.
	var/probability = 0
	//Probability of breaking the floor
	var/floor_break_prob = 0
	//Probability of applying damage to structures
	var/structure_damage_prob = 0

//Gets shit to place on floors
/datum/generator_settings/proc/get_floortrash()
	return list()

//Сломанная контробанда из мондуля vanguard (broken_stuff.dm).
//Добавляется во все темы, вес выше, чем у работающего оружия/брони.
/datum/generator_settings/proc/get_broken_stuff()
	return list(
		/obj/item/broken/inteq_sledgehammer = 3,
		/obj/item/broken/dualsaber = 3,
		/obj/item/broken/energy_sword = 3,
		/obj/item/broken/inteq_elite = 3,
		/obj/item/broken/makarov = 3,
		/obj/item/broken/c20r = 3,
		/obj/item/broken/bulldog = 3,
		/obj/item/broken/ushm = 3,
		/obj/item/broken/sniper_rifle = 3,
		/obj/item/broken/m1garand = 3,
		/obj/item/broken/homemadeak = 3,
		/obj/item/broken/vss = 3,
		/obj/item/broken/hmg = 3,
	)

//Get directional stuff that goes on walls.
/datum/generator_settings/proc/get_directional_walltrash()
	return list()

//Gets non directional stuff that goes on walls
/datum/generator_settings/proc/get_non_directional_walltrash()
	return list()

//A list of rooms that can be placed on the map.
//Assoc list.
//key = ruin part
//value = max occurances
/datum/generator_settings/proc/get_valid_rooms(allowed_flags = RUIN_PART_DEFAULT)
	. = list()
	for(var/datum/map_template/ruin_part/ruinpart as() in GLOB.loaded_ruin_parts)
		if(ruinpart.special_flags & allowed_flags)
			.[ruinpart] = ruinpart.max_occurances

//A list of rooms to force place on the map.
//Useful for stuff like making crutch fuel outposts that have plasma in them.
/datum/generator_settings/proc/get_required_rooms()
	return list()
