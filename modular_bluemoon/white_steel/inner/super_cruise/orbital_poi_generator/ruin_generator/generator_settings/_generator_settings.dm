//A datum for the generation settings of a ruin
/datum/generator_settings
	//Probability of this generator being chosen.
	var/probability = 0
	//Probability of breaking the floor
	var/floor_break_prob = 0
	//Probability of applying damage to structures
	var/structure_damage_prob = 0
	//WHITE-STEEL PORT: как руина этого генератора подписана как «сигнал» в консоли шаттла.
	var/signal_name = "Неопознанный сигнал"

//Gets shit to place on floors
/datum/generator_settings/proc/get_floortrash()
	return list()

//WHITE-STEEL PORT: общие константы генератора руин.
//Доля обломков (/obj/structure/salvage) от общего веса мусора. Используется и в
//add_rare_salvage(), и при расчёте веса матрigrass (generator_ratvar.dm) — менять долю
//нужно ТОЛЬКО здесь, иначе шанс матрigrass поедет.
#define RARELY_SALVAGE_SHARE 0.025
//Шанс появления матрigrass в мусоре руин Ратвара (ровно 1/1000).
#define MATRIGRASS_SPAWN_CHANCE 0.001

//WHITE-STEEL PORT: на ЛЮБОМ типе карт вместо мусора может появиться один случайный обломок
///obj/structure/salvage (без родителя). Шанс — 2.5% (0.025) от общего веса мусора на появление
//любого из обломков.
/datum/generator_settings/proc/add_rare_salvage(list/floortrash)
	if(!islist(floortrash))
		return
	var/list/salvage_types = list()
	for(var/obj/structure/salvage/S as() in subtypesof(/obj/structure/salvage))
		salvage_types += S
	if(!length(salvage_types))
		return
	var/total_weight = 0
	for(var/key in floortrash)
		total_weight += floortrash[key]
	if(total_weight <= 0)
		return
	var/per_type = total_weight * RARELY_SALVAGE_SHARE / length(salvage_types)
	for(var/salvage_type in salvage_types)
		floortrash[salvage_type] = (floortrash[salvage_type] || 0) + per_type

//Сломанное оружие больше не спавнится в мусоре руин.
/datum/generator_settings/proc/get_broken_stuff()
	return list()

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
