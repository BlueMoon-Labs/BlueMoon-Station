/**
 * Stores recently played gamemodes, maps, etc.
 */
/datum/controller/subsystem/persistence
	var/list/saved_modes = list(1,2,3)
	var/list/saved_round_types = list()
	var/list/saved_chaos = list(5,5,5)
	var/list/saved_dynamic_rules = list(list(),list(),list())
	var/average_threat = 50
	var/list/saved_maps
	var/last_dynamic_gamemode = "" //BLUEMOON ADDITION

/datum/controller/subsystem/persistence/SaveServerPersistence()
	. = ..()
	CollectRoundtype()
	RecordMaps()

/datum/controller/subsystem/persistence/LoadServerPersistence()
	. = ..()
	LoadRecentModes()
	LoadRecentRoundTypes()
	LoadRecentChaos()
	LoadRecentRulesets()
	LoadRecentMaps()
	LoadRecentDynamicType() //BLUEMOON ADDITION

// BLUEMOON EDITED - режимы теперь могут записываться после двух часов игры
/datum/controller/subsystem/persistence/proc/CollectRoundtype(record_chaos = TRUE)
	var/json_file = null
	var/list/file_data = list()
	if(!GLOB.midround_recorded)
		saved_modes[3] = saved_modes[2]
		saved_modes[2] = saved_modes[1]
		saved_modes[1] = SSticker.mode.config_tag
		RecordRecentRoundType(GLOB.round_type)
		json_file = file("data/RecentModes.json")
		file_data["data"] = saved_modes
		fdel(json_file)
		WRITE_FILE(json_file, json_encode(file_data))
	else
		message_admins("Режим был записан посреди раунда через midround_record, и по окончанию раунда записан не будет.")
	if(!record_chaos)
		return
	saved_chaos[3] = saved_chaos[2]
	saved_chaos[2] = saved_chaos[1]
	saved_chaos[1] = SSticker.mode.get_chaos()
	average_threat = (SSactivity.get_average_threat() + average_threat) / 2
	json_file = file("data/RecentChaos.json")
	file_data = list()
	file_data["data"] = saved_chaos + average_threat
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

// BLUEMOON EDITED - режимы теперь могут записываться после двух часов игры
/datum/controller/subsystem/persistence/proc/RecordMaps()
	if(GLOB.midround_recorded)
		message_admins("Карта была записана посреди раунда через midround_record, и по окончанию раунда записана не будет.")
		return
	saved_maps = saved_maps?.len ? list("[SSmapping.config.map_name]") | saved_maps : list("[SSmapping.config.map_name]")
	var/json_file = file("data/RecentMaps.json")
	var/list/file_data = list()
	file_data["maps"] = saved_maps
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

//BLUEMOON ADDITION START
/datum/controller/subsystem/persistence/proc/RecordDynamicType(var/type)
	if(GLOB.midround_recorded)
		message_admins("Тип динамика был записан посреди раунда через midround_record, и по окончанию раунда записан не будет.")
		return
	last_dynamic_gamemode = type
	var/json_file = file("data/RecentDynamicType.json")
	var/list/file_data = list()
	file_data["data"] = last_dynamic_gamemode
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/datum/controller/subsystem/persistence/proc/UnrecordGracefulEnding()
	var/json_file = file("data/GracefulEnding.json")
	var/list/file_data = list()
	file_data["data"] = "NOT_GRACEFULLY_ENDED"
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))
	message_admins("Раунд начался. Пометка \"Нормально завершившийся\" удалена.")

/datum/controller/subsystem/persistence/proc/RecordGracefulEnding()
	var/json_file = file("data/GracefulEnding.json")
	var/list/file_data = list()
	file_data["data"] = "GRACEFULLY_ENDED"
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))
	message_admins("Раунд помечен как \"Нормально завершившийся\"")

/datum/controller/subsystem/persistence/proc/CheckGracefulEnding()
	var/json_file = file("data/GracefulEnding.json")
	if(!fexists(json_file))
		return TRUE
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return TRUE
	return json["data"] == "GRACEFULLY_ENDED"

/datum/controller/subsystem/persistence/proc/LoadRecentDynamicType()
	var/json_file = file("data/RecentDynamicType.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return
	last_dynamic_gamemode = json["data"]
//BLUEMOON ADDITION END

/datum/controller/subsystem/persistence/proc/LoadRecentModes()
	var/json_file = file("data/RecentModes.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return
	saved_modes = json["data"]

/datum/controller/subsystem/persistence/proc/RecordRecentRoundType(roundtype)
	if(!roundtype)
		return
	LAZYINITLIST(saved_round_types)
	while(saved_round_types.len < 3)
		saved_round_types += ""
	saved_round_types[3] = saved_round_types[2]
	saved_round_types[2] = saved_round_types[1]
	saved_round_types[1] = roundtype
	var/json_file = file("data/RecentRoundTypes.json")
	var/list/file_data = list()
	file_data["data"] = saved_round_types
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/datum/controller/subsystem/persistence/proc/LoadRecentRoundTypes()
	var/json_file = file("data/RecentRoundTypes.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return
	saved_round_types = json["data"]

/datum/controller/subsystem/persistence/proc/LoadRecentChaos()
	var/json_file = file("data/RecentChaos.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return
	saved_chaos = json["data"]
	if(saved_chaos.len > 3)
		average_threat = saved_chaos[4]
	saved_chaos.len = 3

/datum/controller/subsystem/persistence/proc/LoadRecentRulesets()
	var/json_file = file("data/RecentRulesets.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return
	saved_dynamic_rules = json["data"]

/datum/controller/subsystem/persistence/proc/LoadRecentMaps()
	var/json_file = file("data/RecentMaps.json")
	if(!fexists(json_file))
		return
	var/list/json = json_decode(file2text(json_file))
	if(!json)
		return
	saved_maps = json["maps"]

/datum/controller/subsystem/persistence/proc/get_recent_chaos()
	var/sum = 0
	for(var/n in saved_chaos)
		sum += n
	return sum/length(saved_chaos)
